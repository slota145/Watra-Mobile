extends SceneTree
## Test bazy i lochu z Hordą: dotknięcie Watry w bazie otwiera wejście do lochu, krąg kamieni zatrzymuje postać;
## w lochu gobliny pojawiają się poza ekranem i idą do Wojciecha, zadają obrażenia (pasek zdrowia), miecz je zabija
## (licznik pokonanych), strumień przyspiesza z czasem, a po śmierci postaci jest okno wyniku z dwoma przyciskami.
## Żar: z goblina wypada iskra, sama leci do postaci z bliska, „Do bazy” zanosi żar do Watry (zapis), śmierć go gasi.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _touch(pos: Vector2, pressed: bool, finger := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.pressed = pressed
	e.position = pos
	root.push_input(e, true)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	await _test_base()
	await _test_horde()
	DirAccess.remove_absolute(root.get_node("Game").settings_path)
	DirAccess.remove_absolute(root.get_node("Game").save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_embers(arena: Node, hero: ProtoHero, horde: ProtoHorde) -> void:
	var game: Node = root.get_node("Game")
	game.embers = 0
	game.save_game()
	var embers: Array = []
	for n in arena.get_node("World").get_children():
		if n is ProtoEmber:
			embers.append(n)
	_check(embers.size() + horde.embers == horde.kills, "z każdego goblina wypada iskra żaru (%d + zebrane %d)" % [embers.size(), horde.embers])
	await _wait(0.6)
	_check(horde.embers >= 1 and arena.embers_label.text == str(horde.embers), "iskry obok postaci same do niej lecą (żar %d)" % horde.embers)
	# iskra daleko leży; z bliska leci do postaci
	var far := ProtoEmber.new()
	far.hero = hero
	far.position = hero.position + Vector2(120, 0)
	arena.get_node("World").add_child(far)
	var before := horde.embers
	far.collected.connect(func(v: int) -> void: horde._on_ember(v))
	await _wait(0.8)
	_check(horde.embers == before and is_instance_valid(far) and not far._taken, "daleka iskra czeka na ziemi")
	hero.position = far.position + Vector2(-30, 0)
	await _wait(0.6)
	_check(horde.embers == before + 1, "podejście przyciąga iskrę")
	# duża iskra co BIG_EVERY goblinów
	horde.kills = ProtoHorde.BIG_EVERY - 1
	var g := horde.spawn()
	g.take_damage(1000, hero.global_position)
	await process_frame
	await process_frame
	var big := false
	for n in arena.get_node("World").get_children():
		big = big or (n is ProtoEmber and n.value == ProtoEmber.BIG)
	_check(big, "co %d. goblin - duża iskra" % ProtoHorde.BIG_EVERY)
	# „Do bazy”: żar trafia do Watry i do zapisu (bez zmiany sceny w teście)
	var top: Rect2 = arena.base_button.get_global_rect()
	_check(top.size.y >= 44.0 and arena.joystick._is_blocked(top.get_center()), "przycisk „Do bazy” w lochu, 44 px, nie rusza gałki")
	horde.embers = 7
	arena._bank()
	_check(game.embers == 7 and game.embers_brought == 7 and horde.embers == 0, "powrót zanosi żar do Watry")
	game.embers = 0
	game.load_game()
	_check(game.embers == 7, "żar zapisany")
	horde.embers = 3  # tyle zgaśnie przy śmierci (sprawdzane niżej)


func _test_base() -> void:
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var watra: ProtoWatra = arena.watra
	_check(watra != null and arena.horde_spawner == null, "baza: Watra stoi, Hordy brak")
	_check(watra.glow_size() == 1.0 or watra.embers > 0, "bez żaru zwykła poświata")
	watra.embers = 500
	_check(watra.glow_size() > 1.4 and watra.glow_size() <= 1.6, "dużo żaru - większy ogień (%.2f)" % watra.glow_size())
	# zamiast zmiany sceny - tylko zapamiętujemy, że wejście zadziałało
	for c in watra.entered.get_connections():
		watra.entered.disconnect(c.callable)
	var entered := [false]
	watra.entered.connect(func() -> void: entered[0] = true)
	await _wait(0.3)
	var screen := watra.get_global_transform_with_canvas() * Vector2(0, -40)
	_check(Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(screen), "Watra widoczna z miejsca startu")
	_touch(screen, true)
	_touch(screen, false)
	await process_frame
	_check(entered[0], "dotknięcie Watry otwiera wejście do lochu")
	entered[0] = false
	_touch(Vector2(30, 600), true)
	_touch(Vector2(30, 600), false)
	await process_frame
	_check(not entered[0], "dotknięcie obok Watry nic nie robi")
	# krąg kamieni: postać pchana w Watrę zatrzymuje się na nim
	var hero: ProtoHero = arena.hero
	hero.position = watra.position + Vector2(0, 40)
	arena.joystick.vector = Vector2.UP
	await _wait(1.0)
	arena.joystick.vector = Vector2.ZERO
	_check(hero.position.y > watra.position.y + 10.0, "postać nie wchodzi w ogień (y %.0f)" % (hero.position.y - watra.position.y))
	arena.queue_free()
	await process_frame


func _test_horde() -> void:
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	_check(horde != null and arena.watra == null, "loch: Horda bez Watry")
	_check(horde.interval() > ProtoHorde.INTERVAL_END and horde.max_alive() == ProtoHorde.ALIVE_START, "start: wolny strumień")
	await _wait(ProtoHorde.FIRST_DELAY + 0.2)
	var goblins: Array = get_nodes_in_group(ProtoWeapon.TARGETS)
	_check(goblins.size() >= 1, "pojawił się goblin")
	if goblins.is_empty():
		return
	var g: ProtoGoblin = goblins[0]
	var screen := g.get_global_transform_with_canvas().origin
	_check(not Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(screen), "goblin pojawia się poza ekranem")
	var d0 := g.position.distance_to(hero.position)
	await _wait(0.5)
	_check(g.position.distance_to(hero.position) < d0 - 10.0, "goblin idzie do Wojciecha")
	# goblin obok postaci zadaje obrażenia
	g.position = hero.position + Vector2(10, 0)
	await _wait(2.0)
	_check(hero.hp < ProtoHero.MAX_HP, "goblin zadaje obrażenia (zdrowie %d)" % hero.hp)
	_check(is_equal_approx(arena.health_bar.value, hero.hp), "pasek zdrowia pokazuje zdrowie")
	# miecz zabija gobliny obok postaci
	hero.hp = ProtoHero.MAX_HP
	arena.weapon.attack_held = true
	await _wait(3.0)
	arena.weapon.attack_held = false
	_check(horde.kills >= 1, "miecz zabija gobliny (pokonane: %d)" % horde.kills)
	_check(arena.kills_label.text.ends_with(str(horde.kills)), "licznik pokonanych: %s" % arena.kills_label.text)
	await _test_embers(arena, hero, horde)
	# strumień rozkręca się z czasem
	horde.time = ProtoHorde.RAMP_TIME
	_check(is_equal_approx(horde.interval(), ProtoHorde.INTERVAL_END) and horde.max_alive() == ProtoHorde.ALIVE_END, "po 3 minutach pełne tempo")
	# śmierć: okno wyniku z przyciskami pod kciukiem
	hero._invulnerable = 0.0
	hero.take_damage(1000)
	_check(hero.dead, "Wojciech pada przy zerze zdrowia")
	await _wait(1.5)
	var result: RunResult = arena.result
	var view := root.get_visible_rect().size
	_check(result.visible and paused, "okno wyniku i pauza po śmierci")
	_check(result.retry_button.get_global_rect().get_center().y > view.y * 0.5 \
		and result.base_button.get_global_rect().size.y >= 44.0, "przyciski w dolnej połowie, min. 44 px")
	_check(result._summary.text.contains(str(horde.kills)), "wynik pokazuje pokonane: " + result._summary.text.replace("\n", ", "))
	_check(result._summary.text.contains(tr("Zgasło żaru: %d") % 3), "po śmierci żar z lochu gaśnie")
	var game: Node = root.get_node("Game")
	arena._bank()
	_check(game.embers == 7, "martwy Wojciech nie donosi żaru do Watry (%d)" % game.embers)
	paused = false
	arena.queue_free()
	await process_frame

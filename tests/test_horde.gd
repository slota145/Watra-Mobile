extends SceneTree
## Test bazy i lochu z Hordą: dotknięcie Watry w bazie otwiera wejście do lochu, krąg kamieni zatrzymuje postać;
## w lochu gobliny pojawiają się poza ekranem i idą do Wojciecha, zadają obrażenia (pasek zdrowia), miecz je zabija
## (licznik pokonanych), strumień przyspiesza z czasem, a po śmierci postaci jest okno wyniku z dwoma przyciskami.
## Żar: z goblina wypada iskra, sama leci do postaci z bliska i zapełnia pasek; pełny pasek - przycisk przyzwania Wodza.
## Wódz: przyzwanie zjada żar z paska, gobliny uciekają, ataki z ostrzeżeniem (cios w ziemię, rzut tasakiem, okrzyk),
## po śmierci skrzynia, zwycięstwo zanosi żar do Watry i odblokowuje poziom; śmierć i ucieczka gaszą żar.
## Baza: dotknięcie Watry otwiera wybór poziomu lochu.
## Łucznik (od 2. poziomu): trzyma dystans, przed strzałem linia celu, strzała trafia stojącą postać, da się ją wyminąć,
## trafienie mieczem przerywa naciąganie, limit łuczników naraz.

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
	await _test_chief()
	await _test_archer()
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
	# pasek żaru: do kosztu przyzwania; pełny - przycisk „Przyzwij Wodza” pod kciukiem
	horde._on_ember(0)
	horde.embers = 40
	horde._on_ember(0)
	_check(is_equal_approx(arena.ember_bar.value, 40.0) and not arena.summon_button.visible, "pasek żaru rośnie, bez przycisku przyzwania")
	horde.embers = DungeonLevels.SUMMON_COST + 5
	horde._on_ember(0)
	await process_frame
	var r: Rect2 = arena.summon_button.get_global_rect()
	var view := root.get_visible_rect().size
	_check(arena.summon_button.visible and arena.ember_bar.value == DungeonLevels.SUMMON_COST, "pełny pasek - przycisk przyzwania")
	_check(r.size.y >= 44.0 and r.get_center().y < view.y * 0.25 and arena.joystick._is_blocked(r.get_center()), "przycisk przyzwania u góry ekranu, 44 px, nie rusza gałki")
	# ucieczka z okna pauzy nie zanosi żaru
	arena._open_menu()
	_check(arena.pause_menu.leave_note.visible, "pauza ostrzega, że ucieczka gasi żar")
	arena.pause_menu.leaving.emit()
	arena.pause_menu.close()
	_check(game.embers == 0, "ucieczka nie zanosi żaru do Watry")
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
	# wybór poziomu: od 1 do najwyższego odblokowanego
	var game: Node = root.get_node("Game")
	game.best_level = 2
	arena.open_picker()
	var picker: LevelPicker = arena.picker
	_check(picker.visible and paused and picker.max_level == 3, "wybór poziomu (odblokowane do 3), gra stoi")
	picker.set_level(9)
	_check(picker.level == 3 and picker.plus_button.disabled and not picker.minus_button.disabled, "poziom nie wyżej niż odblokowany")
	picker.set_level(0)
	_check(picker.level == 1 and picker.minus_button.disabled, "poziom nie niżej niż 1")
	await process_frame
	_check(picker.enter_button.get_global_rect().get_center().y > root.get_visible_rect().size.y * 0.5 \
		and picker.enter_button.get_global_rect().size.y >= 44.0, "„Wejdź” w dolnej połowie, min. 44 px")
	for c in picker.enter.get_connections():
		picker.enter.disconnect(c.callable)
	var chosen := [0]
	picker.enter.connect(func(l: int) -> void: chosen[0] = l)
	picker.set_level(2)
	picker.enter_button.pressed.emit()
	_check(chosen[0] == 2 and not paused and not picker.visible, "„Wejdź” wchodzi na wybrany poziom")
	game.best_level = 0
	entered[0] = false
	_touch(Vector2(180, 470), true)
	_touch(Vector2(180, 470), false)
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
	# tryb deweloperski: nieśmiertelność - zdrowie wraca do pełna, licznik zgonów
	var game0: Node = root.get_node("Game")
	arena._open_menu()
	arena.pause_menu.immortal_toggle.button_pressed = true
	arena.pause_menu.close()
	_check(game0.dev_immortal and hero.immortal and arena.deaths_label.visible, "pauza włącza nieśmiertelność, widać licznik zgonów")
	hero._invulnerable = 0.0
	hero.take_damage(1000)
	_check(not hero.dead and hero.hp == ProtoHero.MAX_HP and hero.deaths == 1, "nieśmiertelny: zamiast śmierci pełne zdrowie")
	_check(arena.deaths_label.text == tr("Zgony: %d") % 1, "licznik zgonów: " + arena.deaths_label.text)
	game0.load_settings()
	_check(game0.dev_immortal, "nieśmiertelność zapamiętana w ustawieniach")
	arena._open_menu()
	arena.pause_menu.immortal_toggle.button_pressed = false
	arena.pause_menu.close()
	_check(not hero.immortal and not arena.deaths_label.visible, "wyłączenie nieśmiertelności")
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
	_check(game.embers == 0, "martwy Wojciech nie donosi żaru do Watry (%d)" % game.embers)
	_check(not arena.summon_button.visible, "po śmierci bez przycisku przyzwania")
	paused = false
	arena.queue_free()
	await process_frame


func _arrows(arena: Node) -> Array:
	var out: Array = []
	for n in arena.get_node("World").get_children():
		if n is ProtoArrow and not n._done:
			out.append(n)
	return out


func _test_archer() -> void:
	var game: Node = root.get_node("Game")
	_check(DungeonLevels.archer_share(1) == 0.0 and DungeonLevels.archer_share(2) > 0.0
		and DungeonLevels.archer_share(99) == DungeonLevels.ARCHER_SHARE_MAX, "łucznicy od 2. poziomu, udział rośnie do sufitu")
	game.best_level = 2
	game.dungeon_level = 2
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	var a: ProtoGoblinArcher = horde.spawn_at(hero.position + Vector2(100, 0), true)
	await process_frame
	_check(a.hp == roundi(ProtoGoblinArcher.ARCHER_HP * horde.power) and a.hp < roundi(ProtoGoblin.MAX_HP * horde.power), "łucznik słabszy od goblina (%d)" % a.hp)
	# z daleka podchodzi, z bliska się cofa
	a._cooldown = 99.0
	a.position = hero.position + Vector2(170, 0)
	await _wait(0.5)
	_check(a.position.x - hero.position.x < 165.0, "łucznik z daleka podchodzi")
	a.position = hero.position + Vector2(30, 0)
	await _wait(0.5)
	_check(a.position.x - hero.position.x > 40.0, "za blisko - łucznik się cofa")
	# strzał w stojącą postać: linia celu, strzała, obrażenia
	a.position = hero.position + Vector2(100, 0)
	hero.hp = hero.max_hp
	a._cooldown = 0.0
	await _wait(0.15)
	_check(a.aiming() and a._aim_line.visible, "łucznik naciąga łuk - na ziemi linia celu")
	await _wait(ProtoGoblinArcher.RELEASE_TIME + 0.1)
	_check(_arrows(arena).size() == 1, "strzała wylatuje")
	a._cooldown = 99.0
	await _wait(1.2)
	_check(hero.hp < hero.max_hp, "strzała trafia stojącą postać (zdrowie %d)" % hero.hp)
	# zejście z linii po zablokowaniu celu ratuje
	await _wait(0.4)
	hero.hp = hero.max_hp
	a.position = hero.position + Vector2(100, 0)
	a._cooldown = 0.0
	await _wait(ProtoGoblinArcher.RELEASE_TIME - ProtoGoblinArcher.AIM_LOCK + 0.1)
	_check(a.aim_locked(), "cel zablokowany przed strzałem")
	var aim := a.aim
	hero.position += Vector2(0, 30)
	await _wait(0.3)
	_check(a.aim == aim, "po zablokowaniu linia nie podąża za postacią")
	a._cooldown = 99.0
	await _wait(1.6)
	_check(hero.hp == hero.max_hp, "zejście z linii - strzała chybia")
	# cięcie w trakcie naciągania przerywa strzał
	for n in _arrows(arena):
		n.queue_free()
	await process_frame
	a.position = hero.position + Vector2(100, 0)
	a._cooldown = 0.0
	await _wait(0.2)
	a.take_damage(1, hero.global_position)
	await _wait(ProtoGoblinArcher.RELEASE_TIME + 0.2)
	_check(_arrows(arena).is_empty(), "trafienie mieczem przerywa naciąganie")
	# limit łuczników naraz
	horde.level = 50
	for i in 40:
		horde.spawn()
	_check(horde.archers() <= ProtoHorde.MAX_ARCHERS and horde.archers() >= 2, "najwyżej %d łuczników naraz (%d)" % [ProtoHorde.MAX_ARCHERS, horde.archers()])
	horde.scatter()
	_check(horde.archers() == 0, "łucznicy też uciekają przed Wodzem")
	arena.queue_free()
	await process_frame


func _test_chief() -> void:
	var game: Node = root.get_node("Game")
	game.embers = 0
	game.best_level = 1
	game.dungeon_level = 2
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	_check(arena.level == 2 and is_equal_approx(horde.power, DungeonLevels.power(2)), "poziom 2: silniejsze gobliny (x%.2f)" % horde.power)
	var g := horde.spawn_at(hero.position + Vector2(60, 0))
	await process_frame
	_check(g.hp == roundi(ProtoGoblin.MAX_HP * horde.power), "goblin ma więcej zdrowia (%d)" % g.hp)
	horde.embers = DungeonLevels.SUMMON_COST + 12
	horde._on_ember(0)
	arena.summon_button.pressed.emit()
	await process_frame
	var chief: ProtoChief = arena.chief
	_check(chief != null and arena.phase == "boss", "przycisk przyzywa Wodza")
	_check(horde.embers == 12 and arena.embers_label.text == "12", "przyzwanie zjada żar z paska, nadwyżka zostaje")
	_check(not horde.running and not g.alive() and not g.is_in_group(ProtoWeapon.TARGETS), "gobliny uciekają, strumień staje")
	_check(arena.boss_box.visible and arena.boss_bar.max_value == chief.max_hp and chief.max_hp > ProtoChief.MAX_HP, "pasek zdrowia Wodza (%d)" % chief.max_hp)
	var screen := chief.get_global_transform_with_canvas().origin
	_check(Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(screen), "Wódz widoczny na ekranie")
	await _wait(0.5)
	chief.take_damage(50, hero.global_position)
	_check(chief.hp == chief.max_hp, "przy wejściu Wódz nietykalny")
	await _wait(ProtoChief.ENTER_TIME)
	_check(not is_instance_valid(g), "uciekający goblin znika")
	_check(chief.state == "walk", "po ryku Wódz rusza")
	# cios w ziemię: czerwone koło, trafia, gdy postać stoi w środku
	hero.position = chief.position + Vector2(20, 5)
	hero.hp = ProtoHero.MAX_HP
	hero._invulnerable = 0.0
	chief._start_slam()
	_check(chief._telegraph != null and chief._telegraph.radius == ProtoChief.SLAM_RADIUS, "cios w ziemię - ostrzeżenie na ziemi")
	await _wait(ProtoChief.SLAM_WARN + 0.1)
	_check(hero.hp == ProtoHero.MAX_HP - roundi(ProtoChief.SLAM_DAMAGE * chief.power), "cios trafia w kole (zdrowie %d)" % hero.hp)
	# ucieczka z koła - bez obrażeń
	await _wait(1.0)
	hero.hp = ProtoHero.MAX_HP
	hero.position = chief.position + Vector2(20, 5)
	chief._start_slam()
	await _wait(0.3)
	hero.position = chief.position + Vector2(90, 0)
	await _wait(ProtoChief.SLAM_WARN)
	_check(hero.hp == ProtoHero.MAX_HP, "wyjście z koła ratuje przed ciosem")
	# rzut tasakiem: koło pod postacią, tasak spada i wraca
	await _wait(1.0)
	hero.position = chief.position + Vector2(100, 0)
	hero.hp = ProtoHero.MAX_HP
	hero._invulnerable = 0.0
	chief._start_throw()
	_check(chief._telegraph.contains(hero.global_position), "rzut - koło pod postacią")
	await _wait(ProtoChief.THROW_WARN + 0.1)
	_check(hero.hp < ProtoHero.MAX_HP, "tasak trafia stojącą postać (zdrowie %d)" % hero.hp)
	await _wait(1.0)
	_check(chief._cleaver == null, "tasak wraca do Wodza")
	# okrzyk: gobliny wokół Wodza
	var before: int = get_nodes_in_group(ProtoWeapon.TARGETS).size()
	chief._start_roar()
	await _wait(ProtoChief.ROAR_TIME + 0.1)
	_check(get_nodes_in_group(ProtoWeapon.TARGETS).size() == before + ProtoChief.ROAR_MINIONS, "okrzyk przywołuje gobliny")
	# śmierć: skrzynia, iskry, zwycięstwo
	hero.hp = ProtoHero.MAX_HP
	hero.position = chief.position + Vector2(0, 120)
	var at := chief.position
	chief.take_damage(100000, hero.global_position)
	_check(not chief.alive() and arena.phase == "loot", "Wódz pada")
	await _wait(0.3)
	var fled := true
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin and n.alive():
			fled = false
	_check(fled, "po śmierci Wodza gobliny uciekają")
	await _wait(arena.CHEST_DELAY)
	var chest: ProtoChest = arena.chest
	_check(chest != null and chest.position.distance_to(at) < 1.0 and not chest.is_open, "skrzynia w miejscu Wodza")
	var embers_before: int = horde.embers
	hero.position = chest.position + Vector2(0, 10)
	await _wait(0.4)
	_check(chest.is_open, "podejście otwiera skrzynię")
	await _wait(arena.VICTORY_DELAY + 0.2)
	_check(horde.embers == 0 and game.embers == embers_before + DungeonLevels.chest_embers(2), "żar ze skrzyni i z wyprawy w Watrze (%d)" % game.embers)
	_check(game.best_level == 2 and game.unlocked_level() == 3, "zwycięstwo odblokowuje poziom 3")
	_check(arena.run_items + int(arena.run_sold_gold > 0) >= Items.CHEST_ITEMS and game.bag.size() >= mini(Items.CHEST_ITEMS, game.BAG_SIZE), "przedmioty ze skrzyni w torbie (%d)" % game.bag.size())
	var result: RunResult = arena.result
	_check(result.visible and paused and result._summary.text.contains(tr("Odblokowano poziom %d") % 3), "okno zwycięstwa: " + result._summary.text.replace("\n", ", "))
	_check(result.retry_button.text == tr("Następny poziom: %d") % 3, "przycisk następnego poziomu")
	game.load_game()
	_check(game.best_level == 2, "przebity poziom zapisany")
	paused = false
	arena.queue_free()
	await process_frame

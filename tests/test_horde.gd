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
## Osiłek (od 3. poziomu): wytrzymały, przed ciosem czerwone koło przed nim, wyjście z koła ratuje, cięcie nie przerywa
## zamachu, ogłuszenie przerywa, limit osiłków naraz, więcej żaru.
## Elity (od 2. poziomu): więcej zdrowia, napis z cechami, tarcza, szybkość, wzmocnienie sąsiadów, wybuch po śmierci,
## nagroda (przedmiot, duża iskra, sygnał do doświadczenia).

var _failed := 0


func _initialize() -> void:
	# Rozruch (27.11.2026): zdrowie wrogów 40% na 1. poziomie, pełne od 10.; sprawdzane przed wyłączeniem do liczb testów
	_check(is_equal_approx(DungeonLevels.ramp(1), 0.4) and is_equal_approx(DungeonLevels.ramp(10), 1.0)
			and is_equal_approx(DungeonLevels.ramp(40), 1.0) and DungeonLevels.ramp(5) > 0.4 and DungeonLevels.ramp(5) < 1.0,
			"Rozruch: 40% zdrowia na 1. poziomie, pełne od 10.")
	DungeonLevels.enemy_hp = 1.0  # liczby w testach bez próby x3 zdrowia / x2 obrażeń wrogów (20.11.2026)
	DungeonLevels.ramp_start = 1.0  # i bez Rozruchu (27.11.2026)
	DungeonLevels.enemy_damage = 1.0
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
	_test_depth()
	await _test_base()
	await _test_horde()
	await _test_chief()
	await _test_archer()
	await _test_brute()
	await _test_elites()
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
	_check(embers.size() + horde.embers <= horde.kills + ProtoEmber.BIG, "iskry żaru wypadają z części goblinów (%d + zebrane %d, pokonane %d)" % [embers.size(), horde.embers, horde.kills])
	var near := ProtoEmber.new()  # iskra wypada tylko z części goblinów - jedna na pewno obok postaci
	near.hero = hero
	near.position = hero.position + Vector2(12, 0)
	near.collected.connect(horde._on_ember)
	arena.get_node("World").add_child(near)
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
	horde.embers = DungeonLevels.summon_cost(horde.level) + 5
	horde._on_ember(0)
	await process_frame
	var r: Rect2 = arena.summon_button.get_global_rect()
	var view := root.get_visible_rect().size
	_check(arena.summon_button.visible and arena.ember_bar.value == DungeonLevels.summon_cost(horde.level), "pełny pasek - przycisk przyzwania")
	_check(r.size.y >= 44.0 and r.get_center().y < view.y * 0.25 and arena.joystick._is_blocked(r.get_center()), "przycisk przyzwania u góry ekranu, 44 px, nie rusza gałki")
	# ucieczka z okna pauzy nie zanosi żaru
	arena._open_menu()
	_check(arena.pause_menu.leave_note.visible, "pauza ostrzega, że ucieczka gasi żar")
	arena.pause_menu.leaving.emit()
	arena.pause_menu.close()
	_check(game.embers == 0, "ucieczka nie zanosi żaru do Watry")
	horde.embers = 3  # tyle zgaśnie przy śmierci (sprawdzane niżej)


## Głębokie lochy (13.11.2026, +20% na poziom od 17.11.2026): siła rośnie coraz szybciej, więcej potworów (do ALIVE_CAP), doświadczenie liniowo.
func _test_depth() -> void:
	var p10 := DungeonLevels.power(10)
	var p50 := DungeonLevels.power(50)
	var p100 := DungeonLevels.power(100)
	_check(is_equal_approx(DungeonLevels.power(1), 1.0) and p10 > 3.2 and p10 < 3.5 and p50 > 26.0 and p50 < 31.0
			and p100 > 80.0 and p100 < 95.0, "siła: 10. poz. x%.1f, 50. x%.1f, 100. x%.0f (od 40. wolniej)" % [p10, p50, p100])
	_check(roundi(ProtoGoblin.DAMAGE * p100) > HeroLevels.max_hp(15) * 2, "na 100. poziomie goblin zabija postać 15. poziomu jednym ciosem")
	_check(DungeonLevels.crowd(1) == 1.0 and DungeonLevels.crowd(30) > 1.25 and DungeonLevels.crowd(100) == DungeonLevels.CROWD_MAX,
			"tłum rośnie do x%.2f" % DungeonLevels.crowd(100))
	_check(HeroLevels.goblin_xp(100) == roundi(HeroLevels.GOBLIN_XP * DungeonLevels.reward(100)), "doświadczenie rośnie liniowo")
	var horde := ProtoHorde.new()
	horde.density = 3.0
	horde.time = ProtoHorde.RAMP_TIME
	_check(horde.max_alive() == ProtoHorde.ALIVE_CAP, "najwyżej %d potworów naraz" % ProtoHorde.ALIVE_CAP)
	# żar w głębi: iskra warta DungeonLevels.ember_value (+2% na poziom), przyzwanie droższe o wartość iskier i tłum
	_check(DungeonLevels.summon_cost(1) == DungeonLevels.SUMMON_BASE and is_equal_approx(DungeonLevels.ember_value(101), 3.0)
			and DungeonLevels.summon_cost(101) > 450 and DungeonLevels.summon_cost(101) < 480,
			"przyzwanie: 1. poz. %d, 10. %d, 101. %d" % [DungeonLevels.summon_cost(1), DungeonLevels.summon_cost(10), DungeonLevels.summon_cost(101)])
	horde.level = 101
	horde._on_ember(1)
	horde._on_ember(ProtoHorde.BRUTE_EMBERS)
	_check(horde.embers == 12, "iskra na 101. poziomie warta x3 (zwykła + osiłka - %d żaru)" % horde.embers)
	horde.free()


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
	# dalej tylko ten goblin (gęsta Horda potrafi zabić postać przed sprawdzeniem obrażeń)
	horde.running = false
	for n in get_nodes_in_group(ProtoWeapon.TARGETS):
		if n != g:
			n.queue_free()
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
	_check(is_equal_approx(horde.interval(), ProtoHorde.INTERVAL_END) and horde.max_alive() == ProtoHorde.ALIVE_END, "po rozkręceniu pełne tempo")
	# grupka: kilka potworów naraz z jednego miejsca
	var before: Array = get_nodes_in_group(ProtoWeapon.TARGETS)
	var made := horde.spawn_group()
	var group: Array = get_nodes_in_group(ProtoWeapon.TARGETS).filter(func(n: Node) -> bool: return not n in before)
	var tight := group.size() == made and group.all(func(n: Node2D) -> bool:
		return n.global_position.distance_to(group[0].global_position) <= ProtoHorde.GROUP_SPREAD * 3.0)
	_check(made >= ProtoHorde.GROUP_END.x and made <= ProtoHorde.GROUP_END.y and tight, "grupka %d potworów z jednej strony" % made)
	# reszta testu bez tłumu (gęsta Horda potrafi zabić postać, zanim włączy się nieśmiertelność)
	horde.running = false
	for n in get_nodes_in_group(ProtoWeapon.TARGETS):
		n.queue_free()
	hero.hp = ProtoHero.MAX_HP
	await process_frame
	# tryb deweloperski: nieśmiertelność - zdrowie wraca do pełna, licznik zgonów
	var game0: Node = root.get_node("Game")
	arena._open_menu()
	arena.pause_menu.dev.immortal_toggle.button_pressed = true
	arena.pause_menu.close()
	_check(game0.dev_immortal and hero.immortal and arena.deaths_label.visible, "pauza włącza nieśmiertelność, widać licznik zgonów")
	hero._invulnerable = 0.0
	hero.take_damage(1000)
	_check(not hero.dead and hero.hp == ProtoHero.MAX_HP and hero.deaths == 1, "nieśmiertelny: zamiast śmierci pełne zdrowie")
	_check(arena.deaths_label.text == tr("Zgony: %d") % 1, "licznik zgonów: " + arena.deaths_label.text)
	game0.load_game()
	_check(game0.dev_immortal, "nieśmiertelność zapamiętana w zapisie postaci")
	arena._open_menu()
	arena.pause_menu.dev.immortal_toggle.button_pressed = false
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
	var a: ProtoGoblinArcher = horde.spawn_at(hero.position + Vector2(100, 0), "archer")
	await process_frame
	_check(a.hp == roundi(ProtoGoblinArcher.ARCHER_HP * horde.power * DungeonLevels.hp_mult(horde.level)) and a.hp < roundi(ProtoGoblin.MAX_HP * horde.power), "łucznik słabszy od goblina (%d)" % a.hp)
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


func _test_brute() -> void:
	var game: Node = root.get_node("Game")
	_check(DungeonLevels.brute_share(2) == 0.0 and DungeonLevels.brute_share(3) > 0.0
		and DungeonLevels.brute_share(99) == DungeonLevels.BRUTE_SHARE_MAX, "osiłki od 3. poziomu, udział rośnie do sufitu")
	game.best_level = 3
	game.dungeon_level = 3
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	var b: ProtoGoblinBrute = horde.spawn_at(hero.position + Vector2(80, 0), "brute")
	await process_frame
	_check(b.hp == roundi(ProtoGoblinBrute.BRUTE_HP * horde.power * DungeonLevels.hp_mult(horde.level)) and b.hp > roundi(ProtoGoblin.MAX_HP * horde.power) * 3, "osiłek ma dużo zdrowia (%d)" % b.hp)
	await _wait(0.5)
	_check(b.position.x - hero.position.x < 78.0 and b.position.x - hero.position.x > 55.0, "osiłek idzie powoli (%.0f)" % (b.position.x - hero.position.x))
	# cios: koło przed osiłkiem, stojąca postać obrywa, cięcie nie przerywa zamachu
	b.position = hero.position + Vector2(20, 0)
	b._cooldown = 0.0
	hero.hp = hero.max_hp
	await _wait(0.2)
	_check(b._state == "attack" and is_instance_valid(b._telegraph) and b._telegraph.contains(hero.global_position), "zamach: czerwone koło pod postacią")
	b.take_damage(1, hero.global_position)
	await process_frame
	_check(b._state == "attack" and is_instance_valid(b._telegraph), "cięcie nie przerywa zamachu osiłka")
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp == hero.max_hp - roundi(ProtoGoblinBrute.SLAM_DAMAGE * horde.power * DungeonLevels.MONSTER_DAMAGE), "maczuga trafia w kole (zdrowie %d)" % hero.hp)
	_check(b._telegraph == null, "po ciosie koło znika")
	# wyjście z koła ratuje
	await _wait(0.6)
	b._cooldown = 99.0
	await _wait(0.5)
	hero.hp = hero.max_hp
	b.position = hero.position + Vector2(20, 0)
	b._state = "walk"
	b._cooldown = 0.0
	await _wait(0.3)
	hero.position += Vector2(-50, 0)
	b._cooldown = 99.0
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp == hero.max_hp, "wyjście z koła ratuje przed maczugą")
	# ogłuszenie przerywa zamach
	await _wait(0.6)
	b.position = hero.position + Vector2(20, 0)
	b._state = "walk"
	b._cooldown = 0.0
	await _wait(0.2)
	b.stun(1.5)
	await process_frame
	_check(b._state != "attack" and b._telegraph == null, "ogłuszenie przerywa zamach i gasi koło")
	# więcej żaru, limit naraz
	var kills := horde.kills
	b.take_damage(100000, hero.global_position)
	await process_frame
	await process_frame
	_check(horde.kills == kills + 1, "osiłek pokonany")
	# iskra z części osiłków (EMBER_CHANCE), ale warta BRUTE_EMBERS
	var brute_sparks := 0
	for i in 40:
		var extra: ProtoGoblin = horde.spawn_at(hero.position + Vector2(-60, 40), "brute")
		horde.kills = 1  # bez dużych iskier co BIG_EVERY
		extra.take_damage(100000, hero.global_position)
	await process_frame
	await process_frame
	for n in arena.get_node("World").get_children():
		if n is ProtoEmber and n.value == ProtoHorde.BRUTE_EMBERS:
			brute_sparks += 1
	_check(brute_sparks >= 1 and brute_sparks <= 22, "iskra z części osiłków, warta %d (%d z 40)" % [ProtoHorde.BRUTE_EMBERS, brute_sparks])
	horde.level = 50
	for i in 60:
		horde.spawn()
	_check(horde.count(ProtoGoblinBrute) <= ProtoHorde.MAX_BRUTES and horde.count(ProtoGoblinBrute) >= 1, "najwyżej %d osiłków naraz (%d)" % [ProtoHorde.MAX_BRUTES, horde.count(ProtoGoblinBrute)])
	horde.scatter()
	_check(horde.count(ProtoGoblinBrute) == 0, "osiłki też uciekają przed Wodzem")
	arena.queue_free()
	await process_frame


func _test_elites() -> void:
	var game: Node = root.get_node("Game")
	_check(Elites.max_traits(1) == 0 and Elites.max_traits(2) == 1 and Elites.max_traits(4) == 2 and Elites.max_traits(9) == 3,
		"elity od 2. poziomu, więcej cech wyżej")
	var rolled := Elites.roll_traits(9)
	_check(rolled.size() >= 2 and rolled.size() <= 3 and rolled[0] != rolled[1], "cechy elity są różne (%s)" % [rolled])
	game.best_level = 4
	game.dungeon_level = 4
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	_check(horde._elite_next >= Elites.FIRST.x, "pierwsza elita po chwili (%.0f s)" % horde._elite_next)
	var e := horde.spawn_elite()
	_check(e.elite != null and e.elite.traits.size() >= 1 and e.elite.traits.size() <= 2, "spawn_elite: elita z cechami (%s)" % [e.elite.traits])
	e.queue_free()
	# tarcza, napis, poświata
	var s: ProtoGoblin = horde.spawn_at(hero.position + Vector2(150, 0), "goblin", ["shield"] as Array[String])
	await process_frame
	await process_frame
	_check(s.hp == roundi(ProtoGoblin.MAX_HP * Elites.HEALTH * horde.power * DungeonLevels.hp_mult(horde.level)), "elita ma więcej zdrowia (%d)" % s.hp)
	_check(s.elite._label != null and s.elite._label.text == "Tarczowy" and s._sprite.material != null, "elita: napis z cechą i poświata")
	var hp := s.hp
	s.take_damage(10, hero.global_position)
	_check(s.hp == hp and s.elite.shield < s.elite.shield_max, "tarcza bierze trafienie")
	s.take_damage(roundi(s.elite.shield_max), hero.global_position)
	_check(s.hp < hp and s.elite.shield == 0.0, "zbita tarcza - obrażenia idą w zdrowie")
	s.elite._since_hit = Elites.SHIELD_DELAY
	await process_frame
	_check(s.elite.shield == s.elite.shield_max, "tarcza wraca po chwili bez obrażeń")
	s.queue_free()
	# szybki
	var f: ProtoGoblin = horde.spawn_at(hero.position + Vector2(150, 0), "goblin", ["fast"] as Array[String])
	_check(is_equal_approx(f.speed, ProtoGoblin.SPEED * Elites.FAST_SPEED), "szybka elita biega szybciej")
	f.queue_free()
	# dowódczy wzmacnia sąsiadów
	var c: ProtoGoblin = horde.spawn_at(hero.position + Vector2(150, 0), "goblin", ["commanding"] as Array[String])
	var near: ProtoGoblin = horde.spawn_at(hero.position + Vector2(170, 0))
	var normal_hit := near.hit_damage()
	await _wait(0.2)
	_check(near._empowered > 0.0 and near.hit_damage() > normal_hit and near.speed_factor() > 1.0, "dowódczy wzmacnia gobliny wokół")
	c.take_damage(100000, hero.global_position)
	near.queue_free()
	# wybuchowy: koło po śmierci, wybuch rani w kole; nagroda
	var kills := [0]
	horde.elite_killed.connect(func(_g: ProtoGoblin) -> void: kills[0] += 1)
	var v: ProtoGoblin = horde.spawn_at(hero.position + Vector2(10, 0), "goblin", ["volatile"] as Array[String])
	await process_frame
	hero.hp = hero.max_hp
	v._cooldown = 99.0
	v.take_damage(100000, hero.global_position)
	await process_frame
	await process_frame
	var circle := false
	var ember := false
	var loot := false
	for n in arena.get_node("World").get_children():
		circle = circle or n is ProtoTelegraph
		ember = ember or (n is ProtoEmber and n.value == Elites.EMBERS)
		loot = loot or n is ProtoLoot
	_check(circle, "wybuchowa elita zostawia koło")
	_check(ember and loot and kills[0] == 1, "nagroda za elitę: duża iskra, przedmiot, doświadczenie")
	await _wait(Elites.VOLATILE_WARN + 0.1)
	_check(hero.hp == hero.max_hp - roundi(Elites.VOLATILE_DAMAGE * horde.power), "wybuch rani w kole (zdrowie %d)" % hero.hp)
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
	_check(g.hp == roundi(ProtoGoblin.MAX_HP * horde.power * DungeonLevels.hp_mult(horde.level)), "goblin ma więcej zdrowia (%d)" % g.hp)
	horde.embers = DungeonLevels.summon_cost(horde.level) + 12
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
	_check(arena.run_items + int(arena.run_ore > 0) >= Items.CHEST_ITEMS and game.bag.size() >= mini(Items.CHEST_ITEMS, game.BAG_SIZE), "przedmioty ze skrzyni w torbie (%d)" % game.bag.size())
	var result: RunResult = arena.result
	_check(result.visible and paused and result._summary.text.contains(tr("Odblokowano: %s") % Dungeons.level_label(3)), "okno zwycięstwa: " + result._summary.text.replace("\n", ", "))
	_check(result.retry_button.text == tr("Dalej: %s") % Dungeons.level_label(3), "przycisk następnego poziomu")
	game.load_game()
	_check(game.best_level == 2, "przebity poziom zapisany")
	paused = false
	arena.queue_free()
	await process_frame

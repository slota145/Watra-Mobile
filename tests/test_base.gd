extends SceneTree
## Test bazy: drzewko lochów w lochu (premie Hordy, łupu, nauki, zasięgu), kowal (Runa Przekucia na premii,
## zużycie runy, zapis przekuć, runy w oknie), kupiec (wymiana run po kursie, rozmiana, klucz i dłuto za runy, brak run,
## zapis), baza (kowal i kupiec otwierają okna, pasek skrótów
## w dolnej połowie, min. 44 px, po drugiej stronie niż przyciski walki), kamera przy brzegu polany, okna (potwierdzenie drugim stuknięciem,
## „Wróć”, „wstecz”, pauza), przycisk drzewka w wyborze poziomu przy Watrze (szczegóły drzewka - test_tree).

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	_test_smith(game)
	_test_shop(game)
	await _test_dungeon(game)
	await _test_base(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_smith(game: Node) -> void:
	var item := Items.roll(4, "ring", "rare")
	game.add_item(item)
	_check(not game.use_rune(game.bag[0], Runes.REFORGE, 0), "bez runy kowal nie przekuje")
	game.add_rune(Runes.REFORGE, 2)
	var before: Array = item.affixes.duplicate(true)
	_check(game.use_rune(game.bag[0], Runes.REFORGE, 1) and game.runes.get(Runes.REFORGE, 0) == 1,
			"Runa Przekucia zużyta")
	var stats: Array = []
	for a in game.bag[0].affixes:
		stats.append(a.stat)
	var unique := true
	for s in stats:
		unique = unique and stats.count(s) == 1
	_check(unique and game.bag[0].affixes.size() == before.size(), "premie bez powtórzeń, ta sama liczba")
	_check(game.bag[0].affixes[0] == before[0] and game.bag[0].affixes[2] == before[2], "inne premie zostają")
	game.use_rune(game.bag[0], Runes.REFORGE, 1)
	game.load_game()
	_check(int(game.bag[0].get("rerolls", 0)) == 2 and not game.runes.has(Runes.REFORGE),
			"przekucia i zużyte runy zapisane")
	game.add_rune(Runes.REFORGE)
	_check(not game.use_rune(game.bag[0], Runes.REFORGE, 9) and game.runes[Runes.REFORGE] == 1, "zła premia - runa zostaje")
	var common := Items.roll(4, "boots", "common")
	_check(not game.use_rune(common, Runes.REFORGE, 0), "zwykły przedmiot nie ma premii do przekucia")
	var many := 0
	for i in 40:
		var r := Items.roll(3, "amulet", "magic")
		Items.reroll_affix(r, 0)
		many += 1 if Items.AFFIXES.has(r.affixes[0].stat) else 0
	_check(many == 40, "nowa premia zawsze z listy premii")
	game.reset_hero()


func _test_shop(game: Node) -> void:
	game.reset_hero()
	var offers: Array = Shop.offers()
	var buys := offers.filter(func(o: Dictionary) -> bool: return o.kind == "buy")
	var changes := offers.filter(func(o: Dictionary) -> bool: return o.kind == "change")
	_check(buys.size() == 5 and changes.size() == 7 and offers.size() == 14, "5 run do kupienia (bez run bossów), 7 do rozmiany, klucz i dłuto")
	_check(Shop.buy_cost(Runes.CHAOS) == 8 and Shop.buy_cost(Runes.REFORGE) == 3 and Shop.buy_cost(Runes.SEAL) == 30,
			"kupno po kursie x1,5 w górę (Zmiana 8, Przekucie 3, Pieczęć 30 Szlifu)")
	var ci := offers.find(changes.filter(func(o: Dictionary) -> bool: return o.pay == Runes.CHAOS)[0])
	var bi := offers.find(buys.filter(func(o: Dictionary) -> bool: return o.item == Runes.CHAOS)[0])
	var ki := offers.find(offers.filter(func(o: Dictionary) -> bool: return o.item == Gems.KEY)[0])
	var di := offers.find(offers.filter(func(o: Dictionary) -> bool: return o.item == Gems.CHISEL)[0])
	_check(game.shop_problem(bi) == "price" and not game.buy_offer(bi), "bez Run Szlifu nie kupi")
	game.add_rune(Runes.POLISH, 10)
	_check(game.buy_offer(bi) and game.runes[Runes.POLISH] == 2 and game.runes[Runes.CHAOS] == 1, "Runa Zmiany za 8 Szlifu")
	_check(game.buy_offer(ci) and game.runes[Runes.POLISH] == 7 and not game.runes.has(Runes.CHAOS), "rozmiana: Zmiana -> 5 Szlifu")
	game.add_rune(Runes.CHAOS, 2)
	game.add_rune(Runes.ASCEND, 1)
	_check(game.buy_offer(ki) and game.gem_count(Gems.KEY) == 1 and not game.runes.has(Runes.CHAOS), "klucz za 2 Runy Zmiany")
	_check(game.buy_offer(di) and game.gem_count(Gems.CHISEL) == 1 and not game.runes.has(Runes.ASCEND), "dłuto za Runę Wyniesienia")
	_check(game.shop_problem(99) == "none", "zła oferta")
	game.load_game()
	_check(game.runes == {Runes.POLISH: 7} and game.gem_count(Gems.CHISEL) == 1, "wymiany zapisane")
	game.reset_hero()
	game.best_level = 0


func _test_dungeon(game: Node) -> void:
	game.best_level = 20
	game.tree = {"horde": 5, "xp": 4, "loot": 5, "reach": 5}
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var horde: ProtoHorde = arena.horde_spawner
	_check(is_equal_approx(horde.density, 1.2) and is_equal_approx(horde.loot_mult, 1.2) and horde.reach == 30.0,
			"loch: gęstość 1,2, łup x1,2, zasięg +30 px")
	_check(is_equal_approx(horde.interval(), ProtoHorde.INTERVAL_START / 1.2) and horde.max_alive() == roundi(ProtoHorde.ALIVE_START * 1.2),
			"gęstsza Horda: częściej i więcej naraz (%d)" % horde.max_alive())
	var xp: int = game.hero_xp
	arena._gain_xp(100)
	_check(game.hero_xp - xp == 116 or game.hero_level > 1, "doświadczenie +16%% (%d)" % (game.hero_xp - xp))
	var loot := horde.drop_item(Items.roll(1), Vector2(500, 500))
	await process_frame
	_check(loot.magnet == ProtoLoot.MAGNET + 30.0, "łup przyciąga się z dalszej odległości")
	# kamera bez granic: przy brzegu polany postać zostaje na środku ekranu
	arena.hero.position = Vector2(-340, 540)
	await _wait(1.5)
	var on_screen: Vector2 = arena.hero.get_global_transform_with_canvas().origin
	_check(on_screen.distance_to(root.get_visible_rect().size / 2.0) < 4.0, "w rogu polany postać na środku ekranu (%s)" % on_screen)
	arena.queue_free()
	await process_frame
	game.tree = {}
	game.best_level = 0
	game.save_game()


func _test_base(game: Node) -> void:
	game.runes = {Runes.POLISH: 10}
	game.embers = 300
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await _wait(0.3)
	_check(arena.smith != null and arena.merchant != null and arena.base_bar != null, "baza: kowal, kupiec i pasek skrótów")
	var view := root.get_visible_rect().size
	var ok := true
	for id in arena.base_bar.buttons:
		var r: Rect2 = arena.base_bar.buttons[id].get_global_rect()
		ok = ok and r.size.x >= 44.0 and r.size.y >= 44.0 and r.get_center().y > view.y * 0.5 and r.get_center().x < view.x * 0.5
	_check(ok, "pasek: 5 ikon min. 44 px w lewej dolnej części ekranu")
	_check(arena.joystick.blocked.has(arena.base_bar.column), "dotyk paska nie rusza gałki")
	# kowal i kupiec otwierają okna stuknięciem
	var screen: Vector2 = arena.smith.get_global_transform_with_canvas() * Vector2(0, -20)
	_check(Rect2(Vector2.ZERO, view).has_point(screen), "kowal widoczny z miejsca startu")
	_touch(screen)
	await process_frame
	_check(arena.smith_window.visible and paused, "stuknięcie w kowala otwiera kowala, gra stoi")
	arena.smith_window.back_button.pressed.emit()
	_check(not arena.smith_window.visible and not paused, "„Wróć” zamyka okno")
	_touch(arena.merchant.get_global_transform_with_canvas() * Vector2(0, -20))
	await process_frame
	_check(arena.shop_window.visible, "stuknięcie w kupca otwiera kupca")
	# wymiana z potwierdzeniem (Runa Przekucia za 3 Szlifu)
	var buy: Button = arena.shop_window.content.find_child("Buy_0", true, false)
	buy.pressed.emit()
	_check(game.runes[Runes.POLISH] == 10 and arena.shop_window.armed == "offer_0", "pierwsze stuknięcie pyta „Na pewno?”")
	buy = arena.shop_window.content.find_child("Buy_0", true, false)
	_check(buy.text == "Na pewno?", "przycisk pyta („%s”)" % buy.text)
	buy.pressed.emit()
	_check(game.runes[Runes.POLISH] == 7 and game.runes.get(Runes.REFORGE, 0) == 1, "drugie stuknięcie wymienia")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not arena.shop_window.visible and not paused, "„wstecz” zamyka kupca")
	# pasek skrótów
	for id in ["smith", "shop", "stash", "skills"]:
		arena.base_bar.buttons[id].pressed.emit()
		await process_frame
		var w: Control = {"smith": arena.smith_window, "shop": arena.shop_window, "stash": arena.stash_window,
				"skills": arena.skills_window}[id]
		_check(w.visible and paused, "pasek: „%s” otwiera okno" % id)
		w.close()
	arena.base_bar.buttons["watra"].pressed.emit()
	_check(arena.picker.visible, "pasek: „Watra” otwiera wybór poziomu")
	# drzewko z wyboru poziomu
	await process_frame
	var up: Button = arena.picker.upgrades_button
	_check(up.get_global_rect().size.y >= 44.0 and up.get_global_rect().get_center().y > view.y * 0.5, "„Drzewko” pod kciukiem")
	up.pressed.emit()
	_check(arena.tree_window.visible and not arena.picker.visible and paused, "„Drzewko” otwiera drzewko lochów")
	arena.tree_window.back_button.pressed.emit()
	_check(arena.picker.visible and paused, "po zamknięciu drzewka wraca wybór poziomu")
	arena.picker.close()
	# kowal: runy w oknie
	game.add_item(Items.roll(3, "ring", "magic"))
	game.runes.erase(Runes.REFORGE)
	game.runes.erase(Runes.ASCEND)
	game.add_rune(Runes.REFORGE)
	game.add_rune(Runes.ASCEND)
	arena.open_smith()
	arena.smith_window.bag_slots[0].pressed.emit()
	_check(arena.smith_window.detail.visible, "stuknięcie przedmiotu otwiera opis z premiami")
	_check(arena.smith_window.detail.find_child("Use_0", true, false) == null, "bez wybranej runy nie ma „Użyj”")
	arena.smith_window.detail.find_child("Rune_" + Runes.REFORGE, true, false).pressed.emit()
	arena.smith_window.detail.find_child("Use_0", true, false).pressed.emit()
	_check(not game.runes.has(Runes.REFORGE) and int(game.bag[0].rerolls) == 1 and arena.smith_window.detail.visible,
			"Runa Przekucia przy premii, opis zostaje")
	arena.smith_window.detail.find_child("Rune_" + Runes.ASCEND, true, false).pressed.emit()
	arena.smith_window.detail.find_child("UseRune", true, false).pressed.emit()
	_check(game.bag[0].rarity == "magic", "runa na cały przedmiot pyta „Na pewno?”")
	arena.smith_window.detail.find_child("UseRune", true, false).pressed.emit()
	_check(game.bag[0].rarity == "rare" and game.bag[0].affixes.size() >= 3 and not game.runes.has(Runes.ASCEND),
			"drugie stuknięcie: przedmiot rzadki, premie dolosowane")
	# wykuwanie z rudy w oknie kowala
	game.ore = 25
	game.best_level = 3
	arena.smith_window._hide_detail()
	arena.smith_window.refresh()
	var fb: Button = arena.smith_window.forge_buttons["boots"]
	_check(not fb.disabled and fb.size.x >= 44.0, "przycisk wykuwania butów aktywny (min. 44 px)")
	var bag_before: int = game.bag.size()
	fb.pressed.emit()
	var bases: Dictionary = arena.smith_window.base_buttons
	_check(game.bag.size() == bag_before and bases.size() == 3 and bases.has("bast"), "miejsce pokazuje 3 bazy do wyboru")
	var bb: Button = bases["bast"]
	bb.pressed.emit()
	bb = arena.smith_window.base_buttons["bast"]
	_check(game.bag.size() == bag_before and bb.text == tr("Wykuć?"), "wykuwanie najpierw pyta")
	bb.pressed.emit()
	_check(game.bag.size() == bag_before + 1 and game.ore == 5 and arena.smith_window.detail.visible
			and arena.smith_window.selected.slot == "boots" and arena.smith_window.selected.type == "bast",
			"drugie stuknięcie wykuwa łapcie i otwiera ich opis")
	_check(arena.smith_window.forge_buttons["ring"].disabled, "bez 20 rudy przyciski nieaktywne")
	arena.smith_window.back()
	_check(not arena.smith_window.detail.visible and arena.smith_window.visible, "„wstecz” najpierw zamyka opis")
	arena.smith_window.back()
	# leworęczni: pasek po prawej
	game.left_handed = true
	arena._apply_settings()
	await process_frame
	_check(arena.base_bar.buttons["shop"].get_global_rect().get_center().x > view.x * 0.5, "leworęczni: pasek po prawej")
	game.left_handed = false
	arena.queue_free()
	await process_frame


func _touch(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = pos
		e.pressed = pressed
		root.push_input(e, true)

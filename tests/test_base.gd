extends SceneTree
## Test bazy: ulepszenia lochów za złoto (ceny 50-1000, premie, zapis, działanie w lochu), kowal (przeróbka jednej premii,
## rosnąca cena, zapis przeróbek), kupiec (półka: klucz, dłuto, 2 różne kamienie 1. stopnia, 3 przedmioty; kupno
## do sakwy i torby, pełna torba, brak złota, nowa dostawa, zapis), baza (kowal i kupiec otwierają okna, pasek skrótów
## w dolnej połowie, min. 44 px, po drugiej stronie niż przyciski walki), kamera przy brzegu polany, okna (potwierdzenie drugim stuknięciem,
## „Wróć”, „wstecz”, pauza), przycisk ulepszeń w wyborze poziomu przy Watrze.

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
	_test_upgrades(game)
	_test_smith(game)
	_test_shop(game)
	await _test_dungeon(game)
	await _test_base(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_upgrades(game: Node) -> void:
	_check(DungeonUpgrades.ORDER.size() == 4 and game.upgrade_price("monsters") == 50, "4 ulepszenia, pierwszy stopień za 50 złota")
	game.gold = 40
	game.embers = 5000
	_check(not game.buy_upgrade("monsters") and game.gold == 40 and game.embers == 5000, "za mało złota - nie kupi (żar nie pomaga)")
	game.gold = 3000
	var prices: Array = []
	while game.upgrade_price("monsters") > 0:
		prices.append(game.upgrade_price("monsters"))
		game.buy_upgrade("monsters")
	_check(prices == [50, 120, 250, 500, 1000] and game.gold == 3000 - 1920 and game.embers == 5000, "stopnie za 50, 120, 250, 500, 1000 złota")
	_check(not game.buy_upgrade("monsters") and game.upgrade_steps("monsters") == 5, "więcej niż 5 stopni się nie kupi")
	_check(game.upgrade_bonus("monsters") == 50.0 and DungeonUpgrades.bonus("xp", 5) == 40.0
			and DungeonUpgrades.bonus("loot", 5) == 50.0 and DungeonUpgrades.bonus("reach", 5) == 40.0,
			"premie: potwory +50%, doświadczenie +40%, łup +50%, zasięg +40 px")
	_check(DungeonUpgrades.text("monsters", 2) == "+20% potworów", "opis premii („%s”)" % DungeonUpgrades.text("monsters", 2))
	game.buy_upgrade("reach")
	game.load_game()
	_check(game.upgrade_steps("monsters") == 5 and game.upgrade_steps("reach") == 1 and game.gold == 3000 - 1970,
			"ulepszenia i złoto zapisane")
	_check(not game.buy_upgrade("nic"), "nieznane ulepszenie")


func _test_smith(game: Node) -> void:
	game.gold = 0
	var item := Items.roll(4, "ring", "rare")
	game.add_item(item)
	var price := Items.reroll_price(item)
	_check(price == roundi(2.0 * Items.sell_price(item)), "pierwsza przeróbka za 2x cenę sprzedaży (%d)" % price)
	_check(not game.reroll(game.bag[0], 0), "bez złota kowal nie przekuje")
	game.gold = 10000
	var before: Array = item.affixes.duplicate(true)
	_check(game.reroll(game.bag[0], 1) and game.gold == 10000 - price, "przeróbka kosztuje złoto")
	var stats: Array = []
	for a in game.bag[0].affixes:
		stats.append(a.stat)
	var unique := true
	for s in stats:
		unique = unique and stats.count(s) == 1
	_check(unique and game.bag[0].affixes.size() == before.size(), "premie bez powtórzeń, ta sama liczba")
	_check(game.bag[0].affixes[0] == before[0] and game.bag[0].affixes[2] == before[2], "inne premie zostają")
	_check(Items.reroll_price(game.bag[0]) == roundi(2.0 * Items.sell_price(item) * 1.5), "następna przeróbka 1,5x droższa")
	game.reroll(game.bag[0], 1)
	game.load_game()
	_check(int(game.bag[0].get("rerolls", 0)) == 2 and Items.reroll_price(game.bag[0]) == roundi(2.0 * Items.sell_price(item) * 2.25),
			"liczba przeróbek zapisana z przedmiotem")
	_check(not game.reroll(game.bag[0], 9), "zła premia")
	var common := Items.roll(4, "boots", "common")
	_check(not game.reroll(common, 0), "zwykły przedmiot nie ma premii do przekucia")
	var many := 0
	for i in 40:
		var r := Items.roll(3, "amulet", "magic")
		Items.reroll_affix(r, 0)
		many += 1 if Items.AFFIXES.has(r.affixes[0].stat) else 0
	_check(many == 40, "nowa premia zawsze z listy premii")
	game.reset_hero()


func _test_shop(game: Node) -> void:
	game.best_level = 4
	var offers: Array = game.shop_offers()
	_check(game.shop_ready and offers.size() == 7, "pierwsze otwarcie: towar na półce (%d)" % offers.size())
	_check(offers[0].get("gem") == Gems.KEY and offers[0].price == 400 and offers[1].get("gem") == Gems.CHISEL
			and offers[1].price == 250, "klucz za 400, dłuto za 250")
	_check(Gems.grade_of(offers[2].gem) == 0 and Gems.grade_of(offers[3].gem) == 0 and offers[2].price == 60
			and Gems.kind_of(offers[2].gem) != Gems.kind_of(offers[3].gem), "2 różne kamienie 1. stopnia po 60")
	var items_ok := true
	for o in offers.slice(4):
		items_ok = items_ok and o.has("item") and o.item.rarity in ["magic", "rare"] and o.item.level == 4 \
				and o.price == Items.sell_price(o.item) * 4
	_check(items_ok, "3 przedmioty magiczne albo rzadkie z lochu 4, za 4x cenę sprzedaży")
	game.gold = 100
	_check(game.shop_problem(0) == "gold" and not game.buy_offer(0), "za mało złota")
	game.gold = 5000
	_check(game.buy_offer(0) and game.gem_count(Gems.KEY) == 1 and game.gold == 4600 and game.shop.size() == 6,
			"klucz kupiony do sakwy, znika z półki")
	var item: Dictionary = game.shop[3].item
	_check(game.buy_offer(3) and game.bag.size() == 1 and game.bag[0] == item, "przedmiot kupiony do torby")
	game.dev_items(30)
	_check(game.shop_problem(3) == "bag" and not game.buy_offer(3), "pełna torba - przedmiotu nie kupi")
	_check(game.buy_offer(0), "dłuto kupi i przy pełnej torbie")
	game.load_game()
	_check(game.shop.size() == 4 and game.shop_ready and game.gem_count(Gems.CHISEL) == 1, "półka zapisana")
	game.restock_shop(2)
	_check(game.shop.size() == 7 and game.shop[4].item.level == 4, "nowa dostawa: pełna półka, przedmioty z najwyższego lochu")
	game.reset_hero()
	game.best_level = 0


func _test_dungeon(game: Node) -> void:
	game.upgrades = {"monsters": 5, "xp": 2, "loot": 3, "reach": 4}
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var horde: ProtoHorde = arena.horde_spawner
	_check(is_equal_approx(horde.density, 1.5) and is_equal_approx(horde.loot_mult, 1.3) and horde.reach == 32.0,
			"loch: gęstość 1,5, łup x1,3, zasięg +32 px")
	_check(is_equal_approx(horde.interval(), ProtoHorde.INTERVAL_START / 1.5) and horde.max_alive() == 12,
			"gęstsza Horda: częściej i więcej naraz (%d)" % horde.max_alive())
	var xp: int = game.hero_xp
	arena._gain_xp(100)
	_check(game.hero_xp - xp == 116 or game.hero_level > 1, "doświadczenie +16%% (%d)" % (game.hero_xp - xp))
	var loot := horde.drop_item(Items.roll(1), Vector2(500, 500))
	await process_frame
	_check(loot.magnet == ProtoLoot.MAGNET + 32.0, "łup przyciąga się z dalszej odległości")
	# kamera bez granic: przy brzegu polany postać zostaje na środku ekranu
	arena.hero.position = Vector2(-340, 540)
	await _wait(1.5)
	var on_screen: Vector2 = arena.hero.get_global_transform_with_canvas().origin
	_check(on_screen.distance_to(root.get_visible_rect().size / 2.0) < 4.0, "w rogu polany postać na środku ekranu (%s)" % on_screen)
	arena.queue_free()
	await process_frame
	game.upgrades = {}
	game.save_game()


func _test_base(game: Node) -> void:
	game.gold = 1000
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
	# zakup z potwierdzeniem (klucz, 400)
	var buy: Button = arena.shop_window.content.find_child("Buy_0", true, false)
	buy.pressed.emit()
	_check(game.gold == 1000 and arena.shop_window.armed == "offer_0", "pierwsze stuknięcie pyta „Na pewno?”")
	buy = arena.shop_window.content.find_child("Buy_0", true, false)
	_check(buy.text == "Na pewno?", "przycisk pyta („%s”)" % buy.text)
	buy.pressed.emit()
	_check(game.gold == 600 and game.gem_count(Gems.KEY) == 1, "drugie stuknięcie kupuje klucz")
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
	# ulepszenia z wyboru poziomu
	await process_frame
	var up: Button = arena.picker.upgrades_button
	_check(up.get_global_rect().size.y >= 44.0 and up.get_global_rect().get_center().y > view.y * 0.5, "„Ulepszenia lochów” pod kciukiem")
	up.pressed.emit()
	_check(arena.upgrades_window.visible and not arena.picker.visible and paused, "„Ulepszenia lochów” otwiera okno ulepszeń")
	var b: Button = arena.upgrades_window.content.find_child("Buy_xp", true, false)
	b.pressed.emit()
	arena.upgrades_window.content.find_child("Buy_xp", true, false).pressed.emit()
	_check(game.upgrade_steps("xp") == 1 and game.gold == 550 and game.embers == 300 and arena.watra.embers_label.text == "Żar Watry: 300",
			"kupno ulepszenia za złoto, żar Watry nietknięty (%d, %d, %s)" % [game.upgrade_steps("xp"), game.gold, arena.watra.embers_label.text])
	arena.upgrades_window.back_button.pressed.emit()
	_check(arena.picker.visible and paused, "po zamknięciu ulepszeń wraca wybór poziomu")
	arena.picker.close()
	# kowal: przeróbka w oknie
	game.add_item(Items.roll(3, "ring", "rare"))
	arena.open_smith()
	arena.smith_window.bag_slots[0].pressed.emit()
	_check(arena.smith_window.detail.visible, "stuknięcie przedmiotu otwiera opis z premiami")
	var gold: int = game.gold
	var rr: Button = arena.smith_window.detail.find_child("Reroll_0", true, false)
	rr.pressed.emit()
	arena.smith_window.detail.find_child("Reroll_0", true, false).pressed.emit()
	_check(game.gold < gold and int(game.bag[0].rerolls) == 1 and arena.smith_window.detail.visible,
			"przeróbka w oknie (drugie stuknięcie), opis zostaje")
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

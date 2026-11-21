extends SceneTree
## Test targu (Market): założenie rynku, nadrabianie czasu (też offline, najwyżej 12 h, cofnięty zegar), błądzenie
## cen w granicach, giełda (kupno i sprzedaż paczek, przesunięcie ceny, opłata, płacenie innymi runami z resztą,
## brak arbitrażu z kupcem), oferty innych graczy (kupno do torby, sakwy i talizmanów, pełna torba), własne oferty
## (wystawienie, sprzedaż w czasie, za drogie się nie sprzedają, zdjęcie), zapis, SSF bez targu, okno w bazie.

var _failed := 0
var _now := 1_000_000.0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	game.market_clock = func() -> float: return _now
	_test_time(game)
	_test_exchange(game)
	_test_listings(game)
	_test_mine(game)
	await _test_window(game)
	game.reset_hero()
	game.ssf = false
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_time(game: Node) -> void:
	game.best_level = 10
	_check(game.market_catch_up() == 0 and not game.market.is_empty() and game.market.listings.size() == Market.LISTINGS,
			"pierwsze otwarcie zakłada rynek z ofertami")
	_now += Market.TICK * 3.5
	_check(game.market_catch_up() == 3, "po 35 minutach 3 chwile rynku")
	_now += 48 * 3600.0
	var n: int = game.market_catch_up()
	_check(n == int(Market.OFFLINE_MAX / Market.TICK) and is_equal_approx(float(game.market.time), _now),
			"offline najwyżej 12 h (%d chwil)" % n)
	_now -= 5000.0
	_check(game.market_catch_up() == 0 and is_equal_approx(float(game.market.time), _now), "cofnięty zegar - nic")
	var ok := true
	for id in Market.COMMODITY_ORDER:
		var base: float = Market.COMMODITIES[id].base
		var p: float = game.market.prices[id]
		ok = ok and p >= base * Market.PRICE_LIMITS.x - 0.001 and p <= base * Market.PRICE_LIMITS.y + 0.001
	_check(ok, "ceny błądzą w granicach 0,5-2x ceny bazowej")
	game.save_game()
	game.market = {}
	game.load_game()
	_check(not game.market.is_empty() and game.market.listings.size() > 0 and game.market.prices.size() == Market.COMMODITY_ORDER.size(),
			"rynek w zapisie")


func _test_exchange(game: Node) -> void:
	game.runes = {Runes.POLISH: 20}
	game.market.prices[Runes.CHAOS] = 5.0
	var cost := Market.ask(5.0, Runes.CHAOS)
	_check(game.market_buy(Runes.CHAOS) and game.runes[Runes.CHAOS] == 1 and game.runes[Runes.POLISH] == 20 - cost
			and game.market.prices[Runes.CHAOS] > 5.0, "kupno Runy Zmiany za %d Szl., cena rośnie" % cost)
	var p: float = game.market.prices[Runes.CHAOS]
	var before: int = game.runes[Runes.POLISH]
	_check(game.market_sell(Runes.CHAOS) and game.runes[Runes.POLISH] == before + Market.bid(p, Runes.CHAOS)
			and not game.runes.has(Runes.CHAOS) and game.market.prices[Runes.CHAOS] < p, "sprzedaż po cenie skupu, cena spada")
	_check(not game.market_sell(Runes.CHAOS), "bez towaru się nie sprzeda")
	game.ore = 25
	_check(game.market_sell("ore") and game.ore == 15, "ruda w paczkach po 10")
	_check(Market.bid(5.0) < Market.ask(5.0), "skup taniej niż kupno (opłata targowa)")
	# brak arbitrażu z kupcem: tanio na targu nie poniżej rozmiany, drogo nie powyżej ceny kupca
	var ok := true
	for id in Runes.ORDER:
		if id == Runes.POLISH:
			continue
		var base: float = Market.COMMODITIES[id].base
		ok = ok and Market.ask(base * Market.PRICE_LIMITS.x, id) >= Runes.value_of(id) \
				and Market.bid(base * Market.PRICE_LIMITS.y, id) < Shop.buy_cost(id)
	_check(ok, "kupiec i targ nie dają Szlifów z niczego")
	# płacenie innymi runami: brakujące Szlify z najtańszej runy po cenie skupu, reszta w Szlifach
	game.runes = {Runes.POLISH: 1, Runes.SEAL: 1, Runes.REFORGE: 2}
	game.market.prices[Runes.REFORGE] = 2.0
	var wealth: int = game.market_wealth()
	_check(wealth == 1 + Market.bid(2.0, Runes.REFORGE) * 2 + Market.bid(game.market.prices[Runes.SEAL], Runes.SEAL),
			"majątek: Szlify i runy po cenie skupu (%d)" % wealth)
	_check(game.market_pay(3) and game.runes.get(Runes.SEAL, 0) == 1 and game.runes.get(Runes.REFORGE, 0) < 2,
			"płaci najpierw najtańszymi runami, Pieczęć zostaje")
	_check(not game.market_pay(9999) and game.runes.get(Runes.SEAL, 0) == 1, "za mało - nic się nie zmienia")


func _test_listings(game: Node) -> void:
	game.runes = {Runes.POLISH: 200}
	game.bag = []
	game.market.listings = [
		{"loot": Items.roll(5, "ring", "rare"), "price": 10, "seller": "Radomir", "age": 0},
		{"loot": {"gem": "ember:2"}, "price": 3, "seller": "Jagna", "age": 0},
		{"loot": {"talisman": Talismans.ORDER[0]}, "price": 12, "seller": "Bolko", "age": 0},
	]
	var ring: Dictionary = game.market.listings[0].loot
	_check(game.market_buy_listing(0) and game.bag == [ring] and game.runes[Runes.POLISH] == 190, "przedmiot kupiony do torby")
	_check(game.market_buy_listing(0) and game.gem_count("ember:2") == 1, "kamień do sakwy")
	_check(game.market_buy_listing(0) and game.talismans.has(Talismans.ORDER[0]), "talizman od razu")
	game.market.listings = [{"loot": Items.roll(5), "price": 4, "seller": "Miłka", "age": 0}]
	while game.bag.size() < game.BAG_SIZE:
		game.add_item(Items.roll(1))
	_check(game.market_listing_problem(0) == "bag" and not game.market_buy_listing(0), "pełna torba - nie kupi przedmiotu")
	game.bag = []
	game.runes = {}
	_check(game.market_listing_problem(0) == "price", "bez run - nie kupi")
	var fair := Market.fair_price({"rarity": "rare", "level": 10})
	_check(fair > Market.fair_price({"rarity": "magic", "level": 10}) and Market.fair_price({"gem": "ember:5"})
			> Market.fair_price({"gem": "ember:1"}), "uczciwa cena rośnie z rzadkością i ulepszeniem")
	var deals := 0
	var state := Market.fresh(10, 0.0)
	state.listings = []
	for i in 200:
		state.listings.append({"loot": Items.roll(5, "ring", "magic"), "price": 1, "seller": "x", "age": 0})
	Market.tick(state, 10)
	deals = 200 - state.listings.size() + mini(Market.NEW_LISTINGS, 200)
	_check(deals > 50, "okazje szybko znikają (%d z 200)" % deals)


func _test_mine(game: Node) -> void:
	game.bag = []
	game.runes = {}
	game.market.news = []
	var item := Items.roll(6, "helmet", "rare")
	item.sockets = ["ember:1"]
	game.add_item(item)
	game.add_gem("rime:2")
	var fair := Market.fair_price(item)
	_check(game.market_list(fair, 0) and game.bag.is_empty() and game.gem_count("ember:1") == 1
			and game.market.mine[0].loot.sockets == [""], "wystawiony przedmiot, kamień z gniazda wraca do sakwy")
	_check(game.market_list(Market.fair_price({"gem": "rime:2"}) * 100, -1, "rime:2") and game.gem_count("rime:2") == 0,
			"wystawiony kamień z sakwy")
	_check(Market.sell_chance(game.market.mine[1]) == 0.0, "za drogo - nikt nie kupi")
	_check(game.market_unlist(1) and game.gem_count("rime:2") == 1 and game.market.mine.size() == 1, "zdjęcie oferty")
	var sold := false
	for i in 100:
		_now += Market.TICK
		game.market_catch_up()
		if game.market.mine.is_empty():
			sold = true
			break
	_check(sold and game.runes.get(Runes.POLISH, 0) == maxi(1, floori(fair * (1.0 - Market.TAX)))
			and game.market.news.size() == 1, "uczciwa oferta sprzedaje się z czasem (Szlify po opłacie, wiadomość)")
	for i in Market.MINE_MAX:
		game.add_item(Items.roll(2))
		game.market_list(1, 0)
	game.add_item(Items.roll(2))
	_check(not game.market_list(1, 0) and game.market.mine.size() == Market.MINE_MAX, "najwyżej %d ofert" % Market.MINE_MAX)
	game.market.mine = []


func _test_window(game: Node) -> void:
	game.runes = {Runes.POLISH: 50}
	game.bag = []
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.3).timeout
	_check(arena.market != null and arena.base_bar.buttons.has("market"), "targ w bazie i na pasku skrótów")
	var view := root.get_visible_rect().size
	var ok := true
	for id in arena.base_bar.buttons:
		var r: Rect2 = arena.base_bar.buttons[id].get_global_rect()
		ok = ok and r.size.y >= 44.0 and r.get_center().y > view.y * 0.5
	_check(ok, "6 ikon paska w dolnej połowie ekranu")
	arena.base_bar.buttons["market"].pressed.emit()
	await process_frame
	var w: MarketWindow = arena.market_window
	_check(w.visible and paused, "ikona targu otwiera okno, gra stoi")
	var buy: Button = w.content.find_child("Buy_" + Runes.REFORGE, true, false)
	var before: int = game.runes[Runes.POLISH]
	buy.pressed.emit()
	_check(game.runes.get(Runes.REFORGE, 0) == 1 and game.runes[Runes.POLISH] < before, "„Kup” na giełdzie")
	w.tab_buttons["listings"].pressed.emit()
	var first: Button = w.content.find_child("Listing_0", true, false)
	_check(first != null, "zakładka „Oferty”")
	w.tab_buttons["mine"].pressed.emit()
	game.add_item(Items.roll(3, "boots", "magic"))
	w.refresh()
	w.content.find_child("Pick_0", true, false).pressed.emit()
	w.content.find_child("Price_1", true, false).pressed.emit()
	w.content.find_child("List", true, false).pressed.emit()
	_check(game.market.mine.size() == 1 and game.bag.is_empty(), "wystawienie z zakładki „Moje”")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not w.visible and not paused, "„wstecz” zamyka targ")
	game.ssf = true
	_check(not game.market_open() and not game.market_buy(Runes.REFORGE) and game.market_catch_up() == 0, "SSF: targ zamknięty")
	w.open()
	_check(w.tab_buttons["mine"].visible == false, "okno SSF bez zakładek")
	w.close()
	game.ssf = false
	arena.queue_free()
	await process_frame

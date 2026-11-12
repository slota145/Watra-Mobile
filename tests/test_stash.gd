extends SceneTree
## Test skrzyni w bazie: zakładki (pierwsza za darmo, kolejne za złoto, najwyżej 5), przenoszenie między torbą
## a skrzynią (pełne miejsca), zapis, skrzynia w bazie otwiera okno (podejście i stuknięcie), okno: zakładki,
## kupno z potwierdzeniem, opis z „Do skrzyni” / „Do torby”, przeciąganie (ItemSlot), „Wszystko do skrzyni”,
## pola 44 px, „wstecz” i pauza gry.

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
	_test_game(game)
	await _test_base(game)
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_game(game: Node) -> void:
	_check(game.stash.size() == 1 and game.next_tab_price() == 100, "na start 1 zakładka, następna za 100")
	_check(not game.buy_stash_tab(), "bez złota nie da się kupić")
	game.gold = 5000
	var prices: Array = []
	while game.next_tab_price() > 0:
		prices.append(game.next_tab_price())
		game.buy_stash_tab()
	_check(prices == [100, 300, 800, 2000] and game.stash.size() == 5 and game.gold == 5000 - 3200, "zakładki za 100, 300, 800, 2000 (zostało %d złota)" % game.gold)
	_check(not game.buy_stash_tab(), "więcej niż 5 zakładek się nie kupi")
	var item := Items.roll(2, "helmet", "rare")
	game.add_item(item)
	_check(game.to_stash(0, 2) and game.bag.is_empty() and game.stash[2] == [item], "z torby do 3. zakładki")
	game.load_game()
	_check(game.stash.size() == 5 and game.stash[2] == [item], "skrzynia w zapisie")
	_check(game.from_stash(2, 0) and game.bag == [item] and game.stash[2].is_empty(), "ze skrzyni do torby")
	for i in game.STASH_TAB_SIZE:
		game.stash[0].append(Items.roll(1))
	_check(not game.to_stash(0, 0) and game.bag.size() == 1, "pełna zakładka nie przyjmuje")
	while game.bag.size() < game.BAG_SIZE:
		game.add_item(Items.roll(1))
	_check(not game.from_stash(0, 0), "pełna torba nie przyjmuje")
	_check(game.stash_all(1) == game.BAG_SIZE and game.bag.is_empty() and game.stash[1].size() == game.STASH_TAB_SIZE, "wszystko do skrzyni")
	game.reset_hero()
	_check(game.stash.size() == 1 and game.stash[0].is_empty(), "postać od nowa czyści skrzynię")


func _test_base(game: Node) -> void:
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var stash: ProtoStash = arena.stash
	var win: StashWindow = arena.stash_window
	_check(stash != null and not win.visible, "skrzynia stoi w bazie")
	arena.hero.position = stash.position + Vector2(0, 18)
	await _wait(0.2)
	_check(win.visible and paused, "podejście otwiera okno skrzyni i zatrzymuje grę")
	_check(win.tab_buttons.size() == 1 and win.buy_button != null and win.buy_button.disabled, "jedna zakładka, kupno nieaktywne bez złota")
	var small := false
	for b in win.stash_slots + win.bag_slots + win.tab_buttons + [win.buy_button, win.stash_all_button, win.back_button]:
		var r: Rect2 = b.get_global_rect()
		small = small or r.size.x < 44.0 or r.size.y < 44.0
	_check(not small, "pola i przyciski co najmniej 44 px")
	_check(win.get_viewport_rect().encloses(win.back_button.get_global_rect()), "okno mieści się na ekranie")
	win.close()
	_check(not paused, "zamknięcie wznawia grę")
	await _wait(0.2)
	_check(not win.visible, "stojąc przy skrzyni okno nie otwiera się od razu ponownie")
	# kupno zakładki z potwierdzeniem
	game.gold = 150
	game.add_item(Items.roll(1, "ring", "magic"))
	game.add_item(Items.roll(1, "boots", "common"))
	game.add_item(Items.roll(1, "armor", "rare"))
	arena.open_stash()
	win.buy_button.pressed.emit()
	_check(game.stash.size() == 1 and win.buy_button.text == tr("Kupić za %d?") % 100, "kupno pyta")
	win.buy_button.pressed.emit()
	_check(game.stash.size() == 2 and win.tab == 1 and game.gold == 50 and win.tab_buttons.size() == 2, "kupiona zakładka 2, otwarta")
	# stuknięcie: opis i „Do skrzyni”
	var ring: Dictionary = game.bag[0]
	win.bag_slots[0].pressed.emit()
	_check(win.detail.visible and win.move_button.text == tr("Do skrzyni") and win.detail_name.text == Items.name_of(ring), "opis z „Do skrzyni”")
	var r: Rect2 = win.move_button.get_global_rect()
	_check(r.position.y > win.get_viewport_rect().size.y / 2.0 and r.size.y >= 44.0, "przycisk w dolnej połowie")
	win.move_button.pressed.emit()
	_check(game.stash[1] == [ring] and game.bag.size() == 2 and win.stash_slots[0].item == ring, "przeniesiony do zakładki 2")
	# przeciąganie: z torby na skrzynię i ze skrzyni do torby
	var boots: Dictionary = game.bag[0]
	var data = win.bag_slots[0]._get_drag_data(Vector2.ZERO)
	_check(win.stash_slots[5]._can_drop_data(Vector2.ZERO, data) and not win.bag_slots[3]._can_drop_data(Vector2.ZERO, data), "przeciąganie tylko na drugą siatkę")
	win.stash_slots[5]._drop_data(Vector2.ZERO, data)
	_check(game.stash[1].has(boots) and not game.bag.has(boots), "przeciągnięty do skrzyni")
	var back_data = win.stash_slots[0]._get_drag_data(Vector2.ZERO)
	win.bag_slots[10]._drop_data(Vector2.ZERO, back_data)
	_check(game.bag.has(ring) and not game.stash[1].has(ring), "przeciągnięty do torby")
	_check(win.bag_slots[19]._get_drag_data(Vector2.ZERO) == null, "puste pole się nie przeciąga")
	# zakładki i „Wszystko do skrzyni”
	win.tab_buttons[0].pressed.emit()
	_check(win.tab == 0 and win.stash_slots[0].item.is_empty(), "przełączenie na zakładkę 1")
	win.stash_all_button.pressed.emit()
	_check(game.bag.is_empty() and game.stash[0].size() == 2 and win.stash_all_button.disabled, "wszystko do skrzyni")
	win.stash_slots[0].pressed.emit()
	_check(win.move_button.text == tr("Do torby"), "w skrzyni - „Do torby”")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not win.detail.visible and win.visible, "„wstecz” zamyka opis")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not win.visible and not paused and not arena.pause_menu.visible, "„wstecz” zamyka okno, bez pauzy")
	arena.queue_free()
	await process_frame
	game.reset_hero()

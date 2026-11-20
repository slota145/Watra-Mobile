extends SceneTree
## Test drzewka lochów (20.11.2026): dane (13 węzłów, rodzice, ikony, opisy), punkty za przebite poziomy lochu,
## dodawanie (zamknięte duże węzły, brak punktów, sufit), cofanie za darmo (ostatni punkt małego węzła zamyka duże),
## zapis, porządek po wczytaniu i zwrot złota za dawne ulepszenia lochów; w lochu: tańsze przyzwanie, więcej złota,
## Wędrowne cele spoza paska żaru; okno (węzły min. 44 px, „+”, „−”, „Od nowa” z potwierdzeniem).

var _failed := 0


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
	_test_data()
	_test_points(game)
	_test_migration(game)
	await _test_dungeon(game)
	await _test_window(game)
	game.reset_hero()
	game.tree = {}
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	var ok := DungeonTree.ORDER.size() == 13
	var small := 0
	for id in DungeonTree.ORDER:
		ok = ok and DungeonTree.icon_of(id) != null and DungeonTree.name_of(id) != "" and DungeonTree.text(id, 1) != ""
		var p := DungeonTree.parent_of(id)
		if p == "":
			small += 1
			ok = ok and DungeonTree.max_of(id) == 5
		else:
			ok = ok and DungeonTree.parent_of(p) == ""
	_check(ok and small == 4, "13 węzłów z ikonami, 4 małe po 5 punktów, duże za małymi")
	_check(DungeonTree.text("horde", 2) == "+8% potworów" and DungeonTree.value("summon", 10) == 20.0
			and DungeonTree.value("horde", 99) == 20.0, "premie i opis („%s”)" % DungeonTree.text("horde", 2))
	_check(DungeonTree.text("wander", 3).begins_with("Co 20 s 15%"), "Wędrowne cele: opis („%s”)" % DungeonTree.text("wander", 3))


func _test_points(game: Node) -> void:
	game.best_level = 3
	game.tree = {}
	_check(game.tree_total() == 3 and game.tree_free() == 3, "3 przebite poziomy - 3 punkty")
	_check(game.tree_add_problem("elites") == "locked" and not game.tree_add("elites"), "duży węzeł zamknięty bez małego")
	_check(game.tree_add("horde") and game.tree_add("elites") and game.tree_add("elites"), "mały węzeł otwiera duży")
	_check(game.tree_free() == 0 and game.tree_add_problem("loot") == "points", "brak wolnych punktów")
	_check(game.tree_add_problem("nic") == "unknown", "nieznany węzeł")
	game.load_game()
	_check(game.tree == {"horde": 1, "elites": 2}, "drzewko zapisane (%s)" % game.tree)
	_check(game.tree_remove("elites") and game.tree_points("elites") == 1 and game.tree_free() == 1, "cofanie punktu za darmo")
	game.tree_remove("horde")
	_check(game.tree.is_empty() and game.tree_free() == 3, "ostatni punkt małego węzła zabiera duże za nim")
	game.best_level = 10
	for i in 5:
		game.tree_add("reach")
	_check(not game.tree_add("reach") and game.tree_add_problem("reach") == "max", "więcej niż 5 punktów się nie da")
	game.tree_reset()
	_check(game.tree.is_empty() and game.tree_free() == 10, "„Od nowa” oddaje wszystkie punkty")


func _test_migration(game: Node) -> void:
	var f := FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"best_level": 2, "gold": 10, "upgrades": {"monsters": 2, "xp": 1},
			"tree": {"horde": 1, "loot": 1, "gold": 1, "nic": 3}}))
	f.close()
	game.load_game()
	_check(game.gold == 10 + 50 + 120 + 50, "dawne ulepszenia lochów wracają złotem (%d)" % game.gold)
	_check(game.tree.is_empty(), "więcej punktów niż przebitych poziomów - drzewko od nowa (%s)" % game.tree)
	f = FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"best_level": 5, "gold": 0, "tree": {"loot": 0, "gold": 2, "xp": 1}}))
	f.close()
	game.load_game()
	_check(game.tree == {"xp": 1} and game.gold == 0, "duży węzeł bez małego się zamyka (%s)" % game.tree)


func _test_dungeon(game: Node) -> void:
	game.best_level = 40
	game.dungeon_level = 1
	game.tree = {"horde": 1, "summon": 10, "loot": 1, "gold": 10, "reach": 1, "wander": 10}
	game.gold = 0
	game.add_gold(100)
	_check(game.gold == 140, "Skarbiec: +40%% złota (%d)" % game.gold)
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	_check(arena._summon_cost() == roundi(DungeonLevels.summon_cost(arena.level) * 0.8),
			"Szybkie przyzwanie: -20%% żaru na Wodza (%d)" % arena._summon_cost())
	var before: int = arena.goals.size()
	for i in 40:  # 50% szans co 20 s
		if arena._wander_goals == 0:
			arena._tick_wander(DungeonTree.WANDER_EVERY + 0.1)
	_check(arena.goals.size() == before + 1 and arena._wander_goals == 1, "Wędrowne cele: cel spoza paska żaru")
	for i in 60:
		arena._tick_wander(DungeonTree.WANDER_EVERY + 0.1)
	_check(arena._wander_goals == DungeonTree.WANDER_MAX, "najwyżej %d wędrowne cele naraz" % DungeonTree.WANDER_MAX)
	arena.queue_free()
	await process_frame
	game.dev_immortal = false
	game.tree = {}


func _test_window(game: Node) -> void:
	game.best_level = 4
	game.tree = {}
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.open_upgrades()
	await process_frame
	var w: DungeonTreeWindow = arena.tree_window
	_check(w.visible and w.currency_label.text == "4", "okno drzewka, 4 wolne punkty (%s)" % w.currency_label.text)
	var sizes_ok := true
	for id in DungeonTree.ORDER:
		var b: Button = w.node_buttons[id]
		sizes_ok = sizes_ok and b.get_global_rect().size.x >= 44.0 * 0.6
	_check(sizes_ok, "węzły duże do stukania")
	w.node_buttons["elites"].pressed.emit()
	_check(w.selected == "elites" and w.plus_button.disabled, "zamknięty węzeł: „+” wyłączony")
	w.node_buttons["horde"].pressed.emit()
	w.plus_button.pressed.emit()
	_check(game.tree_points("horde") == 1 and w.currency_label.text == "3" and not w.minus_button.disabled, "„+” daje punkt")
	w.minus_button.pressed.emit()
	_check(game.tree_points("horde") == 0, "„−” cofa punkt")
	w.plus_button.pressed.emit()
	w.reset_button.pressed.emit()
	_check(game.tree_points("horde") == 1, "„Od nowa” czeka na potwierdzenie")
	w.reset_button.pressed.emit()
	_check(game.tree.is_empty(), "drugie stuknięcie cofa wszystko")
	w.close()
	arena.queue_free()
	await process_frame

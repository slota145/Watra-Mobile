extends SceneTree
## Test Głębin (decyzje autora 26.11.2026): zwykła drabinka 1-55 bez drugiego kręgu, Głębie od Dungeons.DEEP_FROM
## (Głębia N = poziom 55+N, stare zapisy przeliczają się same), losowy loch i losowe modyfikatory (1-3 z Głębią), sufit
## siły przedmiotów 55, drabinka odblokowań, wybór poziomu (Watra do 55, Czarna Watra - Głębie), plansza otwarcia
## Głębin po bossie na 55, Czarna Watra i przycisk „Głębiny” w bazie dopiero po ich otwarciu, napis „Głębia N” w lochu.

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
	_test_data()
	await _test_picker(game)
	await _test_base(game)
	await _test_deep_run(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Dungeons.DEEP_FROM == 56 and Dungeons.cycle_length() == 55 and Dungeons.for_level(55) == Dungeons.TOWER,
			"drabinka 1-55 (ostatnia Wieża Kościeja), Głębiny od 56")
	_check(Dungeons.deep_of(56) == 1 and Dungeons.deep_of(70) == 15 and Dungeons.deep_of(55) == 0
			and Dungeons.level_of_deep(15) == 70, "Głębia N = poziom 55+N (przebity 70 = Głębia 15)")
	_check(Dungeons.level_label(56) == "Głębia 1" and Dungeons.level_label(12) == "Poziom 12", "napisy: Głębia 1, Poziom 12")
	_check(DungeonMods.deep_count(56) == 1 and DungeonMods.deep_count(Dungeons.level_of_deep(10)) == 2
			and DungeonMods.deep_count(Dungeons.level_of_deep(40)) == DungeonMods.DEEP_MAX,
			"losowe modyfikatory: 1 w Głębiach 1-9, 2 od 10, 3 od 20")
	var ok := true
	for i in 30:
		var m := DungeonMods.roll_deep(Dungeons.level_of_deep(25))
		ok = ok and m.size() == 3 and m.size() == {m[0]: 1, m[1]: 1, m[2]: 1}.size()
	_check(ok, "Głębia 25: 3 różne losowe modyfikatory")
	_check(DungeonMods.active(60, ["embers"]).is_empty() and not DungeonMods.active(30, ["embers"]).is_empty(),
			"wybrane modyfikatory nie działają w Głębinach (tam losowe)")
	_check(Items.MAX_LEVEL == 55, "sufit siły przedmiotów - loch 55")
	_check(Unlocks.all().any(func(u: Dictionary) -> bool: return int(u.level) == 56 and str(u.text).contains("Głębiny"))
			and not Unlocks.all().any(func(u: Dictionary) -> bool: return str(u.text).contains("Drugi krąg")),
			"drabinka odblokowań: Głębiny na 56, bez drugiego kręgu")


func _test_picker(game: Node) -> void:
	var p := LevelPicker.new()
	root.add_child(p)
	await process_frame
	p.open(70, 71)
	_check(p.level == 55 and p.max_level == 55 and not p.deep, "Watra: najwyżej poziom 55, nawet z przebitymi Głębiami")
	p.close()
	p.open(30, 71, true)
	_check(p.deep and p.level == 56 and p.min_level == 56 and p.max_level == 71 and p._level_label.text == "Głębia 1"
			and not p.mods_button.visible, "Czarna Watra: Głębie 1-16, napis „Głębia 1”, bez wyboru modyfikatorów")
	p.set_level(70)
	_check(p._level_label.text == "Głębia 15" and p._info.text.contains("losowy"), "Głębia 15: loch losowy")
	p.close()
	p.queue_free()
	var r: RunResult = load("res://scripts/ui/run_result.gd").new()
	root.add_child(r)
	await process_frame
	r.show_victory(55, 100, 56, 10, 60.0)
	_check(r._title.text == "Otwierają się Głębiny!" and r.retry_button.text == "Dalej: Głębia 1",
			"po bossie na 55: plansza „Otwierają się Głębiny!”, dalej Głębia 1")
	r.queue_free()
	await process_frame


func _base(game: Node, best: int) -> Node:
	game.reset_hero()
	game.best_level = best
	game.deep_seen = false
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	return arena


func _test_base(game: Node) -> void:
	var arena := _base(game, 40)
	await process_frame
	_check(arena.deep_watra == null and not arena.base_bar.buttons.deep.visible, "przed Głębinami - bez Czarnej Watry")
	arena.queue_free()
	await process_frame
	arena = _base(game, 55)
	await process_frame
	await process_frame
	var dw: ProtoWatra = arena.deep_watra
	_check(dw != null and dw.deep and dw.news_label.visible and arena.base_bar.buttons.deep.visible,
			"po bossie na 55 - Czarna Watra z „Nowość!” i przycisk „Głębiny”")
	arena.open_deep_picker()
	_check(arena.picker.visible and arena.picker.deep and game.deep_seen and not dw.news_label.visible,
			"Czarna Watra otwiera wybór Głębi, „Nowość!” gaśnie")
	arena.picker.close()
	arena.queue_free()
	await process_frame


func _test_deep_run(game: Node) -> void:
	game.reset_hero()
	game.best_level = 60
	game.dungeon_level = Dungeons.level_of_deep(12)
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	_check(Dungeons.ORDER.has(arena.climate) and arena.mods.size() == 2 and arena.level_label.text == "Głębia 12",
			"Głębia 12: losowy loch (%s), 2 losowe modyfikatory, na pasku „Głębia 12”" % arena.climate)
	arena.queue_free()
	await process_frame

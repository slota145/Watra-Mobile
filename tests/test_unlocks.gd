extends SceneTree
## Test drabinki odblokowań (Unlocks): wpisy z progów systemów (łucznicy, kamienie, cele, lochy, bronie) po kolei,
## co odblokowuje boss danego poziomu, następny próg, znaczek „Nowość!” nad Watrą gaśnie po otwarciu wyboru poziomu,
## nowości i najbliższe odblokowanie w wyborze poziomu, okno „Drabinka” z przycisku i powrót do wyboru, linie w oknie zwycięstwa.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	_test_data()
	await _test_base()
	DirAccess.remove_absolute(root.get_node("Game").save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _texts(entries: Array) -> String:
	return " | ".join(entries.map(func(e: Dictionary) -> String: return e.text))


func _test_data() -> void:
	var all := Unlocks.all()
	var sorted := true
	for i in range(1, all.size()):
		if all[i].beat < all[i - 1].beat:
			sorted = false
	_check(all.size() >= 15 and sorted, "drabinka: %d wpisów po kolei" % all.size())
	_check(_texts(Unlocks.on_beat(DungeonLevels.ARCHER_FROM - 1)).contains("strzelające"), "boss 1. poziomu: łucznicy (%s)" % _texts(Unlocks.on_beat(1)))
	_check(_texts(Unlocks.on_beat(Gems.MIN_LEVEL - 1)).contains("Kamienie"), "kamienie po bossie 2. poziomu")
	var ten := _texts(Unlocks.on_beat(10))
	_check(ten.contains("Zatopione") and ten.contains(Weapons.name_of(Weapons.GLAIVE)), "boss 10.: nowy loch i glewia (%s)" % ten)
	_check(_texts(Unlocks.new_at(DungeonGoals.KINDS["shrine"])).contains("kapliczka"), "nowość na 5. poziomie: kapliczka")
	_check(not _texts(Unlocks.new_at(11)).contains(Weapons.name_of(Weapons.GLAIVE)), "bronie nie są nowością lochu")
	var next := Unlocks.next_after(5)
	_check(not next.is_empty() and next[0].beat == 6, "następny próg po 5.: boss 6. (%s)" % _texts(next))
	_check(Unlocks.has_new(0, 1) and not Unlocks.has_new(1, 1), "nowość: coś odblokowane od ostatniego oglądania")
	for e in all:
		if e.icon == null:
			_check(false, "ikona: %s" % e.text)


func _test_base() -> void:
	var game: Node = root.get_node("Game")
	game.best_level = 10
	game.unlocks_seen = 4
	game.dungeon_level = 10
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	_check(arena.watra.news_label.visible, "znaczek „Nowość!” nad Watrą")
	arena.open_picker()
	await process_frame
	_check(not arena.watra.news_label.visible and game.unlocks_seen == 10, "wybór poziomu gasi znaczek")
	arena.picker.set_level(11)
	var info: String = arena.picker._info.text
	_check(info.contains("Następne odblokowanie po bossie poziomu %d" % Unlocks.next_after(10)[0].beat), "najwyższy poziom: najbliższe odblokowanie\n" + info)
	arena.picker.set_level(5)
	_check(arena.picker._info.text.contains("Nowość:"), "poziom 5: nowość w opisie")
	var ladder: Button = arena.picker.ladder_button
	var view: Vector2 = root.get_visible_rect().size
	_check(ladder.get_global_rect().size.y >= 44.0 and ladder.get_global_rect().get_center().y > view.y * 0.5, "„Drabinka” pod kciukiem")
	ladder.pressed.emit()
	await process_frame
	await process_frame
	_check(arena.unlocks_window.visible and not arena.picker.visible and paused, "„Drabinka” otwiera okno")
	_check(arena.unlocks_window.content.get_child_count() > 15, "okno: wszystkie progi")
	_check(arena.unlocks_window._next_row != null, "okno: wyróżniony następny próg")
	arena.unlocks_window.back_button.pressed.emit()
	await process_frame
	_check(not arena.unlocks_window.visible and arena.picker.visible, "zamknięcie wraca do wyboru poziomu")
	arena.picker.close()
	arena.queue_free()
	await process_frame
	var result := RunResult.new()
	root.add_child(result)
	await process_frame
	result.show_victory(10, 100, 11, 50, 90.0)
	result.add_unlock_lines(Unlocks.on_beat(10))
	_check(result._summary.text.contains("Odblokowano: ") and result._summary.text.contains("Zatopione"), "okno zwycięstwa: co odblokowano")
	result.queue_free()

extends SceneTree
## Test porządku w kamieniach szlachetnych (decyzje autora 27.11.2026): ocena 1-5 gwiazdek (Gems.jewel_quality /
## jewel_stars), lista w sakwie (Game.jewel_list: premia, ocena najwyżej, sortowanie), zakładka „Szlachetne” w oknie
## „Postać” (wiersze z premiami, wybór premii, rozbijanie widocznych) i filtr łupu (LootFilter.jewel_burns).

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
	_test_quality()
	_test_list(game)
	await _test_window(game)
	_test_filter(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


## Kamień o premiach `stats` ([[cecha, część najwyższej wartości]]) z lochu 20.
func _jewel(kind: String, parts: Array) -> String:
	var stats: Array = []
	for p in parts:
		stats.append([p[0], maxf(snappedf(Items.affix_max(p[0], 20) * Gems.JEWEL_MULT * p[1], 0.1), 0.1)])
	return Gems.make_jewel(kind, 20, stats)


func _test_quality() -> void:
	var best := _jewel("ruby", [["damage_pct", 1.0], ["hp", 1.0]])
	var weak := _jewel("ruby", [["damage_pct", 0.1], ["hp", 0.2]])
	_check(Gems.jewel_stars(best) == 5 and Gems.jewel_stars(weak) == 1, "najwyższe premie - 5 gwiazdek, słabe - 1")
	_check(Gems.jewel_quality(best) > Gems.jewel_quality(weak), "ocena rośnie z wartościami premii")
	_check(Gems.jewel_stars(Gems.make("ember")) == 0, "kamień umiejętności bez gwiazdek")
	_check(Gems.jewel_value(best, "hp") > 0.0 and Gems.jewel_value(best, "mana") == 0.0, "wartość wybranej premii")
	_check(Gems.jewel_stat_pool().has("attack_speed_pct") and Gems.jewel_stat_pool().has("protection_pct"),
			"lista premii ze wszystkich szlachetnych")


func _test_list(game: Node) -> void:
	game.gems = {}
	var a := _jewel("ruby", [["damage_pct", 1.0], ["hp", 0.9]])
	var b := _jewel("onyx", [["hp", 0.3], ["regen", 0.3]])
	var c := _jewel("emerald", [["attack_speed_pct", 0.6], ["move_pct", 0.6], ["dodge_pct", 0.6]])
	for id in [a, b, c]:
		game.add_gem(id, 1, false)
	game.add_gem(Gems.make("ember"), 1, false)
	_check(game.jewel_list() == [a, c, b], "domyślnie od najlepszej oceny, bez kamieni umiejętności")
	_check(game.jewel_list("level")[0] == c, "sortowanie po liczbie premii")
	var hp: Array = game.jewel_list("stat", "hp")
	_check(hp == [a, b], "tylko z premią „zdrowie”, od najwyższej")
	_check(game.jewel_list("stars", "", Gems.jewel_stars(b)).has(b) and not game.jewel_list("stars", "", Gems.jewel_stars(b)).has(a),
			"ocena najwyżej - tylko słabsze")


func _test_window(game: Node) -> void:
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var st: HeroStats = arena.stats_window
	st.open()
	st.set_tab("pouch")
	st.pouch_kind_buttons["jewel"].pressed.emit()
	await process_frame
	_check(st.jewel_rows.visible and not st.pouch_grid.visible and st.jewel_rows.get_child_count() == 3,
			"„Szlachetne”: wiersze zamiast siatki (3 kamienie)")
	var shown := false
	for l in st.jewel_rows.find_children("*", "Label", true, false):
		shown = shown or (l as Label).text.contains(Items.stat_text("attack_speed_pct", Gems.jewel_stats(game.jewel_list()[1])[0][1]))
	_check(shown, "w wierszu widać premie kamienia")
	st.jewel_stat_button.pressed.emit()
	_check(st.jewel_stat_window.visible, "„Premia: …” otwiera wybór premii")
	for btn in st.jewel_stat_window.find_children("*", "Button", true, false):
		if btn.has_meta("stat") and btn.get_meta("stat") == "hp":
			btn.pressed.emit()
	await process_frame
	_check(not st.jewel_stat_window.visible and st.jewel_stat == "hp" and st.jewel_sort == "stat"
			and st.jewel_rows.get_child_count() == 2, "wybór „Zdrowie”: 2 kamienie, sortowane po zdrowiu")
	_check(not st.jewel_shatter_button.visible, "bez progu oceny nie ma „Rozbij widoczne”")
	st.jewel_stat = ""
	st.jewel_max_stars = Gems.jewel_stars(game.jewel_list().back())
	st.refresh()
	var count: int = st._pouch_list().size()
	var shards: int = game.shards
	_check(st.jewel_shatter_button.visible and count >= 1, "ocena „do …”: przycisk „Rozbij widoczne”")
	st.jewel_shatter_button.pressed.emit()
	_check(game.jewel_list().size() == 3, "pierwsze stuknięcie tylko pyta")
	st.jewel_shatter_button.pressed.emit()
	_check(game.jewel_list().size() == 3 - count and game.shards > shards, "drugie rozbija widoczne na odpryski")
	st.close()
	arena.queue_free()
	await process_frame


func _test_filter(game: Node) -> void:
	var f := LootFilter.normalize({"on": true, "jewel_stars": 2})
	var weak := _jewel("ruby", [["damage_pct", 0.1], ["hp", 0.2]])
	var good := _jewel("ruby", [["damage_pct", 1.0], ["hp", 1.0]])
	_check(f.jewel_stars == 2 and LootFilter.jewel_burns(f, weak) and not LootFilter.jewel_burns(f, good),
			"filtr łupu: rozbija szlachetne do 2 gwiazdek, dobre zostają")
	_check(not LootFilter.jewel_burns(LootFilter.normalize({"on": false, "jewel_stars": 2}), weak)
			and not LootFilter.jewel_burns(f, Gems.make("ember")), "wyłączony filtr i kamienie umiejętności - zostają")
	_check(LootFilter.normalize({"jewel_stars": 99}).jewel_stars == Gems.MAX_STARS - 1, "próg przycięty (5 gwiazdek zawsze zostaje)")
	game.loot_filter = f

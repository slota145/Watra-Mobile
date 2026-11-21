extends SceneTree
## Test drabinki odblokowań (Unlocks) i modyfikatorów lochów (DungeonMods - na końcu pliku): wpisy z progów systemów (łucznicy, kamienie, cele, lochy, bronie) po kolei,
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
	await _test_mods()
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
	_check(ten.contains("Katakumby") and ten.contains(Weapons.name_of(Weapons.GLAIVE)), "boss 10.: nowy loch i glewia (%s)" % ten)
	var cycle := _texts(Unlocks.on_beat(Dungeons.cycle_length()))
	_check(cycle.contains("Drugi krąg"), "po ostatnim lochu: drugi krąg (%s)" % cycle)
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
	_check(result._summary.text.contains("Odblokowano: ") and result._summary.text.contains("Katakumby"), "okno zwycięstwa: co odblokowano")
	result.queue_free()


## Modyfikatory: od 20. poziomu, okno z przełącznikami z wyboru poziomu (zapis), w lochu: szybsze i silniejsze
## potwory, podwójny żar, gęstszy tłum, więcej łupu, rzadki łup, elity częściej, nazwy pod paskami.
func _test_mods() -> void:
	var game: Node = root.get_node("Game")
	_check(DungeonMods.active(19, DungeonMods.ORDER).is_empty() and DungeonMods.active(20, ["embers"]) == ["embers"],
			"modyfikatory działają od 20. poziomu")
	_check(_texts(Unlocks.on_beat(DungeonMods.FROM_LEVEL - 1)).contains("Modyfikatory"), "drabinka: modyfikatory po bossie 19.")
	game.best_level = 25
	game.dungeon_level = 20
	game.dungeon_mods = []
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await process_frame
	base.open_picker()
	base.picker.set_level(19)
	_check(not base.picker.mods_button.visible, "poziom 19: bez przycisku modyfikatorów")
	base.picker.set_level(20)
	_check(base.picker.mods_button.visible, "poziom 20: przycisk „Modyfikatory”")
	base.picker.mods_button.pressed.emit()
	await process_frame
	_check(base.mods_window.visible and not base.picker.visible, "przycisk otwiera okno modyfikatorów")
	for id in DungeonMods.ORDER:
		base.mods_window.toggle(id)
	_check(game.dungeon_mods.size() == 4, "włączone wszystkie cztery")
	base.mods_window.toggle("embers")
	base.mods_window.toggle("embers")
	base.mods_window.back_button.pressed.emit()
	await process_frame
	_check(base.picker.visible and base.picker._info.text.contains(DungeonMods.name_of("blood_moon")), "wybór poziomu pokazuje włączone")
	base.picker.close()
	base.queue_free()
	await process_frame
	game.load_game()
	_check(game.dungeon_mods.size() == 4, "modyfikatory w zapisie")

	# bez modyfikatorów - punkt odniesienia
	game.dungeon_mods = []
	var plain: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(plain)
	await process_frame
	plain.horde_spawner.running = false
	var g0: ProtoGoblin = plain.horde_spawner.spawn_at(plain.hero.position + Vector2(200, 0))
	var speed0 := g0.speed
	var dmg0 := g0.hit_damage()
	var density0: float = plain.horde_spawner.density
	var loot0: float = plain.horde_spawner.loot_mult
	plain.queue_free()
	await process_frame
	game.dungeon_mods = DungeonMods.ORDER.duplicate()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	var g: ProtoGoblin = horde.spawn_at(arena.hero.position + Vector2(200, 0))
	_check(is_equal_approx(g.speed, speed0 * 1.25), "Żarliwa Horda: potwory szybsze (%.0f -> %.0f)" % [speed0, g.speed])
	_check(g.hit_damage() == roundi(dmg0 * 1.5) or absi(g.hit_damage() - roundi(dmg0 * 1.5)) <= 1, "Krwawy księżyc: +50%% obrażeń (%d -> %d)" % [dmg0, g.hit_damage()])
	_check(horde.rare_loot, "Krwawy księżyc: rzadszy łup")
	_check(is_equal_approx(horde.density, density0 * 1.5) and is_equal_approx(horde.loot_mult, loot0 * 1.3), "Gromada: tłum x1,5, łup +30%")
	_check(is_equal_approx(horde.elite_rate, 2.0), "Dwór elit: elity dwa razy częściej")
	var before := horde.embers
	horde._on_ember(10)
	_check(horde.embers - before == floori(10 * DungeonLevels.ember_value(20) * 2.0 * horde.ember_mult),
			"Żarliwa Horda: podwójny żar (+%d)" % (horde.embers - before))
	_check(arena.mods_label.visible and arena.mods_label.text.contains(DungeonMods.name_of("elites")), "nazwy modyfikatorów pod paskami")
	arena.queue_free()
	await process_frame
	game.dungeon_mods = []

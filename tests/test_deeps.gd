extends SceneTree
## Test Głębin (decyzje autora 26.11.2026): zwykła drabinka 1-55 bez drugiego kręgu, Głębie od Dungeons.DEEP_FROM
## (Głębia N = poziom 55+N, stare zapisy przeliczają się same), losowy loch i losowe modyfikatory (1-3 z Głębią), sufit
## siły przedmiotów 55, drabinka odblokowań, wybór poziomu (Watra do 55, Czarna Watra - Głębie), plansza otwarcia
## Głębin po bossie na 55, Czarna Watra i przycisk „Głębiny” w bazie dopiero po ich otwarciu, napis „Głębia N” w lochu.
## Krok 2: zestawy Głębin (DeepRuns - tło, każda rola z innego lochu, losowy boss, jedna mechanika, para odporności),
## zapis zestawu, przelosowanie za Odłamki Nawii, wyprawa z zestawem. Krok 3: nagrody Głębin (lepszy łup i premie
## ponad widełki z Głębią, trudny zestaw - więcej łupu i żaru, Odłamki Nawii z bossa, kamień milowy co 5 Głębi).

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
	_test_rolls(game)
	_test_rewards()
	await _test_roll_run(game)
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
	_check(p._level_label.text == "Głębia 15" and p._info.text.contains("Boss:") and p._info.text.contains("Mechanika:")
			and p.reroll_button.visible, "Głębia 15: zestaw (boss, mechanika) i przycisk „Przelosuj”")
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


func _test_rolls(game: Node) -> void:
	var ok := true
	for i in 40:
		var r := DeepRuns.roll(60)
		ok = ok and DeepRuns.valid(r) and r.goblin != r.archer and r.archer != r.brute and r.goblin != r.brute \
				and r.up != r.down and DeepRuns.MECHANICS.has(r.mechanic)
	_check(ok, "zestaw: każda rola z innego lochu, mechanika z lochów z mechaniką, dwa różne żywioły odporności")
	_check(DeepRuns.reroll_cost(Dungeons.level_of_deep(3)) == 1 and DeepRuns.reroll_cost(Dungeons.level_of_deep(10)) == 2,
			"przelosowanie: 1 odłamek, od Głębi 10 - 2")
	game.reset_hero()
	var a: Dictionary = game.deep_roll(60)
	_check(game.deep_roll(60) == a, "zestaw Głębi stały aż do wejścia")
	game.nawia_shards = 0
	_check(not game.reroll_deep(60) and game.deep_roll(60) == a, "bez odłamków nie da się przelosować")
	var seen_new := false
	for i in 5:
		game.nawia_shards = 10
		game.reroll_deep(60)
		seen_new = seen_new or game.deep_roll(60) != a
	_check(seen_new and game.nawia_shards == 10 - DeepRuns.reroll_cost(60), "przelosowanie: nowy zestaw za Odłamki Nawii")
	game.save_game()
	var kept: Dictionary = game.deep_roll(60)
	game.load_game()
	_check(game.deep_roll(60) == kept and game.nawia_shards == 10 - DeepRuns.reroll_cost(60),
			"zestaw i odłamki przechodzą zapis gry")
	var taken: Dictionary = game.take_deep_roll(60)
	_check(taken == kept and not game.deep_rolls.has("60"), "wejście zużywa zestaw")


func _test_roll_run(game: Node) -> void:
	game.reset_hero()
	game.best_level = 60
	var lvl := Dungeons.level_of_deep(3)
	game.dungeon_level = lvl
	game.deep_rolls[str(lvl)] = {"level": lvl, "ground": Dungeons.FROST, "goblin": Dungeons.TEMPLE,
			"archer": Dungeons.MINE, "brute": Dungeons.TOWER, "boss": Dungeons.FOREST, "mechanic": Dungeons.MINE,
			"mods": [], "up": Elements.FIRE, "down": Elements.COLD}
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	_check(arena.climate == Dungeons.FROST and arena.rockfall != null and arena.frost == null and arena.mods.is_empty(),
			"zestaw: tło Lodowe jaskinie, mechanika Osuwiska (bez wymarzania)")
	var g := horde.spawn_at(Vector2(100, 0), "goblin")
	var ar := horde.spawn_at(Vector2(120, 0), "archer")
	var br := horde.spawn_at(Vector2(140, 0), "brute")
	_check(g is ProtoPoludnica and ar is ProtoProcarz and br is ProtoRuneGolem,
			"potwory z trzech lochów: Południca, karzeł-procarz, runiczny golem")
	var base := DungeonLevels.base_resist(lvl)
	_check(is_equal_approx(g.resists[Elements.FIRE], base + DeepRuns.RESIST)
			and is_equal_approx(g.resists[Elements.COLD], base - DeepRuns.RESIST), "odporności z zestawu: ogień +20%, lód -20%")
	_check(arena.summon_button.text == "Przyzwij Leszego", "boss z zestawu: Leszy")
	arena.mods.assign(["crowd", "elites"])
	arena._apply_upgrades()
	_check(is_equal_approx(horde.loot_mult, DungeonMods.mult(arena.mods, "loot") * DeepRuns.hard_mult(2)
			* (1.0 + game.tree_value("loot") / 100.0)), "trudny zestaw: łup x%.2f" % DeepRuns.hard_mult(2))
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	_check(arena.chief is ProtoLeszy and is_equal_approx(arena.chief.resists[Elements.FIRE], base + DeepRuns.RESIST),
			"przyzwany Leszy z odpornościami zestawu")
	game.nawia_shards = 0
	arena.victory()
	_check(game.nawia_shards == DeepRuns.boss_shards(lvl, 2) and arena.result._summary.text.contains("Odłamki Nawii"),
			"zwycięstwo w Głębi: odłamki Nawii (%d)" % game.nawia_shards)
	paused = false
	arena.queue_free()
	await process_frame


func _test_rewards() -> void:
	var l55 := Dungeons.DEEP_FROM - 1
	var d20 := Dungeons.level_of_deep(20)
	_check(Items.legend_chance(d20) > Items.legend_chance(l55) and Items.unique_chance(d20) > Items.unique_chance(l55)
			and Items.deep_loot(l55) == 1.0, "Głębia 20: większa szansa na legendy i unikaty")
	_check(Items.above_chance(d20) > Items.above_chance(l55) and Items.above_chance(Dungeons.level_of_deep(500)) == Items.ABOVE_DEEP_MAX,
			"premie ponad widełki częściej z Głębią (z sufitem)")
	_check(DeepRuns.boss_shards(Dungeons.level_of_deep(12), 2) == DeepRuns.SHARDS_BASE + 2 + 2
			and is_equal_approx(DeepRuns.hard_mult(3), 1.0 + 3 * DeepRuns.HARD_BONUS),
			"odłamki za bossa (Głębia, modyfikatory), trudny zestaw - więcej łupu")
	_check(DeepRuns.is_milestone(Dungeons.level_of_deep(5)) and DeepRuns.is_milestone(Dungeons.level_of_deep(10))
			and not DeepRuns.is_milestone(Dungeons.level_of_deep(7)) and not DeepRuns.is_milestone(50),
			"kamienie milowe: Głębia 5, 10...")
	var ok := true
	for i in 20:
		var it := DeepRuns.milestone_item(Dungeons.level_of_deep(5))
		ok = ok and (it.rarity == "legendary" or it.rarity == "unique")
	_check(ok, "kamień milowy: zawsze legenda albo unikat")

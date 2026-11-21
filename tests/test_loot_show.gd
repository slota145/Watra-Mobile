extends SceneTree
## Test pokazu łupu (przebudowa przedmiotów krok 4, 21.11.2026): siła przedmiotu i strzałka „lepszy”, słupy światła
## według rzadkości, gwiazdka przy premii ponad widełki, napis i strzałka przy krawędzi dla legendy i unikatu.

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
	_test_score()
	await _test_ground(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_score() -> void:
	var weak := Items.roll(10, "ring", "magic", Items.GOBLIN_WEIGHTS, "", false)
	var strong := Items.roll(40, "ring", "legendary", Items.GOBLIN_WEIGHTS, "", false)
	_check(Items.score(strong) > Items.score(weak), "legenda z lochu 40 silniejsza od magicznego z 10")
	_check(Items.is_upgrade(weak, {}), "puste miejsce - zawsze lepszy")
	_check(Items.is_upgrade(strong, weak) and not Items.is_upgrade(weak, strong), "porównanie siły")
	var above := weak.duplicate(true)
	Items.make_above(above, 0)
	_check(Items.score(above) > Items.score(weak), "premia ponad widełki podnosi siłę")
	var uniq := Items.make_unique("strzybog", 20)
	_check(Items.is_upgrade(uniq, strong) and not Items.is_upgrade(uniq, Items.make_unique("strzybog", 30))
			and not Items.is_upgrade(strong, uniq), "unikat: lepszy, chyba że ten sam; założonego unikatu nic nie zastępuje")


func _test_ground(game: Node) -> void:
	game.dungeon_level = 20
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.3).timeout
	arena.horde_spawner.running = false
	var hero: ProtoHero = arena.hero
	var at := hero.position + Vector2(200, 0)  # daleko - postać nie podnosi
	var common: ProtoLoot = arena.horde_spawner.drop_item(Items.roll(20, "helmet", "common"), at)
	var rare: ProtoLoot = arena.horde_spawner.drop_item(Items.roll(20, "boots", "rare"), at)
	var legend: ProtoLoot = arena.horde_spawner.drop_item(Items.roll(20, "ring", "legendary"), at)
	var uniq: ProtoLoot = arena.horde_spawner.drop_item(Items.make_unique("licho", 20), at)
	for l in [common, rare, legend, uniq]:
		l.magnet = 0.0
	await process_frame
	var beam := func(l: ProtoLoot) -> Node:
		for c in l.get_children():
			if "height" in c and "sparks" in c:
				return c
		return null
	_check(beam.call(common) == null and beam.call(rare) != null, "zwykły bez słupa, rzadki ze słupem")
	_check(beam.call(legend).height > beam.call(rare).height and beam.call(legend).sparks and not beam.call(legend).pulse,
			"legenda: wyższy słup z iskrami")
	_check(beam.call(uniq).pulse and beam.call(uniq).color == Items.RARITY_COLORS.unique, "unikat: słup pulsuje, jego kolor")
	_check(legend.is_in_group(GoalArrows.GROUP) and uniq.is_in_group(GoalArrows.GROUP)
			and not rare.is_in_group(GoalArrows.GROUP), "strzałka przy krawędzi tylko dla legendy i unikatu")
	_check(arena.banner.visible and arena.banner.text.contains(Items.name_of(uniq.item)), "napis na środku: %s" % arena.banner.text)
	_check(common.is_better() and uniq.is_better(), "puste miejsca - strzałka „lepszy”")
	game.equipped = {"ring": Items.make_unique("strzybog", 20)}
	game.inventory_changed.emit()
	await process_frame
	_check(not legend.is_better(), "założony unikat - legenda nie ma strzałki")
	var above_item := Items.roll(20, "amulet", "rare")
	Items.make_above(above_item, 0)
	var shiny: ProtoLoot = arena.horde_spawner.drop_item(above_item, at)
	shiny.magnet = 0.0
	await process_frame
	var star := false
	for c in shiny.get_children():
		star = star or "EVERY" in c
	_check(star, "premia ponad widełki - gwiazdka")
	uniq._take()
	await process_frame
	_check(not uniq.goal_active(), "podniesiony unikat - koniec strzałki przy krawędzi")
	arena.queue_free()
	await process_frame

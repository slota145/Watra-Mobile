extends SceneTree
## Symulacja wyprawy: postać stoi z auto atakiem (nieśmiertelna), Horda płynie jak w grze. Co 15 s wypisuje,
## ile potworów żyje, ile zabito i ile żaru zebrano, oraz kiedy uzbierało się SUMMON_COST żaru na bossa.
## Użycie: godot --headless --path . -s res://tools/crowd_sim.gd -- [poziom lochu] [sekundy]


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var level := int(args[0]) if args.size() > 0 else 1
	var seconds := float(args[1]) if args.size() > 1 else 120.0
	var game: Node = root.get_node("Game")
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = true
	var boss_at := -1.0
	var next_print := 15.0
	while horde.time < seconds:
		await process_frame
		if boss_at < 0.0 and horde.embers >= DungeonLevels.SUMMON_COST:
			boss_at = horde.time
		if horde.time >= next_print:
			next_print += 15.0
			print("CZAS %3.0f s: żyje %d (limit %d), zabito %d, żar %d" % [horde.time, horde._alive, horde.max_alive(), horde.kills, horde.embers])
	print("ŻAR NA BOSSA (%d): %s" % [DungeonLevels.SUMMON_COST, ("po %.0f s" % boss_at) if boss_at >= 0.0 else "nie uzbierano"])
	quit()

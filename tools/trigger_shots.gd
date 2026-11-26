extends SceneTree
## Zrzuty kamieni „rzuć, gdy…”: walka w lochu, w której widmowe kopie miecza (Stypa w Rzucie mieczem) i glewii
## zapasowej (Stypa w Ognistym zamachu) same rzucają umiejętności; trzy klatki z widoczną kopią.
## Użycie: SCRIPT=tools/trigger_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1.png, _2.png, _3.png

var _prefix := "/tmp/trigger"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	game.hero_level = 20
	game.best_level = 12
	game.dev_immortal = true
	game.auto_attack = true
	game.dungeon_level = 1
	game.dev_skills()
	game.mastery["glaive"] = 10
	game.set_spare("glaive")
	game.add_gem(Gems.make("cast_kill", 10), 2, false)
	game.socket_skill("throw", 0, Gems.make("cast_kill", 10))
	game.socket_skill("g_sweep", 0, Gems.make("cast_kill", 10))
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	var shots := 0
	var t := 0.0
	while shots < 3 and t < 40.0:
		await process_frame
		t += 1.0 / 60.0
		for w: String in arena.ghosts:
			if arena.ghosts[w].modulate.a > 0.55:
				await RenderingServer.frame_post_draw
				shots += 1
				root.get_texture().get_image().save_png("%s_%d.png" % [_prefix, shots])
				await create_timer(0.7).timeout
				break
	game.dev_immortal = false
	game.auto_attack = false
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

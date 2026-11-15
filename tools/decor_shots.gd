extends SceneTree
## Zrzuty wystroju lochów (ProtoDecor): po jednym kadrze z Leża goblinów, Zatopionych podziemi i Katakumb (bez potworów).
## Użycie: SCRIPT=tools/decor_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_goblins.png, _flooded.png, _catacombs.png

var _prefix := "/tmp/wystroj"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node("Game")
	for pair in [[1, "goblins"], [11, "flooded"], [21, "catacombs"]]:
		game.best_level = pair[0]
		game.dungeon_level = pair[0]
		var arena: Node = load("res://scenes/horde.tscn").instantiate()
		root.add_child(arena)
		await process_frame
		arena.horde_spawner.running = false
		arena.hero.immortal = true
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, pair[1]])
		arena.queue_free()
		await process_frame
	quit()

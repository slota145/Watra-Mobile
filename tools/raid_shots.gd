extends SceneTree
## Zrzuty Napadu Hordy (cel na mapie lochu): obóz pod słupem światła i napad z kręgiem i falami potworów.
## Użycie: SCRIPT=tools/raid_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_oboz.png, _2_napad.png

var _prefix := "/tmp/napad"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.best_level = 6
	game.dungeon_level = 6
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	hero.immortal = true
	arena.weapon.auto_attack = false
	arena.horde_spawner.running = false
	var camp: ProtoRaid = arena.spawn_goal("raid")
	camp.position = hero.position + Vector2(10, -130)
	await create_timer(0.8).timeout
	await _shot("1_oboz")
	hero.position = camp.position + Vector2(-20, 30)
	await create_timer(3.0).timeout
	await _shot("2_napad")
	DirAccess.remove_absolute(game.save_path)
	quit()

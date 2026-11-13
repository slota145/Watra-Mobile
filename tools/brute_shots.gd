extends SceneTree
## Zrzuty goblina osiłka do oceny wyglądu: zamach maczugą z czerwonym kołem na ziemi i uderzenie w ziemię.
## Użycie: SCRIPT=tools/brute_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_zamach.png, _2_uderzenie.png

var _prefix := "/tmp/osilek"


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
	game.best_level = 3
	game.dungeon_level = 3
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, 80)]:
		horde.spawn_at(hero.position + p)
	horde.spawn_at(hero.position + Vector2(-110, -90), "archer")
	var b := horde.spawn_at(hero.position + Vector2(24, -10), "brute") as ProtoGoblinBrute
	b._cooldown = 0.0
	await create_timer(0.75).timeout
	await _shot("1_zamach")
	await create_timer(0.35).timeout
	await _shot("2_uderzenie")
	quit()

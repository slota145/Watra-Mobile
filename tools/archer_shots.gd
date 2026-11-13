extends SceneTree
## Zrzuty goblina łucznika do oceny wyglądu: łucznicy w tłumie goblinów, naciąganie z linią celu, strzała w locie.
## Użycie: SCRIPT=tools/archer_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_celuje.png, _2_strzala.png

var _prefix := "/tmp/lucznik"


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
	game.best_level = 2
	game.dungeon_level = 2
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-40, -50), Vector2(50, -30), Vector2(-60, 40), Vector2(30, 60)]:
		horde.spawn_at(hero.position + p * 1.6)
	var a := horde.spawn_at(hero.position + Vector2(90, -60), true) as ProtoGoblinArcher
	var b := horde.spawn_at(hero.position + Vector2(-100, 30), true) as ProtoGoblinArcher
	a._cooldown = 0.0
	b._cooldown = 0.25
	await create_timer(0.5).timeout
	await _shot("1_celuje")
	await create_timer(0.45).timeout
	await _shot("2_strzala")
	quit()

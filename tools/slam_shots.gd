extends SceneTree
## Zrzuty Rozłupania Ziemi (szlif 19.11.2026): uderzenie miecza, pęknięcie w ziemi i skalne kolce wzdłuż niego.
## Użycie: SCRIPT=tools/slam_shots.gd tools/screenshot.sh <prefiks>. Pliki: <prefiks>_1_uderzenie.png, _2_kolce.png, _3_koniec.png

var _prefix := "/tmp/rozlupanie"


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
	game.best_level = 20
	game.dungeon_level = 3
	game.set_weapon("sword")
	game.dev_skills()
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	var hero: ProtoHero = arena.hero
	hero.immortal = true
	arena.horde_spawner.running = false
	var weapon: ProtoWeapon = arena.weapon
	hero.mana = 999
	for p in [Vector2(45, 0), Vector2(80, 12), Vector2(110, -6), Vector2(140, 8), Vector2(165, -4), Vector2(60, -40)]:
		var g: ProtoGoblin = arena.horde_spawner.spawn_at(hero.position + p)
		g._stunned = 60.0
		g.hp = 1000000
	await create_timer(0.2).timeout
	weapon.cast("slam")
	await create_timer(ProtoWeapon.SLAM_RISE + ProtoWeapon.SLAM_FALL + 0.05).timeout
	await _shot("1_uderzenie")
	await create_timer(0.2).timeout
	await _shot("2_kolce")
	await create_timer(0.3).timeout
	await _shot("3_koniec")
	DirAccess.remove_absolute(game.save_path)
	quit()

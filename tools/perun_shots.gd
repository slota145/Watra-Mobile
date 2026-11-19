extends SceneTree
## Zrzuty Sądu Peruna (szlif 19.11.2026): cięcie w linii i gromy z nieba wzdłuż niego.
## Użycie: SCRIPT=tools/perun_shots.gd tools/screenshot.sh <prefiks>. Pliki: <prefiks>_1_ciecie.png, _2_gromy.png, _3_ostatni.png

var _prefix := "/tmp/perun"


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
	game.set_weapon("katana")
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
	for p in [Vector2(50, -10), Vector2(90, 15), Vector2(130, -5), Vector2(170, 10), Vector2(110, -40)]:
		var g: ProtoGoblin = arena.horde_spawner.spawn_at(hero.position + p)
		g._stunned = 60.0
		g.hp = 1000000
	await create_timer(0.2).timeout
	weapon.charge_held = true
	weapon.cast("k_perun")
	await create_timer(1.6).timeout
	weapon.charge_held = false
	await create_timer(0.06).timeout
	await _shot("1_ciecie")
	await create_timer(0.27).timeout
	await _shot("2_gromy")
	await create_timer(0.25).timeout
	await _shot("3_ostatni")
	DirAccess.remove_absolute(game.save_path)
	quit()

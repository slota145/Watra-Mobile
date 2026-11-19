extends SceneTree
## Zrzuty Tańca ostrza katany (przebudowa 19.11.2026): cienkie proste linie cięć w trakcie tańca i chwila wybuchu
## grubych cięć. Użycie: SCRIPT=tools/dance_shots.gd tools/screenshot.sh <prefiks>
## Pliki: <prefiks>_1_linie.png, _2_wybuch.png

var _prefix := "/tmp/taniec"


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
	weapon.hero.mana = 999
	for p in [Vector2(40, -15), Vector2(70, 12), Vector2(100, -8), Vector2(60, -40), Vector2(120, 25)]:
		var g: ProtoGoblin = arena.horde_spawner.spawn_at(hero.position + p)
		g._stunned = 60.0
		g.hp = 1000000
	await create_timer(0.2).timeout
	weapon._aim = 0.0
	hero.facing = Vector2.RIGHT
	weapon._start("k_dance")
	await create_timer(ProtoKatana.DANCE_EVERY * 4.6).timeout
	await _shot("1_linie")
	await create_timer(ProtoKatana.DANCE_BURST_DELAY + 0.12).timeout
	await _shot("2_wybuch")
	DirAccess.remove_absolute(game.save_path)
	quit()

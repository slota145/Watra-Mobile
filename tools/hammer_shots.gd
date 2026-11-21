extends SceneTree
## Zrzuty młota w lochu: wzniesiony młot i uderzenie, rzut (w locie), skok (w powietrzu i krater z Grzęzawiskiem),
## trzęsienie ziemi, Rozłupanie Ziemi młotem, potem miecz z Widmowymi ostrzami (krążą i tną).
## Użycie: SCRIPT=tools/hammer_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_wzniesiony.png, _2_uderzenie.png, _3_rzut.png, _4_skok.png, _5_krater.png, _6_trzesienie.png,
## _7_rozlupanie.png, _8_ostrza.png, _9_ostrza_tna.png

var _prefix := "/tmp/mlot"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 500.0
	g.position = at
	arena.get_node("World").add_child(g)
	g._stunned = 600.0
	return g


func _arena(game: Node, weapon: String) -> Node:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 30
	game.dungeon_level = 7
	game.set_weapon(weapon)
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	arena.weapon.auto_attack = false
	arena.hero.position = Vector2.ZERO
	return arena


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	var arena: Node = await _arena(game, "hammer")
	var hero: ProtoHero = arena.hero
	var hammer := arena.weapon as ProtoHammer
	for p in [Vector2(34, -6), Vector2(40, 22), Vector2(-60, 50), Vector2(90, -60), Vector2(-90, -40), Vector2(110, 40)]:
		_goblin(arena, p)
	await create_timer(0.5).timeout
	hammer._attack()
	await create_timer(0.17).timeout
	await _shot("1_wzniesiony")
	await create_timer(0.12).timeout
	await _shot("2_uderzenie")
	await create_timer(0.8).timeout
	hero.mana = hero.max_mana
	hammer.reset_cooldowns()
	hammer.cast("m_throw")
	await create_timer(0.3).timeout
	await _shot("3_rzut")
	await create_timer(1.6).timeout
	hammer.skill_gems["m_leap"] = [Gems.unique_of("m_leap")]
	hero.mana = hero.max_mana
	hammer.reset_cooldowns()
	hammer.cast("m_leap")
	await create_timer(0.22).timeout
	await _shot("4_skok")
	await create_timer(0.35).timeout
	await _shot("5_krater")
	await create_timer(1.0).timeout
	hero.mana = hero.max_mana
	hammer.reset_cooldowns()
	hammer.cast("m_quake")
	hammer.charge_held = true
	await create_timer(0.62).timeout
	await _shot("6_trzesienie")
	hammer.charge_held = false
	await create_timer(0.6).timeout
	hero.mana = hero.max_mana
	hammer.reset_cooldowns()
	hammer.cast("slam")
	await create_timer(0.45).timeout
	await _shot("7_rozlupanie")
	arena.queue_free()
	await process_frame
	arena = await _arena(game, "sword")
	hero = arena.hero
	for p in [Vector2(60, -10), Vector2(-70, 40), Vector2(30, 70)]:
		_goblin(arena, p)
	arena.weapon.skill_levels["spectral_blades"] = 10
	arena.weapon.cast("spectral_blades")
	await create_timer(0.25).timeout
	await _shot("8_ostrza")
	await create_timer(0.9).timeout
	await _shot("9_ostrza_tna")
	quit()

extends SceneTree
## Zrzuty Słonecznej włóczni Dadźboga w lochu: pchnięcie (z piętnem nad wrogami), Rzut Dadźboga w locie, Wschód Słońca,
## Kołowrót Słońca (obrót i pierścień), Zenit (krąg ostrzeżenia, spadające włócznie, promienie z nieba).
## Użycie: SCRIPT=tools/spear_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_pchniecie.png, _2_pietno.png, _3_rzut.png, _4_wschod.png, _5_kolowrot.png, _6_pierscien.png,
## _7_zenit_kregi.png, _8_zenit.png

var _prefix := "/tmp/wlocznia"


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


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 45
	game.dungeon_level = 12
	game.set_weapon("spear")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var spear := arena.weapon as ProtoSpear
	spear.auto_attack = false
	var hero: ProtoHero = arena.hero
	hero.position = Vector2.ZERO
	hero.max_mana = 10000
	var gs: Array = []
	for p in [Vector2(34, -6), Vector2(60, -8), Vector2(-50, 40), Vector2(70, 50), Vector2(-80, -40), Vector2(20, 60)]:
		gs.append(_goblin(arena, p))
	await create_timer(0.5).timeout
	spear._attack()
	await create_timer(0.17).timeout
	await _shot("1_pchniecie")
	await create_timer(0.4).timeout
	await _shot("2_pietno")
	hero.mana = hero.max_mana
	spear.reset_cooldowns()
	spear.cast("p_throw")
	await create_timer(0.25).timeout
	await _shot("3_rzut")
	await create_timer(1.0).timeout
	hero.mana = hero.max_mana
	spear.reset_cooldowns()
	spear._set_state("follow")
	spear.cast("p_sunrise")
	await create_timer(0.32).timeout
	await _shot("4_wschod")
	await create_timer(0.8).timeout
	hero.mana = hero.max_mana
	spear.reset_cooldowns()
	spear.cast("p_wheel")
	await create_timer(0.3).timeout
	await _shot("5_kolowrot")
	await create_timer(ProtoSpear.WHEEL_SPIN_TIME * 2 - 0.2).timeout
	await _shot("6_pierscien")
	await create_timer(0.8).timeout
	hero.mana = hero.max_mana
	spear.reset_cooldowns()
	spear.cast("p_zenith")
	await create_timer(0.3).timeout
	await _shot("7_zenit_kregi")
	await create_timer(0.55).timeout
	await _shot("8_zenit")
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	quit()

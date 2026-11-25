extends SceneTree
## Zrzuty Kostura Leszego w lochu: Biegnące Korzenie (łańcuch), Żołądź w locie i sadzonka, Uścisk Boru (oplątanie
## i wciąganie), sadzonki wszystkich rodzajów, Pylenie Mchu przy postaci i sadzonkach, Strażnicy Boru, pełne limity
## (12 sadzonek i 10 drzewców w tłumie).
## Użycie: SCRIPT=tools/staff_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_korzenie.png, _2_zoladz.png, _3_uscisk.png, _4_sadzonki.png, _5_pylenie.png, _6_drzewce.png,
## _7_pelne_limity.png

var _prefix := "/tmp/kostur"


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
	game.best_level = 40
	game.dungeon_level = 7
	game.set_weapon("staff")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var staff := arena.weapon as ProtoStaff
	staff.auto_attack = false
	var hero: ProtoHero = arena.hero
	hero.position = Vector2.ZERO
	hero.max_mana = 10000
	var gs: Array = []
	for p in [Vector2(40, -10), Vector2(85, 0), Vector2(125, -20), Vector2(-60, 40), Vector2(-90, -50), Vector2(20, 70)]:
		gs.append(_goblin(arena, p))
	await create_timer(0.5).timeout
	staff._attack()
	await create_timer(0.38).timeout
	await _shot("1_korzenie")
	await create_timer(0.5).timeout
	hero.mana = hero.max_mana
	staff.reset_cooldowns()
	staff.cast("l_acorn")
	await create_timer(0.35).timeout
	await _shot("2_zoladz")
	await create_timer(0.9).timeout
	staff.skill_gems["l_grasp"] = [Gems.unique_of("l_grasp")]
	hero.mana = hero.max_mana
	staff.reset_cooldowns()
	staff.cast("l_grasp")
	await create_timer(0.45).timeout
	await _shot("3_uscisk")
	await create_timer(0.8).timeout
	staff.add_sapling(hero.global_position + Vector2(-40, 60), "carnivore")
	staff.add_sapling(hero.global_position + Vector2(60, 50), "sapling")
	await create_timer(1.0).timeout
	await _shot("4_sadzonki")
	hero.mana = hero.max_mana
	staff.reset_cooldowns()
	staff.cast("l_spores")
	await create_timer(0.4).timeout
	await _shot("5_pylenie")
	await create_timer(0.6).timeout
	hero.mana = hero.max_mana
	staff.reset_cooldowns()
	staff.cast("l_treants")
	await create_timer(1.6).timeout
	await _shot("6_drzewce")
	# pełne limity w tłumie
	for i in 14:
		staff.add_sapling(hero.global_position + Vector2.from_angle(TAU * i / 14.0) * Vector2(110, 70), "sapling")
	for i in 30:
		_goblin(arena, hero.global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 170.0))
	hero.mana = hero.max_mana
	staff.reset_cooldowns()
	staff.cast("l_treants")
	await create_timer(1.5).timeout
	await _shot("7_pelne_limity")
	quit()

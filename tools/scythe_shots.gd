extends SceneTree
## Zrzuty mrocznej kosy w lochu: Żniwo w połowie zamachu i gasnące, Cięcie Światowida (cięcia w kwadrat i wybuch),
## Pokos (ładowanie - stożek na ziemi, cięcie), kamienie unikalne (4 kwadraty, rzędy wybuchów, fala Nawii).
## Użycie: SCRIPT=tools/scythe_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_zniwo.png, _2_gasnie.png, _3_kwadrat.png, _4_wybuch.png, _5_ladowanie.png, _6_pokos.png,
## _7_cztery.png, _8_rzedy.png, _9_fala.png, _10_taniec.png, _11_skos.png, _12_ostrze.png, _13_mara.png, _14_wybuch_mary.png,
## _15_blizniacze.png

var _prefix := "/tmp/kosa"


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
	game.best_level = 30
	game.dungeon_level = 22
	game.set_weapon("scythe")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	arena.weapon.auto_attack = false
	var hero: ProtoHero = arena.hero
	hero.position = Vector2.ZERO
	var scythe := arena.weapon as ProtoScythe
	for p in [Vector2(40, -10), Vector2(30, 25), Vector2(-60, 50), Vector2(90, -60), Vector2(-90, -40), Vector2(110, 40)]:
		_goblin(arena, p)
	await create_timer(0.5).timeout
	scythe._attack()
	await create_timer(0.26).timeout
	await _shot("1_zniwo")
	await create_timer(0.35).timeout
	await _shot("2_gasnie")
	await create_timer(0.6).timeout
	hero.mana = hero.max_mana
	scythe._start("s_square")
	await create_timer(0.3).timeout
	await _shot("3_kwadrat")
	await create_timer(0.62).timeout
	await _shot("4_wybuch")
	await create_timer(0.8).timeout
	hero.mana = hero.max_mana
	scythe.charge_held = true
	scythe._start("s_mow")
	await create_timer(1.0).timeout
	await _shot("5_ladowanie")
	scythe.charge_held = false
	await create_timer(0.12).timeout
	await _shot("6_pokos")
	await create_timer(0.8).timeout
	for id in Skills.of_weapon("scythe"):
		scythe.skill_gems[id] = [Gems.unique_of(id)]
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe._state = "follow"
	scythe._start("s_square")
	await create_timer(0.3).timeout
	await _shot("7_cztery")
	await create_timer(1.2).timeout
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe._state = "follow"
	scythe.charge_held = true
	scythe._start("s_mow")
	await create_timer(1.5).timeout
	scythe.charge_held = false
	await create_timer(0.45).timeout
	await _shot("8_rzedy")
	await create_timer(1.0).timeout
	scythe._reap_wave(1.0)
	await create_timer(0.3).timeout
	await _shot("9_fala")
	# krok 2: Taniec Marzanny i Postać Mary
	for g in arena.get_node("World").get_children():
		if g is ProtoGoblin:
			g.queue_free()
	await process_frame
	hero.position = Vector2.ZERO
	for p in [Vector2(70, -10), Vector2(110, 30), Vector2(60, 60), Vector2(-60, -40), Vector2(-90, 50), Vector2(150, -50)]:
		_goblin(arena, p)
	await create_timer(0.3).timeout
	scythe.skill_gems["s_dance"] = []
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe._state = "follow"
	scythe.cast("s_dance")
	await create_timer(0.3).timeout
	await _shot("10_taniec")
	await create_timer(0.75).timeout
	await _shot("11_skos")
	await create_timer(0.8).timeout
	scythe.skill_gems["s_dance"] = [Gems.unique_of("s_dance")]
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.cast("s_dance")
	await create_timer(1.3).timeout
	await _shot("12_ostrze")
	await create_timer(3.0).timeout
	scythe.skill_gems["s_mara"] = []
	scythe._cd.clear()
	hero.mana = hero.max_mana
	hero.position = Vector2(-120, 0)
	scythe._state = "follow"
	scythe.cast("s_mara")
	hero.joystick.vector = Vector2(1, -0.3).normalized()
	await create_timer(0.35).timeout
	hero.joystick.vector = Vector2(0.4, 1).normalized()
	await create_timer(0.3).timeout
	hero.joystick.vector = Vector2.ZERO
	await _shot("13_mara")
	scythe.cast("s_mara")
	await create_timer(0.15).timeout
	await _shot("14_wybuch_mary")
	await create_timer(1.0).timeout
	scythe.skill_gems["s_mara"] = [Gems.unique_of("s_mara")]
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.cast("s_mara")
	await create_timer(0.7).timeout
	await _shot("15_blizniacze")
	DirAccess.remove_absolute(game.save_path)
	quit()

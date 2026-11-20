extends SceneTree
## Zrzuty łuku: strzał i Poszukująca strzała, Deszcz strzał, ładowanie i wystrzał Potężnego strzału, balista,
## wielostrzał i przywołanie (kamienie unikalne).
## Użycie: SCRIPT=tools/bow_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_strzaly.png, _2_deszcz.png, _3_ladowanie.png, _4_potezny.png, _5_balista.png, _6_unikalne.png

var _prefix := "/tmp/luk"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://shots_savegame.json"  # osobno od testów (mogą iść równolegle)
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 20
	game.set_weapon("bow")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var bow := arena.weapon as ProtoBow
	hero.position = Vector2.ZERO
	var goblins: Array[ProtoGoblin] = []
	for at in [Vector2(110, -20), Vector2(130, 30), Vector2(-100, 60), Vector2(40, -120), Vector2(-60, -90)]:
		goblins.append(_goblin(arena, at))
	await create_timer(0.3).timeout
	for g in goblins:
		g._stunned = 60.0
	bow._aim = 0.0
	bow._shot_target = goblins[0]
	bow._fire_shot()
	bow._spawn_seeker(hero.global_position, -PI / 2.0)
	await create_timer(0.25).timeout
	await _shot("1_strzaly")
	bow._add_rain(goblins[0].global_position, 1.0)
	await create_timer(0.45).timeout
	await _shot("2_deszcz")
	bow.reset_cooldowns()
	hero.mana = hero.mana_cap()
	bow.charge_held = true
	bow._start("b_power")
	await create_timer(1.0).timeout
	await _shot("3_ladowanie")
	bow.charge_held = false
	await create_timer(0.15).timeout
	await _shot("4_potezny")
	bow._aim = 0.0
	bow._add_ballista(Vector2(-30, 40))
	await create_timer(0.75).timeout
	await _shot("5_balista")
	arena.queue_free()
	await process_frame
	for id in Skills.of_weapon("bow"):
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.save_game()
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.horde_spawner.set_process(false)
	hero = arena.hero
	bow = arena.weapon as ProtoBow
	hero.position = Vector2.ZERO
	goblins.clear()
	for at in [Vector2(110, -20), Vector2(130, 30), Vector2(-100, 60)]:
		goblins.append(_goblin(arena, at))
	await create_timer(0.3).timeout
	for g in goblins:
		g._stunned = 60.0
	hero.mana = hero.mana_cap()
	bow.cast("b_seeker")
	bow._aim = 0.0
	bow._fire_shot()
	await create_timer(0.2).timeout
	await _shot("6_unikalne")
	game.reset_hero()
	game.dev_immortal = false
	game.save_game()
	quit()

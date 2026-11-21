extends SceneTree
## Zrzuty Księgi Arkanów w lochu: pociski z ogonami, Krąg Mocy, Kule Arkanów (z drugą orbitą), Promień Arkanów,
## Pieczęcie Wybuchu z wiązkami (kamienie unikalne w kręgu, kulach i pieczęciach).
## Użycie: SCRIPT=tools/book_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_pociski.png, _2_krag.png, _3_kule.png, _4_promien.png, _4b_fala.png, _5_pieczecie.png

var _prefix := "/tmp/ksiega"


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
	game.best_level = 20
	game.dungeon_level = 6
	game.set_weapon("book")
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
	var book := arena.weapon as ProtoBook
	for p in [Vector2(110, -40), Vector2(-100, -60), Vector2(60, 90), Vector2(-70, 80), Vector2(20, -120), Vector2(140, 60)]:
		_goblin(arena, p)
	await create_timer(0.5).timeout
	book._aim = 0.0
	book._fire_missiles()
	await create_timer(0.22).timeout
	await _shot("1_pociski")
	await create_timer(1.5).timeout
	for id in ["a_missiles", "a_circle", "a_orbs", "a_seals", "a_beam"]:
		book.skill_gems[id] = [Gems.unique_of(id)]
	hero.mana = hero.max_mana
	book._start("a_circle")
	await create_timer(0.2).timeout
	await _shot("2_krag")
	book.cast("a_orbs")
	await create_timer(0.6).timeout
	await _shot("3_kule")
	book.cast("a_orbs")
	hero.mana = hero.max_mana
	book.charge_held = true
	book._start("a_beam")
	await create_timer(0.2).timeout
	await _shot("4b_fala")
	await create_timer(0.38).timeout
	await _shot("4_promien")
	book.charge_held = false
	await create_timer(0.2).timeout
	hero.mana = hero.max_mana
	book._cd.clear()
	book._start("a_seals")
	await create_timer(0.55).timeout
	await _shot("5_pieczecie")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

extends SceneTree
## Zrzuty lodowego rapiera w lochu: pchnięcie, cięcie, znaki chłodu i zamrożony wróg, roztrzaskanie, wypad ze ścieżką
## szronu, krąg Riposty Morozka (z ripostą), Grad Pchnięć z kolcami, Rój Sopli.
## Użycie: SCRIPT=tools/rapier_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_pchniecie.png, _1b_ciecie.png, _2_chlod.png, _3_roztrzaskanie.png, _4_wypad.png, _5_sciezka.png,
## _6_krag.png, _7_riposta.png, _8_grad.png, _9_roj.png, _9b_roj_chmura.png, _10_roj_strzela.png

var _prefix := "/tmp/rapier"


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
	game.best_level = 35
	game.dungeon_level = 7
	game.set_weapon("rapier")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var rapier := arena.weapon as ProtoRapier
	rapier.auto_attack = false
	var hero: ProtoHero = arena.hero
	hero.position = Vector2.ZERO
	hero.max_mana = 10000
	var gs: Array = []
	for p in [Vector2(34, -6), Vector2(54, -8), Vector2(-50, 40), Vector2(70, 50), Vector2(-80, -40), Vector2(20, 60)]:
		gs.append(_goblin(arena, p))
	await create_timer(0.5).timeout
	rapier._attack()
	await create_timer(0.16).timeout
	await _shot("1_pchniecie")
	await create_timer(0.3).timeout
	rapier._cooldown = 0.0
	rapier._attack()
	await create_timer(0.13).timeout
	await _shot("1b_ciecie")
	gs[2].chill(0.25, 5.0, 2)
	gs[3].freeze(5.0)
	await create_timer(0.4).timeout
	await _shot("2_chlod")
	gs[0].freeze(5.0)
	gs[1].position = Vector2(46, 8)
	rapier._cooldown = 0.0
	rapier._set_state("follow")
	rapier._attack()
	await create_timer(0.3).timeout
	await _shot("3_roztrzaskanie")
	await create_timer(0.4).timeout
	hero.mana = hero.max_mana
	rapier.reset_cooldowns()
	rapier.skill_levels["r_lunge"] = 10
	rapier.cast("r_lunge")
	await create_timer(0.1).timeout
	await _shot("4_wypad")
	await create_timer(0.25).timeout
	await _shot("5_sciezka")
	await create_timer(0.6).timeout
	hero.mana = hero.max_mana
	rapier.reset_cooldowns()
	rapier.cast("r_riposte")
	await create_timer(0.6).timeout
	await _shot("6_krag")
	hero.parry_left = 0.2
	hero._invulnerable = 0.0
	hero.take_damage(10)
	await create_timer(0.12).timeout
	await _shot("7_riposta")
	await create_timer(0.8).timeout
	hero.mana = hero.max_mana
	rapier.reset_cooldowns()
	rapier.skill_gems["r_flurry"] = [Gems.unique_of("r_flurry")]
	rapier.cast("r_flurry")
	rapier.charge_held = true
	await create_timer(0.5).timeout
	await _shot("8_grad")
	rapier.charge_held = false
	await create_timer(0.5).timeout
	hero.mana = hero.max_mana
	rapier.reset_cooldowns()
	rapier.cast("r_swarm")
	await create_timer(0.3).timeout
	await _shot("9_roj")
	await create_timer(0.4).timeout
	await _shot("9b_roj_chmura")
	await create_timer(0.5).timeout
	await _shot("10_roj_strzela")
	quit()

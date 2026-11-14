extends SceneTree
## Zrzuty glewii ognia: okno umiejętności z wyborem broni (baza) i walka w lochu - pchnięcie, Ognisty zamach,
## Płonąca bruzda (pas ognia i cięcia w wachlarzu), Słup ognia i Taniec płomieni. Mierzy też klatki na sekundę w tańcu z ogniem na ziemi.
## Użycie: SCRIPT=tools/glaive_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_okno.png, _2_pchniecie.png, _3_zamach.png, _4_bruzda.png, _5_slup.png, _6_taniec.png, _7_taniec.png

var _prefix := "/tmp/glewia"


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
	game.reset_hero()
	game.best_level = 10
	game.dev_set_level(20)
	game.set_weapon("glaive")
	game.dev_set_level(20)
	game.dev_skills()
	game.skill_slots = ["g_thrust", "g_sweep", "g_trail", "g_pillar", "g_dance"]
	game.embers = 900
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.skills_window.open(true)
	await create_timer(0.3).timeout
	await _shot("1_okno")
	arena.skills_window.close()
	arena.queue_free()
	game.dungeon_level = 4
	game.save_game()
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(4.0).timeout
	var weapon: ProtoGlaive = arena.weapon
	var hero: ProtoHero = arena.hero
	weapon.attack_held = true
	await create_timer(0.85).timeout
	await _shot("2_pchniecie")
	weapon.attack_held = false
	await create_timer(0.4).timeout
	weapon.cast("g_sweep")
	await create_timer(0.18).timeout
	await _shot("3_zamach")
	await create_timer(0.6).timeout
	hero.mana = hero.max_mana
	weapon.cast("g_trail")
	await create_timer(0.42).timeout
	await _shot("4_bruzda")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("g_pillar")
	await create_timer(0.55).timeout
	await _shot("5_slup")
	await create_timer(0.3).timeout
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("g_dance")
	var frames := Engine.get_frames_drawn()
	await create_timer(1.15).timeout
	await _shot("6_taniec")
	await create_timer(0.45).timeout
	print("klatki/s w tańcu: %.0f" % ((Engine.get_frames_drawn() - frames) / 1.6))
	await _shot("7_taniec")
	game.dev_immortal = false
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	quit()

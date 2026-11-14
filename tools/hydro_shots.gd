extends SceneTree
## Zrzuty hydrosfery: okno umiejętności z trzema broniami (baza) i walka w lochu - wodny pocisk, Fala, Wir, Gejzery
## i Ulewa. Mierzy też klatki na sekundę w Ulewie z wirem.
## Użycie: SCRIPT=tools/hydro_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_okno.png, _2_pocisk.png, _3_fala.png, _4_wir.png, _5_gejzery.png, _6_ulewa.png

var _prefix := "/tmp/hydrosfera"


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
	game.best_level = 15
	game.set_weapon("hydrosphere")
	game.dev_set_level(20)
	game.dev_skills()
	game.skill_slots = ["h_bolt", "h_wave", "h_vortex", "h_geyser", "h_rain"]
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
	var weapon: ProtoHydrosphere = arena.weapon
	var hero: ProtoHero = arena.hero
	weapon.attack_held = true
	await create_timer(0.45).timeout
	await _shot("2_pocisk")
	weapon.attack_held = false
	await create_timer(0.3).timeout
	weapon.cast("h_wave")
	await create_timer(0.3).timeout
	await _shot("3_fala")
	hero.mana = hero.max_mana
	weapon.cast("h_vortex")
	await create_timer(1.0).timeout
	await _shot("4_wir")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("h_geyser")
	await create_timer(0.62).timeout
	await _shot("5_gejzery")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("h_vortex")
	weapon.cast("h_rain")
	var frames := Engine.get_frames_drawn()
	await create_timer(1.5).timeout
	print("klatki/s w ulewie z wirem: %.0f" % ((Engine.get_frames_drawn() - frames) / 1.5))
	await _shot("6_ulewa")
	game.dev_immortal = false
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	quit()

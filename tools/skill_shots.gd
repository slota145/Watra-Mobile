extends SceneTree
## Zrzuty umiejętności: baza z kamieniem run, okno umiejętności, a w lochu walka - Młynek, Rzut mieczem,
## Rozłupanie Ziemi i Mgnienie z odliczaniem odnowienia na przyciskach.
## Użycie: SCRIPT=tools/skill_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_baza.png, _2_okno.png, _3_mlynek.png, _4_rzut.png, _5_rozlupanie.png, _6_mgnienie.png, _7_pauza.png

var _prefix := "/tmp/umiejetnosci"


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
	game.hero_level = 10
	game.gold = 1250
	game.buy_skill("whirl")
	game.buy_skill("throw")
	game.assign_skill("whirl", 0)
	game.skill_levels = {"strike": 3, "whirl": 5}  # poziomy umiejętności: próg 5. poziomu Młynka odblokowany
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.hero.position = Vector2(60, -100)
	await create_timer(0.6).timeout
	await _shot("1_baza")
	arena.open_skills()
	arena.skills_window.list_icons[1].pressed.emit()
	await create_timer(0.2).timeout
	await _shot("2_okno")
	arena.skills_window.close()
	arena.queue_free()
	game.dev_skills()
	game.dungeon_level = 3
	game.save_game()
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(4.0).timeout
	var weapon: ProtoWeapon = arena.weapon
	weapon.cast("whirl")
	await create_timer(0.5).timeout
	await _shot("3_mlynek")
	await create_timer(2.8).timeout
	arena.hero.mana = arena.hero.max_mana
	weapon.cast("throw")
	await create_timer(0.3).timeout
	await _shot("4_rzut")
	await create_timer(1.0).timeout
	weapon.cast("slam")
	await create_timer(0.42).timeout
	await _shot("5_rozlupanie")
	await create_timer(0.6).timeout
	arena.hero.mana = arena.hero.max_mana
	weapon.cast("blink")
	weapon.flicker_held = true  # trzymany przycisk - skoki przez kolejne gobliny
	await create_timer(0.38).timeout
	await _shot("6_mgnienie")
	weapon.flicker_held = false
	await create_timer(0.3).timeout
	arena._open_menu()
	await create_timer(0.2).timeout
	await _shot("7_pauza")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

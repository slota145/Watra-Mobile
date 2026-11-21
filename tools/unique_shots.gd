extends SceneTree
## Zrzuty kamieni unikalnych: w lochu fala cięcia zwykłego ciosu, Młynek bez odnowienia, odbicia Rzutu, fale
## z trafionych Rozłupaniem, a w bazie zakładka „Kamienie” okna umiejętności z kamieniem unikalnym w gnieździe.
## Użycie: SCRIPT=tools/unique_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_fala.png, _2_mlynek.png, _3_rzut.png, _4_rozlupanie.png, _5_okno.png

var _prefix := "/tmp/unikalne"


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
	game.hero_level = 20
	game.dev_skills()
	for id in Skills.ORDER:
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.dungeon_level = 3
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(4.0).timeout
	var weapon: ProtoWeapon = arena.weapon
	arena.hero.immortal = true
	arena.hero.facing = Vector2.RIGHT
	weapon._attack()
	await create_timer(0.38).timeout
	await _shot("1_fala")
	await create_timer(0.3).timeout
	arena.hero.mana = arena.hero.max_mana
	weapon.cast("whirl")
	await create_timer(3.6).timeout
	await _shot("2_mlynek")
	weapon.cast("whirl")
	await create_timer(0.3).timeout
	arena.hero.mana = arena.hero.max_mana
	weapon.cast("throw")
	await create_timer(0.55).timeout
	await _shot("3_rzut")
	await create_timer(1.2).timeout
	arena.hero.mana = arena.hero.max_mana
	weapon.cast("slam")
	await create_timer(0.55).timeout
	await _shot("4_rozlupanie")
	arena.queue_free()
	await process_frame
	arena = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.open_skills()
	arena.skills_window.set_gems_mode(true)
	arena.skills_window.list_icons[1].pressed.emit()
	await create_timer(0.3).timeout
	await _shot("5_okno")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

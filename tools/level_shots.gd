extends SceneTree
## Zrzuty rozwoju postaci do oceny wyglądu: loch z paskiem doświadczenia i chwilą awansu, okno pauzy
## (auto atak, skróty deweloperskie), okno „Postać”, okno wyniku z doświadczeniem i baza z poziomem postaci.
## Użycie: SCRIPT=tools/level_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_awans.png, _2_pauza.png, _2b_postac.png, _3_wynik.png, _4_baza.png

var _prefix := "/tmp/poziom"


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
	game.add_xp(HeroLevels.xp_to_next(1) + HeroLevels.xp_to_next(2) - 10)
	game.dungeon_level = 1
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(4.0).timeout
	game.add_xp(20)
	await create_timer(0.35).timeout
	await _shot("1_awans")
	arena._open_menu()
	await _shot("2_pauza")
	arena.pause_menu.stats.open()
	await _shot("2b_postac")
	arena.pause_menu.stats.close()
	arena.pause_menu.close()
	arena.run_xp = 143
	arena._start_hero_level = 2
	arena.hero.take_damage(10000)
	await create_timer(1.6).timeout
	await _shot("3_wynik")
	paused = false
	arena.queue_free()
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await create_timer(1.0).timeout
	await _shot("4_baza")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

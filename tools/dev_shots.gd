extends SceneTree
## Zrzuty okna trybu deweloperskiego: pauza z przyciskiem, okno u góry (przełączniki, skróty, poziom postaci),
## okno przewinięte do statystyk (dwie zmienione suwakiem - zielone), wybór poziomu lochu z „wszystkimi poziomami”.
## Użycie: SCRIPT=tools/dev_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_pauza.png, _2_okno.png, _3_statystyki.png, _4_poziomy.png

var _prefix := "/tmp/dev"


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
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	game.dev_stats = {"area_pct": 40.0, "dodge_pct": 25.0}
	game.dev_all_levels = true
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena._open_menu()
	await create_timer(0.2).timeout
	await _shot("1_pauza")
	arena.pause_menu.dev_button.pressed.emit()
	await create_timer(0.3).timeout
	await _shot("2_okno")
	var dev: DevWindow = arena.pause_menu.dev
	dev._scroll.scroll_vertical = int(dev.stat_rows["crit_pct"].label.position.y)
	await create_timer(0.2).timeout
	await _shot("3_statystyki")
	arena.pause_menu.close()
	arena.open_picker()
	arena.picker.set_level(37)
	await create_timer(0.2).timeout
	await _shot("4_poziomy")
	game.dev_stats = {}
	game.dev_all_levels = false
	game.save_settings()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	quit()

extends SceneTree
## Zrzuty Głębin: baza z Czarną Watrą (i „Nowość!”), wybór Głębi przy Czarnej Watrze (planszę otwarcia sprawdza
## tests/test_deeps.gd).
## Użycie: SCRIPT=tools/deep_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_baza.png, _2_wybor.png

var _prefix := "/tmp/glebiny"


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
	game.best_level = 62
	game.deep_seen = false
	game.dungeon_level = 63
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.hero.position = Vector2(-20, 40)
	await create_timer(0.3).timeout
	await _shot("1_baza")
	arena.open_deep_picker()
	await create_timer(0.3).timeout
	await _shot("2_wybor")
	arena.picker.close()
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	quit()

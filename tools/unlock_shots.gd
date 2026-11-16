extends SceneTree
## Zrzuty drabinki odblokowań (Unlocks): znaczek „Nowość!” nad Watrą, wybór poziomu z najbliższym odblokowaniem
## i okno „Drabinka”. Użycie: SCRIPT=tools/unlock_shots.gd tools/screenshot.sh <prefiks> [RESOLUTION]
## Potem modyfikatory lochów: wybór poziomu 20, okno modyfikatorów, pasek w lochu z nazwami modyfikatorów.
## Pliki: <prefiks>_1_watra.png, _2_wybor.png, _3_drabinka.png, _4_wybor20.png, _5_modyfikatory.png, _6_loch.png

var _prefix := "/tmp/drabinka"


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
	game.best_level = 10
	game.unlocks_seen = 4
	game.dungeon_level = 11
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.6).timeout
	await _shot("1_watra")
	arena.open_picker()
	arena.picker.set_level(11)
	await create_timer(0.3).timeout
	await _shot("2_wybor")
	arena.picker.ladder_button.pressed.emit()
	await create_timer(0.4).timeout
	await _shot("3_drabinka")
	arena.unlocks_window.close()
	game.best_level = 25
	game.dungeon_mods = ["embers", "blood_moon"]
	arena.picker.open(20, 26)
	await create_timer(0.3).timeout
	await _shot("4_wybor20")
	arena.picker.mods_button.pressed.emit()
	await create_timer(0.3).timeout
	await _shot("5_modyfikatory")
	arena.mods_window.close()
	arena.picker.close()
	arena.queue_free()
	game.dungeon_level = 20
	var dungeon: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(dungeon)
	await create_timer(2.0).timeout
	await _shot("6_loch")
	DirAccess.remove_absolute(game.save_path)
	quit()

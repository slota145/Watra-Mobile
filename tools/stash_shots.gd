extends SceneTree
## Zrzuty skrzyni w bazie: baza ze skrzynią obok Watry, okno skrzyni z dwiema zakładkami i opis przedmiotu.
## Użycie: SCRIPT=tools/stash_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_baza.png, _2_okno.png, _3_opis.png

var _prefix := "/tmp/skrzynia"


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
	game.gold = 260
	game.buy_stash_tab()
	game.dungeon_level = 4
	game.dev_items(14)
	game.stash_all(0)
	game.dev_items(7)
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	await _shot("1_baza")
	arena.open_stash()
	arena.stash_window._select_tab(0)
	await create_timer(0.2).timeout
	await _shot("2_okno")
	arena.stash_window.bag_slots[1].pressed.emit()
	await create_timer(0.2).timeout
	await _shot("3_opis")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

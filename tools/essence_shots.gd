extends SceneTree
## Zrzut opisu unikatu z poziomem (gwiazdki, esencje, „Ulepsz”) w oknie „Postać” i torby z gwiazdkami poziomu.
## Użycie: SCRIPT=tools/essence_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_opis.png

var _prefix := "/tmp/esencje"


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
	var u := Items.make_unique("licho", 22)
	u.ulevel = 3
	var w := Items.make_unique("swarog", 22)
	w.ulevel = 5
	game.bag = [u, w, Items.roll(22, "ring", "rare")]
	game.essences = {"licho": 3}
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.stats_window.open()
	arena.stats_window._select_bag(0)
	await create_timer(0.3).timeout
	await _shot("1_opis")
	DirAccess.remove_absolute(game.save_path)
	quit()

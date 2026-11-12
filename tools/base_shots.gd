extends SceneTree
## Zrzuty bazy z kowalem i kupcem: okno ulepszeń lochów (żar), kupiec z półką, kowal z opisem przedmiotu
## (premia przed przeróbką uzbrojona - „Na pewno?”).
## Użycie: SCRIPT=tools/base_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_baza.png, _2_ulepszenia.png, _3_kupiec.png, _4_kowal.png

var _prefix := "/tmp/baza"


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
	game.embers = 430
	game.upgrades = {"monsters": 2, "reach": 1}
	game.best_level = 4
	game.dungeon_level = 4
	game.gold = 760
	game.dev_items(6)
	game.equip(0)
	game.restock_shop(4)
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	await _shot("1_baza")
	arena.open_upgrades()
	await create_timer(0.2).timeout
	await _shot("2_ulepszenia")
	arena.upgrades_window.close()
	arena.picker.close()
	arena.open_shop()
	arena.shop_window._buy(0)  # uzbrojony przycisk klucza
	await create_timer(0.2).timeout
	await _shot("3_kupiec")
	arena.shop_window.close()
	arena.open_smith()
	var idx := 0
	for i in game.bag.size():
		if game.bag[i].rarity == "rare":
			idx = i
	arena.smith_window.bag_slots[idx].pressed.emit()
	arena.smith_window._reroll(1)
	await create_timer(0.2).timeout
	await _shot("4_kowal")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

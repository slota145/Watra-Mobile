extends SceneTree
## Zrzuty targu (Market): zakładki Giełda, Oferty i Moje (z wybraną rzeczą do wystawienia).
## Użycie: SCRIPT=tools/market_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_gielda.png, _2_oferty.png, _3_moje.png

var _prefix := "/tmp/targ"


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
	game.best_level = 8
	game.dev_runes()
	game.ore = 34
	game.dev_items(3)
	game.market_catch_up()
	game.market.mine.append({"loot": Items.roll(7, "helmet", "rare"), "price": 14, "seller": game.char_name, "age": 0})
	game.market.news.append("Radomir kupił(a): Stalowy hełm za 9 Szl. (po opłacie 8)")
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.8).timeout
	arena.open_market()
	await create_timer(0.2).timeout
	await _shot("1_gielda")
	arena.market_window.set_tab("listings")
	await create_timer(0.2).timeout
	await _shot("2_oferty")
	arena.market_window.set_tab("mine")
	arena.market_window.pick = {"bag": 0}
	arena.market_window.pick_price = Market.fair_price(game.bag[0])
	arena.market_window.refresh()
	await create_timer(0.2).timeout
	await _shot("3_moje")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

extends SceneTree
## Zrzuty broni zapasowej: loch z przyciskiem zamiany w rogu przycisków (miecz w ręku, łuk zapasowy), po zamianie
## (łuk w ręku) i lista broni w oknie umiejętności („Zapas” / „Odłóż”, mistrzostwo z doganianiem).
## Użycie: SCRIPT=tools/spare_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## i Pamięć oręża (przekreślona cena ulepszenia glewii, gdy Młynek miecza ma wyższy poziom).
## Pliki: <prefiks>_1_loch.png, _2_zamiana.png, _3_bronie.png, _4_pamiec.png

var _prefix := "/tmp/spare"


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
	game.hero_level = 20
	game.best_level = 12
	game.dev_immortal = true
	game.mastery["sword"] = 12
	game.dev_skills()
	game.set_spare("bow")
	game.mastery["bow"] = 4
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(3.0).timeout
	await _shot("1_loch")
	arena._on_swap_pressed()
	await create_timer(0.4).timeout
	await _shot("2_zamiana")
	arena.queue_free()
	await process_frame
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await create_timer(0.5).timeout
	base.skills_window.open(true)
	base.skills_window.open_weapons()
	await create_timer(0.3).timeout
	await _shot("3_bronie")
	base.skills_window.weapon_menu.visible = false
	game.skill_levels["whirl"] = 6
	game.embers = 5000
	game.mastery["glaive"] = 12
	game.set_weapon("glaive")
	base.skills_window.refresh()
	await create_timer(0.3).timeout
	await _shot("4_pamiec")
	game.dev_immortal = false
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

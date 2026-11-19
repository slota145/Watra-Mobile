extends SceneTree
## Zrzuty aur: zakładka „Aury” w oknie umiejętności i walka w lochu z włączonymi aurami (kręgi pod postacią,
## Szron Marzanny, Błędny Ognik, rezerwacja na pasku many).
## Użycie: SCRIPT=tools/aura_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_zakladka.png, <prefiks>_2_walka.png

var _prefix := "/tmp/aury"


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
	game.dungeon_level = 9
	game.dev_skills()
	game.auras = {"krzepa": 3, "strzybog": 1, "szron": 5, "ognik": 2, "perun": 1, "mokosz": 1, "postrach": 2, "jarylo": 1,
			"popiol": 1}
	game.auras_on = ["szron", "ognik"]
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.open_skills()
	var win: SkillsWindow = arena.skills_window
	win.set_aura_mode()
	win._on_aura_pressed("strzybog")  # trzecia aura - powód odmowy w podpowiedzi
	await create_timer(0.2).timeout
	await _shot("1_zakladka")
	win.close()
	arena.queue_free()
	await process_frame
	game.auras_on = ["postrach", "mokosz"]
	game.save_game()
	var horde: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(horde)
	await create_timer(4.0).timeout
	await _shot("2_walka")
	game.reset_hero()
	quit()

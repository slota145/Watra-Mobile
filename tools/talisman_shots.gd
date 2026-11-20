extends SceneTree
## Zrzuty talizmanów: zakładka „Talizmany” w oknie „Postać” i walka w lochu (fala Rogu Gruzłoga, grom Pióra
## Gromu, drżenie Serca Głębin).
## Użycie: SCRIPT=tools/talisman_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_zakladka.png, <prefiks>_2_walka.png

var _prefix := "/tmp/talizmany"


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
	game.talismans = {"shockwave": 4, "thunder": 2, "tremor": 10, "archmage": 1, "devour": 3}
	game.talisman_slots = ["shockwave", "thunder", "tremor"]
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.open_stats()
	var win: HeroStats = arena.stats_window
	win.set_tab("talismans")
	win.refresh()
	win._on_talisman_button("archmage")  # pełne miejsca - wybór miejsca do zamiany
	await create_timer(0.2).timeout
	await _shot("1_zakladka")
	win.close()
	arena.queue_free()
	await process_frame
	var horde: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(horde)
	await create_timer(3.0).timeout
	var tal: ProtoTalismans = horde.talismans_node
	var near: ProtoTarget = null
	for t: ProtoTarget in horde.weapon.targets:
		if is_instance_valid(t) and t.alive() and (near == null or t.global_position.distance_to(horde.hero.global_position)
				< near.global_position.distance_to(horde.hero.global_position)):
			near = t
	tal._tremor_next = 0.0
	if near:
		tal.worn = {"shockwave": 10, "thunder": 10, "tremor": 10}
		for i in 30:
			tal._hit_ready.clear()
			tal.on_hit(near)
	await create_timer(0.25).timeout
	await _shot("2_walka")
	game.reset_hero()
	quit()

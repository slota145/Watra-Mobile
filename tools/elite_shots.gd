extends SceneTree
## Zrzuty elit do oceny wyglądu: elity każdej cechy w tłumie goblinów (poświata, napis, pasek zdrowia, tarcza,
## krąg Dowódczego) i koło wybuchu po śmierci Wybuchowego.
## Użycie: SCRIPT=tools/elite_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_elity.png, _2_wybuch.png

var _prefix := "/tmp/elity"


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
	game.best_level = 7
	game.dungeon_level = 7
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	var h := hero.position
	horde.spawn_at(h + Vector2(-70, -110), "brute", ["commanding", "shield"] as Array[String])
	for p in [Vector2(-110, -80), Vector2(-30, -80), Vector2(-90, -150), Vector2(-40, -140)]:
		horde.spawn_at(h + p)
	horde.spawn_at(h + Vector2(80, -60), "archer", ["fast"] as Array[String])
	horde.spawn_at(h + Vector2(60, 90), "goblin", ["volatile", "fast"] as Array[String])
	for p in [Vector2(-80, 60), Vector2(100, 40)]:
		horde.spawn_at(h + p)
	await create_timer(0.6).timeout
	await _shot("1_elity")
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin and n.elite and "volatile" in n.elite.traits:
			n.take_damage(100000, hero.global_position)
	await create_timer(0.6).timeout
	await _shot("2_wybuch")
	quit()

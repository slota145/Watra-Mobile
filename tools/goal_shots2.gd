extends SceneTree
## Zrzuty Kręgu Żertwy i Kryształu Watry (cele na mapie lochu): pień pod słupem światła, płonący krąg z daniną
## i paczkami potworów, okno wyboru nagrody, kryształ w obronie z falą potworów.
## Użycie: SCRIPT=tools/goal_shots2.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_pien.png, _2_krag.png, _3_wybor.png, _4_krysztal.png

var _prefix := "/tmp/cele2"


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
	game.best_level = 22
	game.dungeon_level = 22
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	var stump: ProtoZertwa = arena.spawn_goal("zertwa")
	stump.position = hero.position + Vector2(20, -130)
	await create_timer(0.8).timeout
	await _shot("1_pien")
	hero.position = stump.position + Vector2(-10, 8)
	await create_timer(ProtoZertwa.PRAY_TIME + 0.2).timeout
	stump.tribute = 37
	hero.position = stump.position + Vector2(0, 40)
	await create_timer(1.6).timeout
	await _shot("2_krag")
	stump.tribute = DungeonGoals.ZER_GOAL - 1
	var g := horde.spawn_at(stump.position + Vector2(10, 5))
	await process_frame
	stump.offer_kill(g)  # szkielet Katakumb wstaje z kości - danina wprost
	await create_timer(0.3).timeout
	await _shot("3_wybor")
	arena.zertwa_offer._list.get_child(0).pressed.emit()
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	var crystal: ProtoCrystal = arena.spawn_goal("crystal")
	crystal.position = hero.position + Vector2(0, -100)
	hero.position = crystal.position + Vector2(-40, 40)
	await create_timer(1.0).timeout
	hero.position = crystal.position + Vector2(0, 150)  # potwory idą na kryształ, nie na postać
	await create_timer(3.0).timeout
	await _shot("4_krysztal")
	DirAccess.remove_absolute(game.save_path)  # testowy zapis (poziom lochu) nie może zmieniać innych testów
	quit()

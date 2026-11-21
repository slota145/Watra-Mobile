extends SceneTree
## Zrzuty unikatów do oceny wyglądu: łup na ziemi (rzadki, legendarny, unikat - słupy światła), opis unikatu w oknie
## „Postać” i Ślady Swaroga z Ostatnią Warownią w walce.
## Użycie: SCRIPT=tools/unique_item_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_lup.png, _2_opis.png, _3_walka.png

var _prefix := "/tmp/unikaty"


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
	game.dungeon_level = 20
	game.dev_uniques()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.horde_spawner.running = false
	var hero: ProtoHero = arena.hero
	var drops := [Items.roll(20, "", "rare"), Items.roll(20, "", "legendary"), Items.make_unique("mokosz", 20)]
	for i in drops.size():
		var loot: ProtoLoot = arena.horde_spawner.drop_item(drops[i], hero.position + Vector2(-50 + 50 * i, -70))
		loot.magnet = 0.0
	await create_timer(1.0).timeout
	await _shot("1_lup")
	arena.stats_window.open()
	arena.stats_window.refresh()
	arena.stats_window.bag_buttons[1].pressed.emit()  # Korona Czarnoboga
	await create_timer(0.2).timeout
	await _shot("2_opis")
	arena.stats_window.close()
	game.equipped = {"boots": Items.make_unique("swarog", 20), "armor": Items.make_unique("bastion", 20)}
	game.inventory_changed.emit()
	arena.horde_spawner.running = true
	for i in 40:
		hero.position += Vector2(cos(i * 0.3), sin(i * 0.3)) * 4.0
		await process_frame
	await create_timer(1.0).timeout
	await _shot("3_walka")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

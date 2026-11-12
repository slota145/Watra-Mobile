extends SceneTree
## Zrzuty przedmiotów do oceny wyglądu: łup na ziemi w lochu (zwykły, magiczny, rzadki), okno „Postać” z ekwipunkiem
## i torbą, dół okna (sprzedaż hurtem, auto sprzedaż), opis przedmiotu z porównaniem i pytanie przy ucieczce.
## Użycie: SCRIPT=tools/item_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_lup.png, _2_okno.png, _2b_dol.png, _3_opis.png, _4_ucieczka.png

var _prefix := "/tmp/przedmioty"


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
	game.dungeon_level = 3
	for slot in ["weapon", "helmet", "armor", "ring"]:
		game.add_item(Items.roll(3, slot, ["magic", "rare", "common", "rare"][game.bag.size()]))
		game.equip(0)
	game.dev_items(9)
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.horde_spawner.running = false
	var hero: ProtoHero = arena.hero
	var i := 0
	for r in ["common", "magic", "rare"]:
		var loot: ProtoLoot = arena.horde_spawner.drop_item(Items.roll(3, "", r), hero.position + Vector2(-60 + 60 * i, -70))
		loot.magnet = 0.0
		i += 1
	arena.horde_spawner._on_ember(57)
	arena.notify_loot(Items.roll(3, "helmet", "rare"), tr("Podniesiono: %s") % "Żelazny hełm")
	arena.notify_loot(Items.roll(3, "boots", "common"), tr("Sprzedano: %s (+%d złota)") % ["Skórzane buty", 8])
	await create_timer(1.0).timeout
	await _shot("1_lup")
	arena._open_menu()
	arena.pause_menu.stats.open()
	await create_timer(0.2).timeout
	await _shot("2_okno")
	var sc: ScrollContainer = arena.pause_menu.stats._scroll
	sc.scroll_vertical = 10000
	arena.pause_menu.stats.sell_common_button.pressed.emit()
	await create_timer(0.2).timeout
	await _shot("2b_dol")
	game.bag[0] = Items.roll(3, "weapon", "rare")
	arena.pause_menu.stats.refresh()
	arena.pause_menu.stats.bag_buttons[0].pressed.emit()
	await create_timer(0.2).timeout
	await _shot("3_opis")
	arena.pause_menu.stats.close()
	arena.pause_menu.base_button.pressed.emit()
	await create_timer(0.2).timeout
	await _shot("4_ucieczka")
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

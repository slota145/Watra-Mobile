extends SceneTree
## Zrzuty filtra łupu: okno z pauzy (zakładka „Zasady” dla wszystkich miejsc), hełm z własnymi ustawieniami
## w zakładce „Premie” z Automatem (łuk), torba okna „Postać” ze znaczkami ognia i przyciskiem filtra.
## Użycie: SCRIPT=tools/filter_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_zasady.png, _2_premie.png, _3_torba.png

var _prefix := "/tmp/filtr"


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
	game.weapon = Weapons.BOW
	game.skill_slots = ["b_shot", "b_rain", "", "", ""]
	game.dungeon_level = 22
	game.loot_filter = LootFilter.defaults()
	game.loot_filter.on = true
	game.loot_filter.auto = true
	game.loot_filter.upgrade = false
	game.loot_filter.slots.all.rarities = ["common", "magic"]
	game.loot_filter.slots.all.stats = ["move_pct"]
	game.loot_filter.slots.helmet.own = true
	game.loot_filter.slots.helmet.stats = ["hp", "element_res_pct"]
	for i in 8:
		game.bag.append(Items.roll(22, "", "", Items.CHEST_WEIGHTS))
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena._open_menu()
	arena.pause_menu.filter_button.pressed.emit()
	await create_timer(0.3).timeout
	await _shot("1_zasady")
	var w: LootFilterWindow = arena.pause_menu.filter_window
	w.slot_buttons["helmet"].pressed.emit()
	w.tab_buttons["stats"].pressed.emit()
	await create_timer(0.3).timeout
	await _shot("2_premie")
	w.close()
	arena.pause_menu.close()
	arena.stats_window.open()
	await create_timer(0.3).timeout
	arena.stats_window._scroll.scroll_vertical = 400
	await create_timer(0.2).timeout
	await _shot("3_torba")
	DirAccess.remove_absolute(game.save_path)
	quit()

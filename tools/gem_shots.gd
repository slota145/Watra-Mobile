extends SceneTree
## Zrzuty kamieni: okno umiejętności (zakładka „Kamienie”), okno „Postać” z sakwą i opisem broni z gniazdami,
## a w lochu walka - Rzut mieczem z Mnożeniem (widmowe miecze), Żar, Szron i Piorun na goblinach.
## Użycie: SCRIPT=tools/gem_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_umiejetnosci.png, _1b_gniazdo, _1c_kamien (wybór kamienia), _2_postac, _2b_statystyki, _2c_sakwa,
## _3_opis, _3b_gniazdo, _4_rzut.png, _5_zar.png

var _prefix := "/tmp/kamienie"


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
	game.hero_level = 15
	game.dungeon_level = 9
	game.dev_skills()
	game.dev_gems()
	game.add_gem("ember:1", 2)
	game.open_skill_socket("throw")
	game.socket_skill("throw", 0, "multi:2")
	game.socket_skill("throw", 1, "discharge:2")
	game.socket_skill("strike", 0, "ember:2")
	game.socket_skill("strike", 1, "rime:2")
	var weapon_item := Items.roll(9, "earring", "rare")
	weapon_item.sockets = ["ruby:2", ""]
	game.bag = [weapon_item, Items.roll(9, "helmet", "magic"), Items.roll(9, "ring", "rare")]
	game.equip(0)
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.open_skills()
	var win: SkillsWindow = arena.skills_window
	win.set_gems_mode(true)
	win.list_icons[Skills.ORDER.find("throw")].pressed.emit()
	await create_timer(0.2).timeout
	await _shot("1_umiejetnosci")
	win.socket_slots[2].pressed.emit()  # puste gniazdo: pasujące kamienie
	await create_timer(0.2).timeout
	await _shot("1b_gniazdo")
	win.picker.close()
	for p in win.pouch_row.get_children():
		if p.gem == "ember:1":
			p.pressed.emit()  # kamień z sakwy: gdzie pasuje
	await create_timer(0.2).timeout
	await _shot("1c_kamien")
	win.picker.close()
	win.close()
	var stats: HeroStats = arena.stats_window
	stats.open()
	await create_timer(0.2).timeout
	await _shot("2_postac")
	stats.set_tab("stats")
	await create_timer(0.2).timeout
	await _shot("2b_statystyki")
	stats.set_tab("pouch")
	await create_timer(0.2).timeout
	await _shot("2c_sakwa")
	stats.set_tab("equip")
	stats._select_equipped("earring")
	await create_timer(0.2).timeout
	await _shot("3_opis")
	stats._on_item_socket(1)
	await create_timer(0.2).timeout
	await _shot("3b_gniazdo")
	stats.picker.close()
	stats.close()
	arena.pause_menu.visible = false
	paused = false
	arena.queue_free()
	game.dungeon_level = 3
	game.save_game()
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(4.0).timeout
	var weapon: ProtoWeapon = arena.weapon
	weapon.cast("throw")
	await create_timer(0.3).timeout
	await _shot("4_rzut")
	await create_timer(1.2).timeout
	weapon.attack_held = true
	await create_timer(1.6).timeout
	await _shot("5_zar")
	weapon.attack_held = false
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

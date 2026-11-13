extends SceneTree
## Test okna trybu deweloperskiego (DevWindow): przycisk w pauzie, statystyki suwakami zamiast przedmiotów (z sufitami,
## obrażenia broni, ↺ i „wszystkie z przedmiotów”, zapis w ustawieniach), poziom postaci ustawiany wprost,
## wszystkie poziomy lochu bez przebijania (Game.unlocked_level, wybór poziomu ze skokami o 10), „wstecz” zamyka okno.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.dev_stats = {}
	game.dev_all_levels = false
	game.auto_attack = false
	_test_data(game)
	await _test_window(game)
	await _test_levels(game)
	game.dev_stats = {}
	game.dev_all_levels = false
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data(game: Node) -> void:
	game.dev_set_stat("dodge_pct", 80.0)
	game.dev_set_stat("hp", 500.0)
	game.dev_set_stat(Items.WEAPON_DAMAGE, 100.0)
	var g: Dictionary = game.gear()
	_check(g.dodge_pct == Items.CAPS.dodge_pct, "suwak nie przebija sufitu uniku (%d%%)" % g.dodge_pct)
	_check(g.hp == 500.0 and g.damage == Vector2i(100, 140), "zdrowie i obrażenia broni z trybu deweloperskiego")
	game.save_settings()
	game.dev_stats = {}
	game.load_settings()
	_check(game.dev_stats.get("hp", 0.0) == 500.0, "statystyki zapamiętane w ustawieniach")
	game.dev_clear_stat("hp")
	_check(game.gear().hp == 0.0, "↺: zdrowie znów z przedmiotów")
	game.dev_clear_stats()
	_check(game.gear().damage == Vector2i.ZERO and game.gear().dodge_pct == 0.0, "wszystkie statystyki z przedmiotów")
	game.dev_set_level(20)
	_check(game.hero_level == 20 and game.hero_xp == 0, "poziom postaci ustawiony wprost")
	game.dev_set_level(999)
	_check(game.hero_level == HeroLevels.MAX_LEVEL, "poziom postaci najwyżej %d" % HeroLevels.MAX_LEVEL)
	game.dev_set_level(1)
	game.best_level = 0
	_check(game.unlocked_level() == 1, "bez trybu: tylko 1. poziom lochu")
	game.dev_all_levels = true
	_check(game.unlocked_level() == game.DEV_MAX_LEVEL, "tryb: wszystkie poziomy lochu (%d)" % game.unlocked_level())
	game.dev_all_levels = false


func _test_window(game: Node) -> void:
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.running = false
	var menu: PauseMenu = arena.pause_menu
	arena._open_menu()
	_check(menu.dev_button.get_global_rect().size.y >= 44.0, "przycisk „Tryb deweloperski” w pauzie, 44 px")
	menu.dev_button.pressed.emit()
	await process_frame
	var dev: DevWindow = menu.dev
	_check(dev.visible and dev.stat_rows.size() == Items.STAT_FORMATS.size() + 1, "okno: wiersz dla każdej statystyki i obrażeń broni")
	var row: Dictionary = dev.stat_rows["area_pct"]
	_check(row.slider.max_value == Items.CAPS.area_pct and row.reset.disabled, "suwak obszaru do sufitu, ↺ nieaktywne")
	_check(row.slider.get_global_rect().size.y >= 44.0 and row.reset.get_global_rect().size.x >= 44.0, "suwak i przyciski 44 px")
	row.slider.value = 60.0
	_check(is_equal_approx(arena.weapon.area_bonus, 60.0) and not row.reset.disabled, "suwak od razu zmienia obszar miecza")
	_check(row.label.text == Items.stat_text("area_pct", 60.0), "opis wartości: " + row.label.text)
	var hp_row: Dictionary = dev.stat_rows["hp"]
	hp_row.slider.value = 300.0
	_check(arena.hero.max_hp == HeroLevels.max_hp(game.hero_level) + 300, "zdrowie postaci z suwaka (%d)" % arena.hero.max_hp)
	row.reset.pressed.emit()
	_check(arena.weapon.area_bonus == 0.0 and row.slider.value == 0.0, "↺ przywraca przedmioty")
	dev.clear_stats_button.pressed.emit()
	_check(game.dev_stats.is_empty(), "„Wszystkie z przedmiotów”")
	var lvl: int = game.hero_level
	dev.hero_level_label.get_parent().get_child(dev.hero_level_label.get_index() + 1).get_child(3).pressed.emit()
	_check(game.hero_level == lvl + 10 and dev.hero_level_label.text == "Poziom postaci: %d" % (lvl + 10), "+10 poziomów postaci")
	_check(arena.hero_level_label.text == "Poz. %d" % (lvl + 10), "arena pokazuje nowy poziom")
	menu.back()
	_check(not dev.visible and menu.visible, "„wstecz” zamyka okno deweloperskie, pauza zostaje")
	menu.close()
	_check(not paused, "gra rusza")
	arena.queue_free()
	await process_frame
	game.dev_set_level(1)


func _test_levels(game: Node) -> void:
	game.best_level = 0
	game.dev_all_levels = true
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.open_picker()
	var picker: LevelPicker = arena.picker
	_check(picker.max_level == game.DEV_MAX_LEVEL and picker.plus10_button.visible, "wybór poziomu: wszystkie, skoki o 10")
	picker.plus10_button.pressed.emit()
	picker.plus10_button.pressed.emit()
	_check(picker.level == game.dungeon_level + 20, "+10 dwa razy (poziom %d)" % picker.level)
	_check(picker.get_global_rect().size.x >= picker.plus10_button.get_global_rect().end.x, "rząd strzałek mieści się na ekranie")
	picker.close()
	game.dev_all_levels = false
	arena.open_picker()
	_check(picker.max_level == 1 and not picker.plus10_button.visible, "bez trybu: 1 poziom, bez skoków o 10")
	picker.close()
	arena.queue_free()
	await process_frame

extends SceneTree
## Test wielu postaci (Game: list_characters, create_character, select_character, delete_character): osobne zapisy
## (poziom, złoto, tryb deweloperski), wspólna skrzynia postaci bez SSF, własna skrzynia postaci SSF, przeniesienie
## starego pojedynczego zapisu, ekran wyboru postaci w menu (karty, usuwanie z potwierdzeniem, formularz nowej).

const DIR := "user://test_characters/"
const SHARED := "user://test_shared_stash.json"
const LEGACY := "user://test_legacy_save.json"

var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _clean() -> void:
	var dir := DirAccess.open(DIR)
	if dir:
		for f in dir.get_files():
			DirAccess.remove_absolute(DIR + f)
	DirAccess.remove_absolute(SHARED)
	DirAccess.remove_absolute(LEGACY + ".old")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.chars_dir = DIR
	game.shared_stash_path = SHARED
	game.legacy_path = LEGACY
	game.save_path = "user://test_savegame.json"  # ustawienia testowe
	_clean()
	_test_slots(game)
	_test_migrate(game)
	await _test_menu(game)
	_clean()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute("user://test_savegame.json")
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_slots(game: Node) -> void:
	var a: String = game.create_character("Ala", false)
	var b: String = game.create_character("Bolko", false)
	var c: String = game.create_character("Samotnik", true)
	var list: Array = game.list_characters()
	_check(list.size() == 3 and list[0].name == "Ala" and list[2].ssf, "trzy postacie, kolejność tworzenia, SSF")
	game.select_character(a)
	_check(game.character == a and game.char_name == "Ala" and game.hero_level == 1, "wybór postaci wczytuje jej zapis")
	game.gold = 500
	game.hero_level = 7
	game.stash[0].append(Items.roll(5))
	game.dev_immortal = true
	game.save_settings()
	game.select_character(b)
	_check(game.gold == 0 and game.hero_level == 1 and not game.dev_immortal, "druga postać osobno: złoto, poziom, tryb deweloperski")
	_check(game.stash[0].size() == 1, "wspólna skrzynia: przedmiot postaci Ala widać u Bolka")
	game.select_character(c)
	_check(game.ssf and game.stash[0].is_empty(), "SSF: własna, pusta skrzynia")
	game.stash[0].append(Items.roll(5))
	game.save_game()
	game.select_character(b)
	_check(game.stash[0].size() == 1, "przedmiot postaci SSF nie trafia do wspólnej skrzyni")
	game.reset_hero()
	_check(game.stash[0].size() == 1, "„postać od nowa” nie czyści wspólnej skrzyni")
	game.select_character(a)
	_check(game.gold == 500 and game.hero_level == 7 and game.dev_immortal, "powrót do Ali: wszystko zostało")
	_check(game.last_character == a, "ostatnia postać zapamiętana")
	var info: Dictionary = game.list_characters()[0]
	_check(info.level == 7 and info.dev, "karta: poziom i znaczek trybu deweloperskiego")
	game.delete_character(b)
	_check(game.list_characters().size() == 2, "usunięcie postaci")
	game.delete_character(a)
	_check(game.character == "" and game.save_path == "" and game.last_character == "", "usunięcie obecnej: brak wybranej postaci")
	game.save_game()  # bez postaci - nic się nie zapisuje
	_check(game.list_characters().size() == 1, "bez wybranej postaci nic nie powstaje")


func _test_migrate(game: Node) -> void:
	var f := FileAccess.open(LEGACY, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hero_level": 12, "gold": 77, "stash": [[Items.roll(3)]]}))
	f.close()
	game._migrate_legacy()
	_check(not FileAccess.file_exists(LEGACY) and FileAccess.file_exists(DIR + "c0.json"), "stary zapis przeniesiony na postać")
	game.select_character("c0")
	_check(game.char_name == Game.DEFAULT_NAME and game.hero_level == 12 and game.gold == 77, "przeniesiona postać: Wojciech, poziom i złoto")


func _test_menu(game: Node) -> void:
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var sel: CharacterSelect = menu.characters
	sel.play.disconnect(menu._on_character)
	var chosen: Array = []
	sel.play.connect(func(id: String) -> void: chosen.append(id))
	menu.get_node("%Play").pressed.emit()
	await process_frame
	_check(sel.visible and sel.list.get_child_count() == 2, "„Graj” pokazuje karty postaci")
	var card: Node = sel.list.get_child(0)
	var play_button: Button = card.find_child("Play", true, false)
	_check(play_button.get_global_rect().size.y >= 44.0, "przycisk „Graj” na karcie dość duży")
	play_button.pressed.emit()
	_check(chosen.size() == 1, "„Graj” na karcie wybiera postać")
	var del: Button = card.find_child("Delete", true, false)
	del.pressed.emit()
	await process_frame
	_check(game.list_characters().size() == 2, "pierwsze „Usuń” tylko pyta")
	(sel.list.get_child(0).find_child("Delete", true, false) as Button).pressed.emit()
	await process_frame
	_check(game.list_characters().size() == 1, "drugie stuknięcie usuwa")
	sel.new_button.pressed.emit()
	_check(sel.form.visible, "„Nowa postać” otwiera formularz")
	sel.name_edit.text = "Mira"
	sel.ssf_button.pressed.emit()
	sel.create_button.pressed.emit()
	await process_frame
	var names: Array = game.list_characters().map(func(ch: Dictionary) -> String: return ch.name)
	_check(names.has("Mira") and not sel.form.visible and chosen.size() == 2, "formularz tworzy postać i od razu ją wybiera")
	_check(game.list_characters().filter(func(ch: Dictionary) -> bool: return ch.name == "Mira")[0].ssf, "nowa postać SSF")
	menu.queue_free()
	await process_frame

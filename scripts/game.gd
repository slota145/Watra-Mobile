extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen, ścieżka zapisu i ustawienia gracza.
## Ustawienia (np. przyciski po lewej) leżą osobno od zapisu gry, w user://settings.cfg.
## Zapis gry (save_path, JSON) trzyma na razie tylko włączone aury.

const MENU_SCENE := "res://scenes/main_menu.tscn"
## Zapis gracza. Testy podmieniają go na osobny plik, żeby nie ruszać prawdziwego zapisu.
const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"

## Testy ustawiają osobny plik zapisu - wtedy ustawienia też idą do osobnego pliku.
var save_path := SAVE_PATH:
	set(value):
		save_path = value
		settings_path = SETTINGS_PATH if value == SAVE_PATH else TEST_SETTINGS_PATH
		load_settings()
		load_game()
var settings_path := SETTINGS_PATH
## Atak i umiejętności w lewym dolnym rogu (dla osób, które wolą trzymać je lewym kciukiem).
var left_handed := false
## Gest ręką postaci przy ataku (prototyp - porównanie wersji z gestem i bez).
var gesture := true
## Włączone aury (identyfikatory z AuraData) - zakładka „Aury” w oknie pauzy.
var auras: Array[String] = []
## Redukcja rezerwacji aur (0.1 = aury rezerwują 10% mniej). Później z poziomów aur i przedmiotów.
var aura_reduction := 0.0


func _ready() -> void:
	# jak w Watrze: gra startuje po polsku, niezależnie od języka telefonu (wybór języka dojdzie w ustawieniach)
	Lang.set_language(Lang.DEFAULT)
	load_settings()
	load_game()


## Numer wersji gry z project.godot (pokazywany w rogu menu).
func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## Przejście do innej sceny (np. z menu do gry).
func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		cfg = ConfigFile.new()
	left_handed = cfg.get_value("controls", "left_handed", false)
	gesture = cfg.get_value("controls", "gesture", true)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "gesture", gesture)
	cfg.save(settings_path)


func load_game() -> void:
	auras.clear()
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		for id in data.get("auras", []):
			if AuraData.is_aura(str(id)) and not auras.has(str(id)):
				auras.append(str(id))


func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"auras": auras}))

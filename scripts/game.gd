extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen, ścieżka zapisu i ustawienia gracza.
## Ustawienia (np. przyciski po lewej) leżą osobno od zapisu gry, w user://settings.cfg.
## Zapis gry (JSON w `save_path`): żar zgromadzony w Watrze (`embers`) i najwyższy przebity poziom lochu (`best_level`).

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
## Żar zgromadzony w Watrze (z iskier zebranych w lochach i doniesionych do bazy).
var embers := 0
## Żar doniesiony z ostatniego lochu - baza pokazuje go nad Watrą i zeruje.
var embers_brought := 0
## Najwyższy poziom lochu, na którym pokonano bossa (0 - jeszcze żaden). Odblokowany jest o jeden wyższy.
var best_level := 0
## Poziom lochu wybrany przy Watrze (na niego wchodzi scena lochu).
var dungeon_level := 1
## Atak i umiejętności w lewym dolnym rogu (dla osób, które wolą trzymać je lewym kciukiem).
var left_handed := false
## Gest ręką postaci przy ataku (prototyp - porównanie wersji z gestem i bez).
var gesture := true


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
	embers = 0
	embers_brought = 0
	best_level = 0
	dungeon_level = 1
	if not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		embers = int(data.get("embers", 0))
		best_level = int(data.get("best_level", 0))
		dungeon_level = clampi(int(data.get("dungeon_level", 1)), 1, unlocked_level())


func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"embers": embers, "best_level": best_level, "dungeon_level": dungeon_level}))


## Żar doniesiony z lochu do Watry (powrót do bazy, nie śmierć) - od razu zapisany.
func bank_embers(amount: int) -> void:
	if amount <= 0:
		return
	embers += amount
	embers_brought += amount
	save_game()


## Najwyższy poziom lochu, na który można wejść (jeden nad najwyższym przebitym).
func unlocked_level() -> int:
	return best_level + 1


## Boss pokonany na poziomie `level` - odblokowuje następny (zapis od razu). Zwraca true, gdy to nowy rekord.
func beat_level(level: int) -> bool:
	if level <= best_level:
		return false
	best_level = level
	save_game()
	return true

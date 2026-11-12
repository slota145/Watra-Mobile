extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen i ścieżka zapisu.
## Na razie szkielet - zapis gry dojdzie razem z pierwszymi systemami.

const MENU_SCENE := "res://scenes/main_menu.tscn"
## Zapis gracza. Testy podmieniają go na osobny plik, żeby nie ruszać prawdziwego zapisu.
const SAVE_PATH := "user://savegame.json"

var save_path := SAVE_PATH


func _ready() -> void:
	# jak w Watrze: gra startuje po polsku, niezależnie od języka telefonu (wybór języka dojdzie w ustawieniach)
	Lang.set_language(Lang.DEFAULT)


## Numer wersji gry z project.godot (pokazywany w rogu menu).
func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## Przejście do innej sceny (np. z menu do gry).
func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

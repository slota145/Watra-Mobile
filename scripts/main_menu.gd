extends Control
## Ekran startowy (na razie zaślepka): tytuł, hasło gry, przycisk „Graj” (prototyp walki) i numer wersji.
## Służy do sprawdzenia, że projekt działa w pionie na telefonie i na komputerze.

## Na razie „Graj” otwiera prototyp walki (lewitujący miecz i kukły).
const PROTOTYPE_SCENE := "res://scenes/prototype.tscn"

@onready var _play: Button = %Play
@onready var _version: Label = %Version
@onready var _note: Label = %Note


func _ready() -> void:
	_version.text = tr("Wersja %s") % Game.version()
	_play.pressed.connect(_on_play)


func _on_play() -> void:
	Game.change_scene(PROTOTYPE_SCENE)

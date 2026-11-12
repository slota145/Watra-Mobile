extends Control
## Ekran startowy (na razie zaślepka): tytuł, hasło gry, przycisk „Graj” i numer wersji.
## Służy do sprawdzenia, że projekt działa w pionie na telefonie i na komputerze.

@onready var _play: Button = %Play
@onready var _version: Label = %Version
@onready var _note: Label = %Note


func _ready() -> void:
	_version.text = tr("Wersja %s") % Game.version()
	_play.pressed.connect(_on_play)


func _on_play() -> void:
	_note.text = tr("Gra jeszcze powstaje - wróć wkrótce!")

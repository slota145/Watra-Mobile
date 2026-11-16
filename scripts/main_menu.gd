extends Control
## Ekran startowy: tytuł, hasło gry, „Graj” (prototyp walki), aktualizacja wersji testowej i numer wersji.
## „Aktualizuj” pojawia się tylko w wyeksportowanej grze (Updater.enabled): menu samo sprawdza, czy jest
## nowa kompilacja, a przycisk pobiera paczkę z grą (kilka MB zamiast całego apk).

## „Graj” otwiera wybór postaci (CharacterSelect, wiele postaci); wybrana postać wchodzi do bazy (prototyp).
const PROTOTYPE_SCENE := "res://scenes/prototype.tscn"

var update_button: Button
var characters: CharacterSelect

@onready var _play: Button = %Play
@onready var _version: Label = %Version
@onready var _note: Label = %Note


func _ready() -> void:
	_play.pressed.connect(_on_play)
	characters = CharacterSelect.new()
	characters.visible = false
	characters.play.connect(_on_character)
	$SafeArea.add_child(characters)
	update_button = Button.new()
	update_button.custom_minimum_size = Vector2(200, 44)
	update_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	update_button.pressed.connect(_on_update_pressed)
	_play.add_sibling(update_button)
	_show_version()
	Updater.state_changed.connect(_on_update_state)
	_on_update_state(Updater.state)
	if Updater.enabled and Updater.state == "idle":
		Updater.check()


func _process(_delta: float) -> void:
	if Updater.state == "downloading":
		_note.text = tr("Pobieranie... %d%%") % roundi(Updater.progress() * 100.0)


func _show_version() -> void:
	_version.text = tr("Wersja %s") % Game.version()
	if Updater.build > 0:
		_version.text += " " + tr("(kompilacja %d)") % Updater.build


func _on_play() -> void:
	characters.open()


func _on_character(id: String) -> void:
	Game.select_character(id)
	Game.change_scene(PROTOTYPE_SCENE)


## Przycisk „wstecz” na Androidzie: zamyka formularz albo wybór postaci.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and characters and characters.visible:
		if characters.form.visible:
			characters.form.visible = false
		else:
			characters.visible = false


func _on_update_pressed() -> void:
	match Updater.state:
		"available":
			Updater.download()
		"ready":
			get_tree().quit()  # nowa wersja wczyta się przy następnym uruchomieniu
		"need_apk":
			OS.shell_open(Updater.APK_URL)
		"error", "up_to_date":
			Updater.check()


func _on_update_state(state: String) -> void:
	update_button.visible = Updater.enabled and state not in ["idle", "checking", "downloading"]
	var remote_build := int(Updater.remote.get("build", 0))
	match state:
		"checking":
			_note.text = tr("Sprawdzam, czy jest nowa wersja...")
		"up_to_date":
			_note.text = tr("Masz najnowszą wersję.")
			update_button.text = tr("Sprawdź ponownie")
		"available":
			_note.text = tr("Jest nowa wersja (kompilacja %d)!") % remote_build
			update_button.text = tr("Aktualizuj")
		"ready":
			_note.text = tr("Pobrano! Zamknij grę i otwórz ją ponownie.")
			update_button.text = tr("Zamknij grę")
		"need_apk":
			_note.text = tr("Ta wersja wymaga pobrania całej gry.")
			update_button.text = tr("Pobierz całą grę")
		"error":
			_note.text = tr("Nie udało się pobrać aktualizacji. Sprawdź internet.")
			update_button.text = tr("Spróbuj ponownie")
		_:
			_note.text = ""

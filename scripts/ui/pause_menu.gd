class_name PauseMenu
extends Control
## Okno pauzy w trakcie gry (przycisk „Menu”): zatrzymuje grę i daje ustawienia sterowania -
## atak i umiejętności po lewej stronie, gest postaci przy ataku - oraz powrót do gry i wyjście do menu głównego.
## Ustawienia zapisuje Game (user://settings.cfg). Działa także przy zatrzymanej grze (PROCESS_MODE_ALWAYS).
## Autoload Game bierzemy z drzewa (_game), bo w skrypcie z class_name nazwa autoloadu nie zawsze jest znana
## (np. w testach uruchamianych przez -s).

signal closed

var left_toggle: CheckButton
var gesture_toggle: CheckButton
var resume_button: Button
var quit_button: Button
## Scena bazy - gdy ustawiona (w lochu), okno ma też przycisk „Powrót do bazy”.
var base_scene := ""
var base_button: Button
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # zasłania grę pod spodem
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.06, 0.95)
	style.border_color = Color(0.85, 0.62, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(260, 0)
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = tr("Pauza")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.78, 0.35))
	column.add_child(title)
	left_toggle = _toggle(column, tr("Atak i umiejętności po lewej"), _game.left_handed)
	left_toggle.toggled.connect(func(on: bool) -> void:
		_game.left_handed = on
		_game.save_settings())
	gesture_toggle = _toggle(column, tr("Gest postaci przy ataku"), _game.gesture)
	gesture_toggle.toggled.connect(func(on: bool) -> void:
		_game.gesture = on
		_game.save_settings())
	resume_button = _button(column, tr("Wróć do gry"))
	resume_button.pressed.connect(close)
	if base_scene != "":
		base_button = _button(column, tr("Powrót do bazy"))
		base_button.pressed.connect(func() -> void: _game.change_scene(base_scene))
	quit_button = _button(column, tr("Menu główne"))
	quit_button.pressed.connect(func() -> void: _game.change_scene(_game.MENU_SCENE))


## Pokazuje okno i zatrzymuje grę.
func open() -> void:
	left_toggle.set_pressed_no_signal(_game.left_handed)
	gesture_toggle.set_pressed_no_signal(_game.gesture)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _toggle(parent: Control, text: String, on: bool) -> CheckButton:
	var t := CheckButton.new()
	t.text = text
	t.button_pressed = on
	t.custom_minimum_size = Vector2(0, 44)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(t)
	return t


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	parent.add_child(b)
	return b

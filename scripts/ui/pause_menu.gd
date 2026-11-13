class_name PauseMenu
extends Control
## Okno pauzy w trakcie gry (przycisk „Menu”): zatrzymuje grę i daje ustawienia sterowania -
## atak i umiejętności po lewej stronie, gest postaci przy ataku, auto atak (umiejętność pod dużym przyciskiem), tryb deweloperski
## (przycisk otwiera DevWindow: nieśmiertelność, wszystkie poziomy lochu, skróty, poziom postaci, statystyki suwakami)
## - oraz powrót do gry i wyjście do menu głównego. Okna „Postać”
## i umiejętności otwierają ikonki w górnym rzędzie areny (decyzja autora 13.11.2026), nie pauza.
## Skróty zmieniają postać w Game (arena słucha jego sygnałów), żar - sygnał `dev_embers` (arena dodaje go
## do paska wyprawy w lochu albo do Watry w bazie). Okno przewija się, gdy nie mieści się na niskim ekranie.
## W lochu „Uciekaj do bazy” i „Menu główne” pytają „Na pewno?” (drugie stuknięcie wychodzi), żeby nie stracić
## wyprawy przypadkiem.
## Ustawienia zapisuje Game (user://settings.cfg). Działa także przy zatrzymanej grze (PROCESS_MODE_ALWAYS).
## Autoload Game bierzemy z drzewa (_game), bo w skrypcie z class_name nazwa autoloadu nie zawsze jest znana
## (np. w testach uruchamianych przez -s).

signal closed
## Gracz wychodzi z gry przyciskiem okna („Powrót do bazy” albo „Menu główne”) - tuż przed zmianą sceny.
signal leaving
## Tryb deweloperski: dodaj tyle żaru.
signal dev_embers(amount: int)

var left_toggle: CheckButton
var gesture_toggle: CheckButton
var auto_toggle: CheckButton
## Przycisk i okno trybu deweloperskiego.
var dev_button: Button
var dev: DevWindow
## Wyjście z lochu czekające na potwierdzenie (przycisk albo null).
var _leave_armed: Button = null
var _scroll: ScrollContainer
var _column: VBoxContainer
var resume_button: Button
var quit_button: Button
## Scena bazy - gdy ustawiona (w lochu), okno ma też przycisk „Powrót do bazy”.
var base_scene := ""
var base_button: Button
## Ostrzeżenie pod przyciskiem powrotu w lochu (ucieczka gasi żar z wyprawy) - pokazywane, gdy jest co stracić.
var leave_note: Label
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
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	var column := VBoxContainer.new()
	_column = column
	column.custom_minimum_size = Vector2(260, 0)
	column.add_theme_constant_override("separation", 8)
	_scroll.add_child(column)
	column.resized.connect(_fit)  # zawijane napisy znają swoją wysokość dopiero po ułożeniu
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
	auto_toggle = _toggle(column, tr("Auto atak (duży przycisk)"), _game.auto_attack)
	auto_toggle.toggled.connect(func(on: bool) -> void:
		_game.auto_attack = on
		_game.save_settings())
	dev_button = _button(column, tr("Tryb deweloperski"))
	dev_button.add_theme_color_override("font_color", Color(1, 0.7, 0.5))
	dev_button.pressed.connect(func() -> void: dev.open())
	dev = DevWindow.new()
	dev.visible = false
	dev.dev_embers.connect(func(amount: int) -> void: dev_embers.emit(amount))
	resume_button = _button(column, tr("Wróć do gry"))
	resume_button.pressed.connect(close)
	if base_scene != "":
		base_button = _button(column, tr("Uciekaj do bazy"))
		base_button.pressed.connect(func() -> void: _leave(base_button, base_scene))
		leave_note = Label.new()
		leave_note.text = tr("Żar z wyprawy zgaśnie - do Watry trafia tylko po pokonaniu bossa.")
		leave_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		leave_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leave_note.add_theme_font_size_override("font_size", 11)
		leave_note.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
		leave_note.visible = false
		column.add_child(leave_note)
	quit_button = _button(column, tr("Menu główne"))
	quit_button.pressed.connect(func() -> void: _leave(quit_button, _game.MENU_SCENE))
	add_child(dev)  # nad oknem pauzy


## Pokazuje okno i zatrzymuje grę. `at_stake` - żar, który zgaśnie przy ucieczce z lochu.
func open(at_stake := 0) -> void:
	if leave_note:
		leave_note.visible = at_stake > 0
	left_toggle.set_pressed_no_signal(_game.left_handed)
	gesture_toggle.set_pressed_no_signal(_game.gesture)
	auto_toggle.set_pressed_no_signal(_game.auto_attack)
	_disarm_leave()
	visible = true
	_fit.call_deferred()
	get_tree().paused = true


## Przycisk „wstecz”: zamyka okno deweloperskie, a gdy go nie ma - pauzę.
func back() -> void:
	if dev.visible:
		dev.close()
		return
	close()


func close() -> void:
	dev.visible = false
	visible = false
	get_tree().paused = false
	closed.emit()


## Okno nie wyższe niż ekran (minus margines) - reszta przewija się palcem.
func _fit() -> void:
	var limit := get_viewport_rect().size.y - 40.0
	_scroll.custom_minimum_size = Vector2(260, minf(maxf(_column.size.y, _column.get_combined_minimum_size().y), limit))


## Wyjście ze sceny. W lochu pierwsze stuknięcie zmienia napis na „Na pewno?”, dopiero drugie wychodzi.
func _leave(button: Button, scene: String) -> void:
	if base_scene != "" and _leave_armed != button:
		_disarm_leave()
		_leave_armed = button
		button.text = tr("Na pewno?")
		button.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
		return
	leaving.emit()
	_game.change_scene(scene)


func _disarm_leave() -> void:
	_leave_armed = null
	if base_button:
		base_button.text = tr("Uciekaj do bazy")
		base_button.remove_theme_color_override("font_color")
	quit_button.text = tr("Menu główne")
	quit_button.remove_theme_color_override("font_color")


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

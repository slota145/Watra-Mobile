class_name PauseMenu
extends Control
## Okno pauzy w trakcie gry (przycisk „Menu”): zatrzymuje grę i daje ustawienia sterowania -
## atak i umiejętności po lewej stronie, gest postaci przy ataku - oraz powrót do gry i wyjście do menu głównego.
## Druga zakładka, „Aury”: lista wszystkich aur (AuraData) z przełącznikami - włączona aura rezerwuje część many,
## razem najwyżej AuraData.MAX_RESERVED; włączone aury zapisuje Game (save_game).
## Ustawienia zapisuje Game (user://settings.cfg). Działa także przy zatrzymanej grze (PROCESS_MODE_ALWAYS).
## Autoload Game bierzemy z drzewa (_game), bo w skrypcie z class_name nazwa autoloadu nie zawsze jest znana
## (np. w testach uruchamianych przez -s).

signal closed

var left_toggle: CheckButton
var gesture_toggle: CheckButton
var resume_button: Button
var quit_button: Button
var game_tab: Button
var auras_tab: Button
## Przełączniki aur (identyfikator -> CheckButton).
var aura_toggles := {}
## Postać, której aury zmieniamy (arena) - przelicza zdrowie i manę po zmianie.
var hero: ProtoHero
var _game_page: VBoxContainer
var _aura_page: VBoxContainer
var _aura_summary: Label
var _aura_message: Label
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
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	var group := ButtonGroup.new()
	game_tab = _tab(tabs, tr("Gra"), group)
	auras_tab = _tab(tabs, tr("Aury"), group)
	game_tab.button_pressed = true
	game_tab.toggled.connect(func(on: bool) -> void: _show_page(not on))
	_game_page = VBoxContainer.new()
	_game_page.add_theme_constant_override("separation", 10)
	column.add_child(_game_page)
	_make_aura_page(column)
	column = _game_page
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
	quit_button = _button(column, tr("Menu główne"))
	quit_button.pressed.connect(func() -> void: _game.change_scene(_game.MENU_SCENE))


## Pokazuje okno i zatrzymuje grę.
func open() -> void:
	left_toggle.set_pressed_no_signal(_game.left_handed)
	gesture_toggle.set_pressed_no_signal(_game.gesture)
	_refresh_auras()
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _show_page(auras: bool) -> void:
	_game_page.visible = not auras
	_aura_page.visible = auras
	_aura_message.text = ""


func _tab(parent: Control, text: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.add_theme_color_override("font_pressed_color", Color(1, 0.78, 0.35))
	b.add_theme_color_override("font_hover_pressed_color", Color(1, 0.78, 0.35))
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


## Zakładka „Aury”: podsumowanie many, komunikat i przewijana lista aur.
func _make_aura_page(parent: Control) -> void:
	_aura_page = VBoxContainer.new()
	_aura_page.add_theme_constant_override("separation", 6)
	_aura_page.visible = false
	parent.add_child(_aura_page)
	_aura_summary = Label.new()
	_aura_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aura_summary.add_theme_font_size_override("font_size", 12)
	_aura_page.add_child(_aura_summary)
	_aura_message = Label.new()
	_aura_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aura_message.add_theme_font_size_override("font_size", 12)
	_aura_message.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
	_aura_page.add_child(_aura_message)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_aura_page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for id in AuraData.ORDER:
		list.add_child(_aura_row(id))


func _aura_row(id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var dot := ColorRect.new()
	dot.color = AuraData.color_of(id)
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_label := Label.new()
	name_label.text = AuraData.name_of(id)
	name_label.add_theme_color_override("font_color", AuraData.color_of(id).lerp(Color.WHITE, 0.3))
	name_label.add_theme_font_size_override("font_size", 14)
	text.add_child(name_label)
	var desc := Label.new()
	desc.text = AuraData.effect_text(id) + " (" + AuraData.cost_text(id, _game.aura_reduction) + ")"
	if not AuraData.is_ready(id):
		desc.text += " - " + tr("zadziała w lochach")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
	text.add_child(desc)
	var toggle := CheckButton.new()
	toggle.custom_minimum_size = Vector2(44, 44)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.toggled.connect(_on_aura_toggled.bind(id))
	row.add_child(toggle)
	aura_toggles[id] = toggle
	return row


## Włącza albo wyłącza aurę (gdy brakuje wolnej many - przełącznik wraca i pojawia się komunikat).
func _on_aura_toggled(on: bool, id: String) -> void:
	var auras: Array[String] = _game.auras
	var old_health := hero.max_health() if hero else 0.0
	if on:
		var reason := AuraData.block_reason(id, auras, _game.aura_reduction)
		if reason != "":
			aura_toggles[id].set_pressed_no_signal(false)
			_aura_message.text = reason
			return
		if not auras.has(id):
			auras.append(id)
	else:
		auras.erase(id)
	_aura_message.text = ""
	_game.save_game()
	if hero:
		hero.auras_changed(old_health)
	_refresh_auras()


func _refresh_auras() -> void:
	for id: String in aura_toggles:
		aura_toggles[id].set_pressed_no_signal(_game.auras.has(id))
	var used := AuraData.reserved_total(_game.auras, _game.aura_reduction)
	_aura_summary.text = tr("Aury rezerwują %d%% many (najwyżej %d%%). Wolna mana zostaje na umiejętności.") % [
			roundi(used * 100), roundi(AuraData.MAX_RESERVED * 100)]


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

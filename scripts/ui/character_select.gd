class_name CharacterSelect
extends Control
## Wybór postaci po „Graj” w menu (wiele postaci, decyzje autora 16.11.2026): przewijana lista kart (Game.list_characters)
## - ikona broni, nazwa, poziom postaci, najgłębszy przebity loch, znaczki „SSF” i „Tryb deweloperski”, przyciski
## „Graj” i „Usuń” (drugie stuknięcie potwierdza). Na dole „Nowa postać” (formularz: nazwa i wybór skrzyni - wspólna
## albo SSF, tylko własny łup) i „Wróć”. Bez postaci formularz otwiera się od razu. Sygnał `play` z identyfikatorem.

signal play(id: String)

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.75)
const SSF_COLOR := Color(0.55, 0.85, 1.0)
const DEV_COLOR := Color(0.6, 1.0, 0.6)

var list: VBoxContainer
var new_button: Button
var back_button: Button
## Formularz nowej postaci.
var form: Control
var name_edit: LineEdit
var shared_button: Button
var ssf_button: Button
var create_button: Button
var _ssf := false
## Która postać czeka na potwierdzenie usunięcia ("" - żadna).
var _armed := ""
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 10
	column.offset_right = -10
	column.offset_top = 10
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(_label(tr("Wybierz postać"), 24, GOLD))
	var scroll := ScrollContainer.new()
	TouchUi.drag_scroll(scroll)  # przewijanie palcem po wierszach i przyciskach
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	new_button = _button(column, tr("Nowa postać"), Vector2(240, 52))
	new_button.pressed.connect(open_form)
	back_button = _button(column, tr("Wróć"), Vector2(240, 48))
	back_button.pressed.connect(func() -> void: visible = false)
	_build_form()


## Pokazuje listę postaci (bez żadnej - od razu formularz nowej).
func open() -> void:
	visible = true
	_armed = ""
	refresh()
	if _game.list_characters().is_empty():
		open_form()


func refresh() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	for ch: Dictionary in _game.list_characters():
		_card(ch)


func _card(ch: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.name = "Card_" + ch.id
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08)
	style.border_color = GOLD.darkened(0.3) if ch.id == _game.character else Color(0.45, 0.3, 0.15)
	style.set_border_width_all(2 if ch.id == _game.character else 1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Weapons.icon_of(ch.weapon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var title := _label(ch.name, 17, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(title)
	var info := _label(tr("Poziom %d · najgłębszy loch: %d") % [ch.level, ch.best_level], 12, TEXT)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(info)
	var tags: Array[String] = []
	if ch.ssf:
		tags.append(tr("SSF - tylko własny łup"))
	if ch.dev:
		tags.append(tr("Tryb deweloperski"))
	if not tags.is_empty():
		var tag := _label(" · ".join(tags), 11, SSF_COLOR if ch.ssf else DEV_COLOR)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(tag)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	row.add_child(buttons)
	var play_button := _button(buttons, tr("Graj"), Vector2(84, 44))
	play_button.name = "Play"
	play_button.pressed.connect(func() -> void: play.emit(ch.id))
	var delete_button := _button(buttons, tr("Na pewno?") if _armed == ch.id else tr("Usuń"), Vector2(84, 44))
	delete_button.name = "Delete"
	delete_button.add_theme_font_size_override("font_size", 14)
	if _armed == ch.id:
		delete_button.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
	delete_button.pressed.connect(_delete.bind(ch.id))


## Usunięcie z potwierdzeniem: pierwsze stuknięcie pyta „Na pewno?”, drugie usuwa.
func _delete(id: String) -> void:
	if _armed != id:
		_armed = id
		refresh()
		return
	_armed = ""
	_game.delete_character(id)
	refresh()


func _build_form() -> void:
	form = Control.new()
	form.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	form.mouse_filter = Control.MOUSE_FILTER_STOP
	form.visible = false
	add_child(form)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	form.add_child(bg)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 16
	column.offset_right = -16
	column.offset_top = 24
	column.offset_bottom = -16
	column.add_theme_constant_override("separation", 10)
	form.add_child(column)
	column.add_child(_label(tr("Nowa postać"), 24, GOLD))
	column.add_child(_label(tr("Imię"), 14, DIM))
	# u góry ekranu - klawiatura telefonu zasłania dół
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(0, 48)
	name_edit.max_length = 20
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_size_override("font_size", 18)
	name_edit.placeholder_text = _game.DEFAULT_NAME
	column.add_child(name_edit)
	column.add_child(_label(tr("Skrzynia w bazie"), 14, DIM))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	shared_button = _button(row, tr("Wspólna"), Vector2(150, 48))
	shared_button.toggle_mode = true
	shared_button.pressed.connect(func() -> void: _set_ssf(false))
	ssf_button = _button(row, tr("SSF"), Vector2(150, 48))
	ssf_button.toggle_mode = true
	ssf_button.pressed.connect(func() -> void: _set_ssf(true))
	var hint := _label("", 12, TEXT)
	hint.name = "Hint"
	column.add_child(hint)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(fill)
	create_button = _button(column, tr("Stwórz postać"), Vector2(240, 52))
	create_button.pressed.connect(_create)
	var cancel := _button(column, tr("Anuluj"), Vector2(240, 48))
	cancel.pressed.connect(func() -> void:
		form.visible = false
		if _game.list_characters().is_empty():
			visible = false)


func open_form() -> void:
	name_edit.text = ""
	_set_ssf(false)
	form.visible = true


func _set_ssf(value: bool) -> void:
	_ssf = value
	shared_button.button_pressed = not value
	ssf_button.button_pressed = value
	for b: Button in [shared_button, ssf_button]:  # wybrana - złoty napis
		if b.button_pressed:
			b.add_theme_color_override("font_color", GOLD)
			b.add_theme_color_override("font_pressed_color", GOLD)
		else:
			b.remove_theme_color_override("font_color")
			b.remove_theme_color_override("font_pressed_color")
	var hint: Label = form.find_child("Hint", true, false)
	hint.text = tr("SSF: postać korzysta tylko z tego, co sama zdobędzie - ma własną skrzynię.") if value \
			else tr("Wspólna skrzynia: przedmioty można przekazywać między postaciami.")


func _create() -> void:
	var id: String = _game.create_character(name_edit.text, _ssf)
	form.visible = false
	refresh()
	play.emit(id)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(parent: Control, text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 17)
	parent.add_child(b)
	return b

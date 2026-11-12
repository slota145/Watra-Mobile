class_name RunResult
extends Control
## Okno wyniku w lochu: po śmierci postaci (`show_result` - pokonane potwory, czas, zgasły żar; „Jeszcze raz”)
## albo po pokonaniu bossa (`show_victory` - żar do Watry, odblokowany poziom; „Następny poziom”).
## Pod spodem duże przyciski (w dolnej połowie ekranu, pod kciukiem), drugi to „Powrót do bazy”.
## Działa przy zatrzymanej grze (PROCESS_MODE_ALWAYS).

signal retry
signal back_to_base

var retry_button: Button
var base_button: Button
var _summary: Label
var _title: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.01, 0.0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var spacer := Control.new()  # tytuł nieco nad środkiem, przyciski pod nim
	spacer.custom_minimum_size = Vector2(0, 60)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var title := Label.new()
	_title = title
	title.text = tr("Ogień przygasł…")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.62, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	title.add_theme_constant_override("outline_size", 6)
	column.add_child(title)
	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.add_theme_font_size_override("font_size", 16)
	_summary.add_theme_color_override("font_color", Color(1, 0.92, 0.78))
	_summary.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	_summary.add_theme_constant_override("outline_size", 4)
	column.add_child(_summary)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	retry_button = _button(column, tr("Jeszcze raz"))
	retry_button.pressed.connect(func() -> void: retry.emit())
	base_button = _button(column, tr("Powrót do bazy"))
	base_button.pressed.connect(func() -> void: back_to_base.emit())


## Pokazuje wynik biegu; `lost_embers` - żar zebrany w lochu, który zgasł razem z postacią.
func show_result(kills: int, seconds: float, lost_embers := 0) -> void:
	var s := int(seconds)
	_summary.text = tr("Pokonane gobliny: %d") % kills + "\n" + tr("Przetrwany czas: %d:%02d") % [s / 60, s % 60]
	if lost_embers > 0:
		_summary.text += "\n" + tr("Zgasło żaru: %d") % lost_embers
	visible = true


## Wynik po pokonaniu bossa: `banked` - żar doniesiony do Watry, `unlocked` - nowo odblokowany poziom (0 - żaden).
## Przycisk „Następny poziom: N” (sygnał `retry`) prowadzi na następny poziom lochu.
## `deaths` - ile razy postać zginęłaby bez nieśmiertelności (tryb deweloperski; 0 - linia nie pokazuje się).
func show_victory(level: int, banked: int, unlocked: int, kills: int, seconds: float, deaths := 0) -> void:
	var s := int(seconds)
	_title.text = tr("Wódz pokonany!")
	_title.add_theme_color_override("font_color", Color(1, 0.82, 0.35))
	var lines: Array[String] = [tr("Poziom lochu: %d") % level, tr("Żar do Watry: %d") % banked]
	if unlocked > 0:
		lines.append(tr("Odblokowano poziom %d") % unlocked)
	lines.append(tr("Pokonane gobliny: %d") % kills)
	lines.append(tr("Czas wyprawy: %d:%02d") % [s / 60, s % 60])
	if deaths > 0:
		lines.append(tr("Zgony (nieśmiertelność): %d") % deaths)
	_summary.text = "\n".join(lines)
	retry_button.text = tr("Następny poziom: %d") % (level + 1)
	visible = true


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 18)
	parent.add_child(b)
	return b

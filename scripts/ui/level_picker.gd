class_name LevelPicker
extends Control
## Wybór poziomu lochu po dotknięciu Watry w bazie (jak wybór poziomu szczeliny w Diablo 3): strzałki ◀ ▶ zmieniają
## poziom od 1 do najwyższego odblokowanego (`Game.unlocked_level`), pod spodem siła potworów i nagroda ze skrzyni
## Wodza, na dole duże przyciski „Wejdź” i „Anuluj” (pod kciukiem). Zatrzymuje grę na czas wyboru.
## Wybrany poziom trafia do `Game.dungeon_level` (zapisywany z grą). Nad „Wejdź” przycisk „Ulepszenia lochów”
## (sygnał `upgrades` - arena chowa wybór i otwiera UpgradesWindow; po jego zamknięciu wybór wraca).

signal enter(level: int)
signal canceled
signal upgrades

var level := 1
var max_level := 1
var minus_button: Button
var plus_button: Button
var enter_button: Button
var cancel_button: Button
var upgrades_button: Button
var _level_label: Label
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_END  # wszystko w dolnej części ekranu
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var title := _label(tr("Loch Hordy"), 22, Color(1, 0.78, 0.35))
	column.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	minus_button = _button(row, "◀", Vector2(56, 56))
	minus_button.pressed.connect(func() -> void: set_level(level - 1))
	_level_label = _label("", 24, Color(1, 0.92, 0.78))
	_level_label.custom_minimum_size = Vector2(130, 0)
	row.add_child(_level_label)
	plus_button = _button(row, "▶", Vector2(56, 56))
	plus_button.pressed.connect(func() -> void: set_level(level + 1))
	_info = _label("", 13, Color(1, 0.88, 0.7))
	column.add_child(_info)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	upgrades_button = _button(column, tr("Ulepszenia lochów"), Vector2(220, 48))
	upgrades_button.icon = preload("res://assets/watra/ember_icon.png")
	upgrades_button.add_theme_constant_override("icon_max_width", 20)
	upgrades_button.add_theme_font_size_override("font_size", 16)
	upgrades_button.pressed.connect(func() -> void:
		visible = false
		upgrades.emit())
	enter_button = _button(column, tr("Wejdź"), Vector2(220, 52))
	enter_button.pressed.connect(func() -> void:
		visible = false
		get_tree().paused = false
		enter.emit(level))
	cancel_button = _button(column, tr("Anuluj"), Vector2(220, 48))
	cancel_button.pressed.connect(close)
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 40)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)


## Pokazuje wybór (zaczyna od ostatnio wybranego poziomu) i zatrzymuje grę.
func open(current: int, unlocked: int) -> void:
	max_level = maxi(unlocked, 1)
	set_level(current)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	canceled.emit()


func set_level(value: int) -> void:
	level = clampi(value, 1, max_level)
	_level_label.text = tr("Poziom %d") % level
	minus_button.disabled = level <= 1
	plus_button.disabled = level >= max_level
	var lines: Array[String] = [tr("Siła potworów: %d%%") % roundi(DungeonLevels.power(level) * 100.0),
		tr("Skrzynia Wodza: %d żaru") % DungeonLevels.chest_embers(level)]
	if level == max_level:
		lines.append(tr("Pokonaj Wodza, żeby odblokować poziom %d") % (level + 1))
	_info.text = "\n".join(lines)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(parent: Control, text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 18)
	parent.add_child(b)
	return b

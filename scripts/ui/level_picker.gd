class_name LevelPicker
extends Control
## Wybór poziomu lochu po dotknięciu Watry w bazie (jak wybór poziomu szczeliny w Diablo 3): strzałki ◀ ▶ zmieniają
## poziom od 1 do najwyższego odblokowanego (`Game.unlocked_level`), pod spodem siła potworów i nagroda ze skrzyni
## Wodza, na dole duże przyciski „Wejdź” i „Anuluj” (pod kciukiem). Zatrzymuje grę na czas wyboru.
## Wybrany poziom trafia do `Game.dungeon_level` (zapisywany z grą). Nad „Wejdź” przycisk „Drzewko”
## (sygnał `upgrades` - arena chowa wybór i otwiera DungeonTreeWindow - drzewko lochów; po jego zamknięciu wybór wraca).
## Drabinka odblokowań (Unlocks): pod opisem poziomu nowości od tego poziomu, a na najwyższym dostępnym - najbliższe
## odblokowanie (który boss i co da); przycisk „Drabinka odblokowań” (sygnał `ladder` - arena otwiera UnlocksWindow, po zamknięciu wybór wraca).
## Przy ponad 10 dostępnych poziomach (np. tryb deweloperski „wszystkie poziomy”) dochodzą skoki o 10 (−10 / +10).
## Z kluczem do Gniazda Żmija (Pinnacles, `Game.zmij_keys`) nad przyciskami pojawia się przycisk „Żmij Gorynycz”
## z poziomem klucza (strzałki obok wybierają inny klucz, gdy są z różnych poziomów) - sygnał `pinnacle`.
## Głębiny (decyzja autora 26.11.2026): przy zwykłej Watrze poziomy 1 do końca drabinki (Dungeons.DEEP_FROM - 1), przy
## Czarnej Watrze (`deep`) Głębie od Dungeons.DEEP_FROM do najwyższej odblokowanej - napis „Głębia N”, loch i modyfikatory
## losowe przy każdym wejściu (bez przycisku modyfikatorów i Żmija).

signal enter(level: int)
signal canceled
signal upgrades
signal ladder
## „Modyfikatory” (od DungeonMods.FROM_LEVEL) - arena otwiera ModsWindow.
signal mods
## Walka ze Żmijem z kluczem z poziomu `key_level` (Pinnacles).
signal pinnacle(key_level: int)

var level := 1
var min_level := 1
var max_level := 1
## Wybór Głębi (Czarna Watra) zamiast zwykłego poziomu.
var deep := false
var _title: Label
var minus_button: Button
var plus_button: Button
var minus10_button: Button
var plus10_button: Button
var enter_button: Button
var cancel_button: Button
var upgrades_button: Button
var ladder_button: Button
var mods_button: Button
var _level_label: Label
var _info: Label
var zmij_button: Button
var _zmij_row: HBoxContainer
var _zmij_prev: Button
var _zmij_next: Button
## Klucze Żmija [[poziom, sztuk], ...] (od najsilniejszego) i który jest wybrany.
var _keys: Array = []
var _key := 0


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
	_title = _label(tr("Loch Hordy"), 22, Color(1, 0.78, 0.35))
	column.add_child(_title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	column.add_child(row)
	minus10_button = _button(row, "−10", Vector2(48, 56))
	minus10_button.add_theme_font_size_override("font_size", 13)
	minus10_button.pressed.connect(func() -> void: set_level(level - 10))
	minus_button = _button(row, "◀", Vector2(56, 56))
	minus_button.pressed.connect(func() -> void: set_level(level - 1))
	_level_label = _label("", 24, Color(1, 0.92, 0.78))
	_level_label.custom_minimum_size = Vector2(124, 0)
	_level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_level_label.add_theme_font_size_override("font_size", 22)
	row.add_child(_level_label)
	plus_button = _button(row, "▶", Vector2(56, 56))
	plus_button.pressed.connect(func() -> void: set_level(level + 1))
	plus10_button = _button(row, "+10", Vector2(48, 56))
	plus10_button.add_theme_font_size_override("font_size", 13)
	plus10_button.pressed.connect(func() -> void: set_level(level + 10))
	_info = _label("", 13, Color(1, 0.88, 0.7))
	column.add_child(_info)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	_zmij_row = HBoxContainer.new()
	_zmij_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_zmij_row.add_theme_constant_override("separation", 5)
	column.add_child(_zmij_row)
	_zmij_prev = _button(_zmij_row, "◀", Vector2(44, 52))
	_zmij_prev.pressed.connect(func() -> void: _show_key(_key - 1))
	zmij_button = _button(_zmij_row, "", Vector2(200, 52))
	zmij_button.icon = Pinnacles.KEY_ICON
	zmij_button.expand_icon = false
	zmij_button.add_theme_constant_override("icon_max_width", 28)
	zmij_button.add_theme_font_size_override("font_size", 13)
	zmij_button.add_theme_color_override("font_color", Color(1, 0.72, 0.45))
	zmij_button.pressed.connect(func() -> void:
		if _keys.is_empty():
			return
		visible = false
		get_tree().paused = false
		pinnacle.emit(int(_keys[_key][0])))
	_zmij_next = _button(_zmij_row, "▶", Vector2(44, 52))
	_zmij_next.pressed.connect(func() -> void: _show_key(_key + 1))
	var extra := HBoxContainer.new()  # dwa mniejsze przyciski obok siebie - mniej miejsca w pionie
	extra.alignment = BoxContainer.ALIGNMENT_CENTER
	extra.add_theme_constant_override("separation", 8)
	column.add_child(extra)
	ladder_button = _button(extra, tr("Drabinka"), Vector2(106, 48))
	ladder_button.add_theme_font_size_override("font_size", 15)
	ladder_button.pressed.connect(func() -> void:
		visible = false
		ladder.emit())
	mods_button = _button(extra, tr("Modyfikatory"), Vector2(106, 48))
	mods_button.add_theme_font_size_override("font_size", 13)
	mods_button.pressed.connect(func() -> void:
		visible = false
		mods.emit())
	upgrades_button = _button(extra, tr("Drzewko"), Vector2(106, 48))
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


## Pokazuje wybór (zaczyna od ostatnio wybranego poziomu) i zatrzymuje grę. `deep` - Głębie (Czarna Watra).
func open(current: int, unlocked: int, deep_mode := false) -> void:
	deep = deep_mode
	if deep:
		min_level = Dungeons.DEEP_FROM
		max_level = maxi(unlocked, Dungeons.DEEP_FROM)
	else:
		min_level = 1
		max_level = clampi(unlocked, 1, Dungeons.DEEP_FROM - 1)
	_title.text = tr("Głębiny") if deep else tr("Loch Hordy")
	_title.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0) if deep else Color(1, 0.78, 0.35))
	minus10_button.visible = max_level - min_level >= 10
	plus10_button.visible = max_level - min_level >= 10
	set_level(current)
	_keys = [] if deep else Pinnacles.key_list(_game().zmij_keys)
	_show_key(0)
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	canceled.emit()


func set_level(value: int) -> void:
	level = clampi(value, min_level, max_level)
	_level_label.text = Dungeons.level_label(level)
	minus_button.disabled = level <= min_level
	plus_button.disabled = level >= max_level
	minus10_button.disabled = level <= min_level
	plus10_button.disabled = level >= max_level
	var lines: Array[String] = []
	if Dungeons.is_random(level):
		lines.append(tr("Loch losowy przy każdym wejściu"))
		lines.append(tr("Losowe modyfikatory: %d") % DungeonMods.deep_count(level))
	else:
		var id := Dungeons.for_level(level)
		var cycle := Dungeons.cycle_of(level)
		lines.append(Dungeons.name_of(id) if cycle == 1 else tr("%s (krąg %d)") % [Dungeons.name_of(id), cycle])
		lines.append(Lang.t(Dungeons.get_data(id).description))
		var res := Dungeons.resist_text(id, level)
		if res != "":
			lines.append(res)
	lines.append(tr("Siła potworów: %d%%") % roundi(DungeonLevels.power(level) * 100.0))
	lines.append(tr("Skrzynia bossa: %d żaru") % DungeonLevels.chest_embers(level))
	mods_button.visible = level >= DungeonMods.FROM_LEVEL and not deep
	var active := DungeonMods.active(level, _game().dungeon_mods)
	if not active.is_empty():
		lines.append(tr("Modyfikatory: %s") % DungeonMods.names(active))
	for e: Dictionary in Unlocks.new_at(level):
		lines.append(tr("Nowość: %s") % e.text)
	if level == max_level:
		if not deep and level == Dungeons.DEEP_FROM - 1:
			lines.append(tr("Pokonaj bossa, żeby otworzyć Głębiny"))
		else:
			lines.append(tr("Pokonaj bossa, żeby odblokować: %s") % Dungeons.level_label(level + 1))
		var next := Unlocks.next_after(_game().best_level)
		if level - 1 == _game().best_level and not next.is_empty():  # nie w trybie „wszystkie poziomy”
			lines.append(tr("Następne odblokowanie po bossie poziomu %d:") % next[0].beat)
			for e: Dictionary in next:
				lines.append("• " + e.text)
	_info.text = "\n".join(lines)


## Przycisk Żmija z kluczem nr `index` (od najsilniejszego); bez kluczy - schowany.
func _show_key(index: int) -> void:
	_zmij_row.visible = not _keys.is_empty()
	if _keys.is_empty():
		return
	_key = clampi(index, 0, _keys.size() - 1)
	var k: Array = _keys[_key]
	zmij_button.text = tr("Żmij Gorynycz\nklucz: poziom %d (x%d)") % [k[0], k[1]]
	_zmij_prev.visible = _keys.size() > 1
	_zmij_next.visible = _keys.size() > 1
	_zmij_prev.disabled = _key <= 0
	_zmij_next.disabled = _key >= _keys.size() - 1


## Autoload Game przez drzewo (odwołanie wprost nie kompiluje się w części testów).
func _game() -> Node:
	return get_node("/root/Game")


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

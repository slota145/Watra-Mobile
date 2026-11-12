class_name StashWindow
extends Control
## Okno skrzyni w bazie (prośba autora 12.11.2026): u góry zakładki (pierwsza za darmo, kolejne za złoto -
## Game.STASH_TAB_PRICES; przycisk „+” z ceną, drugie stuknięcie kupuje), pod nimi siatka zakładki 5x4, niżej torba 5x4.
## Przenoszenie: stuknięcie w przedmiot otwiera opis przy dolnej krawędzi z przyciskiem „Do skrzyni” / „Do torby”,
## albo przeciągnięcie palcem na drugą siatkę (ItemSlot). „Wszystko do skrzyni” przenosi całą torbę do otwartej
## zakładki. Stan trzyma i zapisuje Game. Zatrzymuje grę, gdy jest otwarte (PROCESS_MODE_ALWAYS).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.8)
const SLOT := 48.0
const COLUMNS := 5

## Otwarta zakładka.
var tab := 0
var tab_buttons: Array[Button] = []
var buy_button: Button
var stash_slots: Array[ItemSlot] = []
var bag_slots: Array[ItemSlot] = []
var gold_label: Label
var bag_label: Label
var stash_all_button: Button
var back_button: Button
## Opis wybranego przedmiotu.
var detail: Control
var detail_name: Label
var move_button: Button
var _detail_kind: Label
var _detail_icon: TextureRect
var _detail_lines: VBoxContainer
var _tabs_row: HBoxContainer
## Wybrany przedmiot: siatka ("bag" / "stash") i pole.
var _sel_area := ""
var _sel_index := -1
var _buy_armed := false
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	panel.add_theme_stylebox_override("panel", _panel_style(10))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(300, 0)
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _label(head, tr("Skrzynia"), 18, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/watra/items/coin.png")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(18, 18)
	head.add_child(coin)
	gold_label = _label(head, "0", 15, GOLD)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 4)
	column.add_child(_tabs_row)
	stash_slots = _grid(column, "stash", _game.STASH_TAB_SIZE)
	bag_label = _label(column, "", 13, GOLD)
	bag_slots = _grid(column, "bag", _game.BAG_SIZE)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	column.add_child(bottom)
	stash_all_button = _button(bottom, tr("Wszystko do skrzyni"))
	stash_all_button.pressed.connect(func() -> void: _game.stash_all(tab))
	back_button = _button(bottom, tr("Wróć"))
	back_button.size_flags_stretch_ratio = 0.6
	back_button.pressed.connect(close)
	_make_detail()
	_game.inventory_changed.connect(func() -> void:
		if visible:
			refresh())


## Otwiera okno (na ostatnio oglądanej zakładce) i zatrzymuje grę.
func open() -> void:
	_hide_detail()
	_buy_armed = false
	tab = clampi(tab, 0, _game.stash.size() - 1)
	refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	_hide_detail()
	visible = false
	get_tree().paused = false
	closed.emit()


## Przycisk „wstecz”: najpierw zamyka opis przedmiotu, potem okno.
func back() -> void:
	if detail.visible:
		_hide_detail()
	else:
		close()


func refresh() -> void:
	gold_label.text = str(_game.gold)
	_build_tabs()
	var items: Array = _game.stash[tab]
	for i in stash_slots.size():
		stash_slots[i].show_item(items[i] if i < items.size() else {})
	for i in bag_slots.size():
		bag_slots[i].show_item(_game.bag[i] if i < _game.bag.size() else {})
	bag_label.text = tr("Torba: %d / %d") % [_game.bag.size(), _game.BAG_SIZE]
	stash_all_button.disabled = _game.bag.is_empty() or items.size() >= _game.STASH_TAB_SIZE


## Zakładki 1..N i przycisk kupna następnej („+ 100”), dopóki są do kupienia.
func _build_tabs() -> void:
	for b in tab_buttons:
		b.queue_free()
	tab_buttons.clear()
	if buy_button:
		buy_button.queue_free()
		buy_button = null
	for i in _game.stash.size():
		var b := Button.new()
		b.text = str(i + 1)
		b.toggle_mode = true
		b.button_pressed = i == tab
		b.custom_minimum_size = Vector2(44, 44)
		b.pressed.connect(_select_tab.bind(i))
		_tabs_row.add_child(b)
		tab_buttons.append(b)
	var price: int = _game.next_tab_price()
	if price > 0:
		buy_button = Button.new()
		buy_button.custom_minimum_size = Vector2(0, 44)
		buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_button.add_theme_font_size_override("font_size", 13)
		buy_button.icon = preload("res://assets/watra/items/coin.png")
		buy_button.expand_icon = true
		buy_button.add_theme_constant_override("icon_max_width", 16)
		buy_button.text = tr("Kupić za %d?") % price if _buy_armed else tr("+ zakładka %d") % price
		buy_button.disabled = _game.gold < price
		buy_button.pressed.connect(_on_buy)
		_tabs_row.add_child(buy_button)


func _select_tab(i: int) -> void:
	tab = i
	_buy_armed = false
	_hide_detail()
	refresh()


## Kupno zakładki: pierwsze stuknięcie pyta, drugie kupuje i otwiera nową zakładkę.
func _on_buy() -> void:
	if not _buy_armed:
		_buy_armed = true
		refresh()
		return
	_buy_armed = false
	if _game.buy_stash_tab():
		tab = _game.stash.size() - 1
		_play(preload("res://assets/watra/handleCoins.ogg"))
	refresh()


func _grid(parent: Control, area: String, count: int) -> Array[ItemSlot]:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(grid)
	var out: Array[ItemSlot] = []
	for i in count:
		var s := ItemSlot.new(SLOT)
		s.area = area
		s.index = i
		s.pressed.connect(_select.bind(area, i))
		s.dropped.connect(_on_dropped)
		grid.add_child(s)
		out.append(s)
	return out


## Przeciągnięty przedmiot upuszczony na drugą siatkę.
func _on_dropped(from_area: String, from_index: int) -> void:
	_hide_detail()
	_move(from_area, from_index)


## Przeniesienie między torbą a otwartą zakładką. Zwraca false, gdy cel jest pełny.
func _move(from_area: String, from_index: int) -> bool:
	var ok: bool = _game.to_stash(from_index, tab) if from_area == "bag" else _game.from_stash(tab, from_index)
	if ok:
		_play(preload("res://assets/watra/handleSmallLeather.ogg"))
	return ok


# --- opis przedmiotu ---

func _select(area: String, index: int) -> void:
	var items: Array = _game.bag if area == "bag" else _game.stash[tab]
	if index >= items.size():
		return
	_sel_area = area
	_sel_index = index
	var item: Dictionary = items[index]
	_detail_icon.texture = Items.icon_of(item)
	detail_name.text = Items.name_of(item)
	detail_name.add_theme_color_override("font_color", Items.color_of(item))
	_detail_kind.text = Items.kind_line(item)
	for c in _detail_lines.get_children():
		c.queue_free()
	for line in Items.base_lines(item):
		_label(_detail_lines, line, 13, TEXT)
	for line in Items.affix_lines(item):
		_label(_detail_lines, line, 13, Items.RARITY_COLORS.magic)
	if area == "bag":
		move_button.text = tr("Do skrzyni")
		move_button.disabled = _game.stash[tab].size() >= _game.STASH_TAB_SIZE
	else:
		move_button.text = tr("Do torby")
		move_button.disabled = _game.bag.size() >= _game.BAG_SIZE
	detail.visible = true


func _on_move() -> void:
	if _sel_index >= 0:
		_move(_sel_area, _sel_index)
	_hide_detail()


func _hide_detail() -> void:
	if detail:
		detail.visible = false
	_sel_area = ""
	_sel_index = -1


func _make_detail() -> void:
	detail = Control.new()
	detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	detail.visible = false
	add_child(detail)
	detail.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			_hide_detail())
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(12))
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	detail.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(48, 48)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_detail_icon)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	detail_name = _label(names, "", 17, GOLD)
	_detail_kind = _label(names, "", 11, DIM)
	_detail_lines = VBoxContainer.new()
	_detail_lines.add_theme_constant_override("separation", 1)
	col.add_child(_detail_lines)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	col.add_child(buttons)
	move_button = _button(buttons, "")
	move_button.pressed.connect(_on_move)
	var close_button := _button(buttons, tr("Zamknij"))
	close_button.size_flags_stretch_ratio = 0.7
	close_button.pressed.connect(_hide_detail)


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	b.clip_text = true
	parent.add_child(b)
	return b


func _panel_style(margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.06, 0.97)
	style.border_color = Color(0.85, 0.62, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(margin)
	return style


func _play(stream: AudioStream) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = -6.0
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

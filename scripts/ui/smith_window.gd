class_name SmithWindow
extends BaseWindow
## Okno kowala w bazie (ustalone z autorem 12.11.2026): przeróbka jednej wybranej premii przedmiotu za złoto
## (Items.reroll_affix, cena Items.reroll_price - każda kolejna przeróbka tego przedmiotu droższa).
## U góry założone przedmioty, niżej torba (ItemSlot). Stuknięcie w przedmiot otwiera opis przy dolnej krawędzi:
## stała cecha i premie, przy każdej premii przycisk z ceną (drugie stuknięcie przerabia, nowa premia błyska).
## Opis zostaje otwarty, żeby można było przerabiać dalej. Zwykły przedmiot nie ma premii do przerobienia.

const SLOT := 46.0
const SOUND := preload("res://assets/watra/base/anvil_1.ogg")

var equipped_slots: Array[ItemSlot] = []
var bag_slots: Array[ItemSlot] = []
var bag_label: Label
## Opis wybranego przedmiotu.
var detail: Control
var detail_name: Label
var _detail_kind: Label
var _detail_icon: TextureRect
var _detail_lines: VBoxContainer
## Wybrany przedmiot (słownik z torby albo założony - zmienia się w miejscu) i premia do błysku po przeróbce.
var selected: Dictionary = {}
var _flash := -1


func _build() -> void:
	title_label.text = tr("Kowal")
	label(content, tr("Stuknij przedmiot i wybierz premię do przekucia."), 12, DIM, true)
	label(content, tr("Założone"), 13, GOLD)
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 4)
	row_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(row_box)
	for slot in Items.SLOTS:
		var s := ItemSlot.new(SLOT)
		s.area = "equipped"
		s.pressed.connect(_select_equipped.bind(slot))
		row_box.add_child(s)
		equipped_slots.append(s)
	bag_label = label(content, "", 13, GOLD)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	for i in _game.BAG_SIZE:
		var s := ItemSlot.new(SLOT)
		s.area = "bag"
		s.index = i
		s.pressed.connect(_select_bag.bind(i))
		grid.add_child(s)
		bag_slots.append(s)
	_make_detail()


func refresh() -> void:
	set_currency(COIN, _game.gold)
	for i in Items.SLOTS.size():
		var item: Dictionary = _game.equipped.get(Items.SLOTS[i], {})
		equipped_slots[i].show_item(item)
		equipped_slots[i].icon = Items.icon_of(item) if not item.is_empty() else Items.slot_icon(Items.SLOTS[i])
		equipped_slots[i].modulate.a = 1.0 if not item.is_empty() else 0.5
	for i in bag_slots.size():
		bag_slots[i].show_item(_game.bag[i] if i < _game.bag.size() else {})
	bag_label.text = tr("Torba: %d / %d") % [_game.bag.size(), _game.BAG_SIZE]
	if detail.visible:
		_show_detail()


func back() -> void:
	if detail.visible:
		_hide_detail()
	else:
		close()


func open() -> void:
	_hide_detail()
	super.open()


func _select_equipped(slot: String) -> void:
	if _game.equipped.has(slot):
		_select(_game.equipped[slot])


func _select_bag(index: int) -> void:
	if index < _game.bag.size():
		_select(_game.bag[index])


func _select(item: Dictionary) -> void:
	selected = item
	armed = ""
	_flash = -1
	_show_detail()
	detail.visible = true


func _show_detail() -> void:
	var item := selected
	_detail_icon.texture = Items.icon_of(item)
	detail_name.text = Items.name_of(item)
	detail_name.add_theme_color_override("font_color", Items.color_of(item))
	_detail_kind.text = Items.kind_line(item)
	for c in _detail_lines.get_children():
		_detail_lines.remove_child(c)
		c.queue_free()
	for line in Items.base_lines(item):
		label(_detail_lines, line, 13, TEXT)
	if item.affixes.is_empty():
		label(_detail_lines, tr("Zwykły przedmiot nie ma premii do przekucia."), 12, DIM, true)
		return
	var price := Items.reroll_price(item)
	for i in item.affixes.size():
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		_detail_lines.add_child(box)
		var l := label(box, Items.stat_text(item.affixes[i].stat, item.affixes[i].value), 14, Items.RARITY_COLORS.magic)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _flash:
			l.modulate = Color(2.2, 2.0, 1.2)
			l.create_tween().tween_property(l, "modulate", Color.WHITE, 0.9)
		var b := price_button(box, "affix_%d" % i, price, COIN, _game.gold >= price)
		b.name = "Reroll_%d" % i
		b.pressed.connect(_reroll.bind(i))
	var rerolls := int(item.get("rerolls", 0))
	if rerolls > 0:
		label(_detail_lines, tr("Przekuto już: %d") % rerolls, 11, DIM)


func _reroll(index: int) -> void:
	if not confirm("affix_%d" % index):
		return
	if _game.reroll(selected, index):
		_flash = index
		play(SOUND, -4.0)
	refresh()
	_flash = -1


func _hide_detail() -> void:
	if detail:
		detail.visible = false
	selected = {}
	armed = ""


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
	panel.add_theme_stylebox_override("panel", panel_style(12))
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
	detail_name = label(names, "", 17, GOLD)
	_detail_kind = label(names, "", 11, DIM)
	_detail_lines = VBoxContainer.new()
	_detail_lines.add_theme_constant_override("separation", 3)
	col.add_child(_detail_lines)
	var close_button := button(col, tr("Zamknij"))
	close_button.pressed.connect(_hide_detail)

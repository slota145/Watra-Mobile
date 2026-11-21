class_name SmithWindow
extends BaseWindow
## Okno kowala w bazie: runy zmieniają premie przedmiotu (Runes, ustalone z autorem 20.11.2026 - zamiast przeróbki
## za złoto). U góry zapas run, niżej założone przedmioty i torba (ItemSlot). Stuknięcie w przedmiot otwiera opis
## przy dolnej krawędzi: stała cecha, premie i 6 run (ikona, liczba sztuk). Stuknięcie w runę ją wybiera i pokazuje
## opis; runa na wybraną premię (Szlifu, Przekucia, Pieczęci) dodaje przy premiach przyciski „Użyj”, pozostałe -
## przycisk „Użyj runy” (pierwsze stuknięcie pyta „Na pewno?”). Zmienione premie błyskają. Opis zostaje otwarty,
## żeby można było pracować dalej. Pod torbą wykuwanie (krok 3 punktu 4, decyzja autora 20.11.2026): przycisk z ikoną
## każdego miejsca - za Items.FORGE_ORE rudy nowy przedmiot z najgłębszego przebitego lochu o losowej rzadkości
## (Game.forge; pierwsze stuknięcie pyta, drugie wykuwa i od razu otwiera opis nowego przedmiotu). Ruda w nagłówku.

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
## Wybrana runa ("" - żadna) i premie do błysku po jej użyciu (indeksy; -2 - wszystkie).
var rune := ""
var _flash: Array = []
## Zapas run w oknie (runa -> napis z liczbą).
var _stock: Dictionary = {}
## Przyciski wykuwania (miejsce -> przycisk) i napis pod nimi.
var forge_buttons: Dictionary = {}
## Wybór bazy po stuknięciu miejsca (Items.BASES - 3 bazy): miejsce, którego bazy widać, i ich przyciski.
var forge_slot := ""
var base_row: HBoxContainer
var base_buttons: Dictionary = {}
var forge_label: Label


func _build() -> void:
	title_label.text = tr("Kowal")
	label(content, tr("Stuknij przedmiot, potem runę, którą chcesz go zmienić."), 12, DIM, true)
	var stock := HBoxContainer.new()
	stock.add_theme_constant_override("separation", 2)
	stock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(stock)
	for id in Runes.ORDER:
		var tex := TextureRect.new()
		tex.texture = Runes.icon_of(id)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(26, 26)
		stock.add_child(tex)
		_stock[id] = label(stock, "0", 13, TEXT)
		_stock[id].custom_minimum_size.x = 22
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
	label(content, tr("Wykuj nowy przedmiot"), 13, GOLD)
	var forge_row := HBoxContainer.new()
	forge_row.add_theme_constant_override("separation", 4)
	forge_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(forge_row)
	for slot in Items.SLOTS:
		var b := Button.new()
		b.name = "Forge_" + slot
		b.custom_minimum_size = Vector2(SLOT, SLOT)
		b.icon = Items.slot_icon(slot)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(_pick_slot.bind(slot))
		forge_row.add_child(b)
		forge_buttons[slot] = b
	base_row = HBoxContainer.new()
	base_row.add_theme_constant_override("separation", 6)
	base_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(base_row)
	forge_label = label(content, "", 11, DIM, true)
	_make_detail()


func refresh() -> void:
	currency_icon.visible = true
	set_currency(ORE, _game.ore)
	for slot in forge_buttons:
		var b: Button = forge_buttons[slot]
		b.disabled = _game.forge_problem(slot) != ""
		b.modulate = Color(1.3, 1.2, 0.8) if slot == forge_slot else Color.WHITE
	_show_bases()
	var why: String = _game.forge_problem(Items.SLOTS[0])
	forge_label.text = tr("%d rudy za przedmiot z lochu %d, rzadkość losowa (masz %d rudy).") \
			% [Items.FORGE_ORE, mini(maxi(_game.best_level, 1), Items.MAX_LEVEL), _game.ore]
	if forge_slot == "" and why == "":
		forge_label.text += " " + tr("Stuknij miejsce, potem bazę.")
	if why == "ore":
		forge_label.text += " " + tr("Rudę daje rozbijanie przedmiotów, Skarbnik i Napad Hordy.")
	elif why == "bag":
		forge_label.text += " " + tr("Torba pełna.")
	for id in Runes.ORDER:
		_stock[id].text = str(int(_game.runes.get(id, 0)))
		_stock[id].modulate.a = 1.0 if _game.runes.get(id, 0) > 0 else 0.45
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


## Stuknięte miejsce do wykucia: pokazuje (albo chowa) jego 3 bazy.
func _pick_slot(slot: String) -> void:
	forge_slot = "" if forge_slot == slot else slot
	armed = ""
	refresh()


## Przyciski baz wybranego miejsca: ikona, nazwa i stała cecha; „Wykuć?” po pierwszym stuknięciu.
func _show_bases() -> void:
	for c in base_row.get_children():
		base_row.remove_child(c)
		c.queue_free()
	base_buttons.clear()
	base_row.visible = forge_slot != ""
	if forge_slot == "":
		return
	var level := maxi(_game.best_level, 1)
	for type in Items.bases_of(forge_slot):
		var b := Button.new()
		b.name = "Base_" + type
		b.custom_minimum_size = Vector2(106, 96)
		var key: String = "forge_%s_%s" % [forge_slot, type]
		var implicit: Dictionary = Items.BASES[forge_slot][type].implicit
		var line: String = Items.stat_text(implicit.keys()[0], Items.implicit_value(implicit.keys()[0], implicit.values()[0], level))
		b.text = tr("Wykuć?") if armed == key else Items.base_name(forge_slot, type) + "\n" + line
		b.icon = Items.base_icon(forge_slot, type, Items.tier_for(level))
		b.expand_icon = false
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override("font_size", 10)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = _game.forge_problem(forge_slot) != ""
		b.pressed.connect(_forge.bind(forge_slot, type))
		base_row.add_child(b)
		base_buttons[type] = b


## Wykuwanie: pierwsze stuknięcie bazy pyta, drugie wykuwa i otwiera opis nowego przedmiotu.
func _forge(slot: String, type := "") -> void:
	if not confirm("forge_%s_%s" % [slot, type]):
		return
	var item: Dictionary = _game.forge(slot, type)
	if item.is_empty():
		refresh()
		return
	play(SOUND, -2.0)
	_select(item)
	refresh()


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
	rune = ""
	_flash = []
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
	var per_stat := Runes.needs_stat(rune)
	if item.affixes.is_empty():
		label(_detail_lines, tr("Zwykły przedmiot - bez premii."), 12, DIM, true)
	for i in item.affixes.size():
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		_detail_lines.add_child(box)
		var badge := label(box, Items.tier_badge(item.affixes[i]), 12, Items.tier_color(int(item.affixes[i].get("tier", Items.TIERS))))
		badge.custom_minimum_size.x = 22
		var l := label(box, Items.affix_text(item.affixes[i]), 14, Items.RARITY_COLORS.magic)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if i in _flash or -2 in _flash:
			l.modulate = Color(2.2, 2.0, 1.2)
			l.create_tween().tween_property(l, "modulate", Color.WHITE, 0.9)
		if per_stat:
			var b := button(box, tr("Użyj"))
			b.name = "Use_%d" % i
			b.custom_minimum_size = Vector2(80, 44)
			b.size_flags_horizontal = Control.SIZE_SHRINK_END
			b.disabled = not _can_use(i)
			b.pressed.connect(_use.bind(i))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_detail_lines.add_child(grid)
	for id in Runes.ORDER:
		var b := button(grid, "%s %d" % [Runes.short_of(id), int(_game.runes.get(id, 0))])
		b.name = "Rune_" + id
		b.icon = Runes.icon_of(id)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 18)
		b.add_theme_constant_override("h_separation", 2)
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = id == rune
		if id == rune:
			b.add_theme_color_override("font_color", GOLD)
			b.add_theme_color_override("font_pressed_color", GOLD)
		elif _game.runes.get(id, 0) <= 0:
			b.modulate.a = 0.5
		b.pressed.connect(_pick_rune.bind(id))
	if rune == "":
		label(_detail_lines, tr("Wybierz runę."), 12, DIM, true)
		return
	label(_detail_lines, Runes.name_of(rune), 13, Runes.color_of(rune))
	label(_detail_lines, Runes.text_of(rune), 12, DIM, true)
	var why := "" if _game.runes.get(rune, 0) > 0 else tr("Nie masz tej runy.")
	if why == "":
		why = Runes.blocker(item, rune, 0 if per_stat else -1)
	if why != "":
		label(_detail_lines, why, 12, Color(1, 0.55, 0.4), true)
	elif per_stat:
		label(_detail_lines, tr("Stuknij „Użyj” przy premii."), 12, DIM, true)
	if not per_stat:
		var use := button(_detail_lines, tr("Na pewno?") if armed == "rune" else tr("Użyj runy"))
		use.name = "UseRune"
		use.disabled = why != ""
		if armed == "rune":
			use.add_theme_color_override("font_color", GOLD)
		use.pressed.connect(_use.bind(-1))


## Czy wybraną runę da się użyć na premii `index` (jest runa i działanie ma sens).
func _can_use(index: int) -> bool:
	return _game.runes.get(rune, 0) > 0 and Runes.blocker(selected, rune, index) == ""


func _pick_rune(id: String) -> void:
	rune = "" if rune == id else id
	armed = ""
	_flash = []
	_show_detail()


## Użycie wybranej runy (`index` - premia; -1 - runa na cały przedmiot, z potwierdzeniem).
func _use(index: int) -> void:
	if index < 0 and not confirm("rune"):
		return
	var before: Array = selected.affixes.duplicate(true)
	if _game.use_rune(selected, rune, index):
		_flash = [index] if index >= 0 and rune != Runes.SEAL else [-2]
		if rune == Runes.SEAL:
			_flash = range(1, selected.affixes.size())
		elif rune == Runes.GROWTH:
			_flash = [selected.affixes.size() - 1]
		elif rune == Runes.ASCEND:
			_flash = range(before.size(), selected.affixes.size())
		play(SOUND, -4.0)
	refresh()
	_flash = []


func _hide_detail() -> void:
	if detail:
		detail.visible = false
	selected = {}
	rune = ""
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

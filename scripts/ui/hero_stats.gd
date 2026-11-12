class_name HeroStats
extends Control
## Okno „Postać” (z okna pauzy) - postać, ekwipunek i torba w jednym oknie (ustalone z autorem 12.11.2026):
## u góry poziom i doświadczenie, pod nimi 6 miejsc ekwipunku wokół Wojciecha (po lewej hełm, zbroja, buty; po prawej
## broń, amulet, pierścień) i złoto, niżej statystyki z poziomu i przedmiotów (zielona kolumna - co da następny awans),
## na dole torba 5x4. Stuknięcie w przedmiot otwiera opis przy dolnej krawędzi ekranu (pod kciukiem): cechy, zmiana
## statystyk po założeniu i przyciski „Załóż” / „Zdejmij” i „Sprzedaj” (magiczny i rzadki - drugie stuknięcie „Na pewno?”).
## Liczby bierze z HeroLevels, Items, ProtoHero i ProtoWeapon, stan z Game. Okno przewija się na niskich ekranach.
## Działa przy zatrzymanej grze (PROCESS_MODE_ALWAYS).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const UP := Color(0.55, 0.95, 0.5)
const DOWN := Color(1.0, 0.45, 0.4)
const DIM := Color(1, 0.85, 0.6, 0.8)
const SLOT_SIZE := 52.0
const BAG_COLUMNS := 5
## Miejsca ekwipunku po lewej i po prawej stronie postaci.
const LEFT_SLOTS := ["helmet", "armor", "boots"]
const RIGHT_SLOTS := ["weapon", "amulet", "ring"]
## Kolejność statystyk w oknie; te z EXTRA_STATS pokazują się tylko, gdy przedmioty coś do nich dają.
const STAT_KEYS := ["hp", "mana", "damage", "speed", "move", "protection", "regen", "xp", "slots"]
const EXTRA_STATS := ["protection", "regen", "xp"]

var back_button: Button
## Wiersze statystyk: nazwa -> [etykieta wartości, etykieta przyrostu z następnym poziomem].
var rows := {}
## Przyciski miejsc ekwipunku (miejsce -> przycisk) i pól torby (kolejno).
var equip_buttons := {}
var bag_buttons: Array[Button] = []
var gold_label: Label
var bag_label: Label
## Opis wybranego przedmiotu (przy dolnej krawędzi).
var detail: Control
var detail_name: Label
var detail_lines: VBoxContainer
var equip_button: Button
var sell_button: Button
var detail_close: Button
## Wybrany przedmiot: z torby (`_sel_index` >= 0) albo założony (`_sel_slot`).
var _sel_index := -1
var _sel_slot := ""
var _sell_armed := false
var _title: Label
var _xp_label: Label
var _grid: GridContainer
var _scroll: ScrollContainer
var _column: VBoxContainer
var _detail_icon: TextureRect
var _detail_kind: Label
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
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(316, 0)
	_column.add_theme_constant_override("separation", 6)
	_scroll.add_child(_column)
	_column.resized.connect(_fit)
	_title = _label(_column, "", 20, GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label = _label(_column, "", 12, TEXT)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_make_equipment(_column)
	_make_stats(_column)
	bag_label = _label(_column, "", 13, GOLD)
	var bag := GridContainer.new()
	bag.columns = BAG_COLUMNS
	bag.add_theme_constant_override("h_separation", 6)
	bag.add_theme_constant_override("v_separation", 6)
	bag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_column.add_child(bag)
	for i in _game.BAG_SIZE:
		var b := _slot_button(bag)
		b.pressed.connect(_select_bag.bind(i))
		bag_buttons.append(b)
	back_button = Button.new()
	back_button.text = tr("Wróć")
	back_button.custom_minimum_size = Vector2(0, 48)
	back_button.pressed.connect(close)
	_column.add_child(back_button)
	_make_detail()
	_game.inventory_changed.connect(func() -> void:
		if visible:
			refresh())


## Pokazuje okno z liczbami na obecny poziom postaci i przedmioty.
func open() -> void:
	_hide_detail()
	refresh()
	visible = true
	_fit.call_deferred()


func close() -> void:
	_hide_detail()
	visible = false
	closed.emit()


## Przycisk „wstecz”: najpierw zamyka opis przedmiotu, potem okno.
func back() -> void:
	if detail.visible:
		_hide_detail()
	else:
		close()


## Wpisuje statystyki (poziom + przedmioty), przyrost z następnym poziomem, ekwipunek i torbę.
func refresh() -> void:
	var lvl: int = _game.hero_level
	var gear: Dictionary = _game.gear()
	var top := lvl >= HeroLevels.MAX_LEVEL
	_title.text = tr("Poziom %d") % lvl
	var need: int = _game.xp_needed()
	_xp_label.text = tr("Doświadczenie: %d / %d") % [_game.hero_xp, need] if need > 0 else tr("Najwyższy poziom")
	var nxt := mini(lvl + 1, HeroLevels.MAX_LEVEL)
	var s := summary(lvl, gear)
	_put("hp", s.hp, "+%d" % (HeroLevels.max_hp(nxt) - HeroLevels.max_hp(lvl)), top)
	_put("mana", s.mana, "+%d" % (HeroLevels.max_mana(nxt) - HeroLevels.max_mana(lvl)), top)
	_put("damage", s.damage, "+%d%%" % roundi(HeroLevels.DAMAGE_STEP * 100.0), top)
	_put("speed", s.speed, "", true)
	_put("move", s.move, "", true)
	for key in EXTRA_STATS:
		_put(key, s[key], "", true)
		var shown: bool = s[key] != summary(1, {})[key]
		rows[key][0].get_parent().get_child(rows[key][0].get_index() - 1).visible = shown
		rows[key][0].visible = shown
		rows[key][1].visible = shown
	var slots := HeroLevels.skill_slots(lvl)
	var next_slot := ""
	for l in HeroLevels.SKILL_SLOT_LEVELS:
		if l > lvl:
			next_slot = tr("na poz. %d") % l
			break
	_put("slots", "%d / %d" % [slots, HeroLevels.SKILL_SLOT_LEVELS.size()], next_slot, next_slot == "")
	gold_label.text = str(_game.gold)
	for slot in Items.SLOTS:
		_show_item(equip_buttons[slot], _game.equipped.get(slot, {}), slot)
	for i in bag_buttons.size():
		_show_item(bag_buttons[i], _game.bag[i] if i < _game.bag.size() else {}, "")
	bag_label.text = tr("Torba: %d / %d") % [_game.bag.size(), _game.BAG_SIZE]


## Statystyki postaci jako napisy do okna (poziom i cechy przedmiotów): hp, mana, damage, speed, move, protection,
## regen, xp. Służy też do porównania przed i po założeniu przedmiotu.
static func summary(level: int, gear: Dictionary) -> Dictionary:
	var dmg := damage_range(level, gear)
	return {
		"hp": str(HeroLevels.max_hp(level) + roundi(gear.get("hp", 0.0))),
		"mana": str(HeroLevels.max_mana(level) + roundi(gear.get("mana", 0.0))),
		"damage": "%d-%d" % [dmg.x, dmg.y],
		"speed": Lang.t("%.2f /s") % attacks_per_second(gear),
		"move": str(roundi(ProtoHero.SPEED * (1.0 + gear.get("move_pct", 0.0) / 100.0))),
		"protection": "%d%%" % roundi(gear.get("protection_pct", 0.0)),
		"regen": Lang.t("%.1f /s") % gear.get("regen", 0.0),
		"xp": "+%d%%" % roundi(gear.get("xp_pct", 0.0)),
	}


## Obrażenia cięcia przed mnożnikiem: założona broń albo zwykły miecz postaci.
static func weapon_damage(gear: Dictionary) -> Vector2i:
	var d: Vector2i = gear.get("damage", Vector2i.ZERO)
	return d if d != Vector2i.ZERO else ProtoWeapon.DAMAGE


## Mnożnik obrażeń: poziom postaci i premie przedmiotów (+% obrażeń).
static func damage_mult(level: int, gear := {}) -> float:
	return HeroLevels.damage_mult(level) * (1.0 + gear.get("damage_pct", 0.0) / 100.0)


## Mnożnik szybkości ataku z przedmiotów.
static func attack_speed_mult(gear := {}) -> float:
	return 1.0 + gear.get("attack_speed_pct", 0.0) / 100.0


## Obrażenia jednego cięcia miecza na danym poziomie (od-do), z przedmiotami.
static func damage_range(level: int, gear := {}) -> Vector2i:
	var m := damage_mult(level, gear)
	var d := weapon_damage(gear)
	return Vector2i(roundi(d.x * m), roundi(d.y * m))


## Ile cięć na sekundę przy trzymanym ataku (rozbieg + cięcie + powrót + odpoczynek, przyspieszone przedmiotami).
static func attacks_per_second(gear := {}) -> float:
	return attack_speed_mult(gear) / (ProtoWeapon.WINDUP + ProtoWeapon.SWING + ProtoWeapon.RECOVER + ProtoWeapon.COOLDOWN)


# --- budowa okna ---

func _make_equipment(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var left := _slot_column(row, LEFT_SLOTS)
	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.custom_minimum_size = Vector2(150, 0)
	row.add_child(middle)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/watra/wojciech.png")
	atlas.region = Rect2(0, 0, 54, 54)  # pierwsza klatka „idle” na wprost
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(108, 108)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	middle.add_child(portrait)
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(gold_row)
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/watra/items/coin.png")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(20, 20)
	gold_row.add_child(coin)
	gold_label = _label(gold_row, "0", 15, GOLD)
	var right := _slot_column(row, RIGHT_SLOTS)
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _slot_column(parent: Control, slots: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)
	for slot in slots:
		var b := _slot_button(col)
		b.pressed.connect(_select_equipped.bind(slot))
		equip_buttons[slot] = b
	return col


func _make_stats(parent: Control) -> void:
	var head := HBoxContainer.new()
	parent.add_child(head)
	var spacer := _label(head, "", 11, TEXT)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var next := _label(head, tr("Następny poziom"), 11, UP)
	next.custom_minimum_size = Vector2(96, 0)
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 3)
	parent.add_child(_grid)
	for key in STAT_KEYS:
		var name_label := _label(_grid, _stat_name(key), 13, TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := _label(_grid, "", 13, GOLD)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var up := _label(_grid, "", 12, UP)
		up.custom_minimum_size = Vector2(70, 0)
		up.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rows[key] = [value, up]


## Opis przedmiotu przy dolnej krawędzi ekranu (przyciski pod kciukiem). Stuknięcie obok zamyka.
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
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	detail_name = _label(names, "", 17, GOLD)
	_detail_kind = _label(names, "", 11, DIM)
	detail_lines = VBoxContainer.new()
	detail_lines.add_theme_constant_override("separation", 1)
	col.add_child(detail_lines)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	col.add_child(buttons)
	equip_button = _detail_button(buttons, "")
	equip_button.pressed.connect(_on_equip)
	sell_button = _detail_button(buttons, "")
	sell_button.size_flags_stretch_ratio = 1.3
	sell_button.icon = preload("res://assets/watra/items/coin.png")
	sell_button.expand_icon = true
	sell_button.add_theme_constant_override("icon_max_width", 18)
	sell_button.pressed.connect(_on_sell)
	detail_close = _detail_button(buttons, tr("Zamknij"))
	detail_close.size_flags_stretch_ratio = 0.8
	detail_close.pressed.connect(_hide_detail)


func _detail_button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	b.clip_text = true
	parent.add_child(b)
	return b


# --- wybór przedmiotu ---

func _select_bag(index: int) -> void:
	if index >= _game.bag.size():
		return
	_sel_index = index
	_sel_slot = ""
	_show_detail(_game.bag[index], true)


func _select_equipped(slot: String) -> void:
	if not _game.equipped.has(slot):
		return
	_sel_index = -1
	_sel_slot = slot
	_show_detail(_game.equipped[slot], false)


func _show_detail(item: Dictionary, in_bag: bool) -> void:
	_sell_armed = false
	_detail_icon.texture = Items.icon_of(item)
	detail_name.text = Items.name_of(item)
	detail_name.add_theme_color_override("font_color", Items.color_of(item))
	_detail_kind.text = Items.kind_line(item)
	for c in detail_lines.get_children():
		c.queue_free()
	for line in Items.base_lines(item):
		_label(detail_lines, line, 13, TEXT)
	for line in Items.affix_lines(item):
		_label(detail_lines, line, 13, Items.RARITY_COLORS.magic)
	# porównanie: jak zmienią się statystyki po założeniu (z torby) albo zdjęciu
	var after: Dictionary = _game.equipped.duplicate()
	if in_bag:
		after[item.slot] = item
	else:
		after.erase(item.slot)
	var changes := _compare(Items.totals(_game.equipped), Items.totals(after))
	if not changes.is_empty():
		_label(detail_lines, tr("Po założeniu:") if in_bag else tr("Po zdjęciu:"), 11, DIM)
		for ch in changes:
			_label(detail_lines, ch[0], 12, UP if ch[1] else DOWN)
	equip_button.text = tr("Załóż") if in_bag else tr("Zdejmij")
	equip_button.disabled = not in_bag and _game.bag.size() >= _game.BAG_SIZE
	sell_button.visible = in_bag
	sell_button.text = tr("Sprzedaj %d") % Items.sell_price(item)
	detail.visible = true


## Zmiany statystyk między dwoma zestawami cech: [napis „Zdrowie: 120 → 132”, czy na plus].
func _compare(before: Dictionary, after: Dictionary) -> Array:
	var lvl: int = _game.hero_level
	var a := summary(lvl, before)
	var b := summary(lvl, after)
	var out: Array = []
	for key in ["hp", "mana", "damage", "speed", "move", "protection", "regen", "xp"]:
		if a[key] == b[key]:
			continue
		var better: bool
		if key == "damage":
			var da := damage_range(lvl, before)
			var db := damage_range(lvl, after)
			better = db.x + db.y > da.x + da.y
		else:
			better = _num(b[key]) > _num(a[key])
		out.append([tr("%s: %s → %s") % [_stat_name(key), a[key], b[key]], better])
	return out


static func _num(text: String) -> float:
	return text.replace("+", "").replace("%", "").replace(",", ".").split(" ")[0].to_float()


func _on_equip() -> void:
	if _sel_index >= 0:
		_game.equip(_sel_index)
	elif _sel_slot != "":
		_game.unequip(_sel_slot)
	_hide_detail()


## Sprzedaż: magiczny i rzadki przedmiot wymaga drugiego stuknięcia.
func _on_sell() -> void:
	if _sel_index < 0 or _sel_index >= _game.bag.size():
		return
	var item: Dictionary = _game.bag[_sel_index]
	if item.rarity != "common" and not _sell_armed:
		_sell_armed = true
		sell_button.text = tr("Na pewno?")
		return
	_game.sell(_sel_index)
	_play_coins()
	_hide_detail()


func _hide_detail() -> void:
	if detail:
		detail.visible = false
	_sel_index = -1
	_sel_slot = ""
	_sell_armed = false


func _play_coins() -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = preload("res://assets/watra/handleCoins.ogg")
	audio.volume_db = -6.0
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


## Pole przedmiotu: ikona, ramka w kolorze rzadkości (puste miejsce ekwipunku - przygaszony obrys z Watry).
func _show_item(b: Button, item: Dictionary, slot: String) -> void:
	var color := Color(0.45, 0.35, 0.25)
	if item.is_empty():
		b.icon = Items.slot_icon(slot) if slot != "" else null
		b.modulate = Color(1, 1, 1, 0.55) if slot != "" else Color.WHITE
	else:
		b.icon = Items.icon_of(item)
		b.modulate = Color.WHITE
		color = Items.color_of(item) if item.rarity != "common" else Color(0.7, 0.6, 0.45)
	for state in ["normal", "hover", "pressed", "focus"]:
		var st: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		st.border_color = color if state != "pressed" else color.lightened(0.3)
		b.add_theme_stylebox_override(state, st)


func _slot_button(parent: Control) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 44)
	for state in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.11, 0.08) if state != "pressed" else Color(0.26, 0.18, 0.12)
		st.set_border_width_all(2)
		st.set_corner_radius_all(4)
		st.set_content_margin_all(4)
		b.add_theme_stylebox_override(state, st)
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


## Okno nie wyższe niż ekran (minus margines) - reszta przewija się palcem.
func _fit() -> void:
	var limit := get_viewport_rect().size.y - 32.0
	_scroll.custom_minimum_size = Vector2(316, minf(maxf(_column.size.y, _column.get_combined_minimum_size().y), limit))


func _put(key: String, value: String, up: String, no_up: bool) -> void:
	rows[key][0].text = value
	rows[key][1].text = "" if no_up else up


func _stat_name(key: String) -> String:
	match key:
		"hp":
			return tr("Zdrowie")
		"mana":
			return tr("Mana")
		"damage":
			return tr("Obrażenia miecza")
		"speed":
			return tr("Szybkość ataku")
		"move":
			return tr("Szybkość ruchu")
		"protection":
			return tr("Ochrona")
		"regen":
			return tr("Regeneracja")
		"xp":
			return tr("Doświadczenie")
	return tr("Miejsca na umiejętności")


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

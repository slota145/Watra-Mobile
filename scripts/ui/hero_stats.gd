class_name HeroStats
extends Control
## Okno „Postać” (ikonka portretu w górnym rzędzie areny) na cały ekran, z zakładkami na dole pod kciukiem (ustalone z autorem 13.11.2026):
## u góry poziom, doświadczenie i złoto; „Ekwipunek” - 6 miejsc wokół Wojciecha (po lewej hełm, zbroja, buty; po prawej
## kolczyk, amulet, pierścień), pod postacią zdrowie, obrażenia i ochrona, niżej torba 5x4 i sprzedaż hurtem;
## „Statystyki” - pełna lista z poziomu i przedmiotów (zielona kolumna - co da następny awans); „Sakwa” - kamienie. Stuknięcie w przedmiot otwiera opis przy dolnej krawędzi ekranu (pod kciukiem): cechy, zmiana
## statystyk po założeniu i przyciski „Załóż” / „Zdejmij” i „Sprzedaj” (magiczny i rzadki - drugie stuknięcie „Na pewno?”).
## Pod torbą: „Sprzedaj zwykłe” i „Sprzedaj magiczne i rzadkie” (drugie stuknięcie potwierdza i pokazuje cenę)
## oraz przełącznik auto sprzedaży zwykłych przedmiotów podniesionych w lochu (`Game.auto_sell_common`).
## Kamienie szlachetne (Gems): w opisie przedmiotu rząd jego gniazd, pod każdym krótko, co daje kamień; stuknięcie
## gniazda otwiera GemPicker z pasującymi kamieniami i ich premią w tym miejscu („Włóż”, „Wymień”, „Wyjmij”);
## „Dłuto” dorabia drugie gniazdo (drugie stuknięcie potwierdza). Zakładka „Sakwa”: wszystkie kamienie, klucze i dłuta
## z kropkami stopnia - stuknięcie otwiera GemPicker z listą miejsc, gdzie kamień pasuje.
## Liczby bierze z HeroLevels, Items, ProtoHero i ProtoWeapon, stan z Game. Zakładka przewija się na niskich ekranach.
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
const RIGHT_SLOTS := ["earring", "amulet", "ring"]
## Kolejność statystyk w oknie; te z EXTRA_STATS pokazują się tylko, gdy przedmioty coś do nich dają.
const STAT_KEYS := ["hp", "mana", "damage", "speed", "move", "crit", "crit_dmg", "mana_regen", "protection", "regen",
	"life_on_kill", "cdr", "elite_dmg", "dodge", "area", "pickup", "ember", "xp", "slots"]
const EXTRA_STATS := ["protection", "regen", "life_on_kill", "cdr", "elite_dmg", "dodge", "area", "pickup", "ember", "xp"]
## Statystyki porównywane przy zakładaniu przedmiotu (bez miejsc na umiejętności).
const COMPARE_KEYS := ["hp", "mana", "damage", "speed", "move", "crit", "crit_dmg", "mana_regen", "protection", "regen",
	"life_on_kill", "cdr", "elite_dmg", "dodge", "area", "pickup", "ember", "xp"]
## Bazowe trafienie krytyczne postaci (bez przedmiotów): szansa i obrażenia w procentach.
const CRIT_CHANCE := 5.0
const CRIT_DAMAGE := 150.0
const TABS := ["equip", "stats", "pouch"]
const TAB_NAMES := {"equip": "Ekwipunek", "stats": "Statystyki", "pouch": "Sakwa"}

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
## Sprzedaż hurtem i auto sprzedaż zwykłych.
var sell_common_button: Button
var sell_better_button: Button
var auto_sell_toggle: CheckButton
## Która sprzedaż hurtem czeka na potwierdzenie ("common", "better" albo "").
var _bulk_armed := ""
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
## Kamienie: sakwa (zakładka), w opisie przedmiotu gniazda, podpowiedź i dłuto.
var pouch_label: Label
var pouch_grid: GridContainer
var socket_row: HBoxContainer
var gem_hint: Label
var chisel_button: Button
## Czy dłuto czeka na potwierdzenie.
var _chisel_armed := false
## Zakładki: otwarta, strony i przyciski; 3 najważniejsze liczby pod postacią; wybór kamienia.
var tab := "equip"
var page_equip: VBoxContainer
var page_stats: VBoxContainer
var page_pouch: VBoxContainer
var tab_buttons := {}
var key_stats: Label
var picker: GemPicker
## Krótkie opisy pod gniazdami przedmiotu w opisie.
var socket_labels: Array[Label] = []
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
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(8))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 6
	panel.offset_top = 6
	panel.offset_right = -6
	panel.offset_bottom = -6
	add_child(panel)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	panel.add_child(_column)
	var head := HBoxContainer.new()
	_column.add_child(head)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	_title = _label(names, "", 18, GOLD)
	_xp_label = _label(names, "", 11, TEXT)
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/watra/items/coin.png")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(20, 20)
	head.add_child(coin)
	gold_label = _label(head, "0", 15, GOLD)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.add_child(_scroll)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(pages)
	# zakładka „Ekwipunek”: postać z 6 miejscami i 3 najważniejszymi liczbami, torba, sprzedaż
	page_equip = _page(pages)
	_make_equipment(page_equip)
	var bag_head := HBoxContainer.new()
	page_equip.add_child(bag_head)
	bag_label = _label(bag_head, "", 13, GOLD)
	bag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag := GridContainer.new()
	bag.columns = BAG_COLUMNS
	bag.add_theme_constant_override("h_separation", 6)
	bag.add_theme_constant_override("v_separation", 6)
	bag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page_equip.add_child(bag)
	for i in _game.BAG_SIZE:
		var b := _slot_button(bag)
		b.pressed.connect(_select_bag.bind(i))
		bag_buttons.append(b)
	var sell_row := HBoxContainer.new()
	sell_row.add_theme_constant_override("separation", 6)
	page_equip.add_child(sell_row)
	sell_common_button = _detail_button(sell_row, "")
	sell_common_button.pressed.connect(_on_sell_all.bind("common"))
	sell_better_button = _detail_button(sell_row, "")
	sell_better_button.pressed.connect(_on_sell_all.bind("better"))
	for bb in [sell_common_button, sell_better_button]:
		bb.clip_text = false
		bb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bb.add_theme_font_size_override("font_size", 12)
		bb.custom_minimum_size.y = 44
	auto_sell_toggle = CheckButton.new()
	auto_sell_toggle.text = tr("Sprzedawaj zwykłe od razu po podniesieniu")
	auto_sell_toggle.custom_minimum_size = Vector2(0, 44)
	auto_sell_toggle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	auto_sell_toggle.add_theme_font_size_override("font_size", 12)
	auto_sell_toggle.toggled.connect(func(on: bool) -> void:
		_game.auto_sell_common = on
		_game.save_settings())
	page_equip.add_child(auto_sell_toggle)
	# zakładka „Statystyki”: pełna lista z przyrostem na następnym poziomie
	page_stats = _page(pages)
	_make_stats(page_stats)
	# zakładka „Sakwa”: kamienie, klucze i dłuta - stuknięcie pokazuje, gdzie pasują
	page_pouch = _page(pages)
	pouch_label = _label(page_pouch, "", 13, GOLD)
	pouch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pouch_grid = GridContainer.new()
	pouch_grid.columns = BAG_COLUMNS
	pouch_grid.add_theme_constant_override("h_separation", 6)
	pouch_grid.add_theme_constant_override("v_separation", 6)
	pouch_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page_pouch.add_child(pouch_grid)
	var pouch_hint := _label(page_pouch, tr("Stuknij kamień: zobaczysz, gdzie pasuje i co tam da. Kropki pod kamieniem to jego stopień."), 11, DIM)
	pouch_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# zakładki na dole, pod kciukiem, i „Wróć”
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	_column.add_child(tabs)
	for t in TABS:
		var b := _detail_button(tabs, tr(TAB_NAMES[t]))
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(set_tab.bind(t))
		tab_buttons[t] = b
	back_button = _detail_button(tabs, tr("Wróć"))
	back_button.add_theme_font_size_override("font_size", 13)
	back_button.size_flags_stretch_ratio = 0.8
	back_button.pressed.connect(close)
	_make_detail()
	picker = GemPicker.new()
	picker.changed.connect(func() -> void:
		refresh()
		_redetail())
	add_child(picker)
	set_tab("equip")
	_game.inventory_changed.connect(func() -> void:
		if visible:
			refresh())


func _page(parent: Control) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 6)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(page)
	return page


## Przełącza zakładkę: "equip", "stats" albo "pouch".
func set_tab(t: String) -> void:
	tab = t
	page_equip.visible = t == "equip"
	page_stats.visible = t == "stats"
	page_pouch.visible = t == "pouch"
	for k in tab_buttons:
		_tab_look(tab_buttons[k], k == t)
	_scroll.scroll_vertical = 0


## Wygląd zakładki: wybrana - złota ramka i napis.
func _tab_look(b: Button, active: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		if active:
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.26, 0.18, 0.1)
			st.border_color = GOLD
			st.set_border_width_all(2)
			st.set_corner_radius_all(5)
			b.add_theme_stylebox_override(state, st)
		else:
			b.remove_theme_stylebox_override(state)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		if active:
			b.add_theme_color_override(c, GOLD)
		else:
			b.remove_theme_color_override(c)


## Pokazuje okno z liczbami na obecny poziom postaci i przedmioty.
func open() -> void:
	_hide_detail()
	refresh()
	visible = true
	get_tree().paused = true


func close() -> void:
	_hide_detail()
	picker.close()
	visible = false
	get_tree().paused = false
	closed.emit()


## Przycisk „wstecz”: najpierw zamyka wybór kamienia, potem opis przedmiotu, potem okno.
func back() -> void:
	if picker.visible:
		picker.close()
	elif detail.visible:
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
	for key in ["crit", "crit_dmg", "mana_regen"]:
		_put(key, s[key], "", true)
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
	key_stats.text = tr("Zdrowie %s\nObrażenia %s\nOchrona %s") % [s.hp, s.damage, s.protection]
	for slot in Items.SLOTS:
		_show_item(equip_buttons[slot], _game.equipped.get(slot, {}), slot)
	for i in bag_buttons.size():
		_show_item(bag_buttons[i], _game.bag[i] if i < _game.bag.size() else {}, "")
	bag_label.text = tr("Torba: %d / %d") % [_game.bag.size(), _game.BAG_SIZE]
	_refresh_pouch()
	auto_sell_toggle.set_pressed_no_signal(_game.auto_sell_common)
	_bulk_armed = ""
	_bulk_texts()


## Rzadkości sprzedawane jednym przyciskiem.
static func bulk_rarities(which: String) -> Array:
	return ["common"] if which == "common" else ["magic", "rare"]


## Napisy przycisków sprzedaży hurtem; nieaktywne, gdy nie ma czego sprzedać.
func _bulk_texts() -> void:
	for which in ["common", "better"]:
		var b := sell_common_button if which == "common" else sell_better_button
		var price: int = _game.sell_all_price(bulk_rarities(which))
		if _bulk_armed == which:
			b.text = tr("Na pewno? +%d złota") % price
		else:
			b.text = tr("Sprzedaj zwykłe") if which == "common" else tr("Sprzedaj magiczne i rzadkie")
		b.disabled = price == 0


## Sprzedaż hurtem: pierwsze stuknięcie pyta (z ceną), drugie sprzedaje.
func _on_sell_all(which: String) -> void:
	if _bulk_armed != which:
		_bulk_armed = which
		_bulk_texts()
		return
	if _game.sell_all(bulk_rarities(which)) > 0:
		_play_coins()
	_bulk_armed = ""
	_bulk_texts()


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
		"crit": "%d%%" % roundi(crit_chance(gear)),
		"crit_dmg": "%d%%" % roundi(crit_damage(gear)),
		"mana_regen": Lang.t("%.1f /s") % (HeroLevels.MANA_REGEN + gear.get("mana_regen", 0.0)),
		"life_on_kill": "+%d" % roundi(gear.get("life_on_kill", 0.0)),
		"cdr": "-%d%%" % roundi(gear.get("cdr_pct", 0.0)),
		"elite_dmg": "+%d%%" % roundi(gear.get("elite_dmg_pct", 0.0)),
		"dodge": "%d%%" % roundi(gear.get("dodge_pct", 0.0)),
		"area": "+%d%%" % roundi(gear.get("area_pct", 0.0)),
		"pickup": "+%d%%" % roundi(gear.get("pickup_pct", 0.0)),
		"ember": "+%d%%" % roundi(gear.get("ember_pct", 0.0)),
	}


## Szansa na trafienie krytyczne w procentach: bazowa i z przedmiotów (sufit przedmiotów - Items.CAPS).
static func crit_chance(gear: Dictionary) -> float:
	return CRIT_CHANCE + gear.get("crit_pct", 0.0)


## Obrażenia trafienia krytycznego w procentach zwykłego cięcia: bazowe i z przedmiotów.
static func crit_damage(gear: Dictionary) -> float:
	return CRIT_DAMAGE + gear.get("crit_dmg_pct", 0.0)


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
	middle.custom_minimum_size = Vector2(140, 0)
	row.add_child(middle)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/watra/wojciech.png")
	atlas.region = Rect2(0, 0, 54, 54)  # pierwsza klatka „idle” na wprost
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(84, 84)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	middle.add_child(portrait)
	key_stats = _label(middle, "", 12, TEXT)
	key_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	socket_row = HBoxContainer.new()
	socket_row.add_theme_constant_override("separation", 6)
	col.add_child(socket_row)
	gem_hint = _label(col, "", 11, DIM)
	gem_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	equip_button.visible = true
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
	var sockets: Array = item.get("sockets", [])
	var socket_texts := Items.socket_lines(item)
	for i in sockets.size():
		if sockets[i] != "":
			_label(detail_lines, socket_texts[i], 13, Gems.color_of(sockets[i]))
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
	_show_sockets(item)
	detail.visible = true


## Zmiany statystyk między dwoma zestawami cech: [napis „Zdrowie: 120 → 132”, czy na plus].
func _compare(before: Dictionary, after: Dictionary) -> Array:
	var lvl: int = _game.hero_level
	var a := summary(lvl, before)
	var b := summary(lvl, after)
	var out: Array = []
	for key in COMPARE_KEYS:
		if a[key] == b[key]:
			continue
		var better: bool
		if key == "damage":
			var da := damage_range(lvl, before)
			var db := damage_range(lvl, after)
			better = db.x + db.y > da.x + da.y
		elif key == "cdr":
			better = _num(b[key]) < _num(a[key])  # „-12%” to krótsze odnowienie niż „-5%”
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
	_chisel_armed = false


# --- kamienie ---

## Wybrany przedmiot (z torby albo założony; pusty słownik - żaden).
func _sel_item() -> Dictionary:
	if _sel_index >= 0 and _sel_index < _game.bag.size():
		return _game.bag[_sel_index]
	return _game.equipped.get(_sel_slot, {}) if _sel_slot != "" else {}


## Pokazuje ponownie opis wybranego przedmiotu (po włożeniu lub wyjęciu kamienia).
func _redetail() -> void:
	var item := _sel_item()
	if not item.is_empty():
		_show_detail(item, _sel_index >= 0)


## Zakładka „Sakwa”: wszystkie kamienie, klucze i dłuta (stuknięcie - GemPicker: gdzie pasuje).
func _refresh_pouch() -> void:
	for c in pouch_grid.get_children():
		pouch_grid.remove_child(c)
		c.queue_free()
	var list: Array = _game.gem_list()
	var total := 0
	for id in list:
		total += _game.gem_count(id)
	pouch_label.text = tr("Sakwa: %d") % total if total > 0 \
			else tr("Sakwa pusta - kamienie wypadają w lochach od poziomu %d.") % Gems.MIN_LEVEL
	tab_buttons["pouch"].text = tr("Sakwa (%d)") % total if total > 0 else tr("Sakwa")
	for id in list:
		var slot := GemSlot.new(SLOT_SIZE)
		slot.area = "pouch"
		slot.show_gem(id, _game.gem_count(id))
		slot.pressed.connect(func() -> void: picker.open_gem(id))
		pouch_grid.add_child(slot)


## Gniazda przedmiotu w opisie: pod każdym krótko, co daje kamień; stuknięcie - GemPicker. Obok dłuto.
func _show_sockets(item: Dictionary) -> void:
	for c in socket_row.get_children():
		socket_row.remove_child(c)
		c.queue_free()
	socket_labels.clear()
	socket_row.visible = true
	gem_hint.visible = true
	var cap := _label(socket_row, tr("Gniazda:"), 12, DIM)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sockets: Array = item.get("sockets", [])
	for i in sockets.size():
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(70, 0)
		cell.add_theme_constant_override("separation", 0)
		socket_row.add_child(cell)
		var slot := GemSlot.new(44.0)
		slot.area = "socket"
		slot.index = i
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.show_gem(sockets[i])
		slot.pressed.connect(_on_item_socket.bind(i))
		cell.add_child(slot)
		var text := Gems.short_text(sockets[i], "", item.slot) if sockets[i] != "" else tr("puste")
		var l := _label(cell, text, 9, Gems.color_of(sockets[i]) if sockets[i] != "" else DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(70, 0)
		socket_labels.append(l)
	chisel_button = null
	if sockets.size() < Items.MAX_SOCKETS and _game.gem_count(Gems.CHISEL) > 0:
		chisel_button = Button.new()
		chisel_button.text = tr("Na pewno?") if _chisel_armed else tr("Dłuto (%d)") % _game.gem_count(Gems.CHISEL)
		chisel_button.icon = load(Gems.SPECIAL[Gems.CHISEL].icon)
		chisel_button.expand_icon = true
		chisel_button.add_theme_constant_override("icon_max_width", 22)
		chisel_button.add_theme_font_size_override("font_size", 12)
		chisel_button.custom_minimum_size = Vector2(0, 44)
		chisel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chisel_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		chisel_button.pressed.connect(_on_chisel)
		socket_row.add_child(chisel_button)
	gem_hint.text = tr("Stuknij gniazdo, żeby włożyć, wymienić albo wyjąć kamień.")


## Gniazdo przedmiotu: GemPicker z pasującymi kamieniami szlachetnymi.
func _on_item_socket(i: int) -> void:
	_chisel_armed = false
	var item := _sel_item()
	if not item.is_empty():
		picker.open_item_socket(item, i)


## Dłuto: pierwsze stuknięcie pyta, drugie dorabia gniazdo.
func _on_chisel() -> void:
	if not _chisel_armed:
		_chisel_armed = true
		_redetail()
		return
	_chisel_armed = false
	if _game.add_socket(_sel_item()):
		_play_gem()
	_redetail()


func _play_gem() -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = preload("res://assets/watra/glass_002.ogg")
	audio.volume_db = -8.0
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


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
			return tr("Obrażenia ciosu")
		"speed":
			return tr("Szybkość ataku")
		"move":
			return tr("Szybkość ruchu")
		"protection":
			return tr("Ochrona")
		"regen":
			return tr("Regeneracja")
		"crit":
			return tr("Szansa na krytyk")
		"crit_dmg":
			return tr("Obrażenia krytyczne")
		"mana_regen":
			return tr("Odnowa many")
		"life_on_kill":
			return tr("Zdrowie za zabicie")
		"cdr":
			return tr("Odnowienie umiejętności")
		"elite_dmg":
			return tr("Przeciw elitom i bossom")
		"dodge":
			return tr("Unik")
		"area":
			return tr("Obszar umiejętności")
		"pickup":
			return tr("Zasięg zbierania")
		"ember":
			return tr("Żar")
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

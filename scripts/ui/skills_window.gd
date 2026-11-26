class_name SkillsWindow
extends Control
## Okno umiejętności (ustalenia z autorem 12.11.2026). U góry mistrzostwo broni w ręku (Weapons) i żar Watry, niżej
## przewijana lista umiejętności miecza (Skills): ikona, nazwa, koszt many i odnowienie, opis, a obok miejsce albo
## próg mistrzostwa, który ją odblokuje (13.11.2026: odblokowuje mistrzostwo, a nie złoto). Ulepsza się tylko w bazie
## przy kamieniu run (`open(true)`), z pauzy okno służy do przestawiania. Na dole, pod kciukiem, rząd miejsc jak na przyciskach walki: „Atak” (duży przycisk - z auto atakiem)
## i 4 małe (zablokowane do poziomu postaci). Przypisanie: stuknij umiejętność, potem miejsce - albo przeciągnij ikonę
## na miejsce (SkillSlot). Stuknięcie zajętego miejsca wybiera je: potem stuknięcie innego miejsca zamienia je
## miejscami, a „Zdejmij” opróżnia. Mgnienie nie może stać pod „Atak”. Stan trzyma i zapisuje Game.
## Zakładka „Aury” (Auras, 19.11.2026): lista aur z rezerwacją many i działaniem na obecnym poziomie, przycisk
## „Włącz” / „Wyłącz” (Game.toggle_aura; powód odmowy w podpowiedzi), u góry suma rezerwacji; aury jeszcze
## niezdobyte są szare z napisem, skąd je wziąć.
## Zakładka „Kamienie” (Gems; od 26.11.2026 bez gniazd i sakwy na dole - decyzja autora): lista umiejętności
## z małymi ikonami ich kamieni; stuknięcie odblokowanej umiejętności otwiera jej kartę w GemPicker (`open_skill`:
## gniazda, kamienie do włożenia, Wyjmij, Ulepsz, Otwórz kluczem, strzałki do sąsiednich umiejętności broni w ręku).
## W każdym wierszu listy małe ikony kamieni z gniazd tej umiejętności.
## Poziomy umiejętności (13.11.2026): przy nazwie „poz. X/10”, mana i odnowienie już z premią poziomu, pod opisem
## nowe działania z 5. i 10. poziomu (złote - odblokowane) i co da następny poziom. Odblokowana umiejętność ma z prawej
## przycisk „Ulepsz” z ceną w żarze (przy kamieniu run, drugie stuknięcie potwierdza; Game.upgrade_skill), a gdy
## mistrzostwo nie pozwala - od którego poziomu mistrzostwa (Skills.level_cap).
## Bronie (13.11.2026; od 20.11.2026 lista zamiast rzędu): pod mistrzostwem przycisk z bronią w ręku otwiera listę broni
## (Weapons.ORDER, `weapon_menu`) - przy kamieniu run stuknięcie dostępnej broni bierze ją do ręki (Game.set_weapon), a niedostępnej - odblokowuje ją Pieczęcią Oręża z sakwy
## (drugie stuknięcie potwierdza; Game.unseal_weapon - od 20.11.2026 zamiast kupna za złoto). Lista pokazuje tylko umiejętności broni w ręku.
## Broń zapasowa (26.11.2026): w wierszu dostępnej broni drugi przycisk „Zapas” (Game.set_spare; „Odłóż” ją zdejmuje),
## w stanie broni jej mistrzostwo i doganianie (Game.mastery_mult). Na przycisku broni w ręku - też zapasowa.
## Zatrzymuje grę, gdy jest otwarte (PROCESS_MODE_ALWAYS).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.75)
const BLUE := Color(0.55, 0.7, 1.0)
const RED := Color(1, 0.55, 0.45)
const GREEN := Color(0.55, 0.95, 0.5)
const ROW_ICON := 48.0
const SLOT_SIZE := 52.0

## Czy można kupować (baza, kamień run).
var can_shop := false
## Żar Watry (waluta ulepszeń) i mistrzostwo broni w ręku.
var embers_label: Label
var mastery_label: Label
## Przyciski broni (identyfikator Weapons -> przycisk) i wiersze listy (do ukrywania umiejętności innych broni).
var weapon_buttons := {}
## Broń w ręku na jednym przycisku (prośba autora 20.11.2026 - rząd 5 broni się nie mieścił); stuknięcie otwiera
## listę broni (`weapon_menu`): ikona, nazwa, żywioł, stan i przycisk „Weź” / „Kup” (to są `weapon_buttons`).
var weapon_button: Button
var weapon_menu: Control
var weapon_rows := {}
var row_boxes: Array[Control] = []
var hint: Label
var list_icons: Array[SkillSlot] = []
var buy_buttons: Array[Button] = []
var status_labels: Array[Label] = []
## Pamięć oręża: przekreślona stara cena i nowa na zielono (widoczne tylko przy zniżce).
var memory_labels: Array[RichTextLabel] = []
## Wiersze: nazwa z poziomem, mana i odnowienie, nowe działania (5. i 10. poziom), co da następny poziom.
var name_labels: Array[Label] = []
var info_labels: Array[Label] = []
var perk_labels: Array = []
var next_labels: Array[Label] = []
var slots: Array[SkillSlot] = []
var clear_button: Button
var back_button: Button
## Zakładki „Miejsca” / „Kamienie” i ich zawartość na dole.
var tab_slots: Button
var tab_gems: Button
var gems_mode := false
var tab_auras: Button
var aura_mode := false
## Lista umiejętności i lista aur (zakładka „Aury” podmienia jedną na drugą).
var skill_scroll: ScrollContainer
var aura_scroll: ScrollContainer
var aura_list: VBoxContainer
var slots_row: HBoxContainer
## Wysuwany wybór kamienia (karta umiejętności).
var picker: GemPicker
## Małe ikony kamieni w wierszach listy (wiersz -> pojemnik).
var row_gems: Array[HBoxContainer] = []
## Wybrana umiejętność z listy ("" - żadna) albo wybrane miejsce (-1 - żadne).
var selected_skill := ""
var selected_slot := -1
## Umiejętność czekająca na drugie stuknięcie „Ulepsz”.
var _buy_armed := ""
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
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(10))
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _label(head, tr("Umiejętności"), 18, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ember := TextureRect.new()
	ember.texture = preload("res://assets/watra/ember_icon.png")
	ember.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ember.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ember.custom_minimum_size = Vector2(18, 18)
	head.add_child(ember)
	embers_label = _label(head, "0", 15, GOLD)
	mastery_label = _label(column, "", 12, BLUE)
	mastery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # długie nazwy broni nie rozpychają okna
	weapon_button = _button(column, "")
	weapon_button.custom_minimum_size = Vector2(0, 46)
	weapon_button.expand_icon = true
	weapon_button.add_theme_constant_override("icon_max_width", 28)
	weapon_button.add_theme_font_size_override("font_size", 15)
	weapon_button.pressed.connect(open_weapons)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	tab_slots = _button(tabs, tr("Miejsca"))
	tab_slots.custom_minimum_size.y = 44
	tab_slots.pressed.connect(set_gems_mode.bind(false))
	tab_gems = _button(tabs, tr("Kamienie"))
	tab_gems.custom_minimum_size.y = 44
	tab_gems.pressed.connect(set_gems_mode.bind(true))
	tab_auras = _button(tabs, tr("Aury"))
	tab_auras.custom_minimum_size.y = 44
	tab_auras.pressed.connect(set_aura_mode)
	var scroll := ScrollContainer.new()
	TouchUi.drag_scroll(scroll)  # przewijanie palcem po wierszach i przyciskach
	skill_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for i in Skills.ORDER.size():
		_make_row(list, i)
	aura_scroll = ScrollContainer.new()
	TouchUi.drag_scroll(aura_scroll)  # przewijanie palcem po wierszach i przyciskach
	aura_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	aura_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aura_scroll.visible = false
	column.add_child(aura_scroll)
	aura_list = VBoxContainer.new()
	aura_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aura_list.add_theme_constant_override("separation", 6)
	aura_scroll.add_child(aura_list)
	hint = _label(column, "", 11, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.custom_minimum_size = Vector2(0, 30)
	_make_slots(column)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	column.add_child(bottom)
	clear_button = _button(bottom, tr("Zdejmij"))
	clear_button.pressed.connect(_on_clear)
	back_button = _button(bottom, tr("Wróć"))
	back_button.pressed.connect(close)
	picker = GemPicker.new()
	picker.changed.connect(refresh)
	add_child(picker)
	_make_weapon_menu()
	_game.skills_changed.connect(func() -> void:
		if visible:
			refresh())
	_game.inventory_changed.connect(func() -> void:
		if visible:
			refresh())
	_game.embers_changed.connect(func() -> void:
		if visible:
			refresh())
	_game.auras_changed.connect(func() -> void:
		if visible:
			refresh())


## Wiersz listy: ikona (pole do przeciągania), nazwa z manę i odnowieniem, opis, z prawej ulepszanie albo stan.
func _make_row(list: VBoxContainer, i: int) -> void:
	var id: String = Skills.ORDER[i]
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.1, 0.08, 0.9)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(5)
	box.add_theme_stylebox_override("panel", style)
	list.add_child(box)
	row_boxes.append(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var icon := SkillSlot.new(ROW_ICON)
	icon.area = "list"
	icon.index = i
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon.pressed.connect(_on_list_pressed.bind(i))
	icon.dropped.connect(_on_dropped_to_list)
	row.add_child(icon)
	list_icons.append(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 1)
	row.add_child(texts)
	name_labels.append(_label(texts, Skills.name_of(id), 14, GOLD))
	name_labels.back().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # długa nazwa z poziomem nie rozpycha okna
	info_labels.append(_label(texts, "", 11, BLUE))
	# z kamieniem unikalnym linia jest długa („20 many, potem 7 na sekundę, bez odnowienia”) - bez zawijania rozpychała
	# okno poza ekran (zgłoszenie autora 15.11.2026)
	info_labels.back().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var desc := _label(texts, Lang.t(Skills.DATA[id].description), 11, TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var perks: Array[Label] = []
	for k in Skills.PERK_LEVELS.size():
		var perk := _label(texts, "", 10, DIM)
		perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perks.append(perk)
	perk_labels.append(perks)
	var next := _label(texts, "", 10, BLUE)
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_labels.append(next)
	var gem_icons := HBoxContainer.new()
	gem_icons.add_theme_constant_override("separation", 2)
	texts.add_child(gem_icons)
	row_gems.append(gem_icons)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(66, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var status := _label(right, "", 11, DIM)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_labels.append(status)
	var memory := RichTextLabel.new()
	memory.bbcode_enabled = true
	memory.fit_content = true
	memory.scroll_active = false
	memory.autowrap_mode = TextServer.AUTOWRAP_OFF
	memory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory.add_theme_font_size_override("normal_font_size", 11)
	memory.add_theme_color_override("default_color", DIM)
	memory.visible = false
	right.add_child(memory)
	memory_labels.append(memory)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(66, 44)
	buy.add_theme_font_size_override("font_size", 12)
	buy.clip_text = true
	buy.pressed.connect(_on_buy.bind(id))
	right.add_child(buy)
	buy_buttons.append(buy)


## Rząd miejsc jak na przyciskach walki: „Atak” i 4 małe, z podpisami.
func _make_slots(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	slots_row = row
	for i in Skills.SLOTS:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		row.add_child(cell)
		var slot := SkillSlot.new(SLOT_SIZE + (8.0 if i == Skills.MAIN else 0.0))
		slot.area = "slot"
		slot.index = i
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.pressed.connect(_on_slot_pressed.bind(i))
		slot.dropped.connect(_on_dropped_to_slot.bind(i))
		cell.add_child(slot)
		slots.append(slot)
		var cap := _label(cell, tr("Atak") if i == Skills.MAIN else str(i), 11, GOLD if i == Skills.MAIN else DIM)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Przełącza dolną część: miejsca na przyciskach walki albo kamienie w umiejętnościach.
func set_gems_mode(on: bool) -> void:
	gems_mode = on
	aura_mode = false
	selected_skill = ""
	selected_slot = -1
	refresh()


## Zakładka „Aury”.
func set_aura_mode() -> void:
	aura_mode = true
	gems_mode = false
	selected_skill = ""
	selected_slot = -1
	_aura_problem = ""
	refresh()


## Otwiera okno i zatrzymuje grę. `shop` - można kupować (baza, kamień run).
func open(shop := false) -> void:
	can_shop = shop
	selected_skill = ""
	selected_slot = -1
	_buy_armed = ""
	_aura_problem = ""
	refresh()
	visible = true
	get_tree().paused = true


## Zamyka okno i wznawia grę.
func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


## Przycisk „wstecz”: najpierw zamyka wybór kamienia, potem zdejmuje wybór, potem zamyka okno.
func back() -> void:
	if weapon_menu.visible:
		weapon_menu.visible = false
	elif picker.visible:
		picker.close()
	elif selected_skill != "" or selected_slot >= 0:
		selected_skill = ""
		selected_slot = -1
		refresh()
	else:
		close()


func refresh() -> void:
	embers_label.text = str(_game.embers)
	var need: int = _game.mastery_needed()
	mastery_label.text = tr("Mistrzostwo: %s, poziom %d (%d/%d)") % [Weapons.name_of(_game.weapon),
			_game.mastery_level(), _game.weapon_xp(), need] if need > 0 \
			else tr("Mistrzostwo: %s, poziom %d") % [Weapons.name_of(_game.weapon), _game.mastery_level()]
	weapon_button.icon = Weapons.icon_of(_game.weapon)
	weapon_button.text = tr("%s  ▾ Zmień broń") % Weapons.name_of(_game.weapon) if _game.spare_weapon == "" \
			else tr("%s + %s  ▾ Bronie") % [Weapons.short_name_of(_game.weapon), Weapons.short_name_of(_game.spare_weapon)]
	_refresh_weapon_menu()
	for i in Skills.ORDER.size():
		var id: String = Skills.ORDER[i]
		row_boxes[i].visible = Skills.weapon_of(id) == _game.weapon
		var owned: bool = _game.skills_owned.has(id)
		list_icons[i].draggable = owned
		list_icons[i].show_skill(id, 0, false if gems_mode else (selected_skill == id))
		_show_row_gems(i)
		list_icons[i].modulate = Color.WHITE if owned else Color(0.6, 0.6, 0.6)
		var buy := buy_buttons[i]
		var status := status_labels[i]
		var at: int = _game.skill_slots.find(id)
		var lvl: int = _game.skill_level(id)
		_show_level(i, id, lvl, owned)
		if owned:
			var place := (tr("Pod „Atak”") if at == Skills.MAIN else tr("W miejscu %d") % at) if at >= 0 else tr("Odblokowana")
			var problem: String = _game.skill_upgrade_problem(id)
			var price: int = _game.skill_upgrade_cost(id)
			var memory: bool = can_shop and _game.memory_discount(id) and problem != "max" and problem != "mastery"
			memory_labels[i].visible = memory
			if memory:
				memory_labels[i].text = "[s]%d[/s] [color=#%s]%d[/color]\n[font_size=9]%s[/font_size]" % [
						Skills.upgrade_price(id, lvl), GREEN.to_html(false), price, tr("Pamięć oręża")]
			buy.visible = can_shop and problem != "max"
			buy.text = tr("Na pewno?") if _buy_armed == id else tr("Ulepsz")
			buy.disabled = problem != ""
			status.add_theme_color_override("font_color", GOLD if at >= 0 else DIM)
			if problem == "max":
				status.text = place + "\n" + tr("najwyższy poziom")
			elif problem == "mastery":
				status.text = place + "\n" + tr("ulepsz od mistrz. %d") % Skills.mastery_for(lvl + 1)
				status.add_theme_color_override("font_color", RED)
			elif can_shop and memory:
				status.text = place
				if problem == "embers":
					status.add_theme_color_override("font_color", RED)
			elif can_shop:
				status.text = place + "\n" + tr("%d żaru") % price
				if problem == "embers":
					status.add_theme_color_override("font_color", RED)
			else:
				status.text = place
		else:
			buy.visible = false
			memory_labels[i].visible = false
			status.text = tr("od mistrz. %d") % Skills.mastery_of(id)
			status.add_theme_color_override("font_color", RED)
	for i in Skills.SLOTS:
		var locked: int = 0 if _game.slot_open(i) else HeroLevels.SKILL_SLOT_LEVELS[i - 1]
		slots[i].show_skill(_game.skill_slots[i], locked, selected_slot == i)
	_tab_look(tab_slots, not gems_mode and not aura_mode)
	_tab_look(tab_gems, gems_mode)
	_tab_look(tab_auras, aura_mode)
	skill_scroll.visible = not aura_mode
	aura_scroll.visible = aura_mode
	slots_row.visible = not gems_mode and not aura_mode
	clear_button.visible = not gems_mode and not aura_mode
	if aura_mode:
		_refresh_auras()
		return
	if gems_mode:
		hint.text = tr("Stuknij umiejętność, żeby otworzyć jej kamienie: gniazda i kamienie do włożenia.")
		return
	clear_button.text = tr("Zdejmij")
	clear_button.disabled = selected_slot < 0
	if selected_skill != "":
		hint.text = tr("Stuknij miejsce na dole dla: %s") % Skills.name_of(selected_skill)
	elif selected_slot >= 0:
		hint.text = tr("Stuknij inne miejsce, żeby zamienić, albo „Zdejmij”.")
	else:
		hint.text = tr("Stuknij umiejętność, potem miejsce - albo przeciągnij ją na miejsce. Pod „Atak” działa auto atak.")


func _on_list_pressed(i: int) -> void:
	var id: String = Skills.ORDER[i]
	if gems_mode:
		if not _game.skills_owned.has(id):
			refresh()
			hint.text = _locked_hint(id)
			return
		picker.open_skill(id, Skills.of_weapon(_game.weapon).filter(
				func(s: String) -> bool: return _game.skills_owned.has(s)))
		return
	selected_slot = -1
	if not _game.skills_owned.has(id):
		selected_skill = ""
		_buy_armed = ""
		refresh()
		hint.text = _locked_hint(id)
		return
	selected_skill = "" if selected_skill == id else id
	refresh()


func _on_slot_pressed(slot: int) -> void:
	if not _game.slot_open(slot):
		return
	if selected_skill != "":
		_assign(selected_skill, slot)
		selected_skill = ""
	elif selected_slot >= 0 and selected_slot != slot:
		var id: String = _game.skill_slots[selected_slot]
		if id != "":
			_assign(id, slot)
		selected_slot = -1
	elif selected_slot == slot or _game.skill_slots[slot] == "":
		selected_slot = -1
	else:
		selected_slot = slot
	refresh()


## Przypisanie z komunikatem, gdy się nie da (Mgnienie pod „Atak”).
func _assign(id: String, slot: int) -> void:
	if not _game.assign_skill(id, slot):
		refresh()
		hint.text = tr("%s nie może stać pod „Atak”.") % Skills.name_of(id)


func _on_dropped_to_slot(skill: String, _from_area: String, _from_index: int, slot: int) -> void:
	selected_skill = ""
	selected_slot = -1
	_assign(skill, slot)


func _on_dropped_to_list(_skill: String, from_area: String, from_index: int) -> void:
	if from_area == "slot":
		selected_slot = -1
		_game.clear_skill_slot(from_index)


func _on_clear() -> void:
	if selected_slot >= 0:
		var slot := selected_slot
		selected_slot = -1
		_game.clear_skill_slot(slot)
		refresh()


## Poziom w wierszu: nazwa z „poz. X/10”, mana i odnowienie z premią poziomu, nowe działania (złote - odblokowane)
## i co da następny poziom (tylko przy kupionej).
func _show_level(i: int, id: String, lvl: int, owned: bool) -> void:
	name_labels[i].text = Skills.name_of(id) + ("  " + tr("poz. %d/%d") % [lvl, Skills.MAX_LEVEL] if owned else "")
	var extra: int = _game.item_skill_bonus(id)  # premie przedmiotów (poziom umiejętności)
	if owned and extra > 0:
		name_labels[i].text += " " + tr("(+%d z przedmiotów)") % extra
	var k := Skills.level_cost(lvl)
	var km := Skills.level_mana(lvl)
	var mana := roundi(Skills.mana_of(id) * km)
	var cd := Skills.cooldown_of(id) * k
	var unique: bool = id in ["whirl", "steel_ring", "k_flash"] and Gems.has_unique(_game.skill_sockets(id), id)
	if unique and id == "k_flash":
		mana = roundi(Skills.mana_of(id) * km * 0.5)  # kamień unikalny: skoki za pół many
	elif unique:
		cd = 0.0  # kamień unikalny: bez odnowienia
	if unique and id in ["whirl", "steel_ring"]:
		info_labels[i].text = tr("%d many, potem %d na sekundę, bez odnowienia") \
				% [mana, roundi(mana * (ProtoWeapon.WHIRL_DRAIN if id == "whirl" else ProtoWeapon.STEEL_DRAIN))]
		_show_perks(i, id, lvl, owned)
		return
	info_labels[i].text = tr("Bez many i odnowienia") if mana == 0 and cd == 0.0 \
			else tr("%d many za skok, bez odnowienia") % mana if cd == 0.0 \
			else tr("%d many za skok · odnowienie %s s") % [mana, String.num(cd, 1).trim_suffix(".0")] if id == "k_flash" \
			else tr("%d many · odnowienie %s s") % [mana, String.num(cd, 1).trim_suffix(".0")]
	_show_perks(i, id, lvl, owned)


## Nowe działania z 5. i 10. poziomu i co da następny poziom.
func _show_perks(i: int, id: String, lvl: int, owned: bool) -> void:
	for n in Skills.PERK_LEVELS.size():
		var perk: Label = perk_labels[i][n]
		var on: bool = lvl >= Skills.PERK_LEVELS[n]
		perk.text = tr("Poz. %d: %s") % [Skills.PERK_LEVELS[n], Skills.perk_text(id, n)]
		perk.add_theme_color_override("font_color", GOLD if on else DIM)
	next_labels[i].visible = owned and lvl < Skills.MAX_LEVEL
	next_labels[i].text = tr("Następny poziom: %s") % Skills.next_level_text(id, lvl)


## Stuknięcie broni: dostępną bierze do ręki (tylko przy kamieniu run), niedostępną odblokowuje Pieczęcią Oręża
## (drugie stuknięcie). Bez kamienia run i bez pieczęci - podpowiedź, skąd ją wziąć.
func _on_weapon(w: String) -> void:
	selected_skill = ""
	selected_slot = -1
	if w == _game.weapon:
		_buy_armed = ""
		refresh()
		return
	var why := ""
	if not can_shop:
		why = tr("Broń zmienisz przy kamieniu run w bazie.")
	elif _game.weapon_available(w):
		_buy_armed = ""
		_game.set_weapon(w)
		_play(preload("res://assets/watra/ember_pickup_big.ogg"))
		weapon_menu.visible = false
	elif _game.gem_count(Gems.WEAPON_SEAL) <= 0:
		_buy_armed = ""
		why = tr("%s: po pokonaniu Wodza na %d. poziomie lochu albo wcześniej Pieczęcią Oręża (rzadko ze skrzyni Wodza).") \
				% [Weapons.name_of(w), Weapons.unlock_level(w)]
	elif _buy_armed != "weapon:" + w:
		_buy_armed = "weapon:" + w
		why = tr("Odblokować %s Pieczęcią Oręża? Stuknij jeszcze raz.") % Weapons.name_of(w)
	else:
		_buy_armed = ""
		if _game.unseal_weapon(w):
			_play(preload("res://assets/watra/ember_pickup_big.ogg"))
			weapon_menu.visible = false
	refresh()
	if why != "":
		hint.text = why
		menu_hint.text = why


## Przycisk „Zapas” / „Odłóż” w wierszu broni: ustawia albo zdejmuje broń zapasową (tylko przy kamieniu run).
func _on_spare(w: String) -> void:
	_buy_armed = ""
	var why := ""
	if not can_shop:
		why = tr("Broń zapasową wybierzesz przy kamieniu run w bazie.")
	elif w == _game.spare_weapon:
		_game.set_spare("")
	elif _game.set_spare(w):
		_play(preload("res://assets/watra/ember_pickup_big.ogg"))
		why = tr("%s - broń zapasowa. W lochu zamienisz ją przyciskiem przy umiejętnościach; obie bronie zbierają mistrzostwo.") \
				% Weapons.name_of(w)
	refresh()
	if why != "":
		hint.text = why
		menu_hint.text = why


## Lista broni: przyciemnione tło, okno z wierszem każdej broni (przewijane palcem), pod nim podpowiedź i „Wróć”.
var menu_hint: Label


func _make_weapon_menu() -> void:
	weapon_menu = Control.new()
	weapon_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weapon_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	weapon_menu.visible = false
	add_child(weapon_menu)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weapon_menu.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_menu.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(10))
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	_label(col, tr("Bronie"), 18, GOLD)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchUi.drag_scroll(scroll)
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for w in Weapons.ORDER:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _panel_style(6))
		list.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Weapons.icon_of(w)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 40)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 0)
		row.add_child(texts)
		var title := _label(texts, Weapons.name_of(w), 15, TEXT)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var element := Weapons.element_of(w)
		_label(texts, Elements.name_of(element), 11, Elements.color_of(element))
		var state := _label(texts, "", 11, DIM)
		state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var b := Button.new()
		b.custom_minimum_size = Vector2(84, 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 13)
		b.clip_text = true
		b.pressed.connect(_on_weapon.bind(w))
		var buttons := VBoxContainer.new()  # „Weź” nad „Zapas” - nazwa broni ma miejsce w wierszu
		buttons.add_theme_constant_override("separation", 4)
		buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(buttons)
		buttons.add_child(b)
		var spare := Button.new()
		spare.custom_minimum_size = Vector2(84, 44)
		spare.add_theme_font_size_override("font_size", 13)
		spare.clip_text = true
		spare.pressed.connect(_on_spare.bind(w))
		buttons.add_child(spare)
		weapon_buttons[w] = b
		weapon_rows[w] = {"box": box, "state": state, "spare": spare}
	menu_hint = _label(col, "", 11, DIM)
	menu_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_b := _button(col, tr("Wróć"))
	close_b.pressed.connect(func() -> void: weapon_menu.visible = false)


## Otwiera listę broni (przycisk z bronią w ręku).
func open_weapons() -> void:
	_buy_armed = ""
	_refresh_weapon_menu()
	menu_hint.text = "" if can_shop else tr("Broń zmienisz przy kamieniu run w bazie.")
	weapon_menu.visible = true


## Wiersze listy broni: w ręku - złota ramka i „W ręku”; dostępna - „Weź”; zamknięta - od którego lochu (i przycisk
## Pieczęci Oręża, gdy jest w sakwie).
func _refresh_weapon_menu() -> void:
	for w in weapon_rows:
		var b: Button = weapon_buttons[w]
		var held: bool = w == _game.weapon
		var ready: bool = _game.weapon_available(w)
		var st := _panel_style(6)
		st.border_color = GOLD if held else Color(0.4, 0.3, 0.2)
		st.set_border_width_all(2 if held else 1)
		(weapon_rows[w].box as PanelContainer).add_theme_stylebox_override("panel", st)
		var state: Label = weapon_rows[w].state
		var spare_b: Button = weapon_rows[w].spare
		var is_spare: bool = w == _game.spare_weapon
		spare_b.visible = ready and not held
		spare_b.text = tr("Odłóż") if is_spare else tr("Zapas")
		_tab_look(spare_b, is_spare)
		if is_spare:
			st.border_color = Color(0.85, 0.65, 0.35)
			st.set_border_width_all(2)
		if held or ready:
			b.text = tr("W ręku") if held else tr("Weź")
			var lvl: int = _game.mastery_level(w)
			var mult: float = _game.mastery_mult(w)
			var where := tr("W ręku") if held else (tr("Zapasowa") if is_spare else tr("Dostępna"))
			state.text = tr("%s, mistrzostwo %d, szybsze x%d") % [where, lvl, roundi(mult)] if mult > 1.0 \
					else tr("%s, mistrzostwo %d") % [where, lvl]
		else:
			state.text = tr("Po lochu %d albo Pieczęcią Oręża") % Weapons.unlock_level(w)
			b.text = tr("Na pewno?") if _buy_armed == "weapon:" + w else tr("Pieczęć")
		b.disabled = held
		_tab_look(b, held)


## Podpowiedź przy nieodblokowanej umiejętności: od którego poziomu mistrzostwa broni.
func _locked_hint(id: String) -> String:
	return tr("Odblokuje ją mistrzostwo: %s, poziom %d. Rośnie od pokonanych potworów i bossów.") \
			% [Weapons.name_of(Skills.weapon_of(id)), Skills.mastery_of(id)]


## Ulepszanie: pierwsze stuknięcie pyta „Na pewno?”, drugie ulepsza za żar.
func _on_buy(id: String) -> void:
	if _buy_armed != id:
		_buy_armed = id
		refresh()
		return
	_buy_armed = ""
	if _game.upgrade_skill(id):
		_play(preload("res://assets/watra/ember_pickup_big.ogg"))
	refresh()


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
## Powód ostatniej odmowy włączenia aury (pokazany w podpowiedzi do kolejnej zmiany).
var _aura_problem := ""


## Zakładka „Aury”: suma rezerwacji i wiersz każdej aury (ikona, nazwa z poziomem, rezerwacja, działanie, przycisk).
func _refresh_auras() -> void:
	for c in aura_list.get_children():
		c.queue_free()
	var cut: float = _game.aura_cut()
	var reserved := Auras.reserved_total(_game.auras_on, _game.auras, cut)
	var total := _label(aura_list, tr("Aury rezerwują %d%% many (najwięcej %d%%)") % [roundi(reserved * 100),
			roundi(Auras.MAX_RESERVED * 100)], 12, BLUE)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for id: String in Auras.ORDER:
		var lvl: int = _game.auras.get(id, 0)
		var on: bool = _game.auras_on.has(id)
		var box := PanelContainer.new()
		var st := _panel_style(6)
		st.bg_color = Color(0.16, 0.11, 0.08) if lvl > 0 else Color(0.1, 0.08, 0.07, 0.8)
		st.border_color = Auras.color_of(id) if on else Color(0.4, 0.3, 0.2)
		st.set_border_width_all(2 if on else 1)
		box.add_theme_stylebox_override("panel", st)
		aura_list.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Auras.icon_of(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.modulate = Color.WHITE if lvl > 0 else Color(0.45, 0.45, 0.45)
		row.add_child(icon)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		row.add_child(col)
		var title := tr("%s %d/%d") % [Auras.name_of(id), lvl, Auras.MAX_LEVEL] if lvl > 0 else Auras.name_of(id)
		var title_label := _label(col, title, 13, Auras.color_of(id) if lvl > 0 else DIM)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # długa nazwa z 10/10 nie rozpycha okna
		_label(col, Auras.cost_text(id, maxi(lvl, 1), cut), 11, BLUE)
		var desc := _label(col, Auras.effect_text(id, maxi(lvl, 1)), 11, TEXT if lvl > 0 else DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if lvl == 0:
			var where := _label(col, tr("Kamień aury wypada ze skrzyń od lochu %d") % Auras.MIN_LEVEL, 10, RED)
			where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			continue
		var b := Button.new()
		b.text = tr("Wyłącz") if on else tr("Włącz")
		b.custom_minimum_size = Vector2(70, 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 13)
		if on:
			_tab_look(b, true)
		b.pressed.connect(_on_aura_pressed.bind(id))
		row.add_child(b)
	if _aura_problem != "":
		hint.text = _aura_problem
	elif _game.auras.is_empty():
		hint.text = tr("Nie masz jeszcze żadnej aury. Kamienie aur wypadają ze skrzyń od lochu %d.") % Auras.MIN_LEVEL
	else:
		hint.text = tr("Włączona aura działa cały czas, ale zajmuje część many. Kolejny taki sam kamień podnosi jej poziom.")


func _on_aura_pressed(id: String) -> void:
	_aura_problem = _game.toggle_aura(id)
	refresh()


## Małe ikony kamieni z gniazd umiejętności w wierszu listy (puste otwarte gniazdo - kółko gniazda).
func _show_row_gems(i: int) -> void:
	var id: String = Skills.ORDER[i]
	var box := row_gems[i]
	for c in box.get_children():
		c.queue_free()
	if not _game.skills_owned.has(id):
		return
	var sockets: Array = _game.skill_sockets(id)
	for k in _game.skill_open_count(id):
		var icon := TextureRect.new()
		icon.texture = Gems.icon_of(sockets[k]) if sockets[k] != "" else Gems.SOCKET_ICON
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)


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

class_name SkillsWindow
extends Control
## Okno umiejętności (ustalenia z autorem 12.11.2026). U góry złoto, niżej przewijana lista umiejętności miecza
## (Skills): ikona, nazwa, koszt many i odnowienie, opis, a obok cena i wymagany poziom albo „Kupiona”. Kupuje się
## tylko w bazie przy kamieniu run (`open(true)`; drugie stuknięcie „Kup” potwierdza), z pauzy okno służy do
## przestawiania. Na dole, pod kciukiem, rząd miejsc jak na przyciskach walki: „Atak” (duży przycisk - z auto atakiem)
## i 4 małe (zablokowane do poziomu postaci). Przypisanie: stuknij umiejętność, potem miejsce - albo przeciągnij ikonę
## na miejsce (SkillSlot). Stuknięcie zajętego miejsca wybiera je: potem stuknięcie innego miejsca zamienia je
## miejscami, a „Zdejmij” opróżnia. Mgnienie nie może stać pod „Atak”. Stan trzyma i zapisuje Game.
## Zakładka „Kamienie” (Gems, część 4 rozwoju postaci): stuknięcie umiejętności na liście wybiera ją, na dole jej
## 5 gniazd (otwarte Game.skill_open_count, zamknięte z kluczem - stuknięcie otwiera Kluczem Runicznym, drugie
## potwierdza) i sakwa z kamieniami umiejętności. Pod każdym gniazdem krótko, co robi jego kamień (Gems.short_text).
## Wkładanie (13.11.2026): stuknięcie otwartego gniazda otwiera GemPicker z pasującymi kamieniami i ich działaniem
## w tej umiejętności („Włóż”, „Wymień”, „Wyjmij”), stuknięcie kamienia w sakwie - GemPicker z listą umiejętności,
## gdzie pasuje; można też przeciągnąć kamień na gniazdo (GemSlot), a z gniazda do sakwy (wyjęcie za darmo).
## W każdym wierszu listy małe ikony kamieni z gniazd tej umiejętności.
## Poziomy umiejętności (13.11.2026): przy nazwie „poz. X/10”, mana i odnowienie już z premią poziomu, pod opisem
## nowe działania z 5. i 10. poziomu (złote - odblokowane) i co da następny poziom. Kupiona umiejętność ma z prawej
## przycisk „Ulepsz” z ceną (przy kamieniu run, drugie stuknięcie potwierdza; Game.upgrade_skill), a gdy poziom
## postaci nie pozwala - od którego poziomu postaci (Skills.level_cap).
## Zatrzymuje grę, gdy jest otwarte (PROCESS_MODE_ALWAYS).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.75)
const BLUE := Color(0.55, 0.7, 1.0)
const RED := Color(1, 0.55, 0.45)
const ROW_ICON := 48.0
const SLOT_SIZE := 52.0

## Czy można kupować (baza, kamień run).
var can_shop := false
var gold_label: Label
var hint: Label
var list_icons: Array[SkillSlot] = []
var buy_buttons: Array[Button] = []
var status_labels: Array[Label] = []
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
var slots_row: HBoxContainer
var gems_box: VBoxContainer
var socket_slots: Array[GemSlot] = []
## Krótkie opisy pod gniazdami i wysuwany wybór kamienia.
var socket_labels: Array[Label] = []
var picker: GemPicker
var pouch_row: HBoxContainer
var pouch_empty: Label
## Małe ikony kamieni w wierszach listy (wiersz -> pojemnik).
var row_gems: Array[HBoxContainer] = []
## Zakładka „Kamienie”: umiejętność, której gniazda widać, wybrany kamień z sakwy i wybrane gniazdo.
var gem_skill := Skills.STRIKE
var selected_gem := ""
var selected_socket := -1
## Pierwsze stuknięcie zamkniętego gniazda (drugie zużywa klucz).
var _key_armed := false
## Wybrana umiejętność z listy ("" - żadna) albo wybrane miejsce (-1 - żadne).
var selected_skill := ""
var selected_slot := -1
## Umiejętność czekająca na drugie stuknięcie „Kup”.
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
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/watra/items/coin.png")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(18, 18)
	head.add_child(coin)
	gold_label = _label(head, "0", 15, GOLD)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	tab_slots = _button(tabs, tr("Miejsca"))
	tab_slots.custom_minimum_size.y = 44
	tab_slots.pressed.connect(set_gems_mode.bind(false))
	tab_gems = _button(tabs, tr("Kamienie"))
	tab_gems.custom_minimum_size.y = 44
	tab_gems.pressed.connect(set_gems_mode.bind(true))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for i in Skills.ORDER.size():
		_make_row(list, i)
	hint = _label(column, "", 11, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.custom_minimum_size = Vector2(0, 30)
	_make_slots(column)
	_make_gems(column)
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
	_game.skills_changed.connect(func() -> void:
		if visible:
			refresh())
	_game.inventory_changed.connect(func() -> void:
		if visible:
			refresh())


## Wiersz listy: ikona (pole do przeciągania), nazwa z manę i odnowieniem, opis, z prawej kupno albo stan.
func _make_row(list: VBoxContainer, i: int) -> void:
	var id: String = Skills.ORDER[i]
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.1, 0.08, 0.9)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(5)
	box.add_theme_stylebox_override("panel", style)
	list.add_child(box)
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
	info_labels.append(_label(texts, "", 11, BLUE))
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


## Zakładka „Kamienie”: rząd 5 gniazd wybranej umiejętności, pod nim przewijana sakwa z kamieniami umiejętności.
func _make_gems(column: VBoxContainer) -> void:
	gems_box = VBoxContainer.new()
	gems_box.add_theme_constant_override("separation", 4)
	gems_box.visible = false
	column.add_child(gems_box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	gems_box.add_child(row)
	for i in Gems.SKILL_SOCKETS:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(58, 0)
		cell.add_theme_constant_override("separation", 0)
		row.add_child(cell)
		var slot := GemSlot.new(48.0)
		slot.area = "socket"
		slot.index = i
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.pressed.connect(_on_socket_pressed.bind(i))
		slot.dropped.connect(_on_dropped_to_socket.bind(i))
		cell.add_child(slot)
		socket_slots.append(slot)
		var cap := _label(cell, "", 9, DIM)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.custom_minimum_size = Vector2(58, 24)
		socket_labels.append(cap)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 52)
	gems_box.add_child(scroll)
	var holder := HBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	pouch_row = HBoxContainer.new()
	pouch_row.add_theme_constant_override("separation", 4)
	holder.add_child(pouch_row)
	pouch_empty = _label(holder, tr("Sakwa pusta - kamienie wypadają w lochach od poziomu %d.") % Gems.MIN_LEVEL, 11, DIM)
	pouch_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pouch_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pouch_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Przełącza dolną część: miejsca na przyciskach walki albo kamienie w umiejętnościach.
func set_gems_mode(on: bool) -> void:
	gems_mode = on
	selected_skill = ""
	selected_slot = -1
	selected_gem = ""
	selected_socket = -1
	_key_armed = false
	if on and not _game.skills_owned.has(gem_skill):
		gem_skill = Skills.STRIKE
	refresh()


## Otwiera okno i zatrzymuje grę. `shop` - można kupować (baza, kamień run).
func open(shop := false) -> void:
	can_shop = shop
	selected_skill = ""
	selected_slot = -1
	_buy_armed = ""
	selected_gem = ""
	selected_socket = -1
	_key_armed = false
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
	if picker.visible:
		picker.close()
	elif selected_skill != "" or selected_slot >= 0 or selected_gem != "" or selected_socket >= 0:
		selected_skill = ""
		selected_slot = -1
		selected_gem = ""
		selected_socket = -1
		refresh()
	else:
		close()


func refresh() -> void:
	gold_label.text = str(_game.gold)
	for i in Skills.ORDER.size():
		var id: String = Skills.ORDER[i]
		var owned: bool = _game.skills_owned.has(id)
		list_icons[i].draggable = owned
		list_icons[i].show_skill(id, 0, (gem_skill == id) if gems_mode else (selected_skill == id))
		_show_row_gems(i)
		list_icons[i].modulate = Color.WHITE if owned else Color(0.6, 0.6, 0.6)
		var buy := buy_buttons[i]
		var status := status_labels[i]
		var at: int = _game.skill_slots.find(id)
		var lvl: int = _game.skill_level(id)
		_show_level(i, id, lvl, owned)
		if owned:
			var place := (tr("Pod „Atak”") if at == Skills.MAIN else tr("W miejscu %d") % at) if at >= 0 else tr("Kupiona")
			var problem: String = _game.skill_upgrade_problem(id)
			var price := Skills.upgrade_price(id, lvl)
			buy.visible = can_shop and problem != "max"
			buy.text = tr("Na pewno?") if _buy_armed == id else tr("Ulepsz")
			buy.disabled = problem != ""
			status.add_theme_color_override("font_color", GOLD if at >= 0 else DIM)
			if problem == "max":
				status.text = place + "\n" + tr("najwyższy poziom")
			elif problem == "hero":
				status.text = place + "\n" + tr("ulepsz od poz. %d") % Skills.hero_level_for(lvl + 1)
				status.add_theme_color_override("font_color", RED)
			elif can_shop:
				status.text = place + "\n" + tr("%d zł") % price
				if problem == "gold":
					status.add_theme_color_override("font_color", RED)
			else:
				status.text = place
		else:
			var need := Skills.level_of(id)
			var price := Skills.price_of(id)
			buy.visible = can_shop
			buy.text = tr("Na pewno?") if _buy_armed == id else tr("Kup")
			buy.disabled = not _game.can_buy_skill(id)
			if _game.hero_level < need:
				status.text = tr("%d zł\nod poz. %d") % [price, need]
				status.add_theme_color_override("font_color", RED)
			else:
				status.text = tr("%d zł") % price
				status.add_theme_color_override("font_color", GOLD if _game.gold >= price else RED)
			if not can_shop:
				status.text += "\n" + tr("kup przy kamieniu run")
	for i in Skills.SLOTS:
		var locked: int = 0 if _game.slot_open(i) else HeroLevels.SKILL_SLOT_LEVELS[i - 1]
		slots[i].show_skill(_game.skill_slots[i], locked, selected_slot == i)
	_tab_look(tab_slots, not gems_mode)
	_tab_look(tab_gems, gems_mode)
	slots_row.visible = not gems_mode
	gems_box.visible = gems_mode
	clear_button.visible = not gems_mode
	if gems_mode:
		_refresh_gems()
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
		_key_armed = false
		selected_socket = -1
		if not _game.skills_owned.has(id):
			refresh()
			hint.text = tr("Najpierw kup tę umiejętność przy kamieniu run w bazie.")
			return
		gem_skill = id
		refresh()
		return
	selected_slot = -1
	if not _game.skills_owned.has(id):
		selected_skill = ""
		_buy_armed = ""
		refresh()
		hint.text = tr("Najpierw kup tę umiejętność przy kamieniu run w bazie.")
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
	if gems_mode:
		if selected_socket >= 0:
			_game.unsocket_skill(gem_skill, selected_socket)
			selected_socket = -1
			refresh()
		return
	if selected_slot >= 0:
		var slot := selected_slot
		selected_slot = -1
		_game.clear_skill_slot(slot)
		refresh()


## Poziom w wierszu: nazwa z „poz. X/10”, mana i odnowienie z premią poziomu, nowe działania (złote - odblokowane)
## i co da następny poziom (tylko przy kupionej).
func _show_level(i: int, id: String, lvl: int, owned: bool) -> void:
	name_labels[i].text = Skills.name_of(id) + ("  " + tr("poz. %d/%d") % [lvl, Skills.MAX_LEVEL] if owned else "")
	var k := Skills.level_cost(lvl)
	var mana := roundi(Skills.mana_of(id) * k)
	var cd := Skills.cooldown_of(id) * k
	var unique: bool = id in ["whirl", "blink"] and Gems.has_unique(_game.skill_sockets(id), id)
	if unique:
		cd = 0.0  # kamień unikalny: bez odnowienia
	if unique and id == "whirl":
		info_labels[i].text = tr("%d many, potem %d na sekundę, bez odnowienia") \
				% [mana, roundi(mana * ProtoWeapon.WHIRL_DRAIN)]
		_show_perks(i, id, lvl, owned)
		return
	info_labels[i].text = tr("Bez many i odnowienia") if mana == 0 and cd == 0.0 \
			else tr("%d many za skok, bez odnowienia") % mana if cd == 0.0 \
			else tr("%d many za skok · odnowienie %s s") % [mana, String.num(cd, 1).trim_suffix(".0")] if id == "blink" \
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


## Kupno i ulepszanie: pierwsze stuknięcie pyta „Na pewno?”, drugie kupuje (niekupioną) albo ulepsza (kupioną).
func _on_buy(id: String) -> void:
	if _buy_armed != id:
		_buy_armed = id
		refresh()
		return
	_buy_armed = ""
	var ok: bool = _game.upgrade_skill(id) if _game.skills_owned.has(id) else _game.buy_skill(id)
	if ok:
		_play(preload("res://assets/watra/handleCoins.ogg"))
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


## Zakładka „Kamienie”: gniazda wybranej umiejętności, sakwa i podpowiedź.
func _refresh_gems() -> void:
	var sockets: Array = _game.skill_sockets(gem_skill)
	var open: int = _game.skill_open_count(gem_skill)
	for i in Gems.SKILL_SOCKETS:
		socket_slots[i].show_gem(sockets[i] if i < open else "", 0, selected_socket == i, i >= open)
		var cap := socket_labels[i]
		if i >= open:
			cap.text = tr("zamknięte")
			cap.add_theme_color_override("font_color", Color(1, 0.85, 0.6, 0.45))
		elif sockets[i] == "":
			cap.text = tr("puste")
			cap.add_theme_color_override("font_color", DIM)
		else:
			cap.text = Gems.short_text(sockets[i], gem_skill)
			cap.add_theme_color_override("font_color", Gems.color_of(sockets[i]))
	for c in pouch_row.get_children():
		pouch_row.remove_child(c)
		c.queue_free()
	var list: Array = _game.gem_list("support")
	if _game.gem_count(Gems.KEY) > 0:
		list.push_front(Gems.KEY)
	if not list.has(selected_gem):
		selected_gem = ""
	for k in list.size():
		var id: String = list[k]
		var slot := GemSlot.new(44.0)
		slot.area = "pouch"
		slot.index = k
		slot.show_gem(id, _game.gem_count(id), selected_gem == id)
		slot.pressed.connect(_on_pouch_pressed.bind(id))
		slot.dropped.connect(_on_dropped_to_pouch)
		pouch_row.add_child(slot)
	pouch_empty.visible = list.is_empty()
	clear_button.text = tr("Wyjmij")
	clear_button.disabled = selected_socket < 0
	var skill_name := Skills.name_of(gem_skill)
	if _key_armed:
		hint.text = tr("Otworzyć gniazdo w: %s? Zużyje Klucz Runiczny (masz %d). Stuknij jeszcze raz.") \
				% [skill_name, _game.gem_count(Gems.KEY)]
	elif selected_gem != "" and Gems.is_special(selected_gem):
		hint.text = tr("%s: %s") % [Gems.name_of(selected_gem), Gems.description(selected_gem)[0]]
	elif selected_gem != "":
		hint.text = tr("%s w: %s - %s Stuknij gniazdo.") % [Gems.name_of(selected_gem), skill_name,
				Gems.support_text(selected_gem, gem_skill)]
	elif selected_socket >= 0:
		var id: String = sockets[selected_socket]
		hint.text = tr("%s: %s „Wyjmij” odkłada kamień do sakwy.") % [Gems.name_of(id), Gems.support_text(id, gem_skill)]
	else:
		hint.text = tr("Kamienie w: %s. Stuknij gniazdo, żeby włożyć kamień, albo kamień, żeby zobaczyć, gdzie pasuje.") % skill_name


## Kamień w sakwie: GemPicker z listą umiejętności, gdzie pasuje (klucz - gdzie otworzyć gniazdo).
func _on_pouch_pressed(id: String) -> void:
	_key_armed = false
	selected_socket = -1
	selected_gem = ""
	refresh()
	picker.open_gem(id)


func _on_socket_pressed(i: int) -> void:
	var open: int = _game.skill_open_count(gem_skill)
	if i >= open:
		selected_gem = ""
		selected_socket = -1
		if _game.gem_count(Gems.KEY) <= 0:
			_key_armed = false
			refresh()
			hint.text = tr("Gniazdo zamknięte. Otwiera je Klucz Runiczny - rzadki łup ze skrzyni Wodza.")
		elif not _key_armed:
			_key_armed = true
			refresh()
		else:
			_key_armed = false
			if _game.open_skill_socket(gem_skill):
				_play(preload("res://assets/watra/glass_002.ogg"))
			refresh()
		return
	_key_armed = false
	selected_gem = ""
	selected_socket = -1
	refresh()
	picker.open_skill_socket(gem_skill, i)


## Wkłada kamień w gniazdo z komunikatem, gdy się nie da.
func _put(id: String, i: int) -> void:
	var problem: String = _game.skill_socket_problem(gem_skill, i, id)
	selected_gem = ""
	selected_socket = -1
	if problem == "" and _game.socket_skill(gem_skill, i, id):
		_play(preload("res://assets/watra/handleSmallLeather.ogg"))
		refresh()
		return
	refresh()
	if problem == "same":
		hint.text = tr("%s ma już kamień tego rodzaju.") % Skills.name_of(gem_skill)
	elif problem == "skill":
		hint.text = tr("Pasuje tylko do: %s.") % Skills.name_of(Gems.unique_skill(id))


func _on_dropped_to_socket(gem: String, from_area: String, from_index: int, i: int) -> void:
	_key_armed = false
	if from_area == "pouch":
		_put(gem, i)
	elif from_area == "socket" and from_index != i:
		# przeniesienie między gniazdami tej samej umiejętności: wyjęcie i włożenie
		var old: String = _game.skill_sockets(gem_skill)[i]
		_game.unsocket_skill(gem_skill, from_index)
		if old != "":
			_game.unsocket_skill(gem_skill, i)
			_game.socket_skill(gem_skill, from_index, old)
		_put(gem, i)


func _on_dropped_to_pouch(_gem: String, from_area: String, from_index: int) -> void:
	if from_area == "socket":
		selected_socket = -1
		_game.unsocket_skill(gem_skill, from_index)
		refresh()


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

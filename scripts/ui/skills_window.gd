class_name SkillsWindow
extends Control
## Okno umiejętności (ustalenia z autorem 12.11.2026). U góry złoto, niżej przewijana lista umiejętności miecza
## (Skills): ikona, nazwa, koszt many i odnowienie, opis, a obok cena i wymagany poziom albo „Kupiona”. Kupuje się
## tylko w bazie przy kamieniu run (`open(true)`; drugie stuknięcie „Kup” potwierdza), z pauzy okno służy do
## przestawiania. Na dole, pod kciukiem, rząd miejsc jak na przyciskach walki: „Atak” (duży przycisk - z auto atakiem)
## i 4 małe (zablokowane do poziomu postaci). Przypisanie: stuknij umiejętność, potem miejsce - albo przeciągnij ikonę
## na miejsce (SkillSlot). Stuknięcie zajętego miejsca wybiera je: potem stuknięcie innego miejsca zamienia je
## miejscami, a „Zdejmij” opróżnia. Mgnienie nie może stać pod „Atak”. Stan trzyma i zapisuje Game.
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
var slots: Array[SkillSlot] = []
var clear_button: Button
var back_button: Button
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
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	column.add_child(bottom)
	clear_button = _button(bottom, tr("Zdejmij"))
	clear_button.pressed.connect(_on_clear)
	back_button = _button(bottom, tr("Wróć"))
	back_button.pressed.connect(close)
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
	_label(texts, Skills.name_of(id), 14, GOLD)
	var info := tr("Bez many i odnowienia") if Skills.mana_of(id) == 0 \
			else tr("%d many za skok, bez odnowienia") % Skills.mana_of(id) if Skills.cooldown_of(id) == 0.0 \
			else tr("%d many · odnowienie %d s") % [Skills.mana_of(id), roundi(Skills.cooldown_of(id))]
	_label(texts, info, 11, BLUE)
	var desc := _label(texts, Lang.t(Skills.DATA[id].description), 11, TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


## Otwiera okno i zatrzymuje grę. `shop` - można kupować (baza, kamień run).
func open(shop := false) -> void:
	can_shop = shop
	selected_skill = ""
	selected_slot = -1
	_buy_armed = ""
	refresh()
	visible = true
	get_tree().paused = true


## Zamyka okno i wznawia grę (otwarte z pauzy wraca do pauzy, więc gra stoi dalej).
func close() -> void:
	visible = false
	if not get_parent() is PauseMenu:
		get_tree().paused = false
	closed.emit()


## Przycisk „wstecz”: najpierw zdejmuje wybór, potem zamyka okno.
func back() -> void:
	if selected_skill != "" or selected_slot >= 0:
		selected_skill = ""
		selected_slot = -1
		refresh()
	else:
		close()


func refresh() -> void:
	gold_label.text = str(_game.gold)
	for i in Skills.ORDER.size():
		var id: String = Skills.ORDER[i]
		var owned: bool = _game.skills_owned.has(id)
		list_icons[i].draggable = owned
		list_icons[i].show_skill(id, 0, selected_skill == id)
		list_icons[i].modulate = Color.WHITE if owned else Color(0.6, 0.6, 0.6)
		var buy := buy_buttons[i]
		var status := status_labels[i]
		var at: int = _game.skill_slots.find(id)
		if owned:
			buy.visible = false
			status.text = (tr("Pod „Atak”") if at == Skills.MAIN else tr("W miejscu %d") % at) if at >= 0 else tr("Kupiona")
			status.add_theme_color_override("font_color", GOLD if at >= 0 else DIM)
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
	clear_button.disabled = selected_slot < 0
	if selected_skill != "":
		hint.text = tr("Stuknij miejsce na dole dla: %s") % Skills.name_of(selected_skill)
	elif selected_slot >= 0:
		hint.text = tr("Stuknij inne miejsce, żeby zamienić, albo „Zdejmij”.")
	else:
		hint.text = tr("Stuknij umiejętność, potem miejsce - albo przeciągnij ją na miejsce. Pod „Atak” działa auto atak.")


func _on_list_pressed(i: int) -> void:
	var id: String = Skills.ORDER[i]
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
	if selected_slot >= 0:
		var slot := selected_slot
		selected_slot = -1
		_game.clear_skill_slot(slot)
		refresh()


## Kupno: pierwsze stuknięcie pyta „Na pewno?”, drugie kupuje.
func _on_buy(id: String) -> void:
	if _buy_armed != id:
		_buy_armed = id
		refresh()
		return
	_buy_armed = ""
	if _game.buy_skill(id):
		_play(preload("res://assets/watra/handleCoins.ogg"))
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

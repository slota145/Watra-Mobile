class_name GemPicker
extends Control
## Wybór kamienia wysuwany od dołu ekranu (ustalone z autorem 13.11.2026) - dwie drogi wkładania kamieni:
## - „najpierw gniazdo” (`open_skill_socket`, `open_item_socket`): lista tylko pasujących kamieni z sakwy, przy każdym
##   co zrobi w tej umiejętności albo w tym przedmiocie (Gems.support_text, Gems.jewel_text); kamień, którego nie da się
##   włożyć, jest przygaszony z powodem; u góry kamień, który już siedzi w gnieździe, z przyciskiem „Wyjmij”;
## - „najpierw kamień” (`open_gem` - stuknięcie kamienia w sakwie): opis kamienia i lista miejsc, gdzie pasuje (kamień
##   umiejętności - kupione umiejętności, szlachetny - założone przedmioty i torba), przy każdym działanie i „Włóż”
##   (w pierwsze wolne gniazdo). Klucz Runiczny - umiejętności z zamkniętymi gniazdami („Otwórz”), Dłuto Jubilera -
##   przedmioty z jednym gniazdem („Dorób”); oba z potwierdzeniem drugim stuknięciem.
## Każdy przycisk ma co najmniej 44 px, „Zamknij” na dole pod kciukiem. Po włożeniu okno zamyka się (sygnał `changed`).
## Stan trzyma i zapisuje Game. Działa przy zatrzymanej grze.

signal changed
signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.75)
const RED := Color(1, 0.5, 0.42)
const PUT_SOUND := preload("res://assets/watra/handleSmallLeather.ogg")
const GEM_SOUND := preload("res://assets/watra/glass_002.ogg")

## Tryb: "skill_socket", "item_socket" albo "gem".
var mode := ""
var skill := ""
var item: Dictionary = {}
var index := -1
var gem := ""
## Przycisk czekający na drugie stuknięcie (klucz, dłuto).
var armed := ""
var title_label: Label
var sub_label: Label
var list: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
## Przyciski akcji w wierszach (do testów): klucz wiersza -> przycisk.
var actions := {}
var _panel: PanelContainer
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			close())
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.06, 0.98)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 8
	_panel.offset_right = -8
	_panel.offset_bottom = -8
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	_panel.add_child(col)
	title_label = _label(col, "", 16, GOLD)
	sub_label = _label(col, "", 11, DIM)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	close_button = Button.new()
	close_button.text = tr("Zamknij")
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(close)
	col.add_child(close_button)


## Gniazdo `i` umiejętności: pasujące kamienie umiejętności.
func open_skill_socket(skill_id: String, i: int) -> void:
	_open("skill_socket")
	skill = skill_id
	index = i
	_build()


## Gniazdo `i` przedmiotu (słownik z torby albo założony): pasujące kamienie szlachetne.
func open_item_socket(target: Dictionary, i: int) -> void:
	_open("item_socket")
	item = target
	index = i
	_build()


## Kamień (klucz, dłuto) z sakwy: gdzie pasuje i co tam zrobi.
func open_gem(id: String) -> void:
	_open("gem")
	gem = id
	_build()


func close() -> void:
	visible = false
	armed = ""
	closed.emit()


func _open(new_mode: String) -> void:
	mode = new_mode
	armed = ""
	skill = ""
	item = {}
	index = -1
	gem = ""
	title_label.remove_theme_color_override("font_color")
	title_label.add_theme_color_override("font_color", GOLD)
	visible = true


func _build() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	actions.clear()
	match mode:
		"skill_socket":
			_build_skill_socket()
		"item_socket":
			_build_item_socket()
		"gem":
			_build_gem()
	_fit.call_deferred()


## Lista nie wyższa niż ok. 60% ekranu - reszta przewija się palcem.
func _fit() -> void:
	var limit := get_viewport_rect().size.y * 0.6
	scroll.custom_minimum_size = Vector2(0, minf(list.get_combined_minimum_size().y, limit))


# --- najpierw gniazdo ---

func _build_skill_socket() -> void:
	title_label.text = tr("%s - gniazdo %d") % [Skills.name_of(skill), index + 1]
	var current: String = _game.skill_sockets(skill)[index]
	_current_row(current, Gems.support_text(current, skill) if current != "" else "")
	var gems: Array = _game.gem_list("support")
	sub_label.text = tr("Kamienie umiejętności z sakwy - co zrobią w: %s") % Skills.name_of(skill)
	if gems.is_empty():
		_label(list, tr("Brak kamieni umiejętności. Wypadają w lochach od poziomu %d.") % Gems.MIN_LEVEL, 12, DIM, true)
	for id in gems:
		var problem: String = _game.skill_socket_problem(skill, index, id)
		var reason := tr("%s ma już kamień tego rodzaju.") % Skills.name_of(skill) if problem == "same" \
				else tr("Pasuje tylko do: %s.") % Skills.name_of(Gems.unique_skill(id)) if problem == "skill" else ""
		var b := _row(id, Gems.icon_of(id), Gems.name_of(id), Gems.color_of(id), Gems.support_text(id, skill),
				reason, tr("Wymień") if current != "" else tr("Włóż"))
		b.disabled = problem != ""
		b.pressed.connect(func() -> void:
			if _game.socket_skill(skill, index, id):
				_done(PUT_SOUND))


func _build_item_socket() -> void:
	title_label.text = tr("%s - gniazdo %d") % [Items.name_of(item), index + 1]
	var current: String = item.sockets[index]
	_current_row(current, Gems.jewel_text(current, item.slot) if current != "" else "")
	var gems: Array = _game.gem_list("jewel")
	sub_label.text = tr("Kamienie szlachetne z sakwy - co dadzą w tym miejscu (%s)") \
			% Lang.t(Gems.GROUP_NAMES[Gems.SLOT_GROUPS[item.slot]])
	if gems.is_empty():
		_label(list, tr("Brak kamieni szlachetnych. Wypadają w lochach od poziomu %d.") % Gems.MIN_LEVEL, 12, DIM, true)
	for id in gems:
		var b := _row(id, Gems.icon_of(id), Gems.name_of(id), Gems.color_of(id), Gems.jewel_text(id, item.slot), "",
				tr("Wymień") if current != "" else tr("Włóż"))
		b.pressed.connect(func() -> void:
			if _game.socket_item(item, index, id):
				_done(PUT_SOUND))


## Kamień siedzący w gnieździe: opis i „Wyjmij” (za darmo, wraca do sakwy).
func _current_row(current: String, effect: String) -> void:
	if current == "":
		return
	var b := _row("out", Gems.icon_of(current), tr("W gnieździe: %s") % Gems.name_of(current), Gems.color_of(current),
			effect, "", tr("Wyjmij"))
	b.pressed.connect(func() -> void:
		var ok: bool = _game.unsocket_skill(skill, index) if mode == "skill_socket" else _game.unsocket_item(item, index)
		if ok:
			_done(PUT_SOUND))
	var sep := HSeparator.new()
	list.add_child(sep)


# --- najpierw kamień ---

func _build_gem() -> void:
	title_label.text = Gems.name_of(gem)
	title_label.add_theme_color_override("font_color", Gems.color_of(gem))
	sub_label.text = Gems.kind_line(gem) + "  ·  " + tr("Sztuk: %d") % _game.gem_count(gem)
	if gem == Gems.KEY:
		_build_key()
	elif gem == Gems.CHISEL:
		_build_chisel()
	elif Gems.is_support(gem):
		_label(list, Gems.description(gem)[0], 12, TEXT, true)
		_label(list, tr("Gdzie włożyć:"), 12, GOLD)
		var any := false
		for id in Skills.ORDER:
			if not _game.skills_owned.has(id):
				continue
			any = true
			var free: int = _game.free_skill_socket(id)
			var problem: String = _game.skill_socket_problem(id, free, gem) if free >= 0 else "full"
			var reason := tr("Brak wolnego gniazda (otwiera je Klucz Runiczny).") if problem == "full" \
					else tr("Ma już kamień tego rodzaju.") if problem == "same" \
					else tr("Pasuje tylko do: %s.") % Skills.name_of(Gems.unique_skill(gem)) if problem == "skill" else ""
			var b := _row(id, Skills.icon_of(id), Skills.name_of(id), GOLD, Gems.support_text(gem, id), reason, tr("Włóż"))
			b.disabled = problem != ""
			b.pressed.connect(func() -> void:
				if _game.socket_skill(id, _game.free_skill_socket(id), gem):
					_done(PUT_SOUND))
		if not any:
			_label(list, tr("Najpierw kup umiejętność przy kamieniu run w bazie."), 12, DIM, true)
	else:
		for line in Gems.jewel_lines(gem):
			_label(list, line, 12, TEXT, true)
		_label(list, tr("Gdzie włożyć:"), 12, GOLD)
		_item_rows(func(it: Dictionary) -> String: return "" if _game.free_item_socket(it) >= 0 \
				else tr("Brak wolnego gniazda (dorabia je Dłuto Jubilera)."),
				func(it: Dictionary) -> String: return Gems.jewel_text(gem, it.slot), tr("Włóż"),
				func(it: Dictionary) -> bool: return _game.socket_item(it, _game.free_item_socket(it), gem), PUT_SOUND)


## Klucz: umiejętności, które mają jeszcze zamknięte gniazda.
func _build_key() -> void:
	_label(list, Gems.description(gem)[0], 12, TEXT, true)
	var any := false
	for id in Skills.ORDER:
		if not _game.skills_owned.has(id):
			continue
		any = true
		var open: int = _game.skill_open_count(id)
		var full := open >= Gems.SKILL_SOCKETS
		var b := _row(id, Skills.icon_of(id), Skills.name_of(id), GOLD,
				tr("Otwarte gniazda: %d / %d") % [open, Gems.SKILL_SOCKETS], tr("Wszystkie gniazda otwarte.") if full else "",
				tr("Na pewno?") if armed == id else tr("Otwórz"))
		b.disabled = full
		b.pressed.connect(func() -> void:
			if armed != id:
				armed = id
				_build()
			elif _game.open_skill_socket(id):
				_done(GEM_SOUND))
	if not any:
		_label(list, tr("Najpierw kup umiejętność przy kamieniu run w bazie."), 12, DIM, true)


## Dłuto: przedmioty z jednym gniazdem.
func _build_chisel() -> void:
	_label(list, Gems.description(gem)[0], 12, TEXT, true)
	_item_rows(func(it: Dictionary) -> String: return tr("Ma już %d gniazda.") % Items.MAX_SOCKETS \
			if it.sockets.size() >= Items.MAX_SOCKETS else "",
			func(it: Dictionary) -> String: return tr("Gniazda: %d / %d") % [it.sockets.size(), Items.MAX_SOCKETS],
			"", func(it: Dictionary) -> bool: return _game.add_socket(it), GEM_SOUND, true)


## Wiersze przedmiotów (założone, potem torba): `reason_of` - czemu się nie da, `effect_of` - opis, `act` - akcja.
## `confirm` - akcja z potwierdzeniem drugim stuknięciem (napis przycisku „Dorób”).
func _item_rows(reason_of: Callable, effect_of: Callable, action_text: String, act: Callable, sound: AudioStream,
		confirm := false) -> void:
	var items: Array = _game.all_items()
	if items.is_empty():
		_label(list, tr("Brak przedmiotów."), 12, DIM, true)
	for k in items.size():
		var it: Dictionary = items[k]
		var key := "item_%d" % k
		var worn: bool = k < _game.equipped.size()  # all_items: najpierw założone
		var name := Items.name_of(it) + (" · " + tr("założony") if worn else "")
		var text := action_text
		if confirm:
			text = tr("Na pewno?") if armed == key else tr("Dorób")
		var reason: String = reason_of.call(it)
		var b := _row(key, Items.icon_of(it), name, Items.color_of(it), effect_of.call(it), reason, text)
		b.disabled = reason != ""
		b.pressed.connect(func() -> void:
			if confirm and armed != key:
				armed = key
				_build()
			elif act.call(it):
				_done(sound))


# --- wiersze ---

## Wiersz: ikona, nazwa w kolorze, opis działania, powód (czerwony - wtedy wiersz przygaszony) i przycisk akcji.
func _row(key: String, icon: Texture2D, title: String, color: Color, effect: String, reason: String,
		action_text: String) -> Button:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.16, 0.11, 0.08)
	st.border_color = color.darkened(0.35)
	st.set_border_width_all(1)
	st.set_corner_radius_all(4)
	st.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", st)
	list.add_child(panel)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(36, 36)
	tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(tex)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	box.add_child(col)
	_label(col, title, 13, color, true)
	if effect != "":
		_label(col, effect, 11, TEXT, true)
	if reason != "":
		_label(col, reason, 11, RED, true)
		tex.modulate = Color(1, 1, 1, 0.45)
	var b := Button.new()
	b.text = action_text
	b.custom_minimum_size = Vector2(78, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 13)
	b.clip_text = true
	box.add_child(b)
	actions[key] = b
	return b


func _done(sound: AudioStream) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = sound
	audio.volume_db = -8.0
	get_parent().add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	changed.emit()
	close()


func _label(parent: Control, text: String, font_size: int, color: Color, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

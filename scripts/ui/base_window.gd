class_name BaseWindow
extends Control
## Wspólny szkielet okien budynków w bazie (ulepszenia lochów przy Watrze, kowal, kupiec): przyciemnione tło,
## panel na cały ekran (z marginesem), u góry tytuł i waluta (ikona + liczba - `set_currency`), w środku przewijana
## treść (`content`), na dole przycisk „Wróć” (pod kciukiem). Zatrzymuje grę, gdy jest otwarte (PROCESS_MODE_ALWAYS).
## Kupno z potwierdzeniem: pierwsze stuknięcie przycisku z ceną pyta („Na pewno?”), drugie kupuje (`confirm`).
## Okno pochodne buduje treść w `_build` i odświeża ją w `refresh` (też po każdym Game.inventory_changed).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const DIM := Color(1, 0.85, 0.6, 0.8)
const COIN := preload("res://assets/watra/items/coin.png")
const EMBER := preload("res://assets/watra/ember_icon.png")

var title_label: Label
var currency_icon: TextureRect
var currency_label: Label
## Treść okna (w przewijanym obszarze) i dolny rząd przycisków.
var content: VBoxContainer
var footer: HBoxContainer
var scroll: ScrollContainer
var back_button: Button
## Który przycisk czeka na drugie stuknięcie (klucz nadaje okno pochodne; "" - żaden).
var armed := ""
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
	panel.add_theme_stylebox_override("panel", panel_style(10))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	title_label = label(head, "", 18, GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	currency_icon = TextureRect.new()
	currency_icon.texture = COIN
	currency_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	currency_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	currency_icon.custom_minimum_size = Vector2(18, 18)
	head.add_child(currency_icon)
	currency_label = label(head, "0", 15, GOLD)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	back_button = button(footer, tr("Wróć"))
	back_button.pressed.connect(close)
	_build()
	_game.inventory_changed.connect(_on_changed)
	_game.embers_changed.connect(_on_changed)


## Treść okna (okno pochodne).
func _build() -> void:
	pass


## Odświeżenie treści (okno pochodne).
func refresh() -> void:
	pass


func _on_changed() -> void:
	if visible:
		refresh()


## Otwiera okno i zatrzymuje grę.
func open() -> void:
	armed = ""
	refresh()
	scroll.scroll_vertical = 0
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


## Przycisk „wstecz” na Androidzie (okno pochodne może najpierw zamknąć np. opis przedmiotu).
func back() -> void:
	close()


## Waluta w nagłówku: ikona (złoto albo żar) i liczba.
func set_currency(icon: Texture2D, amount: int) -> void:
	currency_icon.texture = icon
	currency_label.text = str(amount)


## Kupno z potwierdzeniem: pierwsze stuknięcie uzbraja przycisk `key` (zwraca false i odświeża okno - przycisk
## pyta „Na pewno?”), drugie zwraca true.
func confirm(key: String) -> bool:
	if armed != key:
		armed = key
		refresh()
		return false
	armed = ""
	return true


## Przycisk z ceną (ikona waluty); uzbrojony pyta o potwierdzenie (bez ceny - nie zmieściłaby się).
func price_button(parent: Control, key: String, price: int, icon: Texture2D, can_pay: bool) -> Button:
	var b := button(parent, tr("Na pewno?") if armed == key else str(price))
	b.icon = null if armed == key else icon
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 16)
	b.custom_minimum_size = Vector2(96, 48)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not can_pay
	if armed == key:
		b.add_theme_color_override("font_color", GOLD)
	return b


## Rząd z ikoną po lewej i kolumną tekstu (zwraca kolumnę; ramka w kolorze `border`).
func row(icon: Texture2D, border: Color) -> HBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(40, 40)
	tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(tex)
	return box


## Kolumna tekstu w rzędzie (rozciąga się, tekst się zawija).
func text_column(parent: Control) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	parent.add_child(col)
	return col


func clear_content() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()


func button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	b.clip_text = true
	parent.add_child(b)
	return b


func label(parent: Control, text: String, font_size: int, color: Color, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


static func panel_style(margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.06, 0.97)
	style.border_color = Color(0.85, 0.62, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(margin)
	return style


func play(stream: AudioStream, volume := -6.0) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

class_name GemSlot
extends Button
## Pole kamienia (Gems) w oknach umiejętności i „Postać”: ikona kamienia w okrągłym gnieździe z Watry.
## `area` - "pouch" (kamień w sakwie, w rogu liczba sztuk) albo "socket" (gniazdo umiejętności lub przedmiotu,
## `index` - które). Stuknięcie - sygnał `pressed`. Przeciągnięcie palcem kamienia z sakwy na gniazdo - sygnał
## `dropped` na gnieździe; przeciągnięcie z gniazda na sakwę - `dropped` na polu sakwy (wyjęcie). Zamknięte
## gniazdo (`locked`) pokazuje kłódkę z kluczem i nic na nie nie wpada.

## Na to pole upuszczono kamień `gem` przeciągnięty z pola `from_area` / `from_index`.
signal dropped(gem: String, from_area: String, from_index: int)

const FRAME := Color(0.45, 0.35, 0.25)
const GOLD := Color(1.0, 0.78, 0.35)
const KEY_ICON := preload("res://assets/watra/gems/rune_ascend.png")

var area := "socket"
var index := 0
## Kamień w polu ("" - puste gniazdo).
var gem := ""
var count := 0
var locked := false
var _styles := {}
var _count_label: Label
var _socket: TextureRect


func _init(size_px := 44.0) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width", int(size_px) - 12)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.11, 0.08) if state != "pressed" else Color(0.26, 0.18, 0.12)
		st.border_color = FRAME
		st.set_border_width_all(2)
		st.set_corner_radius_all(int(size_px / 2.0))
		st.set_content_margin_all(5)
		add_theme_stylebox_override(state, st)
		_styles[state] = st
	_socket = TextureRect.new()
	_socket.texture = Gems.SOCKET_ICON
	_socket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_socket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_socket.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_socket.show_behind_parent = true
	add_child(_socket)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 10)
	_count_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_count_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.03))
	_count_label.add_theme_constant_override("outline_size", 3)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_count_label.offset_right = -3
	_count_label.offset_bottom = 1
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)


## Pokazuje kamień (albo puste / zamknięte gniazdo). `selected` - złota ramka.
func show_gem(id: String, amount := 0, selected := false, is_locked := false) -> void:
	gem = id
	count = amount
	locked = is_locked
	icon = KEY_ICON if locked else (Gems.icon_of(id) if id != "" else null)
	modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
	_socket.visible = area == "socket" and not locked
	_count_label.text = str(amount) if area == "pouch" and amount > 1 else ""
	for state in _styles:
		var st: StyleBoxFlat = _styles[state]
		st.border_color = GOLD if selected else (Gems.color_of(id).darkened(0.3) if id != "" else FRAME)
		st.set_border_width_all(3 if selected else 2)


func _get_drag_data(_at: Vector2) -> Variant:
	if gem == "" or locked or Gems.is_special(gem):
		return null
	var preview := TextureRect.new()
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = custom_minimum_size
	preview.position = -custom_minimum_size / 2.0
	preview.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()  # podgląd pod palcem, wyśrodkowany
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"gem_slot": true, "gem": gem, "area": area, "index": index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("gem_slot", false)):
		return false
	if area == "pouch":
		return data.area == "socket"  # z gniazda do sakwy - wyjęcie
	return not locked and not (data.area == area and data.index == index)


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data.gem, data.area, data.index)

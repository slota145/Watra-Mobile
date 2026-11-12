class_name ItemSlot
extends Button
## Pole na przedmiot w oknie skrzyni: ikona i ramka w kolorze rzadkości. Stuknięcie - sygnał `pressed` (opis
## przedmiotu), przeciągnięcie palcem na pole innej siatki - sygnał `dropped` na polu docelowym (przeniesienie
## między torbą a skrzynią). `area` mówi, do której siatki należy pole ("bag" albo "stash"), `index` - które to pole.

## Na to pole upuszczono przedmiot przeciągnięty z innej siatki.
signal dropped(from_area: String, from_index: int)

var area := ""
var index := 0
## Przedmiot w polu (pusty słownik - pole puste).
var item: Dictionary = {}


func _init(size_px := 48.0) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width", int(size_px) - 8)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.11, 0.08) if state != "pressed" else Color(0.26, 0.18, 0.12)
		st.set_border_width_all(2)
		st.set_corner_radius_all(4)
		st.set_content_margin_all(3)
		add_theme_stylebox_override(state, st)


## Pokazuje przedmiot (albo puste pole).
func show_item(new_item: Dictionary) -> void:
	item = new_item
	icon = Items.icon_of(item) if not item.is_empty() else null
	var color := Color(0.45, 0.35, 0.25)
	if not item.is_empty():
		color = Items.color_of(item) if item.rarity != "common" else Color(0.7, 0.6, 0.45)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st: StyleBoxFlat = get_theme_stylebox(state)
		st.border_color = color if state != "pressed" else color.lightened(0.3)


func _get_drag_data(_at: Vector2) -> Variant:
	if item.is_empty():
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
	return {"item_slot": true, "area": area, "index": index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("item_slot", false) and data.area != area


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data.area, data.index)

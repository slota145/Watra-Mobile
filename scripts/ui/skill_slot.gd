class_name SkillSlot
extends Button
## Pole umiejętności w oknie umiejętności (SkillsWindow): ikona umiejętności w ramce. `area` - "slot" (miejsce
## na przycisku walki, `index` 0 - duży przycisk ataku, 1-4 - małe) albo "list" (ikona na liście umiejętności).
## Stuknięcie - sygnał `pressed`. Przeciągnięcie palcem kupionej umiejętności na miejsce - sygnał `dropped`
## na polu docelowym; przeciągnięcie z miejsca na listę zdejmuje umiejętność z miejsca. Zablokowane miejsce
## (`locked_level`) pokazuje poziom, na którym się odblokuje, i nic na nie nie wpada.

## Na to pole upuszczono umiejętność `skill` przeciągniętą z pola `from_area` / `from_index`.
signal dropped(skill: String, from_area: String, from_index: int)

const FRAME := Color(0.45, 0.35, 0.25)
const GOLD := Color(1.0, 0.78, 0.35)

var area := "slot"
var index := 0
## Umiejętność w polu ("" - puste).
var skill := ""
## Czy umiejętność można przeciągać (na liście - tylko kupione).
var draggable := true
var locked_level := 0
var _styles := {}


func _init(size_px := 48.0) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width", int(size_px) - 8)
	add_theme_font_size_override("font_size", 10)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.11, 0.08) if state != "pressed" else Color(0.26, 0.18, 0.12)
		st.border_color = FRAME
		st.set_border_width_all(2)
		st.set_corner_radius_all(6)
		st.set_content_margin_all(3)
		add_theme_stylebox_override(state, st)
		_styles[state] = st


## Pokazuje umiejętność (albo puste / zablokowane miejsce). `selected` - złota ramka (wybrane pole).
func show_skill(id: String, locked := 0, selected := false) -> void:
	skill = id
	locked_level = locked
	icon = Skills.icon_of(id) if id != "" and locked == 0 else null
	text = tr("Poz. %d") % locked if locked > 0 else ("+" if id == "" and area == "slot" else "")
	modulate = Color(1, 1, 1, 0.55) if locked > 0 else Color.WHITE
	for state in _styles:
		var st: StyleBoxFlat = _styles[state]
		st.border_color = GOLD if selected else (GOLD.darkened(0.35) if index == 0 and area == "slot" else FRAME)
		st.set_border_width_all(3 if selected else 2)


func _get_drag_data(_at: Vector2) -> Variant:
	if skill == "" or not draggable or locked_level > 0:
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
	return {"skill_slot": true, "skill": skill, "area": area, "index": index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("skill_slot", false)):
		return false
	if area == "list":
		return data.area == "slot"  # z miejsca na listę - zdjęcie z miejsca
	return locked_level == 0 and not (data.area == area and data.index == index) \
			and (index != Skills.MAIN or Skills.can_be_main(data.skill))


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data.skill, data.area, data.index)

class_name ZertwaOffer
extends Control
## Wybór nagrody za Krąg Żertwy (DungeonGoals.zertwa_offer): przyciemniony ekran, tytuł i trzy duże przyciski
## w dolnej połowie (pod kciukiem) - rzadki przedmiot, kamień albo żar; każdy z ikoną i nazwą w kolorze rzadkości.
## Gra stoi, dopóki gracz nie wybierze (PROCESS_MODE_ALWAYS; pauzę włącza i zdejmuje arena). Sygnał `chosen` z wyborem.

signal chosen(reward: Dictionary)

const EMBER_ICON := preload("res://assets/watra/ember_icon.png")

var _list: VBoxContainer
var _rewards: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.0, 0.0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var title := Label.new()
	title.text = tr("Danina złożona!")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 6)
	column.add_child(title)
	var sub := Label.new()
	sub.text = tr("Wybierz dar Kręgu Żertwy")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(1, 0.88, 0.78))
	sub.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	sub.add_theme_constant_override("outline_size", 4)
	column.add_child(sub)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_list)
	var bottom := Control.new()  # nad przyciskami walki i paskiem gestów
	bottom.custom_minimum_size = Vector2(0, 90)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)


## Pokazuje nagrody do wyboru (słowniki: {"item": przedmiot albo {"gem": id}} lub {"embers": ile}).
func open(rewards: Array[Dictionary]) -> void:
	_rewards = rewards
	for c in _list.get_children():
		c.queue_free()
	for r in rewards:
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 60)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.expand_icon = false
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_constant_override("icon_max_width", 36)
		if r.has("embers"):
			b.icon = EMBER_ICON
			b.text = tr("Żar: +%d") % int(r["embers"])
			b.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
		else:
			var item: Dictionary = r["item"]
			b.icon = ProtoLoot.icon_of(item)
			b.text = ProtoLoot.name_of(item)
			b.add_theme_color_override("font_color", ProtoLoot.color_of(item))
		b.pressed.connect(_choose.bind(r))
		_list.add_child(b)
	visible = true


func _choose(reward: Dictionary) -> void:
	visible = false
	chosen.emit(reward)

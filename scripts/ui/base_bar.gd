class_name BaseBar
extends Control
## Pasek skrótów w bazie (ustalone z autorem 12.11.2026): ikony w dwóch kolumnach przy dolnej krawędzi, po drugiej
## stronie niż przyciski walki (`left_handed` - po prawej). Każda ikona z podpisem otwiera okno budynku od razu,
## bez podchodzenia postacią (sygnał `chosen` z identyfikatorem): Watra (wybór poziomu i drzewko lochów),
## Skrzynia, Umiejętności (kamień run), Kowal, Kupiec, Targ (rynek), Głębiny (Czarna Watra - widoczne dopiero po ich
## otwarciu: arena ustawia `deep_open`).

signal chosen(id: String)

const BUTTON := Vector2(54, 54)
## Identyfikator, podpis, ikona.
const ENTRIES := [
	["watra", "Watra", "res://assets/watra/base/status_watra.png"],
	["stash", "Skrzynia", "res://assets/watra/chest.png"],
	["skills", "Umiejętności", "res://assets/watra/rune_stone.png"],
	["smith", "Kowal", "res://assets/watra/base/reforge.png"],
	["shop", "Kupiec", "res://assets/watra/base/tax_pouch.png"],
	["market", "Targ", "res://assets/watra/base/market_stall.png"],
	["deep", "Głębiny", "res://assets/watra/base/status_watra.png"],
]

var buttons := {}
## Czy Głębiny są otwarte (przycisk „Głębiny” widoczny).
var deep_open := false:
	set(value):
		deep_open = value
		if buttons.has("deep"):
			buttons.deep.visible = value
			_layout()
var column: GridContainer
var left_handed := false:
	set(value):
		left_handed = value
		if is_node_ready():
			_layout()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column = GridContainer.new()  # 2 kolumny po 3 ikony - 6 ikon mieści się w dolnej połowie ekranu 16:9
	column.columns = 2
	column.add_theme_constant_override("h_separation", 3)
	column.add_theme_constant_override("v_separation", 3)
	add_child(column)
	for e in ENTRIES:
		var b := Button.new()
		b.name = e[0]
		b.custom_minimum_size = BUTTON
		b.icon = load(e[2])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 30)
		b.text = tr(e[1])
		b.add_theme_font_size_override("font_size", 9)
		b.add_theme_color_override("font_color", Color(1, 0.88, 0.6))
		b.add_theme_constant_override("h_separation", 0)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.1, 0.07, 0.05, 0.78)
		st.border_color = Color(0.7, 0.5, 0.25, 0.9)
		st.set_border_width_all(1)
		st.set_corner_radius_all(6)
		st.set_content_margin_all(2)
		b.add_theme_stylebox_override("normal", st)
		var pressed_st := st.duplicate()
		pressed_st.bg_color = Color(0.3, 0.18, 0.08, 0.9)
		b.add_theme_stylebox_override("pressed", pressed_st)
		b.add_theme_stylebox_override("hover", st)
		b.pressed.connect(func() -> void: chosen.emit(e[0]))
		if e[0] == "deep":  # Czarna Watra: fioletowa ikona ognia
			b.self_modulate = Color(0.85, 0.65, 1.0)
			b.visible = deep_open
		column.add_child(b)
		buttons[e[0]] = b
	_layout()
	resized.connect(_layout)


## Ikony w lewym dolnym rogu (albo prawym dla leworęcznych).
func _layout() -> void:
	var h := column.get_combined_minimum_size()
	column.size = h
	column.position = Vector2(size.x - h.x if left_handed else 0.0, size.y - h.y)

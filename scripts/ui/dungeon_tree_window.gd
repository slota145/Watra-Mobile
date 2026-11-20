class_name DungeonTreeWindow
extends BaseWindow
## Okno drzewka lochów (DungeonTree, stan w Game.tree; ustalone z autorem 20.11.2026 - rysowane drzewko jak atlas PoE):
## w środku Watra, od niej gałęzie do węzłów (przyciski 48 px z ikoną i liczbą punktów pod spodem). Drzewko przesuwa się
## palcem (`_TreeView`), a układ zmniejsza się, gdy ekran jest wąski. Stuknięcie węzła pokazuje na dole (pod kciukiem)
## jego nazwę, punkty, obecną i następną premię oraz przyciski „−” i „+” (cofanie za darmo). „Od nowa” oddaje wszystkie
## punkty (drugie stuknięcie potwierdza). W nagłówku wolne punkty (1 za każdy przebity poziom lochu).
## Otwiera je przycisk „Drzewko” w wyborze poziomu przy Watrze (zastąpiło okno ulepszeń lochów za złoto).

const ADD_SOUND := preload("res://assets/watra/ember_pickup_big.ogg")
const WATRA_ICON := preload("res://assets/watra/base/status_watra.png")
const NODE_SIZE := 48.0
const GREEN := Color(0.55, 0.95, 0.5)
const LOCKED := Color(0.45, 0.42, 0.4)

var view: _TreeView
var node_buttons := {}
var point_labels := {}
var selected := ""
var detail_name: Label
var detail_points: Label
var detail_now: Label
var detail_next: Label
var minus_button: Button
var plus_button: Button
var reset_button: Button
var hint_label: Label


func _build() -> void:
	title_label.text = tr("Drzewko lochów")
	currency_icon.texture = WATRA_ICON
	scroll.visible = false
	var column := scroll.get_parent()
	view = _TreeView.new()
	view.window = self
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.custom_minimum_size = Vector2(0, 260)
	column.add_child(view)
	column.move_child(view, scroll.get_index())
	for id: String in DungeonTree.ORDER:
		var b := Button.new()
		b.name = "Node_" + id
		b.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
		b.size = Vector2(NODE_SIZE, NODE_SIZE)
		b.icon = DungeonTree.icon_of(id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 34)
		b.mouse_filter = Control.MOUSE_FILTER_PASS  # przeciągnięcie po węźle przesuwa drzewko
		b.pressed.connect(_select.bind(id))
		view.add_child(b)
		node_buttons[id] = b
		var pts := Label.new()
		pts.add_theme_font_size_override("font_size", 11)
		pts.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		pts.add_theme_constant_override("outline_size", 3)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pts.size = Vector2(NODE_SIZE + 20, 14)
		pts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.add_child(pts)
		point_labels[id] = pts
	# opis wybranego węzła - nad przyciskami, pod kciukiem
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", panel_style(6))
	column.add_child(detail)
	column.move_child(detail, footer.get_index())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	detail.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	detail_name = label(col, "", 15, GOLD)
	detail_points = label(col, "", 12, TEXT)
	detail_now = label(col, "", 12, GREEN, true)
	detail_next = label(col, "", 12, Color(1, 0.7, 0.35), true)
	minus_button = button(row, "−")
	minus_button.custom_minimum_size = Vector2(48, 48)
	minus_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	minus_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	minus_button.add_theme_font_size_override("font_size", 22)
	minus_button.pressed.connect(_remove)
	plus_button = button(row, "+")
	plus_button.custom_minimum_size = Vector2(48, 48)
	plus_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	plus_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plus_button.add_theme_font_size_override("font_size", 22)
	plus_button.pressed.connect(_add)
	hint_label = label(column, "", 11, DIM, true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.move_child(hint_label, footer.get_index())
	reset_button = button(footer, tr("Od nowa"))
	footer.move_child(reset_button, 0)
	reset_button.pressed.connect(_reset)
	selected = DungeonTree.ORDER[0]


func open() -> void:
	super.open()
	view.center()


func refresh() -> void:
	set_currency(WATRA_ICON, _game.tree_free())
	for id: String in DungeonTree.ORDER:
		var b: Button = node_buttons[id]
		var pts: int = _game.tree_points(id)
		var most := DungeonTree.max_of(id)
		var open_node: bool = DungeonTree.parent_of(id) == "" or _game.tree_points(DungeonTree.parent_of(id)) > 0
		var border := LOCKED
		if pts >= most:
			border = GOLD
		elif pts > 0:
			border = GREEN
		elif open_node:
			border = TEXT
		_node_style(b, border, id == selected)
		b.modulate = Color.WHITE if open_node else Color(0.55, 0.55, 0.55)
		var lbl: Label = point_labels[id]
		lbl.text = "%d/%d" % [pts, most]
		lbl.add_theme_color_override("font_color", border)
	_show_detail()
	reset_button.text = tr("Na pewno?") if armed == "reset" else tr("Od nowa")
	view.queue_redraw()


func _node_style(b: Button, border: Color, chosen: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.2, 0.13, 0.08) if chosen else Color(0.12, 0.08, 0.06)
		st.border_color = border
		st.set_border_width_all(3 if chosen else 2)
		st.set_corner_radius_all(24)
		b.add_theme_stylebox_override(state, st)


func _show_detail() -> void:
	var id := selected
	var pts: int = _game.tree_points(id)
	var most := DungeonTree.max_of(id)
	detail_name.text = DungeonTree.name_of(id)
	detail_points.text = tr("Punkty: %d/%d") % [pts, most]
	detail_now.text = DungeonTree.text(id, pts) if pts > 0 else tr("Jeszcze bez punktów")
	detail_next.visible = pts < most
	detail_next.text = tr("Następny punkt: %s") % DungeonTree.text(id, pts + 1)
	var problem: String = _game.tree_add_problem(id)
	plus_button.disabled = problem != ""
	minus_button.disabled = pts <= 0
	if problem == "locked":
		hint_label.text = tr("Najpierw daj punkt w: %s.") % DungeonTree.name_of(DungeonTree.parent_of(id))
	elif problem == "points" and pts < most:
		hint_label.text = tr("Brak wolnych punktów - punkt za każdy nowy przebity poziom lochu.")
	else:
		hint_label.text = tr("Stuknij węzeł, żeby zobaczyć, co daje. Punkty cofasz za darmo.")


func _select(id: String) -> void:
	selected = id
	armed = ""
	refresh()


func _add() -> void:
	if _game.tree_add(selected):
		play(ADD_SOUND, -10.0)
	armed = ""
	refresh()


func _remove() -> void:
	_game.tree_remove(selected)
	armed = ""
	refresh()


func _reset() -> void:
	if DungeonTree.spent(_game.tree) == 0:
		return
	if not confirm("reset"):
		refresh()
		return
	_game.tree_reset()
	refresh()


## Pole drzewka: rysuje Watrę i gałęzie, układa węzły (środek widoku + `pan`, skala `fit` na wąskim ekranie)
## i przesuwa się palcem (przeciągnięcie - także po węźle, bo węzły przepuszczają przeciąganie).
class _TreeView extends Control:
	var window: DungeonTreeWindow
	var pan := Vector2.ZERO
	var fit := 1.0
	var _dragged := 0.0

	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_layout)

	func center() -> void:
		pan = Vector2.ZERO
		_layout()

	## Skala tak, żeby najdalszy węzeł mieścił się w szerokości (z miejscem na przycisk), i rozstawienie węzłów.
	func _layout() -> void:
		var reach := 0.0
		var reach_y := 0.0
		for id: String in DungeonTree.ORDER:
			reach = maxf(reach, absf(DungeonTree.pos_of(id).x))
			reach_y = maxf(reach_y, absf(DungeonTree.pos_of(id).y))
		var half := size * 0.5 - Vector2(DungeonTreeWindow.NODE_SIZE * 0.5 + 8.0, DungeonTreeWindow.NODE_SIZE * 0.5 + 14.0)
		fit = clampf(minf(half.x / maxf(reach, 1.0), half.y / maxf(reach_y, 1.0)), 0.6, 1.0)
		for id: String in DungeonTree.ORDER:
			var at := _spot(id)
			var b: Button = window.node_buttons[id]
			b.position = at - b.size * 0.5
			var lbl: Label = window.point_labels[id]
			lbl.position = at + Vector2(-lbl.size.x * 0.5, DungeonTreeWindow.NODE_SIZE * 0.5 - 2.0)
		queue_redraw()

	func _spot(id: String) -> Vector2:
		return size * 0.5 + pan + DungeonTree.pos_of(id) * fit

	func _gui_input(event: InputEvent) -> void:
		var motion := event as InputEventMouseMotion
		if motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			pan += motion.relative
			var limit := Vector2(220, 220)
			pan = pan.clamp(-limit, limit)
			_layout()
			accept_event()

	func _draw() -> void:
		var mid := size * 0.5 + pan
		for id: String in DungeonTree.ORDER:
			var parent := DungeonTree.parent_of(id)
			var from := mid if parent == "" else _spot(parent)
			var lit: bool = window._game.tree_points(id) > 0
			draw_line(from, _spot(id), Color(1.0, 0.65, 0.3, 0.85) if lit else Color(0.5, 0.42, 0.35, 0.6),
					3.0 if lit else 2.0)
		draw_circle(mid, 26.0, Color(1.0, 0.55, 0.2, 0.18))
		draw_circle(mid, 18.0, Color(0.12, 0.08, 0.06))
		draw_arc(mid, 18.0, 0.0, TAU, 32, Color(1.0, 0.7, 0.35), 2.0)
		var tex := DungeonTreeWindow.WATRA_ICON
		draw_texture_rect(tex, Rect2(mid - Vector2(14, 14), Vector2(28, 28)), false)

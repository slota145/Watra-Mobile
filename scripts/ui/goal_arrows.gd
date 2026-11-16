class_name GoalArrows
extends Control
## Strzałki przy krawędzi ekranu do celów na mapie lochu (DungeonGoals), które są poza kadrem: kółko z ikonką celu
## (skrzynia, kapliczka) i trójkąt wskazujący kierunek, lekko pulsujące. Cel w kadrze nie ma strzałki - widać go
## po słupie światła. Cele to węzły z grupy GROUP z `goal_active()`, `goal_icon` i `goal_color`.
## Strzałki omijają górny pasek interfejsu (`avoid_top` - jego dół to górna granica). Nie łapią dotyku.

const GROUP := "dungeon_goal"
const RADIUS := 15.0
const MARGIN := 6.0
## Cel liczy się jako widoczny, gdy jego środek jest tyle pikseli w głąb ekranu.
const INSIDE := 12.0

## Górny pasek (pasek zdrowia i żaru) - strzałki stają pod nim.
var avoid_top: Control
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Położenia strzałek (w pikselach tej kontrolki) i ich cele - też do testów.
func arrows() -> Array:
	var out: Array = []
	var screen := get_viewport_rect().size
	var canvas := get_viewport().get_canvas_transform()
	var top := 0.0
	if avoid_top and avoid_top.is_visible_in_tree():
		top = avoid_top.get_global_rect().end.y - global_position.y
	var area := Rect2(Vector2(0, top), size - Vector2(0, top)).grow(-(RADIUS + MARGIN))
	for goal in get_tree().get_nodes_in_group(GROUP):
		if not goal.goal_active():
			continue
		var on_screen: Vector2 = canvas * (goal.global_position + Vector2(0, -12))
		if Rect2(Vector2.ZERO, screen).grow(-INSIDE).has_point(on_screen):
			continue
		var local := on_screen - global_position
		var center := area.get_center()
		var dir := local - center
		if dir.length() < 1.0:
			continue
		var half := area.size / 2.0
		var t := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		out.append({"goal": goal, "at": center + dir * minf(t, 1.0), "dir": dir.normalized()})
	return out


func _draw() -> void:
	var pulse := 1.0 + 0.08 * sin(_time * 6.0)
	for a: Dictionary in arrows():
		var at: Vector2 = a["at"]
		var dir: Vector2 = a["dir"]
		var color: Color = a["goal"].goal_color
		var r := RADIUS * pulse
		# trójkąt na zewnątrz kółka, w stronę celu
		var tip := at + dir * (r + 7.0)
		var side := dir.orthogonal() * 6.0
		var base := at + dir * (r - 1.0)
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
		draw_circle(at, r + 1.5, Color(0.05, 0.03, 0.02, 0.85))
		draw_arc(at, r, 0.0, TAU, 28, color, 2.0)
		var icon: Texture2D = a["goal"].goal_icon
		if icon:
			var s := 20.0 / maxf(icon.get_width(), icon.get_height())
			var isize := Vector2(icon.get_width(), icon.get_height()) * s
			draw_texture_rect(icon, Rect2(at - isize / 2.0, isize), false)

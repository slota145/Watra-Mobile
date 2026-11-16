class_name GoalBeam
extends Node2D
## Słup światła nad celem na mapie lochu (DungeonGoals): pionowa smuga w kolorze celu, rozjaśniająca się
## u podstawy i pulsująca - widać ją przez tłum potworów. Rysowana w kodzie (wielokąt z kolorami wierzchołków,
## mieszanie addytywne), bez grafik. Tu też wspólne kółko postępu „stań przy celu” (`draw_ring`).

const HEIGHT := 150.0
const WIDTH := 14.0

var color := Color(1.0, 0.8, 0.4)
var _time := randf() * 10.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 5


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * 3.0)
	var base := Color(color, 0.55 * pulse)
	var top := Color(color, 0.0)
	var w := WIDTH * (0.9 + 0.1 * sin(_time * 5.0))
	draw_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.4, -HEIGHT), Vector2(-w * 0.4, -HEIGHT)]),
			PackedColorArray([base, base, top, top]))
	# jaśniejszy rdzeń i plama na ziemi
	var core := Color(color.lightened(0.5), 0.5 * pulse)
	draw_polygon(PackedVector2Array([Vector2(-w * 0.3, 0), Vector2(w * 0.3, 0), Vector2(0, -HEIGHT * 0.8)]),
			PackedColorArray([core, core, Color(core, 0.0)]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, w * 1.8, Color(color, 0.25 * pulse))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Gaśnie i znika.
func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


## Kółko na ziemi wokół celu: ciemny pierścień i jasny łuk postępu (0-1). Spłaszczone jak cień (widok z ukosa).
static func draw_ring(canvas: CanvasItem, progress: float, radius: float, ring_color: Color) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	canvas.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0, 0, 0, 0.45), 4.0)
	canvas.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(ring_color, 0.35), 1.5)
	if progress > 0.0:
		canvas.draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * clampf(progress, 0.0, 1.0), 40,
				ring_color.lightened(0.3), 3.0)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

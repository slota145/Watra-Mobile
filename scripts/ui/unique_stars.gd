class_name UniqueStars
extends Control
## Gwiazdki poziomu unikatu (Items.unique_level): pełne do poziomu, puste kontury do Items.UNIQUE_MAX_LEVEL.
## Rysowane wielokątami (bez znaku ★ w czcionce). Opis przedmiotu w oknie „Postać”, pole torby, przedmiot na ziemi.
## `compact` - tylko pełne gwiazdki ponad 1. poziom (pole torby i ziemia, gdzie mało miejsca).

const FULL := Color(1.0, 0.82, 0.3)
const EMPTY := Color(0.55, 0.45, 0.3, 0.8)
const OUTLINE := Color(0.15, 0.08, 0.03)

var level := 1:
	set(v):
		level = v
		_resize()
		queue_redraw()
## Średnica jednej gwiazdki w pikselach gry.
var star := 10.0:
	set(v):
		star = v
		_resize()
		queue_redraw()
var compact := false:
	set(v):
		compact = v
		_resize()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Ile gwiazdek widać.
func count() -> int:
	return maxi(level - 1, 0) if compact else Items.UNIQUE_MAX_LEVEL


func _resize() -> void:
	custom_minimum_size = Vector2(count() * (star + 1.0), star)
	size = custom_minimum_size


func _draw() -> void:
	for i in count():
		var filled := compact or i < level
		var c := Vector2(i * (star + 1.0) + star / 2.0, star / 2.0)
		var pts := _points(c, star / 2.0)
		if filled:
			draw_colored_polygon(pts, FULL)
		pts.append(pts[0])
		draw_polyline(pts, OUTLINE if filled else EMPTY, 1.0)


static func _points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var radius := r if k % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	return pts

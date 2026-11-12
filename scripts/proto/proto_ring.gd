class_name ProtoRing
extends Node2D
## Rozchodzący się pierścień na ziemi (spłaszczony jak cienie): fale okrzyku Wodza, kurz po uderzeniu.
## Po `delay` s rośnie do `max_radius` przez `duration` s, gaśnie i sam znika.

var color := Color(1, 0.6, 0.2, 0.8)
var max_radius := 40.0
var duration := 0.5
var delay := 0.0

var _time := 0.0


func _ready() -> void:
	z_index = -1
	scale = Vector2(1.0, ProtoTelegraph.SQUASH)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time > delay + duration:
		queue_free()


func _draw() -> void:
	var k := (_time - delay) / duration
	if k <= 0.0:
		return
	var c := Color(color, color.a * (1.0 - k))
	draw_arc(Vector2.ZERO, max_radius * k, 0.0, TAU, 40, c, 2.0)

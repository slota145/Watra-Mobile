class_name ProtoArrow
extends Node2D
## Strzała goblina łucznika: leci prosto (wolno, żeby dało się ją wyminąć kciukiem) na wysokości `HEIGHT` nad ziemią,
## z cieniem pod spodem. Trafia Wojciecha, gdy zbliży się do jego stóp na `HIT_RADIUS`, i wtedy znika z iskrą;
## po przeleceniu `RANGE` pikseli opada i gaśnie. Rysowana kodem (drzewce, grot, czerwone lotki), bez grafiki.
## Węzeł stoi w punkcie na ziemi pod strzałą, więc sortowanie po Y działa jak u postaci.

## Prędkość (Wojciech: 70 px/s) - strzała z odległości 120 px leci ok. 1 s, w tym czasie da się zejść z linii.
const SPEED := 115.0
const RANGE := 240.0
## Wysokość lotu nad ziemią (px) i promień trafienia (odległość od stóp postaci).
const HEIGHT := 11.0
const HIT_RADIUS := 8.0
const SHAFT := Color(0.55, 0.38, 0.22)
const HEAD := Color(0.82, 0.8, 0.76)
const FLETCH := Color(0.75, 0.16, 0.12)
const OUTLINE := Color(0.1, 0.06, 0.05)

var hero: ProtoHero
var direction := Vector2.RIGHT
var damage := 8

var _flown := 0.0
var _done := false
var _height := HEIGHT


func _process(delta: float) -> void:
	if _done:
		return
	var step := SPEED * delta
	position += direction * step
	_flown += step
	if hero and not hero.dead and global_position.distance_to(hero.global_position) <= HIT_RADIUS:
		hero.take_damage(damage)
		_finish(true)
		return
	if _flown >= RANGE:
		_finish(false)


## Koniec lotu: przy trafieniu krótki błysk, przy chybieniu strzała opada na ziemię i gaśnie.
func _finish(hit: bool) -> void:
	_done = true
	var tween := create_tween()
	if hit:
		modulate = Color(2.5, 2.0, 1.6)
		tween.tween_property(self, "modulate:a", 0.0, 0.12)
	else:
		tween.tween_method(_set_height, HEIGHT, 1.0, 0.15)
		tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.tween_callback(queue_free)


func _set_height(h: float) -> void:
	_height = h
	queue_redraw()


func _draw() -> void:
	# cień na ziemi
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 3.5, Color(0, 0, 0, 0.3))
	# strzała obrócona w kierunku lotu, uniesiona nad cień
	draw_set_transform(Vector2(0, -_height), direction.angle())
	draw_line(Vector2(-7, 0), Vector2(5, 0), OUTLINE, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(4, -2.5), Vector2(4, 2.5)]), OUTLINE)
	draw_line(Vector2(-7, 0), Vector2(4, 0), SHAFT, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(4.6, -1.5), Vector2(4.6, 1.5)]), HEAD)
	draw_line(Vector2(-8, -2), Vector2(-5, 0), FLETCH, 1.5)
	draw_line(Vector2(-8, 2), Vector2(-5, 0), FLETCH, 1.5)

class_name ProtoTelegraph
extends Node2D
## Czerwone koło na ziemi zapowiadające atak bossa (skopiowane z Watry - scripts/telegraph.gd, tylko koło).
## Wypełnia się od środka przez `duration` sekund, w chwili pełnego wypełnienia atak uderza. W środku zbiegają się
## kręgi (coraz szybciej), tuż przed uderzeniem koło jasno błyska. Koło jest spłaszczone w pionie jak cienie
## (widok z góry pod kątem). Leży pod postaciami (z_index -1); sprząta je potwór albo samo po `LINGER` s.
## Wachlarz (`arc` > 0, zamach rycerza-szkieleta): wycinek koła o kącie `arc` w kierunku `angle` (liczonym na
## płaskiej ziemi, przed spłaszczeniem - `ground_angle`).
## Pas (`length` > 0, fala Wodnika): prostokąt od punktu startu w kierunku `angle`, szerokości `width`,
## wypełnia się od początku do końca; bez spłaszczenia (kierunek liczy się już na ziemi).

const FILL := Color(1.0, 0.12, 0.06, 0.2)
const CHARGE := Color(1.0, 0.18, 0.08, 0.4)
const EDGE := Color(1.0, 0.25, 0.12, 0.9)
const MARK := Color(1.0, 0.55, 0.3, 0.7)
const FLASH := Color(1.0, 0.85, 0.7, 0.45)
## Od jakiego postępu koło błyska przed uderzeniem.
const FLASH_FROM := 0.85
## Spłaszczenie koła w pionie (perspektywa).
const SQUASH := 0.6
## Bezpiecznik: po tylu sekundach od wypełnienia koło samo znika.
const LINGER := 2.0

var radius := 40.0
var duration := 1.0
## Pas zamiast koła: długość (0 - koło), szerokość i kierunek (radiany).
var length := 0.0
var width := 28.0
var angle := 0.0
## Wachlarz: kąt rozwarcia (0 - pełne koło).
var arc := 0.0
var progress := 0.0

var _time := 0.0


func _ready() -> void:
	z_index = -1
	if length > 0.0:
		rotation = angle
	else:
		scale = Vector2(1.0, SQUASH)


func _process(delta: float) -> void:
	_time += delta
	progress = minf(1.0, progress + delta / duration)
	queue_redraw()
	if _time > duration + LINGER:
		queue_free()


## Czy punkt świata leży w kole (z uwzględnieniem spłaszczenia).
func contains(point: Vector2) -> bool:
	var local := point - global_position
	if length > 0.0:
		local = local.rotated(-angle)
		return local.x >= 0.0 and local.x <= length and absf(local.y) <= width / 2.0
	local.y /= SQUASH
	if arc > 0.0 and local.length() > 0.5 and absf(angle_difference(local.angle(), angle)) > arc / 2.0:
		return false
	return local.length() <= radius


## Kąt kierunku `dir` (świat) na płaskiej ziemi - do `angle` wachlarza.
static func ground_angle(dir: Vector2) -> float:
	return Vector2(dir.x, dir.y / SQUASH).angle()


func _draw() -> void:
	if length > 0.0:
		_draw_line_shape()
		return
	if arc > 0.0:
		_draw_fan()
		return
	var pulse := 0.75 + 0.25 * sin(_time * lerpf(8.0, 22.0, progress))
	var edge := Color(EDGE, EDGE.a * pulse)
	var phase := fposmod(_time * lerpf(1.2, 3.5, progress), 1.0)
	draw_circle(Vector2.ZERO, radius, FILL)
	draw_circle(Vector2.ZERO, radius * progress, CHARGE)
	for k in 2:
		var r := radius * (1.0 - fposmod(phase + k * 0.5, 1.0))
		if r > 2.0:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, MARK, 1.0)
	if progress >= FLASH_FROM and int(_time * 20.0) % 2 == 0:
		draw_circle(Vector2.ZERO, radius, FLASH)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, edge, 2.0)


## Pas: tło, wypełnienie od początku, przesuwające się kreski w kierunku fali, błysk i obramowanie.
func _draw_line_shape() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * lerpf(8.0, 22.0, progress))
	var half := width / 2.0
	var rect := Rect2(0.0, -half, length, width)
	draw_rect(rect, FILL)
	draw_rect(Rect2(0.0, -half, length * progress, width), CHARGE)
	var phase := fposmod(_time * lerpf(1.2, 3.5, progress), 1.0)
	for k in 3:
		var x := length * fposmod(phase + k / 3.0, 1.0)
		draw_line(Vector2(x, -half + 2.0), Vector2(x, half - 2.0), MARK, 1.0)
	if progress >= FLASH_FROM and int(_time * 20.0) % 2 == 0:
		draw_rect(rect, FLASH)
	draw_rect(rect, Color(EDGE, EDGE.a * pulse), false, 2.0)


## Wachlarz: wycinek koła wypełniany od środka, z obramowaniem.
func _draw_fan() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * lerpf(8.0, 22.0, progress))
	draw_colored_polygon(_fan_points(radius), FILL)
	if progress > 0.02:
		draw_colored_polygon(_fan_points(radius * progress), CHARGE)
	if progress >= FLASH_FROM and int(_time * 20.0) % 2 == 0:
		draw_colored_polygon(_fan_points(radius), FLASH)
	var edge := _fan_points(radius)
	edge.append(edge[0])
	draw_polyline(edge, Color(EDGE, EDGE.a * pulse), 2.0)


func _fan_points(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2.ZERO])
	var steps := 16
	for i in steps + 1:
		pts.append(Vector2.from_angle(angle - arc / 2.0 + arc * i / steps) * r)
	return pts

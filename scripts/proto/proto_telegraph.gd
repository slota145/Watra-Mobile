class_name ProtoTelegraph
extends Node2D
## Czerwone koło na ziemi zapowiadające atak bossa (skopiowane z Watry - scripts/telegraph.gd, tylko koło).
## Wypełnia się od środka przez `duration` sekund, w chwili pełnego wypełnienia atak uderza. W środku zbiegają się
## kręgi (coraz szybciej), tuż przed uderzeniem koło jasno błyska. Koło jest spłaszczone w pionie jak cienie
## (widok z góry pod kątem). Leży pod postaciami (z_index -1); sprząta je potwór albo samo po `LINGER` s.

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
var progress := 0.0

var _time := 0.0


func _ready() -> void:
	z_index = -1
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
	local.y /= SQUASH
	return local.length() <= radius


func _draw() -> void:
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

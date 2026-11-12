class_name Joystick
extends Control
## Pływająca gałka do chodzenia: dotknij ekranu w dowolnym wolnym miejscu i przeciągnij palcem.
## Gałka pojawia się tam, gdzie zaczął się dotyk, a gdy palec odjedzie za daleko, podąża za nim.
## Obsługuje dotyk wieloma palcami (InputEventScreenTouch / ScreenDrag z numerem palca), więc można iść
## i jednocześnie trzymać przycisk ataku. Na komputerze mysz udaje dotyk (emulate_touch_from_mouse).
## Dotyk zaczęty na zablokowanym obszarze (przyciski - `blocked`) nie uruchamia gałki.

## Promień ruchu gałki w pikselach gry.
const RADIUS := 28.0
## Poniżej tej części promienia postać stoi (drżenie palca).
const DEAD_ZONE := 0.15

## Kierunek i siła (długość 0..1). Odczytuje go postać w każdej klatce.
var vector := Vector2.ZERO
## Kontrolki, na których dotyk nie uruchamia gałki (przyciski interfejsu).
var blocked: Array[Control] = []
var _finger := -1
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1 and not _is_blocked(event.position):
			_finger = event.index
			_base = event.position
			_knob = _base
			vector = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _finger:
		_knob = event.position
		var offset := _knob - _base
		if offset.length() > RADIUS:
			_base = _knob - offset.limit_length(RADIUS)  # gałka jedzie za palcem
			offset = _knob - _base
		vector = Vector2.ZERO if offset.length() / RADIUS < DEAD_ZONE else offset / RADIUS
		queue_redraw()


## Puszcza gałkę (np. przy otwarciu pauzy - palec zdjęty w zatrzymanej grze nie dałby znać).
func release() -> void:
	_finger = -1
	vector = Vector2.ZERO
	queue_redraw()


func _is_blocked(pos: Vector2) -> bool:
	for c in blocked:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


func _draw() -> void:
	if _finger == -1:
		return
	draw_circle(_base, RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(_base, RADIUS, 0.0, TAU, 32, Color(1, 0.85, 0.5, 0.45), 1.5)
	draw_circle(_base + vector * RADIUS, 10.0, Color(1, 0.85, 0.5, 0.6))

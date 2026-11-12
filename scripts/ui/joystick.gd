class_name Joystick
extends Control
## Pływająca gałka do chodzenia: dotknij ekranu w dowolnym wolnym miejscu i przeciągnij palcem.
## Gałka pojawia się tam, gdzie zaczął się dotyk, a gdy palec odjedzie za daleko, podąża za nim.
## Leży pod przyciskami interfejsu (pierwsze dziecko warstwy), więc dotyk przycisku jej nie uruchamia.
## Działa na zdarzeniach myszy: na telefonie Godot zamienia dotyk na mysz, na komputerze to zwykła mysz.

## Promień ruchu gałki w pikselach gry.
const RADIUS := 28.0
## Poniżej tej części promienia postać stoi (drżenie palca).
const DEAD_ZONE := 0.15

## Kierunek i siła (długość 0..1). Odczytuje go postać w każdej klatce.
var vector := Vector2.ZERO
var _active := false
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_base = event.position
			_knob = _base
		else:
			_active = false
			vector = Vector2.ZERO
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _active:
		_knob = event.position
		var offset := _knob - _base
		if offset.length() > RADIUS:
			_base = _knob - offset.limit_length(RADIUS)  # gałka jedzie za palcem
			offset = _knob - _base
		var strength := offset.length() / RADIUS
		vector = Vector2.ZERO if strength < DEAD_ZONE else offset / RADIUS
		queue_redraw()
		accept_event()


func _draw() -> void:
	if not _active:
		return
	draw_circle(_base, RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(_base, RADIUS, 0.0, TAU, 32, Color(1, 0.85, 0.5, 0.45), 1.5)
	draw_circle(_base + vector * RADIUS, 10.0, Color(1, 0.85, 0.5, 0.6))

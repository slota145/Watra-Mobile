class_name ActionButton
extends Control
## Okrągły przycisk akcji pod kciukiem (atak, umiejętność). Działa na dotyku z numerem palca, więc można go
## trzymać, idąc jednocześnie gałką. `held` jest prawdą, dopóki palec go trzyma. Pusty przycisk (bez ikony)
## to wolne miejsce na umiejętność: ciemne kółko z przerywanym brzegiem i plusem. Zablokowane miejsce (`locked_level`)
## ma kłódkę i poziom postaci, na którym się odblokuje; `unlock_flash` - złoty błysk przy odblokowaniu.
## Umiejętność w odnowieniu (`set_state`) przykrywa ciemny wycinek z liczbą sekund, a przy braku many ikona jest
## przyciemniona na niebiesko; `deny` - krótkie drgnięcie, gdy umiejętności nie dało się użyć.

signal pressed
signal released

## Promień kółka w pikselach gry (pole do stukania to kwadrat 2 x radius).
@export var radius := 22.0
@export var icon: Texture2D
## Wolne miejsce (na razie nic nie robi poza mignięciem).
@export var empty := false
## Miejsce zablokowane do tego poziomu postaci (0 - odblokowane).
var locked_level := 0:
	set(value):
		locked_level = value
		queue_redraw()

var held := false
## Odnowienie umiejętności: ile zostało i ile trwa całe (s); brak many na umiejętność.
var cooldown_left := 0.0
var cooldown_total := 0.0
var no_mana := false
var _finger := -1
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # ikona 64 px pomniejszona bez gubienia pikseli
	size = Vector2.ONE * radius * 2.0
	pivot_offset = size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var center := get_global_rect().get_center()
		if event.pressed and _finger == -1 and event.position.distance_to(center) <= radius + 4.0:
			_finger = event.index
			held = true
			_flash = 1.0
			scale = Vector2.ONE * 0.92
			pressed.emit()
			queue_redraw()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			held = false
			scale = Vector2.ONE
			released.emit()
			queue_redraw()


## Puszcza przycisk bez dotyku (np. przy otwarciu pauzy).
func release() -> void:
	if held:
		_finger = -1
		held = false
		scale = Vector2.ONE
		released.emit()
		queue_redraw()


## Stan umiejętności w miejscu: odnowienie (zostało, całe) i czy brakuje many. Przerysowuje tylko przy zmianie.
func set_state(left: float, total: float, lacks_mana: bool) -> void:
	if ceilf(left * 10.0) == ceilf(cooldown_left * 10.0) and lacks_mana == no_mana and total == cooldown_total:
		return
	cooldown_left = left
	cooldown_total = total
	no_mana = lacks_mana
	queue_redraw()


## Krótkie drgnięcie w bok - umiejętności nie dało się użyć (odnowienie albo brak many).
func deny() -> void:
	var x := position.x
	var tween := create_tween()
	for dx in [3.0, -3.0, 2.0, 0.0]:
		tween.tween_property(self, "position:x", x + dx, 0.04)


## Złoty błysk i podskok przy odblokowaniu miejsca.
func unlock_flash() -> void:
	_flash = 1.0
	scale = Vector2.ONE * 1.25
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var fill := Color(0.08, 0.06, 0.06, 0.55 if empty else 0.7).lerp(Color(1.0, 0.8, 0.45, 0.8), _flash * 0.5)
	draw_circle(c, radius, fill)
	if locked_level > 0:
		var line := Color(0.75, 0.68, 0.58, 0.55)
		draw_arc(c, radius - 1.0, 0.0, TAU, 32, line, 1.0)
		# kłódka: kabłąk i korpus, pod nią poziom odblokowania
		var body := Rect2(c + Vector2(-5, -7), Vector2(10, 8))
		draw_arc(c + Vector2(0, -7), 3.5, PI, TAU, 10, line, 1.5)
		draw_rect(body, line)
		var font := ThemeDB.fallback_font
		var text := tr("Poz. %d") % locked_level
		draw_string_outline(font, c + Vector2(-radius, 11), text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, 3, Color(0, 0, 0, 0.8))
		draw_string(font, c + Vector2(-radius, 11), text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, Color(1, 0.88, 0.65, 0.8))
		return
	if empty:
		for i in 12:  # przerywany brzeg
			var a := TAU * i / 12.0
			draw_arc(c, radius - 1.0, a, a + TAU / 24.0, 4, Color(0.85, 0.75, 0.6, 0.5), 1.0)
		var s := radius * 0.3
		draw_line(c - Vector2(s, 0), c + Vector2(s, 0), Color(0.85, 0.75, 0.6, 0.45), 1.5)
		draw_line(c - Vector2(0, s), c + Vector2(0, s), Color(0.85, 0.75, 0.6, 0.45), 1.5)
		return
	draw_arc(c, radius - 1.0, 0.0, TAU, 40, Color(1.0, 0.8, 0.45, 0.9 if held else 0.7), 2.0)
	if icon:
		var side := radius * 1.3
		var tint := Color(0.45, 0.55, 1.0) if no_mana else Color.WHITE
		draw_texture_rect(icon, Rect2(c - Vector2.ONE * side / 2.0, Vector2.ONE * side), false, tint)
	if cooldown_left > 0.0 and cooldown_total > 0.0:
		# ciemny wycinek: tyle koła, ile odnowienia zostało (od góry, zgodnie z ruchem wskazówek)
		var k := clampf(cooldown_left / cooldown_total, 0.0, 1.0)
		var r := (radius - 1.5) / 2.0  # gruby łuk o szerokości promienia = wycinek koła
		var from := -PI / 2.0 + TAU * (1.0 - k)
		draw_arc(c, r, from, -PI / 2.0 + TAU, maxi(3, int(40 * k)), Color(0, 0, 0, 0.6), r * 2.0)
		var font := ThemeDB.fallback_font
		var text := str(ceili(cooldown_left))
		var fs := 14 if radius > 26.0 else 12
		var at := c + Vector2(-radius, fs * 0.35)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, fs, 4, Color(0, 0, 0, 0.9))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, fs, Color(1, 0.95, 0.85))

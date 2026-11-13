class_name ProtoWatra
extends Node2D
## Watra w bazie prototypu: ogień w kręgu kamieni runicznych z Watry (assets/watra/watra.png, 6 klatek),
## z poświatą i iskrami. Dotknięcie ognia palcem otwiera wejście do lochu z Hordą (sygnał `entered`).
## Węzeł stoi u podstawy kręgu (sortowanie po Y z postacią). Pod ogniem licznik żaru (`embers`) - im więcej żaru,
## tym większa i jaśniejsza poświata; `brought` (żar doniesiony właśnie z lochu) wyskakuje nad ogniem jako „+N”.

signal entered

const TEXTURE := preload("res://assets/watra/watra.png")
const FRAMES := 6
const FPS := 7.0
## Kamienie wokół ognia - postać ich nie przechodzi (promień dla ProtoHero.obstacles).
const RADIUS := 38.0
## Obszar do stukania (wokół ognia, w pikselach gry względem węzła) - większy niż sam płomień, żeby łatwo trafić kciukiem.
const TAP_RECT := Rect2(-46, -96, 92, 104)

## Żar zgromadzony w Watrze (ustawia arena przed dodaniem do sceny).
var embers := 0
## Żar doniesiony z ostatniego lochu (pokazywany raz po powrocie).
var brought := 0

var _sprite: Sprite2D
var _glow: Sprite2D
var _time := 0.0
var _flare := 0.0
var embers_label: Label


func _ready() -> void:
	_glow = Sprite2D.new()
	_glow.texture = _glow_texture()
	_glow.scale = Vector2(3.2, 2.2)
	_glow.position = Vector2(0, -20)
	_glow.modulate = Color(1.0, 0.55, 0.2, 0.45)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_glow.z_index = -1
	add_child(_glow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = FRAMES
	_sprite.offset = Vector2(0, -44)
	add_child(_sprite)
	var sparks := CPUParticles2D.new()
	sparks.position = Vector2(0, -56)
	sparks.amount = 18
	sparks.lifetime = 1.6
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(12, 5)
	sparks.direction = Vector2.UP
	sparks.spread = 25.0
	sparks.gravity = Vector2(0, -12)
	sparks.initial_velocity_min = 18.0
	sparks.initial_velocity_max = 40.0
	sparks.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.45, 0.15, 0.8), Color(0.6, 0.2, 0.1, 0.0)])
	sparks.color_ramp = ramp
	sparks.material = add
	sparks.z_index = 30
	add_child(sparks)
	var label := Label.new()
	label.text = tr("Dotknij Watry, by wejść w płomienie")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(200, 14)
	label.position = Vector2(-100, 4)  # pod kręgiem kamieni (nad ogniem zasłaniałby go pasek u góry)
	label.z_index = 31
	add_child(label)
	embers_label = Label.new()
	embers_label.text = tr("Żar Watry: %d") % embers
	embers_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	embers_label.add_theme_font_size_override("font_size", 10)
	embers_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.35))
	embers_label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03))
	embers_label.add_theme_constant_override("outline_size", 4)
	embers_label.size = Vector2(200, 14)
	embers_label.position = Vector2(-100, 17)
	embers_label.z_index = 31
	add_child(embers_label)
	if brought > 0:
		_show_brought.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * FPS) % FRAMES
	_flare = maxf(_flare - delta * 0.5, 0.0)
	var pulse := 1.0 + sin(_time * 5.3) * 0.04 + sin(_time * 9.1) * 0.03
	_glow.scale = Vector2(3.2, 2.2) * pulse * (glow_size() + _flare * 0.4)
	_glow.modulate.a = 0.45 + 0.15 * minf(glow_size() - 1.0, 1.0) + _flare * 0.3


## Nowa ilość żaru (np. po kupnie ulepszenia) - licznik pod ogniem i wielkość poświaty.
func set_embers(value: int) -> void:
	embers = value
	embers_label.text = tr("Żar Watry: %d") % embers


## Wielkość poświaty z ilości żaru: 1 bez żaru, rośnie powoli (logarytmicznie) do 1,6 przy 1000 żaru.
func glow_size() -> float:
	return 1.0 + 0.6 * clampf(log(1.0 + embers) / log(1001.0), 0.0, 1.0)


## Powrót z lochu: rozbłysk ognia i „+N” lecące w górę nad płomieniem.
func _show_brought() -> void:
	_flare = 1.0
	var num := Label.new()
	num.text = "+%d" % brought
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 16)
	num.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	num.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.02))
	num.add_theme_constant_override("outline_size", 5)
	num.size = Vector2(80, 20)
	num.position = Vector2(-40, -80)
	num.z_index = 32
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", -120.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.6).set_delay(1.2)
	tween.tween_callback(num.queue_free)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not get_tree().paused:
		var local: Vector2 = (get_global_transform_with_canvas().affine_inverse() * event.position)
		if TAP_RECT.has_point(local):
			entered.emit()


## Miękka okrągła plama światła (generowana, bez pliku).
static func _glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t

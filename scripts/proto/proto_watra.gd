class_name ProtoWatra
extends Node2D
## Watra w bazie prototypu: ogień w kręgu kamieni runicznych z Watry (assets/watra/watra.png, 6 klatek),
## z poświatą i iskrami. Dotknięcie ognia palcem otwiera wejście do lochu z Hordą (sygnał `entered`).
## Węzeł stoi u podstawy kręgu (sortowanie po Y z postacią).

signal entered

const TEXTURE := preload("res://assets/watra/watra.png")
const FRAMES := 6
const FPS := 7.0
## Kamienie wokół ognia - postać ich nie przechodzi (promień dla ProtoHero.obstacles).
const RADIUS := 38.0
## Obszar do stukania (wokół ognia, w pikselach gry względem węzła) - większy niż sam płomień, żeby łatwo trafić kciukiem.
const TAP_RECT := Rect2(-46, -96, 92, 104)

var _sprite: Sprite2D
var _glow: Sprite2D
var _time := 0.0


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
	label.position = Vector2(-100, -112)
	label.z_index = 31
	add_child(label)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * FPS) % FRAMES
	var pulse := 1.0 + sin(_time * 5.3) * 0.04 + sin(_time * 9.1) * 0.03
	_glow.scale = Vector2(3.2, 2.2) * pulse


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

class_name ProtoStash
extends Node2D
## Skrzynia w bazie (przechowalnia przedmiotów): skrzynia z Watry z podpisem „Skrzynia”. Stuknięcie palcem albo
## podejście postaci otwiera okno skrzyni (sygnał `opened`, okno StashWindow w arenie). Po zamknięciu okna skrzynia
## otwiera się z podejścia dopiero, gdy postać odejdzie i wróci. Postać nie przechodzi przez skrzynię (`RADIUS`).
## Ten sam skrypt służy innym miejscom w bazie (`texture`, `title`, `sprite_scale`), np. kamieniowi run
## z umiejętnościami (grafika rune_stone z Watry, okno SkillsWindow).

signal opened

const TEXTURE := preload("res://assets/watra/chest.png")
const SCALE := 1.4
## Postać nie wchodzi w skrzynię (promień dla ProtoHero.obstacles).
const RADIUS := 14.0
## Z tej odległości (stopy-stopy) podejście otwiera okno.
const OPEN_RANGE := 26.0
## Obszar do stukania (piksele gry względem węzła).
const TAP_RECT := Rect2(-28, -44, 56, 54)

var hero: ProtoHero
## Grafika, podpis i skala (domyślnie skrzynia) - ustawiane przed dodaniem do sceny.
var texture: Texture2D = TEXTURE
var title := "Skrzynia"
var sprite_scale := SCALE
## Postać musi odejść, zanim podejście znów otworzy okno.
var _armed := true


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(1.6, 1.4)
	add_child(shadow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 2.0)
	add_child(sprite)
	var label := Label.new()
	label.text = tr(title)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(80, 14)
	label.position = Vector2(-40, 4)
	label.z_index = 31
	add_child(label)


func _process(_delta: float) -> void:
	if hero == null or get_tree().paused:
		return
	var d := hero.global_position.distance_to(global_position)
	if d > OPEN_RANGE * 1.5:
		_armed = true
	elif _armed and d <= OPEN_RANGE:
		_armed = false
		opened.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not get_tree().paused:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var h := texture.get_height() * sprite_scale  # wyższa grafika (kamień run) - wyższy obszar
		var rect := TAP_RECT.merge(Rect2(-28, -h - 4.0, 56, h + 14.0))
		if rect.has_point(local):
			_armed = false
			opened.emit()

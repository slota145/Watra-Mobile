class_name ProtoDummy
extends Node2D
## Kukła treningowa z Watry: nieśmiertelna, chwieje się i błyska przy trafieniu, pokazuje liczby obrażeń,
## a nad nią licznik - obrażenia na sekundę (z ostatnich 5 s), suma i liczba trafień. Po 4 s spokoju zeruje się.

const DPS_WINDOW := 5.0
const RESET_AFTER := 4.0
## Wysokość środka kukły nad ziemią (tam celuje broń i wyskakują liczby).
const CENTER_HEIGHT := 18.0
const HIT_SOUNDS := [preload("res://assets/watra/dummy_hit_1.ogg"), preload("res://assets/watra/dummy_hit_2.ogg"),
	preload("res://assets/watra/dummy_hit_3.ogg"), preload("res://assets/watra/dummy_hit_4.ogg")]

var _hits: Array = []  # [czas, obrażenia]
var _total := 0
var _count := 0
var _clock := 0.0
var _since_hit := INF
var _sprite: Sprite2D
var _label: Label
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	add_child(_make_shadow())
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/watra/dummy.png")
	_sprite.offset = Vector2(0, -20)
	add_child(_sprite)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120, 30)
	_label.position = Vector2(-60, -84)
	add_child(_label)
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = -9.0
	add_child(_audio)
	_update_label()


## Punkt, w który celuje broń.
func center() -> Vector2:
	return global_position + Vector2(0, -CENTER_HEIGHT)


func take_damage(amount: int, from: Vector2) -> void:
	_audio.stream = HIT_SOUNDS.pick_random()
	_audio.pitch_scale = randf_range(0.92, 1.08)
	_audio.play()
	_spawn_number(amount)
	var away := signf(global_position.x - from.x) if absf(global_position.x - from.x) > 1.0 else 1.0
	var tween := _sprite.create_tween()
	_sprite.modulate = Color(3, 3, 3)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	tween.parallel().tween_property(_sprite, "rotation", 0.2 * away, 0.06)
	tween.tween_property(_sprite, "rotation", 0.0, 0.2)
	_hits.append([_clock, amount])
	_total += amount
	_count += 1
	_since_hit = 0.0
	_update_label()


func _process(delta: float) -> void:
	_clock += delta
	_since_hit += delta
	if _since_hit > RESET_AFTER and _count > 0:
		_hits.clear()
		_total = 0
		_count = 0
		_update_label()
	elif _count > 0 and Engine.get_process_frames() % 15 == 0:
		_update_label()


func _update_label() -> void:
	if _count == 0:
		_label.text = tr("Kukła treningowa")
		return
	_hits = _hits.filter(func(h: Array) -> bool: return _clock - h[0] <= DPS_WINDOW)
	var recent := 0
	for h in _hits:
		recent += h[1]
	var span := clampf(_clock - (_hits[0][0] if _hits else _clock), 1.0, DPS_WINDOW)
	_label.text = tr("%d obrażeń/s") % roundi(recent / span) + "\n" + tr("Suma %d, trafień: %d") % [_total, _count]


func _spawn_number(amount: int) -> void:
	var num := Label.new()
	num.text = str(amount)
	num.add_theme_font_size_override("font_size", 12)
	num.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	num.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.05))
	num.add_theme_constant_override("outline_size", 4)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(40, 16)
	num.position = Vector2(-20 + randf_range(-8, 8), -CENTER_HEIGHT - 26)
	num.z_index = 20
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", num.position.y - 18, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(num.queue_free)


func _make_shadow() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ProtoHero._shadow_texture()
	return s

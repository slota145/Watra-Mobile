class_name ProtoEmber
extends Node2D
## Iskra żaru, która wypada z pokonanego potwora w lochu. Wyskakuje z ciała, leży i migocze, a gdy postać podejdzie
## bliżej niż `MAGNET`, leci do niej coraz szybciej. Po dolocie: sygnał `collected` z wartością i brzęk.
## Grafika: assets/effects/ember.png (tools/ember_art.py) - rząd 0 mała iskra (1 żaru), rząd 1 duża (5 żaru).

signal collected(value: int)

const TEXTURE := preload("res://assets/effects/ember.png")
const FRAMES := 4
const FPS := 8.0
## Z tej odległości (stopy-stopy) iskra sama leci do postaci.
const MAGNET := 40.0
const PICKUP := 6.0
const SOUND_SMALL := preload("res://assets/watra/ember_pickup.ogg")
const SOUND_BIG := preload("res://assets/watra/ember_pickup_big.ogg")
## Wartość dużej iskry.
const BIG := 5

var hero: ProtoHero
var value := 1

var _sprite: Sprite2D
var _glow: Sprite2D
var _time := randf() * 10.0
var _pulled := false
var _speed := 0.0
var _taken := false


func _ready() -> void:
	var big := value >= BIG
	_glow = Sprite2D.new()
	_glow.texture = ProtoWatra._glow_texture()
	_glow.scale = Vector2.ONE * (0.55 if big else 0.35)
	_glow.modulate = Color(1.0, 0.5, 0.15, 0.5)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	add_child(_glow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = FRAMES
	_sprite.vframes = 2
	_sprite.frame_coords = Vector2i(0, 1 if big else 0)
	add_child(_sprite)
	# wyskok z ciała potwora: łuk w bok i w dół na ziemię
	var land := position + Vector2(randf_range(-10, 10), randf_range(-3, 5))
	_sprite.position.y = -10.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", land, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "position:y", -4.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame_coords.x = int(_time * FPS) % FRAMES
	_glow.modulate.a = 0.4 + 0.15 * sin(_time * 6.0)
	if _taken or hero == null or hero.dead:
		return
	var target := hero.global_position + Vector2(0, -6)
	var to := target - global_position
	if not _pulled and to.length() <= MAGNET:
		_pulled = true
		_speed = 40.0
	if _pulled:
		_speed += 400.0 * delta
		global_position += to.normalized() * minf(_speed * delta, to.length())
		if to.length() <= PICKUP:
			_take()
	else:
		_sprite.position.y = -4.0 - 1.5 * (0.5 + 0.5 * sin(_time * 3.0))


func _take() -> void:
	_taken = true
	collected.emit(value)
	var audio := AudioStreamPlayer.new()
	audio.stream = SOUND_BIG if value >= BIG else SOUND_SMALL
	audio.volume_db = -14.0 if value < BIG else -8.0
	audio.pitch_scale = randf_range(1.1, 1.35)
	add_child(audio)
	audio.play()
	_sprite.visible = false
	_glow.visible = false
	audio.finished.connect(queue_free)

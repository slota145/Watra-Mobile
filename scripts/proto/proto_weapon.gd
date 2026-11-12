class_name ProtoWeapon
extends Node2D
## Lewitujący miecz z prototypu: unosi się obok postaci (lekko kołysząc się i doganiając ją z opóźnieniem),
## a gdy cel jest w zasięgu, sam do niego leci, bierze zamach i tnie po łuku przez cel, po czym wraca.
## Węzeł stoi na ziemi pod mieczem (sortowanie po Y z postacią i kukłą), a sam obrazek wisi wyżej (ujemne _sprite.position.y).
## Smuga za ostrzem jest tymczasowa (rysowana kodem) - docelowe efekty ataków robimy w kreatorze efektów PixelLab.

const TEXTURE := preload("res://assets/watra/iron_sword.png")
## Punkt chwytu na obrazku miecza (rękojeść) - wokół niego miecz się obraca.
const GRIP := Vector2(9.5, 10.0)
## Czubek ostrza na obrazku.
const TIP := Vector2(61.0, 9.0)
const SCALE := 0.5
## Jak daleko od postaci miecz sięga po cel (piksele gry).
const REACH := 64.0
const COOLDOWN := 0.75
const WINDUP := 0.16
const SWING := 0.13
const RECOVER := 0.1
## Oś zamachu leży między postacią a celem, tyle pikseli przed środkiem celu; rękojeść krąży blisko osi,
## a ostrze (ok. 31 px) zatacza duży łuk przez cel. SWING_ARC - szerokość łuku w radianach.
const PIVOT_DISTANCE := 18.0
const SWING_RADIUS := 5.0
const SWING_ARC := 2.4
const HOVER_HEIGHT := 22.0
const DAMAGE := Vector2i(14, 20)
const TRAIL_LIFE := 0.15

var hero: ProtoHero
## Cele do bicia (kukły). Arena dopisuje je przy starcie.
var targets: Array[ProtoDummy] = []
## Smuga - Line2D w świecie (arena ją tworzy).
var trail: Line2D

var _state := "follow"
var _t := 0.0
var _cooldown := 0.3
var _target: ProtoDummy
var _hit_done := false
var _a0 := 0.0
var _pivot := Vector2.ZERO
var _from_pos := Vector2.ZERO
var _from_height := 0.0
var _from_rot := 0.0
var _clock := 0.0
var _trail_points: Array = []  # [czas, punkt]
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.centered = false
	_sprite.offset = -GRIP
	_sprite.scale = Vector2.ONE * SCALE
	add_child(_sprite)
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(0.7, 0.7)
	shadow.modulate.a = 0.6
	add_child(shadow)
	if hero:
		position = _follow_spot()


func _process(delta: float) -> void:
	_clock += delta
	_cooldown -= delta
	_t += delta
	match _state:
		"follow":
			_follow(delta)
			if _cooldown <= 0.0:
				_try_attack()
		"windup":
			var k := ease(clampf(_t / WINDUP, 0.0, 1.0), -2.0)  # płynnie: przyspiesza i hamuje
			var start := _swing_point(_a0 - _swing_dir() * 0.3, SWING_RADIUS)  # odrobinę dalej - zamach
			position = _from_pos.lerp(start, k)
			_sprite.position.y = lerpf(_from_height, -ProtoDummy.CENTER_HEIGHT, k)
			_sprite.rotation = lerp_angle(_from_rot, _a0 - _swing_dir() * 0.3, k)
			if _t >= WINDUP:
				_set_state("swing")
		"swing":
			var k := ease(clampf(_t / SWING, 0.0, 1.0), 0.4)  # szybki start, hamowanie pod koniec
			var a := _a0 + _swing_dir() * SWING_ARC * k
			position = _swing_point(a, SWING_RADIUS)
			_sprite.rotation = a
			if not _hit_done and k >= 0.45:
				_hit_done = true
				if is_instance_valid(_target):
					_target.take_damage(randi_range(DAMAGE.x, DAMAGE.y), hero.global_position)
					Input.vibrate_handheld(15)
			if _t >= SWING:
				_set_state("recover")
		"recover":
			if _t >= RECOVER:
				_set_state("follow")
				_cooldown = COOLDOWN
	_update_trail()


## Miejsce obok postaci, za jej ramieniem (od strony przeciwnej do kierunku patrzenia).
func _follow_spot() -> Vector2:
	var side := -1.0 if hero.facing.x >= 0.0 else 1.0
	return hero.position + Vector2(side * 12.0, 3.0)


func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	var side := 1.0 if hero.facing.x >= 0.0 else -1.0
	_sprite.position.y = lerpf(_sprite.position.y, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0), k)
	# ostrze w górę, lekko pochylone w stronę patrzenia, z delikatnym kołysaniem
	var rest := -PI / 2.0 + 0.35 * side + 0.06 * sin(_clock * 2.1)
	_sprite.rotation = lerp_angle(_sprite.rotation, rest, k)


func _try_attack() -> void:
	var best: ProtoDummy = null
	var best_d := REACH
	for t in targets:
		var d := hero.global_position.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
	if not best:
		return
	_target = best
	# oś zamachu przed celem od strony postaci; ostrze idzie od jednej strony celu do drugiej
	var toward_hero := (hero.global_position - best.global_position).normalized()
	_pivot = best.center() + toward_hero * PIVOT_DISTANCE
	_a0 = (-toward_hero).angle() - _swing_dir() * SWING_ARC / 2.0
	_from_pos = position
	_from_height = _sprite.position.y
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("windup")
	hero.play_gesture(best.global_position)


## Kierunek zamachu: zgodnie z ruchem wskazówek, gdy postać jest z lewej, inaczej przeciwnie (ostrze idzie "przed" nią).
func _swing_dir() -> float:
	if not is_instance_valid(_target):
		return 1.0
	return 1.0 if hero.global_position.x <= _target.global_position.x else -1.0


## Punkt na ziemi, nad którym wisi rękojeść, gdy ostrze wskazuje kąt `a` (rękojeść `radius` px od osi zamachu).
func _swing_point(a: float, radius: float) -> Vector2:
	var hilt := _pivot + Vector2.from_angle(a) * radius
	return get_parent().to_local(hilt + Vector2(0, ProtoDummy.CENTER_HEIGHT))


func _set_state(state: String) -> void:
	_state = state
	_t = 0.0


func _update_trail() -> void:
	if not trail:
		return
	if _state == "swing":
		_trail_points.append([_clock, _sprite.to_global(TIP - GRIP)])
	_trail_points = _trail_points.filter(func(p: Array) -> bool: return _clock - p[0] <= TRAIL_LIFE)
	var pts := PackedVector2Array()
	for p in _trail_points:
		pts.append(trail.to_local(p[1]))
	trail.points = pts

class_name ProtoBirdmanShaman
extends ProtoGoblinBrute
## Szaman burzy - silny potwór Górskich równin (Dungeons.PLAINS, jak w Watrze, ustalone z autorem 15.11.2026):
## podchodzi na CAST_RANGE, wskazuje laską miejsce pod postacią - tam leży koło ostrzeżenia (promień BOLT_RADIUS,
## SLAM_WARN s, zostaje w miejscu z chwili wskazania) - i wali tam piorun: żywioł Grom (odporność go zmniejsza)
## i porażenie (ProtoHero.shock - więcej obrażeń przez SHOCK_TIME s). Jak osiłek: trafienie nie przerywa czaru,
## ogłuszenie tak. Nie piszczy przy ucieczce. Grafika: assets/spritekiln/birdman_shaman/birdman_shaman.tscn (idle,
## walk, attack ze zdarzeniem `hit`, hit, death).

const SHAMAN_SCENE := "res://assets/spritekiln/birdman_shaman/birdman_shaman.tscn"
const SHAMAN_HP := 120
const SHAMAN_SPEED := 25.0
const BOLT_DAMAGE := 22
const BOLT_RADIUS := 22.0
const CAST_RANGE := 100.0
const SHOCK_TIME := 2.0
const BOLT_FX := preload("res://assets/effects/katana_hit.png")
const BOLT_FX_FRAMES := 10
const BOLT_FX_ANCHOR := Vector2(28, 22)


func _init() -> void:
	super()
	scene_path = SHAMAN_SCENE
	max_hp = SHAMAN_HP
	speed = SHAMAN_SPEED
	damage = BOLT_DAMAGE
	element = Elements.LIGHTNING
	squeaks = false
	fallback_color = Color(0.5, 0.7, 1.0)
	anim_hit_at = 0.62


func _walk_move(to_hero: Vector2) -> Vector2:
	if to_hero.length() <= CAST_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
		return Vector2.ZERO
	if to_hero.length() > CAST_RANGE * 0.8:
		_face(to_hero)
		return to_hero.normalized() * speed * speed_factor()
	return Vector2.ZERO


## Czar: koło pod postacią (miejsce z chwili wskazania).
func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_telegraph.radius = BOLT_RADIUS
	_telegraph.position = position + to_hero


## Piorun: rani i poraża w kole, błysk burzy.
func _strike() -> void:
	_struck = true
	if _telegraph and is_instance_valid(_telegraph):
		if hero and not hero.dead and _telegraph.contains(hero.global_position):
			hero.take_damage(hit_damage(), element)
			hero.shock(SHOCK_TIME)
		Fx.once(get_parent(), BOLT_FX, BOLT_FX_FRAMES, 18.0, _telegraph.global_position + Vector2(0, -8), BOLT_FX_ANCHOR,
				20, 1.2)
	_remove_telegraph()
	_audio.stream = SLAM_SOUND
	_audio.pitch_scale = randf_range(1.6, 1.8)
	_audio.play()

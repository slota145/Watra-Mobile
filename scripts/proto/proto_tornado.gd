class_name ProtoTornado
extends Node2D
## Trąba powietrzna (Podniebne wyspy, ustalone z autorem 21.11.2026). Dwa tryby:
## - wędrowna (`chase` = false): kilka krąży po lochu przez całą wyprawę (ProtoWind), sunie powoli do losowych punktów;
## - pościg (`chase` = true): trąby Gryfa - suną za postacią przez `life` s i znikają.
## Postać w zasięgu PULL_RADIUS jest wciągana ku środkowi (ProtoHero.drift, wolniej niż biegnie), a w samym środku
## (HIT_RADIUS) dostaje obrażenia powietrzem i zostaje wyrzucona na THROW px (ProtoHero.leap) - potem chwila
## przerwy (HIT_COOLDOWN). Grafika: zapętlona trąba Gryfa z Watry (`gryf_tornado`, kreator efektów PixelLab).

const FX := preload("res://assets/watra/effects/gryf_tornado.png")
const FX_FRAMES := 8
const FX_FPS := 14.0
const FX_ANCHOR := Vector2(23, 64)
const FX_SIZE := 1.0
const PULL_RADIUS := 60.0
const PULL_SPEED := 30.0
const HIT_RADIUS := 12.0
const HIT_COOLDOWN := 1.2
const THROW := 70.0
const WANDER_SPEED := 22.0
const CHASE_SPEED := 52.0
const FADE := 0.4

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var damage := 10
var chase := false
## Pościg: po tylu sekundach znika (wędrowna trwa, aż ktoś ją usunie).
var life := 4.0

var _time := 0.0
var _hit_cd := 0.0
var _goal := Vector2.ZERO
var _fx: Sprite2D


func _ready() -> void:
	_fx = Fx.loop(self, FX, FX_FRAMES, FX_FPS, Vector2.ZERO, FX_ANCHOR, 0, FX_SIZE)
	_fx.modulate = Color(0.92, 0.97, 1.0, 0.85)
	_goal = position
	modulate.a = 0.0


func _process(delta: float) -> void:
	_time += delta
	_hit_cd -= delta
	var fade_out := (life - _time) / FADE if chase else 1.0
	modulate.a = clampf(minf(_time / FADE, fade_out), 0.0, 1.0)
	if chase and _time >= life:
		queue_free()
		return
	_move(delta)
	if hero == null or hero.dead or modulate.a < 0.5:
		return
	var to := global_position - hero.global_position
	var d := to.length()
	if d < HIT_RADIUS and _hit_cd <= 0.0:
		_hit_cd = HIT_COOLDOWN
		hero.take_damage(damage, Elements.AIR)
		var away := (-to).normalized() if d > 0.5 else Vector2.from_angle(randf() * TAU)
		hero.leap((hero.global_position + away * THROW).clamp(hero.bounds.position, hero.bounds.end), 0.3, 12.0)
	elif d < PULL_RADIUS and d > 2.0 and _hit_cd <= 0.0:
		hero.drift(to.normalized() * minf(PULL_SPEED * delta, d))


func _move(delta: float) -> void:
	if chase:
		if hero and not hero.dead:
			position += (hero.global_position - global_position).normalized() * CHASE_SPEED * delta
		return
	if position.distance_to(_goal) < 8.0:
		_goal = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
	position = position.move_toward(_goal, WANDER_SPEED * delta)


## Kurz pod trąbą (spłaszczone koło).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 16.0, Color(0.85, 0.9, 1.0, 0.18))
	draw_circle(Vector2.ZERO, 9.0, Color(0.0, 0.0, 0.0, 0.18))

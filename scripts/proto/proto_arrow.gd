class_name ProtoArrow
extends Node2D
## Strzała goblina łucznika: leci prosto (wolno, żeby dało się ją wyminąć kciukiem) na wysokości `HEIGHT` nad ziemią,
## z cieniem pod spodem. Trafia Wojciecha, gdy zbliży się do jego stóp na `HIT_RADIUS`, i wtedy znika z błyskiem
## i drzazgami; po przeleceniu `RANGE` pikseli opada i gaśnie. Grafika z kreatora efektów PixelLab:
## `assets/effects/arrow_fly.png` (lot w pętli, grot w prawo - obracany w kierunku lotu) i `arrow_hit.png` (trafienie).
## Węzeł stoi w punkcie na ziemi pod strzałą, więc sortowanie po Y działa jak u postaci.
## Kula wody żabołaka (`water`): ta sama strzała z grafiką bańki hydrosfery (`hydro_bolt`, rozprysk `hydro_splash`),
## żywioł wody i przemoczenie postaci (spowolnienie SOAK_SLOW na SOAK_TIME s).
## Inne pociski: `element` - żywioł (strzała Nawii szkieleta łucznika), `bubble` - grafika bańki (kule Nawii
## Nekromanty), `tint` - barwa, `speed` / `fly_range` - prędkość i zasięg.

## Prędkość (Wojciech: 70 px/s) - strzała z odległości 120 px leci ok. 1 s, w tym czasie da się zejść z linii.
const SPEED := 115.0
const RANGE := 240.0
## Wysokość lotu nad ziemią (px) i promień trafienia (odległość od stóp postaci).
const HEIGHT := 11.0
const HIT_RADIUS := 8.0
## Arkusze z pixellab_src/vfx/ids.json (klatki, fps, punkt zaczepienia - środek strzały / środek błysku).
const FLY := preload("res://assets/effects/arrow_fly.png")
const FLY_FRAMES := 6
const FLY_FPS := 16.0
const FLY_ANCHOR := Vector2(30, 8)
const HIT := preload("res://assets/effects/arrow_hit.png")
const HIT_FRAMES := 8
const HIT_FPS := 16.0
const HIT_ANCHOR := Vector2(16, 14)

const WATER_FLY := preload("res://assets/effects/hydro_bolt.png")
const WATER_FLY_FRAMES := 8
const WATER_FLY_ANCHOR := Vector2(22, 8)
const WATER_HIT := preload("res://assets/effects/hydro_splash.png")
const WATER_HIT_FRAMES := 10
const WATER_HIT_ANCHOR := Vector2(21, 18)
const SOAK_SLOW := 0.25
const SOAK_TIME := 2.0

var hero: ProtoHero
var direction := Vector2.RIGHT
var damage := 8
## Kula wody zamiast strzały (żabołak).
var water := false
var element := Elements.PHYSICAL
var bubble := false
var tint := Color.WHITE
var speed := SPEED
var fly_range := RANGE
## Podpalenie przy trafieniu (żar ognika): obrażenia jednego płomienia (0 - bez podpalenia).
var ignite := 0

var _flown := 0.0
var _done := false
var _height := HEIGHT
var _time := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	if water:
		bubble = true
		element = Elements.WATER
	_sprite = Sprite2D.new()
	_sprite.texture = WATER_FLY if bubble else FLY
	_sprite.hframes = WATER_FLY_FRAMES if bubble else FLY_FRAMES
	_sprite.centered = false
	_sprite.offset = -(WATER_FLY_ANCHOR if bubble else FLY_ANCHOR)
	_sprite.modulate = tint
	_sprite.position = Vector2(0, -_height)
	_sprite.rotation = direction.angle()
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * FLY_FPS) % _sprite.hframes
	if _done:
		return
	var step := speed * delta
	position += direction * step
	_flown += step
	if hero and not hero.dead and global_position.distance_to(hero.global_position) <= HIT_RADIUS:
		hero.take_damage(damage, element)
		if water:
			hero.slow(SOAK_SLOW, SOAK_TIME, Elements.COLORS[Elements.WATER].lerp(Color.WHITE, 0.4))
		if ignite > 0:
			hero.ignite(ignite, 3.0)
		_finish(true)
		return
	if _flown >= fly_range:
		_finish(false)


## Koniec lotu: przy trafieniu błysk z drzazgami w miejscu strzały, przy chybieniu strzała opada na ziemię i gaśnie.
func _finish(hit: bool) -> void:
	_done = true
	if hit:
		var fx: Sprite2D
		if bubble:
			fx = Fx.once(get_parent(), WATER_HIT, WATER_HIT_FRAMES, 14.0, global_position + Vector2(0, -_height), WATER_HIT_ANCHOR, 20, 0.6)
		else:
			fx = Fx.once(get_parent(), HIT, HIT_FRAMES, HIT_FPS, global_position + Vector2(0, -_height), HIT_ANCHOR)
		fx.modulate = tint
		queue_free()
		return
	var tween := create_tween()
	tween.tween_method(_set_height, HEIGHT, 1.0, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.tween_callback(queue_free)


func _set_height(h: float) -> void:
	_height = h
	_sprite.position = Vector2(0, -h)
	queue_redraw()


## Cień na ziemi pod strzałą.
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.3))

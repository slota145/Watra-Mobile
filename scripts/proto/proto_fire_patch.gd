class_name ProtoFirePatch
extends Node2D
## Płonąca ziemia (Wulkaniczne równiny - golem, Żywiołak ognia, lawa): koło (spłaszczone jak cienie) płomyków
## z kreatora efektów glewii (`glaive_ground_fire`) przez `time` s. Postać, która w nim stoi, co TICK s jest
## podpalana (ProtoHero.ignite - `burn` obrażeń na płomień przez BURN_TIME s). Pod koniec płomienie gasną.

const FX := preload("res://assets/effects/glaive_ground_fire.png")
const FX_FRAMES := 8
const FX_ANCHOR := Vector2(10, 15)
const FX_FPS := 12.0
const SPACING := 12.0
const SQUASH := 0.6
const TICK := 0.5
const BURN_TIME := 2.0
const FADE := 0.4

var hero: ProtoHero
var radius := 20.0
var time := 3.0
## Obrażenia jednego płomienia podpalenia.
var burn := 4

var _left := 0.0
var _tick := 0.0
var _flames: Array[Sprite2D] = []
var _t := 0.0


func _ready() -> void:
	z_index = -1
	_left = time
	var spots: Array[Vector2] = [Vector2.ZERO]
	var r := SPACING
	while r < radius + 1.0:
		var count := int(TAU * r / SPACING)
		for i in count:
			var a := TAU * i / count + r
			spots.append(Vector2(cos(a), sin(a) * SQUASH) * r)
		r += SPACING
	for p in spots:
		var f := Sprite2D.new()
		f.texture = FX
		f.hframes = FX_FRAMES
		f.centered = false
		f.offset = -FX_ANCHOR
		f.position = p
		f.frame = randi() % FX_FRAMES
		add_child(f)
		_flames.append(f)


## Czy punkt świata leży w płonącym kole.
func contains(point: Vector2) -> bool:
	var d := point - global_position
	return Vector2(d.x, d.y / SQUASH).length() <= radius


func _process(delta: float) -> void:
	_t += delta
	_left -= delta
	for i in _flames.size():
		_flames[i].frame = (int(_t * FX_FPS) + i) % FX_FRAMES
	if _left < FADE:
		modulate.a = maxf(_left / FADE, 0.0)
	if _left <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0 and hero and not hero.dead and contains(hero.global_position):
		_tick = TICK
		hero.ignite(burn, BURN_TIME)


## Płonąca ziemia w punkcie `at` świata (rodzic - świat lochu).
static func spawn(parent: Node, at: Vector2, hero_ref: ProtoHero, r: float, seconds: float, burn_damage: int) -> ProtoFirePatch:
	var p := ProtoFirePatch.new()
	p.hero = hero_ref
	p.radius = r
	p.time = seconds
	p.burn = burn_damage
	parent.add_child(p)
	p.global_position = at
	return p

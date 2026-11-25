class_name ProtoGrove
extends Node2D
## Żywa puszcza - mechanika Prastarego Boru (Dungeons.FOREST, decyzja autora 25.11.2026, liczby - Claude): co EVERY s
## (losowo w widełkach) pod postacią pojawia się zapowiedź (czerwone koło ProtoTelegraph, RADIUS) i po WARN s z ziemi
## wyskakują korzenie (leshy_roots z Watry): postać w kole obrywa (natura) i korzenie na HOLD s ją trzymają (prawie pełne
## spowolnienie - ProtoHero.slow ogranicza je do 80%). Zapowiedź celuje trochę przed postać, gdy idzie - trzeba zmienić kierunek albo stanąć. Arena tworzy
## węzeł tylko w tym lochu (`arena.grove`).

const EVERY := Vector2(5.0, 8.0)
const RADIUS := 26.0
const WARN := 1.0
const LEAD := 0.5
const DAMAGE := 8
const HOLD := 1.0
const HOLD_SLOW := 0.9
const ROOTS_FX := preload("res://assets/watra/effects/leshy_roots.png")

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: korzenie same nie wyskakują.
var passive := false
## Ile razy korzenie złapały postać (testy).
var grabs := 0
var _next := 3.0
var _warn: ProtoTelegraph


func _process(delta: float) -> void:
	if hero == null or hero.dead:
		return
	if _warn and is_instance_valid(_warn):
		if _warn.progress >= 1.0:
			_burst()
		return
	if passive:
		return
	_next -= delta
	if _next <= 0.0:
		start()


## Zapowiedź korzeni pod postacią (trochę przed nią, gdy idzie).
func start() -> void:
	_next = randf_range(EVERY.x, EVERY.y)
	_warn = ProtoTelegraph.new()
	_warn.radius = RADIUS
	_warn.duration = WARN
	get_parent().add_child(_warn)
	_warn.global_position = (hero.global_position + hero.velocity * LEAD).clamp(bounds.position, bounds.end)


func _burst() -> void:
	var at := _warn.global_position
	if _warn.contains(hero.global_position):
		grabs += 1
		hero.take_damage(maxi(1, roundi(DAMAGE * power)), Elements.NATURE)
		hero.slow(HOLD_SLOW, HOLD, Elements.COLORS[Elements.NATURE])
	_warn.queue_free()
	_warn = null
	for i in 3:
		var p := at + Vector2.from_angle(TAU * i / 3.0 + randf()) * Vector2(RADIUS * 0.5, RADIUS * 0.3)
		Fx.once(get_parent(), ROOTS_FX, 10, 16.0, p.round(), Vector2(24, 39), 20, 0.9)


func _exit_tree() -> void:
	if _warn and is_instance_valid(_warn):
		_warn.queue_free()

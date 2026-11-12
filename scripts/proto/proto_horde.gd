class_name ProtoHorde
extends Node
## Ciągły strumień Hordy w lochu prototypu: gobliny pojawiają się tuż poza ekranem i idą do Wojciecha.
## Z czasem przychodzą coraz częściej i coraz więcej naraz (`interval`, `max_alive`), aż do sufitu po ~3 minutach.
## Liczy pokonane potwory i czas przetrwania (`kills`, `time`).

signal kills_changed(kills: int)

## Odstęp między potworami na starcie i po pełnym rozkręceniu (s).
const INTERVAL_START := 1.3
const INTERVAL_END := 0.3
## Najwięcej potworów naraz na starcie i po pełnym rozkręceniu.
const ALIVE_START := 8
const ALIVE_END := 45
## Po tylu sekundach strumień osiąga pełne tempo.
const RAMP_TIME := 180.0
## Pierwszy potwór po tylu sekundach (chwila na rozejrzenie się).
const FIRST_DELAY := 1.5

var hero: ProtoHero
## Gdzie dodawać potwory (świat z sortowaniem po Y).
var world: Node2D
var bounds := Rect2(-300, -300, 600, 600)
var kills := 0
var time := 0.0
var running := true

var _next := FIRST_DELAY
var _alive := 0


func _process(delta: float) -> void:
	if not running or hero == null or hero.dead:
		return
	time += delta
	_next -= delta
	if _next <= 0.0:
		_next = interval()
		if _alive < max_alive():
			spawn()


## Obecny odstęp między potworami.
func interval() -> float:
	return lerpf(INTERVAL_START, INTERVAL_END, _ramp())


func max_alive() -> int:
	return roundi(lerpf(ALIVE_START, ALIVE_END, _ramp()))


func _ramp() -> float:
	return clampf(time / RAMP_TIME, 0.0, 1.0)


func spawn() -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = hero
	g.bounds = bounds
	g.position = spawn_point()
	g.died.connect(_on_died)
	_alive += 1
	world.add_child(g)
	return g


## Punkt tuż poza widocznym kadrem (w losowym kierunku od postaci), w granicach areny.
## Gdy postać stoi przy brzegu areny i w danym kierunku nie ma miejsca, losuje inny kierunek.
func spawn_point() -> Vector2:
	var view := hero.get_viewport_rect().size
	var half := view / 2.0 + Vector2(16, 24)
	var p := Vector2.ZERO
	for i in 12:
		var dir := Vector2.from_angle(randf() * TAU)
		# promień do krawędzi kadru w tym kierunku
		var t := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		p = hero.global_position + dir * t
		if bounds.has_point(p):
			return p
	return p.clamp(bounds.position, bounds.end)


func _on_died(_g: ProtoGoblin) -> void:
	_alive -= 1
	kills += 1
	kills_changed.emit(kills)

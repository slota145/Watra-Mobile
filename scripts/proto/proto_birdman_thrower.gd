class_name ProtoBirdmanThrower
extends ProtoGoblinArcher
## Ptakoczłek miotacz - strzelający potwór Górskich równin (Dungeons.PLAINS, jak w Watrze, ustalone z autorem
## 15.11.2026): jak goblin łucznik (dystans, linia celu, przerwanie trafieniem), ale rzuca oszczepem - cięższy
## pocisk (grafika strzały, większa i jaśniejsza), fizyczny. Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/birdman_thrower/birdman_thrower.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const THROWER_SCENE := "res://assets/spritekiln/birdman_thrower/birdman_thrower.tscn"
const THROWER_HP := 32
const JAVELIN_DAMAGE := 12
## Rzut w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## rzut zgrał się z RELEASE_TIME (linia celu); ustawiane po eksporcie modelu.
var throw_at := RELEASE_TIME
var _throw_started := false


func _init() -> void:
	super()
	scene_path = THROWER_SCENE
	max_hp = THROWER_HP
	damage = JAVELIN_DAMAGE
	squeaks = false
	fallback_color = Color(0.8, 0.8, 0.82)
	arrow_scale = 1.35
	arrow_tint = Color(1.15, 1.1, 1.0)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_throw_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _throw_started and _timer >= RELEASE_TIME - throw_at:
		_throw_started = true
		_play(&"attack", true)


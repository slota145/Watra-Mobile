class_name ProtoWila
extends ProtoGoblinArcher
## Wiła - strzelający potwór Podniebnych wysp (Dungeons.SKY, ustalone z autorem 21.11.2026): opętana nimfa wiatru,
## zachowuje się jak goblin łucznik (dystans, linia celu, przerwanie trafieniem), ale ciska ostrze wiatru
## (ProtoArrow `wind` - półksiężyc z Watry, powietrze, lekko odpycha postać), które leci szybciej i dalej niż strzała.
## Nie piszczy przy ucieczce. Grafika: assets/spritekiln/wila/wila.tscn (idle, walk, attack ze zdarzeniem `release`,
## hit, death).

const WILA_SCENE := "res://assets/spritekiln/wila/wila.tscn"
const WILA_HP := 24
const BLADE_DAMAGE := 9
const BLADE_SPEED := 135.0
const BLADE_RANGE := 260.0
const BLADE_TINT := Color(0.85, 0.97, 1.0)
## Rzut w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## rzut zgrał się z RELEASE_TIME (linia celu).
var throw_at := 0.42
var _throw_started := false


func _init() -> void:
	super()
	scene_path = WILA_SCENE
	max_hp = WILA_HP
	damage = BLADE_DAMAGE
	element = Elements.AIR
	squeaks = false
	fallback_color = Color(0.9, 0.97, 1.0)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_throw_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _throw_started and _timer >= RELEASE_TIME - throw_at:
		_throw_started = true
		_play(&"attack", true)


## Ostrze wiatru: półksiężyc leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.wind = true
	b.tint = BLADE_TINT
	b.speed = BLADE_SPEED
	b.fly_range = BLADE_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.position = position + aim * 6.0
	get_parent().add_child(b)

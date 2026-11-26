class_name ProtoApprentice
extends ProtoGoblinArcher
## Uczeń czarnoksiężnika - strzelający potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): młody
## adept Kościeja w szacie z kapturem, z księgą i świecącą dłonią. Zachowuje się jak goblin łucznik (dystans, czerwona
## linia celu, przerwanie trafieniem), ale z dłoni wypuszcza pocisk Arkanów (ProtoArrow `arcane` - fioletowa głowa
## z ogonem, wysysa trochę many). Nie piszczy przy ucieczce. Grafika: assets/spritekiln/apprentice/apprentice.tscn
## (idle, walk, attack ze zdarzeniem `release` ok. 0,6 s, hit, death); do czasu grafiki - zastępczy kolor.

const APPRENTICE_SCENE := "res://assets/spritekiln/apprentice/apprentice.tscn"
const APPRENTICE_HP := 26
const BOLT_DAMAGE := 10
const BOLT_SPEED := 150.0
const BOLT_RANGE := 250.0
## Strzał w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## strzał zgrał się z RELEASE_TIME (linia celu).
var shot_at := 0.6
var _shot_started := false


func _init() -> void:
	super()
	scene_path = APPRENTICE_SCENE
	max_hp = APPRENTICE_HP
	damage = BOLT_DAMAGE
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.7, 0.5, 0.95)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_shot_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _shot_started and _timer >= RELEASE_TIME - shot_at:
		_shot_started = true
		_play(&"attack", true)


## Pocisk Arkanów leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.arcane = true
	b.speed = BOLT_SPEED
	b.fly_range = BOLT_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.position = position + aim * 6.0
	get_parent().add_child(b)

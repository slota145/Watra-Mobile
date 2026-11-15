class_name ProtoFireWisp
extends ProtoGoblinArcher
## Ognik - strzelający potwór Wulkanicznych równin (Dungeons.VOLCANO, ustalone z autorem 15.11.2026): lewitująca
## kula ognia, zachowuje się jak goblin łucznik (dystans, linia celu, przerwanie trafieniem), ale pluje żarem -
## ognistą bańką (ProtoArrow `bubble`, żywioł ognia), która podpala postać. Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/fire_wisp/fire_wisp.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const WISP_SCENE := "res://assets/spritekiln/fire_wisp/fire_wisp.tscn"
const WISP_HP := 24
const EMBER_DAMAGE := 9
const BURN := 3
const EMBER_TINT := Color(1.0, 0.55, 0.2)
## Plucie w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## plucie zgrało się z RELEASE_TIME (linia celu); ustawiane po eksporcie modelu.
var spit_at := RELEASE_TIME
var _spit_started := false


func _init() -> void:
	super()
	scene_path = WISP_SCENE
	max_hp = WISP_HP
	damage = EMBER_DAMAGE
	element = Elements.FIRE
	squeaks = false
	fallback_color = Color(1.0, 0.6, 0.2)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_spit_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _spit_started and _timer >= RELEASE_TIME - spit_at:
		_spit_started = true
		_play(&"attack", true)


## Żar: ognista bańka, podpala.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.bubble = true
	b.element = Elements.FIRE
	b.tint = EMBER_TINT
	b.direction = aim
	b.damage = hit_damage()
	b.ignite = roundi(BURN * power)
	b.position = position + aim * 6.0
	get_parent().add_child(b)

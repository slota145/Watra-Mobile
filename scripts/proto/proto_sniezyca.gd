class_name ProtoSniezyca
extends ProtoGoblinArcher
## Śnieżnica - strzelający potwór Lodowych jaskiń (Dungeons.FROST, ustalone z autorem 25.11.2026): mroźna wiła,
## zachowuje się jak goblin łucznik (dystans, linia celu, przerwanie trafieniem), ale ciska sopel (ProtoArrow `ice` -
## sopel z kreatora, lód: spowalnia i dokłada chłodu), który leci szybciej i dalej niż strzała. Nie piszczy przy
## ucieczce. Grafika: assets/spritekiln/sniezyca/sniezyca.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const SNIEZYCA_SCENE := "res://assets/spritekiln/sniezyca/sniezyca.tscn"
const SNIEZYCA_HP := 26
const ICICLE_DAMAGE := 10
const ICICLE_SPEED := 150.0
const ICICLE_RANGE := 260.0
## Rzut w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## rzut zgrał się z RELEASE_TIME (linia celu).
var throw_at := 0.42
var _throw_started := false


func _init() -> void:
	super()
	scene_path = SNIEZYCA_SCENE
	max_hp = SNIEZYCA_HP
	damage = ICICLE_DAMAGE
	element = Elements.COLD
	squeaks = false
	fallback_color = Color(0.88, 0.96, 1.0)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_throw_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _throw_started and _timer >= RELEASE_TIME - throw_at:
		_throw_started = true
		_play(&"attack", true)


## Sopel leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.ice = true
	b.speed = ICICLE_SPEED
	b.fly_range = ICICLE_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.position = position + aim * 6.0
	get_parent().add_child(b)

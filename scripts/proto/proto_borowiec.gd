class_name ProtoBorowiec
extends ProtoGoblinArcher
## Borowiec - strzelający potwór Prastarego Boru (Dungeons.FOREST, ustalone z autorem 25.11.2026): duch boru, sługa
## Leszego z łukiem z cierniowej gałęzi; zachowuje się jak goblin łucznik (dystans, linia celu, przerwanie trafieniem),
## ale strzela cierniem (ProtoArrow `thorn` - natura). Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/borowiec/borowiec.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const BOROWIEC_SCENE := "res://assets/spritekiln/borowiec/borowiec.tscn"
const BOROWIEC_HP := 28
const THORN_DAMAGE := 10
const THORN_SPEED := 140.0
const THORN_RANGE := 250.0
## Strzał w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## strzał zgrał się z RELEASE_TIME (linia celu).
var shot_at := 0.63
var _shot_started := false


func _init() -> void:
	super()
	scene_path = BOROWIEC_SCENE
	max_hp = BOROWIEC_HP
	damage = THORN_DAMAGE
	element = Elements.NATURE
	squeaks = false
	fallback_color = Color(0.45, 0.35, 0.2)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_shot_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _shot_started and _timer >= RELEASE_TIME - shot_at:
		_shot_started = true
		_play(&"attack", true)


## Cierń leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.thorn = true
	b.speed = THORN_SPEED
	b.fly_range = THORN_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.position = position + aim * 6.0
	get_parent().add_child(b)

class_name ProtoZarPtak
extends ProtoGoblinArcher
## Żar-ptak - strzelający potwór Świątyni Słońca (Dungeons.TEMPLE, ustalone z autorem 26.11.2026): świetlisty ptak
## o złoto-pomarańczowych piórach z długim, świecącym ogonem. Zachowuje się jak goblin łucznik (dystans, linia celu,
## przerwanie trafieniem), ale unosi się nad ziemią i wypuszcza z dzioba promień światła (ProtoArrow `ray` - Prawia).
## Nie piszczy przy ucieczce. Grafika: assets/spritekiln/zar_ptak/zar_ptak.tscn (idle, walk, attack ze zdarzeniem
## `release`, hit, death); do czasu grafiki - zastępczy kolor.

const ZAR_SCENE := "res://assets/spritekiln/zar_ptak/zar_ptak.tscn"
const ZAR_HP := 26
const RAY_DAMAGE := 11
const RAY_SPEED := 170.0
const RAY_RANGE := 260.0
## Strzał w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## strzał zgrał się z RELEASE_TIME (linia celu).
var shot_at := 0.6
var _shot_started := false


func _init() -> void:
	super()
	scene_path = ZAR_SCENE
	max_hp = ZAR_HP
	damage = RAY_DAMAGE
	element = Elements.PRAWIA
	squeaks = false
	fallback_color = Color(1.0, 0.65, 0.2)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_shot_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _shot_started and _timer >= RELEASE_TIME - shot_at:
		_shot_started = true
		_play(&"attack", true)


## Promień leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.ray = true
	b.speed = RAY_SPEED
	b.fly_range = RAY_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.position = position + aim * 6.0
	get_parent().add_child(b)

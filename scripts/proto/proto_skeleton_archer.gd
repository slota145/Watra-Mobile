class_name ProtoSkeletonArcher
extends ProtoGoblinArcher
## Szkielet łucznik - strzelający potwór Katakumb (Dungeons.CATACOMBS, ustalone z autorem 15.11.2026): jak goblin
## łucznik (dystans, linia celu, przerwanie trafieniem), ale strzela fioletową strzałą Nawii (odporność na żywioły
## ją zmniejsza). Nie piszczy przy ucieczce. Grafika: assets/spritekiln/skeleton_archer/skeleton_archer.tscn
## (idle, walk, attack ze zdarzeniem `release`, hit, death).

const SKELETON_ARCHER_SCENE := "res://assets/spritekiln/skeleton_archer/skeleton_archer.tscn"
const SKELETON_ARCHER_HP := 28
const NAWIA_ARROW_DAMAGE := 10
## Stopy w animacji chodu przesuwają się z tą prędkością.
const SKELETON_ARCHER_SPEED := 36.0
## Strzał w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## strzał zgrał się z RELEASE_TIME (linia celu); wcześniej łucznik stoi.
const SHOT_AT := 0.49

var _shot_started := false


func _init() -> void:
	super()
	scene_path = SKELETON_ARCHER_SCENE
	max_hp = SKELETON_ARCHER_HP
	speed = SKELETON_ARCHER_SPEED
	damage = NAWIA_ARROW_DAMAGE
	element = Elements.NAWIA
	squeaks = false
	fallback_color = Color(0.75, 0.7, 0.85)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_shot_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _shot_started and _timer >= RELEASE_TIME - SHOT_AT:
		_shot_started = true
		_play(&"attack", true)

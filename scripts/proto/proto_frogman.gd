class_name ProtoFrogman
extends ProtoGoblinArcher
## Żabołak - strzelający potwór Zatopionych podziemi (Dungeons.FLOODED, ustalone z autorem 15.11.2026): zachowuje się
## jak goblin łucznik (trzyma dystans, linia celu na ziemi, przerwanie trafieniem), ale pluje kulą wody (ProtoArrow
## z `water`) - żywioł wody i przemoczenie (spowolnienie). Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/frogman/frogman.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const FROGMAN_SCENE := "res://assets/spritekiln/frogman/frogman.tscn"
const FROGMAN_HP := 30
const SPIT_DAMAGE := 9
## Stopy w animacji chodu przesuwają się z tą prędkością (bez ślizgania).
const FROGMAN_SPEED := 33.0
## Plucie w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## plucie zgrało się z RELEASE_TIME (linia celu jak u łucznika); wcześniej żabołak stoi i pulsuje gardłem.
const SPIT_AT := 0.41

var _spit_started := false


func _init() -> void:
	super()
	scene_path = FROGMAN_SCENE
	max_hp = FROGMAN_HP
	speed = FROGMAN_SPEED
	damage = SPIT_DAMAGE
	element = Elements.WATER
	squeaks = false
	fallback_color = Color(0.35, 0.65, 0.3)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_spit_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _spit_started and _timer >= RELEASE_TIME - SPIT_AT:
		_spit_started = true
		_play(&"attack", true)

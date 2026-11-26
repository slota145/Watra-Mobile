class_name ProtoProcarz
extends ProtoGoblinArcher
## Karzeł-procarz - strzelający potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026; liczby - Claude):
## karzeł górnik opętany przez Hordę, z procą. Zachowuje się jak goblin łucznik (dystans, czerwona linia celu,
## przerwanie trafieniem), ale ciska kamieniem z procy (ProtoArrow z grafiką kamienia z tools/mine_art.py - szybszy
## od strzały, żywioł ziemia). Kamień rozbija się na głazach Osuwiska (ProtoRockfall) - za głazem można się schować.
## Nie piszczy przy ucieczce. Grafika: assets/spritekiln/procarz/procarz.tscn (idle, walk, attack ze zdarzeniem
## `release` ok. 0,6 s, hit, death); do czasu grafiki - zastępczy kolor.

const PROCARZ_SCENE := "res://assets/spritekiln/procarz/procarz.tscn"
const PROCARZ_HP := 28
const STONE_DAMAGE := 10
const STONE_SPEED := 140.0
const STONE_RANGE := 250.0
const STONE_TEX := preload("res://assets/watra/decor/mine/sling_stone.png")
const STONE_TINT := Color(0.85, 0.7, 0.5)
## Strzał w animacji `attack` pada tyle sekund po jej początku (zdarzenie `release`) - animacja rusza tak, żeby
## strzał zgrał się z RELEASE_TIME (linia celu).
var shot_at := 0.6
var _shot_started := false


func _init() -> void:
	super()
	scene_path = PROCARZ_SCENE
	max_hp = PROCARZ_HP
	damage = STONE_DAMAGE
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.6, 0.45, 0.3)


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_shot_started = false
	_play(&"idle")


func _process(delta: float) -> void:
	super(delta)
	if _scene and _state == "attack" and not _shot_started and _timer >= RELEASE_TIME - shot_at:
		_shot_started = true
		_play(&"attack", true)


## Kamień z procy leci w zablokowanym kierunku.
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var b := ProtoArrow.new()
	b.hero = hero
	b.element = Elements.EARTH
	b.speed = STONE_SPEED
	b.fly_range = STONE_RANGE
	b.direction = aim
	b.damage = hit_damage()
	b.tint = STONE_TINT
	b.position = position + aim * 6.0
	get_parent().add_child(b)
	stone_look(b)


## Grafika kamienia zamiast strzały (po _ready pocisku); trafienie - drzazgi strzały w barwie kamienia.
static func stone_look(b: ProtoArrow) -> void:
	var s: Sprite2D = b._sprite
	s.texture = STONE_TEX
	s.hframes = 1
	s.frame = 0
	s.rotation = 0.0
	s.offset = -Vector2(STONE_TEX.get_width(), STONE_TEX.get_height()) / 2.0
	s.modulate = Color.WHITE

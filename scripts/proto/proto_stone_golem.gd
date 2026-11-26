class_name ProtoStoneGolem
extends ProtoGoblinBrute
## Skalny golem - silny potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026; liczby - Claude): ożywiona
## bryła skały z żyłami kruszcu. Jak goblin osiłek (czerwone koło przed nim, trafienie nie przerywa zamachu), ale
## jeszcze wolniejszy, cięższy i silniejszy: wali pięścią w ziemię (ziemia), a z koła wyskakują skalne kolce (slam_spikes
## młota) i rozchodzi się wstrząs. Król Karłów przyzywa golemy (`minion_kind` brute). Nie piszczy przy ucieczce.
## Grafika: assets/spritekiln/stone_golem/stone_golem.tscn (idle, walk, attack ze zdarzeniem `hit` ok. 0,75 s, hit,
## death); do czasu grafiki - zastępczy kolor.

const STONEGOLEM_SCENE := "res://assets/spritekiln/stone_golem/stone_golem.tscn"
const GOLEM_HP := 240
const GOLEM_SPEED := 17.0
const GOLEM_DAMAGE := 30
const SPIKES_FX := preload("res://assets/effects/slam_spikes.png")
const SPIKES_FRAMES := 18
const SPIKES_ANCHOR := Vector2(30, 34)


func _init() -> void:
	super()
	scene_path = STONEGOLEM_SCENE
	max_hp = GOLEM_HP
	speed = GOLEM_SPEED
	damage = GOLEM_DAMAGE
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.5, 0.48, 0.45)
	anim_hit_at = 0.75  # pięść spada w animacji `attack` po ok. 0,75 s (zdarzenie `hit`)
	shadow_scale = 1.4


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		Fx.once(get_parent(), SPIKES_FX, SPIKES_FRAMES, 22.0, at.round(), SPIKES_ANCHOR, 2, 0.7)


## Bardzo ciężki: odepchnięcie jeszcze słabsze niż u osiłka.
func push_away(from: Vector2, force: float) -> void:
	super(from, force * 0.5)

class_name ProtoRuneGolem
extends ProtoGoblinBrute
## Runiczny golem - silny potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): konstrukt z ciemnych
## kamiennych bloków spiętych żelazem, z wyrytymi fioletowymi runami i kryształem w piersi. Jak goblin osiłek (wolny,
## wytrzymały, czerwone koło przed nim, trafienie nie przerywa zamachu), ale silniejszy: bije pięścią w ziemię - cios
## Arkanami, a w kole rozbłyska wybuch pieczęci (arcane_blast Księgi Arkanów). Nie piszczy przy ucieczce.
## Grafika: assets/spritekiln/rune_golem/rune_golem.tscn (idle, walk, attack ze zdarzeniem `hit` ok. 0,75 s, hit,
## death); do czasu grafiki - zastępczy kolor.

const RUNEGOLEM_SCENE := "res://assets/spritekiln/rune_golem/rune_golem.tscn"
const GOLEM_HP := 220
const GOLEM_SPEED := 20.0
const GOLEM_DAMAGE := 27
const BLAST_FX := preload("res://assets/effects/arcane_blast.png")


func _init() -> void:
	super()
	scene_path = RUNEGOLEM_SCENE
	max_hp = GOLEM_HP
	speed = GOLEM_SPEED
	damage = GOLEM_DAMAGE
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.4, 0.35, 0.55)
	anim_hit_at = 0.75  # pięść spada w animacji `attack` po ok. 0,75 s (zdarzenie `hit`)


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		var fx := Fx.once(get_parent(), BLAST_FX, 9, 18.0, at.round(), Vector2(36, 20), 2, SLAM_RADIUS / 34.0)
		fx.modulate.a = 0.9

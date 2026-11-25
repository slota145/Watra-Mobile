class_name ProtoIceGiant
extends ProtoGoblinBrute
## Lodowy olbrzym - silny potwór Lodowych jaskiń (Dungeons.FROST, ustalone z autorem 25.11.2026): jak goblin osiłek
## (wolny, wytrzymały, czerwone koło przed nim, trafienie nie przerywa zamachu), ale uderza obiema pięściami z lodu:
## cios lodem, a trafiona postać na chwilę prawie zamarza (spowolnienie FREEZE_SLOW na FREEZE_TIME s) i dostaje dużo
## chłodu (ProtoFrost.chill_hero); w kole pęka lód (frost_shatter). Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/ice_giant/ice_giant.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const GIANT_SCENE := "res://assets/spritekiln/ice_giant/ice_giant.tscn"
const GIANT_HP := 190
const GIANT_SPEED := 22.0
const GIANT_DAMAGE := 26
const FREEZE_SLOW := 0.6
const FREEZE_TIME := 1.2
const COLD := 25.0
const SHATTER_FX := preload("res://assets/effects/frost_shatter.png")


func _init() -> void:
	super()
	scene_path = GIANT_SCENE
	max_hp = GIANT_HP
	speed = GIANT_SPEED
	damage = GIANT_DAMAGE
	element = Elements.COLD
	squeaks = false
	fallback_color = Color(0.55, 0.75, 0.95)
	anim_hit_at = 0.75  # pięści spadają w animacji `attack` (zdarzenie `hit`)


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		Fx.once(get_parent(), SHATTER_FX, 10, 16.0, at.round(), Vector2(31, 29), 20, SLAM_RADIUS / 26.0 * 0.8)


func _hit_hero() -> void:
	hero.slow(FREEZE_SLOW, FREEZE_TIME, Elements.COLORS[Elements.COLD])
	ProtoFrost.chill_hero(hero, COLD)

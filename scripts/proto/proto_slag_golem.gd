class_name ProtoSlagGolem
extends ProtoGoblinBrute
## Żużlowy golem - silny potwór Wulkanicznych równin (Dungeons.VOLCANO, ustalone z autorem 15.11.2026): jak goblin
## osiłek (wolny, wytrzymały, czerwone koło przed nim, trafienie nie przerywa zamachu), ale uderza pięściami
## z lawy: cios ogniem, a w kole zostaje na PATCH_TIME s płonąca ziemia (ProtoFirePatch - podpala). Nie piszczy
## przy ucieczce. Grafika: assets/spritekiln/slag_golem/slag_golem.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const GOLEM_SCENE := "res://assets/spritekiln/slag_golem/slag_golem.tscn"
const GOLEM_HP := 180
const GOLEM_SPEED := 24.0
const GOLEM_DAMAGE := 24
const PATCH_TIME := 3.0
const BURN := 4


func _init() -> void:
	super()
	scene_path = GOLEM_SCENE
	max_hp = GOLEM_HP
	speed = GOLEM_SPEED
	damage = GOLEM_DAMAGE
	element = Elements.FIRE
	squeaks = false
	fallback_color = Color(0.35, 0.28, 0.25)
	anim_hit_at = 0.7  # pięści spadają w animacji `attack` po 0,7 s (zdarzenie `hit`)


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		ProtoFirePatch.spawn(get_parent(), at, hero, SLAM_RADIUS, PATCH_TIME, roundi(BURN * power))

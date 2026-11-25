class_name ProtoWildTreant
extends ProtoGoblinBrute
## Dziki drzewiec - silny potwór Prastarego Boru (Dungeons.FOREST, ustalone z autorem 25.11.2026; inny niż przyjazne
## drzewce Kostura Leszego): jak goblin osiłek (wolny, wytrzymały, czerwone koło przed nim, trafienie nie przerywa
## zamachu), ale bije szponami z korzeni - cios naturą, a trafioną postać korzenie na chwilę trzymają (spowolnienie
## ROOT_SLOW na ROOT_TIME s); w kole wybuchają korzenie (leshy_roots z Watry). Leszy budzi go okrzykiem. Nie piszczy przy
## ucieczce. Grafika: assets/spritekiln/wild_treant/wild_treant.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const WILD_SCENE := "res://assets/spritekiln/wild_treant/wild_treant.tscn"
const WILD_HP := 200
const WILD_SPEED := 22.0
const WILD_DAMAGE := 26
const ROOT_SLOW := 0.7
const ROOT_TIME := 1.0
const ROOTS_FX := preload("res://assets/watra/effects/leshy_roots.png")


func _init() -> void:
	super()
	scene_path = WILD_SCENE
	max_hp = WILD_HP
	speed = WILD_SPEED
	damage = WILD_DAMAGE
	element = Elements.NATURE
	squeaks = false
	fallback_color = Color(0.3, 0.26, 0.22)
	anim_hit_at = 0.74  # szpony spadają w animacji `attack` po 0,74 s (zdarzenie `hit`)


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		Fx.once(get_parent(), ROOTS_FX, 10, 16.0, at.round(), Vector2(24, 39), 20, SLAM_RADIUS / 22.0)


func _hit_hero() -> void:
	hero.slow(ROOT_SLOW, ROOT_TIME, Elements.COLORS[Elements.NATURE])

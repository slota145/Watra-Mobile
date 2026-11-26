class_name ProtoKumir
extends ProtoGoblinBrute
## Kumir - silny potwór Świątyni Słońca (Dungeons.TEMPLE, ustalone z autorem 26.11.2026): ożywiony kamienny posąg-bożek
## z piaskowca, z płaską twarzą-maską i złotym znakiem słońca na piersi; przez pęknięcia prześwituje światło. Jak goblin
## osiłek (wolny, wytrzymały, czerwone koło przed nim, trafienie nie przerywa zamachu), ale jeszcze wolniejszy i silniejszy:
## bije obiema pięściami w ziemię - cios Prawią, a w kole rozbłyska pierścień światła (sun_ring włóczni). Swarożyc go nie
## budzi. Nie piszczy przy ucieczce. Grafika: assets/spritekiln/kumir/kumir.tscn (idle, walk, attack ze zdarzeniem
## `hit`, hit, death); do czasu grafiki - zastępczy kolor.

const KUMIR_SCENE := "res://assets/spritekiln/kumir/kumir.tscn"
const KUMIR_HP := 230
const KUMIR_SPEED := 19.0
const KUMIR_DAMAGE := 28
const RING_FX := preload("res://assets/effects/sun_ring.png")


func _init() -> void:
	super()
	scene_path = KUMIR_SCENE
	max_hp = KUMIR_HP
	speed = KUMIR_SPEED
	damage = KUMIR_DAMAGE
	element = Elements.PRAWIA
	squeaks = false
	fallback_color = Color(0.78, 0.66, 0.46)
	anim_hit_at = 0.75  # pięści spadają w animacji `attack` po ok. 0,75 s (zdarzenie `hit`)


func _strike() -> void:
	var at := _telegraph.global_position if _telegraph and is_instance_valid(_telegraph) else global_position
	super()
	if get_parent():
		var fx := Fx.once(get_parent(), RING_FX, 8, 16.0, at.round(), Vector2(58, 25), 2, SLAM_RADIUS / 50.0)
		fx.modulate.a = 0.85

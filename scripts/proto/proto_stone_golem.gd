class_name ProtoStoneGolem
extends ProtoGoblinBrute
## Skalny golem - silny potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026): powolny, ciężki.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/stone_golem/stone_golem.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const STONEGOLEM_SCENE := "res://assets/spritekiln/stone_golem/stone_golem.tscn"


func _init() -> void:
	super()
	scene_path = STONEGOLEM_SCENE
	max_hp = 220
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.5, 0.48, 0.45)

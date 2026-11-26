class_name ProtoRuneGolem
extends ProtoGoblinBrute
## Runiczny golem - silny potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): konstrukt z runami.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/rune_golem/rune_golem.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const RUNEGOLEM_SCENE := "res://assets/spritekiln/rune_golem/rune_golem.tscn"


func _init() -> void:
	super()
	scene_path = RUNEGOLEM_SCENE
	max_hp = 220
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.4, 0.35, 0.55)

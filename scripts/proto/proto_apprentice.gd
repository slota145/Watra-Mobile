class_name ProtoApprentice
extends ProtoGoblinArcher
## Uczeń czarnoksiężnika - strzelający potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): strzela magicznymi pociskami.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/apprentice/apprentice.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const APPRENTICE_SCENE := "res://assets/spritekiln/apprentice/apprentice.tscn"


func _init() -> void:
	super()
	scene_path = APPRENTICE_SCENE
	max_hp = 26
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.7, 0.5, 0.95)

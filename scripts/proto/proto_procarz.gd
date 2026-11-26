class_name ProtoProcarz
extends ProtoGoblinArcher
## Karzeł-procarz - strzelający potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026): rzuca kamieniami z procy.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/procarz/procarz.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const PROCARZ_SCENE := "res://assets/spritekiln/procarz/procarz.tscn"


func _init() -> void:
	super()
	scene_path = PROCARZ_SCENE
	max_hp = 26
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.6, 0.45, 0.3)

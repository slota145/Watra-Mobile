class_name ProtoKretolak
extends ProtoGoblin
## Kretołak - zwykły potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026): szybki, wyskakuje spod ziemi.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/kretolak/kretolak.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const KRETOLAK_SCENE := "res://assets/spritekiln/kretolak/kretolak.tscn"


func _init() -> void:
	scene_path = KRETOLAK_SCENE
	max_hp = 30
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.45, 0.35, 0.3)

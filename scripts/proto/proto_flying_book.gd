class_name ProtoFlyingBook
extends ProtoGoblin
## Latająca księga - zwykły potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): szybka, gryząca.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: assets/spritekiln/flying_book/flying_book.tscn
## (idle, walk, attack, hit, death); do czasu grafiki - zastępczy kolor.

const FLYINGBOOK_SCENE := "res://assets/spritekiln/flying_book/flying_book.tscn"


func _init() -> void:
	scene_path = FLYINGBOOK_SCENE
	max_hp = 28
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.55, 0.35, 0.75)

class_name ProtoSkeletonArcher
extends ProtoGoblinArcher
## Szkielet łucznik - strzelający potwór Katakumb (Dungeons.CATACOMBS, ustalone z autorem 15.11.2026): jak goblin
## łucznik (dystans, linia celu, przerwanie trafieniem), ale strzela fioletową strzałą Nawii (odporność na żywioły
## ją zmniejsza). Nie piszczy przy ucieczce. Grafika: assets/spritekiln/skeleton_archer/skeleton_archer.tscn
## (idle, walk, attack ze zdarzeniem `release`, hit, death).

const SKELETON_ARCHER_SCENE := "res://assets/spritekiln/skeleton_archer/skeleton_archer.tscn"
const SKELETON_ARCHER_HP := 28
const NAWIA_ARROW_DAMAGE := 10


func _init() -> void:
	super()
	scene_path = SKELETON_ARCHER_SCENE
	max_hp = SKELETON_ARCHER_HP
	damage = NAWIA_ARROW_DAMAGE
	element = Elements.NAWIA
	squeaks = false
	fallback_color = Color(0.75, 0.7, 0.85)

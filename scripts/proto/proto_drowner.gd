class_name ProtoDrowner
extends ProtoGoblin
## Topielec - zwykły potwór Zatopionych podziemi (Dungeons.FLOODED, ustalone z autorem 15.11.2026): jak goblin
## z tasakiem idzie do Wojciecha i drapie z bliska, ale jest wolniejszy i wytrzymalszy, bije wodą (odporność
## na żywioły zmniejsza cios) i trafienie przemacza postać - spowalnia ją o SOAK_SLOW na SOAK_TIME s.
## Nie piszczy przy ucieczce przed Wodnikiem. Grafika: assets/spritekiln/drowner/drowner.tscn (idle, walk,
## attack ze zdarzeniem `hit`, hit, death).

const DROWNER_SCENE := "res://assets/spritekiln/drowner/drowner.tscn"
const DROWNER_HP := 48
const DROWNER_SPEED := 30.0
const DROWNER_DAMAGE := 11
const SOAK_SLOW := 0.25
const SOAK_TIME := 2.0


func _init() -> void:
	scene_path = DROWNER_SCENE
	max_hp = DROWNER_HP
	speed = DROWNER_SPEED
	damage = DROWNER_DAMAGE
	element = Elements.WATER
	squeaks = false
	fallback_color = Color(0.55, 0.7, 0.78)


func _hit_hero() -> void:
	hero.slow(SOAK_SLOW, SOAK_TIME, Elements.COLORS[Elements.WATER].lerp(Color.WHITE, 0.4))

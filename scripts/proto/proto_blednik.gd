class_name ProtoBlednik
extends ProtoGoblin
## Błędnik - zwykły potwór Prastarego Boru (Dungeons.FOREST, ustalone z autorem 25.11.2026): błędny ognik, duch lasu.
## Szybki i słaby, unosi się nad ziemią, doskakuje i parzy zielonym ogniem natury (odporność na żywioły zmniejsza
## cios), a trafienie przypala postać na chwilę (ProtoHero.ignite). Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/blednik/blednik.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const BLEDNIK_SCENE := "res://assets/spritekiln/blednik/blednik.tscn"
const BLEDNIK_HP := 30
const BLEDNIK_SPEED := 44.0
const BLEDNIK_DAMAGE := 9
const BURN := 2
const BURN_TIME := 2.0


func _init() -> void:
	scene_path = BLEDNIK_SCENE
	max_hp = BLEDNIK_HP
	speed = BLEDNIK_SPEED
	damage = BLEDNIK_DAMAGE
	element = Elements.NATURE
	squeaks = false
	fallback_color = Color(0.7, 1.0, 0.45)


func _hit_hero() -> void:
	hero.ignite(roundi(BURN * power), BURN_TIME)

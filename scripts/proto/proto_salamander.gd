class_name ProtoSalamander
extends ProtoGoblin
## Salamandra - zwykły potwór Wulkanicznych równin (Dungeons.VOLCANO, ustalone z autorem 15.11.2026): szybka
## ognista jaszczurka, słabsza od goblina; ugryzienie bije ogniem i podpala postać (ProtoHero.ignite). Nie piszczy
## przy ucieczce. Grafika: assets/spritekiln/salamander/salamander.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const SALAMANDER_SCENE := "res://assets/spritekiln/salamander/salamander.tscn"
const SALAMANDER_HP := 32
const SALAMANDER_SPEED := 50.0
const SALAMANDER_DAMAGE := 8
## Obrażenia jednego płomienia podpalenia i czas.
const BURN := 3
const BURN_TIME := 3.0


func _init() -> void:
	scene_path = SALAMANDER_SCENE
	max_hp = SALAMANDER_HP
	speed = SALAMANDER_SPEED
	damage = SALAMANDER_DAMAGE
	element = Elements.FIRE
	squeaks = false
	fallback_color = Color(0.95, 0.45, 0.15)


func _hit_hero() -> void:
	hero.ignite(roundi(BURN * power), BURN_TIME)

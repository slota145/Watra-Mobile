class_name ProtoPoludnica
extends ProtoGoblin
## Południca - zwykły potwór Świątyni Słońca (Dungeons.TEMPLE, ustalone z autorem 26.11.2026): słowiański duch południa
## w białej sukni, ze słomkowymi włosami, wiankiem z kłosów i sierpem. Szybka, sunie nad posadzką; cięcie sierpem bije
## Prawią (odporność na żywioły zmniejsza cios) i oślepia postać (ProtoHero.blind - słabsze ciosy przez BLIND_TIME s).
## Nie piszczy przy ucieczce. Grafika: assets/spritekiln/poludnica/poludnica.tscn (idle, walk, attack ze zdarzeniem
## `hit`, hit, death); do czasu grafiki - zastępczy kolor.

const POLUDNICA_SCENE := "res://assets/spritekiln/poludnica/poludnica.tscn"
const POLUDNICA_HP := 34
const POLUDNICA_SPEED := 46.0
const POLUDNICA_DAMAGE := 11
const BLIND_TIME := 1.5


func _init() -> void:
	scene_path = POLUDNICA_SCENE
	max_hp = POLUDNICA_HP
	speed = POLUDNICA_SPEED
	damage = POLUDNICA_DAMAGE
	element = Elements.PRAWIA
	squeaks = false
	fallback_color = Color(1.0, 0.95, 0.75)


func _hit_hero() -> void:
	hero.blind(BLIND_TIME)

class_name ProtoZmarzlak
extends ProtoGoblin
## Zmarzlak - zwykły potwór Lodowych jaskiń (Dungeons.FROST, ustalone z autorem 25.11.2026): zamarznięty trup dawnego
## wojownika z oszronionym toporem. Jak goblin idzie do postaci i rąbie z bliska, ale wolniej i wytrzymalej, bije
## lodem (odporność na żywioły zmniejsza cios), a trafienie spowalnia postać o CHILL_SLOW na CHILL_TIME s i dokłada
## chłodu (ProtoFrost.chill_hero). Nie piszczy przy ucieczce. Grafika: assets/spritekiln/zmarzlak/zmarzlak.tscn
## (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const ZMARZLAK_SCENE := "res://assets/spritekiln/zmarzlak/zmarzlak.tscn"
const ZMARZLAK_HP := 50
const ZMARZLAK_SPEED := 28.0
const ZMARZLAK_DAMAGE := 12
const CHILL_SLOW := 0.25
const CHILL_TIME := 2.0
const COLD := 10.0


func _init() -> void:
	scene_path = ZMARZLAK_SCENE
	max_hp = ZMARZLAK_HP
	speed = ZMARZLAK_SPEED
	damage = ZMARZLAK_DAMAGE
	element = Elements.COLD
	squeaks = false
	fallback_color = Color(0.62, 0.78, 0.92)


func _hit_hero() -> void:
	hero.slow(CHILL_SLOW, CHILL_TIME, Elements.COLORS[Elements.COLD])
	ProtoFrost.chill_hero(hero, COLD)

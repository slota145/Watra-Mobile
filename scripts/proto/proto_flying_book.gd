class_name ProtoFlyingBook
extends ProtoGoblin
## Latająca księga - zwykły potwór Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): ożywiona księga
## zaklęć z kłapiącymi okładkami i zębami z kartek. Szybka (szybsza od goblina), podlatuje i gryzie - cios Arkanami
## (odporność na żywioły zmniejsza), który wysysa trochę many postaci (BITE_DRAIN, fioletowy napis). Nie piszczy przy
## ucieczce. Grafika: assets/spritekiln/flying_book/flying_book.tscn (idle, walk, attack ze zdarzeniem `hit` ok. 0,4 s,
## hit, death); do czasu grafiki - zastępczy kolor.

const FLYINGBOOK_SCENE := "res://assets/spritekiln/flying_book/flying_book.tscn"
const BOOK_HP := 28
const BOOK_SPEED := 50.0
const BOOK_DAMAGE := 9
const BITE_DRAIN := 5
## Bez grafiki: ugryzienie po tylu sekundach zamachu (jak zdarzenie `hit` animacji).
const BITE_AT := 0.4

## Ile razy księga wyssała manę (testy).
var drains := 0


func _init() -> void:
	scene_path = FLYINGBOOK_SCENE
	max_hp = BOOK_HP
	speed = BOOK_SPEED
	damage = BOOK_DAMAGE
	element = Elements.ARCANE
	squeaks = false
	fallback_color = Color(0.55, 0.35, 0.75)
	strike_time = BITE_AT
	attack_time = BITE_AT + 0.25


## Ugryzienie wysysa manę.
func _hit_hero() -> void:
	if hero.mana <= 0:
		return
	var lost := mini(BITE_DRAIN, hero.mana)
	hero.mana -= lost
	hero.mana_changed.emit(hero.mana, hero.max_mana)
	drains += 1

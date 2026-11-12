class_name HeroLevels
## Poziomy doświadczenia postaci (ustalone z autorem 12.11.2026): doświadczenie za każdego pokonanego goblina
## i dużo za Wodza Goblinów (więcej na wyższych poziomach lochu). Śmierć nie zabiera zdobytego doświadczenia.
## Awans daje statystyki (więcej zdrowia, many i obrażeń, pełne leczenie), a na wybranych poziomach odblokowuje kolejne
## miejsce na umiejętność (`SKILL_SLOT_LEVELS`). Stan postaci (poziom, doświadczenie) trzyma i zapisuje `Game`.

## Najwyższy poziom postaci (na razie - do rozbudowy razem z lochami).
const MAX_LEVEL := 50
## Doświadczenie na awans z poziomu n: BASE * n^POW (1->2: 50, 2->3: 132, 5->6: 476, 10->11: 1256).
const XP_BASE := 50.0
const XP_POW := 1.4
## Zdrowie na 1. poziomie i przyrost na każdy kolejny.
const HP_BASE := 100
const HP_STEP := 10
## Mana na 1. poziomie i przyrost na każdy kolejny (prośba autora: pasek many; zużyją ją umiejętności).
const MANA_BASE := 50
const MANA_STEP := 5
## Mnożnik obrażeń broni rośnie o tyle na poziom (+6%).
const DAMAGE_STEP := 0.06
## Na tych poziomach odblokowują się kolejne miejsca na umiejętności (w kolejności od boku ekranu do góry).
const SKILL_SLOT_LEVELS := [3, 6, 10, 15]
## Doświadczenie za goblina i za Wodza na 1. poziomie lochu (rośnie z siłą lochu - DungeonLevels.power).
const GOBLIN_XP := 2.0
const CHIEF_XP := 60.0


## Ile doświadczenia trzeba zebrać na poziomie `level`, żeby awansować.
static func xp_to_next(level: int) -> int:
	return roundi(XP_BASE * pow(maxi(level, 1), XP_POW))


## Największe zdrowie postaci na danym poziomie.
static func max_hp(level: int) -> int:
	return HP_BASE + HP_STEP * (maxi(level, 1) - 1)


## Największa mana postaci na danym poziomie.
static func max_mana(level: int) -> int:
	return MANA_BASE + MANA_STEP * (maxi(level, 1) - 1)


## Mnożnik obrażeń broni na danym poziomie (1. poziom - 1.0).
static func damage_mult(level: int) -> float:
	return 1.0 + DAMAGE_STEP * (maxi(level, 1) - 1)


## Ile miejsc na umiejętności jest odblokowanych na danym poziomie.
static func skill_slots(level: int) -> int:
	var n := 0
	for l in SKILL_SLOT_LEVELS:
		if level >= l:
			n += 1
	return n


## Doświadczenie za pokonanego goblina na danym poziomie lochu.
static func goblin_xp(dungeon_level: int) -> int:
	return roundi(GOBLIN_XP * DungeonLevels.power(dungeon_level))


## Doświadczenie za Wodza Goblinów na danym poziomie lochu.
static func chief_xp(dungeon_level: int) -> int:
	return roundi(CHIEF_XP * DungeonLevels.power(dungeon_level))

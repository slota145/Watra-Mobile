class_name Skills
## Umiejętności miecza (ustalone z autorem 12.11.2026). Zwykły cios też jest umiejętnością: można go przestawić,
## a na jego miejsce pod dużym przyciskiem dać inną - wtedy ta podlega auto atakowi. Gdy umiejętności pod dużym
## przyciskiem brakuje many albo się odnawia, miecz tnie zwykłym ciosem. Pozostałe kupuje się za złoto przy kamieniu
## run w bazie (cena i wymagany poziom postaci), a przypisuje w oknie umiejętności (SkillsWindow).
## Kupione i miejsca trzyma i zapisuje Game (`skills_owned`, `skill_slots`). Działanie - ProtoWeapon.

## Zwykły cios (darmowy, zawsze kupiony).
const STRIKE := "strike"
## Miejsca: 0 - duży przycisk (atak), 1-4 - małe miejsca wokół niego (odblokowane z poziomem - HeroLevels).
const SLOTS := 5
const MAIN := 0

## name - nazwa, icon - ikona, mana - koszt, cooldown - odnowienie (s), price - złoto, level - wymagany poziom postaci,
## main - czy może stać pod dużym przyciskiem (auto atak), range - z jakiej odległości auto atak jej używa (stopy-stopy),
## power - obrażenia jako wielokrotność zwykłego cięcia (w Młynku - na jedno trafienie).
const DATA := {
	"strike": {
		"name": "Zwykły cios", "icon": preload("res://assets/watra/iron_sword_icon.png"),
		"mana": 0, "cooldown": 0.0, "price": 0, "level": 1, "main": true, "range": 48.0, "power": 1.0,
		"description": "Miecz tnie po łuku najbliższego wroga.",
	},
	"whirl": {
		"name": "Młynek", "icon": preload("res://assets/watra/skills/whirlwind.png"),
		"mana": 25, "cooldown": 8.0, "price": 100, "level": 3, "main": true, "range": 40.0, "power": 0.6,
		"description": "Miecz wiruje wokół ciebie przez 3 s i rani wszystkich dookoła. Możesz przy tym chodzić.",
	},
	"throw": {
		"name": "Rzut mieczem", "icon": preload("res://assets/watra/skills/lunge.png"),
		"mana": 15, "cooldown": 4.0, "price": 300, "level": 6, "main": true, "range": 120.0, "power": 1.5,
		"description": "Miecz leci w najbliższego wroga, przebija wszystkich po drodze i wraca, raniąc ich drugi raz.",
	},
	"slam": {
		"name": "Rozłupanie Ziemi", "icon": preload("res://assets/watra/skills/ground_slam.png"),
		"mana": 25, "cooldown": 7.0, "price": 800, "level": 10, "main": true, "range": 70.0, "power": 2.2,
		"description": "Miecz spada z góry na wrogów: fala pęknięć rani wszystkich wokół i na chwilę ich ogłusza.",
	},
	"blink": {
		"name": "Mgnienie", "icon": preload("res://assets/watra/skills/flicker.png"),
		"mana": 15, "cooldown": 5.0, "price": 1500, "level": 15, "main": false, "range": 0.0, "power": 1.2,
		"description": "Doskok w stronę, w którą idziesz, z cięciem wszystkich po drodze. Ratuje z okrążenia. Nie może stać pod dużym przyciskiem.",
	},
}
## Kolejność w oknie umiejętności.
const ORDER := ["strike", "whirl", "throw", "slam", "blink"]


static func has(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id].name) if DATA.has(id) else ""


static func icon_of(id: String) -> Texture2D:
	return DATA[id].icon if DATA.has(id) else null


static func mana_of(id: String) -> int:
	return DATA[id].mana if DATA.has(id) else 0


static func cooldown_of(id: String) -> float:
	return DATA[id].cooldown if DATA.has(id) else 0.0


static func price_of(id: String) -> int:
	return DATA[id].price if DATA.has(id) else 0


static func level_of(id: String) -> int:
	return DATA[id].level if DATA.has(id) else 1


## Czy umiejętność może stać pod dużym przyciskiem (Mgnienie - nie: auto atak wrzucałby postać w hordę).
static func can_be_main(id: String) -> bool:
	return id == "" or (DATA.has(id) and DATA[id].main)


## Ile miejsc (razem z dużym przyciskiem) jest odblokowanych na danym poziomie postaci.
static func open_slots(hero_level: int) -> int:
	return 1 + HeroLevels.skill_slots(hero_level)

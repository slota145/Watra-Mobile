class_name Weapons
## Rodzaje broni i mistrzostwo broni (ustalone z autorem 13.11.2026). Gracz używa jednej broni naraz (zmiana w bazie);
## każda ma własne umiejętności (Skills, pole "weapon") i własne mistrzostwo. Mistrzostwo rośnie od potworów pokonanych
## tą bronią i od bossów (tyle samo co doświadczenie postaci - arena.gd `_gain_xp`) i odblokowuje kolejne umiejętności
## (próg w Skills, pole "mastery") oraz pozwala ulepszać je wyżej (Skills.level_cap). Stan: `Game.weapon`,
## `Game.mastery` (broń -> poziom), `Game.mastery_xp` (broń -> doświadczenie na tym poziomie).
## Nowe rodzaje broni (łuk, hydrosfera, mroczna kosa…) odblokowuje postęp: pokonanie Wodza na poziomie `unlock`
## (za darmo), a wcześniej można je kupić za `price` złota (decyzja autora 13.11.2026). Zmiana broni w oknie
## umiejętności przy kamieniu run (Game.set_weapon, Game.buy_weapon). Węzeł broni w lochu: miecz - ProtoWeapon,
## glewia ognia - ProtoGlaive, hydrosfera - ProtoHydrosphere (`make`).

const SWORD := "sword"
const GLAIVE := "glaive"
const HYDROSPHERE := "hydrosphere"
## name - nazwa, element - żywioł obrażeń (Elements), unlock - poziom lochu, po którego przebiciu broń jest za darmo
## (0 - od początku), price - złoto za wcześniejsze odblokowanie.
const DATA := {
	"sword": {"name": "Miecz", "element": Elements.PHYSICAL, "unlock": 0, "price": 0,
		"icon": preload("res://assets/watra/iron_sword_icon.png")},
	"glaive": {"name": "Glewia ognia", "short": "Glewia", "element": Elements.FIRE, "unlock": 10, "price": 3000,
		"icon": preload("res://assets/skills/glaive/g_thrust.png")},
	"hydrosphere": {"name": "Hydrosfera", "element": Elements.WATER, "unlock": 15, "price": 4500,
		"icon": preload("res://assets/skills/hydro/h_bolt.png")},
}
const ORDER := ["sword", "glaive", "hydrosphere"]
## Najwyższy poziom mistrzostwa (jak poziom postaci).
const MAX_MASTERY := 50


static func has(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id].name) if DATA.has(id) else ""


static func element_of(id: String) -> String:
	return DATA[id].element if DATA.has(id) else Elements.PHYSICAL


## Czy broń jest dostępna bez kupowania przy danym najwyższym przebitym poziomie lochu.
static func unlocked_by(id: String, best_level: int) -> bool:
	return DATA.has(id) and best_level >= int(DATA[id].unlock)


## Krótka nazwa (przycisk broni w oknie umiejętności).
static func short_name_of(id: String) -> String:
	return Lang.t(DATA[id].get("short", DATA[id].name)) if DATA.has(id) else ""


static func icon_of(id: String) -> Texture2D:
	return DATA[id].icon if DATA.has(id) else null


## Poziom lochu, po którego przebiciu broń jest za darmo.
static func unlock_level(id: String) -> int:
	return DATA[id].unlock if DATA.has(id) else 0


## Skrypt węzła broni do walki (miecz - ProtoWeapon, glewia - ProtoGlaive, hydrosfera - ProtoHydrosphere).
static func script_of(id: String) -> Script:
	match id:
		GLAIVE:
			return ProtoGlaive
		HYDROSPHERE:
			return ProtoHydrosphere
	return ProtoWeapon


## Nowy węzeł broni do walki.
static func make(id: String) -> ProtoWeapon:
	return script_of(id).new()


static func price_of(id: String) -> int:
	return DATA[id].price if DATA.has(id) else 0


## Doświadczenie mistrzostwa potrzebne do następnego poziomu (ta sama krzywa co poziomy postaci).
static func xp_to_next(level: int) -> int:
	return HeroLevels.xp_to_next(level)

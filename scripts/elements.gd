class_name Elements
## Żywioły (ustalone z autorem 13.11.2026; pomysł i system z Watry - `scripts/elements.gd` Watry). Rodzaj obrażeń:
## fizyczne (miecz, zwykła stal) albo jeden z ośmiu żywiołów: ogień, woda, lód, Grom (pioruny), ziemia, powietrze,
## Nawia (ciemność) i natura (trucizna, później pnącza i ciernie). Na razie fundament: nazwy, kolory, odporności
## potworów i liczenie obrażeń z odpornością (`reduce`). Działanie każdego żywiołu (EFFECTS - opis ustalony z autorem)
## dochodzi razem z bronią, która go używa; potwory na razie biją fizycznie, a bohater nie ma odporności (decyzja
## autora 13.11.2026 - odporności bohatera z przedmiotów, jak w Watrze, później).

const PHYSICAL := "physical"
const FIRE := "fire"
const WATER := "water"
const COLD := "cold"
const LIGHTNING := "lightning"
const EARTH := "earth"
const AIR := "air"
const NAWIA := "nawia"
const NATURE := "nature"
## Arkana (decyzja autora 21.11.2026): magia Księgi Arkanów - fioletowo-białe efekty, trafienia wysysają manę
## (ARCANE_LEECH obrażeń, najwyżej ARCANE_LEECH_MAX many na trafienie; ProtoWeapon._deal).
const ARCANE := "arcane"
const ARCANE_LEECH := 0.03
const ARCANE_LEECH_MAX := 3
## Nawia (mroczna kosa, ustalone z autorem 21.11.2026): trafienia wysysają życie (NAWIA_LEECH obrażeń, najwyżej
## NAWIA_LEECH_MAX zdrowia na trafienie; ProtoWeapon._deal), a trafiony wróg przez NAWIA_WEAK_TIME s zadaje o NAWIA_WEAK
## mniej obrażeń (ProtoTarget.wither - ciemna mgiełka nad głową).
const NAWIA_LEECH := 0.02
const NAWIA_LEECH_MAX := 4
const NAWIA_WEAK := 0.15
const NAWIA_WEAK_TIME := 2.0
## Żywioły (bez fizycznych) w kolejności do pokazywania.
const ALL: Array[String] = [FIRE, WATER, COLD, LIGHTNING, EARTH, AIR, NAWIA, NATURE, ARCANE]
const NAMES := {PHYSICAL: "Fizyczne", FIRE: "Ogień", WATER: "Woda", COLD: "Lód", LIGHTNING: "Grom", EARTH: "Ziemia",
		AIR: "Powietrze", NAWIA: "Nawia", NATURE: "Natura", ARCANE: "Arkana"}
## Kolory liczb obrażeń, ikon i efektów (ogień, lód i Nawia jak w Watrze; Grom niebieski jak pioruny w grze - 17.11.2026).
const COLORS := {PHYSICAL: Color(1.0, 0.95, 0.85), FIRE: Color(1.0, 0.55, 0.2), WATER: Color(0.3, 0.6, 1.0),
		COLD: Color(0.7, 0.95, 1.0), LIGHTNING: Color(0.45, 0.7, 1.0), EARTH: Color(0.75, 0.55, 0.3),
		AIR: Color(0.8, 1.0, 0.9), NAWIA: Color(0.7, 0.45, 1.0), NATURE: Color(0.55, 0.95, 0.35),
		ARCANE: Color(0.9, 0.7, 1.0)}
## Co robi żywioł (ustalone z autorem 13.11.2026; działanie w grze - razem z bronią danego żywiołu).
const EFFECTS := {
	FIRE: "Podpala: obrażenia przez kilka sekund.",
	WATER: "Przemacza: wróg jest wolniejszy i dostaje więcej od Gromu i lodu.",
	COLD: "Spowalnia, a po kilku trafieniach zamraża na chwilę.",
	LIGHTNING: "Poraża: wróg dostaje więcej obrażeń, piorun przeskakuje na sąsiada.",
	EARTH: "Ogłusza i odpycha.",
	AIR: "Odpycha albo ściąga wrogów w jedno miejsce.",
	NAWIA: "Wysysa życie i osłabia ciosy wroga.",
	NATURE: "Truje - trucizna kumuluje się z każdym trafieniem.",
	ARCANE: "Wysysa manę: trafienia oddają trochę many.",
}
## Odporność: ułamek zmniejszający obrażenia danego żywiołu (ujemny - wrażliwość). Granice jak w Watrze.
const MAX_RESISTANCE := 0.75
const MIN_RESISTANCE := -1.0
## Combo żywiołów (np. woda + Grom) i wrażliwości nie mogą razem pomnożyć obrażeń bardziej niż tyle razy
## (pilnowanie balansu - żeby dwa połączone żywioły nie mnożyły obrażeń bez końca).
const MAX_MULT := 2.0
## Combo z przemoczeniem (ustalone z autorem 15.11.2026, wariant „oba”): przemoczony wróg dostaje od Gromu i lodu
## o SOAK_BONUS więcej, piorun z przemoczonego przeskakuje na SOAK_CHAIN_EXTRA wrogów więcej, a lód (kamień Szron)
## zamraża przemoczonego na SOAK_FREEZE s. Porażony wróg (Grom) dostaje od wszystkiego o SHOCK_BONUS więcej.
const SOAK_BONUS := 1.3
const SOAK_CHAIN_EXTRA := 2
const SOAK_FREEZE := 0.6
const SHOCK_BONUS := 0.15
const SOAKED_BY := [LIGHTNING, COLD]
## Lód (lodowy rapier, ustalone z autorem 25.11.2026 - ProtoTarget.chill): każde trafienie lodem spowalnia o CHILL_SLOW
## na CHILL_TIME s i dokłada znak chłodu; CHILL_STACKS znaków zamraża wroga na CHILL_FREEZE s (potem chwila odporności
## - ProtoTarget.FREEZE_IMMUNE). Bossy się nie zatrzymują (jak przy ogłuszeniu), ale też liczą się jako zamrożone.
const CHILL_SLOW := 0.25
const CHILL_TIME := 2.0
const CHILL_STACKS := 4
const CHILL_FREEZE := 1.0
## Natura (Kostur Leszego, ustalone z autorem 25.11.2026 - ProtoTarget.poison): każde trafienie naturą dokłada znak
## trucizny (najwyżej POISON_STACKS); każdy znak zadaje POISON_SHARE obrażeń trafienia na sekundę przez POISON_TIME s
## (nowe trafienie odnawia czas wszystkich znaków).
const POISON_SHARE := 0.1
const POISON_TIME := 4.0
const POISON_STACKS := 10
## Odporności potworów (nazwa potwora -> {żywioł: ułamek}). Gobliny Hordy nie mają żadnych; wpisy dojdą
## z nowymi rodzajami lochów i potworów (np. utopce odporne na wodę, wrażliwe na Grom).
const MONSTER_RESIST := {}


static func is_element(id: String) -> bool:
	return id == PHYSICAL or NAMES.has(id)


static func name_of(id: String) -> String:
	return Lang.t(NAMES[id]) if NAMES.has(id) else ""


static func color_of(id: String) -> Color:
	return COLORS.get(id, COLORS[PHYSICAL])


static func effect_text(id: String) -> String:
	return Lang.t(EFFECTS[id]) if EFFECTS.has(id) else ""


## Odporność potwora `monster` na żywioł (0 - brak wpisu), przycięta do granic.
static func resistance(monster: String, element: String) -> float:
	var r: float = MONSTER_RESIST.get(monster, {}).get(element, 0.0)
	return clampf(r, MIN_RESISTANCE, MAX_RESISTANCE)


## Obrażenia po odporności (`resist` - ułamek) i dodatkowym mnożniku z combo (`bonus`, np. 1.3 - przemoczony
## wróg dostaje od Gromu +30%). Mnożnik całości najwyżej MAX_MULT; zawsze co najmniej 1 obrażenie.
static func reduce(amount: int, resist: float, bonus := 1.0) -> int:
	if amount <= 0:
		return 0
	var mult := (1.0 - clampf(resist, MIN_RESISTANCE, MAX_RESISTANCE)) * maxf(bonus, 0.0)
	return maxi(1, roundi(amount * minf(mult, MAX_MULT)))


## Mnożnik combo z przemoczeniem: Grom i lód na przemoczonym wrogu - SOAK_BONUS, inaczej 1.
static func soak_bonus(element: String, soaked: bool) -> float:
	return SOAK_BONUS if soaked and element in SOAKED_BY else 1.0

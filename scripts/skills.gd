class_name Skills
## Umiejętności broni (Weapons): miecza (ustalone z autorem 12.11.2026) i glewii ognia (13.11.2026). Każda broń
## ma własny zwykły cios (`basic_of`) i własne umiejętności (pole "weapon", `of_weapon`); w oknie i na przyciskach
## są tylko umiejętności broni w ręku. Miecz: Zwykły cios też jest umiejętnością: można go przestawić,
## a na jego miejsce pod dużym przyciskiem dać inną - wtedy ta podlega auto atakowi. Gdy umiejętności pod dużym
## przyciskiem brakuje many albo się odnawia, miecz tnie zwykłym ciosem. Pozostałe odblokowuje mistrzostwo broni
## (Weapons; decyzja autora 13.11.2026 - wcześniej kupowało się je za złoto): po dojściu do progu "mastery" umiejętność
## sama trafia do odblokowanych (Game.add_mastery), a przypisuje się ją w oknie umiejętności (SkillsWindow).
## Odblokowane i miejsca trzyma i zapisuje Game (`skills_owned`, `skill_slots`). Działanie - ProtoWeapon.
## Poziomy umiejętności (ustalone z autorem 13.11.2026): 1-MAX_LEVEL, kolejny kupuje się żarem z Watry przy kamieniu
## run (`upgrade_price` rośnie z poziomem; do 13.11.2026 złotem), najwyżej połowa poziomu mistrzostwa broni w górę
## (`level_cap`). Każdy poziom daje
## +DAMAGE_STEP obrażeń, poziomy COST_LEVELS - mniej many i krótsze odnowienie (zwykły cios: szybszy), AREA_LEVELS -
## większy obszar i zasięg, PERK_LEVELS - nowe działanie (`PERKS`, opisy dla okna; działanie - ProtoWeapon).
## Poziomy trzyma i zapisuje Game (`skill_levels`).

## Zwykły cios (darmowy, zawsze kupiony).
const STRIKE := "strike"
## Miejsca: 0 - duży przycisk (atak), 1-4 - małe miejsca wokół niego (odblokowane z poziomem - HeroLevels).
const SLOTS := 5
const MAIN := 0
## Mgnienie: tyle many wraca za każdego wroga zabitego skokiem (5. poziom - x2) i co który skok wir z 10. poziomu.
const BLINK_MANA_ON_KILL := 2
const BLINK_SPIN_EVERY := 5

## name - nazwa, icon - ikona, mana - koszt, cooldown - odnowienie (s), weapon - broń (Weapons), mastery - poziom
## mistrzostwa broni, który ją odblokowuje (progi jak dawne wymagane poziomy postaci),
## main - czy może stać pod dużym przyciskiem (auto atak), range - z jakiej odległości auto atak jej używa (stopy-stopy),
## power - obrażenia jako wielokrotność zwykłego cięcia (w Młynku - na jedno trafienie). Mgnienie jak Flicker Strike z PoE
## (decyzja autora 13.11.2026): bez odnowienia, skacze, dopóki starcza many; zabite skokiem wrogi zwracają manę.
const DATA := {
	"strike": {
		"name": "Zwykły cios", "icon": preload("res://assets/watra/iron_sword_icon.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "sword", "mastery": 1, "main": true, "range": 48.0, "power": 1.0,
		"description": "Miecz tnie po łuku najbliższego wroga.",
	},
	"whirl": {
		"name": "Młynek", "icon": preload("res://assets/watra/skills/whirlwind.png"),
		"mana": 25, "cooldown": 8.0, "weapon": "sword", "mastery": 3, "main": true, "range": 40.0, "power": 0.6,
		"description": "Miecz wiruje wokół ciebie przez 3 s i rani wszystkich dookoła. Możesz przy tym chodzić.",
	},
	"throw": {
		"name": "Rzut mieczem", "icon": preload("res://assets/watra/skills/lunge.png"),
		"mana": 15, "cooldown": 4.0, "weapon": "sword", "mastery": 6, "main": true, "range": 120.0, "power": 1.5,
		"description": "Miecz leci w najbliższego wroga, przebija wszystkich po drodze i wraca, raniąc ich drugi raz.",
	},
	"slam": {
		"name": "Rozłupanie Ziemi", "icon": preload("res://assets/watra/skills/ground_slam.png"),
		"mana": 25, "cooldown": 7.0, "weapon": "sword", "mastery": 10, "main": true, "range": 70.0, "power": 2.2,
		"description": "Miecz spada z góry na wrogów: fala pęknięć rani wszystkich wokół i na chwilę ich ogłusza.",
	},
	"blink": {
		"name": "Mgnienie", "icon": preload("res://assets/watra/skills/flicker.png"),
		"mana": 7, "cooldown": 0.0, "weapon": "sword", "mastery": 15, "main": false, "range": 0.0, "power": 1.2,
		"description": "Przytrzymaj - przeskakujesz na wylot przez najbliższego wroga, tnąc wszystkich po drodze, potem przez kolejnego, dopóki starcza many. Każdy wróg zabity skokiem zwraca 2 many. Nie może stać pod dużym przyciskiem.",
	},	# Glewia ognia (ustalone z autorem 13.11.2026): każde trafienie podpala (ProtoGlaive), "burn" - ile obrażeń
	# trafienia dopala się przez 3 s.
	"g_thrust": {
		"name": "Pchnięcie glewii", "icon": preload("res://assets/watra/skills/enchanted_blade.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "glaive", "mastery": 1, "main": true, "range": 64.0, "power": 1.0, "burn": 0.3,
		"description": "Glewia dźga daleko przed siebie, rani wszystkich na linii i słabo ich podpala.",
	},
	"g_sweep": {
		"name": "Ognisty zamach", "icon": preload("res://assets/watra/skills/crescent.png"),
		"mana": 15, "cooldown": 5.0, "weapon": "glaive", "mastery": 3, "main": true, "range": 56.0, "power": 1.3, "burn": 1.0,
		"description": "Glewia zatacza szeroki półokrąg przed tobą i mocno podpala trafionych.",
	},
	"g_trail": {
		"name": "Płonący ślad", "icon": preload("res://assets/watra/skills/fire_wall.png"),
		"mana": 20, "cooldown": 7.0, "weapon": "glaive", "mastery": 6, "main": true, "range": 110.0, "power": 1.2, "burn": 0.5,
		"description": "Doskakujesz z pchnięciem w stronę wroga, a za tobą zostaje pas ognia, który pali wrogów przez 3 s.",
	},
	"g_pillar": {
		"name": "Słup ognia", "icon": preload("res://assets/watra/skills/aura_swarog_ember.png"),
		"mana": 25, "cooldown": 8.0, "weapon": "glaive", "mastery": 10, "main": true, "range": 80.0, "power": 2.2, "burn": 0.5,
		"description": "Glewia spada z góry i wbija się w ziemię: wybuch ognia rani wszystkich wokół, a ziemia płonie przez 3 s.",
	},
	"g_dance": {
		"name": "Taniec płomieni", "icon": preload("res://assets/watra/skills/ks_blade_dance.png"),
		"mana": 30, "cooldown": 10.0, "weapon": "glaive", "mastery": 15, "main": true, "range": 60.0, "power": 0.7, "burn": 0.3,
		"description": "Glewia wiruje wokół ciebie przez 3 s i co chwilę wypuszcza zamaszyste cięcia, które powoli lecą na wszystkie strony i przebijają wrogów.",
	},
}
## Poziomy umiejętności: najwyższy, przyrost obrażeń na poziom, poziomy z mniejszym kosztem many i odnowieniem
## (o COST_STEP każdy), z większym obszarem (o AREA_STEP każdy) i z nowym działaniem.
const MAX_LEVEL := 10
const DAMAGE_STEP := 0.1
const COST_LEVELS := [3, 7]
const COST_STEP := 0.1
const AREA_LEVELS := [4, 8]
const AREA_STEP := 0.1
const PERK_LEVELS := [5, 10]
## Cena ulepszenia z poziomu n na n+1 (żar): UPGRADE_PRICE[umiejętność] * n (zwykły cios najtańszy, Mgnienie
## najdroższe; liczby jak dawne ceny w złocie - do oceny na telefonie).
const UPGRADE_PRICE := {"strike": 40, "whirl": 60, "throw": 90, "slam": 140, "blink": 200,
		"g_thrust": 40, "g_sweep": 60, "g_trail": 90, "g_pillar": 140, "g_dance": 200}
## Nowe działanie na poziomach PERK_LEVELS (opisy dla okna umiejętności).
const PERKS := {
	"strike": ["Co trzeci cios tnie dwa razy.", "Cios rani też najbliższego wroga obok."],
	"whirl": ["Wiruje 4 s zamiast 3.", "Na koniec wybuch odpycha wrogów."],
	"throw": ["Na końcu lotu miecz odbija się w kolejnego wroga.", "Rzuca dwa miecze naraz."],
	"slam": ["Dłuższe ogłuszenie.", "Po pół sekundy uderza druga fala pęknięć."],
	"blink": ["Zabicie skokiem zwraca dwa razy więcej many.", "Co 5. skok krótki wir wokół postaci."],
	"g_thrust": ["Podpalenie dwa razy silniejsze.", "Co trzecie pchnięcie dźga dwa razy."],
	"g_sweep": ["Zamach odpycha wrogów.", "Zaraz po nim drugi zamach w drugą stronę."],
	"g_trail": ["Pas ognia płonie 5 s zamiast 3.", "Na końcu doskoku wybuch ognia."],
	"g_pillar": ["Płonący krąg o połowę większy.", "Po pół sekundy drugi wybuch."],
	"g_dance": ["Tańczy 4 s zamiast 3.", "Cięcia lecą po dwa naraz, w przeciwne strony."],
}
## Dawne ceny umiejętności w złocie - tylko do zwrotu złota przy wczytaniu starego zapisu (Game.load_game).
const LEGACY_PRICE := {"whirl": 100, "throw": 300, "slam": 800, "blink": 1500}
## Kolejność w oknie umiejętności.
const ORDER := ["strike", "whirl", "throw", "slam", "blink", "g_thrust", "g_sweep", "g_trail", "g_pillar", "g_dance"]


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


## Poziom mistrzostwa broni, który odblokowuje umiejętność.
static func mastery_of(id: String) -> int:
	return DATA[id].mastery if DATA.has(id) else 1


## Broń, do której należy umiejętność.
static func weapon_of(id: String) -> String:
	return DATA[id].weapon if DATA.has(id) else ""


## Umiejętności broni `weapon` w kolejności okna.
static func of_weapon(weapon: String) -> Array[String]:
	var list: Array[String] = []
	for id in ORDER:
		if weapon_of(id) == weapon:
			list.append(id)
	return list


## Zwykły cios broni (pierwsza jej umiejętność; pusty duży przycisk to ten cios).
static func basic_of(weapon: String) -> String:
	var list := of_weapon(weapon)
	return list[0] if not list.is_empty() else STRIKE


## Czy to zwykły cios którejś broni (bez many i odnowienia, szybszy z poziomami).
static func is_basic(id: String) -> bool:
	return DATA.has(id) and basic_of(weapon_of(id)) == id


## Ile obrażeń trafienia dopala się w podpaleniu (glewia ognia; 0 - nie podpala).
static func burn_of(id: String) -> float:
	return DATA[id].get("burn", 0.0) if DATA.has(id) else 0.0


## Umiejętności broni `weapon` odblokowane na poziomie mistrzostwa `mastery` (w kolejności okna).
static func unlocked_at(weapon: String, mastery: int) -> Array[String]:
	var list: Array[String] = []
	for id in ORDER:
		if weapon_of(id) == weapon and mastery >= mastery_of(id):
			list.append(id)
	return list


## Czy umiejętność może stać pod dużym przyciskiem (Mgnienie - nie: auto atak wrzucałby postać w hordę).
static func can_be_main(id: String) -> bool:
	return id == "" or (DATA.has(id) and DATA[id].main)


## Ile miejsc (razem z dużym przyciskiem) jest odblokowanych na danym poziomie postaci.
static func open_slots(hero_level: int) -> int:
	return 1 + HeroLevels.skill_slots(hero_level)


## Najwyższy poziom umiejętności przy danym poziomie mistrzostwa broni (połowa w górę, nie więcej niż MAX_LEVEL).
static func level_cap(mastery: int) -> int:
	return clampi(ceili(mastery / 2.0), 1, MAX_LEVEL)


## Poziom mistrzostwa broni potrzebny do poziomu umiejętności `level`.
static func mastery_for(level: int) -> int:
	return maxi(1, 2 * level - 1)


## Cena ulepszenia z poziomu `level` na następny w żarze (0 - już najwyższy).
static func upgrade_price(id: String, level: int) -> int:
	if not DATA.has(id) or level >= MAX_LEVEL:
		return 0
	return UPGRADE_PRICE.get(id, 100) * maxi(level, 1)


## Mnożnik obrażeń z poziomu umiejętności (1. poziom - 1.0).
static func level_damage(level: int) -> float:
	return 1.0 + DAMAGE_STEP * (maxi(level, 1) - 1)


## Mnożnik kosztu many i odnowienia z poziomu (poziomy COST_LEVELS).
static func level_cost(level: int) -> float:
	return 1.0 - COST_STEP * _reached(COST_LEVELS, level)


## Mnożnik obszaru i zasięgu z poziomu (poziomy AREA_LEVELS).
static func level_area(level: int) -> float:
	return 1.0 + AREA_STEP * _reached(AREA_LEVELS, level)


## Ile nowych działań (PERKS) jest odblokowanych na poziomie (0-2).
static func perks_at(level: int) -> int:
	return _reached(PERK_LEVELS, level)


## Opis nowego działania nr `i` (0 - z 5. poziomu, 1 - z 10.).
static func perk_text(id: String, i: int) -> String:
	return Lang.t(PERKS[id][i]) if PERKS.has(id) and i < PERKS[id].size() else ""


## Co da kolejny poziom (krótko, dla okna): obrażenia i premia tego poziomu.
static func next_level_text(id: String, level: int) -> String:
	if level >= MAX_LEVEL:
		return ""
	var next := level + 1
	var parts: Array[String] = [Lang.t("+%d%% obrażeń") % roundi(DAMAGE_STEP * 100)]
	if next in COST_LEVELS:
		parts.append(Lang.t("szybszy cios") if id == STRIKE else Lang.t("-%d%% many i odnowienia") % roundi(COST_STEP * 100))
	if next in AREA_LEVELS:
		parts.append(Lang.t("+%d%% obszaru") % roundi(AREA_STEP * 100))
	if next in PERK_LEVELS:
		parts.append(Lang.t("nowe działanie"))
	return ", ".join(parts)


static func _reached(levels: Array, level: int) -> int:
	var n := 0
	for l in levels:
		if level >= l:
			n += 1
	return n

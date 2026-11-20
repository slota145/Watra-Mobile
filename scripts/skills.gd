class_name Skills
## Umiejętności broni (Weapons): miecza (ustalone z autorem 12.11.2026), glewii ognia (13.11.2026), hydrosfery
## (14.11.2026) i elektrycznej katany (15.11.2026). Każda broń
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
## +DAMAGE_STEP obrażeń i +MANA_LEVEL_STEP kosztu many (jak w PoE - 19.11.2026), poziomy COST_LEVELS - krótsze odnowienie
## (zwykły cios: szybszy), AREA_LEVELS -
## większy obszar i zasięg, PERK_LEVELS - nowe działanie (`PERKS`, opisy dla okna; działanie - ProtoWeapon).
## Poziomy trzyma i zapisuje Game (`skill_levels`).

## Zwykły cios (darmowy, zawsze kupiony).
const STRIKE := "strike"
## Miejsca: 0 - duży przycisk (atak), 1-4 - małe miejsca wokół niego (odblokowane z poziomem - HeroLevels).
const SLOTS := 5
const MAIN := 0
## Skoki jak Mgnienie (Błysk Peruna katany): tyle many wraca za każdego wroga zabitego skokiem (5. poziom - x2) i co który
## skok wyładowanie z 10. poziomu.
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
		"mana": 15, "cooldown": 0.0, "weapon": "sword", "mastery": 3, "main": true, "range": 40.0, "power": 0.6,
		"description": "Miecz wiruje wokół ciebie, dopóki trzymasz przycisk, i rani wszystkich dookoła; co sekundę zużywa manę. Możesz przy tym chodzić.",
	},
	"throw": {
		"name": "Rzut mieczem", "icon": preload("res://assets/watra/skills/lunge.png"),
		"mana": 22, "cooldown": 4.0, "weapon": "sword", "mastery": 6, "main": true, "range": 120.0, "power": 1.5,
		"description": "Miecz leci w najdalszego wroga w zasięgu, przebija wszystkich po drodze i wraca, raniąc ich drugi raz.",
	},
	"slam": {
		"name": "Rozłupanie Ziemi", "icon": preload("res://assets/watra/skills/ground_slam.png"),
		"mana": 38, "cooldown": 7.0, "weapon": "sword", "mastery": 10, "main": true, "range": 70.0, "power": 2.2,
		"description": "Miecz spada z góry na wrogów: fala pęknięć rani wszystkich wokół i ogłusza, a dalej przez tłum biegnie szczelina, z której wyskakują skalne kolce.",
	},
	# Krąg stali (pomysł autora i Claude 15.11.2026, zamiast Mgnienia - to zostało przy katanie jako Błysk Peruna):
	# widmowe miecze krążą wokół postaci, a miecz w ręku walczy normalnie (ProtoWeapon._process_ring). Nie pod „Atak”
	# (decyzja autora 15.11.2026 - krąg odpala się osobno, np. razem z Młynkiem pod „Atak”).
	"steel_ring": {
		"name": "Krąg stali", "icon": preload("res://assets/skills/sword/steel_ring.png"),
		"mana": 45, "cooldown": 12.0, "weapon": "sword", "mastery": 15, "main": false, "range": 50.0, "power": 0.6,
		"description": "Przez 6 s wokół ciebie krążą trzy widmowe miecze i tną każdego, kto podejdzie. Twój miecz walczy w tym czasie normalnie. Nie może stać pod dużym przyciskiem.",
	},	# Glewia ognia (ustalone z autorem 13.11.2026): każde trafienie podpala (ProtoGlaive), "burn" - ile obrażeń
	# trafienia dopala się przez 3 s.
	"g_thrust": {
		"name": "Pchnięcie glewii", "icon": preload("res://assets/skills/glaive/g_thrust.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "glaive", "mastery": 1, "main": true, "range": 64.0, "power": 1.0, "burn": 0.3,
		"description": "Glewia dźga daleko przed siebie, rani wszystkich na linii i słabo ich podpala.",
	},
	"g_sweep": {
		"name": "Ognisty zamach", "icon": preload("res://assets/skills/glaive/g_sweep.png"),
		"mana": 22, "cooldown": 5.0, "weapon": "glaive", "mastery": 3, "main": true, "range": 56.0, "power": 1.3, "burn": 1.0,
		"description": "Glewia zatacza szeroki półokrąg przed tobą i mocno podpala trafionych.",
	},
	"g_trail": {
		"name": "Płonąca bruzda", "icon": preload("res://assets/skills/glaive/g_trail.png"),
		"mana": 30, "cooldown": 7.0, "weapon": "glaive", "mastery": 6, "main": true, "range": 120.0, "power": 1.2, "burn": 0.5,
		"description": "Glewia wbija się w ziemię i ryje bruzdę do przodu: zostaje pas ognia, który pali wrogów przez 3 s, a w wachlarzu wylatują 3 szybkie cięcia ognia, które przebijają wrogów.",
	},
	"g_pillar": {
		"name": "Słup ognia", "icon": preload("res://assets/skills/glaive/g_pillar.png"),
		"mana": 38, "cooldown": 8.0, "weapon": "glaive", "mastery": 10, "main": true, "range": 80.0, "power": 2.2, "burn": 0.5,
		"description": "Glewia spada z góry i wbija się w ziemię: wybuch ognia rani wszystkich wokół, a ziemia płonie przez 3 s.",
	},
	"g_dance": {
		"name": "Taniec płomieni", "icon": preload("res://assets/skills/glaive/g_dance.png"),
		"mana": 45, "cooldown": 10.0, "weapon": "glaive", "mastery": 15, "main": true, "range": 60.0, "power": 0.7, "burn": 0.3,
		"description": "Przez 3 s glewia tnie zamaszyście dookoła ciebie pod różnymi kątami, a każde cięcie wypuszcza sierp ognia, który powoli leci na zewnątrz i przebija wrogów.",
	},
	# Hydrosfera (ustalone z autorem 14.11.2026): walka na dystans, każde trafienie przemacza (ProtoHydrosphere).
	"h_bolt": {
		"name": "Wodny pocisk", "icon": preload("res://assets/skills/hydro/h_bolt.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "hydrosphere", "mastery": 1, "main": true, "range": 140.0, "power": 0.9,
		"description": "Kula wypluwa bańkę wody w najdalszego wroga w zasięgu; rozprysk rani też tych obok. Trafieni są przemoczeni.",
	},
	"h_wave": {
		"name": "Fala", "icon": preload("res://assets/skills/hydro/h_wave.png"),
		"mana": 22, "cooldown": 5.0, "weapon": "hydrosphere", "mastery": 3, "main": true, "range": 90.0, "power": 1.2,
		"description": "Fala wody toczy się łukiem przed tobą, rani i odpycha wrogów.",
	},
	"h_vortex": {
		"name": "Wir", "icon": preload("res://assets/skills/hydro/h_vortex.png"),
		"mana": 30, "cooldown": 8.0, "weapon": "hydrosphere", "mastery": 6, "main": true, "range": 140.0, "power": 0.35,
		"description": "Wodny wir w miejscu wroga przez 3 s wciąga wrogów do środka i co chwilę ich rani.",
	},
	"h_geyser": {
		"name": "Gejzery", "icon": preload("res://assets/skills/hydro/h_geyser.png"),
		"mana": 38, "cooldown": 8.0, "weapon": "hydrosphere", "mastery": 10, "main": true, "range": 120.0, "power": 1.8,
		"description": "Pod pięcioma najbliższymi wrogami tryskają gejzery: ranią i ogłuszają na 1 s.",
	},
	"h_guardian": {
		"name": "Wodny Strażnik", "icon": preload("res://assets/skills/hydro/h_guardian.png"),
		"mana": 45, "cooldown": 12.0, "weapon": "hydrosphere", "mastery": 15, "main": true, "range": 110.0, "power": 0.8,
		"description": "Kula wody pojawia się z wybuchem przy wrogu, zostaje 6 s i strzela wodnymi pociskami w najbliższych wrogów.",
	},
	# Elektryczna katana (ustalone z autorem 15.11.2026): najszybsza broń, każde trafienie poraża (ProtoKatana).
	"k_slash": {
		"name": "Błyskawiczne cięcie", "icon": preload("res://assets/skills/katana/k_slash.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "katana", "mastery": 1, "main": true, "range": 46.0, "power": 0.75,
		"description": "Katana tnie błyskawicznie po łuku najbliższego wroga. Trafieni są porażeni.",
	},
	"k_dance": {
		"name": "Taniec ostrza", "icon": preload("res://assets/skills/katana/k_dance.png"),
		"mana": 22, "cooldown": 5.0, "weapon": "katana", "mastery": 3, "main": true, "range": 60.0, "power": 0.6,
		"description": "Idziesz naprzód, tnąc cztery razy cienkimi, prostymi liniami. Po chwili wszystkie naraz wybuchają potężnymi cięciami, a między trafionymi przeskakuje błękitny piorun.",
	},
	"k_riposte": {
		"name": "Riposta", "icon": preload("res://assets/skills/katana/k_riposte.png"),
		"mana": 22, "cooldown": 6.0, "weapon": "katana", "mastery": 6, "main": true, "range": 50.0, "power": 1.3,
		"description": "Przez 3 s katana czeka w gardzie: następny cios cię nie rani, a ty odpowiadasz cięciem dookoła, wyskokiem ku napastnikowi i precyzyjnym cięciem po okręgu.",
	},
	"k_perun": {
		"name": "Sąd Peruna", "icon": preload("res://assets/skills/katana/k_perun.png"),
		"mana": 38, "cooldown": 8.0, "weapon": "katana", "mastery": 10, "main": false, "range": 200.0, "power": 2.2,
		"charge": true,
		"description": "Przytrzymaj, żeby naładować, i puść: katana tnie w linii prostej ku najdalszemu wrogowi - tym dłużej i szerzej, im dłużej trwało ładowanie - a po chwili wzdłuż cięcia biją gromy z nieba. Nie może stać pod dużym przyciskiem.",
	},
	"k_flash": {
		"name": "Błysk Peruna", "icon": preload("res://assets/skills/katana/k_flash.png"),
		"mana": 10, "cooldown": 0.0, "weapon": "katana", "mastery": 15, "main": false, "range": 0.0, "power": 1.2,
		"description": "Przytrzymaj - przeskakujesz piorunem na wylot przez najbliższego wroga, tnąc wszystkich po drodze, potem przez kolejnego, dopóki starcza many. Każdy wróg zabity skokiem zwraca 2 many. Nie może stać pod dużym przyciskiem.",
	},
	# Łuk (ustalone z autorem 20.11.2026): żywioł powietrze - trafienia lekko odpychają (ProtoBow).
	"b_shot": {
		"name": "Strzał", "icon": preload("res://assets/skills/bow/b_shot.png"),
		"mana": 0, "cooldown": 0.0, "weapon": "bow", "mastery": 1, "main": true, "range": 170.0, "power": 0.85,
		"description": "Łuk strzela w najdalszego wroga w zasięgu. Strzała lekko odpycha trafionego.",
	},
	"b_seeker": {
		"name": "Poszukująca strzała", "icon": preload("res://assets/skills/bow/b_seeker.png"),
		"mana": 18, "cooldown": 2.2, "weapon": "bow", "mastery": 3, "main": true, "range": 200.0, "power": 0.9,
		"description": "Strzała sama szuka wrogów: skręca łukiem ku celowi, przebija go na wylot i leci do kolejnego - 4 trafienia.",
	},
	"b_rain": {
		"name": "Deszcz strzał", "icon": preload("res://assets/skills/bow/b_rain.png"),
		"mana": 30, "cooldown": 6.0, "weapon": "bow", "mastery": 6, "main": true, "range": 170.0, "power": 0.35,
		"description": "Na najbliższego wroga spada deszcz strzał - przez sekundę rani wszystkich w kręgu.",
	},
	"b_power": {
		"name": "Potężny strzał", "icon": preload("res://assets/skills/bow/b_power.png"),
		"mana": 38, "cooldown": 7.0, "weapon": "bow", "mastery": 10, "main": false, "range": 200.0, "power": 2.4,
		"charge": true,
		"description": "Przytrzymaj, żeby naciągnąć, i puść: podmuch odpycha wrogów w pasie przed tobą (im dłużej ładujesz, tym szerzej i dalej), a strzała leci daleko i przebija wszystkich. Nie może stać pod dużym przyciskiem.",
	},
	"b_ballista": {
		"name": "Balista", "icon": preload("res://assets/skills/bow/b_ballista.png"),
		"mana": 45, "cooldown": 12.0, "weapon": "bow", "mastery": 15, "main": true, "range": 120.0, "power": 0.6,
		"description": "Stawiasz balistę przy wrogu: stoi 8 s, obraca się ku celom i strzela bełtami w najbliższych wrogów.",
	},
}
## Poziomy umiejętności: najwyższy, przyrost obrażeń na poziom, poziomy z mniejszym kosztem many i odnowieniem
## (o COST_STEP każdy), z większym obszarem (o AREA_STEP każdy) i z nowym działaniem.
const MAX_LEVEL := 10
const DAMAGE_STEP := 0.1
const COST_LEVELS := [3, 7]
const COST_STEP := 0.1
## Koszt many rośnie z każdym poziomem umiejętności (decyzja autora 19.11.2026; 10. poziom x2,08). Bazowe koszty
## w DATA podniesione x1,5 tego samego dnia (wcześniej poziomy obniżały koszt).
const MANA_LEVEL_STEP := 0.12
const AREA_LEVELS := [4, 8]
const AREA_STEP := 0.1
const PERK_LEVELS := [5, 10]
## Cena ulepszenia z poziomu n na n+1 (żar): UPGRADE_PRICE[umiejętność] * n (zwykły cios najtańszy, Mgnienie
## najdroższe; liczby jak dawne ceny w złocie - do oceny na telefonie).
const UPGRADE_PRICE := {"strike": 40, "whirl": 60, "throw": 90, "slam": 140, "steel_ring": 200,
		"g_thrust": 40, "g_sweep": 60, "g_trail": 90, "g_pillar": 140, "g_dance": 200,
		"h_bolt": 40, "h_wave": 60, "h_vortex": 90, "h_geyser": 140, "h_guardian": 200,
		"k_slash": 40, "k_dance": 60, "k_riposte": 90, "k_perun": 140, "k_flash": 200,
		"b_shot": 40, "b_seeker": 60, "b_rain": 90, "b_power": 140, "b_ballista": 200}
## Nowe działanie na poziomach PERK_LEVELS (opisy dla okna umiejętności).
const PERKS := {
	"strike": ["Co trzeci cios tnie dwa razy.", "Cios rani też najbliższego wroga obok."],
	"whirl": ["Zużywa o 30% mniej many.", "Co 2,5 s wirowania wybuch odpycha wrogów."],
	"throw": ["Na końcu lotu miecz odbija się w kolejnego wroga.", "Rzuca dwa miecze naraz."],
	"slam": ["Dłuższe ogłuszenie.", "Po pół sekundy uderza druga fala pęknięć."],
	"steel_ring": ["Krąg trwa 8 s zamiast 6.", "Pięć mieczy zamiast trzech."],
	"g_thrust": ["Podpalenie dwa razy silniejsze.", "Co trzecie pchnięcie dźga dwa razy."],
	"g_sweep": ["Zamach odpycha wrogów.", "Zaraz po nim drugi zamach w drugą stronę."],
	"g_trail": ["Bruzda płonie 5 s zamiast 3.", "5 cięć zamiast 3."],
	"g_pillar": ["Płonący krąg o połowę większy.", "Po pół sekundy drugi wybuch."],
	"g_dance": ["Tańczy 4 s zamiast 3.", "Sierpy lecą po dwa naraz, w przeciwne strony."],
	"h_bolt": ["Rozprysk większy i silniejszy.", "Co trzeci pocisk to trzy bańki w wachlarzu."],
	"h_wave": ["Fala toczy się o połowę dalej.", "Za pierwszą falą idzie druga."],
	"h_vortex": ["Wir kręci się 4 s zamiast 3.", "Na koniec wir wybucha falą wody."],
	"h_geyser": ["Ogłuszenie 1,5 s zamiast 1.", "Osiem gejzerów zamiast pięciu."],
	"h_guardian": ["Strażnik zostaje 8 s zamiast 6.", "Pojawiają się dwie kule naraz."],
	"k_slash": ["Co czwarte cięcie - piorun w najdalszego wroga w zasięgu.", "Cięcie przeskakuje piorunem po dwóch kolejnych wrogach."],
	"k_dance": ["6 cięć zamiast 4.", "Na końcu piorun przeskakuje też na 3 wrogów obok."],
	"k_riposte": ["Garda czeka 5 s zamiast 3.", "Z precyzyjnego cięcia po okręgu piorun przeskakuje na wrogów obok."],
	"k_perun": ["Ładuje się o 1/3 szybciej.", "Na końcu cięcia uderza piorun, który rani wszystkich wokół."],
	"k_flash": ["Zabicie skokiem zwraca dwa razy więcej many.", "Co 5. skok wiązka piorunów przeskakuje po 5 wrogach."],
	"b_shot": ["Strzała przebija pierwszego wroga i leci dalej.", "Co trzeci strzał to dwie strzały."],
	"b_seeker": ["6 trafień zamiast 4.", "Lecą dwie strzały naraz."],
	"b_rain": ["Krąg deszczu o 30% większy.", "Deszcz pada 2 s zamiast 1."],
	"b_power": ["Naciąga się o 1/3 szybciej.", "Podmuch ogłusza wrogów na 0,8 s."],
	"b_ballista": ["Balista stoi 11 s zamiast 8.", "Stawiasz dwie balisty naraz."],
}
## Dawne ceny umiejętności w złocie - tylko do zwrotu złota przy wczytaniu starego zapisu (Game.load_game).
const LEGACY_PRICE := {"whirl": 100, "throw": 300, "slam": 800, "blink": 1500}
## Kolejność w oknie umiejętności.
const ORDER := ["strike", "whirl", "throw", "slam", "steel_ring", "g_thrust", "g_sweep", "g_trail", "g_pillar", "g_dance",
		"h_bolt", "h_wave", "h_vortex", "h_geyser", "h_guardian", "k_slash", "k_dance", "k_riposte", "k_perun", "k_flash",
		"b_shot", "b_seeker", "b_rain", "b_power", "b_ballista"]


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


## Czy umiejętność ładuje się przytrzymaniem przycisku (Sąd Peruna katany - działa po puszczeniu).
static func is_charged(id: String) -> bool:
	return DATA.has(id) and DATA[id].get("charge", false)


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


## Mnożnik odnowienia (i szybkości zwykłego ciosu) z poziomu (poziomy COST_LEVELS).
static func level_cost(level: int) -> float:
	return 1.0 - COST_STEP * _reached(COST_LEVELS, level)


## Mnożnik kosztu many z poziomu umiejętności (+MANA_LEVEL_STEP na poziom).
static func level_mana(level: int) -> float:
	return 1.0 + MANA_LEVEL_STEP * (clampi(level, 1, MAX_LEVEL) - 1)


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
	if mana_of(id) > 0:
		parts.append(Lang.t("+%d%% many") % roundi(MANA_LEVEL_STEP * 100))
	if next in COST_LEVELS:
		parts.append(Lang.t("szybszy cios") if id == STRIKE else Lang.t("-%d%% odnowienia") % roundi(COST_STEP * 100))
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

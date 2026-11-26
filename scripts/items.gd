class_name Items
## Przedmioty (ustalone z autorem 12.11.2026, przebudowa itemizacji 21.11.2026): 6 miejsc ekwipunku (kolczyk, hełm,
## zbroja, buty, pierścień, amulet), 3 rzadkości - zwykły (bez premii), magiczny (1-2 losowe premie), rzadki (3-5).
## Każde miejsce ma 3 bazy (BASES) z własną stałą cechą (np. hełm - zdrowie, kaptur - mana, rogaty hełm - odporność
## na żywioły); stała cecha rośnie z poziomem lochu do MAX_LEVEL (sufit siły przedmiotów - loch 55, koniec zwykłej drabinki; decyzja autora 26.11.2026 - wcześniej 40), a co kilka
## poziomów (VISUAL_FROM) zmienia się wygląd i nazwa bazy (5 stopni).
## Premie mają stopnie T7 (najsłabszy) - T1 (najlepszy, decyzja autora 21.11.2026 - jak tiery w Path of Exile):
## wyższe odblokowują się w głębszych lochach (TIER_FROM; T1 od lochu 40) i wypadają rzadziej (TIER_WEIGHTS),
## widełki stopni są szerokie i zachodzą na siebie. Łup: skrzynia Wodza (`roll_chest`) i rzadko gobliny (`roll_goblin`).
## Niepotrzebne przedmioty rozbija się na rudę żelaza (`ore_value`; rzadki - czasem Runa Szlifu).
## Przedmiot to słownik z samymi identyfikatorami i liczbami (nazwy składane przy pokazywaniu - zasady w lang.gd):
## {"slot", "type" - baza, "tier" - stopień wyglądu 0-4, "level", "rarity", "base": {cecha: wartość},
## "affixes": [{"stat", "value", "tier" 1-7, "skill" - tylko premia skill_level}], "sockets": [kamień],
## "rerolls": ile razy przekuto premię (Runa Przekucia - `reroll_affix`)}. Premie zmieniają runy u kowala (Runes).
## Gniazda na kamienie szlachetne (Gems): "sockets" - lista identyfikatorów kamieni ("" - puste gniazdo); każdy przedmiot
## ma 1 gniazdo, bardzo rzadko 2 (SECOND_SOCKET), drugie dorabia Dłuto Jubilera (Game.add_socket).
## Stan (torba, założone, ruda) trzyma i zapisuje `Game`; sumę cech założonych przedmiotów liczy `totals`.
## Ikony: assets/watra/items/ (skopiowane z Watry, wersje _magic i _rare) i assets/items/ (przebarwione linie Watry -
## tools/item_bases_art.py).

## Kolczyk z kłem (decyzja autora 13.11.2026) zastąpił miejsce „Broń”: daje obrażenia każdej broni (Weapons), więc
## nie gryzie się z mieczem, glewią itd. Stare przedmioty z miejsca "weapon" (miecze) wczytują się jako kolczyki
## tej samej siły (`normalize`, LEGACY_SLOTS).
## Dawne miejsca w zapisie -> obecne.
const LEGACY_SLOTS := {"weapon": "earring"}
const SLOTS := ["earring", "helmet", "armor", "boots", "ring", "amulet"]
const SLOT_NAMES := {"earring": "Kolczyk", "helmet": "Hełm", "armor": "Zbroja", "boots": "Buty", "ring": "Pierścień",
		"amulet": "Amulet"}
## Pusty obrazek miejsca w oknie ekwipunku (z Watry).
const SLOT_ICONS := {"earring": "slot_earring", "helmet": "slot_helmet", "armor": "slot_chest", "boots": "slot_boots",
		"ring": "slot_ring", "amulet": "slot_necklace"}
## Sufit siły przedmiotów (decyzja autora 21.11.2026): stała cecha i stopnie premii przestają rosnąć na tym poziomie
## lochu - dalej gra się po lepsze stopnie, rzadkość i kamienie, a nie po większe liczby.
const MAX_LEVEL := 55
## Bazy przedmiotów (decyzja autora 21.11.2026): miejsce -> baza -> stała cecha {cecha: [na 1. poziomie lochu,
## na MAX_LEVEL]}, ikony (5 stopni wyglądu, ścieżka w assets/ bez rozszerzenia) i nazwy (5 stopni). Pierwsza baza
## miejsca to dawna (stare zapisy - `normalize`). Kolczyk każdej bazy daje też obrażenia ciosu (EARRING_DAMAGE).
const BASES := {
	"earring": {
		"fang": {"implicit": {"crit_pct": [2.0, 6.0]},
			"icons": ["watra/items/fang_earring", "watra/items/fang_t2", "watra/items/fang_t3", "watra/items/fang_t4", "watra/items/fang_t5"],
			"names": ["Kolczyk z kłem", "Kolczyk z kłem niedźwiedzia", "Kolczyk z kłem bazyliszka", "Kolczyk z kłem demona",
					"Kolczyk ze smoczym kłem"]},
		"stud": {"implicit": {"attack_speed_pct": [2.0, 8.0], "cast_speed_pct": [2.0, 8.0]},
			"icons": ["watra/items/silver_earring", "watra/items/stud_t2", "watra/items/stud_t3", "watra/items/stud_t4", "watra/items/stud_t5"],
			"names": ["Srebrny kolczyk", "Kolczyk z szafirem", "Kolczyk z lazurytem", "Kolczyk z gwiezdnym kamieniem",
					"Kolczyk niebios"]},
		"tooth": {"implicit": {"pen_pct": [2.0, 8.0]},
			"icons": ["items/tooth_t1", "items/tooth_t2", "items/tooth_t3", "items/tooth_t4", "items/tooth_t5"],
			"names": ["Kolczyk z zębem", "Kolczyk z zębem wilka", "Kolczyk z zębem wiwerny", "Kolczyk z zębem żmija",
					"Kolczyk z zębem smoka"]},
	},
	"helmet": {
		"helm": {"implicit": {"hp": [8.0, 155.0]},
			"icons": ["watra/items/iron_helmet", "watra/items/helm_t2", "watra/items/helm_t3", "watra/items/helm_t4", "watra/items/helm_t5"],
			"names": ["Żelazny hełm", "Stalowy hełm", "Mithrilowy hełm", "Runiczny hełm", "Smoczy hełm"]},
		"hood": {"implicit": {"mana": [8.0, 50.0]},
			"icons": ["watra/items/leather_cap", "watra/items/hood_t2", "watra/items/hood_t3", "watra/items/hood_t4", "watra/items/hood_t5"],
			"names": ["Skórzany kaptur", "Kaptur wędrowca", "Kaptur maga", "Kaptur runiczny", "Kaptur nocy"]},
		"horned": {"implicit": {"element_res_pct": [4.0, 15.0]},
			"icons": ["items/horned_t1", "items/horned_t2", "items/horned_t3", "items/horned_t4", "items/horned_t5"],
			"names": ["Rogaty hełm", "Hełm z rogami tura", "Hełm wojownika", "Hełm Peruna", "Smoczy hełm rogaty"]},
	},
	"armor": {
		"plate": {"implicit": {"hp": [18.0, 345.0]},
			"icons": ["watra/items/chainmail", "watra/items/plate_t2", "watra/items/plate_t3", "watra/items/plate_t4", "watra/items/plate_t5"],
			"names": ["Kolczuga", "Stalowy napierśnik", "Mithrilowy napierśnik", "Runiczna zbroja", "Smocza zbroja"]},
		"robe": {"implicit": {"protection_pct": [2.0, 8.0]},
			"icons": ["watra/items/robe_t1", "watra/items/robe_t2", "watra/items/robe_t3", "watra/items/robe_t4", "watra/items/robe_t5"],
			"names": ["Lniana szata", "Szata zielarki", "Szata maga", "Szata runiczna", "Szata gwiazd"]},
		"jerkin": {"implicit": {"dodge_pct": [2.0, 8.0]},
			"icons": ["watra/items/leather_armor", "watra/items/jerkin_t2", "watra/items/jerkin_t3", "watra/items/jerkin_t4", "watra/items/jerkin_t5"],
			"names": ["Skórznia", "Kaftan łowcy", "Kaftan zwiadowcy", "Kaftan cienia", "Kaftan ze smoczej skóry"]},
	},
	"boots": {
		"boots": {"implicit": {"move_pct": [4.0, 12.0]},
			"icons": ["watra/items/leather_boots", "watra/items/boots_t2", "watra/items/boots_t3", "watra/items/boots_t4", "watra/items/boots_t5"],
			"names": ["Skórzane buty", "Buty wędrowca", "Elfie buty", "Buty cienia", "Buty ze smoczej skóry"]},
		"greaves": {"implicit": {"dodge_pct": [2.0, 6.0]},
			"icons": ["watra/items/greaves_t1", "watra/items/greaves_t2", "watra/items/greaves_t3", "watra/items/greaves_t4", "watra/items/greaves_t5"],
			"names": ["Żelazne nagolenice", "Stalowe nagolenice", "Mithrilowe nagolenice", "Runiczne nagolenice",
					"Smocze nagolenice"]},
		"bast": {"implicit": {"regen": [0.5, 10.0]},
			"icons": ["items/bast_t1", "items/bast_t2", "items/bast_t3", "items/bast_t4", "items/bast_t5"],
			"names": ["Łapcie z łyka", "Łapcie wędrowca", "Łapcie zielarza", "Łapcie leśnych duchów", "Łapcie Mokoszy"]},
	},
	"ring": {
		"band": {"implicit": {"damage_pct": [4.0, 12.0]},
			"icons": ["watra/items/copper_ring", "watra/items/band_t2", "watra/items/band_t3", "watra/items/band_t4", "watra/items/band_t5"],
			"names": ["Miedziany pierścień", "Srebrny pierścień", "Rubinowy pierścień", "Platynowy pierścień", "Gwiezdny pierścień"]},
		"signet": {"implicit": {"mana_regen": [0.3, 1.5]},
			"icons": ["watra/items/ring_of_strength", "watra/items/signet_t2", "watra/items/signet_t3", "watra/items/signet_t4", "watra/items/signet_t5"],
			"names": ["Sygnet", "Srebrny sygnet", "Sygnet z szafirem", "Sygnet runiczny", "Gwiezdny sygnet"]},
		"gold": {"implicit": {"rarity_pct": [4.0, 15.0]},
			"icons": ["items/gold_t1", "items/gold_t2", "items/gold_t3", "items/gold_t4", "items/gold_t5"],
			"names": ["Złota obrączka", "Złoty pierścień kupca", "Pierścień skarbnika", "Pierścień Welesa",
					"Pierścień złotego runa"]},
	},
	"amulet": {
		"amber": {"implicit": {"mana": [10.0, 60.0]},
			"icons": ["watra/items/amber_necklace", "watra/items/amulet_t2", "watra/items/amulet_t3", "watra/items/amulet_t4", "watra/items/amulet_t5"],
			"names": ["Bursztynowy naszyjnik", "Srebrny amulet", "Złoty amulet", "Runiczny amulet", "Smoczy amulet"]},
		"runic": {"implicit": {"elem_dmg_pct": [4.0, 15.0]},
			"icons": ["items/runic_t1", "items/runic_t2", "items/runic_t3", "items/runic_t4", "items/runic_t5"],
			"names": ["Runiczny wisior", "Amulet run", "Amulet żywiołów", "Amulet mocy", "Amulet Swaroga"]},
		"talisman": {"implicit": {"xp_pct": [4.0, 15.0]},
			"icons": ["watra/items/talisman_t1", "watra/items/talisman_t2", "watra/items/talisman_t3", "watra/items/talisman_t4", "watra/items/talisman_t5"],
			"names": ["Kościany wisior", "Wisior z kłem", "Wisior szamana", "Wisior przodków", "Wisior Nawii"]},
	},
}
## Obrażenia ciosu kolczyka (od-do) na 1. poziomie lochu; rosną o EARRING_GROWTH na poziom do MAX_LEVEL (lekko losowo).
const EARRING_DAMAGE := Vector2(15.0, 21.0)
const EARRING_GROWTH := 0.12
## Stała cecha z tych premii rośnie jak siła lochu (powoli na początku, szybko pod koniec), reszta - liniowo.
const CURVED_STATS := ["hp", "regen", "life_on_kill"]
## Od którego poziomu lochu przedmiot ma kolejny stopień wyglądu i nazwy (5 stopni z Watry).
const VISUAL_FROM := [1, 5, 12, 22, 32]

## Stopnie premii (decyzja autora 21.11.2026): T7 - T1, od którego poziomu lochu wypadają (indeks 0 = T7) i wagi
## losowania (wyższy stopień - rzadszy).
const TIER_FROM := [1, 5, 10, 16, 22, 30, 40]
const TIER_WEIGHTS := [22, 20, 18, 15, 12, 8, 5]
const TIERS := 7
## Kolory znaczków stopni (T1 - złoty, T7 - szary).
const TIER_COLORS := [Color(1.0, 0.78, 0.25), Color(1.0, 0.6, 0.3), Color(0.85, 0.5, 0.95), Color(0.45, 0.7, 1.0),
		Color(0.5, 0.9, 0.6), Color(0.85, 0.85, 0.8), Color(0.62, 0.62, 0.62)]

const RARITIES := ["common", "magic", "rare", "legendary", "unique"]
const RARITY_NAMES := {"common": "Zwykły", "magic": "Magiczny", "rare": "Rzadki", "legendary": "Legendarny",
		"unique": "Unikat"}
## Kolory rzadkości jak w Watrze (legendarny - pomarańczowy, unikat - złoto-brązowy jak w Path of Exile).
const RARITY_COLORS := {"common": Color(0.92, 0.92, 0.95), "magic": Color(0.45, 0.65, 1.0),
		"rare": Color(1.0, 0.86, 0.3), "legendary": Color(1.0, 0.55, 0.15), "unique": Color(0.8, 0.62, 0.36)}
## Unikaty (decyzja autora 21.11.2026): po jednym na miejsce, stała baza (z jej stałą cechą), stałe premie z wąskimi
## widełkami (`stats`, pole przedmiotu "ustats"; hp_pct - procent największego zdrowia, wartości ujemne to kara)
## i własne działanie z siłą `power` (pole "upower"; działanie w walce - ProtoUniques i ProtoWeapon._deal). Kowal ich
## nie przerabia (Runes.blocker). Wypadają z łupu od UNIQUE_FROM z szansą UNIQUE_CHANCE (rośnie do UNIQUE_MAX na MAX_LEVEL).
## licho - bez krytyków, co LICHO_EVERY. trafienie x`power`; crown - umiejętności i aury płacą zdrowiem zamiast many;
## bastion - za każdego wroga w BASTION_RADIUS +`power`% obrażeń i +BASTION_RES% odporności (do BASTION_MAX wrogów);
## swarog - płonący ślad (SWAROG_TIME s), `power`% obrażeń broni na sekundę i podpalenie; strzybog - pocisk przy
## trafieniu rozpada się na STRZYBOG_SHARDS odłamki (STRZYBOG_POWER siły); mokosz - umiejętność powtarza się po
## MOKOSZ_DELAY s z `power`% siły, koszt many x MOKOSZ_COST.
const UNIQUES := {
	"licho": {"name": "Oko Licha", "slot": "earring", "type": "stud", "flavor": "Pech, który nauczył się liczyć.",
		"stats": {"attack_speed_pct": [10.0, 14.0], "cast_speed_pct": [10.0, 14.0]}, "power": [3.0, 3.0]},
	"crown": {"name": "Korona Czarnoboga", "slot": "helmet", "type": "helm", "flavor": "Ofiara z krwi zamiast many.",
		"stats": {"damage_pct": [35.0, 40.0], "hp_pct": [15.0, 20.0]}, "power": [0.0, 0.0]},
	"bastion": {"name": "Ostatnia Warownia", "slot": "armor", "type": "plate", "flavor": "Ostoja trwa, choćby otoczona.",
		"stats": {"move_pct": [-20.0, -20.0]}, "power": [2.0, 2.0]},
	"swarog": {"name": "Ślady Swaroga", "slot": "boots", "type": "boots", "flavor": "Gdzie stąpa, tam płonie ziemia.",
		"stats": {"move_pct": [8.0, 10.0], "hp_pct": [-15.0, -15.0]}, "power": [25.0, 30.0]},
	"strzybog": {"name": "Pierścień Strzyboga", "slot": "ring", "type": "band", "flavor": "Wiatr rozdziera każdy pocisk.",
		"stats": {"proj_dmg_pct": [-25.0, -25.0]}, "power": [3.0, 3.0]},
	"mokosz": {"name": "Zwierciadło Mokoszy", "slot": "amulet", "type": "amber", "flavor": "Każde zaklęcie ma swoje odbicie.",
		"stats": {}, "power": [55.0, 60.0]},
	# tylko ze skrzyni Żmija Gorynycza (Pinnacles, "source") - zwykły łup ich nie losuje
	"zmij_fang": {"name": "Kieł Gorynycza", "slot": "earring", "type": "fang", "source": "zmij",
		"flavor": "Trzy paszcze, jeden głód.", "stats": {"elem_dmg_pct": [15.0, 20.0]}, "power": [60.0, 70.0]},
	"zmij_scale": {"name": "Łuska Gorynycza", "slot": "armor", "type": "plate", "source": "zmij",
		"flavor": "Kto rani smoka, sam płonie.", "stats": {"element_res_pct": [8.0, 12.0], "hp_pct": [8.0, 10.0]},
		"power": [120.0, 140.0]},
}
const UNIQUE_FROM := 10
## Poziomy unikatów (ankieta autora 21.11.2026): rozbity unikat daje esencję tego unikatu (Game.essences), esencje
## podnoszą poziom unikatu 1-UNIQUE_MAX_LEVEL (pole "ulevel"; koszt przejścia z poziomu n na n+1 - n esencji,
## `essence_cost`); każdy poziom ponad 1. daje +UNIQUE_LEVEL_STEP dodatnim premiom i sile działania (kary bez zmian;
## `unique_stat`, `unique_power`). Rozbicie ulepszonego oddaje włożone esencje (`essences_in`).
const UNIQUE_MAX_LEVEL := 5
const UNIQUE_LEVEL_STEP := 0.1
const UNIQUE_CHANCE := 0.002
const UNIQUE_MAX := 0.005
const LICHO_EVERY := 4
const BASTION_RADIUS := 70.0
const BASTION_RES := 1.0
const BASTION_MAX := 20
const SWAROG_TIME := 2.0
const STRZYBOG_SHARDS := 3
const STRZYBOG_POWER := 0.5
const MOKOSZ_DELAY := 0.4
const MOKOSZ_COST := 1.8
## Kieł Gorynycza: co ZMIJ_FANG_EVERY s ZMIJ_FANG_BALLS kul ognia spada na najbliższych wrogów w ZMIJ_FANG_RANGE
## (`power`% obrażeń broni ogniem w kole ZMIJ_FANG_RADIUS i podpalenie). Łuska Gorynycza: gdy postać dostanie
## obrażenia, wokół niej wybucha ognisty krąg (ZMIJ_SCALE_RADIUS, `power`% obrażeń broni, podpalenie), najwyżej
## co ZMIJ_SCALE_COOLDOWN s.
const ZMIJ_FANG_EVERY := 3.0
const ZMIJ_FANG_BALLS := 3
const ZMIJ_FANG_RANGE := 150.0
const ZMIJ_FANG_RADIUS := 20.0
const ZMIJ_SCALE_RADIUS := 60.0
const ZMIJ_SCALE_COOLDOWN := 4.0
## Ile losowych premii daje rzadkość (od-do; rzadki 3-5, legendarny zawsze 6 - decyzje autora 21.11.2026).
const AFFIX_COUNT := {"common": Vector2i(0, 0), "magic": Vector2i(1, 2), "rare": Vector2i(3, 5), "legendary": Vector2i(6, 6),
		"unique": Vector2i(0, 0)}
## Przedmiot legendarny (decyzja autora 21.11.2026): tylko z łupu (nie z kuźni ani run), szansa na każdy przedmiot
## z łupu LEGEND_CHANCE, rośnie z głębią do LEGEND_MAX (`legend_chance`); jego premie wypadają o LEGEND_TIER_BOOST
## stopień lepiej (`make_affix`).
const LEGEND_CHANCE := 0.005
const LEGEND_MAX := 0.015
const LEGEND_TIER_BOOST := 1
## Premie ponad widełki (decyzja autora 21.11.2026, jak Greater Affix z Diablo 4): każda premia przedmiotu z łupu
## z szansą ABOVE_CHANCE (od MAX_LEVEL - ABOVE_CHANCE_DEEP) dostaje najlepszy stopień z poziomu przedmiotu i wartość
## o ABOVE_MIN-ABOVE_MAX ponad jego górną granicę (pole "above"; znaczek „T1+”). Zwykłe runy nigdy - tylko Runa Bogów
## (`make_above`). Wszystkie premie ponad widełki - przedrostek „Anielski” (`is_angelic`).
const ABOVE_CHANCE := 0.03
const ABOVE_CHANCE_DEEP := 0.05
## Głębiny, krok 3 (decyzja autora 26.11.2026): w Głębinach szansa na premię ponad widełki rośnie o ABOVE_DEEP_STEP
## za Głębię, najwyżej do ABOVE_DEEP_MAX (jedyna droga do mocniejszego sprzętu ponad sufit siły 55).
const ABOVE_DEEP_STEP := 0.003
const ABOVE_DEEP_MAX := 0.15
## Lepszy łup z Głębią: szanse na legendy i unikaty x `deep_loot` (+DEEP_LOOT_STEP za Głębię, najwyżej DEEP_LOOT_MAX),
## a wagi rzadkości jak z premią „rzadkości łupu” +DEEP_RARITY_STEP% za Głębię (najwyżej DEEP_RARITY_MAX%).
const DEEP_LOOT_STEP := 0.03
const DEEP_LOOT_MAX := 2.0
const DEEP_RARITY_STEP := 2.0
const DEEP_RARITY_MAX := 60.0
const ABOVE_MIN := 0.05
const ABOVE_MAX := 0.3
## Te premie nie wychodzą ponad widełki (poziomy umiejętności to liczby całkowite).
const ABOVE_SKIP := ["skill_level", "skill_level_all"]
const ABOVE_COLOR := Color(0.75, 1.0, 1.0)
const ANGELIC_COLOR := Color(1.0, 0.97, 0.8)
## Potencjał kowalski (decyzja autora 21.11.2026): każdy przedmiot ma POTENTIAL punktów (od-do), runy je zużywają
## (Runes `cost`), przy zerze runy już nie działają; Runa Odnowy przywraca pełny. Pola "potential" i "potential_max".
const POTENTIAL := Vector2i(15, 25)
## Szanse rzadkości (wagi): łup z goblina i ze skrzyni Wodza (skrzynia częściej daje lepsze).
const GOBLIN_WEIGHTS := {"common": 65, "magic": 28, "rare": 7}
const CHEST_WEIGHTS := {"common": 35, "magic": 45, "rare": 20}
## Szansa, że goblin upuści przedmiot (2,5%).
const GOBLIN_DROP := 0.025
## Skrzynia Wodza: tyle przedmiotów, z czego pierwszy co najmniej magiczny.
const CHEST_ITEMS := 3

## Cechy postaci, które dają przedmioty: nazwa we wzorze (z liczbą), czy w procentach.
## hp - zdrowie, mana, damage_pct - obrażenia, attack_speed_pct - szybkość ataku, move_pct - szybkość ruchu,
## regen - zdrowie na sekundę, protection_pct - mniej obrażeń od potworów, xp_pct - więcej doświadczenia,
## crit_pct - szansa na trafienie krytyczne (do bazowych HeroStats.CRIT_CHANCE), crit_dmg_pct - obrażenia krytyczne
## (do bazowych HeroStats.CRIT_DAMAGE), life_on_kill - zdrowie za zabicie potwora, cdr_pct - krótsze odnowienie
## umiejętności, elite_dmg_pct - obrażenia przeciw elitom i bossom, mana_regen - mana na sekundę (do HeroLevels.MANA_REGEN),
## area_pct - większy obszar cięć i umiejętności, dodge_pct - szansa, że cios potwora nie trafi, pickup_pct - dalej
## przyciągane iskry i łup, ember_pct - więcej żaru z iskier (decyzja autora 13.11.2026), pen_pct - przebicie odporności
## potworów (zmniejsza ich wspólną odporność głębi - DungeonLevels.base_resist; 17.11.2026), mana_on_kill - mana za
## zabicie potwora (nisko, z sufitem CAPS - decyzja autora 19.11.2026), reserve_pct - aury rezerwują o tyle procent
## mniej many (tylko pierścień i amulet, sufit 20% - decyzja autora 19.11.2026), elem_dmg_pct - więcej obrażeń od
## wszystkich żywiołów (broń żywiołu, kamienie Żar / Szron / Piorun, aury, talizmany; nie fizyczne - decyzja autora 20.11.2026),
## magic_dmg_pct - więcej obrażeń broni magicznej (Weapons `magic`: Księga Arkanów, hydrosfera), cast_speed_pct - szybkość
## rzucania czarów: broń magiczna przyspiesza tylko od niej, reszta tylko od attack_speed_pct (decyzje autora 21.11.2026).
## Nowe premie (decyzja autora 21.11.2026): skill_level - poziom jednej umiejętności (pole "skill"; ponad 10. poziom
## do Skills.MAX_LEVEL + ITEM_LEVELS_MAX), skill_level_all - poziom wszystkich umiejętności (tylko amulet, od lochu 22),
## proj/area/melee/minion_dmg_pct - obrażenia umiejętności z danym znacznikiem (Skills.TAGS), proj_speed_pct - szybkość
## pocisków, duration_pct - czas działania umiejętności (kręgi, wiry, przywołańcy, podpalenia), afflicted_dmg_pct -
## obrażenia przeciw wrogom podpalonym, spowolnionym, przemoczonym albo porażonym, full_hp_dmg_pct - przeciw wrogom
## z pełnym zdrowiem, kill_haste_pct - szybkość ruchu i ataku przez KILL_HASTE_TIME po zabiciu, rarity_pct - lepsza
## rzadkość łupu, quantity_pct - więcej przedmiotów, ore_pct - więcej rudy z rozbijania.
const STAT_FORMATS := {
	"hp": "+%d do zdrowia",
	"mana": "+%d do many",
	"damage_pct": "+%d%% obrażeń",
	"attack_speed_pct": "+%d%% szybkości ataku",
	"move_pct": "+%d%% szybkości ruchu",
	"regen": "+%.1f zdrowia na sekundę",
	"protection_pct": "+%d%% ochrony przed obrażeniami",
	"xp_pct": "+%d%% doświadczenia",
	"crit_pct": "+%d%% szansy na trafienie krytyczne",
	"crit_dmg_pct": "+%d%% obrażeń krytycznych",
	"life_on_kill": "+%.1f zdrowia za zabicie potwora",
	"cdr_pct": "%d%% krótsze odnowienie umiejętności",
	"elite_dmg_pct": "+%d%% obrażeń przeciw elitom i bossom",
	"mana_regen": "+%.1f many na sekundę",
	"area_pct": "+%d%% obszaru umiejętności",
	"dodge_pct": "+%d%% szansy na unik",
	"pickup_pct": "+%d%% zasięgu zbierania",
	"ember_pct": "+%d%% żaru",
	"element_res_pct": "+%d%% odporności na żywioły",
	"pen_pct": "+%d%% przebicia odporności potworów",
	"mana_on_kill": "+%.1f many za zabicie potwora",
	"reserve_pct": "%d%% mniejsza rezerwacja many przez aury",
	"elem_dmg_pct": "+%d%% obrażeń od żywiołów",
	"magic_dmg_pct": "+%d%% obrażeń magicznych",
	"cast_speed_pct": "+%d%% szybkości rzucania czarów",
	"skill_level": "+%d do poziomu umiejętności",
	"skill_level_all": "+%d do poziomu wszystkich umiejętności",
	"proj_dmg_pct": "+%d%% obrażeń pocisków",
	"area_dmg_pct": "+%d%% obrażeń obszarowych",
	"melee_dmg_pct": "+%d%% obrażeń wręcz",
	"minion_dmg_pct": "+%d%% obrażeń przywołańców",
	"proj_speed_pct": "+%d%% szybkości pocisków",
	"duration_pct": "+%d%% czasu działania umiejętności",
	"afflicted_dmg_pct": "+%d%% obrażeń przeciw osłabionym wrogom",
	"full_hp_dmg_pct": "+%d%% obrażeń przeciw wrogom z pełnym zdrowiem",
	"kill_haste_pct": "+%d%% szybkości ruchu i ataku po zabiciu",
	"rarity_pct": "+%d%% rzadkości łupu",
	"quantity_pct": "+%d%% ilości łupu",
	"ore_pct": "+%d%% rudy z rozbijania",
}
## Losowe premie: widełki [najmniej, najwięcej] stopnia T7 i T1, stopnie pomiędzy - po równo (`tier_range`; widełki
## zachodzą na siebie). T1 to mniej więcej dawna premia z 40. poziomu lochu. `slots` - tylko w tych miejscach (bez
## pola - wszędzie), `from` - od tego poziomu lochu (bez pola - od 1.).
const AFFIXES := {
	"hp": {"t7": [6.0, 14.0], "t1": [100.0, 280.0]},
	"mana": {"t7": [5.0, 12.0], "t1": [24.0, 38.0]},
	"damage_pct": {"t7": [4.0, 9.0], "t1": [23.0, 34.0]},
	"attack_speed_pct": {"t7": [3.0, 7.0], "t1": [16.0, 24.0]},
	"move_pct": {"t7": [3.0, 6.0], "t1": [9.0, 14.0]},
	"regen": {"t7": [0.4, 1.2], "t1": [6.5, 24.0]},
	"protection_pct": {"t7": [2.0, 5.0], "t1": [8.0, 13.0]},
	"xp_pct": {"t7": [4.0, 10.0], "t1": [17.0, 27.0]},
	"crit_pct": {"t7": [2.0, 4.0], "t1": [5.0, 8.0]},
	"crit_dmg_pct": {"t7": [10.0, 20.0], "t1": [26.0, 42.0]},
	"life_on_kill": {"t7": [1.0, 2.0], "t1": [16.0, 40.0]},
	"cdr_pct": {"t7": [3.0, 6.0], "t1": [8.0, 12.0]},
	"elite_dmg_pct": {"t7": [6.0, 12.0], "t1": [22.0, 34.0]},
	"mana_regen": {"t7": [0.3, 0.8], "t1": [1.3, 2.1]},
	"mana_on_kill": {"t7": [0.2, 0.4], "t1": [0.4, 0.6]},
	"area_pct": {"t7": [4.0, 8.0], "t1": [10.0, 17.0]},
	"dodge_pct": {"t7": [2.0, 4.0], "t1": [5.0, 8.0]},
	"pickup_pct": {"t7": [10.0, 20.0], "t1": [26.0, 42.0]},
	"ember_pct": {"t7": [4.0, 8.0], "t1": [14.0, 21.0]},
	"element_res_pct": {"t7": [5.0, 10.0], "t1": [15.0, 23.0]},
	"pen_pct": {"t7": [2.0, 5.0], "t1": [5.0, 9.0]},
	"reserve_pct": {"t7": [2.0, 4.0], "t1": [4.0, 6.0], "slots": ["ring", "amulet"]},
	"elem_dmg_pct": {"t7": [6.0, 12.0], "t1": [32.0, 45.0]},
	"magic_dmg_pct": {"t7": [6.0, 12.0], "t1": [32.0, 45.0]},
	"cast_speed_pct": {"t7": [3.0, 7.0], "t1": [16.0, 24.0]},
	"skill_level": {"t7": [1.0, 1.0], "t1": [2.0, 2.0], "slots": ["earring", "helmet", "amulet"]},
	"skill_level_all": {"t7": [1.0, 1.0], "t1": [1.0, 1.0], "slots": ["amulet"], "from": 22},
	"proj_dmg_pct": {"t7": [4.0, 8.0], "t1": [25.0, 35.0]},
	"area_dmg_pct": {"t7": [4.0, 8.0], "t1": [25.0, 35.0]},
	"melee_dmg_pct": {"t7": [4.0, 8.0], "t1": [25.0, 35.0]},
	"minion_dmg_pct": {"t7": [4.0, 8.0], "t1": [25.0, 35.0]},
	"proj_speed_pct": {"t7": [4.0, 8.0], "t1": [25.0, 35.0]},
	"duration_pct": {"t7": [3.0, 6.0], "t1": [20.0, 30.0]},
	"afflicted_dmg_pct": {"t7": [5.0, 10.0], "t1": [30.0, 40.0]},
	"full_hp_dmg_pct": {"t7": [5.0, 10.0], "t1": [30.0, 40.0]},
	"kill_haste_pct": {"t7": [3.0, 5.0], "t1": [15.0, 20.0]},
	"rarity_pct": {"t7": [4.0, 8.0], "t1": [20.0, 30.0], "slots": ["ring", "amulet", "helmet", "boots"]},
	"quantity_pct": {"t7": [4.0, 8.0], "t1": [20.0, 30.0], "slots": ["ring", "amulet", "helmet", "boots"]},
	"ore_pct": {"t7": [4.0, 8.0], "t1": [20.0, 30.0], "slots": ["ring", "amulet", "helmet", "boots"]},
}
## Premia skill_level: stopnie T2 i T1 dają +2, niższe +1 (widełki tylko do pokazania w oknie).
const SKILL_LEVEL_T2 := 2
## Najwyżej tyle poziomów ponad Skills.MAX_LEVEL dają przedmioty (umiejętność do 12. poziomu).
const ITEM_LEVELS_MAX := 2
## Premia kill_haste_pct działa przez tyle sekund po zabiciu.
const KILL_HASTE_TIME := 3.0
## Premie z ułamkiem (jedno miejsce po przecinku), reszta - liczby całkowite.
const DECIMAL_STATS := ["regen", "mana_regen", "mana_on_kill"]
## Premie many rosły kiedyś z siłą lochu (x152 na 101. poziomie - mana bez końca, uwaga autora 17.11.2026); teraz liniowo.
## Stare przedmioty i kamienie szlachetne są przycinane do nowej górnej granicy (`clamp_affix`).
const CLAMPED_STATS := ["mana", "mana_regen"]
## Zdrowie za zabicie działa w tylu częściach wartości z przedmiotu (uwaga autora 17.11.2026: setki zabójstw na wyprawę
## robiły z postaci nieśmiertelną; było 1-2 za zabicie, teraz 0,25-0,5). Mnożnik zamiast nowych liczb, żeby stare
## przedmioty i kamienie szlachetne osłabły tak samo jak nowe.
const LIFE_ON_KILL_MULT := 0.25


## Zdrowie za jedno zabicie z sumy cech (`gear`).
static func life_on_kill(gear: Dictionary) -> float:
	return gear.get("life_on_kill", 0.0) * LIFE_ON_KILL_MULT
## Sufity sumy z całego ekwipunku (żeby postać nie stała się nieśmiertelna ani nie fruwała po lochu).
## Szansa na krytyk: 95% z przedmiotów + bazowe 5% = pewny krytyk; odnowienie aż do zera (decyzja autora 13.11.2026:
## osiągalne, ale bardzo trudne - premie na jednym przedmiocie są małe; przy zerowym odnowieniu hamulcem zostaje mana).
## Unik do 50% (połowa ciosów nadal trafia), obszar do +100%, zasięg zbierania do +200%, żar do +100%.
const CAPS := {"protection_pct": 50.0, "move_pct": 50.0, "attack_speed_pct": 75.0, "cast_speed_pct": 75.0, "crit_pct": 95.0, "cdr_pct": 100.0,
	"dodge_pct": 50.0, "area_pct": 100.0, "pickup_pct": 200.0, "ember_pct": 100.0,
	"element_res_pct": Elements.MAX_RESISTANCE * 100.0, "pen_pct": 55.0, "mana_on_kill": 2.0,
	"reserve_pct": 20.0, "proj_speed_pct": 100.0, "duration_pct": 100.0, "kill_haste_pct": 50.0, "rarity_pct": 200.0,
	"quantity_pct": 100.0, "ore_pct": 200.0, "skill_level_all": 3.0}
## Gniazda: najwięcej w przedmiocie i szansa na drugie od razu (według rzadkości - bardzo rzadko).
const MAX_SOCKETS := 2
const SECOND_SOCKET := {"common": 0.0, "magic": 0.01, "rare": 0.03, "legendary": 0.1, "unique": 0.0}
## Rozbicie przedmiotu (decyzja autora 20.11.2026, zamiast sprzedaży za złoto): ruda według rzadkości, rzadki
## dodatkowo z szansą SCRAP_RUNE daje Runę Szlifu (obie liczby rosną ze Skarbcem drzewka lochów - Game.treasury_mult).
const ORE := {"common": 1, "magic": 2, "rare": 4, "legendary": 8, "unique": 10}
const SCRAP_RUNE := 0.15
## Wykuwanie u kowala (decyzja autora 20.11.2026): FORGE_ORE rudy za przedmiot z wybranego miejsca, z najgłębszego
## przebitego lochu, rzadkość losowana wagami FORGE_WEIGHTS (jak skrzynia Wodza) - Game.forge.
const FORGE_ORE := 20
const FORGE_WEIGHTS := {"common": 35, "magic": 45, "rare": 20}


## Stopień wyglądu przedmiotu (0-4) z poziomu lochu.
static func tier_for(level: int) -> int:
	var t := 0
	for i in VISUAL_FROM.size():
		if maxi(level, 1) >= VISUAL_FROM[i]:
			t = i
	return t


## Bazy miejsca w kolejności (pierwsza - dawna).
static func bases_of(slot: String) -> Array:
	return BASES[slot].keys() if BASES.has(slot) else []


## Baza przedmiotu (stare zapisy bez pola - pierwsza baza miejsca).
static func type_of(item: Dictionary) -> String:
	var t: String = item.get("type", "")
	return t if BASES.get(item.get("slot", ""), {}).has(t) else str(bases_of(item.get("slot", "earring"))[0])


## Stała cecha bazy na poziomie lochu (do MAX_LEVEL): od wartości z 1. poziomu do tej z MAX_LEVEL - liniowo albo
## (CURVED_STATS) jak siła lochu.
static func implicit_value(stat: String, range_: Array, level: int) -> float:
	var l := clampi(level, 1, MAX_LEVEL)
	var f := float(l - 1) / float(MAX_LEVEL - 1)
	if stat in CURVED_STATS:
		f = (DungeonLevels.power(l) - 1.0) / (DungeonLevels.power(MAX_LEVEL) - 1.0)
	var v := lerpf(range_[0], range_[1], f)
	return snappedf(v, 0.1) if stat in DECIMAL_STATS else float(roundi(v))


## Stałe cechy nowego przedmiotu bazy `type` z miejsca `slot` (kolczyk - też obrażenia ciosu, lekko losowe).
static func roll_base(slot: String, type: String, level: int) -> Dictionary:
	var base := {}
	if slot == "earring":
		var m := (1.0 + EARRING_GROWTH * (clampi(level, 1, MAX_LEVEL) - 1)) * randf_range(0.92, 1.08)
		base["damage"] = [roundi(EARRING_DAMAGE.x * m), roundi(EARRING_DAMAGE.y * m)]
	var implicit: Dictionary = BASES[slot][type].implicit
	for stat in implicit:
		base[stat] = implicit_value(stat, implicit[stat], level)
	return base


## Nowy przedmiot: miejsce (puste - losowe), poziom lochu, rzadkość (pusta - losowana wagami `weights`, z łupu
## z szansą `legend_chance` legendarny), baza (pusta - losowa z miejsca). `loot` - z łupu (legendy i premie ponad
## widełki); kuźnia podaje false.
static func roll(level: int, slot := "", rarity := "", weights := GOBLIN_WEIGHTS, type := "", loot := true) -> Dictionary:
	if loot and Dungeons.is_deep(level):  # Głębiny: lepsze rzadkości
		weights = boosted_weights(weights, minf(DEEP_RARITY_STEP * Dungeons.deep_of(level), DEEP_RARITY_MAX))
	if rarity == "unique" or (rarity == "" and loot and randf() < unique_chance(level)):
		var ids: Array = UNIQUES.keys().filter(func(id: String) -> bool:
			return (slot == "" or UNIQUES[id].slot == slot) and not UNIQUES[id].has("source"))
		return make_unique(ids.pick_random(), level)
	if slot == "":
		slot = SLOTS[randi() % SLOTS.size()]
	if rarity == "":
		rarity = "legendary" if loot and randf() < legend_chance(level) else roll_rarity(weights)
	if not BASES[slot].has(type):
		type = bases_of(slot).pick_random()
	var pot := randi_range(POTENTIAL.x, POTENTIAL.y)
	var item := {"slot": slot, "type": type, "tier": tier_for(level), "level": maxi(level, 1), "rarity": rarity,
			"base": roll_base(slot, type, level), "affixes": [], "sockets": [""], "potential": pot, "potential_max": pot}
	for i in randi_range(AFFIX_COUNT[rarity].x, AFFIX_COUNT[rarity].y):
		add_affix(item)
	if loot:
		var chance := above_chance(level)
		for i in item.affixes.size():
			if randf() < chance:
				make_above(item, i)
	if randf() < SECOND_SOCKET[rarity]:
		item.sockets.append("")
	return item


## Szansa, że przedmiot z łupu będzie unikatem (od UNIQUE_FROM, rośnie z głębią do UNIQUE_MAX na MAX_LEVEL; w Głębinach
## jeszcze x `deep_loot`).
static func unique_chance(level: int) -> float:
	if level < UNIQUE_FROM:
		return 0.0
	return lerpf(UNIQUE_CHANCE, UNIQUE_MAX, float(mini(level, MAX_LEVEL) - UNIQUE_FROM) / float(MAX_LEVEL - UNIQUE_FROM)) \
			* deep_loot(level)


## Mnożnik szans na legendy i unikaty w Głębinach (poza nimi 1).
static func deep_loot(level: int) -> float:
	return minf(1.0 + DEEP_LOOT_STEP * Dungeons.deep_of(level), DEEP_LOOT_MAX)


## Szansa, że premia przedmiotu z łupu wyjdzie ponad widełki (od MAX_LEVEL wyższa, w Głębinach rośnie z Głębią).
static func above_chance(level: int) -> float:
	if level < MAX_LEVEL:
		return ABOVE_CHANCE
	return minf(ABOVE_CHANCE_DEEP + ABOVE_DEEP_STEP * Dungeons.deep_of(level), ABOVE_DEEP_MAX)


## Nowy unikat `id` z poziomu lochu `level`: stała baza, premie i siła działania losowane w wąskich widełkach,
## bez potencjału kowalskiego (kowal go nie przerabia).
static func make_unique(id: String, level: int) -> Dictionary:
	var u: Dictionary = UNIQUES[id]
	var stats := {}
	for stat in u.stats:
		stats[stat] = float(roundi(randf_range(u.stats[stat][0], u.stats[stat][1])))
	return {"slot": u.slot, "type": u.type, "tier": tier_for(level), "level": maxi(level, 1), "rarity": "unique",
			"unique": id, "base": roll_base(u.slot, u.type, level), "ustats": stats,
			"upower": float(roundi(randf_range(u.power[0], u.power[1]))), "affixes": [], "sockets": [""],
			"potential": 0, "potential_max": 0}


static func is_unique(item: Dictionary) -> bool:
	return item.get("rarity", "") == "unique" and UNIQUES.has(item.get("unique", ""))


## Poziom unikatu (1-UNIQUE_MAX_LEVEL; bez pola - 1).
static func unique_level(item: Dictionary) -> int:
	return clampi(int(item.get("ulevel", 1)), 1, UNIQUE_MAX_LEVEL)


## Mnożnik dodatnich premii i siły unikatu z jego poziomu.
static func unique_mult(item: Dictionary) -> float:
	return 1.0 + UNIQUE_LEVEL_STEP * (unique_level(item) - 1)


## Premia unikatu po poziomie (ujemna - kara, bez zmian).
static func unique_stat(item: Dictionary, stat: String) -> float:
	var v := float(item.get("ustats", {}).get(stat, 0.0))
	return v * unique_mult(item) if v > 0.0 else v


## Siła działania unikatu po poziomie.
static func unique_power(item: Dictionary) -> float:
	return float(item.get("upower", 0.0)) * unique_mult(item)


## Ile esencji kosztuje podniesienie unikatu z poziomu `level` (0 - już najwyższy).
static func essence_cost(level: int) -> int:
	return level if level < UNIQUE_MAX_LEVEL else 0


## Ile esencji włożono w unikat (wracają przy rozbiciu).
static func essences_in(item: Dictionary) -> int:
	var l := unique_level(item)
	return (l - 1) * l / 2


## Liczba do opisu: całkowita bez ułamka, inaczej jedno miejsce po przecinku.
static func _num(v: float) -> String:
	return str(roundi(v)) if is_equal_approx(v, roundf(v)) else ("%.1f" % v)


## Opis działania unikatu `id` z siłą `power`.
static func unique_effect(id: String, power: float) -> String:
	match id:
		"licho":
			return Lang.t("Bez trafień krytycznych - za to co %d. trafienie zadaje x%s obrażeń") % [LICHO_EVERY, _num(power)]
		"crown":
			return Lang.t("Umiejętności i aury płacą zdrowiem zamiast many")
		"bastion":
			return Lang.t("Za każdego wroga blisko postaci: +%s%% obrażeń i +%d%% odporności na wszystko (do %d wrogów)") \
					% [_num(power), roundi(BASTION_RES), BASTION_MAX]
		"swarog":
			return Lang.t("Za postacią zostaje płonący ślad: %d%% obrażeń broni na sekundę i podpalenie") % roundi(power)
		"strzybog":
			return Lang.t("Pocisk przy trafieniu rozpada się na %d odłamki w pobliskich wrogów (%d%% siły pocisku)") \
					% [STRZYBOG_SHARDS, roundi(strzybog_power(power) * 100.0)]
		"mokosz":
			return Lang.t("Umiejętności (oprócz zwykłego ataku) powtarzają się same po chwili z %d%% siły; koszt many x1,8") \
					% roundi(power)
		"zmij_fang":
			return Lang.t("Co %d s %d kule ognia spadają na najbliższych wrogów: %d%% obrażeń broni i podpalenie") \
					% [roundi(ZMIJ_FANG_EVERY), ZMIJ_FANG_BALLS, roundi(power)]
		"zmij_scale":
			return Lang.t("Gdy cię zranią, wokół wybucha ognisty krąg: %d%% obrażeń broni i podpalenie (co %d s)") \
					% [roundi(power), roundi(ZMIJ_SCALE_COOLDOWN)]
	return ""


## Siła odłamków Pierścienia Strzyboga (część siły pocisku) z siły unikatu (bazowo STRZYBOG_BASE -> STRZYBOG_POWER).
const STRZYBOG_BASE := 3.0
static func strzybog_power(power: float) -> float:
	return STRZYBOG_POWER * power / STRZYBOG_BASE


## Linie unikatu do opisu: stałe premie po poziomie (kara - z minusem), działanie i cytat.
static func unique_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var stats: Dictionary = item.get("ustats", {})
	for stat in stats:
		var v := unique_stat(item, stat)
		var text := Lang.t("+%d%% zdrowia") % roundi(absf(v)) if stat == "hp_pct" else stat_text(stat, absf(v))
		lines.append(("-" + text.substr(1)) if v < 0.0 and text.begins_with("+") else text)
	lines.append(unique_effect(item.unique, unique_power(item)))
	lines.append("„%s”" % Lang.t(UNIQUES[item.unique].flavor))
	return lines


## Szansa, że przedmiot z łupu będzie legendarny (rośnie z głębią lochu).
static func legend_chance(level: int) -> float:
	return minf(LEGEND_CHANCE * (1.0 + float(maxi(level, 1)) / MAX_LEVEL), LEGEND_MAX) * deep_loot(level)


## Premia `index` przedmiotu ponad widełki: najlepszy stopień z poziomu przedmiotu i wartość ponad jego górną granicę.
## False - premia już ponad albo taka, która nie wychodzi ponad (ABOVE_SKIP).
static func make_above(item: Dictionary, index: int) -> bool:
	var a: Dictionary = item.affixes[index]
	if a.get("above", false) or a.stat in ABOVE_SKIP:
		return false
	a.tier = mini(int(a.get("tier", TIERS)), best_tier(item.level))
	a.above = true
	a.value = above_value(a.stat, a.tier)
	return true


## Losowa wartość premii ponad widełki stopnia `tier`.
static func above_value(stat: String, tier: int) -> float:
	var v := tier_range(stat, tier).y * (1.0 + randf_range(ABOVE_MIN, ABOVE_MAX))
	return snappedf(v, 0.1) if stat in DECIMAL_STATS else float(maxi(roundi(v), roundi(tier_range(stat, tier).y) + 1))


## Czy któraś premia jest ponad widełkami.
static func has_above(item: Dictionary) -> bool:
	return item.get("affixes", []).any(func(a: Dictionary) -> bool: return a.get("above", false))


## Anielski przedmiot: wszystkie premie (co najmniej jedna) ponad widełkami.
static func is_angelic(item: Dictionary) -> bool:
	var list: Array = item.get("affixes", [])
	return not list.is_empty() and list.all(func(a: Dictionary) -> bool: return a.get("above", false))


## Potencjał kowalski przedmiotu: [ile zostało, ile najwięcej] (stare bez pola - pełny POTENTIAL.y).
static func potential_of(item: Dictionary) -> Vector2i:
	var most := int(item.get("potential_max", POTENTIAL.y))
	return Vector2i(clampi(int(item.get("potential", most)), 0, most), most)


## Linia potencjału kowalskiego do opisu przedmiotu.
static func potential_line(item: Dictionary) -> String:
	if is_unique(item):
		return Lang.t("Unikatu nie da się przerobić u kowala")
	var p := potential_of(item)
	return Lang.t("Potencjał kowalski: %d / %d") % [p.x, p.y]


## Czy premia może wypaść na przedmiocie z miejsca `slot` (pole "slots" w AFFIXES; bez niego - wszędzie) i poziomu
## lochu `level` (pole "from"). Mniejsza rezerwacja many (aury, decyzja autora 19.11.2026) - tylko pierścień i amulet.
static func affix_fits(stat: String, slot: String, level := MAX_LEVEL) -> bool:
	var a: Dictionary = AFFIXES[stat]
	return (not a.has("slots") or slot in a.slots) and level >= int(a.get("from", 1))


## Nowa losowa premia rodzaju, którego przedmiot jeszcze nie ma (pasującego do miejsca i poziomu). False - brak.
static func add_affix(item: Dictionary) -> bool:
	var taken: Array = item.affixes.map(func(a: Dictionary) -> String: return a.stat)
	var pool: Array = AFFIXES.keys().filter(func(stat: String) -> bool:
		return not stat in taken and affix_fits(stat, item.slot, item.level))
	if pool.is_empty():
		return false
	item.affixes.append(make_affix(pool.pick_random(), item.level, 0, LEGEND_TIER_BOOST if item.rarity == "legendary" else 0))
	return true


## Premia `stat` z losowym stopniem dostępnym na poziomie lochu `level` (`tier` > 0 - ten stopień; `boost` - o tyle
## stopni lepiej, legendarny).
static func make_affix(stat: String, level: int, tier := 0, boost := 0) -> Dictionary:
	if tier <= 0:
		tier = maxi(roll_tier(level) - boost, 1)
	var a := {"stat": stat, "value": tier_value(stat, tier), "tier": tier}
	if stat == "skill_level":
		a.skill = Skills.ORDER.pick_random()
	return a


## Najlepszy stopień premii (1-7) dostępny na poziomie lochu.
static func best_tier(level: int) -> int:
	var best := TIERS
	for i in TIER_FROM.size():
		if maxi(level, 1) >= TIER_FROM[i]:
			best = TIERS - i
	return best


## Losowy stopień premii dostępny na poziomie lochu (wagi TIER_WEIGHTS).
static func roll_tier(level: int) -> int:
	var best := best_tier(level)
	var total := 0
	for i in TIERS - best + 1:
		total += TIER_WEIGHTS[i]
	var pick := randi() % total
	for i in TIERS - best + 1:
		pick -= TIER_WEIGHTS[i]
		if pick < 0:
			return TIERS - i
	return TIERS


## Widełki premii `stat` stopnia `tier` (Vector2: najmniej, najwięcej).
static func tier_range(stat: String, tier: int) -> Vector2:
	var a: Dictionary = AFFIXES[stat]
	if stat == "skill_level":
		var v := 2.0 if tier <= SKILL_LEVEL_T2 else 1.0
		return Vector2(v, v)
	var f := float(TIERS - clampi(tier, 1, TIERS)) / float(TIERS - 1)
	return Vector2(lerpf(a.t7[0], a.t1[0], f), lerpf(a.t7[1], a.t1[1], f))


## Losowa wartość premii `stat` w widełkach stopnia `tier`.
static func tier_value(stat: String, tier: int) -> float:
	var r := tier_range(stat, tier)
	var v := randf_range(r.x, r.y)
	return snappedf(v, 0.1) if stat in DECIMAL_STATS else float(roundi(v))


## Najwyższa wartość premii `stat` na poziomie lochu `level` (górna granica najlepszego stopnia, bez losowania).
static func affix_max(stat: String, level: int) -> float:
	return tier_range(stat, best_tier(level)).y


## Premia z CLAMPED_STATS przycięta do górnej granicy z jej poziomu (`mult` - kamienie szlachetne, część premii).
static func clamp_affix(stat: String, value: float, level: int, mult := 1.0) -> float:
	if stat not in CLAMPED_STATS:
		return value
	return minf(value, snappedf(affix_max(stat, level) * mult, 0.1))


## Wartość losowej premii na danym poziomie lochu (losowy stopień; kamienie szlachetne).
static func roll_affix(stat: String, level: int) -> float:
	return tier_value(stat, roll_tier(level))


## Runa Szlifu: nowa wartość premii w widełkach jej stopnia (stopień zostaje; premia ponad widełki - nowa wartość
## ponad nimi).
static func polish_affix(a: Dictionary) -> Dictionary:
	var out := a.duplicate()
	var tier := int(a.get("tier", TIERS))
	out.value = above_value(a.stat, tier) if a.get("above", false) else tier_value(a.stat, tier)
	return out


static func roll_rarity(weights: Dictionary) -> String:
	var total := 0
	for r in weights:
		total += weights[r]
	var pick := randi() % total
	for r in weights:
		pick -= weights[r]
		if pick < 0:
			return r
	return "common"


## Łup ze skrzyni Wodza: CHEST_ITEMS przedmiotów, pierwszy co najmniej magiczny. Premie przedmiotów: `rarity_pct` -
## lepsze wagi rzadkości, `quantity_pct` - szansa (w procentach) na jeszcze jeden przedmiot.
static func roll_chest(level: int, rarity_pct := 0.0, quantity_pct := 0.0) -> Array:
	var items: Array = []
	var weights := boosted_weights(CHEST_WEIGHTS, rarity_pct)
	for i in CHEST_ITEMS + (1 if randf() * 100.0 < quantity_pct else 0):
		var item := roll(level, "", "", weights)
		if i == 0 and item.rarity == "common":
			item = roll(level, "", "magic" if randf() < 0.75 else "rare")
		items.append(item)
	return items


## Goblin padł: z szansą GOBLIN_DROP (razy `chance_mult` - ulepszenie łupu) przedmiot, inaczej pusty słownik.
## `weights` - wagi rzadkości (modyfikator lochu Krwawy księżyc - wagi skrzyni bossa).
static func roll_goblin(level: int, chance_mult := 1.0, weights := GOBLIN_WEIGHTS) -> Dictionary:
	return roll(level, "", "", weights) if randf() < GOBLIN_DROP * chance_mult else {}


## Wagi rzadkości z premią „rzadkości łupu” (`rarity_pct`): magiczne i rzadkie częściej (rzadkie podwójnie).
static func boosted_weights(weights: Dictionary, rarity_pct: float) -> Dictionary:
	if rarity_pct <= 0.0:
		return weights
	var w := weights.duplicate()
	w.magic = roundi(w.magic * (1.0 + rarity_pct / 100.0))
	w.rare = roundi(w.rare * (1.0 + 2.0 * rarity_pct / 100.0))
	return w


## Nazwa przedmiotu w obecnym języku (anielski - z przedrostkiem w rodzaju nazwy bazy).
static func name_of(item: Dictionary) -> String:
	if is_unique(item):
		return Lang.t(UNIQUES[item.unique].name)
	var base: String = BASES[item.slot][type_of(item)].names[clampi(int(item.get("tier", 0)), 0, 4)]
	if not is_angelic(item):
		return Lang.t(base)
	var word := base.split(" ")[0]
	var fmt := "Anielska %s" if word.ends_with("a") else ("Anielskie %s" if word.ends_with("e") or word.ends_with("y") else "Anielski %s")
	var shown := Lang.t(base)
	return Lang.t(fmt) % (shown.left(1).to_lower() + shown.substr(1))


## Nazwa bazy (najniższy stopień - do wyboru u kowala).
static func base_name(slot: String, type: String) -> String:
	return Lang.t(BASES[slot][type].names[0])


static func color_of(item: Dictionary) -> Color:
	return RARITY_COLORS.get(item.get("rarity", "common"), RARITY_COLORS.common)


## Ikona przedmiotu (wersja magiczna i rzadka mają inne kolory, jak w Watrze; legendarny - jak rzadki).
static func icon_of(item: Dictionary) -> Texture2D:
	var suffix: String = {"common": "", "magic": "_magic", "rare": "_rare", "legendary": "_rare", "unique": "_rare"}.get(item.get("rarity", "common"), "")
	return base_icon(item.slot, type_of(item), int(item.get("tier", 0)), suffix)


## Ikona bazy na stopniu wyglądu `tier` (`suffix` - "", "_magic", "_rare").
static func base_icon(slot: String, type: String, tier := 0, suffix := "") -> Texture2D:
	return load("res://assets/%s%s.png" % [BASES[slot][type].icons[clampi(tier, 0, 4)], suffix])


static func slot_icon(slot: String) -> Texture2D:
	return load("res://assets/watra/items/%s.png" % SLOT_ICONS[slot])


## Opis pod nazwą: „Rzadki - Hełm, loch 3”.
static func kind_line(item: Dictionary) -> String:
	return Lang.t("%s - %s, loch %d") % [Lang.t(RARITY_NAMES[item.rarity]), Lang.t(SLOT_NAMES[item.slot]), item.level]


## Opis jednej cechy z liczbą („+12 do zdrowia”).
static func stat_text(stat: String, value: float) -> String:
	if stat == "damage":
		return ""
	if stat == "life_on_kill":
		return Lang.t(STAT_FORMATS[stat]) % (value * LIFE_ON_KILL_MULT)
	if stat in DECIMAL_STATS:
		return Lang.t(STAT_FORMATS[stat]) % value
	return Lang.t(STAT_FORMATS[stat]) % roundi(value)


## Opis premii przedmiotu bez stopnia (poziom jednej umiejętności - z jej nazwą).
static func affix_text(a: Dictionary) -> String:
	if a.stat == "skill_level":
		return Lang.t("+%d do poziomu: %s") % [roundi(a.value), Skills.name_of(a.get("skill", ""))]
	return stat_text(a.stat, a.value)


## Znaczek stopnia premii („T3”, ponad widełki - „T3+”).
static func tier_badge(a: Dictionary) -> String:
	return "T%d%s" % [int(a.get("tier", TIERS)), "+" if a.get("above", false) else ""]


## Kolor znaczka premii (ponad widełki - ABOVE_COLOR).
static func affix_color(a: Dictionary) -> Color:
	return ABOVE_COLOR if a.get("above", false) else tier_color(int(a.get("tier", TIERS)))


## Kolor ramki pola z przedmiotem: anielski, rzadkość (zwykły - brązowy) i grubość (ponad widełki - grubsza).
static func frame_of(item: Dictionary) -> Array:
	if is_unique(item):
		return [RARITY_COLORS.unique, 3]
	if is_angelic(item):
		return [ANGELIC_COLOR, 3]
	var color: Color = color_of(item) if item.get("rarity", "common") != "common" else Color(0.7, 0.6, 0.45)
	return [color, 3 if has_above(item) else 2]


## Kolor znaczka stopnia.
static func tier_color(tier: int) -> Color:
	return TIER_COLORS[clampi(tier, 1, TIERS) - 1]


## Linie stałej cechy przedmiotu (kolczyk - obrażenia ciosu).
static func base_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for stat in item.base:
		if stat == "damage":
			lines.append(Lang.t("Obrażenia ciosu: %d-%d") % [item.base.damage[0], item.base.damage[1]])
		else:
			lines.append(stat_text(stat, item.base[stat]))
	return lines


## Siła przedmiotu do strzałki „lepszy” na ziemi (ankieta autora 21.11.2026): premie według stopnia (T1 - 7 punktów,
## T7 - 1), premia ponad widełki x ABOVE_SCORE, do tego poziom lochu (stała cecha rośnie z nim do MAX_LEVEL).
const ABOVE_SCORE := 1.3
const LEVEL_SCORE := 0.15


static func score(item: Dictionary) -> float:
	var s := LEVEL_SCORE * mini(int(item.get("level", 1)), MAX_LEVEL)
	for a in item.get("affixes", []):
		s += (TIERS + 1 - int(a.get("tier", TIERS))) * (ABOVE_SCORE if a.get("above", false) else 1.0)
	return s


## Czy `item` jest lepszy od założonego `worn` (pusty - nic nie założono): unikat - gdy nie ma założonego tego samego,
## założonego unikatu nic nie zastępuje, reszta - większa siła (`score`).
static func is_upgrade(item: Dictionary, worn: Dictionary) -> bool:
	if worn.is_empty():
		return true
	if is_unique(item):
		return not (is_unique(worn) and worn.unique == item.unique)
	if is_unique(worn):
		return false
	return score(item) > score(worn)


## Kolor linii `i` z `affix_lines` (premia ponad widełki, zwykła premia, unikat - jego kolor, cytat przygaszony).
static func line_color(item: Dictionary, i: int) -> Color:
	if is_unique(item):
		return RARITY_COLORS.unique.darkened(0.25) if i == affix_lines(item).size() - 1 else RARITY_COLORS.unique
	if i < item.affixes.size() and item.affixes[i].get("above", false):
		return ABOVE_COLOR
	return RARITY_COLORS.magic


## Linie premii ze znaczkiem stopnia („T3  +12% obrażeń”); unikat - jego stałe premie i działanie (`unique_lines`).
static func affix_lines(item: Dictionary) -> Array[String]:
	if is_unique(item):
		return unique_lines(item)
	var lines: Array[String] = []
	for a in item.affixes:
		lines.append("%s  %s" % [tier_badge(a), affix_text(a)])
	return lines


## Ile rudy daje rozbicie (bez premii Skarbca).
static func ore_value(item: Dictionary) -> int:
	return ORE.get(item.get("rarity", "common"), 1)


## Runa Przekucia (Runes): premia `index` losowana od nowa - rodzaj (spośród tych, których przedmiot jeszcze nie ma; może wypaść
## ten sam), stopień i siła z poziomu przedmiotu. Zmienia przedmiot w miejscu i liczy przeróbki. Zwraca false przy złym indeksie.
static func reroll_affix(item: Dictionary, index: int) -> bool:
	if index < 0 or index >= item.get("affixes", []).size():
		return false
	var taken: Array = []
	for i in item.affixes.size():
		if i != index:
			taken.append(item.affixes[i].stat)
	var pool: Array = AFFIXES.keys().filter(func(stat: String) -> bool:
		return not stat in taken and affix_fits(stat, item.slot, item.level))
	item.affixes[index] = make_affix(pool.pick_random(), item.level)
	item.rerolls = int(item.get("rerolls", 0)) + 1
	return true


## Suma cech założonych przedmiotów (słownik miejsce -> przedmiot). Klucze ze STAT_FORMATS (z sufitami CAPS),
## "damage" - obrażenia cięcia założonej broni jako Vector2i (bez broni: Vector2i.ZERO) i "skill_bonus" - poziomy
## pojedynczych umiejętności z premii skill_level (umiejętność -> ile), "uniques" - założone unikaty (id -> siła
## działania) i "hp_pct" - procent największego zdrowia z unikatów.
static func totals(equipped: Dictionary) -> Dictionary:
	var t := {"damage": Vector2i.ZERO, "skill_bonus": {}, "uniques": {}, "hp_pct": 0.0}
	for stat in STAT_FORMATS:
		t[stat] = 0.0
	for slot in equipped:
		var item: Dictionary = equipped[slot]
		for stat in item.base:
			if stat == "damage":
				t.damage = Vector2i(item.base.damage[0], item.base.damage[1])
			else:
				t[stat] += float(item.base[stat])
		for a in item.affixes:
			if a.stat == "skill_level":
				var skill: String = a.get("skill", "")
				t.skill_bonus[skill] = int(t.skill_bonus.get(skill, 0)) + roundi(a.value)
			t[a.stat] += float(a.value)
		if is_unique(item):
			t.uniques[item.unique] = unique_power(item)
			var stats: Dictionary = item.get("ustats", {})
			for stat in stats:
				t[stat] = t.get(stat, 0.0) + unique_stat(item, stat)
		for id in item.get("sockets", []):
			for gem in Gems.jewel_stats(id):
				t[gem[0]] += clamp_affix(gem[0], gem[1], Gems.jewel_level(id), Gems.JEWEL_MULT)
	t["element_res_raw"] = t.element_res_pct  # surowa suma - aura Hart Żywiołów podnosi sufit (Auras.apply)
	for stat in CAPS:
		t[stat] = minf(t[stat], CAPS[stat])
	return t


const WEAPON_DAMAGE := "weapon_damage"


## Obrażenia cięcia z najmniejszej wartości (rozrzut jak u broni: najwięcej = 1,4 x najmniej).
static func weapon_damage_from(low: float) -> Vector2i:
	return Vector2i(roundi(low), roundi(low * 1.4))


## Suma cech z nadpisanymi statystykami trybu deweloperskiego (statystyka -> wartość, najwyżej do sufitu CAPS).
static func with_overrides(t: Dictionary, overrides: Dictionary) -> Dictionary:
	for stat in overrides:
		if stat == WEAPON_DAMAGE:
			t.damage = weapon_damage_from(overrides[stat])
		elif t.has(stat):
			t[stat] = minf(float(overrides[stat]), CAPS.get(stat, INF))
	return t


## Linie kamieni w gniazdach („Rubin - Odłamek: +20 do zdrowia”); puste gniazdo - „Puste gniazdo”.
static func socket_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for id in item.get("sockets", []):
		if id == "":
			lines.append(Lang.t("Puste gniazdo"))
		else:
			lines.append(Lang.t("%s: %s") % [Gems.name_of(id), Gems.jewel_text(id)])
	return lines


## Stopień, w którego widełki najlepiej pasuje stara premia bez stopnia (zapisy sprzed 21.11.2026) - spośród
## dostępnych na poziomie lochu `level`.
static func nearest_tier(stat: String, value: float, level: int) -> int:
	var best := TIERS
	var best_d := INF
	for tier in range(TIERS, best_tier(level) - 1, -1):
		var r := tier_range(stat, tier)
		var d := absf(value - (r.x + r.y) / 2.0)  # najbliżej środka widełek
		if d < best_d:
			best_d = d
			best = tier
	return best


## Przedmiot wczytany z JSON-a (liczby przychodzą jako float) - typy jak przy losowaniu. Zły wpis - pusty słownik.
## Stare zapisy (sprzed gniazd) dostają jedno puste gniazdo; sprzed baz i stopni (21.11.2026) - pierwszą bazę
## miejsca (stała cecha liczona od nowa z poziomu, do MAX_LEVEL), a premie - najbliższy stopień i wartość w jego widełkach.
static func normalize(data) -> Dictionary:
	if data is Dictionary and LEGACY_SLOTS.has(data.get("slot", "")):
		data = data.duplicate()
		data.slot = LEGACY_SLOTS[data.slot]
	if not (data is Dictionary) or not SLOTS.has(data.get("slot", "")) or not RARITIES.has(data.get("rarity", "")):
		return {}
	var level := maxi(int(data.get("level", 1)), 1)
	var converted: bool = not BASES[data.slot].has(data.get("type", ""))
	var type: String = bases_of(data.slot)[0] if converted else data.type
	var base := {}
	var raw_base = data.get("base", {})
	if raw_base is Dictionary:
		for stat in raw_base:
			if stat == "damage" and raw_base[stat] is Array and raw_base[stat].size() == 2:
				var cap := (1.0 + EARRING_GROWTH * (MAX_LEVEL - 1)) * 1.08
				base[stat] = [mini(int(raw_base[stat][0]), roundi(EARRING_DAMAGE.x * cap)),
						mini(int(raw_base[stat][1]), roundi(EARRING_DAMAGE.y * cap))]
			elif STAT_FORMATS.has(stat) and not converted:
				base[stat] = snappedf(float(raw_base[stat]), 0.1) if stat in DECIMAL_STATS else float(int(raw_base[stat]))
	if converted:
		var implicit: Dictionary = BASES[data.slot][type].implicit
		for stat in implicit:
			base[stat] = implicit_value(stat, implicit[stat], level)
	if data.slot == "earring" and not base.has("damage"):
		var m := 1.0 + EARRING_GROWTH * (clampi(level, 1, MAX_LEVEL) - 1)
		base["damage"] = [roundi(EARRING_DAMAGE.x * m), roundi(EARRING_DAMAGE.y * m)]
	var affixes: Array = []
	var raw_affixes = data.get("affixes", [])
	if raw_affixes is Array:
		for a in raw_affixes:
			if not (a is Dictionary) or not AFFIXES.has(a.get("stat", "")):
				continue
			var stat: String = a.stat
			var v := float(a.get("value", 0))
			var tier := int(a.get("tier", 0))
			if tier < 1 or tier > TIERS:
				tier = nearest_tier(stat, v, level)
				var r := tier_range(stat, tier)
				v = clampf(v, r.x, r.y)
			var above: bool = a.get("above", false) == true and not stat in ABOVE_SKIP
			if not above:
				v = clamp_affix(stat, v, level)
			var entry := {"stat": stat, "value": snappedf(v, 0.1) if stat in DECIMAL_STATS else float(roundi(v)), "tier": tier}
			if above:
				entry.above = true
			if stat == "skill_level":
				if not Skills.has(str(a.get("skill", ""))):
					continue
				entry.skill = str(a.skill)
			affixes.append(entry)
	var sockets: Array = []
	var raw_sockets = data.get("sockets", [""])
	if raw_sockets is Array:
		for id in raw_sockets.slice(0, MAX_SOCKETS):
			sockets.append(id if id is String and Gems.is_jewel(id) else "")
	if sockets.is_empty():
		sockets.append("")
	var item := {"slot": data.slot, "type": type, "tier": clampi(int(data.get("tier", tier_for(level))), 0, 4),
			"level": level, "rarity": data.rarity, "base": base, "affixes": affixes, "sockets": sockets}
	if data.rarity == "unique":  # unikat: dane z UNIQUES, wartości przycięte do widełek, bez premii i potencjału
		var id := str(data.get("unique", ""))
		if not UNIQUES.has(id) or UNIQUES[id].slot != data.slot or UNIQUES[id].type != type:
			return {}
		item.unique = id
		item.affixes = []
		var stats := {}
		var raw_stats = data.get("ustats", {})
		for stat in UNIQUES[id].stats:
			var r: Array = UNIQUES[id].stats[stat]
			var v: float = float(raw_stats.get(stat, r[0])) if raw_stats is Dictionary else float(r[0])
			stats[stat] = clampf(v, r[0], r[1])
		item.ustats = stats
		var pr: Array = UNIQUES[id].power
		item.upower = clampf(float(data.get("upower", pr[0])), pr[0], pr[1])
		if int(data.get("ulevel", 1)) > 1:
			item.ulevel = clampi(int(data.ulevel), 1, UNIQUE_MAX_LEVEL)
		item.potential = 0
		item.potential_max = 0
		return item
	var pot := potential_of(data)
	item.potential = pot.x
	item.potential_max = pot.y
	if int(data.get("rerolls", 0)) > 0:
		item.rerolls = int(data.rerolls)
	return item

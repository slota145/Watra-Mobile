class_name Dungeons
## Rodzaje lochów (ustalone z autorem 15.11.2026). Wspólna drabinka poziomów (decyzja autora 21.11.2026): każdy loch
## trwa LEVELS_PER poziomów w kolejności ORDER (1-5 gobliny, 6-10 Zatopione podziemia, 11-15 Katakumby, 16-20 Górskie
## równiny, 21-25 Podniebne wyspy, 26-30 Wulkaniczne równiny, 31-35 Lodowe jaskinie, 36-40 Prastary Bór, 41-45 Świątynia Słońca), a po ostatnim lochu drabinka zaczyna się od nowa - drugi krąg (26-50) i kolejne,
## (31-60, 61-90) z coraz silniejszymi potworami (siła zależy tylko od poziomu - DungeonLevels). Od RANDOM_FROM (endgame) przy każdym
## wejściu losuje się loch spośród wszystkich. Do 21.11.2026 każdy loch trwał 10 poziomów (od 41 Wulkaniczne do 100).
## Każdy loch: nazwa, boss, podłoże (tekstura z Watry powtarzana na polanie i jej odcień), żywioł potworów
## (Elements; odporność bohatera - `element_res_pct`) i potwory na trzech rolach strumienia ProtoHorde:
## `basic` - zwykły, `ranged` - strzelający z dystansu, `strong` - silny z ciosem w koło (udziały jak u goblinów -
## DungeonLevels.archer_share / brute_share). Klasy potworów i bossa wybiera `ProtoHorde.make_monster`
## i arena (`summon_chief`).

const GOBLINS := "goblins"
const FLOODED := "flooded"
const CATACOMBS := "catacombs"
const PLAINS := "plains"
const VOLCANO := "volcano"
const SKY := "sky"
const FROST := "frost"
const FOREST := "forest"
const TEMPLE := "temple"
## Od tego poziomu (włącznie z nim) loch jest losowy przy każdym wejściu.
const RANDOM_FROM := 101
## Ile poziomów trwa każdy loch na drabince.
const LEVELS_PER := 5
const ORDER: Array[String] = [GOBLINS, FLOODED, CATACOMBS, PLAINS, SKY, VOLCANO, FROST, FOREST, TEMPLE]
## Odporności potworów (decyzja autora 17.11.2026, wariant jak Last Epoch/PoE): wspólna odporność na wszystko - także
## fizyczne - rośnie z głębią (DungeonLevels.base_resist), a lochy mają do niej łagodny charakter (RESISTS: żywioł ->
## dodatek, ujemny - wrażliwość), żeby wybór broni coś znaczył, ale żadna nie była bezużyteczna. Gracz zmniejsza
## odporność premią „Przebicie odporności” (`pen_pct`, ProtoWeapon.penetration). Działa przez Elements.reduce
## (ProtoWeapon._deal, piorun i szron z kamieni, podpalenie - ProtoTarget.burn).
const RESISTS := {
	GOBLINS: {},
	FLOODED: {Elements.WATER: 0.2, Elements.LIGHTNING: -0.2},
	CATACOMBS: {Elements.NAWIA: 0.2, Elements.PRAWIA: -0.2},  # nieumarli wrażliwi na światło bogów (decyzja autora 26.11.2026)
	PLAINS: {Elements.LIGHTNING: 0.2, Elements.COLD: -0.2},
	VOLCANO: {Elements.FIRE: 0.2, Elements.WATER: -0.2},
	SKY: {Elements.AIR: 0.2, Elements.EARTH: -0.2},
	FROST: {Elements.COLD: 0.2, Elements.FIRE: -0.2},
	FOREST: {Elements.NATURE: 0.2, Elements.FIRE: -0.2},
	TEMPLE: {Elements.PRAWIA: 0.2, Elements.NAWIA: -0.2},
}
const DATA := {
	GOBLINS: {"name": "Leże goblinów", "boss": "Wódz Goblinów", "summon": "Przyzwij Wodza",
		"ground": "res://assets/watra/grass.png", "tint": Color(0.72, 0.68, 0.8), "element": Elements.PHYSICAL,
		"description": "Gobliny Hordy, łucznicy i osiłki; rządzi nimi Wódz."},
	FLOODED: {"name": "Zatopione podziemia", "boss": "Wodnik", "summon": "Przyzwij Wodnika",
		"ground": "res://assets/watra/swamp_floor.png", "tint": Color(0.92, 0.95, 1.0), "element": Elements.WATER,
		"description": "Zalane ruiny. Topielce przemaczają, żabołaki plują wodą, topielice mrożą ziemię; w głębi czeka Wodnik."},
	CATACOMBS: {"name": "Katakumby", "boss": "Nekromanta", "summon": "Przyzwij Nekromantę",
		"ground": "res://assets/watra/catacombs_floor.png", "tint": Color(0.66, 0.64, 0.76), "element": Elements.NAWIA,
		"description": "Kamienne krypty. Szkielety wstają z kości, łucznicy strzelają Nawią, rycerze tną szerokim zamachem; rządzi nimi Nekromanta."},
	PLAINS: {"name": "Górskie równiny", "boss": "Gromoskrzydły", "summon": "Przyzwij Gromoskrzydłego",
		"ground": "res://assets/watra/plains_floor.png", "tint": Color(0.86, 0.9, 0.94), "element": Elements.LIGHTNING,
		"description": "Wietrzne hale pod szczytami. Ptakoludzie doskakują z oszczepami, miotacze rzucają, szamani ściągają pioruny; nad nimi krąży Gromoskrzydły."},
	# szósty loch (ustalony z autorem 21.11.2026): wysepki nad chmurami, duchy wiatru, Gryf z Watry, podmuchy i trąby
	SKY: {"name": "Podniebne wyspy", "boss": "Gryf", "summon": "Przyzwij Gryfa",
		"ground": "res://assets/watra/sky_floor.png", "tint": Color(1.0, 1.0, 1.0), "element": Elements.AIR,
		"description": "Skaliste wysepki nad morzem chmur i ruiny chramu Strzyboga. Latawce przelatują przez śmiałków, wiły ciskają ostrza wiatru, wichrowce wciągają do siebie; wiatr zrywa się podmuchami, a po wyspach wędrują trąby powietrzne. Nad nimi króluje Gryf."},
	VOLCANO: {"name": "Wulkaniczne równiny", "boss": "Żywiołak ognia", "summon": "Przyzwij Żywiołaka",
		"ground": "res://assets/watra/volcano_floor.png", "tint": Color(1.0, 1.0, 1.0), "element": Elements.FIRE,
		"description": "Popiół i stygnąca lawa. Salamandry gryzą i podpalają, ogniki plują żarem, żużlowe golemy zostawiają płonącą ziemię; w sercu wulkanu czeka Żywiołak ognia."},
	# siódmy loch (ustalony z autorem 25.11.2026): lodowe jaskinie, duchy zimy, Dziad Mróz, wymarzanie i koksowniki
	FROST: {"name": "Lodowe jaskinie", "boss": "Dziad Mróz", "summon": "Przyzwij Dziada Mroza",
		"ground": "res://assets/watra/frost_floor.png", "tint": Color(1.0, 1.0, 1.0), "element": Elements.COLD,
		"description": "Błyszczące jaskinie lodu i uwięzieni w nim wojownicy. Zmarzlaki rąbią zmarzniętymi toporami, śnieżnice ciskają sople, lodowe olbrzymy zamrażają ziemię; mróz powoli skuwa śmiałków, rozgrzewają tylko koksowniki. W głębi czeka Dziad Mróz."},
	# ósmy loch (ustalony z autorem 25.11.2026): Prastary Bór z Watry, duchy lasu, Leszy z Watry, Żywa puszcza
	FOREST: {"name": "Prastary Bór", "boss": "Leszy", "summon": "Przyzwij Leszego",
		"ground": "res://assets/watra/forest_floor.png", "tint": Color(0.86, 0.9, 0.84), "element": Elements.NATURE,
		"description": "Mroczna puszcza pradawnych dębów i świecących grzybów. Błędniki parzą zielonym ogniem, borowcy strzelają cierniami, dzikie drzewce biją szponami w ziemię; korzenie same chwytają śmiałków. Nad borem panuje Leszy."},
	# dziewiąty loch (ustalony z autorem 26.11.2026): Zajęta Świątynia Słońca - Prawia, Południce, Żar-ptaki, kumiry,
	# boss Swarożyc-strażnik, mechanika Promienie słońca (ProtoSunbeams)
	TEMPLE: {"name": "Świątynia Słońca", "boss": "Swarożyc", "summon": "Przyzwij Swarożyca",
		"ground": "res://assets/watra/temple_floor.png", "tint": Color(0.92, 0.88, 0.82), "element": Elements.PRAWIA,
		"description": "Sanktuarium Dadźboga zajęte przez Hordę; jego strażnicy oszaleli od światła. Południce tną sierpami i oślepiają, żar-ptaki strzelają promieniami, kamienne kumiry miażdżą pięściami, a przez posadzkę suną palące promienie słońca - chroni tylko cień kolumn. Świątyni strzeże Swarożyc."},
}


## Loch na danym poziomie (od RANDOM_FROM - losowy, za każdym razem inny; wcześniej kolejne kręgi drabinki).
static func for_level(level: int) -> String:
	if level >= RANDOM_FROM:
		return ORDER.pick_random()
	return ORDER[floori((maxi(level, 1) - 1) / float(LEVELS_PER)) % ORDER.size()]


## Pierwszy poziom lochu `id` w pierwszym kręgu drabinki (gobliny - 1).
static func first_level(id: String) -> int:
	return maxi(ORDER.find(id), 0) * LEVELS_PER + 1


## Długość jednego kręgu drabinki (wszystkie lochy po kolei).
static func cycle_length() -> int:
	return ORDER.size() * LEVELS_PER


## Który krąg drabinki na tym poziomie (1 - pierwszy).
static func cycle_of(level: int) -> int:
	return floori((maxi(level, 1) - 1) / float(cycle_length())) + 1


## Czy na tym poziomie loch jest losowy.
static func is_random(level: int) -> bool:
	return level >= RANDOM_FROM


static func name_of(id: String) -> String:
	return Lang.t(DATA.get(id, DATA[GOBLINS]).name)


static func boss_of(id: String) -> String:
	return Lang.t(DATA.get(id, DATA[GOBLINS]).boss)


## Odporności potworów lochu `id` na poziomie `level`: wspólna odporność głębi na każdy żywioł i fizyczne plus charakter
## lochu (Elements.ALL + fizyczne -> ułamek).
static func resists(id: String, level := 1) -> Dictionary:
	var base := DungeonLevels.base_resist(level)
	var out := {}
	for e in Elements.ALL + [Elements.PHYSICAL]:
		out[e] = base + float(RESISTS.get(id, {}).get(e, 0.0))
	return out


## Opis odporności do wyboru poziomu: „Odporność potworów: 30% · Bardziej: Woda +20% · Mniej: Grom -20%” ("" - brak).
static func resist_text(id: String, level := 1) -> String:
	var strong: Array[String] = []
	var weak: Array[String] = []
	var r: Dictionary = RESISTS.get(id, {})
	for e: String in r:
		var line := "%s %+d%%" % [Elements.name_of(e), roundi(r[e] * 100.0)]
		if r[e] > 0.0:
			strong.append(line)
		else:
			weak.append(line)
	var parts: Array[String] = []
	var base := roundi(DungeonLevels.base_resist(level) * 100.0)
	if base > 0:
		parts.append(Lang.t("Odporność potworów: %d%%") % base)
	if not strong.is_empty():
		parts.append(Lang.t("Bardziej: %s") % ", ".join(strong))
	if not weak.is_empty():
		parts.append(Lang.t("Mniej: %s") % ", ".join(weak))
	return " · ".join(parts)


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, DATA[GOBLINS])

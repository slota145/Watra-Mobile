class_name Dungeons
## Rodzaje lochów (ustalone z autorem 15.11.2026). Wspólna drabinka poziomów: każdy loch zaczyna się od swojego
## poziomu (`from`) i trwa do początku następnego (1-10 gobliny, od 11 Zatopione podziemia; kolejne lochy dojdą
## w podobnym rytmie; od 21 Katakumby, od 31 Górskie równiny, od 41 Wulkaniczne równiny), a od RANDOM_FROM (endgame) przy każdym wejściu losuje się loch spośród wszystkich.
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
## Od tego poziomu (włącznie z nim) loch jest losowy przy każdym wejściu.
const RANDOM_FROM := 101
const ORDER: Array[String] = [GOBLINS, FLOODED, CATACOMBS, PLAINS, VOLCANO]
## Odporności potworów (decyzja autora 17.11.2026, wariant jak Last Epoch/PoE): wspólna odporność na wszystko - także
## fizyczne - rośnie z głębią (DungeonLevels.base_resist), a lochy mają do niej łagodny charakter (RESISTS: żywioł ->
## dodatek, ujemny - wrażliwość), żeby wybór broni coś znaczył, ale żadna nie była bezużyteczna. Gracz zmniejsza
## odporność premią „Przebicie odporności” (`pen_pct`, ProtoWeapon.penetration). Działa przez Elements.reduce
## (ProtoWeapon._deal, piorun i szron z kamieni, podpalenie - ProtoTarget.burn).
const RESISTS := {
	GOBLINS: {},
	FLOODED: {Elements.WATER: 0.2, Elements.LIGHTNING: -0.2},
	CATACOMBS: {Elements.NAWIA: 0.2, Elements.FIRE: -0.2},
	PLAINS: {Elements.LIGHTNING: 0.2, Elements.COLD: -0.2},
	VOLCANO: {Elements.FIRE: 0.2, Elements.WATER: -0.2},
}
const DATA := {
	GOBLINS: {"name": "Leże goblinów", "from": 1, "boss": "Wódz Goblinów", "summon": "Przyzwij Wodza",
		"ground": "res://assets/watra/grass.png", "tint": Color(0.72, 0.68, 0.8), "element": Elements.PHYSICAL,
		"description": "Gobliny Hordy, łucznicy i osiłki; rządzi nimi Wódz."},
	FLOODED: {"name": "Zatopione podziemia", "from": 11, "boss": "Wodnik", "summon": "Przyzwij Wodnika",
		"ground": "res://assets/watra/swamp_floor.png", "tint": Color(0.92, 0.95, 1.0), "element": Elements.WATER,
		"description": "Zalane ruiny. Topielce przemaczają, żabołaki plują wodą, topielice mrożą ziemię; w głębi czeka Wodnik."},
	CATACOMBS: {"name": "Katakumby", "from": 21, "boss": "Nekromanta", "summon": "Przyzwij Nekromantę",
		"ground": "res://assets/watra/catacombs_floor.png", "tint": Color(0.66, 0.64, 0.76), "element": Elements.NAWIA,
		"description": "Kamienne krypty. Szkielety wstają z kości, łucznicy strzelają Nawią, rycerze tną szerokim zamachem; rządzi nimi Nekromanta."},
	PLAINS: {"name": "Górskie równiny", "from": 31, "boss": "Gromoskrzydły", "summon": "Przyzwij Gromoskrzydłego",
		"ground": "res://assets/watra/plains_floor.png", "tint": Color(0.86, 0.9, 0.94), "element": Elements.LIGHTNING,
		"description": "Wietrzne hale pod szczytami. Ptakoludzie doskakują z oszczepami, miotacze rzucają, szamani ściągają pioruny; nad nimi krąży Gromoskrzydły."},
	VOLCANO: {"name": "Wulkaniczne równiny", "from": 41, "boss": "Żywiołak ognia", "summon": "Przyzwij Żywiołaka",
		"ground": "res://assets/watra/volcano_floor.png", "tint": Color(1.0, 1.0, 1.0), "element": Elements.FIRE,
		"description": "Popiół i stygnąca lawa. Salamandry gryzą i podpalają, ogniki plują żarem, żużlowe golemy zostawiają płonącą ziemię; w sercu wulkanu czeka Żywiołak ognia."}
}


## Loch na danym poziomie (od RANDOM_FROM - losowy, za każdym razem inny).
static func for_level(level: int) -> String:
	if level >= RANDOM_FROM:
		return ORDER.pick_random()
	var out := ORDER[0]
	for id in ORDER:
		if level >= int(DATA[id].from):
			out = id
	return out


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

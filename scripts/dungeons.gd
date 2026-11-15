class_name Dungeons
## Rodzaje lochów (ustalone z autorem 15.11.2026). Wspólna drabinka poziomów: każdy loch zaczyna się od swojego
## poziomu (`from`) i trwa do początku następnego (1-10 gobliny, od 11 Zatopione podziemia; kolejne lochy dojdą
## w podobnym rytmie), a od RANDOM_FROM (endgame) przy każdym wejściu losuje się loch spośród wszystkich.
## Każdy loch: nazwa, boss, podłoże (tekstura z Watry powtarzana na polanie i jej odcień), żywioł potworów
## (Elements; odporność bohatera - `element_res_pct`) i potwory na trzech rolach strumienia ProtoHorde:
## `basic` - zwykły, `ranged` - strzelający z dystansu, `strong` - silny z ciosem w koło (udziały jak u goblinów -
## DungeonLevels.archer_share / brute_share). Klasy potworów i bossa wybiera `ProtoHorde.make_monster`
## i arena (`summon_chief`).

const GOBLINS := "goblins"
const FLOODED := "flooded"
## Od tego poziomu (włącznie z nim) loch jest losowy przy każdym wejściu.
const RANDOM_FROM := 101
const ORDER: Array[String] = [GOBLINS, FLOODED]
const DATA := {
	GOBLINS: {"name": "Leże goblinów", "from": 1, "boss": "Wódz Goblinów", "summon": "Przyzwij Wodza",
		"ground": "res://assets/watra/grass.png", "tint": Color(0.72, 0.68, 0.8), "element": Elements.PHYSICAL,
		"description": "Gobliny Hordy, łucznicy i osiłki; rządzi nimi Wódz."},
	FLOODED: {"name": "Zatopione podziemia", "from": 11, "boss": "Wodnik", "summon": "Przyzwij Wodnika",
		"ground": "res://assets/watra/swamp_floor.png", "tint": Color(0.92, 0.95, 1.0), "element": Elements.WATER,
		"description": "Zalane ruiny. Topielce przemaczają, żabołaki plują wodą, topielice mrożą ziemię; w głębi czeka Wodnik."},
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


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, DATA[GOBLINS])

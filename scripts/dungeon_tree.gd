class_name DungeonTree
## Drzewko lochów (ustalone z autorem 20.11.2026, zamiast ulepszeń lochów za złoto - DungeonUpgrades; wzór: atlas
## Path of Exile, drzewko Watry `../Watra/scripts/watra_tree.gd`). Watra w środku, 4 gałęzie (HORDA, ŁUP, NAUKA, CELE):
## w każdej mały węzeł (do 5 punktów - dawne ulepszenia) i za nim duże węzły (10-15 punktów), dostępne, gdy mały ma
## choć 1 punkt. Punkty: 1 za każdy przebity poziom lochu (`Game.best_level`); cofanie za darmo (decyzja autora).
## Stan (węzeł -> punkty) trzyma i zapisuje `Game.tree`, działanie - `Game.tree_value` w arenie i ProtoHorde.

const ORDER: Array[String] = ["horde", "elites", "summon", "loot", "gold", "gems", "xp", "mastery", "embers",
		"reach", "gift", "rewards", "wander"]

## name, icon, branch (gałąź), parent ("" - mały węzeł przy Watrze), max (punkty), step (premia za punkt), text (wzór
## z liczbą), pos (miejsce w oknie - kierunek od Watry w stopniach i odległość).
const NODES := {
	"horde": {"name": "Gęstsza Horda", "icon": "res://assets/watra/base/goblin_heart.png", "parent": "", "max": 5,
		"step": 4.0, "text": "+%d%% potworów", "angle": -135.0, "dist": 80.0},
	"elites": {"name": "Łowy na elity", "icon": "res://assets/watra/tree/elites.png", "parent": "horde", "max": 15,
		"step": 5.0, "text": "+%d%% elit", "angle": -155.0, "dist": 165.0},
	"summon": {"name": "Szybkie przyzwanie", "icon": "res://assets/watra/tree/summon.png", "parent": "horde", "max": 10,
		"step": 2.0, "text": "-%d%% żaru na przyzwanie Wodza", "angle": -115.0, "dist": 165.0},
	"loot": {"name": "Hojność Watry", "icon": "res://assets/watra/base/bag.png", "parent": "", "max": 5,
		"step": 4.0, "text": "+%d%% szansy na łup", "angle": -45.0, "dist": 80.0},
	"gold": {"name": "Skarbiec", "icon": "res://assets/watra/base/tax_pouch.png", "parent": "loot", "max": 15,
		"step": 4.0, "text": "+%d%% złota", "angle": -65.0, "dist": 165.0},
	"gems": {"name": "Kamienie Watry", "icon": "res://assets/watra/tree/gems.png", "parent": "loot", "max": 10,
		"step": 6.0, "text": "+%d%% szansy na kamienie, aury i talizmany", "angle": -25.0, "dist": 165.0},
	"xp": {"name": "Nauka z walki", "icon": "res://assets/watra/base/bless_wisdom.png", "parent": "", "max": 5,
		"step": 4.0, "text": "+%d%% doświadczenia", "angle": 45.0, "dist": 80.0},
	"mastery": {"name": "Mistrzostwo", "icon": "res://assets/watra/tree/mastery.png", "parent": "xp", "max": 15,
		"step": 4.0, "text": "+%d%% mistrzostwa broni", "angle": 25.0, "dist": 165.0},
	"embers": {"name": "Żar Watry", "icon": "res://assets/watra/ember_icon.png", "parent": "xp", "max": 10,
		"step": 5.0, "text": "+%d%% żaru", "angle": 65.0, "dist": 165.0},
	"reach": {"name": "Długie ręce", "icon": "res://assets/watra/base/node_lightness.png", "parent": "", "max": 5,
		"step": 6.0, "text": "+%d px zasięgu zbierania", "angle": 135.0, "dist": 80.0},
	"gift": {"name": "Hojne bóstwa", "icon": "res://assets/watra/tree/gift.png", "parent": "reach", "max": 10,
		"step": 6.0, "text": "Dar kapliczki trwa o %d s dłużej", "angle": 105.0, "dist": 170.0},
	"rewards": {"name": "Szczodre cele", "icon": "res://assets/watra/tree/rewards.png", "parent": "reach", "max": 15,
		"step": 5.0, "text": "+%d%% nagród z celów (żar skrzyń, złoto Skarbnika, odpryski Kryształu)",
		"angle": 135.0, "dist": 185.0},
	"wander": {"name": "Wędrowne cele", "icon": "res://assets/watra/tree/wander.png", "parent": "reach", "max": 10,
		"step": 5.0, "text": "Co %d s %d%% szans na dodatkowy cel na mapie (niezależnie od paska żaru)",
		"angle": 165.0, "dist": 170.0},
}
## Wędrowne cele (prośba autora 20.11.2026): co WANDER_EVERY s szansa `step` % za punkt na cel spoza paska żaru;
## najwyżej WANDER_MAX takich celów na mapie naraz.
const WANDER_EVERY := 20.0
const WANDER_MAX := 2


static func has(id: String) -> bool:
	return NODES.has(id)


static func name_of(id: String) -> String:
	return Lang.t(NODES[id].name) if NODES.has(id) else ""


static func icon_of(id: String) -> Texture2D:
	return load(NODES[id].icon) if NODES.has(id) else null


static func max_of(id: String) -> int:
	return NODES[id].max if NODES.has(id) else 0


static func parent_of(id: String) -> String:
	return NODES[id].parent if NODES.has(id) else ""


## Węzły, które odblokowuje węzeł `id` (duże za małym).
static func children_of(id: String) -> Array[String]:
	var out: Array[String] = []
	for n: String in ORDER:
		if NODES[n].parent == id:
			out.append(n)
	return out


## Premia węzła przy `points` punktach (procenty, piksele albo sekundy - jak w opisie).
static func value(id: String, points: int) -> float:
	return NODES[id].step * clampi(points, 0, max_of(id)) if NODES.has(id) else 0.0


## Opis premii przy `points` punktach.
static func text(id: String, points: int) -> String:
	if id == "wander":
		return Lang.t(NODES[id].text) % [roundi(WANDER_EVERY), roundi(value(id, points))]
	return Lang.t(NODES[id].text) % roundi(value(id, points))


## Miejsce węzła względem Watry (piksele okna przed przesunięciem): kierunek i odległość z danych.
static func pos_of(id: String) -> Vector2:
	return Vector2.from_angle(deg_to_rad(NODES[id].angle)) * NODES[id].dist if NODES.has(id) else Vector2.ZERO


## Suma punktów (wszystkie węzły kosztują 1 punkt za poziom).
static func spent(tree: Dictionary) -> int:
	var total := 0
	for id in tree:
		total += int(tree[id])
	return total

class_name DungeonMods
extends RefCounted
## Modyfikatory lochów (pomysł z Dwarven Realms, decyzje autora 16.11.2026): gracz sam je włącza przy wyborze poziomu
## (od FROM_LEVEL - szczebel drabinki odblokowań), każdy utrudnia wyprawę i daje premię do nagród - ryzyko za nagrodę.
## Wybór zapamiętuje Game.dungeon_mods (w zapisie), działa na poziomach >= FROM_LEVEL (`active`).
## Działanie (arena `_apply_mods` i ProtoHorde): `speed`/`damage` - mnożniki prędkości i obrażeń potworów (bez bossa),
## `embers` - mnożnik żaru z iskier, `density` - mnożnik tłumu, `loot` - mnożnik szansy łupu, `rare_loot` - przedmioty
## z potworów z wagami rzadkości skrzyni bossa, `elite_rate` - elity tyle razy częściej, `elite_xp` - mnożnik
## doświadczenia za elity.

const FROM_LEVEL := 20
const ORDER: Array[String] = ["embers", "crowd", "blood_moon", "elites"]
const DATA := {
	"embers": {"name": "Żarliwa Horda", "color": Color(1.0, 0.6, 0.25), "speed": 1.25, "embers": 2.0,
			"cost": "Potwory szybsze o 25%", "reward": "Podwójny żar z iskier"},
	"crowd": {"name": "Gromada", "color": Color(0.75, 1.0, 0.55), "density": 1.5, "loot": 1.3,
			"cost": "O połowę więcej potworów naraz", "reward": "+30% szansy na łup"},
	"blood_moon": {"name": "Krwawy księżyc", "color": Color(1.0, 0.35, 0.35), "damage": 1.5, "rare_loot": true,
			"cost": "Potwory zadają +50% obrażeń", "reward": "Przedmioty z potworów częściej rzadkie"},
	"elites": {"name": "Dwór elit", "color": Color(0.85, 0.6, 1.0), "elite_rate": 2.0, "elite_xp": 2.0,
			"cost": "Elity dwa razy częściej", "reward": "Podwójne doświadczenie za elity"},
}


## Głębiny (decyzja autora 26.11.2026): modyfikatory losowe przy każdym wejściu - 1 w Głębiach 1-9, 2 w 10-19, 3 od 20.
const DEEP_STEP := 10
const DEEP_MAX := 3


## Ile losowych modyfikatorów w Głębi na poziomie `level`.
static func deep_count(level: int) -> int:
	return clampi(1 + Dungeons.deep_of(level) / DEEP_STEP, 1, DEEP_MAX)


## Losowe modyfikatory wyprawy w Głębiny (bez powtórek, w kolejności ORDER).
static func roll_deep(level: int) -> Array[String]:
	var pool := ORDER.duplicate()
	pool.shuffle()
	var picked := pool.slice(0, deep_count(level))
	var out: Array[String] = []
	for id in ORDER:
		if picked.has(id):
			out.append(id)
	return out


## Włączone modyfikatory na poziomie `level` (poniżej FROM_LEVEL i w Głębinach - żadne wybrane; Głębiny losują
## swoje - `roll_deep`).
static func active(level: int, chosen: Array) -> Array[String]:
	var out: Array[String] = []
	if level < FROM_LEVEL or Dungeons.is_deep(level):
		return out
	for id in ORDER:
		if chosen.has(id):
			out.append(id)
	return out


## Iloczyn wartości `key` włączonych modyfikatorów (brak - 1).
static func mult(mods: Array, key: String) -> float:
	var m := 1.0
	for id in mods:
		m *= float(DATA[id].get(key, 1.0))
	return m


static func has_flag(mods: Array, key: String) -> bool:
	for id in mods:
		if DATA[id].get(key, false):
			return true
	return false


static func name_of(id: String) -> String:
	return Lang.t(DATA[id]["name"])


## Nazwy włączonych modyfikatorów po przecinku (do wyboru poziomu i paska w lochu).
static func names(mods: Array) -> String:
	return ", ".join(mods.map(func(id: String) -> String: return name_of(id)))

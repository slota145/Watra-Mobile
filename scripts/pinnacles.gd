class_name Pinnacles
extends RefCounted
## Bossowie szczytowi (końcówka gry) - na razie Żmij Gorynycz (ustalenia z autorem 22.11.2026, docs/ROADMAP.md).
## Klucz do Gniazda Żmija wypada rzadko ze skrzyni bossa lochu (od KEY_FROM, szansa KEY_CHANCE razy ulepszenia łupu)
## i pamięta poziom lochu, z którego wypadł - na tym poziomie walczy Żmij (`Game.zmij_keys`: poziom -> sztuk).
## Wejście przy Watrze (LevelPicker - przycisk „Żmij Gorynycz”), walka na Pogorzelisku (arena.gd z `Game.pinnacle_key`,
## boss ProtoZmij). Klucz zużywa się dopiero po zwycięstwie (śmierć i ucieczka go nie zabierają - do oceny autora).
## Skrzynia Żmija (`chest_items`): pewny przedmiot legendarny, zwykły łup skrzyni bossa, podwójne runy, więcej żaru
## (CHEST_EMBERS) i z szansą UNIQUE_CHANCE jeden z unikatów tylko z Żmija (UNIQUES, dane w Items.UNIQUES).

## Łup w postaci {"zmij_key": poziom lochu} - ProtoLoot dodaje go do `Game.zmij_keys`.
const KEY := "zmij_key"
const KEY_FROM := 30
const KEY_CHANCE := 0.05
const KEY_NAME := "Klucz do Gniazda Żmija"
const KEY_ICON := preload("res://assets/watra/zmij_key.png")
const KEY_COLOR := Color(1.0, 0.45, 0.2)
const BOSS_NAME := "Żmij Gorynycz"
## Żmij jest silniejszy niż boss lochu z tego samego poziomu (razy DungeonLevels.BOSS_POWER).
const POWER := 1.3
## Skrzynia Żmija: ile razy więcej żaru niż skrzynia bossa lochu, szansa na unikat Żmija, ile razy więcej
## doświadczenia niż za bossa lochu.
const CHEST_EMBERS := 3
const UNIQUE_CHANCE := 0.25
const XP_MULT := 3
## Unikaty tylko z Żmija (nie wypadają ze zwykłego łupu - Items.UNIQUES z "source": "zmij").
const UNIQUES: Array[String] = ["zmij_fang", "zmij_scale"]


## Czy skrzynia bossa z poziomu `level` daje klucz (`chance_mult` - ulepszenia łupu z drzewka i modyfikatorów).
static func roll_key(level: int, chance_mult := 1.0) -> bool:
	return level >= KEY_FROM and randf() < KEY_CHANCE * chance_mult


## Łup skrzyni Żmija z poziomu klucza `level` (bez żaru - ten liczy arena).
static func chest_items(level: int, rarity_pct := 0.0, quantity_pct := 0.0, chance_mult := 1.0) -> Array:
	var items: Array = [Items.roll(level, "", "legendary")]
	items.append_array(Items.roll_chest(level, rarity_pct, quantity_pct))
	if randf() < UNIQUE_CHANCE:
		items.append(Items.make_unique(UNIQUES.pick_random(), level))
	for id in Gems.roll_chest(level, chance_mult):
		items.append({"gem": id})
	for i in 2:
		for id in Runes.roll_chest(level, chance_mult):
			items.append({"rune": id})
	return items


## Nazwa klucza z poziomem („Klucz do Gniazda Żmija (poziom 34)”).
static func key_name(level: int) -> String:
	return Lang.t("%s (poziom %d)") % [Lang.t(KEY_NAME), level]


## Klucze posortowane od najsilniejszego: [[poziom, sztuk], ...] z `Game.zmij_keys`.
static func key_list(keys: Dictionary) -> Array:
	var out: Array = []
	for l in keys:
		if int(keys[l]) > 0:
			out.append([int(l), int(keys[l])])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	return out

class_name Items
## Przedmioty (ustalone z autorem 12.11.2026): 6 miejsc ekwipunku (broń, hełm, zbroja, buty, pierścień, amulet),
## 3 rzadkości jak w Watrze, ale prościej - zwykły (bez premii), magiczny (1-2 losowe premie), rzadki (3-4).
## Siła przedmiotu zależy od poziomu lochu, z którego wypadł (`level`): od niego rośnie stała cecha miejsca
## (np. zdrowie z hełmu) i wartości premii, a co `LEVELS_PER_TIER` poziomów zmienia się wygląd i nazwa (5 stopni
## z Watry: żelazny, stalowy, mithrilowy, runiczny, smoczy). Łup: skrzynia Wodza (`roll_chest`) i rzadko gobliny
## (`roll_goblin`). Niepotrzebne przedmioty sprzedaje się za złoto (`sell_price`).
## Przedmiot to słownik z samymi identyfikatorami i liczbami (nazwy składane przy pokazywaniu - zasady w lang.gd):
## {"slot", "tier", "level", "rarity", "base": {cecha: wartość}, "affixes": [{"stat", "value"}], "sockets": [kamień],
## "rerolls": ile razy kowal przerabiał premię (od tego rośnie cena kolejnej przeróbki - `reroll_price`)}.
## Gniazda na kamienie szlachetne (Gems): "sockets" - lista identyfikatorów kamieni ("" - puste gniazdo); każdy przedmiot
## ma 1 gniazdo, bardzo rzadko 2 (SECOND_SOCKET), drugie dorabia Dłuto Jubilera (Game.add_socket).
## Stan (torba, założone, złoto) trzyma i zapisuje `Game`; sumę cech założonych przedmiotów liczy `totals`.
## Ikony: assets/watra/items/ (skopiowane z Watry, wersje _magic i _rare).

const SLOTS := ["weapon", "helmet", "armor", "boots", "ring", "amulet"]
const SLOT_NAMES := {"weapon": "Broń", "helmet": "Hełm", "armor": "Zbroja", "boots": "Buty", "ring": "Pierścień",
		"amulet": "Amulet"}
## Pusty obrazek miejsca w oknie ekwipunku (z Watry).
const SLOT_ICONS := {"weapon": "slot_weapon", "helmet": "slot_helmet", "armor": "slot_chest", "boots": "slot_boots",
		"ring": "slot_ring", "amulet": "slot_necklace"}
## Linie przedmiotów z Watry: plik ikony na każdy stopień.
const LINES := {
	"weapon": ["iron_sword", "sword_t2", "sword_t3", "sword_t4", "sword_t5"],
	"helmet": ["iron_helmet", "helm_t2", "helm_t3", "helm_t4", "helm_t5"],
	"armor": ["chainmail", "plate_t2", "plate_t3", "plate_t4", "plate_t5"],
	"boots": ["leather_boots", "boots_t2", "boots_t3", "boots_t4", "boots_t5"],
	"ring": ["copper_ring", "band_t2", "band_t3", "band_t4", "band_t5"],
	"amulet": ["amber_necklace", "amulet_t2", "amulet_t3", "amulet_t4", "amulet_t5"],
}
## Nazwy z Watry, według stopnia.
const NAMES := {
	"weapon": ["Żelazny miecz", "Stalowy miecz", "Mithrilowy miecz", "Runiczne ostrze", "Smocze ostrze"],
	"helmet": ["Żelazny hełm", "Stalowy hełm", "Mithrilowy hełm", "Runiczny hełm", "Smoczy hełm"],
	"armor": ["Kolczuga", "Stalowy napierśnik", "Mithrilowy napierśnik", "Runiczna zbroja", "Smocza zbroja"],
	"boots": ["Skórzane buty", "Buty wędrowca", "Elfie buty", "Buty cienia", "Buty ze smoczej skóry"],
	"ring": ["Miedziany pierścień", "Srebrny pierścień", "Złoty pierścień", "Platynowy pierścień", "Gwiezdny pierścień"],
	"amulet": ["Bursztynowy naszyjnik", "Srebrny amulet", "Złoty amulet", "Runiczny amulet", "Smoczy amulet"],
}
## Co tyle poziomów lochu przedmioty wchodzą na wyższy stopień (lochy 1-4: żelazne, 5-8: stalowe…).
const LEVELS_PER_TIER := 4

const RARITIES := ["common", "magic", "rare"]
const RARITY_NAMES := {"common": "Zwykły", "magic": "Magiczny", "rare": "Rzadki"}
## Kolory rzadkości jak w Watrze.
const RARITY_COLORS := {"common": Color(0.92, 0.92, 0.95), "magic": Color(0.45, 0.65, 1.0),
		"rare": Color(1.0, 0.86, 0.3)}
## Ile losowych premii daje rzadkość (od-do).
const AFFIX_COUNT := {"common": Vector2i(0, 0), "magic": Vector2i(1, 2), "rare": Vector2i(3, 4)}
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
## przyciągane iskry i łup, ember_pct - więcej żaru z iskier (decyzja autora 13.11.2026).
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
	"life_on_kill": "+%d zdrowia za zabicie potwora",
	"cdr_pct": "%d%% krótsze odnowienie umiejętności",
	"elite_dmg_pct": "+%d%% obrażeń przeciw elitom i bossom",
	"mana_regen": "+%.1f many na sekundę",
	"area_pct": "+%d%% obszaru umiejętności",
	"dodge_pct": "+%d%% szansy na unik",
	"pickup_pct": "+%d%% zasięgu zbierania",
	"ember_pct": "+%d%% żaru",
}
## Losowe premie: [najmniej, najwięcej] na 1. poziomie lochu; `scales` - rośnie z siłą lochu (DungeonLevels.power),
## inaczej (procenty) rośnie płynnie o `per_level` z każdym poziomem lochu (decyzja autora 12.11.2026 - wcześniej
## skokami co stopień, przez co od lochu 17 procenty stawały).
const AFFIXES := {
	"hp": {"min": 6.0, "max": 14.0, "scales": true},
	"mana": {"min": 5.0, "max": 12.0, "scales": true},
	"damage_pct": {"min": 4.0, "max": 9.0, "per_level": 0.6},
	"attack_speed_pct": {"min": 3.0, "max": 7.0, "per_level": 0.4},
	"move_pct": {"min": 3.0, "max": 6.0, "per_level": 0.2},
	"regen": {"min": 0.4, "max": 1.2, "scales": true},
	"protection_pct": {"min": 2.0, "max": 5.0, "per_level": 0.2},
	"xp_pct": {"min": 4.0, "max": 10.0, "per_level": 0.4},
	"crit_pct": {"min": 2.0, "max": 4.0, "per_level": 0.1},
	"crit_dmg_pct": {"min": 10.0, "max": 20.0, "per_level": 0.5},
	"life_on_kill": {"min": 1.0, "max": 2.0, "scales": true},
	"cdr_pct": {"min": 3.0, "max": 6.0, "per_level": 0.15},
	"elite_dmg_pct": {"min": 6.0, "max": 12.0, "per_level": 0.5},
	"mana_regen": {"min": 0.5, "max": 1.2, "scales": true},
	"area_pct": {"min": 4.0, "max": 8.0, "per_level": 0.2},
	"dodge_pct": {"min": 2.0, "max": 4.0, "per_level": 0.1},
	"pickup_pct": {"min": 10.0, "max": 20.0, "per_level": 0.5},
	"ember_pct": {"min": 4.0, "max": 8.0, "per_level": 0.3},
}
## Premie z ułamkiem (jedno miejsce po przecinku), reszta - liczby całkowite.
const DECIMAL_STATS := ["regen", "mana_regen"]
## Sufity sumy z całego ekwipunku (żeby postać nie stała się nieśmiertelna ani nie fruwała po lochu).
## Szansa na krytyk: 95% z przedmiotów + bazowe 5% = pewny krytyk; odnowienie aż do zera (decyzja autora 13.11.2026:
## osiągalne, ale bardzo trudne - premie na jednym przedmiocie są małe; przy zerowym odnowieniu hamulcem zostaje mana).
## Unik do 50% (połowa ciosów nadal trafia), obszar do +100%, zasięg zbierania do +200%, żar do +100%.
const CAPS := {"protection_pct": 50.0, "move_pct": 50.0, "attack_speed_pct": 75.0, "crit_pct": 95.0, "cdr_pct": 100.0,
	"dodge_pct": 50.0, "area_pct": 100.0, "pickup_pct": 200.0, "ember_pct": 100.0}
## Stała cecha każdego miejsca na 1. poziomie lochu (liczby rosną z siłą lochu, procenty o BASE_PCT_PER_LEVEL).
## Broń: obrażenia cięcia (od-do) zamiast zwykłego miecza postaci.
const BASE := {
	"weapon": {"damage": Vector2(15.0, 21.0)},
	"helmet": {"hp": 8.0},
	"armor": {"hp": 18.0},
	"boots": {"move_pct": 4.0},
	"ring": {"damage_pct": 4.0},
	"amulet": {"mana": 10.0},
}
## Stała cecha butów i pierścienia (procenty) rośnie o tyle z każdym poziomem lochu.
const BASE_PCT_PER_LEVEL := 0.2
## Gniazda: najwięcej w przedmiocie i szansa na drugie od razu (według rzadkości - bardzo rzadko).
const MAX_SOCKETS := 2
const SECOND_SOCKET := {"common": 0.0, "magic": 0.01, "rare": 0.03}
## Cena sprzedaży: tyle złota za zwykły przedmiot z 1. poziomu lochu, mnożnik rzadkości.
const SELL_BASE := 5.0
const SELL_RARITY := {"common": 1.0, "magic": 2.0, "rare": 4.0}
## Kowal (ustalone z autorem 12.11.2026): przeróbka jednej premii kosztuje REROLL_BASE x cena sprzedaży,
## a każda kolejna przeróbka tego samego przedmiotu REROLL_GROWTH razy więcej.
const REROLL_BASE := 2.0
const REROLL_GROWTH := 1.5


## Stopień przedmiotu (0-4) z poziomu lochu.
static func tier_for(level: int) -> int:
	return clampi((maxi(level, 1) - 1) / LEVELS_PER_TIER, 0, 4)


## Nowy przedmiot: miejsce (puste - losowe), poziom lochu, rzadkość (pusta - losowana wagami `weights`).
static func roll(level: int, slot := "", rarity := "", weights := GOBLIN_WEIGHTS) -> Dictionary:
	if slot == "":
		slot = SLOTS[randi() % SLOTS.size()]
	if rarity == "":
		rarity = roll_rarity(weights)
	var tier := tier_for(level)
	var p := DungeonLevels.power(level)
	var base := {}
	for stat in BASE[slot]:
		var v = BASE[slot][stat]
		if v is Vector2:
			var m := (1.0 + 0.12 * (maxi(level, 1) - 1)) * randf_range(0.92, 1.08)
			base[stat] = [roundi(v.x * m), roundi(v.y * m)]
		elif stat in ["move_pct", "damage_pct"]:
			base[stat] = roundi(v + BASE_PCT_PER_LEVEL * (maxi(level, 1) - 1))
		else:
			base[stat] = roundi(v * p)
	var affixes: Array = []
	var pool: Array = AFFIXES.keys()
	pool.shuffle()
	var count := randi_range(AFFIX_COUNT[rarity].x, AFFIX_COUNT[rarity].y)
	for i in count:
		var stat: String = pool[i]
		affixes.append({"stat": stat, "value": roll_affix(stat, level)})
	var sockets: Array = [""]
	if randf() < SECOND_SOCKET[rarity]:
		sockets.append("")
	return {"slot": slot, "tier": tier, "level": maxi(level, 1), "rarity": rarity, "base": base, "affixes": affixes,
			"sockets": sockets}


## Wartość losowej premii na danym poziomie lochu.
static func roll_affix(stat: String, level: int) -> float:
	var a: Dictionary = AFFIXES[stat]
	var v := randf_range(a.min, a.max)
	if a.get("scales", false):
		v *= DungeonLevels.power(level)
	else:
		v += a.get("per_level", 0.0) * (maxi(level, 1) - 1)
	return snappedf(v, 0.1) if stat in DECIMAL_STATS else float(roundi(v))


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


## Łup ze skrzyni Wodza: CHEST_ITEMS przedmiotów, pierwszy co najmniej magiczny.
static func roll_chest(level: int) -> Array:
	var items: Array = []
	for i in CHEST_ITEMS:
		var item := roll(level, "", "", CHEST_WEIGHTS)
		if i == 0 and item.rarity == "common":
			item = roll(level, "", "magic" if randf() < 0.75 else "rare")
		items.append(item)
	return items


## Goblin padł: z szansą GOBLIN_DROP (razy `chance_mult` - ulepszenie łupu) przedmiot, inaczej pusty słownik.
static func roll_goblin(level: int, chance_mult := 1.0) -> Dictionary:
	return roll(level) if randf() < GOBLIN_DROP * chance_mult else {}


## Nazwa przedmiotu w obecnym języku.
static func name_of(item: Dictionary) -> String:
	return Lang.t(NAMES[item.slot][item.tier])


static func color_of(item: Dictionary) -> Color:
	return RARITY_COLORS.get(item.get("rarity", "common"), RARITY_COLORS.common)


## Ikona przedmiotu (wersja magiczna i rzadka mają inne kolory, jak w Watrze).
static func icon_of(item: Dictionary) -> Texture2D:
	var suffix: String = {"common": "", "magic": "_magic", "rare": "_rare"}.get(item.get("rarity", "common"), "")
	return load("res://assets/watra/items/%s%s.png" % [LINES[item.slot][item.tier], suffix])


static func slot_icon(slot: String) -> Texture2D:
	return load("res://assets/watra/items/%s.png" % SLOT_ICONS[slot])


## Opis pod nazwą: „Rzadki - Hełm, loch 3”.
static func kind_line(item: Dictionary) -> String:
	return Lang.t("%s - %s, loch %d") % [Lang.t(RARITY_NAMES[item.rarity]), Lang.t(SLOT_NAMES[item.slot]), item.level]


## Opis jednej cechy z liczbą („+12 do zdrowia”).
static func stat_text(stat: String, value: float) -> String:
	if stat == "damage":
		return ""
	if stat in DECIMAL_STATS:
		return Lang.t(STAT_FORMATS[stat]) % value
	return Lang.t(STAT_FORMATS[stat]) % roundi(value)


## Linie stałej cechy przedmiotu (broń - obrażenia cięcia).
static func base_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for stat in item.base:
		if stat == "damage":
			lines.append(Lang.t("Obrażenia cięcia: %d-%d") % [item.base.damage[0], item.base.damage[1]])
		else:
			lines.append(stat_text(stat, item.base[stat]))
	return lines


static func affix_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for a in item.affixes:
		lines.append(stat_text(a.stat, a.value))
	return lines


## Ile złota daje sprzedaż.
static func sell_price(item: Dictionary) -> int:
	return maxi(1, roundi(SELL_BASE * DungeonLevels.power(item.level) * SELL_RARITY[item.rarity]))


## Cena następnej przeróbki premii u kowala.
static func reroll_price(item: Dictionary) -> int:
	return roundi(REROLL_BASE * sell_price(item) * pow(REROLL_GROWTH, int(item.get("rerolls", 0))))


## Kowal: premia `index` losowana od nowa - rodzaj (spośród tych, których przedmiot jeszcze nie ma; może wypaść
## ten sam) i siła z poziomu przedmiotu. Zmienia przedmiot w miejscu i liczy przeróbki. Zwraca false przy złym indeksie.
static func reroll_affix(item: Dictionary, index: int) -> bool:
	if index < 0 or index >= item.get("affixes", []).size():
		return false
	var taken: Array = []
	for i in item.affixes.size():
		if i != index:
			taken.append(item.affixes[i].stat)
	var pool: Array = AFFIXES.keys().filter(func(stat: String) -> bool: return not stat in taken)
	var stat: String = pool.pick_random()
	item.affixes[index] = {"stat": stat, "value": roll_affix(stat, item.level)}
	item.rerolls = int(item.get("rerolls", 0)) + 1
	return true


## Suma cech założonych przedmiotów (słownik miejsce -> przedmiot). Klucze ze STAT_FORMATS (z sufitami CAPS)
## oraz "damage" - obrażenia cięcia założonej broni jako Vector2i (bez broni: Vector2i.ZERO).
static func totals(equipped: Dictionary) -> Dictionary:
	var t := {"damage": Vector2i.ZERO}
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
			t[a.stat] += float(a.value)
		for id in item.get("sockets", []):
			var gem := Gems.jewel_stat(id, item.slot)
			if gem[0] != "":
				t[gem[0]] += gem[1]
	for stat in CAPS:
		t[stat] = minf(t[stat], CAPS[stat])
	return t


## Linie kamieni w gniazdach („Rubin - Odłamek: +20 do zdrowia”); puste gniazdo - „Puste gniazdo”.
static func socket_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for id in item.get("sockets", []):
		if id == "":
			lines.append(Lang.t("Puste gniazdo"))
		else:
			lines.append(Lang.t("%s: %s") % [Gems.name_of(id), Gems.jewel_text(id, item.slot)])
	return lines


## Przedmiot wczytany z JSON-a (liczby przychodzą jako float) - typy jak przy losowaniu. Zły wpis - pusty słownik.
## Stare zapisy (sprzed gniazd) dostają jedno puste gniazdo.
static func normalize(data) -> Dictionary:
	if not (data is Dictionary) or not SLOTS.has(data.get("slot", "")) or not RARITIES.has(data.get("rarity", "")):
		return {}
	var base := {}
	var raw_base = data.get("base", {})
	if raw_base is Dictionary:
		for stat in raw_base:
			if stat == "damage" and raw_base[stat] is Array and raw_base[stat].size() == 2:
				base[stat] = [int(raw_base[stat][0]), int(raw_base[stat][1])]
			elif STAT_FORMATS.has(stat):
				base[stat] = int(raw_base[stat])
	var affixes: Array = []
	var raw_affixes = data.get("affixes", [])
	if raw_affixes is Array:
		for a in raw_affixes:
			if a is Dictionary and STAT_FORMATS.has(a.get("stat", "")):
				var v := float(a.get("value", 0))
				affixes.append({"stat": a.stat, "value": snappedf(v, 0.1) if a.stat in DECIMAL_STATS else v})
	var sockets: Array = []
	var raw_sockets = data.get("sockets", [""])
	if raw_sockets is Array:
		for id in raw_sockets.slice(0, MAX_SOCKETS):
			sockets.append(Gems.make(Gems.kind_of(id), Gems.grade_of(id)) if id is String and Gems.is_jewel(id) else "")
	if sockets.is_empty():
		sockets.append("")
	var item := {"slot": data.slot, "tier": clampi(int(data.get("tier", 0)), 0, 4), "level": maxi(int(data.get("level", 1)), 1),
			"rarity": data.rarity, "base": base, "affixes": affixes, "sockets": sockets}
	if int(data.get("rerolls", 0)) > 0:
		item.rerolls = int(data.rerolls)
	return item

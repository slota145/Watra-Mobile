class_name Runes
## Runy - waluta-przedmioty jak orby w Path of Exile (ustalone z autorem 20.11.2026, ROADMAP punkt 4; przeniesione
## z Watry - `../Watra/scripts/item_craft.gd`). Każda runa to jedno działanie kowala na premiach przedmiotu
## (`ACTIONS`, `apply`): Szlifu - nowa wartość wybranej premii, Przekucia - wybrana premia od nowa, Przydania - nowa
## premia, Wyniesienia - wyższa rzadkość, Zmiany - wszystkie premie od nowa, Pieczęci - wybrana zostaje, reszta od nowa.
## Runy nie kosztują złota (gra odchodzi od złota). Stan: `Game.runes` (identyfikator -> ile sztuk, bez limitu).
## Łup: rzadko z potworów (`roll_monster`), skrzynia Wodza (`roll_chest`), skrzynie-cele, Kryształ Watry i nagroda
## Kręgu Żertwy (`roll`); na ziemi to {"rune": identyfikator} (ProtoLoot). Rzadsze runy wypadają dopiero od swojego
## poziomu lochu (`min_level`). `value` - „kurs” runy w Runach Szlifu: wymiana u kupca, a potem rynek (punkt 5).
## Potencjał kowalski (decyzja autora 21.11.2026): każde użycie runy zabiera przedmiotowi `cost` punktów
## (Items.potential_of), przy braku runa nie działa. Runa Bogów (jedna premia ponad widełki) i Runa Odnowy (pełny
## potencjał) - bardzo rzadkie, tylko od lochu BOSS_RUNES_FROM, z elit i skrzyni bossa (`boss`; nie u kupca).

const POLISH := "rune_polish"
const REFORGE := "rune_reforge"
const GROWTH := "rune_growth"
const ASCEND := "rune_ascend"
const CHAOS := "rune_chaos"
const SEAL := "rune_seal"
const GODS := "rune_gods"
const RENEWAL := "rune_renewal"
const ORDER: Array[String] = [POLISH, REFORGE, GROWTH, ASCEND, CHAOS, SEAL, GODS, RENEWAL]

## "weight" - jak często wypada (najprostsze najczęściej), "min_level" - od którego poziomu lochu,
## "value" - kurs w Runach Szlifu, "stat" - działa na wybraną premię (trzeba ją wskazać), "rare" - świeci jak
## rzadki przedmiot (ze słupem światła).
const DATA := {
	POLISH: {"name": "Runa Szlifu", "short": "Szlif", "weight": 10.0, "min_level": 1, "value": 1, "stat": true, "cost": 1,
		"color": Color(0.7, 0.85, 1.0),
		"text": "Wybrana premia dostaje nową wartość w swoim zakresie - może wyjść lepsza albo gorsza."},
	REFORGE: {"name": "Runa Przekucia", "short": "Przekucie", "weight": 7.0, "min_level": 1, "value": 2, "stat": true, "cost": 1,
		"color": Color(1.0, 0.75, 0.35),
		"text": "Wybrana premia losowana od nowa: inny rodzaj i nowa wartość."},
	GROWTH: {"name": "Runa Przydania", "short": "Przydanie", "weight": 5.0, "min_level": 1, "value": 3, "cost": 2,
		"color": Color(0.5, 0.9, 0.5),
		"text": "Nowa losowa premia, jeśli przedmiot ma wolne miejsce (magiczny: 2, rzadki: 5, legendarny: 6)."},
	ASCEND: {"name": "Runa Wyniesienia", "short": "Wyniesienie", "weight": 3.0, "min_level": 3, "value": 6, "cost": 2,
		"rare": true, "color": Color(1.0, 0.82, 0.35),
		"text": "Zwykły -> magiczny -> rzadki: wyższa rzadkość i brakujące premie dolosowane."},
	CHAOS: {"name": "Runa Zmiany", "short": "Zmiana", "weight": 3.0, "min_level": 1, "value": 5, "rare": true, "cost": 2,
		"color": Color(0.45, 0.75, 1.0),
		"text": "Wszystkie premie losowane od nowa (rzadkość i poziom zostają)."},
	SEAL: {"name": "Runa Pieczęci", "short": "Pieczęć", "weight": 0.8, "min_level": 20, "value": 20, "stat": true, "cost": 3,
		"rare": true, "color": Color(1.0, 0.7, 0.3),
		"text": "Wybrana premia zostaje, wszystkie pozostałe losowane od nowa."},
	GODS: {"name": "Runa Bogów", "short": "Bogowie", "weight": 0.0, "min_level": 40, "value": 60, "stat": true, "cost": 0,
		"rare": true, "boss": true, "color": Color(1.0, 0.92, 0.6),
		"text": "Wybrana premia wychodzi ponad widełki: najlepszy stopień i wartość do 30% ponad nim. Nie zużywa potencjału."},
	RENEWAL: {"name": "Runa Odnowy", "short": "Odnowa", "weight": 0.0, "min_level": 40, "value": 40, "cost": 0,
		"rare": true, "boss": true, "color": Color(0.45, 0.95, 0.6),
		"text": "Przywraca pełny potencjał kowalski przedmiotu."},
}
## Runa Bogów i Runa Odnowy: od tego poziomu lochu, szansa na każdą z elity i ze skrzyni bossa.
const BOSS_RUNES_FROM := 40
const BOSS_RUNE_ELITE := 0.01
const BOSS_RUNE_CHEST := 0.06

## Szansa na runę z każdego zabitego potwora (elita - ELITE) - rzadko, jak orby w PoE.
const MONSTER := 0.002
const ELITE := 0.08
## Skrzynia Wodza: tyle run na pewno i szansa na jeszcze jedną.
const CHEST_SURE := 2
const CHEST_EXTRA := 0.5


static func valid(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id].name) if DATA.has(id) else ""


static func short_of(id: String) -> String:
	return Lang.t(DATA[id].short) if DATA.has(id) else ""


static func text_of(id: String) -> String:
	return Lang.t(DATA[id].text) if DATA.has(id) else ""


static func color_of(id: String) -> Color:
	return DATA[id].color if DATA.has(id) else Color.WHITE


static func icon_of(id: String) -> Texture2D:
	return load("res://assets/runes/%s.png" % id)


static func is_rare(id: String) -> bool:
	return DATA.get(id, {}).get("rare", false)


## Czy runa działa na wybraną premię (Szlifu, Przekucia, Pieczęci).
static func needs_stat(id: String) -> bool:
	return DATA.get(id, {}).get("stat", false)


## Ile potencjału kowalskiego zabiera runa.
static func cost_of(id: String) -> int:
	return int(DATA.get(id, {}).get("cost", 0))


## Czy runa wypada tylko z elit i bossów od BOSS_RUNES_FROM (Runa Bogów, Runa Odnowy; nie u kupca).
static func is_boss(id: String) -> bool:
	return DATA.get(id, {}).get("boss", false)


## Runy bossów z jednego źródła (szansa `chance` na każdą, od BOSS_RUNES_FROM) - lista identyfikatorów.
static func roll_boss(level: int, chance: float) -> Array:
	var out: Array = []
	if level >= BOSS_RUNES_FROM:
		for id in [GODS, RENEWAL]:
			if randf() < chance:
				out.append(id)
	return out


## Kurs runy w Runach Szlifu.
static func value_of(id: String) -> int:
	return int(DATA.get(id, {}).get("value", 0))


## Losowa runa z poziomu lochu `level` (wagi DATA; rzadsze dopiero od swojego poziomu). `skip` - bez tych run
## (nagroda Kręgu Żertwy pomija najprostszą Runę Szlifu).
static func roll(level: int, skip: Array = []) -> String:
	var total := 0.0
	for id in ORDER:
		if level >= DATA[id].min_level and not id in skip:
			total += DATA[id].weight
	var pick := randf() * total
	for id in ORDER:
		if level >= DATA[id].min_level and not id in skip:
			pick -= DATA[id].weight
			if pick <= 0.0:
				return id
	return POLISH


## Zabity potwór: runa z szansą MONSTER (elita - ELITE) razy `chance_mult`, inaczej "". Elita od BOSS_RUNES_FROM
## czasem daje Runę Bogów albo Odnowy.
static func roll_monster(level: int, elite := false, chance_mult := 1.0) -> String:
	if elite:
		var boss := roll_boss(level, BOSS_RUNE_ELITE * chance_mult)
		if not boss.is_empty():
			return boss[0]
	return roll(level) if randf() < (ELITE if elite else MONSTER) * chance_mult else ""


## Runy ze skrzyni Wodza: CHEST_SURE na pewno i jeszcze jedna z szansą CHEST_EXTRA x `chance_mult`.
static func roll_chest(level: int, chance_mult := 1.0) -> Array:
	var out: Array = []
	for i in CHEST_SURE:
		out.append(roll(level))
	if randf() < CHEST_EXTRA * chance_mult:
		out.append(roll(level))
	out.append_array(roll_boss(level, BOSS_RUNE_CHEST * chance_mult))
	return out


## Ile premii mieści rzadkość (najwięcej).
static func max_affixes(item: Dictionary) -> int:
	return Items.AFFIX_COUNT[item.rarity].y


## Czy runę `id` da się użyć na przedmiocie (`index` - wybrana premia dla run z needs_stat). Pusty napis - da się,
## inaczej powód do pokazania graczowi.
static func blocker(item: Dictionary, id: String, index := -1) -> String:
	if item.is_empty() or not DATA.has(id):
		return "?"
	var count: int = item.affixes.size()
	if Items.potential_of(item).x < cost_of(id):
		return Lang.t("Brak potencjału kowalskiego - przedmiot nie przyjmie już tej runy.")
	match id:
		POLISH, REFORGE:
			if count == 0:
				return Lang.t("Zwykły przedmiot nie ma premii.")
		GROWTH:
			if item.rarity == "common":
				return Lang.t("Zwykły przedmiot nie ma miejsca na premie - najpierw Runa Wyniesienia.")
			if count >= max_affixes(item):
				return Lang.t("Brak wolnego miejsca na premię.")
		ASCEND:
			if item.rarity == "rare":
				return Lang.t("Przedmiot jest już rzadki.")
			if item.rarity == "legendary":
				return Lang.t("Legendarnego przedmiotu nie da się wynieść.")
		CHAOS:
			if count == 0:
				return Lang.t("Zwykły przedmiot nie ma premii.")
		SEAL:
			if count < 2:
				return Lang.t("Pieczęć potrzebuje co najmniej dwóch premii.")
	if needs_stat(id) and (index < 0 or index >= count):
		return Lang.t("Wybierz premię.")
	if id == GODS:
		var a: Dictionary = item.affixes[index]
		if a.get("above", false):
			return Lang.t("Ta premia jest już ponad widełkami.")
		if a.stat in Items.ABOVE_SKIP:
			return Lang.t("Tej premii nie da się podnieść ponad widełki.")
	if id == RENEWAL:
		var p := Items.potential_of(item)
		if p.x >= p.y:
			return Lang.t("Potencjał kowalski jest pełny.")
	return ""


## Działanie runy `id` na przedmiocie (zmienia go w miejscu). Zwraca false, gdy się nie da (`blocker`).
## Nie zużywa runy - to robi Game.use_rune.
static func apply(item: Dictionary, id: String, index := -1) -> bool:
	if blocker(item, id, index) != "":
		return false
	match id:
		POLISH:
			item.affixes[index] = Items.polish_affix(item.affixes[index])  # stopień zostaje
		REFORGE:
			Items.reroll_affix(item, index)
		GROWTH:
			_add_affix(item)
		ASCEND:
			item.rarity = "magic" if item.rarity == "common" else "rare"
			while item.affixes.size() < Items.AFFIX_COUNT[item.rarity].x and _add_affix(item):
				pass
		CHAOS:
			item.affixes = []
			for i in randi_range(Items.AFFIX_COUNT[item.rarity].x, Items.AFFIX_COUNT[item.rarity].y):
				_add_affix(item)
		SEAL:
			var kept: Dictionary = item.affixes[index]
			var count: int = item.affixes.size()
			item.affixes = [kept]
			while item.affixes.size() < count and _add_affix(item):
				pass
		GODS:
			Items.make_above(item, index)
		RENEWAL:
			item.potential = Items.potential_of(item).y
	var pot := Items.potential_of(item)
	item.potential_max = pot.y
	if id != RENEWAL:
		item.potential = pot.x - cost_of(id)
	return true


## Nowa losowa premia rodzaju, którego przedmiot jeszcze nie ma (pasującego do miejsca), z losowym stopniem.
static func _add_affix(item: Dictionary) -> bool:
	return Items.add_affix(item)

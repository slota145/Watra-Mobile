class_name Gems
## Kamienie (rozwój postaci, część 4 - ustalone z autorem 12.11.2026). Dwa rodzaje kamieni, oba z łupu w lochu
## (od poziomu lochu MIN_LEVEL; rzadko z goblinów, częściej ze skrzyni Wodza):
## - kamienie umiejętności (SUPPORT, 8 rodzajów) - włożone w umiejętność zmieniają jej działanie (więcej ostrzy,
##   większy obszar, podpalenie, spowolnienie, piorun, krótsze odnowienie, mniej many, leczenie z obrażeń); każda
##   umiejętność ma 5 gniazd, otwarte 2 (SKILL_OPEN), kolejne otwiera rzadki Klucz Runiczny (KEY) - po jednym na gniazdo;
##   jeden rodzaj kamienia najwyżej raz w umiejętności; działanie - ProtoWeapon (`Gems.skill_power`);
## - kamienie szlachetne (JEWELS: rubin, szafir, szmaragd, onyks) - włożone w przedmiot dają premię zależną od
##   miejsca (broń / strój - hełm, zbroja, buty / biżuteria - pierścień, amulet); przedmiot ma 1 gniazdo, bardzo rzadko 2
##   (Items.roll), drugie dorabia rzadkie Dłuto Jubilera (CHISEL); premie liczy Items.totals.
## Kamień ma stopień 0-4 (GRADES, jak stopnie przedmiotów - Items.tier_for poziomu lochu). Kamienie leżą w osobnej
## sakwie (`Game.gems`: identyfikator -> ile sztuk), więc nie zajmują torby. Identyfikator kamienia: "rodzaj:stopień"
## (np. "ember:2"), klucza i dłuta - KEY i CHISEL. Wkładanie i wyjmowanie (za darmo) - Game, okna SkillsWindow i HeroStats.

const GRADES := ["Okruch", "Odłamek", "Kamień", "Szlifowany", "Królewski"]
## Kamienie wypadają od tego poziomu lochu (decyzja autora: najpierw przedmioty i umiejętności).
const MIN_LEVEL := 3
## Gniazda umiejętności: razem i otwarte na start.
const SKILL_SOCKETS := 5
const SKILL_OPEN := 2
const KEY := "skill_key"
const CHISEL := "chisel"
## Łup: szansa na kamień z goblina, na kamień ze skrzyni Wodza (dwie próby), na klucz i dłuto ze skrzyni
## (rośnie z poziomem lochu do sufitu) i z goblina.
const GOBLIN_GEM := 0.012
const CHEST_GEM := [0.8, 0.3]
const CHEST_KEY := Vector2(0.04, 0.15)
const CHEST_CHISEL := Vector2(0.06, 0.2)
const CHEST_RARE_STEP := 0.005
const GOBLIN_RARE := 0.0015
## Szansa, że kamień to kamień umiejętności (inaczej szlachetny).
const SUPPORT_SHARE := 0.5

## Kamienie umiejętności: nazwa, ikona (z Watry), kolor, `values` - siła na stopniach 0-4, `unit` - jak pokazać
## liczbę, `text` - opis ogólny, `skills` - jak działa w danej umiejętności (gdy różnie).
## multi - dodatkowe ostrza / ciosy z obrażeniami `values` x zwykłe; area - obszar +%; ember - podpalenie
## (% obrażeń trafienia przez 3 s); rime - spowolnienie o % na 2 s; discharge - piorun przeskakuje na 2 wrogów (%
## obrażeń); haste - krótsze odnowienie (zwykły cios: szybszy); thrift - mniej many (zwykły cios: mana za trafienie);
## leech - leczy % zadanych obrażeń.
const SUPPORT := {
	"multi": {"name": "Mnożenie", "icon": "split", "color": Color(0.85, 0.85, 0.8), "unit": "pct",
		"values": [40, 50, 60, 70, 85],
		"text": "Więcej ostrzy (dodatkowe zadają %d%% obrażeń).",
		"skills": {
			"strike": "Po cięciu pada drugie, w drugą stronę (%d%% obrażeń).",
			"whirl": "Wiruje drugi, widmowy miecz (%d%% obrażeń).",
			"throw": "Lecą 3 miecze wachlarzem (boczne - %d%% obrażeń).",
			"slam": "Po uderzeniu idzie druga, szersza fala (%d%% obrażeń).",
			"blink": "Każdy skok tnie też pobliskiego wroga (%d%% obrażeń).",
		}},
	"area": {"name": "Szerokość", "icon": "area", "color": Color(0.88, 0.75, 0.44), "unit": "pct",
		"values": [15, 22, 30, 38, 50],
		"text": "Większy obszar: +%d%% zasięgu ciosu, wiru, fali i skoku."},
	"ember": {"name": "Żar", "icon": "ember", "color": Color(1.0, 0.55, 0.25), "unit": "pct",
		"values": [20, 35, 50, 70, 100],
		"text": "Podpala trafionych: %d%% obrażeń przez 3 s."},
	"rime": {"name": "Szron", "icon": "rime", "color": Color(0.55, 0.85, 1.0), "unit": "pct",
		"values": [15, 20, 25, 30, 40],
		"text": "Spowalnia trafionych o %d%% na 2 s."},
	"discharge": {"name": "Piorun", "icon": "discharge", "color": Color(1.0, 0.95, 0.45), "unit": "pct",
		"values": [20, 30, 40, 55, 70],
		"text": "Trafienie przeskakuje na 2 pobliskich wrogów (%d%% obrażeń)."},
	"haste": {"name": "Pośpiech", "icon": "venom", "color": Color(0.55, 0.9, 0.5), "unit": "pct",
		"values": [10, 14, 18, 23, 30],
		"text": "Odnowienie krótsze o %d%%.",
		"skills": {
			"strike": "Cios szybszy o %d%%.",
			"blink": "Skoki częstsze o %d%%.",
		}},
	"thrift": {"name": "Oszczędność", "icon": "echo", "color": Color(0.75, 0.55, 1.0), "unit": "pct",
		"values": [15, 20, 25, 32, 40],
		"text": "Umiejętność kosztuje o %d%% mniej many.",
		"skills": {
			"strike": "Każde trafienie oddaje %d many.",
		}},
	"leech": {"name": "Krwiopijca", "icon": "brutal", "color": Color(0.95, 0.35, 0.35), "unit": "pct",
		"values": [2, 3, 4, 5, 7],
		"text": "Leczy %d%% zadanych obrażeń."},
}
const SUPPORT_ORDER := ["multi", "area", "ember", "rime", "discharge", "haste", "thrift", "leech"]
## Oszczędność w zwykłym ciosie: many za trafienie na stopniach 0-4.
const THRIFT_STRIKE := [1, 1, 2, 2, 3]

## Kamienie szlachetne: nazwa, plik ikony (z Watry, `<icon>_<stopień+1>.png`), kolor i cecha (Items.STAT_FORMATS)
## według grupy miejsc.
const JEWELS := {
	"ruby": {"name": "Rubin", "color": Color(1.0, 0.42, 0.42),
		"weapon": "damage_pct", "gear": "hp", "jewelry": "regen"},
	"sapphire": {"name": "Szafir", "color": Color(0.43, 0.66, 1.0),
		"weapon": "mana", "gear": "mana", "jewelry": "xp_pct"},
	"emerald": {"name": "Szmaragd", "color": Color(0.37, 0.86, 0.49),
		"weapon": "attack_speed_pct", "gear": "move_pct", "jewelry": "attack_speed_pct"},
	"onyx": {"name": "Onyks", "color": Color(0.78, 0.78, 0.82),
		"weapon": "protection_pct", "gear": "protection_pct", "jewelry": "hp"},
}
const JEWEL_ORDER := ["ruby", "sapphire", "emerald", "onyx"]
## Grupa miejsca przedmiotu dla kamieni szlachetnych.
const SLOT_GROUPS := {"weapon": "weapon", "helmet": "gear", "armor": "gear", "boots": "gear", "ring": "jewelry",
		"amulet": "jewelry"}
const GROUP_NAMES := {"weapon": "broń", "gear": "strój", "jewelry": "biżuteria"}
## Wartość cechy kamienia szlachetnego na stopniach 0-4.
const JEWEL_VALUES := {
	"damage_pct": [4, 6, 9, 12, 16],
	"hp": [12, 20, 27, 33, 40],
	"regen": [0.5, 0.8, 1.1, 1.4, 1.8],
	"mana": [10, 15, 21, 27, 33],
	"xp_pct": [4, 6, 8, 11, 15],
	"attack_speed_pct": [3, 4, 6, 8, 10],
	"move_pct": [3, 4, 5, 6, 8],
	"protection_pct": [2, 3, 4, 5, 7],
}

const SPECIAL := {
	KEY: {"name": "Klucz Runiczny", "icon": "res://assets/watra/gems/rune_ascend.png", "color": Color(1.0, 0.8, 0.35),
		"text": "Otwiera kolejne gniazdo wybranej umiejętności (okno umiejętności)."},
	CHISEL: {"name": "Dłuto Jubilera", "icon": "res://assets/watra/gems/rune_polish.png", "color": Color(0.7, 0.85, 1.0),
		"text": "Dorabia drugie gniazdo w przedmiocie (opis przedmiotu w oknie „Postać”)."},
}
const SOCKET_ICON := preload("res://assets/watra/gems/socket.png")


## Identyfikator kamienia z rodzaju i stopnia.
static func make(kind: String, grade: int) -> String:
	return "%s:%d" % [kind, clampi(grade, 0, GRADES.size() - 1)]


static func kind_of(id: String) -> String:
	return id.get_slice(":", 0)


static func grade_of(id: String) -> int:
	return clampi(int(id.get_slice(":", 1)), 0, GRADES.size() - 1) if id.contains(":") else 0


static func is_special(id: String) -> bool:
	return SPECIAL.has(id)


static func is_support(id: String) -> bool:
	return SUPPORT.has(kind_of(id)) and id.contains(":")


static func is_jewel(id: String) -> bool:
	return JEWELS.has(kind_of(id)) and id.contains(":")


## Czy identyfikator jest poprawny (z zapisu gry).
static func valid(id) -> bool:
	return id is String and (is_special(id) or is_support(id) or is_jewel(id))


## Nazwa: „Żar - Odłamek”, „Rubin - Królewski”, „Klucz Runiczny”.
static func name_of(id: String) -> String:
	if is_special(id):
		return Lang.t(SPECIAL[id].name)
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	if data.is_empty():
		return ""
	return Lang.t("%s - %s") % [Lang.t(data.name), Lang.t(GRADES[grade_of(id)])]


static func color_of(id: String) -> Color:
	if is_special(id):
		return SPECIAL[id].color
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	return data.get("color", Color.WHITE)


static func icon_of(id: String) -> Texture2D:
	if is_special(id):
		return load(SPECIAL[id].icon)
	if is_support(id):
		return load("res://assets/watra/supports/%s.png" % SUPPORT[kind_of(id)].icon)
	if is_jewel(id):
		return load("res://assets/watra/gems/%s_%d.png" % [kind_of(id), grade_of(id) + 1])
	return null


## Rodzaj kamienia słowami („Kamień umiejętności, stopień 2/5”).
static func kind_line(id: String) -> String:
	if is_special(id):
		return Lang.t("Rzadki przedmiot")
	var kind := Lang.t("Kamień umiejętności") if is_support(id) else Lang.t("Kamień szlachetny")
	return Lang.t("%s, stopień %d/%d") % [kind, grade_of(id) + 1, GRADES.size()]


## Siła kamienia umiejętności (liczba z `values` jego stopnia).
static func support_value(id: String) -> float:
	return float(SUPPORT[kind_of(id)].values[grade_of(id)]) if is_support(id) else 0.0


## Opis działania kamienia umiejętności; z `skill` - jak działa w tej umiejętności.
static func support_text(id: String, skill := "") -> String:
	if not is_support(id):
		return ""
	var kind := kind_of(id)
	var data: Dictionary = SUPPORT[kind]
	if kind == "thrift" and skill == Skills.STRIKE:
		return Lang.t(data.skills.strike) % THRIFT_STRIKE[grade_of(id)]
	var text: String = data.get("skills", {}).get(skill, data.text)
	return Lang.t(text) % roundi(support_value(id))


## Cecha (Items.STAT_FORMATS) i wartość kamienia szlachetnego w miejscu przedmiotu `slot`.
static func jewel_stat(id: String, slot: String) -> Array:
	if not is_jewel(id) or not SLOT_GROUPS.has(slot):
		return ["", 0.0]
	var stat: String = JEWELS[kind_of(id)][SLOT_GROUPS[slot]]
	return [stat, float(JEWEL_VALUES[stat][grade_of(id)])]


## Opis premii kamienia szlachetnego w miejscu `slot` („+20 do zdrowia”).
static func jewel_text(id: String, slot: String) -> String:
	var s := jewel_stat(id, slot)
	return Items.stat_text(s[0], s[1]) if s[0] != "" else ""


## Wszystkie premie kamienia szlachetnego w trzech grupach („Broń: +6% obrażeń”).
static func jewel_lines(id: String) -> Array[String]:
	var lines: Array[String] = []
	for group in ["weapon", "gear", "jewelry"]:
		var stat: String = JEWELS[kind_of(id)][group]
		lines.append(Lang.t("%s: %s") % [Lang.t(GROUP_NAMES[group]).capitalize(),
				Items.stat_text(stat, float(JEWEL_VALUES[stat][grade_of(id)]))])
	return lines


## Linie opisu kamienia w sakwie (bez kontekstu umiejętności czy przedmiotu).
static func description(id: String) -> Array[String]:
	if is_special(id):
		return [Lang.t(SPECIAL[id].text)]
	if is_support(id):
		return [support_text(id)]
	return jewel_lines(id)


## Kamień z łupu na poziomie lochu (losowy rodzaj, stopień z poziomu).
static func roll(level: int) -> String:
	var grade := Items.tier_for(level)
	if randf() < SUPPORT_SHARE:
		return make(SUPPORT_ORDER.pick_random(), grade)
	return make(JEWEL_ORDER.pick_random(), grade)


## Łup z goblina: kamień, klucz albo dłuto (rzadko; poniżej MIN_LEVEL nic) - "" gdy nic.
static func roll_goblin(level: int) -> String:
	if level < MIN_LEVEL:
		return ""
	var r := randf()
	if r < GOBLIN_RARE:
		return KEY if randf() < 0.5 else CHISEL
	return roll(level) if r < GOBLIN_RARE + GOBLIN_GEM else ""


## Łup ze skrzyni Wodza: lista identyfikatorów (kamienie, klucz, dłuto; poniżej MIN_LEVEL - pusta).
static func roll_chest(level: int) -> Array:
	var out: Array = []
	if level < MIN_LEVEL:
		return out
	for chance in CHEST_GEM:
		if randf() < chance:
			out.append(roll(level))
	var step := CHEST_RARE_STEP * (level - MIN_LEVEL)
	if randf() < minf(CHEST_KEY.x + step, CHEST_KEY.y):
		out.append(KEY)
	if randf() < minf(CHEST_CHISEL.x + step, CHEST_CHISEL.y):
		out.append(CHISEL)
	return out


## Siła kamienia umiejętności rodzaju `kind` w gniazdach (lista identyfikatorów; 0 - brak).
static func skill_power(sockets: Array, kind: String) -> float:
	for id in sockets:
		if id is String and is_support(id) and kind_of(id) == kind:
			return support_value(id)
	return 0.0


## Stopień kamienia rodzaju `kind` w gniazdach (-1 - brak).
static func skill_grade(sockets: Array, kind: String) -> int:
	for id in sockets:
		if id is String and is_support(id) and kind_of(id) == kind:
			return grade_of(id)
	return -1

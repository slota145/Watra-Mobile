class_name Gems
## Kamienie (rozwój postaci, część 4 - ustalone z autorem 12.11.2026). Dwa rodzaje kamieni, oba z łupu w lochu
## (od poziomu lochu MIN_LEVEL; rzadko z goblinów, częściej ze skrzyni Wodza):
## - kamienie umiejętności (SUPPORT, 8 rodzajów) - włożone w umiejętność zmieniają jej działanie (więcej ostrzy,
##   większy obszar, podpalenie, spowolnienie, piorun, krótsze odnowienie, mniej many, leczenie z obrażeń); każda
##   umiejętność ma 5 gniazd, otwarte 2 (SKILL_OPEN), kolejne otwiera rzadki Klucz Runiczny (KEY) - po jednym na gniazdo;
##   jeden rodzaj kamienia najwyżej raz w umiejętności; działanie - ProtoWeapon (`Gems.skill_power`);
## - kamienie szlachetne (JEWELS: rubin, szafir, szmaragd, onyks) - włożone w przedmiot dają swoje premie (2-5,
##   te same w każdym miejscu); przedmiot ma 1 gniazdo, bardzo rzadko 2
##   (Items.roll), drugie dorabia rzadkie Dłuto Jubilera (CHISEL); premie liczy Items.totals.
## - kamienie unikalne (UNIQUE, ustalone z autorem 13.11.2026) - po jednym na umiejętność, bez ulepszeń, pasują tylko
##   do swojej umiejętności, zajmują zwykłe gniazdo i zmieniają sposób jej działania (Młynek bez odnowienia, Mgnienie
##   bez limitu skoków, odbicia Rzutu, fale z trafionych Rozłupaniem, fala cięcia zwykłego ciosu); rzadko ze skrzyni
##   Wodza od UNIQUE_MIN_LEVEL; identyfikator "unique:<umiejętność>"; działanie - ProtoWeapon (`Gems.has_unique`).
## Bez stopni (przebudowa ustalona z autorem 15.11.2026): kamień umiejętności wypada na 1. poziomie i ulepsza się
## go złotem i odpryskami do MAX_LEVEL (`upgrade_cost`, siła rośnie płynnie - `support_value`); kamień szlachetny
## wypada z 2-3 losowymi premiami z puli swojego rodzaju (JEWELS `pool`, te same w każdym miejscu przedmiotu, siła
## z poziomu lochu jak premie przedmiotów), a ulepszenie dokłada mu kolejną losową premię (do JEWEL_MAX). Niepotrzebny
## kamień sprzedaje się za złoto (`sell_price`) albo rozbija na odpryski (`shard_value`; odpryski w `Game.shards`).
## Kamienie leżą w osobnej sakwie (`Game.gems`: identyfikator -> ile sztuk; takie same kamienie leżą na stosie),
## więc nie zajmują torby. Identyfikatory: kamień umiejętności "rodzaj:poziom" (np. "ember:3"), szlachetny
## "rodzaj:poziom lochu:cecha=wartość,cecha=wartość" (np. "ruby:7:damage_pct=5,hp=18"), klucz i dłuto - KEY i CHISEL.
## Wkładanie i wyjmowanie (za darmo), ulepszanie, sprzedaż i rozbijanie - Game, okna SkillsWindow, HeroStats i GemPicker.

## Najwyższy poziom ulepszenia kamienia umiejętności; najwięcej premii kamienia szlachetnego (wypada z 2-3).
const MAX_LEVEL := 10
const JEWEL_MAX := 5
## Szansa, że kamień szlachetny wypadnie z 3 premiami (inaczej z 2).
const JEWEL_THREE := 0.35
## Siła premii kamienia szlachetnego względem takiej samej premii przedmiotu z tego poziomu lochu.
const JEWEL_MULT := 0.6
## Ulepszenie kamienia umiejętności z poziomu L: złoto UPGRADE_GOLD x UPGRADE_GROWTH^(L-1) (zaokrąglone do 10),
## odpryski UPGRADE_SHARDS x L. Kamień szlachetny: dołożenie premii nr 3, 4, 5 - JEWEL_GOLD / JEWEL_SHARDS (złoto
## rośnie o 5% na poziom lochu kamienia).
const UPGRADE_GOLD := 80.0
const UPGRADE_GROWTH := 1.45
const UPGRADE_SHARDS := 2.25
const JEWEL_GOLD := {3: 300, 4: 900, 5: 2000}
const JEWEL_SHARDS := {3: 5, 4: 10, 5: 20}
## Sprzedaż: kamień umiejętności SELL_SUPPORT + SELL_SHARE włożonego złota, szlachetny SELL_JEWEL za premię
## (+5% na poziom lochu), unikalny SELL_UNIQUE. Rozbicie: SHATTER_BASE odprysków + SELL_SHARE włożonych
## (szlachetny liczony od 2 premii), unikalny SHATTER_UNIQUE.
const SELL_SUPPORT := 15
const SELL_JEWEL := 10
const SELL_UNIQUE := 200
const SELL_SHARE := 0.5
const SHATTER_BASE := 2
const SHATTER_UNIQUE := 15
## Kamienie wypadają od tego poziomu lochu (decyzja autora: najpierw przedmioty i umiejętności).
const MIN_LEVEL := 3
## Gniazda umiejętności: razem i otwarte na start.
const SKILL_SOCKETS := 5
const SKILL_OPEN := 2
const KEY := "skill_key"
const CHISEL := "chisel"
## Łup (17.11.2026 - ok. 3x mniej, uwaga autora: za dużo kamieni na początku): szansa na kamień z goblina, na kamień ze skrzyni Wodza (dwie próby), na klucz i dłuto ze skrzyni
## (rośnie z poziomem lochu do sufitu) i z goblina.
const GOBLIN_GEM := 0.004
const CHEST_GEM := [0.3, 0.1]
const CHEST_KEY := Vector2(0.04, 0.15)
const CHEST_CHISEL := Vector2(0.06, 0.2)
const CHEST_RARE_STEP := 0.005
const GOBLIN_RARE := 0.0005
## Kamień unikalny ze skrzyni Wodza: od poziomu lochu, szansa (rośnie o CHEST_RARE_STEP na poziom do sufitu).
const UNIQUE_MIN_LEVEL := 5
const CHEST_UNIQUE := Vector2(0.03, 0.08)
## Szansa, że kamień to kamień umiejętności (inaczej szlachetny).
const SUPPORT_SHARE := 0.5

## Kamienie umiejętności: nazwa, ikona (z Watry), kolor, `values` - siła na 1. i MAX_LEVEL poziomie (pomiędzy płynnie), `unit` - jak pokazać
## liczbę, `text` - opis ogólny, `skills` - jak działa w danej umiejętności (gdy różnie).
## multi - dodatkowe ostrza / ciosy z obrażeniami `values` x zwykłe; area - obszar +%; ember - podpalenie
## (% obrażeń trafienia przez 3 s); rime - spowolnienie o % na 2 s; discharge - piorun przeskakuje na 2 wrogów (%
## obrażeń); haste - krótsze odnowienie (zwykły cios: szybszy); thrift - mniej many (zwykły cios: mana za trafienie);
## leech - leczy % zadanych obrażeń.
const SUPPORT := {
	"multi": {"name": "Mnożenie", "icon": "split", "color": Color(0.85, 0.85, 0.8), "unit": "pct",
		"values": [40, 100],
		"text": "Więcej ostrzy (dodatkowe zadają %d%% obrażeń).",
		"skills": {
			"strike": "Po cięciu pada drugie, w drugą stronę (%d%% obrażeń).",
			"whirl": "Wiruje drugi, widmowy miecz (%d%% obrażeń).",
			"throw": "Lecą 3 miecze wachlarzem (boczne - %d%% obrażeń).",
			"slam": "Po uderzeniu idzie druga, szersza fala (%d%% obrażeń).",
			"steel_ring": "Krąży o jeden widmowy miecz więcej (%d%% obrażeń).",
			"k_flash": "Każdy skok tnie też pobliskiego wroga (%d%% obrażeń).",
		}},
	"area": {"name": "Szerokość", "icon": "area", "color": Color(0.88, 0.75, 0.44), "unit": "pct",
		"values": [15, 55],
		"text": "Większy obszar: +%d%% zasięgu ciosu, wiru, fali i skoku."},
	"ember": {"name": "Żar", "icon": "ember", "color": Color(1.0, 0.55, 0.25), "unit": "pct",
		"values": [20, 115],
		"text": "Podpala trafionych: %d%% obrażeń przez 3 s."},
	"rime": {"name": "Szron", "icon": "rime", "color": Color(0.55, 0.85, 1.0), "unit": "pct",
		"values": [15, 45],
		"text": "Spowalnia trafionych o %d%% na 2 s i rani lodem (połowa tej liczby jako %% obrażeń)."},
	"discharge": {"name": "Piorun", "icon": "discharge", "color": Color(0.45, 0.7, 1.0), "unit": "pct",
		"values": [20, 80],
		"text": "Trafienie przeskakuje na 2 pobliskich wrogów (%d%% obrażeń od pioruna) i poraża ich."},
	"haste": {"name": "Pośpiech", "icon": "venom", "color": Color(0.55, 0.9, 0.5), "unit": "pct",
		"values": [10, 33],
		"text": "Odnowienie krótsze o %d%%.",
		"skills": {
			"strike": "Cios szybszy o %d%%.",
			"k_flash": "Skoki częstsze o %d%%.",
		}},
	"thrift": {"name": "Oszczędność", "icon": "echo", "color": Color(0.75, 0.55, 1.0), "unit": "pct",
		"values": [15, 45],
		"text": "Umiejętność kosztuje o %d%% mniej many.",
		"skills": {
			"strike": "Każde trafienie oddaje %d many.",
		}},
	"leech": {"name": "Krwiopijca", "icon": "brutal", "color": Color(0.95, 0.35, 0.35), "unit": "pct",
		"values": [2, 8],
		"text": "Leczy %d%% zadanych obrażeń."},
}
## Kamienie unikalne (klucz - umiejętność): nazwa, kolor, krótki opis pod gniazdem i pełny opis. Ikony -
## assets/watra/unique_gems/<umiejętność>.png (tools/unique_gem_art.py).
const UNIQUE_PREFIX := "unique:"
const UNIQUE := {
	"strike": {"name": "Kamień Wichrowego Ostrza", "short": "Fala cięcia",
		"text": "Każde cięcie wypuszcza do przodu falę, która przebija wrogów (60% obrażeń ciosu)."},
	"whirl": {"name": "Kamień Wiecznego Wiru", "short": "Rośnie z czasem",
		"text": "Im dłużej wirujesz, tym większy wir: przez 4 s zasięg i obrażenia Młynka rosną aż do +100%."},
	"throw": {"name": "Kamień Rykoszetu", "short": "Odbicia",
		"text": "Miecz (i widmowe miecze) odbija się od trafionego wroga w kolejnego - do 3 odbić."},
	"slam": {"name": "Kamień Drżącej Ziemi", "short": "Fale z trafionych",
		"text": "Każdy trafiony wróg wywołuje wokół siebie falę uderzeniową, która rani pobliskich (50% obrażeń)."},
	# elektryczna katana (pomysły autora 15.11.2026)
	"k_slash": {"name": "Kamień Gromowego Ostrza", "short": "Piorun z cięcia",
		"text": "Z każdego cięcia leci do przodu łuk pioruna, który przebija wrogów (50% obrażeń cięcia)."},
	"k_dance": {"name": "Kamień Wiru Ostrza", "short": "Taniec w miejscu",
		"text": "Taniec ostrza w miejscu: zamiast iść naprzód, tniesz 6 razy dookoła siebie."},
	"k_riposte": {"name": "Kamień Łańcucha Kontr", "short": "Kontry z trafionych",
		"text": "Każdy wróg trafiony kontrą sam tnie dookoła siebie (50% siły) - a trafieni przez niego też, łańcuchem (każdy wróg raz, najwyżej 12)."},
	"k_perun": {"name": "Kamień Wędrownych Gromów", "short": "Pioruny po ziemi",
		"text": "Z cięcia wyskakują pioruny pełzające po ziemi, każdy do innego wroga (60% siły) - im dłuższe ładowanie, tym więcej (2-6)."},
	"steel_ring": {"name": "Kamień Wiecznej Stali", "short": "Krąg bez końca",
		"text": "Krąg stali nie znika po czasie i nie ma odnowienia: krąży, dopóki go nie wyłączysz (drugie stuknięcie) albo nie skończy się mana - zużywa ją co sekundę."},
	"k_flash": {"name": "Kamień Nieskończonej Mgły", "short": "Skoki za pół many",
		"text": "Każdy skok Błysku Peruna kosztuje o połowę mniej many."},
	# glewia ognia (ustalone z autorem 14.11.2026)
	"g_thrust": {"name": "Kamień Trójzęba", "short": "3 pchnięcia",
		"text": "Glewia dźga trzy razy naraz w wąskim stożku przed sobą - każdy wróg obrywa raz."},
	"g_sweep": {"name": "Kamień Pogorzeliska", "short": "Płonąca ziemia",
		"text": "Zamach zostawia wzdłuż łuku płonącą ziemię, która przez 3 s rani i podpala wrogów."},
	"g_trail": {"name": "Kamień Bumerangu", "short": "Cięcia wracają",
		"text": "Cięcia bruzdy po dolocie zawracają do ciebie i ranią wrogów drugi raz."},
	"g_pillar": {"name": "Kamień Ognistego Deszczu", "short": "3 upadki",
		"text": "Glewia spada po kolei w 3 różnych wrogów w pobliżu (wybuchy 60% siły, mniejsze płonące kręgi)."},
	"g_dance": {"name": "Kamień Rykoszetu Płomieni", "short": "Odbicia sierpów",
		"text": "Sierpy ognia odbijają się od trafionego wroga w kolejnego w pobliżu - do 3 odbić."},
	# hydrosfera (pomysły autora 14.11.2026)
	"h_bolt": {"name": "Kamień Wodnej Orbity", "short": "Krążące bańki",
		"text": "Bańki nie lecą w wroga, tylko przez 3 s krążą wokół ciebie i przebijają wrogów (najwyżej 4 naraz)."},
	"h_wave": {"name": "Kamień Przypływu", "short": "Fale dookoła",
		"text": "Fala wylatuje na wszystkie strony: 6 fal dookoła ciebie, każda o 40% słabsza."},
	"h_vortex": {"name": "Kamień Wędrownego Wiru", "short": "Wir wędruje",
		"text": "Wir sam płynie ku najbliższym wrogom i wciąga ich po drodze; kręci się o 1 s dłużej."},
	"h_geyser": {"name": "Kamień Erupcji", "short": "Kule z gejzerów",
		"text": "Każdy gejzer wypluwa 3 kule wody, które spadają dookoła i ranią obszarem (60% siły gejzera)."},
	"h_guardian": {"name": "Kamień Echa", "short": "Strażnik powtarza",
		"text": "Strażnik powtarza ze swojego miejsca twoją Falę, Wir i Gejzery - za darmo, z połową siły."},
}
const UNIQUE_COLOR := Color(1.0, 0.82, 0.35)
## Dawne identyfikatory kamieni -> obecne (wczytanie starego zapisu): kamień unikalny Mgnienia miecza przeszedł
## na Błysk Peruna katany (15.11.2026).
const LEGACY := {"unique:blink": "unique:k_flash"}
const SUPPORT_ORDER := ["multi", "area", "ember", "rime", "discharge", "haste", "thrift", "leech"]
## Oszczędność w zwykłym ciosie: many za trafienie na 1. i MAX_LEVEL poziomie.
const THRIFT_STRIKE := [1, 4]

## Kamienie szlachetne: nazwa, plik ikony (z Watry, `<rodzaj>_<liczba premii>.png` - kamień rośnie z premiami),
## kolor i `pool` - premie (Items.STAT_FORMATS), które mogą na nim wypaść; działają tak samo w każdym miejscu przedmiotu.
const JEWELS := {
	"ruby": {"name": "Rubin", "color": Color(1.0, 0.42, 0.42),
		"pool": ["damage_pct", "hp", "regen", "crit_pct", "crit_dmg_pct", "pen_pct"]},
	"sapphire": {"name": "Szafir", "color": Color(0.43, 0.66, 1.0),
		"pool": ["mana", "mana_regen", "cdr_pct", "xp_pct", "ember_pct"]},
	"emerald": {"name": "Szmaragd", "color": Color(0.37, 0.86, 0.49),
		"pool": ["attack_speed_pct", "move_pct", "dodge_pct", "pickup_pct", "area_pct"]},
	"onyx": {"name": "Onyks", "color": Color(0.78, 0.78, 0.82),
		"pool": ["protection_pct", "hp", "life_on_kill", "regen", "element_res_pct"]},
}
const JEWEL_ORDER := ["ruby", "sapphire", "emerald", "onyx"]

const SPECIAL := {
	KEY: {"name": "Klucz Runiczny", "icon": "res://assets/watra/gems/rune_ascend.png", "color": Color(1.0, 0.8, 0.35),
		"text": "Otwiera kolejne gniazdo wybranej umiejętności (okno umiejętności)."},
	CHISEL: {"name": "Dłuto Jubilera", "icon": "res://assets/watra/gems/rune_polish.png", "color": Color(0.7, 0.85, 1.0),
		"text": "Dorabia drugie gniazdo w przedmiocie (opis przedmiotu w oknie „Postać”)."},
}
const SOCKET_ICON := preload("res://assets/watra/gems/socket.png")


## Identyfikator kamienia umiejętności z rodzaju i poziomu ulepszenia.
static func make(kind: String, level := 1) -> String:
	return "%s:%d" % [kind, clampi(level, 1, MAX_LEVEL)]


## Identyfikator kamienia szlachetnego: rodzaj, poziom lochu, z którego wypadł, i premie [[cecha, wartość], ...].
static func make_jewel(kind: String, dungeon_level: int, stats: Array) -> String:
	var parts: PackedStringArray = []
	for s in stats:
		var v: float = s[1]
		parts.append("%s=%s" % [s[0], str(snappedf(v, 0.1)) if s[0] in Items.DECIMAL_STATS else str(roundi(v))])
	return "%s:%d:%s" % [kind, maxi(dungeon_level, 1), ",".join(parts)]


static func kind_of(id: String) -> String:
	return id.get_slice(":", 0)


static func is_special(id: String) -> bool:
	return SPECIAL.has(id)


## Kamień umiejętności: zwykły (rodzaj:poziom) albo unikalny.
static func is_support(id: String) -> bool:
	return (SUPPORT.has(kind_of(id)) and id.get_slice_count(":") == 2 and id.get_slice(":", 1).is_valid_int()
			and int(id.get_slice(":", 1)) >= 1 and int(id.get_slice(":", 1)) <= MAX_LEVEL) or is_unique(id)


## Kamień unikalny ("unique:<umiejętność>").
static func is_unique(id: String) -> bool:
	return id.begins_with(UNIQUE_PREFIX) and UNIQUE.has(id.trim_prefix(UNIQUE_PREFIX))


## Identyfikator kamienia unikalnego umiejętności.
static func unique_of(skill: String) -> String:
	return UNIQUE_PREFIX + skill


## Umiejętność kamienia unikalnego ("" - to nie unikalny).
static func unique_skill(id: String) -> String:
	return id.trim_prefix(UNIQUE_PREFIX) if is_unique(id) else ""


## Czy w gniazdach umiejętności `skill` siedzi jej kamień unikalny.
static func has_unique(sockets: Array, skill: String) -> bool:
	return sockets.has(unique_of(skill))


## Kamień szlachetny z premiami (stare identyfikatory "rubin:stopień" sprzed 15.11.2026 nie przechodzą - decyzja autora).
static func is_jewel(id: String) -> bool:
	return JEWELS.has(kind_of(id)) and id.get_slice_count(":") == 3 and not jewel_stats(id).is_empty()


## Czy identyfikator jest poprawny (z zapisu gry).
static func valid(id) -> bool:
	return id is String and (is_special(id) or is_support(id) or is_jewel(id))


## Poziom ulepszenia kamienia umiejętności (1-MAX_LEVEL); szlachetny - liczba premii; inne - 0.
static func level_of(id: String) -> int:
	if is_unique(id) or is_special(id):
		return 0
	if JEWELS.has(kind_of(id)):
		return jewel_stats(id).size()
	return clampi(int(id.get_slice(":", 1)), 1, MAX_LEVEL) if id.contains(":") else 0


## Poziom lochu, z którego wypadł kamień szlachetny (siła dokładanych premii).
static func jewel_level(id: String) -> int:
	return maxi(int(id.get_slice(":", 1)), 1)


## Premie kamienia szlachetnego: [[cecha, wartość], ...] (pusta - zły identyfikator).
static func jewel_stats(id: String) -> Array:
	var out: Array = []
	if not JEWELS.has(kind_of(id)) or id.get_slice_count(":") != 3:
		return out
	for part in id.get_slice(":", 2).split(",", false):
		var stat := part.get_slice("=", 0)
		if not Items.STAT_FORMATS.has(stat) or not part.contains("="):
			return []
		out.append([stat, float(part.get_slice("=", 1))])
	return out


## Nazwa: „Żar”, „Rubin”, „Klucz Runiczny”, „Kamień Wichrowego Ostrza” (poziom pokazuje `kind_line` i pole).
static func name_of(id: String) -> String:
	if is_special(id):
		return Lang.t(SPECIAL[id].name)
	if is_unique(id):
		return Lang.t(UNIQUE[unique_skill(id)].name)
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	return Lang.t(data.name) if not data.is_empty() else ""


static func color_of(id: String) -> Color:
	if is_special(id):
		return SPECIAL[id].color
	if is_unique(id):
		return UNIQUE_COLOR
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	return data.get("color", Color.WHITE)


static func icon_of(id: String) -> Texture2D:
	if is_special(id):
		return load(SPECIAL[id].icon)
	if is_unique(id):
		return load("res://assets/watra/unique_gems/%s.png" % unique_skill(id))
	if is_support(id):
		return load("res://assets/watra/supports/%s.png" % SUPPORT[kind_of(id)].icon)
	if is_jewel(id):
		return load("res://assets/watra/gems/%s_%d.png" % [kind_of(id), clampi(level_of(id), 1, 5)])
	return null


## Rodzaj kamienia słowami („Kamień umiejętności, poziom 3/10”, „Kamień szlachetny, premie 3/5”).
static func kind_line(id: String) -> String:
	if is_special(id):
		return Lang.t("Rzadki przedmiot")
	if is_unique(id):
		return Lang.t("Kamień unikalny: %s") % Skills.name_of(unique_skill(id))
	if is_support(id):
		return Lang.t("Kamień umiejętności, poziom %d/%d") % [level_of(id), MAX_LEVEL]
	return Lang.t("Kamień szlachetny, premie %d/%d") % [level_of(id), JEWEL_MAX]


## Krótki opis działania kamienia pod gniazdem (kilka słów): kamień umiejętności w umiejętności `skill`,
## szlachetny - liczba premii.
const SHORT := {
	"multi": "Więcej ostrzy",
	"area": "+%d%% obszaru",
	"ember": "Podpala %d%%",
	"rime": "Spowalnia %d%%",
	"discharge": "Piorun %d%%",
	"haste": "-%d%% odnowienia",
	"thrift": "-%d%% many",
	"leech": "Leczy %d%%",
}
const SHORT_STRIKE := {"haste": "+%d%% szybkości", "thrift": "+%d many za cios"}


static func short_text(id: String, skill := "", _slot := "") -> String:
	if is_unique(id):
		return Lang.t(UNIQUE[unique_skill(id)].short)
	if is_support(id):
		var kind := kind_of(id)
		if kind == "thrift" and Skills.is_basic(skill):
			return Lang.t(SHORT_STRIKE.thrift) % thrift_mana(level_of(id))
		var text: String = SHORT_STRIKE[kind] if Skills.is_basic(skill) and SHORT_STRIKE.has(kind) else SHORT[kind]
		return Lang.t(text) % roundi(support_value(id)) if text.contains("%d") else Lang.t(text)
	if is_jewel(id):
		return Lang.n(level_of(id), "%d premia", "%d premie", "%d premii") % level_of(id)
	return ""


## Wartość z pary [na 1. poziomie, na MAX_LEVEL] dla poziomu `level` (płynnie, zaokrąglona).
static func _lerp_level(pair: Array, level: int) -> int:
	return roundi(lerpf(float(pair[0]), float(pair[1]), float(clampi(level, 1, MAX_LEVEL) - 1) / (MAX_LEVEL - 1)))


## Siła kamienia umiejętności (z `values` na jego poziomie).
static func support_value(id: String) -> float:
	return float(_lerp_level(SUPPORT[kind_of(id)].values, level_of(id))) if is_support(id) and not is_unique(id) else 0.0


## Oszczędność w zwykłym ciosie: many za trafienie na poziomie `level`.
static func thrift_mana(level: int) -> int:
	return _lerp_level(THRIFT_STRIKE, level)


## Opis działania kamienia umiejętności; z `skill` - jak działa w tej umiejętności.
static func support_text(id: String, skill := "") -> String:
	if not is_support(id):
		return ""
	if is_unique(id):
		var own := unique_skill(id)
		var text := Lang.t(UNIQUE[own].text)
		return text if skill == "" or skill == own else Lang.t("Pasuje tylko do: %s.") % Skills.name_of(own)
	var kind := kind_of(id)
	var data: Dictionary = SUPPORT[kind]
	if kind == "thrift" and Skills.is_basic(skill):
		return Lang.t(data.skills.strike) % thrift_mana(level_of(id))
	var text: String = data.get("skills", {}).get(skill, data.text)
	return Lang.t(text) % roundi(support_value(id))


## Premie kamienia szlachetnego słowami („+6% obrażeń”), każda osobno.
static func jewel_lines(id: String) -> Array[String]:
	var lines: Array[String] = []
	for s in jewel_stats(id):
		lines.append(Items.stat_text(s[0], s[1]))
	return lines


## Premie kamienia szlachetnego w jednej linii („+6% obrażeń, +20 do zdrowia”) - opis gniazda przedmiotu.
static func jewel_text(id: String, _slot := "") -> String:
	return ", ".join(jewel_lines(id))


## Linie opisu kamienia w sakwie (bez kontekstu umiejętności czy przedmiotu).
static func description(id: String) -> Array[String]:
	if is_special(id):
		return [Lang.t(SPECIAL[id].text)]
	if is_support(id):
		return [support_text(id)]
	return jewel_lines(id)


# --- łup ---

## Kamień szlachetny rodzaju `kind` z łupu na poziomie lochu: 2-3 różne premie z jego puli.
static func roll_jewel(kind: String, level: int, count := -1) -> String:
	if count < 0:
		count = 3 if randf() < JEWEL_THREE else 2
	var pool: Array = JEWELS[kind].pool.duplicate()
	pool.shuffle()
	var stats: Array = []
	for i in mini(count, pool.size()):
		stats.append([pool[i], _jewel_value(pool[i], level)])
	return make_jewel(kind, level, stats)


## Siła premii kamienia szlachetnego z poziomu lochu (część premii przedmiotu, co najmniej 1 / 0,1).
static func _jewel_value(stat: String, level: int) -> float:
	var v := Items.roll_affix(stat, level) * JEWEL_MULT
	return maxf(snappedf(v, 0.1), 0.1) if stat in Items.DECIMAL_STATS else float(maxi(roundi(v), 1))


## Kamień z łupu na poziomie lochu: kamień umiejętności (1. poziom) albo szlachetny z premiami z tego poziomu.
static func roll(level: int) -> String:
	if randf() < SUPPORT_SHARE:
		return make(SUPPORT_ORDER.pick_random())
	return roll_jewel(JEWEL_ORDER.pick_random(), level)


## Łup z goblina: kamień, klucz albo dłuto (rzadko; poniżej MIN_LEVEL nic) - "" gdy nic.
## `chance_mult` - mnożnik szans (ulepszenie łupu).
static func roll_goblin(level: int, chance_mult := 1.0) -> String:
	if level < MIN_LEVEL:
		return ""
	var r := randf()
	if r < GOBLIN_RARE * chance_mult:
		return KEY if randf() < 0.5 else CHISEL
	return roll(level) if r < (GOBLIN_RARE + GOBLIN_GEM) * chance_mult else ""


## Łup ze skrzyni Wodza: lista identyfikatorów (kamienie, klucz, dłuto; poniżej MIN_LEVEL - pusta).
## `chance_mult` - mnożnik szans (ulepszenie łupu).
static func roll_chest(level: int, chance_mult := 1.0) -> Array:
	var out: Array = []
	if level < MIN_LEVEL:
		return out
	for chance in CHEST_GEM:
		if randf() < chance * chance_mult:
			out.append(roll(level))
	var step := CHEST_RARE_STEP * (level - MIN_LEVEL)
	if level >= UNIQUE_MIN_LEVEL and randf() < minf(CHEST_UNIQUE.x + CHEST_RARE_STEP * (level - UNIQUE_MIN_LEVEL),
			CHEST_UNIQUE.y) * chance_mult:
		out.append(unique_of(UNIQUE.keys().pick_random()))
	if randf() < minf(CHEST_KEY.x + step, CHEST_KEY.y) * chance_mult:
		out.append(KEY)
	if randf() < minf(CHEST_CHISEL.x + step, CHEST_CHISEL.y) * chance_mult:
		out.append(CHISEL)
	return out


# --- ulepszanie, sprzedaż, rozbijanie ---

## Czy kamień da się ulepszyć (kamień umiejętności poniżej MAX_LEVEL, szlachetny poniżej JEWEL_MAX premii).
static func can_upgrade(id: String) -> bool:
	if is_jewel(id):
		return level_of(id) < mini(JEWEL_MAX, JEWELS[kind_of(id)].pool.size())
	return is_support(id) and not is_unique(id) and level_of(id) < MAX_LEVEL


## Koszt następnego ulepszenia: Vector2i(złoto, odpryski); Vector2i.ZERO - nie da się.
static func upgrade_cost(id: String) -> Vector2i:
	if not can_upgrade(id):
		return Vector2i.ZERO
	var lvl := level_of(id)
	if is_jewel(id):
		var gold := roundi(JEWEL_GOLD[lvl + 1] * (1.0 + 0.05 * (jewel_level(id) - 1)) / 10.0) * 10
		return Vector2i(gold, JEWEL_SHARDS[lvl + 1])
	return Vector2i(roundi(UPGRADE_GOLD * pow(UPGRADE_GROWTH, lvl - 1) / 10.0) * 10, roundi(UPGRADE_SHARDS * lvl))


## Kamień po ulepszeniu: kamień umiejętności o poziom wyżej, szlachetny z dołożoną losową premią z puli
## (z poziomu lochu kamienia). Gdy się nie da - ten sam identyfikator.
static func upgraded(id: String) -> String:
	if not can_upgrade(id):
		return id
	if is_support(id):
		return make(kind_of(id), level_of(id) + 1)
	var stats := jewel_stats(id)
	var free: Array = []
	for stat in JEWELS[kind_of(id)].pool:
		if not stats.any(func(s: Array) -> bool: return s[0] == stat):
			free.append(stat)
	var stat: String = free.pick_random()
	stats.append([stat, _jewel_value(stat, jewel_level(id))])
	return make_jewel(kind_of(id), jewel_level(id), stats)


## Ile złota i odprysków włożono w ulepszenia kamienia (Vector2i; szlachetny liczony od 2 premii).
static func invested(id: String) -> Vector2i:
	var total := Vector2i.ZERO
	if is_jewel(id):
		for n in range(3, level_of(id) + 1):
			total += Vector2i(roundi(JEWEL_GOLD[n] * (1.0 + 0.05 * (jewel_level(id) - 1)) / 10.0) * 10, JEWEL_SHARDS[n])
	elif is_support(id) and not is_unique(id):
		for lvl in range(1, level_of(id)):
			total += upgrade_cost(make(kind_of(id), lvl))
	return total


## Czy kamień można sprzedać albo rozbić (klucze i dłuta nie).
static func can_sell(id: String) -> bool:
	return is_support(id) or is_jewel(id)


## Ile złota daje sprzedaż sztuki kamienia.
static func sell_price(id: String) -> int:
	if is_unique(id):
		return SELL_UNIQUE
	if is_jewel(id):
		return roundi(SELL_JEWEL * level_of(id) * (1.0 + 0.05 * (jewel_level(id) - 1)))
	if is_support(id):
		return SELL_SUPPORT + roundi(invested(id).x * SELL_SHARE)
	return 0


## Ile odprysków daje rozbicie sztuki kamienia.
static func shard_value(id: String) -> int:
	if is_unique(id):
		return SHATTER_UNIQUE
	if can_sell(id):
		return SHATTER_BASE + roundi(invested(id).y * SELL_SHARE)
	return 0


## Siła kamienia umiejętności rodzaju `kind` w gniazdach (lista identyfikatorów; 0 - brak).
static func skill_power(sockets: Array, kind: String) -> float:
	for id in sockets:
		if id is String and is_support(id) and not is_unique(id) and kind_of(id) == kind:
			return support_value(id)
	return 0.0


## Poziom kamienia rodzaju `kind` w gniazdach (0 - brak).
static func skill_level(sockets: Array, kind: String) -> int:
	for id in sockets:
		if id is String and is_support(id) and not is_unique(id) and kind_of(id) == kind:
			return level_of(id)
	return 0

class_name AuraData
## Dane aur rezerwujących manę (lista zatwierdzona przez autora 19.11.2026 - docs/ROADMAP.md): nazwy, rezerwacja,
## kolory kręgów, opisy i siła na poziomach 1-10. Wzór: ../Watra/scripts/aura_data.gd.
## Aura włączona na stałe zabiera część maksymalnej many (rezerwacja). Razem aury rezerwują najwyżej MAX_RESERVED many,
## więc zawsze zostaje trochę na umiejętności. Działanie w prototypie walki - ProtoAuras; aury z `ready: false`
## już rezerwują manę, ale działać zaczną, gdy powstaną potrzebne systemy (wrogowie, żywioły, łup).

## Razem aury rezerwują najwyżej tyle many (75% - na start mieszczą się 2 aury, 3 tylko najtańsze).
const MAX_RESERVED := 0.75
const MAX_LEVEL := 10

## Kolejność na liście w zakładce „Aury”.
const ORDER: Array[String] = [
	"krzepa", "strzybog", "zywia", "mana", "swarog", "perun", "ognik", "szron", "postrach", "mgla", "mokosz",
	"czarnobog", "jarylo", "trzyglow", "kamienna_krew", "popiol", "mroz", "licho", "pieczec", "hart", "weles",
]

## name - nazwa, reserve - ułamek pełnej many, color - kolor kręgu i ikony, radius - zasięg aury działającej
## na wrogów w kręgu (0 - aura na postać), ready - czy działa już w prototypie, desc - opis aury, która jeszcze nie działa.
const DATA := {
	"krzepa": {"name": "Krzepa", "reserve": 0.25, "color": Color8(220, 70, 60), "radius": 0.0, "ready": true},
	"strzybog": {"name": "Wiatr Strzyboga", "reserve": 0.30, "color": Color8(120, 230, 200), "radius": 0.0, "ready": true},
	"zywia": {"name": "Źródło Żywii", "reserve": 0.20, "color": Color8(240, 120, 150), "radius": 0.0, "ready": true},
	"mana": {"name": "Źródło Many", "reserve": 0.15, "color": Color8(90, 150, 255), "radius": 0.0, "ready": true},
	"swarog": {"name": "Żar Swaroga", "reserve": 0.25, "color": Color8(255, 140, 50), "radius": 0.0, "ready": true},
	"perun": {"name": "Gniew Peruna", "reserve": 0.35, "color": Color8(255, 225, 80), "radius": 0.0, "ready": true},
	"ognik": {"name": "Błędny Ognik", "reserve": 0.35, "color": Color8(160, 255, 140), "radius": 0.0, "ready": true},
	"szron": {"name": "Szron Marzanny", "reserve": 0.25, "color": Color8(150, 220, 255), "radius": 70.0, "ready": true},
	"postrach": {"name": "Postrach", "reserve": 0.30, "color": Color8(170, 70, 200), "radius": 80.0, "ready": false,
		"desc": "Wrogowie w kręgu zadają mniej obrażeń i atakują wolniej"},
	"mgla": {"name": "Mgła Nawii", "reserve": 0.30, "color": Color8(140, 170, 150), "radius": 80.0, "ready": false,
		"desc": "Wrogowie w kręgu czasem chybiają"},
	"mokosz": {"name": "Opieka Mokoszy", "reserve": 0.30, "color": Color8(180, 130, 80), "radius": 0.0, "ready": false,
		"desc": "Co kilka sekund odnawia tarczę, która pochłania część obrażeń"},
	"czarnobog": {"name": "Piętno Czarnoboga", "reserve": 0.30, "color": Color8(170, 30, 40), "radius": 80.0, "ready": false,
		"desc": "Wrogowie w kręgu dostają tym więcej obrażeń, im dłużej w nim stoją"},
	"jarylo": {"name": "Oko Jaryły", "reserve": 0.25, "color": Color8(170, 240, 90), "radius": 0.0, "ready": false,
		"desc": "Większa szansa na trafienie krytyczne i mocniejsze krytyki"},
	"trzyglow": {"name": "Pancerz Trzygłowa", "reserve": 0.30, "color": Color8(160, 175, 190), "radius": 0.0, "ready": false,
		"desc": "Więcej pancerza: mniej obrażeń od ciosów fizycznych"},
	"kamienna_krew": {"name": "Kamienna Krew", "reserve": 0.20, "color": Color8(130, 120, 110), "radius": 0.0, "ready": false,
		"desc": "Przy niskim zdrowiu dostajesz dużo mniej obrażeń"},
	"popiol": {"name": "Zwiastun Popiołu", "reserve": 0.25, "color": Color8(230, 110, 70), "radius": 0.0, "ready": false,
		"desc": "Zabity wróg wybucha ogniem i podpala sąsiadów"},
	"mroz": {"name": "Zwiastun Mrozu", "reserve": 0.25, "color": Color8(110, 200, 255), "radius": 0.0, "ready": false,
		"desc": "Zamrożony albo zabity wróg pęka w lodowe odłamki, które ranią sąsiadów"},
	"licho": {"name": "Złość Licha", "reserve": 0.30, "color": Color8(110, 50, 150), "radius": 0.0, "ready": false,
		"desc": "Obrażenia w czasie (podpalenia, mróz, trucizny, Nawia) są mocniejsze i trwają dłużej"},
	"pieczec": {"name": "Pieczęć Rodu", "reserve": 0.30, "color": Color8(210, 215, 225), "radius": 0.0, "ready": false,
		"desc": "Większa odporność na wszystkie żywioły"},
	"hart": {"name": "Hart Żywiołów", "reserve": 0.35, "color": Color8(255, 200, 230), "radius": 0.0, "ready": false,
		"desc": "Większa maksymalna odporność na żywioły"},
	"weles": {"name": "Dłoń Welesa", "reserve": 0.20, "color": Color8(230, 190, 70), "radius": 0.0, "ready": false,
		"desc": "Przyciąga łup i doświadczenie z dużej odległości"},
}

## Gniew Peruna: odstęp piorunów i zasięg szukania wroga.
const PERUN_INTERVAL := 3.0
const PERUN_RANGE := 220.0
## Szron Marzanny: co tyle sekund rany od mrozu wrogom w kręgu.
const SZRON_TICK := 0.5
## Błędny Ognik: promień i czas okrążenia, przerwa między trafieniami tego samego wroga.
const OGNIK_RADIUS := 40.0
const OGNIK_PERIOD := 2.2
const OGNIK_HIT_GAP := 0.6


static func is_aura(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id]["name"])


static func color_of(id: String) -> Color:
	return DATA[id]["color"]


static func radius_of(id: String) -> float:
	return DATA[id]["radius"]


static func is_ready(id: String) -> bool:
	return DATA[id]["ready"]


## Ile pełnej many rezerwuje aura (z redukcją rezerwacji, np. 0.1 = 10% taniej).
static func reserve_of(id: String, reduction := 0.0) -> float:
	return DATA[id]["reserve"] * (1.0 - clampf(reduction, 0.0, 0.9))


## Ile many rezerwują razem podane aury.
static func reserved_total(auras: Array, reduction := 0.0) -> float:
	var total := 0.0
	for id in auras:
		if is_aura(id):
			total += reserve_of(id, reduction)
	return total


## Dlaczego nie da się włączyć aury ("" - da się).
static func block_reason(id: String, active: Array, reduction := 0.0) -> String:
	if not is_aura(id) or active.has(id):
		return ""
	if reserved_total(active, reduction) + reserve_of(id, reduction) > MAX_RESERVED + 0.0001:
		return Lang.t("Za mało wolnej many - wyłącz inną aurę")
	return ""


## Siła aury: [wartość na poziomie 1, przyrost za poziom].
const POWER := {
	"krzepa": [0.20, 0.02], "strzybog": [0.10, 0.01], "zywia": [0.01, 0.002], "mana": [0.02, 0.004],
	"swarog": [0.15, 0.03], "perun": [1.2, 0.15], "ognik": [0.5, 0.06], "szron": [0.15, 0.03],
}


## Siła aury na danym poziomie (ułamek: np. 0.2 = +20%).
static func power(id: String, level := 1) -> float:
	var p: Array = POWER.get(id, [0.0, 0.0])
	return p[0] + p[1] * (clampi(level, 1, MAX_LEVEL) - 1)


## Opis działania na danym poziomie (zakładka „Aury”).
static func effect_text(id: String, level := 1) -> String:
	var v := power(id, level)
	match id:
		"krzepa":
			return Lang.t("+%d%% maksymalnego zdrowia") % roundi(v * 100)
		"strzybog":
			return Lang.t("+%d%% szybkości ruchu i ataku") % roundi(v * 100)
		"zywia":
			return Lang.t("Odnawia %s%% maksymalnego zdrowia na sekundę") % decimal(v * 100)
		"mana":
			return Lang.t("Odnawia %s%% maksymalnej many na sekundę") % decimal(v * 100)
		"swarog":
			return Lang.t("Ciosy zadają dodatkowo %d%% obrażeń od ognia") % roundi(v * 100)
		"perun":
			return Lang.t("Co %d s piorun uderza we wroga: %d%% obrażeń broni") % [roundi(PERUN_INTERVAL), roundi(v * 100)]
		"ognik":
			return Lang.t("Ognik krąży wokół ciebie i rani wrogów: %d%% obrażeń broni") % roundi(v * 100)
		"szron":
			return Lang.t("Wrogowie w kręgu zwalniają i co pół sekundy dostają %d%% obrażeń broni od mrozu") % roundi(v * 100)
	return Lang.t(DATA[id].get("desc", ""))


## Liczba z jednym miejscem po przecinku (po polsku przecinek: „1,5”).
static func decimal(value: float) -> String:
	var s := String.num(value, 1)
	if not "." in s:
		s += ".0"
	return s.replace(".", ",") if Lang.is_polish() else s


## Napis kosztu: "rezerwuje 30% many".
static func cost_text(id: String, reduction := 0.0) -> String:
	return Lang.t("rezerwuje %d%% many") % roundi(reserve_of(id, reduction) * 100)

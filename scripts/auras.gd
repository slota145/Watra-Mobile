class_name Auras
## Aury rezerwujące manę (pomysł autora 19.11.2026, lista 21 aur zatwierdzona tego samego dnia - docs/ROADMAP.md;
## wzór: ../Watra/scripts/aura_data.gd). Aura włączona na stałe zabiera część maksymalnej many (rezerwacja,
## `reserve`), a w zamian daje premię albo działa sama (piorun, krąg mrozu, ognik - ProtoAuras).
## Zasady (ustalone z autorem 19.11.2026):
## - aurę zdobywa się z łupu: kamień aury wypada od poziomu lochu MIN_LEVEL ze skrzyni Wodza i ze skrzyń na mapie
##   lochu (`roll_chest`); po podniesieniu aura od razu jest w zakładce „Aury” (Game.add_aura), bez sakwy;
## - kolejny taki sam kamień podnosi poziom aury (1-MAX_LEVEL): mocniejsze działanie i trochę mniejsza rezerwacja
##   (RESERVE_CUT za poziom);
## - aury rezerwują razem najwyżej MAX_RESERVED many i nigdy nie zabierają many potrzebnej na najdroższą założoną
##   umiejętność (Game.aura_problem) - dlatego wypadają dopiero od lochu 8, gdy postać ma 100+ many.
## Ten plik to same dane i liczby; zapis (poziomy, włączone) w Game, działanie w ProtoHero (premie postaci przez
## `apply`), ProtoWeapon (ogień Swaroga) i ProtoAuras (kręgi pod postacią, piorun, mróz, ognik).
## Gotowe jest 8 aur (`ready`), pozostałe 13 z listy dojdzie w kolejnej sesji (docs/ROADMAP.md).

## Razem aury rezerwują najwyżej tyle many (zawsze zostaje ćwierć na umiejętności).
const MAX_RESERVED := 0.75
const MAX_LEVEL := 10
## Rezerwacja maleje o tyle (część) z każdym poziomem aury ponad pierwszy (10. poziom - o 18% taniej).
const RESERVE_CUT := 0.02
## Od tego poziomu lochu wypadają kamienie aur (decyzja autora 19.11.2026 - wcześniej za mało many na 2 aury).
const MIN_LEVEL := 8
## Szansa na kamień aury ze skrzyni Wodza i ze skrzyni na mapie lochu.
const CHEST_CHANCE := 0.25
const GOAL_CHEST_CHANCE := 0.12

## Kolejność na liście w zakładce „Aury” (najpierw gotowe).
const ORDER: Array[String] = ["krzepa", "strzybog", "zywia", "mana", "swarog", "perun", "ognik", "szron"]

## name - nazwa, reserve - ułamek pełnej many, color - kolor kręgu i ikony, radius - zasięg aury działającej
## na wrogów w kręgu (0 - aura na postać), power - [siła na 1. poziomie, przyrost za poziom].
const DATA := {
	"krzepa": {"name": "Krzepa", "reserve": 0.25, "color": Color8(220, 70, 60), "radius": 0.0, "power": [0.20, 0.02]},
	"strzybog": {"name": "Wiatr Strzyboga", "reserve": 0.30, "color": Color8(120, 230, 200), "radius": 0.0,
		"power": [0.10, 0.01]},
	"zywia": {"name": "Źródło Żywii", "reserve": 0.20, "color": Color8(240, 120, 150), "radius": 0.0,
		"power": [0.01, 0.002]},
	"mana": {"name": "Źródło Many", "reserve": 0.15, "color": Color8(90, 150, 255), "radius": 0.0,
		"power": [0.02, 0.003]},
	"swarog": {"name": "Żar Swaroga", "reserve": 0.25, "color": Color8(255, 140, 50), "radius": 0.0,
		"power": [0.15, 0.03]},
	"perun": {"name": "Gniew Peruna", "reserve": 0.35, "color": Color8(110, 170, 255), "radius": 0.0,
		"power": [1.2, 0.15]},
	"ognik": {"name": "Błędny Ognik", "reserve": 0.35, "color": Color8(160, 255, 140), "radius": 0.0,
		"power": [0.5, 0.06]},
	"szron": {"name": "Szron Marzanny", "reserve": 0.25, "color": Color8(170, 230, 255), "radius": 70.0,
		"power": [0.15, 0.03]},
}

## Gniew Peruna: odstęp piorunów, zasięg szukania wroga, porażenie celu (s).
const PERUN_INTERVAL := 3.0
const PERUN_RANGE := 220.0
const PERUN_SHOCK := 2.0
## Szron Marzanny: co tyle sekund rany od mrozu wrogom w kręgu, spowolnienie (część szybkości).
const SZRON_TICK := 0.5
const SZRON_SLOW := 0.25
## Błędny Ognik: promień i czas okrążenia, przerwa między trafieniami tego samego wroga.
const OGNIK_RADIUS := 40.0
const OGNIK_PERIOD := 2.2
const OGNIK_HIT_GAP := 0.6
## Żar Swaroga: podpalenie za tyle części dodanego ognia.
const SWAROG_BURN := 0.5


static func is_aura(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id]["name"]) if DATA.has(id) else ""


static func color_of(id: String) -> Color:
	return DATA[id]["color"] if DATA.has(id) else Color.WHITE


static func radius_of(id: String) -> float:
	return DATA[id]["radius"] if DATA.has(id) else 0.0


## Ile pełnej many rezerwuje aura na danym poziomie (ułamek).
static func reserve_of(id: String, level := 1) -> float:
	if not DATA.has(id):
		return 0.0
	return DATA[id]["reserve"] * (1.0 - RESERVE_CUT * (clampi(level, 1, MAX_LEVEL) - 1))


## Ile many rezerwują razem włączone aury (`on` - lista, `levels` - aura -> poziom).
static func reserved_total(on: Array, levels: Dictionary) -> float:
	var total := 0.0
	for id in on:
		total += reserve_of(id, levels.get(id, 1))
	return minf(total, MAX_RESERVED)


## Siła aury na danym poziomie (ułamek: np. 0.2 = +20%).
static func power(id: String, level := 1) -> float:
	if not DATA.has(id):
		return 0.0
	var p: Array = DATA[id]["power"]
	return p[0] + p[1] * (clampi(level, 1, MAX_LEVEL) - 1)


## Premie postaci z włączonych aur dopisane do sumy cech przedmiotów (`gear` - kopia; Items.totals): szybkość ruchu
## i ataku (Strzybóg, z sufitami Items.CAPS) oraz klucze aur czytane przez ProtoHero.apply_gear: aura_hp_pct
## (Krzepa), aura_regen_pct (Żywia - część zdrowia na sekundę), aura_mana_regen_pct (część many na sekundę),
## aura_reserve (rezerwacja), aura_fire (Swaróg - część ciosu dodana jako ogień, czyta arena dla broni).
static func apply(gear: Dictionary, on: Array, levels: Dictionary) -> Dictionary:
	var g := gear.duplicate()
	if on.is_empty():
		return g
	g["aura_reserve"] = reserved_total(on, levels)
	for id in on:
		var p := power(id, levels.get(id, 1))
		match id:
			"krzepa":
				g["aura_hp_pct"] = p
			"strzybog":
				for stat in ["move_pct", "attack_speed_pct"]:
					g[stat] = minf(g.get(stat, 0.0) + p * 100.0, Items.CAPS.get(stat, INF))
			"zywia":
				g["aura_regen_pct"] = p
			"mana":
				g["aura_mana_regen_pct"] = p
			"swarog":
				g["aura_fire"] = p
	return g


## Opis działania na danym poziomie (zakładka „Aury”, powiadomienie o nowej aurze).
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
			return Lang.t("Ciosy zadają dodatkowo %d%% obrażeń od ognia i podpalają") % roundi(v * 100)
		"perun":
			return Lang.t("Co %d s piorun uderza we wroga: %d%% obrażeń broni") % [roundi(PERUN_INTERVAL), roundi(v * 100)]
		"ognik":
			return Lang.t("Ognik krąży wokół ciebie i rani wrogów: %d%% obrażeń broni") % roundi(v * 100)
		"szron":
			return Lang.t("Wrogowie w kręgu zwalniają i co pół sekundy dostają %d%% obrażeń broni od mrozu") % roundi(v * 100)
	return ""


## Liczba z jednym miejscem po przecinku (po polsku przecinek: „1,5”).
static func decimal(value: float) -> String:
	var s := String.num(value, 1)
	if not "." in s:
		s += ".0"
	return s.replace(".", ",") if Lang.is_polish() else s


## Napis kosztu: "rezerwuje 30% many".
static func cost_text(id: String, level := 1) -> String:
	return Lang.t("rezerwuje %d%% many") % roundi(reserve_of(id, level) * 100)


## Kamień aury ze skrzyni (Wódz: `goal` false, skrzynia na mapie lochu: true); "" - nic. `luck` - mnożnik łupu lochu.
static func roll_chest(level: int, goal := false, luck := 1.0) -> String:
	if level < MIN_LEVEL or randf() >= (GOAL_CHEST_CHANCE if goal else CHEST_CHANCE) * luck:
		return ""
	return ORDER[randi() % ORDER.size()]


## Ikona aury (kamień w kolorze aury z jasnym pierścieniem) - rysowana w kodzie, raz na aurę.
static var _icons := {}
static func icon_of(id: String) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := color_of(id)
	var mid := Vector2(15.5, 15.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(mid)
			if d <= 14.5 and d > 12.0:
				img.set_pixel(x, y, c.lightened(0.35))  # pierścień
			elif d <= 12.0 and d > 10.5:
				img.set_pixel(x, y, Color(0.1, 0.07, 0.06, 0.9))
			elif d <= 10.5:
				var light := clampf(1.0 - Vector2(x, y).distance_to(mid + Vector2(-3, -3)) / 14.0, 0.0, 1.0)
				img.set_pixel(x, y, c.darkened(0.35).lerp(c.lightened(0.5), light))
	var tex := ImageTexture.create_from_image(img)
	_icons[id] = tex
	return tex

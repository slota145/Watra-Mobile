class_name Talismans
## Talizmany - przedmioty specjalne bez statystyk, z jednym efektem (pomysł autora 19.11.2026; ustalenia z ankiety
## tego dnia): 3 miejsca na talizmany (okno „Postać”, zakładka „Talizmany”), 10 efektów wzorowanych na legendarnej
## biżuterii Watry (../Watra/scripts/legendary_effects.gd); ikony - trofea i magiczne przedmioty z Watry
## (assets/watra/talismans/; nie biżuteria - zgłoszenie autora 20.11.2026: pierścienie myliły się z ekwipunkiem).
## - wypadają od poziomu lochu MIN_LEVEL ze skrzyń na mapie lochu (`roll_chest`) i jako nagroda Kręgu Żertwy;
## - po podniesieniu talizman od razu jest w kolekcji (Game.add_talisman, bez torby) i sam wskakuje w wolne miejsce;
## - kolejny taki sam podnosi jego poziom (1-MAX_LEVEL): większa szansa i siła efektu.
## Ten plik to dane i liczby; zapis w Game (`talismans`, `talisman_slots`), działanie w ProtoTalismans
## (dziecko postaci - trafienie, zabójstwo, rana, umiejętność, co kilka sekund).

const SLOTS := 3
const MAX_LEVEL := 10
const MIN_LEVEL := 5
## Szansa na talizman ze skrzyni na mapie lochu (razy mnożnik łupu lochu).
const CHEST_CHANCE := 0.10

const ORDER: Array[String] = ["shockwave", "thunder", "whirlpool", "roots", "thorns", "bloodlust", "kaboom", "devour",
		"tremor", "archmage", "overload", "cull", "onslaught", "arcane", "pyre", "blood_magic", "mom", "avatar",
		"point_blank", "pain"]

## name, icon, color (poświata i napisy), trigger - kiedy działa (hit - trafienie wroga, kill - pokonany wróg,
## hurt - rana postaci, skill - użyta umiejętność, passive - co `every` s), chance - [szansa na 1. poziomie, przyrost
## za poziom], power - [siła na 1. poziomie, przyrost] (zwykle część ciosu broni).
const DATA := {
	"shockwave": {"name": "Róg Gruzłoga", "icon": preload("res://assets/watra/talismans/guard_horn.png"),
		"color": Color8(230, 190, 110), "trigger": "hit", "chance": [0.10, 0.008], "power": [0.8, 0.1]},
	"thunder": {"name": "Pióro Gromu", "icon": preload("res://assets/watra/talismans/storm_feather.png"),
		"color": Color8(120, 170, 255), "trigger": "hit", "chance": [0.10, 0.008], "power": [1.0, 0.12]},
	"whirlpool": {"name": "Perła Topieli", "icon": preload("res://assets/watra/talismans/drowned_pearl.png"),
		"color": Color8(80, 150, 255), "trigger": "hit", "chance": [0.08, 0.006], "power": [0.25, 0.03]},
	"roots": {"name": "Gałąź Leszego", "icon": preload("res://assets/watra/talismans/summon_leshy.png"),
		"color": Color8(120, 200, 90), "trigger": "hit", "chance": [0.10, 0.008], "power": [0.4, 0.05]},
	"thorns": {"name": "Kora Leszego", "icon": preload("res://assets/watra/talismans/ancient_bark.png"),
		"color": Color8(150, 210, 80), "trigger": "hurt", "chance": [0.35, 0.03], "power": [1.0, 0.12]},
	"bloodlust": {"name": "Czaszka Biesa", "icon": preload("res://assets/watra/talismans/summon_bies.png"),
		"color": Color8(230, 60, 50), "trigger": "kill", "chance": [0.30, 0.03], "power": [0.06, 0.006]},
	"kaboom": {"name": "Serce Goblina", "icon": preload("res://assets/watra/talismans/goblin_heart.png"),
		"color": Color8(255, 130, 50), "trigger": "kill", "chance": [0.20, 0.02], "power": [0.6, 0.07]},
	"devour": {"name": "Ząb Pożeracza", "icon": preload("res://assets/watra/talismans/worm_tooth.png"),
		"color": Color8(220, 90, 120), "trigger": "kill", "chance": [0.10, 0.01], "power": [0.02, 0.002]},
	"tremor": {"name": "Serce Głębin", "icon": preload("res://assets/watra/talismans/crystal_heart.png"),
		"color": Color8(190, 140, 90), "trigger": "passive", "chance": [1.0, 0.0], "power": [0.5, 0.06]},
	"archmage": {"name": "Kryształ Peruna", "icon": preload("res://assets/watra/talismans/summon_storm_eagle.png"),
		"color": Color8(150, 200, 255), "trigger": "skill", "chance": [1.0, 0.0], "power": [0.15, 0.02]},
	# wzorowane na węzłach drzewka Path of Exile (decyzja autora 20.11.2026)
	"overload": {"name": "Łuska Żmija", "icon": preload("res://assets/watra/talismans/hydra_scale.png"),
		"color": Color8(90, 220, 140), "trigger": "crit", "chance": [1.0, 0.0], "power": [0.30, 0.03]},
	"cull": {"name": "Hak Kata", "icon": preload("res://assets/watra/talismans/summon_giant_worm.png"),
		"color": Color8(190, 60, 70), "trigger": "hit", "chance": [1.0, 0.0], "power": [0.08, 0.004]},
	"onslaught": {"name": "Poroże Jelenia", "icon": preload("res://assets/watra/talismans/antlers.png"),
		"color": Color8(200, 170, 110), "trigger": "kill", "chance": [0.25, 0.02], "power": [0.15, 0.015]},
	"arcane": {"name": "Świeca Wiedźmy", "icon": preload("res://assets/watra/talismans/summon_necromancer.png"),
		"color": Color8(120, 220, 140), "trigger": "mana", "chance": [1.0, 0.0], "power": [0.15, 0.015]},
	"pyre": {"name": "Lont Pożogi", "icon": preload("res://assets/watra/talismans/kobold_fuse.png"),
		"color": Color8(255, 120, 40), "trigger": "kill", "chance": [1.0, 0.0], "power": [0.6, 0.06]},
	"blood_magic": {"name": "Krwawe Serce", "icon": preload("res://assets/watra/talismans/summon_chief.png"),
		"color": Color8(210, 40, 50), "trigger": "passive", "chance": [1.0, 0.0], "power": [1.0, -0.03]},
	"mom": {"name": "Nić Mokoszy", "icon": preload("res://assets/watra/talismans/spider_silk.png"),
		"color": Color8(110, 150, 255), "trigger": "passive", "chance": [1.0, 0.0], "power": [0.20, 0.015]},
	"avatar": {"name": "Krzesiwo Swaroga", "icon": preload("res://assets/watra/talismans/great_flint.png"),
		"color": Color8(255, 150, 60), "trigger": "passive", "chance": [1.0, 0.0], "power": [0.10, 0.02]},
	"point_blank": {"name": "Kieł Niedźwiedzia", "icon": preload("res://assets/watra/talismans/beast_fang.png"),
		"color": Color8(220, 200, 160), "trigger": "passive", "chance": [1.0, 0.0], "power": [0.25, 0.025]},
	"pain": {"name": "Szpon Upiora", "icon": preload("res://assets/watra/talismans/ghoul_claw.png"),
		"color": Color8(120, 160, 120), "trigger": "passive", "chance": [1.0, 0.0], "power": [0.30, 0.03]},
}

## Przerwa po zadziałaniu efektu przy trafieniu (umiejętności trafiające wielu wrogów naraz nie sypią efektami).
const HIT_GAP := 0.25
## Róg Gruzłoga: promień fali i ogłuszenie.
const SHOCK_RADIUS := 40.0
const SHOCK_STUN := 0.6
## Pióro Gromu: piorun przeskakuje na tylu wrogów w tym zasięgu.
const THUNDER_CHAIN := 2
const THUNDER_RANGE := 70.0
## Perła Topieli: wir ciągnie wrogów z promienia, rani co WHIRL_TICK s, WHIRL_TICKS razy.
const WHIRL_RADIUS := 60.0
const WHIRL_TICK := 0.3
const WHIRL_TICKS := 4
const WHIRL_PULL := 120.0
## Gałąź Leszego: korzenie oplątują wrogów w promieniu na ROOTS_TIME s (+ROOTS_TIME_STEP za poziom).
const ROOTS_RADIUS := 35.0
const ROOTS_TIME := 1.5
const ROOTS_TIME_STEP := 0.1
## Kora Leszego: ciernie wokół postaci.
const THORNS_RADIUS := 45.0
## Czaszka Biesa: najwięcej tylu ładunków, każdy trwa tyle sekund (nowy odświeża czas).
const BLOODLUST_STACKS := 5
const BLOODLUST_TIME := 5.0
## Serce Goblina: promień wybuchu pokonanego.
const KABOOM_RADIUS := 45.0
## Serce Głębin: co tyle sekund (-TREMOR_STEP za poziom) drży ziemia w promieniu.
const TREMOR_EVERY := 3.0
const TREMOR_STEP := 0.1
const TREMOR_RADIUS := 60.0
## Kryształ Peruna (jak Archmage w Path of Exile): piorun po umiejętności - część ciosu + część pełnej many;
## umiejętności kosztują więcej many (ARCHMAGE_COST, mniej o ARCHMAGE_COST_STEP za poziom).
const ARCHMAGE_HIT := 0.3
const ARCHMAGE_RANGE := 200.0
const ARCHMAGE_COST := 0.25
const ARCHMAGE_COST_STEP := 0.01
## Łuska Żmija (Elemental Overload): po trafieniu krytycznym premia żywiołów na tyle sekund.
const OVERLOAD_TIME := 8.0
## Poroże Jelenia (Onslaught): szybszy ruch i atak na tyle sekund po zabójstwie.
const ONSLAUGHT_TIME := 4.0
## Świeca Wiedźmy (Arcane Surge): po wydaniu tyle many - premia obrażeń i odnowy many (+ARCANE_REGEN) na ARCANE_TIME s.
const ARCANE_MANA := 50
const ARCANE_TIME := 4.0
const ARCANE_REGEN := 0.5
## Lont Pożogi: płonący pokonany wróg przekazuje ogień sąsiadom w tym promieniu.
const PYRE_RADIUS := 50.0
## Kieł Niedźwiedzia (Point Blank): pełna premia do tej odległości, kara (połowa premii) od tej.
const POINT_BLANK_NEAR := 60.0
const POINT_BLANK_FAR := 130.0
## Szpon Upiora (Pain Attunement): działa poniżej tej części zdrowia.
const PAIN_BELOW := 0.5


static func is_talisman(id: String) -> bool:
	return DATA.has(id)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id]["name"]) if DATA.has(id) else ""


static func icon_of(id: String) -> Texture2D:
	return DATA[id]["icon"] if DATA.has(id) else null


static func color_of(id: String) -> Color:
	return DATA[id]["color"] if DATA.has(id) else Color.WHITE


static func trigger_of(id: String) -> String:
	return DATA[id]["trigger"] if DATA.has(id) else ""


static func _scaled(pair: Array, level: int) -> float:
	return pair[0] + pair[1] * (clampi(level, 1, MAX_LEVEL) - 1)


## Szansa zadziałania na danym poziomie (0-1).
static func chance(id: String, level := 1) -> float:
	return minf(_scaled(DATA[id]["chance"], level), 1.0) if DATA.has(id) else 0.0


## Siła efektu na danym poziomie.
static func power(id: String, level := 1) -> float:
	return _scaled(DATA[id]["power"], level) if DATA.has(id) else 0.0


## Serce Głębin: odstęp drżenia ziemi na danym poziomie.
static func tremor_every(level := 1) -> float:
	return TREMOR_EVERY - TREMOR_STEP * (clampi(level, 1, MAX_LEVEL) - 1)


## Kryształ Peruna: o tyle droższe umiejętności (ułamek).
static func archmage_cost(level := 1) -> float:
	return ARCHMAGE_COST - ARCHMAGE_COST_STEP * (clampi(level, 1, MAX_LEVEL) - 1)


## Gałąź Leszego: czas oplątania.
static func roots_time(level := 1) -> float:
	return ROOTS_TIME + ROOTS_TIME_STEP * (clampi(level, 1, MAX_LEVEL) - 1)


## Opis działania na danym poziomie (zakładka „Talizmany”).
static func effect_text(id: String, level := 1) -> String:
	var c := roundi(chance(id, level) * 100)
	var p := power(id, level)
	match id:
		"shockwave":
			return Lang.t("%d%% szans przy trafieniu: fala uderzeniowa wokół wroga - %d%% obrażeń broni i ogłuszenie") % [c, roundi(p * 100)]
		"thunder":
			return Lang.t("%d%% szans przy trafieniu: piorun z nieba - %d%% obrażeń broni, przeskakuje na 2 wrogów") % [c, roundi(p * 100)]
		"whirlpool":
			return Lang.t("%d%% szans przy trafieniu: wir wciąga wrogów i rani 4 razy po %d%% obrażeń broni") % [c, roundi(p * 100)]
		"roots":
			return Lang.t("%d%% szans przy trafieniu: korzenie - %d%% obrażeń broni i oplątanie na %s s") % [c, roundi(p * 100),
					Auras.decimal(roots_time(level))]
		"thorns":
			return Lang.t("%d%% szans, gdy ktoś cię zrani: ciernie wokół ciebie - %d%% obrażeń broni") % [c, roundi(p * 100)]
		"bloodlust":
			return Lang.t("%d%% szans przy pokonaniu wroga: +%s%% obrażeń na %d s (do %d razy)") % [c, Auras.decimal(p * 100),
					roundi(BLOODLUST_TIME), BLOODLUST_STACKS]
		"kaboom":
			return Lang.t("%d%% szans: pokonany wróg wybucha - %d%% obrażeń broni") % [c, roundi(p * 100)]
		"devour":
			return Lang.t("%d%% szans: pokonany wróg leczy o %s%% zdrowia") % [c, Auras.decimal(p * 100)]
		"tremor":
			return Lang.t("Co %s s drży ziemia wokół ciebie - %d%% obrażeń broni") % [Auras.decimal(tremor_every(level)),
					roundi(p * 100)]
		"archmage":
			return Lang.t("Każda umiejętność ciska piorun: %d%% many jako obrażenia; umiejętności kosztują %d%% więcej many") % [
					roundi(p * 100), roundi(archmage_cost(level) * 100)]
		"overload":
			return Lang.t("Trafienie krytyczne: +%d%% obrażeń od żywiołów na %d s") % [roundi(p * 100), roundi(OVERLOAD_TIME)]
		"cull":
			return Lang.t("Trafiony wróg poniżej %s%% zdrowia ginie (elity i bossowie - poniżej połowy tego)") % Auras.decimal(p * 100)
		"onslaught":
			return Lang.t("%d%% szans przy pokonaniu wroga: +%d%% szybkości ruchu i ataku na %d s") % [c, roundi(p * 100),
					roundi(ONSLAUGHT_TIME)]
		"arcane":
			return Lang.t("Po wydaniu %d many: +%d%% obrażeń i +%d%% odnowy many na %d s") % [ARCANE_MANA, roundi(p * 100),
					roundi(ARCANE_REGEN * 100), roundi(ARCANE_TIME)]
		"pyre":
			return Lang.t("Płonący wróg, który zginie, podpala sąsiadów (%d%% obrażeń broni)") % roundi(p * 100)
		"blood_magic":
			return Lang.t("Umiejętności kosztują zdrowie zamiast many (%d%% kosztu) - cała mana na aury") % roundi(p * 100)
		"mom":
			return Lang.t("%d%% obrażeń, które dostajesz, bierze mana") % roundi(p * 100)
		"avatar":
			return Lang.t("Obrażenia fizyczne zamieniają się w ogień i są o %d%% większe") % roundi(p * 100)
		"point_blank":
			return Lang.t("Wrogowie blisko ciebie dostają +%d%% obrażeń, daleko - o połowę tego mniej") % roundi(p * 100)
		"pain":
			return Lang.t("Poniżej połowy zdrowia: +%d%% obrażeń") % roundi(p * 100)
	return ""


## Talizman ze skrzyni na mapie lochu ("" - nic); `luck` - mnożnik łupu lochu.
static func roll_chest(level: int, luck := 1.0) -> String:
	if level < MIN_LEVEL or randf() >= CHEST_CHANCE * luck:
		return ""
	return roll()


## Losowy talizman.
static func roll() -> String:
	return ORDER[randi() % ORDER.size()]

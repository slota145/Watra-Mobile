class_name Weapons
## Rodzaje broni i mistrzostwo broni (ustalone z autorem 13.11.2026). Gracz używa jednej broni naraz (zmiana w bazie);
## każda ma własne umiejętności (Skills, pole "weapon") i własne mistrzostwo. Mistrzostwo rośnie od potworów pokonanych
## tą bronią i od bossów (tyle samo co doświadczenie postaci - arena.gd `_gain_xp`) i odblokowuje kolejne umiejętności
## (próg w Skills, pole "mastery") oraz pozwala ulepszać je wyżej (Skills.level_cap). Stan: `Game.weapon`,
## `Game.mastery` (broń -> poziom), `Game.mastery_xp` (broń -> doświadczenie na tym poziomie).
## Nowe rodzaje broni (łuk, hydrosfera, mroczna kosa…) odblokowuje postęp: pokonanie Wodza na poziomie `unlock`
## (za darmo), a wcześniej odblokowuje je Pieczęć Oręża (Gems.WEAPON_SEAL, decyzja autora 20.11.2026; do tego dnia
## kupno za złoto). Zmiana broni w oknie umiejętności przy kamieniu run (Game.set_weapon, Game.unseal_weapon). Węzeł broni w lochu: miecz - ProtoWeapon,
## glewia ognia - ProtoGlaive, hydrosfera - ProtoHydrosphere, elektryczna katana - ProtoKatana (`make`).

const SWORD := "sword"
const GLAIVE := "glaive"
const HYDROSPHERE := "hydrosphere"
const KATANA := "katana"
const BOW := "bow"
const BOOK := "book"
const SCYTHE := "scythe"
const HAMMER := "hammer"
const RAPIER := "rapier"
const STAFF := "staff"
## name - nazwa, element - żywioł obrażeń (Elements), unlock - poziom lochu, po którego przebiciu broń jest za darmo,
## start - do wyboru przy tworzeniu postaci (START; decyzja autora 21.11.2026: miecz, łuk albo księga, dwie niewybrane
## od lochu 5 - Game.start_weapon), magic - broń magiczna (premia obrażeń magicznych, szybkość rzucania czarów).
const DATA := {
	"sword": {"name": "Miecz", "element": Elements.PHYSICAL, "unlock": 5, "start": true,
		"icon": preload("res://assets/watra/iron_sword_icon.png")},
	"glaive": {"name": "Glewia ognia", "short": "Glewia", "element": Elements.FIRE, "unlock": 10,
		"icon": preload("res://assets/skills/glaive/g_thrust.png")},
	"hydrosphere": {"name": "Hydrosfera", "short": "Hydro", "element": Elements.WATER, "unlock": 15, "magic": true,
		"icon": preload("res://assets/skills/hydro/h_bolt.png")},
	"katana": {"name": "Elektryczna katana", "short": "Katana", "element": Elements.LIGHTNING, "unlock": 20,
		"icon": preload("res://assets/skills/katana/k_slash.png")},
	# łuk (ustalone z autorem 20.11.2026): żywioł powietrze, loch 5 - pierwsza broń po mieczu
	"bow": {"name": "Łuk", "element": Elements.AIR, "unlock": 5, "start": true,
		"icon": preload("res://assets/skills/bow/b_shot.png")},
	# Księga Arkanów (ankieta z autorem 21.11.2026): broń magiczna, żywioł Arkana, do wyboru na start
	"book": {"name": "Księga Arkanów", "short": "Księga", "element": Elements.ARCANE, "unlock": 5, "start": true,
		"magic": true, "icon": preload("res://assets/skills/book/a_missiles.png")},
	# mroczna kosa (ustalone z autorem 21.11.2026): żywioł Nawia, za darmo od lochu 25
	"scythe": {"name": "Mroczna kosa", "short": "Kosa", "element": Elements.NAWIA, "unlock": 25,
		"icon": preload("res://assets/skills/scythe/s_reap.png")},
	# młot - broń ziemi (ustalone z autorem 21.11.2026): ogłusza i odpycha, za darmo od lochu 30 (po pierwszym kręgu)
	"hammer": {"name": "Młot", "element": Elements.EARTH, "unlock": 30,
		"icon": preload("res://assets/skills/hammer/m_smash.png")},
	# lodowy rapier - pierwsza broń lodu (ustalone z autorem 25.11.2026): spowalnia, zamraża i roztrzaskuje, od lochu 35
	"rapier": {"name": "Lodowy rapier", "short": "Rapier", "element": Elements.COLD, "unlock": 35,
		"icon": preload("res://assets/skills/rapier/r_thrust.png")},
	# Kostur Leszego - pierwsza broń natury, magiczna (pomysły autora 25.11.2026): truje, sadzonki, drzewce; od lochu 40
	"staff": {"name": "Kostur Leszego", "short": "Kostur", "element": Elements.NATURE, "unlock": 40, "magic": true,
		"icon": preload("res://assets/skills/staff/l_roots.png")},
}
const ORDER := ["sword", "bow", "book", "glaive", "hydrosphere", "katana", "scythe", "hammer", "rapier", "staff"]
## Bronie do wyboru przy tworzeniu postaci.
const START: Array[String] = ["sword", "bow", "book"]
## Najwyższy poziom mistrzostwa (jak poziom postaci).
const MAX_MASTERY := 50


static func has(id: String) -> bool:
	return DATA.has(id)


## Czy broń magiczna (premia obrażeń magicznych, szybkość rzucania czarów zamiast szybkości ataku).
static func is_magic(id: String) -> bool:
	return DATA.get(id, {}).get("magic", false)


static func name_of(id: String) -> String:
	return Lang.t(DATA[id].name) if DATA.has(id) else ""


static func element_of(id: String) -> String:
	return DATA[id].element if DATA.has(id) else Elements.PHYSICAL


## Czy broń jest dostępna bez kupowania przy danym najwyższym przebitym poziomie lochu.
static func unlocked_by(id: String, best_level: int) -> bool:
	return DATA.has(id) and best_level >= int(DATA[id].unlock)


## Krótka nazwa (przycisk broni w oknie umiejętności).
static func short_name_of(id: String) -> String:
	return Lang.t(DATA[id].get("short", DATA[id].name)) if DATA.has(id) else ""


static func icon_of(id: String) -> Texture2D:
	return DATA[id].icon if DATA.has(id) else null


## Poziom lochu, po którego przebiciu broń jest za darmo.
static func unlock_level(id: String) -> int:
	return DATA[id].unlock if DATA.has(id) else 0


## Skrypt węzła broni do walki (miecz - ProtoWeapon, glewia - ProtoGlaive, hydrosfera - ProtoHydrosphere,
## katana - ProtoKatana).
static func script_of(id: String) -> Script:
	match id:
		GLAIVE:
			return ProtoGlaive
		HYDROSPHERE:
			return ProtoHydrosphere
		KATANA:
			return ProtoKatana
		BOW:
			return ProtoBow
		BOOK:
			return ProtoBook
		SCYTHE:
			return ProtoScythe
		HAMMER:
			return ProtoHammer
		RAPIER:
			return ProtoRapier
		STAFF:
			return ProtoStaff
	return ProtoWeapon


## Nowy węzeł broni do walki.
static func make(id: String) -> ProtoWeapon:
	return script_of(id).new()


## Doświadczenie mistrzostwa potrzebne do następnego poziomu (ta sama krzywa co poziomy postaci).
static func xp_to_next(level: int) -> int:
	return HeroLevels.xp_to_next(level)

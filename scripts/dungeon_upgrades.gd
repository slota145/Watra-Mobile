class_name DungeonUpgrades
## Ulepszenia lochów za złoto (ustalone z autorem 12.11.2026; do 13.11.2026 za żar z Watry - żar idzie teraz na
## ulepszanie umiejętności): wspólne dla wszystkich lochów, każde ma
## MAX_STEPS stopni z rosnącą ceną (PRICES). Kupione stopnie trzyma i zapisuje `Game.upgrades` (identyfikator -> stopień),
## kupuje `Game.buy_upgrade`, okno - `scripts/ui/upgrades_window.gd` (przycisk w wyborze poziomu przy Watrze).
## Działanie w lochu (arena.gd): "monsters" - gęstszy strumień goblinów (ProtoHorde.density), "xp" - więcej doświadczenia,
## "loot" - większa szansa na przedmioty i kamienie z goblinów i skrzyni Wodza, "reach" - iskry i łup przyciągają się
## z dalszej odległości (ProtoEmber.magnet, ProtoLoot.magnet).

const ORDER := ["monsters", "xp", "loot", "reach"]
## Ceny kolejnych stopni (złoto; liczby jak dawne ceny w żarze - do oceny na telefonie).
const PRICES := [50, 120, 250, 500, 1000]
const MAX_STEPS := 5
## Nazwa, wzór opisu (z liczbą), przyrost na stopień, ikona.
const DATA := {
	"monsters": {"name": "Gęstsza Horda", "text": "+%d%% potworów", "step": 10.0,
			"icon": "res://assets/watra/base/goblin_heart.png"},
	"xp": {"name": "Nauka z walki", "text": "+%d%% doświadczenia", "step": 8.0,
			"icon": "res://assets/watra/base/bless_wisdom.png"},
	"loot": {"name": "Hojność Watry", "text": "+%d%% szansy na łup", "step": 10.0,
			"icon": "res://assets/watra/base/bag.png"},
	"reach": {"name": "Długie ręce", "text": "+%d px zasięgu zbierania", "step": 8.0,
			"icon": "res://assets/watra/base/node_lightness.png"},
}


static func has(id: String) -> bool:
	return DATA.has(id)


## Cena następnego stopnia (0 - wszystkie kupione).
static func price(steps: int) -> int:
	return PRICES[steps] if steps >= 0 and steps < MAX_STEPS else 0


## Premia ulepszenia przy danym stopniu (procenty albo piksele - jak w opisie).
static func bonus(id: String, steps: int) -> float:
	return DATA[id].step * clampi(steps, 0, MAX_STEPS) if DATA.has(id) else 0.0


static func name_of(id: String) -> String:
	return Lang.t(DATA[id].name)


## Opis premii przy danym stopniu („+20% potworów”).
static func text(id: String, steps: int) -> String:
	return Lang.t(DATA[id].text) % roundi(bonus(id, steps))


static func icon_of(id: String) -> Texture2D:
	return load(DATA[id].icon)

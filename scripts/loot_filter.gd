class_name LootFilter
## Filtr łupu (pomysł autora i ankieta 21.11.2026): przedmiot podniesiony w lochu, którego filtr nie chce, od razu
## rozbija się na rudę (ProtoLoot, małe przygaszone powiadomienie, podsumowanie na koniec wyprawy). Ustawienia trzyma
## zapis postaci (`Game.loot_filter`, różne postacie mają różne bronie), okno - `scripts/ui/loot_filter_window.gd`
## (z pauzy i z torby okna „Postać”), w torbie znaczek ognia przy przedmiotach, które filtr by rozbił (`burns`).
## Kolejność decyzji (`verdict`):
## 1. filtr wyłączony, legenda albo unikat - zostaje (rozbijane są tylko zwykłe, magiczne i rzadkie);
## 2. bezpiecznik: premia ponad widełki, 2 gniazda - zostaje (każde osobno do wyłączenia);
## 3. lepszy od założonego (strzałka „lepszy” - Items.is_upgrade) - zostaje (do wyłączenia);
## 4. rzadkość nie jest zaznaczona do rozbijania w ustawieniach miejsca - zostaje;
## 5. co najmniej `count` premii z listy w progu stopnia (`tier`: T1 najlepszy, T7 - każdy stopień) - zostaje;
##    pusta lista (i wyłączony Automat) - liczy się każda premia;
## 6. reszta się rozbija.
## Ustawienia miejsc: "all" - wspólne, a każde miejsce (Items.SLOTS) może mieć własne (`own`), inaczej bierze wspólne.
## Automat (`auto`): dorzuca do listy premie pasujące do broni w ręku i założonych umiejętności (`auto_stats`, znaczniki
## Skills.TAGS) i premie ogólne; próg „Auto” (tier 0) bierze z głębokości lochu (`auto_tier`). Ręcznie zaznaczone premie
## i bezpiecznik zawsze wygrywają (Automat tylko dokłada premie do listy).

## Rzadkości, które filtr może rozbijać.
const RARITIES := ["common", "magic", "rare"]
## Próg „Auto” (tylko z Automatem; bez niego liczy się jak T7).
const AUTO_TIER := 0
## Automat: próg o tyle stopni słabszy od najlepszego dostępnego na tym poziomie lochu (loch 40: T1 -> próg T3).
const AUTO_TIER_SLACK := 2
## Ile premii z listy najwyżej (rzadki ma do 5).
const MAX_COUNT := 5
## Premie ogólne Automatu (każda postać ich chce).
const AUTO_GENERAL := ["hp", "damage_pct", "element_res_pct", "protection_pct", "skill_level_all"]
## Grupy premii w oknie filtra (kolejność wierszy).
const GROUPS := [
	["Obrażenia", ["damage_pct", "elem_dmg_pct", "magic_dmg_pct", "melee_dmg_pct", "proj_dmg_pct", "area_dmg_pct",
			"minion_dmg_pct", "crit_pct", "crit_dmg_pct", "pen_pct", "elite_dmg_pct", "afflicted_dmg_pct", "full_hp_dmg_pct"]],
	["Obrona", ["hp", "regen", "life_on_kill", "protection_pct", "element_res_pct", "dodge_pct"]],
	["Szybkość", ["attack_speed_pct", "cast_speed_pct", "move_pct", "proj_speed_pct", "kill_haste_pct", "cdr_pct"]],
	["Umiejętności i mana", ["skill_level", "skill_level_all", "area_pct", "duration_pct", "mana", "mana_regen",
			"mana_on_kill", "reserve_pct"]],
	["Łup i inne", ["rarity_pct", "quantity_pct", "ore_pct", "xp_pct", "ember_pct", "pickup_pct"]],
]
## Krótkie nazwy premii w oknie filtra (bez liczb).
const STAT_NAMES := {
	"damage_pct": "% obrażeń", "elem_dmg_pct": "% obrażeń od żywiołów", "magic_dmg_pct": "% obrażeń magicznych",
	"melee_dmg_pct": "% obrażeń wręcz", "proj_dmg_pct": "% obrażeń pocisków", "area_dmg_pct": "% obrażeń obszarowych",
	"minion_dmg_pct": "% obrażeń przywołańców", "crit_pct": "Szansa na trafienie krytyczne",
	"crit_dmg_pct": "% obrażeń krytycznych", "pen_pct": "Przebicie odporności", "elite_dmg_pct": "Obrażenia przeciw elitom",
	"afflicted_dmg_pct": "Obrażenia przeciw osłabionym", "full_hp_dmg_pct": "Obrażenia przeciw zdrowym",
	"hp": "Zdrowie", "regen": "Zdrowie na sekundę", "life_on_kill": "Zdrowie za zabicie", "protection_pct": "Ochrona",
	"element_res_pct": "Odporność na żywioły", "dodge_pct": "Unik", "attack_speed_pct": "Szybkość ataku",
	"cast_speed_pct": "Szybkość rzucania czarów", "move_pct": "Szybkość ruchu", "proj_speed_pct": "Szybkość pocisków",
	"kill_haste_pct": "Szybkość po zabiciu", "cdr_pct": "Krótsze odnowienie", "skill_level": "Poziom umiejętności",
	"skill_level_all": "Poziom wszystkich umiejętności", "area_pct": "Obszar umiejętności",
	"duration_pct": "Czas działania umiejętności", "mana": "Mana", "mana_regen": "Mana na sekundę",
	"mana_on_kill": "Mana za zabicie", "reserve_pct": "Mniejsza rezerwacja many", "rarity_pct": "Rzadkość łupu",
	"quantity_pct": "Ilość łupu", "ore_pct": "Ruda z rozbijania", "xp_pct": "Doświadczenie", "ember_pct": "Żar",
	"pickup_pct": "Zasięg zbierania",
}


## Domyślne ustawienia filtra (wyłączony; po włączeniu rozbija zwykłe).
static func defaults() -> Dictionary:
	var slots := {"all": default_rules()}
	for slot in Items.SLOTS:
		var r := default_rules()
		r["own"] = false
		slots[slot] = r
	return {"on": false, "auto": false, "upgrade": true, "safe_above": true, "safe_sockets": true, "slots": slots}


## Domyślne zasady jednego miejsca.
static func default_rules() -> Dictionary:
	return {"rarities": ["common"], "tier": AUTO_TIER, "count": 1, "stats": []}


## Ustawienia z zapisu poprawione do znanych wartości (brakujące - domyślne, nieznane premie odrzucone).
static func normalize(raw) -> Dictionary:
	var f := defaults()
	if not raw is Dictionary:
		return f
	for key in ["on", "auto", "upgrade", "safe_above", "safe_sockets"]:
		if raw.has(key):
			f[key] = bool(raw[key])
	var raw_slots = raw.get("slots", {})
	if raw_slots is Dictionary:
		for key in f.slots:
			var r = raw_slots.get(key, null)
			if r is Dictionary:
				f.slots[key] = _normalize_rules(r, key != "all")
	return f


static func _normalize_rules(r: Dictionary, has_own: bool) -> Dictionary:
	var out := default_rules()
	var rar: Array = []
	for x in r.get("rarities", []):
		if x in RARITIES and not rar.has(x):
			rar.append(x)
	out.rarities = rar
	out.tier = clampi(int(r.get("tier", AUTO_TIER)), AUTO_TIER, Items.TIERS)
	out.count = clampi(int(r.get("count", 1)), 1, MAX_COUNT)
	var stats: Array = []
	for s in r.get("stats", []):
		if Items.AFFIXES.has(s) and not stats.has(s):
			stats.append(s)
	out.stats = stats
	if has_own:
		out["own"] = bool(r.get("own", false))
	return out


## Zasady działające dla miejsca `slot` (własne albo wspólne).
static func rules_for(filter: Dictionary, slot: String) -> Dictionary:
	var r: Dictionary = filter.slots.get(slot, {})
	return r if r.get("own", false) else filter.slots.all


## Próg Automatu z głębokości lochu: najlepszy dostępny stopień + AUTO_TIER_SLACK (płytko - T7, czyli każdy).
static func auto_tier(level: int) -> int:
	return mini(Items.TIERS, Items.best_tier(level) + AUTO_TIER_SLACK)


## Próg stopnia, który naprawdę działa (Auto bez Automatu - każdy stopień).
static func effective_tier(filter: Dictionary, rules: Dictionary, level: int) -> int:
	var t := int(rules.get("tier", AUTO_TIER))
	if t == AUTO_TIER:
		return auto_tier(level) if filter.get("auto", false) else Items.TIERS
	return t


## Premie, które Automat dorzuca do listy: ogólne, od broni (magiczna - obrażenia magiczne i szybkość rzucania,
## reszta - szybkość ataku; broń żywiołu - obrażenia od żywiołów) i od znaczników założonych umiejętności.
static func auto_stats(weapon: String, skills: Array) -> Array:
	var out: Array = AUTO_GENERAL.duplicate()
	if Weapons.is_magic(weapon):
		out.append_array(["magic_dmg_pct", "cast_speed_pct"])
	else:
		out.append("attack_speed_pct")
	if Weapons.DATA.get(weapon, {}).get("element", Elements.PHYSICAL) != Elements.PHYSICAL:
		out.append("elem_dmg_pct")
	for id in skills:
		if str(id) == "":
			continue
		for tag in Skills.tags_of(str(id)):
			var stat: String = Skills.TAG_STATS.get(tag, "")
			if stat != "" and not out.has(stat):
				out.append(stat)
			var extra: String = {"projectile": "proj_speed_pct", "area": "area_pct", "minion": "duration_pct"}.get(tag, "")
			if extra != "" and not out.has(extra):
				out.append(extra)
	return out


## Czy premia `a` liczy się do listy: ręcznie zaznaczona, albo z Automatu (poziom umiejętności - tylko założonej).
static func _listed(a: Dictionary, stats: Array, auto: Array, skills: Array) -> bool:
	var stat: String = a.get("stat", "")
	if stats.has(stat):
		return true
	if stat == "skill_level" and not auto.is_empty():
		return skills.has(a.get("skill", ""))
	return auto.has(stat)


## Decyzja filtra: "" - przedmiot zostaje, inaczej powód rozbicia ("rarity" nie występuje - rzadkość chroni).
## `ctx`: {"weapon", "skills" - założone umiejętności, "level" - poziom lochu, "equipped" - założone przedmioty}.
static func verdict(filter: Dictionary, item: Dictionary, ctx: Dictionary) -> String:
	if not filter.get("on", false) or item.is_empty() or not item.has("rarity"):
		return ""
	if not item.rarity in RARITIES or Items.is_unique(item):
		return ""
	if filter.get("safe_above", true) and Items.has_above(item):
		return ""
	if filter.get("safe_sockets", true) and item.get("sockets", []).size() >= Items.MAX_SOCKETS:
		return ""
	var slot: String = item.get("slot", "")
	if filter.get("upgrade", true) and Items.is_upgrade(item, ctx.get("equipped", {}).get(slot, {})):
		return ""
	var rules := rules_for(filter, slot)
	if not item.rarity in rules.rarities:
		return ""
	var skills: Array = ctx.get("skills", [])
	var auto: Array = auto_stats(ctx.get("weapon", Weapons.SWORD), skills) if filter.get("auto", false) else []
	var tier := effective_tier(filter, rules, int(ctx.get("level", 1)))
	var any: bool = rules.stats.is_empty() and auto.is_empty()
	var count := 0
	for a in item.get("affixes", []):
		if int(a.get("tier", Items.TIERS)) <= tier and (any or _listed(a, rules.stats, auto, skills)):
			count += 1
	return "" if count >= int(rules.count) else "burn"


## Stan gry potrzebny filtrowi (Game - autoload przekazany z węzła, bo w class_name nazwa autoloadu bywa nieznana).
static func context(game: Node) -> Dictionary:
	return {"weapon": game.weapon, "skills": game.skill_slots, "level": game.dungeon_level, "equipped": game.equipped}


## Czy filtr z ustawień gry rozbiłby ten przedmiot (podniesienie w lochu, znaczek ognia w torbie).
static func burns(game: Node, item: Dictionary) -> bool:
	return verdict(game.loot_filter, item, context(game)) != ""


## Nazwa premii w oknie filtra.
static func stat_name(stat: String) -> String:
	return Lang.t(STAT_NAMES.get(stat, stat))

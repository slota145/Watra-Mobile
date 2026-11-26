class_name DeepRuns
extends RefCounted
## Zestawy Głębin - krok 2 (ustalone z autorem 26.11.2026): każda Głębia ma wylosowany zawczasu zestaw, widoczny przy
## wyborze Głębi (Czarna Watra) - tło (podłoga i ozdoby lochu), potwory na każdej roli z innego lochu (zwykły,
## strzelający, silny), losowy boss spośród wszystkich bossów lochów, jedna losowa mechanika lochu (MECHANICS), losowe
## modyfikatory (DungeonMods.roll_deep) i losowa para odporności (jeden żywioł +RESIST, inny -RESIST). Zestaw można
## przelosować za żar (`reroll_cost` - rośnie z Głębią). Po wejściu zestaw się zużywa i na następny raz losuje się nowy
## (Game.deep_roll / take_deep_roll). Zestaw to słownik (zapisywany w grze): level, ground, goblin, archer, brute, boss,
## mechanic, mods, up, down.

## Lochy z mechaniką (arena tworzy ją według `mechanic` zestawu): wiatr i trąby, wymarzanie, Żywa puszcza, Promienie
## słońca, Osuwiska, Magiczne pieczęcie.
const MECHANICS: Array[String] = [Dungeons.SKY, Dungeons.FROST, Dungeons.FOREST, Dungeons.TEMPLE, Dungeons.MINE,
		Dungeons.TOWER]
## Nazwy mechanik do opisu zestawu.
const MECHANIC_NAMES := {Dungeons.SKY: "Wiatr i trąby powietrzne", Dungeons.FROST: "Wymarzanie (koksowniki grzeją)",
		Dungeons.FOREST: "Żywa puszcza (korzenie)", Dungeons.TEMPLE: "Promienie słońca (cień kolumn chroni)",
		Dungeons.MINE: "Osuwiska (głazy ze stropu)", Dungeons.TOWER: "Magiczne pieczęcie"}
## Role potworów strumienia (ProtoHorde) w zestawie.
const ROLES: Array[String] = ["goblin", "archer", "brute"]
## Charakter odporności Głębi: jeden żywioł bardziej, inny mniej.
const RESIST := 0.2
## Przelosowanie: koszt w żarze = REROLL_BASE + REROLL_STEP za każdą Głębię.
const REROLL_BASE := 50
const REROLL_STEP := 10


## Nowy losowy zestaw dla poziomu `level` (Głębia).
static func roll(level: int) -> Dictionary:
	var dungeons := Dungeons.ORDER.duplicate()
	dungeons.shuffle()
	var elements := Elements.ALL.duplicate()
	elements.shuffle()
	return {"level": level, "ground": Dungeons.ORDER.pick_random(), "goblin": dungeons[0], "archer": dungeons[1],
			"brute": dungeons[2], "boss": Dungeons.ORDER.pick_random(), "mechanic": MECHANICS.pick_random(),
			"mods": DungeonMods.roll_deep(level), "up": elements[0], "down": elements[1]}


## Czy słownik to poprawny zestaw (stary albo zepsuty zapis - nie).
static func valid(r: Dictionary) -> bool:
	for key in ["ground", "goblin", "archer", "brute", "boss"]:
		if not Dungeons.ORDER.has(str(r.get(key, ""))):
			return false
	return MECHANICS.has(str(r.get("mechanic", ""))) and Elements.ALL.has(str(r.get("up", ""))) \
			and Elements.ALL.has(str(r.get("down", ""))) and r.get("mods") is Array


## Zestaw po wczytaniu z zapisu (JSON): liczby całkowite i lista modyfikatorów jak przy losowaniu.
static func normalize(r: Dictionary) -> Dictionary:
	var out := r.duplicate()
	out.level = int(r.get("level", 0))
	var mods: Array[String] = []
	for m in r.get("mods", []):
		if DungeonMods.DATA.has(str(m)):
			mods.append(str(m))
	out.mods = mods
	return out


## Koszt przelosowania zestawu Głębi na poziomie `level`.
static func reroll_cost(level: int) -> int:
	return REROLL_BASE + REROLL_STEP * Dungeons.deep_of(level)


## Odporności potworów Głębi: wspólna z głębi i para zestawu (+RESIST / -RESIST).
static func resists(r: Dictionary, level: int) -> Dictionary:
	var base := DungeonLevels.base_resist(level)
	var out := {}
	for e in Elements.ALL + [Elements.PHYSICAL]:
		out[e] = base
	out[r.up] = base + RESIST
	out[r.down] = base - RESIST
	return out


## Loch, z którego pochodzi potwór roli `kind` (inne rodzaje - np. sługi bossa - z lochu bossa).
static func climate_for(r: Dictionary, kind: String) -> String:
	return str(r[kind]) if ROLES.has(kind) else str(r.boss)


## Opis zestawu do wyboru Głębi (kolejne wiersze).
static func describe(r: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append(Lang.t("Tło: %s") % Dungeons.name_of(r.ground))
	lines.append(Lang.t("Potwory: %s, %s, %s") % [Dungeons.name_of(r.goblin), Dungeons.name_of(r.archer),
			Dungeons.name_of(r.brute)])
	lines.append(Lang.t("Boss: %s") % Dungeons.boss_of(r.boss))
	lines.append(Lang.t("Mechanika: %s") % Lang.t(MECHANIC_NAMES[r.mechanic]))
	if not (r.mods as Array).is_empty():
		lines.append(Lang.t("Modyfikatory: %s") % DungeonMods.names(r.mods))
	lines.append(Lang.t("Bardziej: %s +%d%% · Mniej: %s -%d%%") % [Elements.name_of(r.up), roundi(RESIST * 100),
			Elements.name_of(r.down), roundi(RESIST * 100)])
	return lines

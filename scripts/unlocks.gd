class_name Unlocks
extends RefCounted
## Drabinka odblokowań (pomysł z Dwarven Realms, decyzje autora 16.11.2026): jedna lista wszystkiego, co gra odkrywa
## z głębokością lochu - tylko POKAZUJE progi, które już są w kodzie (nic nowego nie blokuje). Liczby bierze ze
## stałych systemów (DungeonLevels, Elites, Gems, DungeonGoals, Dungeons, Weapons), więc zmiana progu tam zmienia
## też drabinkę. Każdy wpis: `beat` - który poziom trzeba przebić (Game.best_level), `level` - na którym poziomie
## lochu to widać (beat + 1; bronie i zakładki skrzyni - po przebiciu), `text`, `kind` (monster, loot, goal, dungeon,
## weapon, stash).
## Pokazują ją: wybór poziomu przy Watrze (nowość na tym poziomie i następne odblokowanie, przycisk „Drabinka”
## - okno UnlocksWindow), okno zwycięstwa (co właśnie odblokowano) i kropka „Nowość!” nad Watrą
## (Game.unlocks_seen < Game.best_level i jest coś nowego).

## Ikona wpisu wg rodzaju (cele na mapie - własna grafika celu, bronie - ikona broni).
const ICONS := {"monster": preload("res://assets/watra/base/goblin_heart.png"), "loot": preload("res://assets/watra/gems/emerald_3.png"),
		"dungeon": preload("res://assets/watra/base/status_watra.png")}
const GOAL_ICONS := {"chest": preload("res://assets/watra/chest.png"), "shrine": preload("res://assets/watra/shrine.png"),
		"skarbnik": preload("res://assets/watra/skarbnik.png"), "zertwa": preload("res://assets/watra/zertwa_stump.png"),
		"crystal": preload("res://assets/watra/watra_crystal.png"), "raid": preload("res://assets/watra/raid_cart.png")}
const KINDS_COLOR := {"monster": Color(1.0, 0.55, 0.45), "loot": Color(0.6, 0.85, 1.0), "goal": Color(1.0, 0.85, 0.4),
		"dungeon": Color(0.75, 1.0, 0.6), "weapon": Color(1.0, 0.7, 0.35), "stash": Color(0.95, 0.8, 0.55)}


## Wszystkie wpisy, posortowane po `beat`.
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_add(out, Elites.FROM_LEVEL, "monster", "Elitarne potwory z cechami")
	_add(out, DungeonLevels.ARCHER_FROM, "monster", "Potwory strzelające z dystansu")
	_add(out, DungeonLevels.BRUTE_FROM, "monster", "Silne potwory z ciosem w koło")
	_add(out, Gems.MIN_LEVEL, "loot", "Kamienie do umiejętności i przedmiotów")
	_add(out, Elites.TWO_TRAITS_FROM, "monster", "Elity z dwiema cechami")
	_add(out, Gems.UNIQUE_MIN_LEVEL, "loot", "Kamienie unikalne umiejętności ze skrzyni bossa")
	_add(out, Elites.THREE_TRAITS_FROM, "monster", "Elity z trzema cechami")
	var goals := {"chest": "Cel na mapie: skrzynia", "shrine": "Cel na mapie: kapliczka z darem bóstwa",
			"skarbnik": "Cel na mapie: Skarbnik", "zertwa": "Cel na mapie: Krąg Żertwy",
			"crystal": "Cel na mapie: Kryształ Watry", "raid": "Cel na mapie: Napad Hordy (ruda żelaza)"}
	for kind: String in DungeonGoals.KINDS:
		_add(out, int(DungeonGoals.KINDS[kind]), "goal", goals.get(kind, kind), [], GOAL_ICONS.get(kind))
	for id: String in Dungeons.ORDER:
		var from := Dungeons.first_level(id)
		if from > 1:
			_add(out, from, "dungeon", "Nowy loch: %s (boss: %s)", [Dungeons.name_of(id), Dungeons.get_data(id).boss])
	_add(out, DungeonMods.FROM_LEVEL, "dungeon", "Modyfikatory lochów: trudniej, ale lepsze nagrody (przy wyborze poziomu)")
	_add(out, Dungeons.DEEP_FROM, "dungeon", "Głębiny: Czarna Watra w bazie - losowy loch i losowe modyfikatory przy każdym wejściu")
	_add(out, Pinnacles.KEY_FROM, "loot", "Boss szczytowy: klucz do Gniazda Żmija ze skrzyni bossa (rzadko)", [],
			Pinnacles.KEY_ICON)
	for id: String in Weapons.ORDER:
		var beat := Weapons.unlock_level(id)
		if beat > 0:
			out.append({"beat": beat, "level": beat + 1, "kind": "weapon", "icon": Weapons.icon_of(id),
					"text": Lang.t("Broń za darmo: %s") % Weapons.name_of(id)})
	for i in Game.STASH_TAB_LEVELS.size():  # zakładki skrzyni w bazie - za przebite lochy (od 20.11.2026, wcześniej złoto)
		var beat: int = Game.STASH_TAB_LEVELS[i]
		out.append({"beat": beat, "level": beat + 1, "kind": "stash", "icon": GOAL_ICONS.chest,
				"text": Lang.t("Zakładka skrzyni w bazie nr %d") % (i + 2)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.beat < b.beat)
	return out


## Wpis pojawiający się na poziomie lochu `level` (do przebicia: poziom wcześniej). Pomija poziom 1 (od początku).
static func _add(out: Array[Dictionary], level: int, kind: String, text: String, args: Array = [],
		icon: Texture2D = null) -> void:
	if level <= 1:
		return
	var t := Lang.t(text)
	if not args.is_empty():
		t = t % args
	out.append({"beat": level - 1, "level": level, "kind": kind, "text": t, "icon": icon if icon else ICONS.get(kind)})


## Odblokowane przez przebicie dokładnie poziomu `beat`.
static func on_beat(beat: int) -> Array:
	return all().filter(func(e: Dictionary) -> bool: return e.beat == beat)


## Nowości widoczne od poziomu lochu `level` (bez broni i zakładek skrzyni - te są w bazie).
static func new_at(level: int) -> Array:
	return all().filter(func(e: Dictionary) -> bool: return e.level == level and not e.kind in ["weapon", "stash"])


## Najbliższe odblokowania po przebiciu `best` (wszystkie wpisy z najmniejszym `beat` > best); puste - koniec drabinki.
static func next_after(best: int) -> Array:
	var later := all().filter(func(e: Dictionary) -> bool: return e.beat > best)
	if later.is_empty():
		return []
	var first: int = later[0].beat
	return later.filter(func(e: Dictionary) -> bool: return e.beat == first)


## Czy między przebitym `seen` a `best` odblokowało się coś nowego (kropka „Nowość!”).
static func has_new(seen: int, best: int) -> bool:
	for e in all():
		if e.beat > seen and e.beat <= best:
			return true
	return false

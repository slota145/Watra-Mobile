extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen, ścieżka zapisu i ustawienia gracza.
## Ustawienia (np. przyciski po lewej) leżą osobno od zapisu gry, w user://settings.cfg.
## Zapis gry (JSON w `save_path`): żar zgromadzony w Watrze (`embers`), najwyższy przebity poziom lochu (`best_level`)
## i postać - poziom i doświadczenie (`hero_level`, `hero_xp`; dane poziomów w HeroLevels), przedmioty w torbie
## (`bag`, najwyżej BAG_SIZE), założone (`equipped`: miejsce -> przedmiot) i ruda żelaza z rozbitych przedmiotów (`ore`;
## gra nie ma złota od 20.11.2026 - stare złoto przelicza się raz na runy i rudę, `_convert_gold`),
## skrzynia w bazie (`stash`: zakładki po STASH_TAB_SIZE miejsc; kolejne za przebite lochy - STASH_TAB_LEVELS),
## broń i mistrzostwo (`weapon`, `mastery` - broń -> poziom, `mastery_xp`, `weapons_bought` - kupione przed progiem,
## `weapon_slots` - miejsca umiejętności każdej broni; dane w Weapons), umiejętności
## (`skills_owned` - odblokowane, `skill_slots` - co stoi w miejscach, `skill_levels` - poziomy; dane w Skills), kamienie (Gems):
## sakwa (`gems`: identyfikator -> ile sztuk), odpryski (`shards`), kamienie w umiejętnościach (`skill_gems`: umiejętność -> lista
## Gems.SKILL_SOCKETS identyfikatorów, "" - puste) i otwarte gniazda (`skill_open`); kamienie w przedmiotach
## leżą w samych przedmiotach ("sockets"). Baza (ustalone 12.11.2026): drzewko lochów (`tree`: węzeł DungeonTree -> punkty;
## od 20.11.2026 zamiast ulepszeń lochów za złoto), kupiec (stała wymiana run - Shop, `buy_offer`) i kowal (`use_rune` - runy zmieniają premie przedmiotu; `runes`: identyfikator runy -> ile sztuk, Runes).
## Żywioły i mistrzostwo (13.11.2026): umiejętności odblokowuje mistrzostwo broni, ulepsza się je żarem, a ulepszenia
## lochów kupuje się złotem. Stary zapis (bez `mastery`) przechodzi raz (`_migrate_mastery`): mistrzostwo miecza = poziom
## postaci, kupione umiejętności i poziomy zostają, a wydane na nie złoto i żar wydany na ulepszenia lochów wracają.
## Wiele postaci (decyzje autora 16.11.2026): każda postać to osobny plik w `chars_dir` (`<id>.json`, z nazwą `char_name`,
## `ssf` i trybem deweloperskim - `dev`), bez limitu; wybór na ekranie postaci (CharacterSelect w menu), ostatnia
## w ustawieniach (`last_character`). Ustawienia sterowania wspólne (settings.cfg). Skrzynia w bazie wspólna dla
## postaci bez SSF (SHARED_STASH); postać SSF ma własną skrzynię w swoim pliku. Stary pojedynczy zapis (SAVE_PATH)
## przechodzi raz na pierwszą postać „Wojciech” (`_migrate_legacy`, razem z trybem deweloperskim z ustawień).
## Aury (19.11.2026, dane w Auras): `auras` - zdobyte aury (aura -> poziom), `auras_on` - włączone (rezerwują manę).
## Rynek (20.11.2026, dane i symulacja w Market): `market` - stan targu (ceny, oferty innych graczy, oferty gracza,
## wiadomości, czas ostatniej chwili); bez SSF; nadrabia czas `market_catch_up` (też offline, do Market.OFFLINE_MAX).
## Talizmany (19.11.2026, dane w Talismans): `talismans` - zdobyte (talizman -> poziom), `talisman_slots` - 3 miejsca.
## Testy ustawiają `save_path` na plik testowy - wtedy jedna postać w jednym pliku, skrzynia w nim (bez wspólnej).

## Zmiana doświadczenia: `xp` na obecnym poziomie, `need` - ile trzeba do awansu (0 na najwyższym poziomie).
signal xp_changed(level: int, xp: int, need: int)
## Awans postaci na poziom `level` (przy kilku awansach naraz - raz, z ostatnim poziomem).
signal leveled_up(level: int)
## Zmiana torby, założonych przedmiotów albo złota.
signal inventory_changed
## Nowa aura, wyższy poziom aury albo włączenie / wyłączenie aury.
signal auras_changed
## Nowy talizman, wyższy poziom albo zmiana w miejscach na talizmany.
signal talismans_changed
## Odblokowanie lub ulepszenie umiejętności albo zmiana miejsc umiejętności.
signal skills_changed
## Zmiana mistrzostwa obecnej broni: poziom, doświadczenie na nim i ile trzeba do następnego (0 na najwyższym).
signal mastery_changed(level: int, xp: int, need: int)
## Mistrzostwo odblokowało umiejętność (arena pokazuje napis nad postacią).
signal skill_unlocked(id: String)
## Zmiana broni w ręku (arena podmienia węzeł broni) albo kupno broni.
signal weapon_changed
## Zmiana żaru w Watrze (ulepszenie umiejętności, żar z lochu).
signal embers_changed

## Miejsca w torbie (siatka 5x4 w oknie „Postać”).
const BAG_SIZE := 20
## Skrzynia w bazie: miejsca w zakładce i ceny kolejnych zakładek (pierwsza za darmo; razem najwyżej 5).
const STASH_TAB_SIZE := 20
## Kolejne zakładki skrzyni dochodzą za darmo po przebiciu tych poziomów lochu (decyzja autora 20.11.2026).
const STASH_TAB_LEVELS := [5, 15, 30, 50]
## Przeliczenie złota ze starego zapisu (decyzja autora 20.11.2026): losowa runa (bez Pieczęci) za GOLD_PER_RUNE złota,
## najwyżej GOLD_RUNES_MAX run, reszta w rudzie - 1 za GOLD_PER_ORE złota, najwyżej GOLD_ORE_MAX.
const GOLD_PER_RUNE := 1000
const GOLD_RUNES_MAX := 20
const GOLD_PER_ORE := 100
const GOLD_ORE_MAX := 100

const MENU_SCENE := "res://scenes/main_menu.tscn"
## Stary zapis jednej postaci (sprzed wielu postaci) - przenoszony na pierwszą postać.
const SAVE_PATH := "user://savegame.json"
## Pliki postaci i wspólna skrzynia postaci bez SSF.
const CHARS_DIR := "user://characters/"
const SHARED_STASH := "user://shared_stash.json"
const DEFAULT_NAME := "Wojciech"
const SETTINGS_PATH := "user://settings.cfg"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"

## Plik zapisu obecnej postaci ("" - żadna nie wybrana, nic się nie zapisuje). Testy ustawiają osobny plik
## (nazwa z „test”) - wtedy ustawienia też idą do osobnego pliku.
var save_path := "":
	set(value):
		save_path = value
		settings_path = TEST_SETTINGS_PATH if value.contains("test") else SETTINGS_PATH
		load_settings()
		load_game()
var settings_path := SETTINGS_PATH
## Katalog plików postaci (testy - osobny) i wspólna skrzynia.
var chars_dir := CHARS_DIR
var shared_stash_path := SHARED_STASH
## Obecna postać: identyfikator (nazwa pliku; "" - zapis testowy), nazwa i czy SSF (tylko własny łup, własna skrzynia).
var character := ""
var char_name := DEFAULT_NAME
var ssf := false
## Ostatnio grana postać (w ustawieniach) - wybierana przy starcie gry.
var last_character := ""
## Stary zapis jednej postaci do przeniesienia (testy podmieniają).
var legacy_path := SAVE_PATH
## Żar zgromadzony w Watrze (z iskier zebranych w lochach i doniesionych do bazy).
var embers := 0
## Żar doniesiony z ostatniego lochu - baza pokazuje go nad Watrą i zeruje.
var embers_brought := 0
## Najwyższy poziom lochu, na którym pokonano bossa (0 - jeszcze żaden). Odblokowany jest o jeden wyższy.
var best_level := 0
## Do którego przebitego poziomu gracz widział drabinkę odblokowań (Unlocks) - kropka „Nowość!” nad Watrą.
var unlocks_seen := 0
## Włączone modyfikatory lochów (DungeonMods; działają od DungeonMods.FROM_LEVEL).
var dungeon_mods: Array = []
## Poziom lochu wybrany przy Watrze (na niego wchodzi scena lochu).
var dungeon_level := 1
## Poziom postaci i doświadczenie zebrane na tym poziomie.
var hero_level := 1
var hero_xp := 0
## Przedmioty w torbie (kolejność jak w siatce) i założone (miejsce -> przedmiot) - słowniki z Items.roll.
var bag: Array = []
var equipped := {}
## Ruda żelaza (z rozbijania przedmiotów i Skarbnika) - surowiec kowala.
var ore := 0
## Złoto ze starego zapisu i dawnych zwrotów - tylko przy wczytaniu, zaraz przeliczane na runy i rudę (`_convert_gold`).
var gold := 0
## Co dało przeliczenie złota przy tym wczytaniu: Vector2i(runy, ruda) - arena pokazuje napis w bazie i zeruje.
var gold_converted := Vector2i.ZERO
## Skrzynia w bazie: lista zakładek, każda to lista przedmiotów (najwyżej STASH_TAB_SIZE).
var stash: Array = [[]]
## Broń w ręku (Weapons) i mistrzostwo każdej broni (broń -> poziom; brak wpisu - 1. poziom) z doświadczeniem.
var weapon := Weapons.SWORD
## Broń wybrana przy tworzeniu postaci (Weapons.START) - dostępna od początku; pozostałe dwie z wyboru od lochu 5.
## Stare zapisy (bez wyboru) - miecz.
var start_weapon := Weapons.SWORD
var mastery := {}
var mastery_xp := {}
## Bronie odblokowane Pieczęcią Oręża przed progiem odblokowania i miejsca umiejętności broni, których nie ma w ręku
## (broń -> lista jak `skill_slots`; obecna broń ma swoje w `skill_slots`).
var weapons_bought: Array = []
var weapon_slots := {}
## Odblokowane umiejętności (identyfikatory ze Skills; zwykły cios zawsze) i co stoi w miejscach
## (Skills.SLOTS; 0 - duży przycisk, "" - puste miejsce).
var skills_owned: Array = [Skills.STRIKE]
var skill_slots: Array = _default_slots()
## Poziomy umiejętności (umiejętność -> poziom 2-Skills.MAX_LEVEL; brak wpisu - 1. poziom).
var skill_levels := {}
## Sakwa z kamieniami, kluczami i dłutami (identyfikator Gems -> liczba sztuk).
var gems := {}
## Odpryski z rozbitych kamieni - waluta ulepszania kamieni.
var shards := 0
## Runy (Runes, 20.11.2026 - waluta-przedmioty zamiast złota u kowala): identyfikator -> ile sztuk.
var runes := {}
## Stan targu (Market) - pusty słownik: rynek jeszcze nie otwarty (powstaje przy pierwszym nadrabianiu).
var market := {}
## Zegar rynku (sekundy); testy podmieniają go, żeby przesunąć czas.
var market_clock := func() -> float: return Time.get_unix_time_from_system()
## Kamienie w gniazdach umiejętności i liczba otwartych gniazd (brak wpisu - Gems.SKILL_OPEN).
var skill_gems := {}
var skill_open := {}
## Drzewko lochów (DungeonTree, 20.11.2026 - zamiast ulepszeń lochów za złoto): węzeł -> punkty.
var tree := {}
## Dawne ulepszenia lochów z wczytanego zapisu (tylko do zwrotu przy przejściu na drzewko).
var _old_upgrades := {}
## Ceny stopni dawnych ulepszeń lochów (złoto; od 13.11.2026, wcześniej żar) - zwrot przy przejściu na drzewko.
const OLD_UPGRADE_PRICES := [50, 120, 250, 500, 1000]
## Aury: zdobyte (aura -> poziom 1-Auras.MAX_LEVEL) i włączone.
var auras := {}
var auras_on: Array = []
## Talizmany: zdobyte (talizman -> poziom 1-Talismans.MAX_LEVEL) i założone ("" - puste miejsce).
var talismans := {}
var talisman_slots: Array = ["", "", ""]
## Doświadczenie dopisane od ostatniego zapisu (zapis przy końcu wyprawy, pauzie i przełączeniu aplikacji).
var _dirty := false
## Atak i umiejętności w lewym dolnym rogu (dla osób, które wolą trzymać je lewym kciukiem).
var left_handed := false
## Gest ręką postaci przy ataku (prototyp - porównanie wersji z gestem i bez).
var gesture := true
## Auto atak: umiejętność spod dużego przycisku (zwykle zwykły cios) rusza sama, gdy potwór jest w zasięgu.
var auto_attack := false
## Dawny przełącznik „rozbijaj zwykłe od razu” (do 21.11.2026) - czytany tylko raz, żeby ustawić filtr łupu postaci
## bez zapisanego filtra (`_read_filter`).
var auto_sell_common := false
## Filtr łupu postaci (LootFilter - ustawienia, okno LootFilterWindow); zapis postaci, bo każda postać ma inną broń.
var loot_filter := LootFilter.defaults()
## Tryb deweloperski (okno pauzy): nieśmiertelność - zdrowie schodzi, ale zamiast śmierci wraca do pełna.
var dev_immortal := false
## Tryb deweloperski: licznik klatek na sekundę i potworów naraz w lochu (sprawdzanie wydajności tłumu na telefonie).
var dev_fps := false
## Tryb deweloperski: wybór dowolnego poziomu lochu (do DEV_MAX_LEVEL) bez przebijania poprzednich.
var dev_all_levels := false
## Tryb deweloperski: statystyki ustawione suwakiem (statystyka -> wartość) zamiast sumy z przedmiotów (Items.with_overrides).
var dev_stats := {}
const DEV_MAX_LEVEL := 100


func _ready() -> void:
	# jak w Watrze: gra startuje po polsku, niezależnie od języka telefonu (wybór języka dojdzie w ustawieniach)
	Lang.set_language(Lang.DEFAULT)
	load_settings()
	_migrate_legacy()
	if last_character != "" and FileAccess.file_exists(chars_dir + last_character + ".json"):
		select_character(last_character)


## Numer wersji gry z project.godot (pokazywany w rogu menu).
func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## Przejście do innej sceny (np. z menu do gry).
func change_scene(path: String) -> void:
	save_if_dirty()  # doświadczenie z lochu (także przy ucieczce)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		cfg = ConfigFile.new()
	left_handed = cfg.get_value("controls", "left_handed", false)
	gesture = cfg.get_value("controls", "gesture", true)
	auto_attack = cfg.get_value("controls", "auto_attack", false)
	last_character = str(cfg.get_value("characters", "last", ""))
	auto_sell_common = cfg.get_value("items", "auto_sell_common", false)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "gesture", gesture)
	cfg.set_value("controls", "auto_attack", auto_attack)
	cfg.set_value("characters", "last", last_character)
	cfg.save(settings_path)
	save_game()  # tryb deweloperski leży w zapisie postaci


## Filtr łupu z zapisu postaci; bez zapisanego filtra - domyślny, a przy włączonym dawnym przełączniku
## „rozbijaj zwykłe od razu” włączony i rozbijający zwykłe (tak jak dotąd).
func _read_filter(raw) -> void:
	loot_filter = LootFilter.normalize(raw)
	if raw == null and auto_sell_common:
		loot_filter.on = true


## Tryb deweloperski postaci z zapisu (słownik `dev`).
func _read_dev(raw) -> void:
	var d: Dictionary = raw if raw is Dictionary else {}
	dev_immortal = bool(d.get("immortal", false))
	dev_all_levels = bool(d.get("all_levels", false))
	dev_fps = bool(d.get("fps", false))
	var raw_stats = d.get("stats", {})
	dev_stats = raw_stats if raw_stats is Dictionary else {}


func _dev_data() -> Dictionary:
	return {"immortal": dev_immortal, "all_levels": dev_all_levels, "fps": dev_fps, "stats": dev_stats}


## Lista postaci do ekranu wyboru: słowniki z `id`, `name`, `ssf`, `level`, `best_level`, `weapon`, `dev` (czy włączony
## tryb deweloperski), `created`; od najstarszej.
func list_characters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(chars_dir)
	if dir == null:
		return out
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(chars_dir + file))
		if not data is Dictionary:
			continue
		var dev: Dictionary = data.get("dev", {}) if data.get("dev", {}) is Dictionary else {}
		out.append({"id": file.get_basename(), "name": str(data.get("name", DEFAULT_NAME)), "ssf": bool(data.get("ssf", false)),
				"level": int(data.get("hero_level", 1)), "best_level": int(data.get("best_level", 0)),
				"weapon": str(data.get("weapon", Weapons.SWORD)), "created": int(data.get("created", 0)),
				"dev": bool(dev.get("immortal", false)) or bool(dev.get("all_levels", false)) or not (dev.get("stats", {}) as Dictionary).is_empty()})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.created < b.created if a.created != b.created else a.id < b.id)
	return out


## Nowa postać (1. poziom, pusta torba; postać bez SSF widzi wspólną skrzynię). Zwraca jej identyfikator.
func create_character(name: String, is_ssf: bool, first_weapon := Weapons.SWORD) -> String:
	DirAccess.make_dir_recursive_absolute(chars_dir)
	var id := "c%d" % int(Time.get_unix_time_from_system())
	var n := 1
	while FileAccess.file_exists(chars_dir + id + ".json"):
		n += 1
		id = "c%d_%d" % [int(Time.get_unix_time_from_system()), n]
	var clean := name.strip_edges().left(20)
	var f := FileAccess.open(chars_dir + id + ".json", FileAccess.WRITE)
	if f:
		var w := first_weapon if first_weapon in Weapons.START else Weapons.SWORD
		f.store_string(JSON.stringify({"name": clean if clean != "" else DEFAULT_NAME, "ssf": is_ssf,
				"created": int(Time.get_unix_time_from_system()), "start_weapon": w, "weapon": w,
				"skills_owned": [Skills.basic_of(w)], "mastery": {}}))
		f.close()
	return id


## Wybiera postać: zapis obecnej, wczytanie wybranej, zapamiętanie jako ostatniej.
func select_character(id: String) -> void:
	if save_path != "":
		save_if_dirty()
	character = id  # przed wczytaniem - od niej zależy, czy skrzynia jest wspólna
	save_path = chars_dir + id + ".json"
	last_character = id
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("characters", "last", id)
	cfg.save(settings_path)


## Usuwa postać na zawsze (jej przedmioty we wspólnej skrzyni zostają). Obecna postać - zapis się odłącza.
func delete_character(id: String) -> void:
	DirAccess.remove_absolute(chars_dir + id + ".json")
	if id == character:
		character = ""
		save_path = ""
	if id == last_character:
		last_character = ""
		var cfg := ConfigFile.new()
		cfg.load(settings_path)
		cfg.set_value("characters", "last", "")
		cfg.save(settings_path)


## Stary pojedynczy zapis (SAVE_PATH) - raz przenosi go na postać „Wojciech” z trybem deweloperskim ze starych
## ustawień; skrzynia trafia do wspólnej (przy pierwszym wczytaniu, gdy wspólnej jeszcze nie ma).
func _migrate_legacy() -> void:
	if not FileAccess.file_exists(legacy_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
	if not data is Dictionary:
		return
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	data["name"] = DEFAULT_NAME
	data["ssf"] = false
	data["created"] = 0
	data["dev"] = {"immortal": cfg.get_value("dev", "immortal", false), "all_levels": cfg.get_value("dev", "all_levels", false),
			"fps": cfg.get_value("dev", "fps", false), "stats": cfg.get_value("dev", "stats", {})}
	DirAccess.make_dir_recursive_absolute(chars_dir)
	var id := "c0"
	var f := FileAccess.open(chars_dir + id + ".json", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(legacy_path, legacy_path + ".old")
	if last_character == "":
		last_character = id


func load_game() -> void:
	embers = 0
	embers_brought = 0
	best_level = 0
	unlocks_seen = 0
	dungeon_mods = []
	dungeon_level = 1
	hero_level = 1
	hero_xp = 0
	bag = []
	equipped = {}
	gold = 0
	ore = 0
	stash = [[]]
	start_weapon = Weapons.SWORD
	weapon = Weapons.SWORD
	mastery = {}
	mastery_xp = {}
	weapons_bought = []
	weapon_slots = {}
	skills_owned = [Skills.STRIKE]
	skill_slots = _default_slots()
	skill_levels = {}
	gems = {}
	shards = 0
	runes = {}
	market = {}
	skill_gems = {}
	skill_open = {}
	tree = {}
	_old_upgrades = {}
	auras = {}
	auras_on = []
	talismans = {}
	talisman_slots = ["", "", ""]
	_read_filter(null)
	char_name = DEFAULT_NAME
	ssf = false
	_read_dev({})
	_dirty = false
	if save_path == "" or not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		char_name = str(data.get("name", DEFAULT_NAME))
		ssf = bool(data.get("ssf", false))
		_read_dev(data.get("dev", {}))
		_read_filter(data.get("loot_filter", null))
		if _uses_shared_stash() and FileAccess.file_exists(shared_stash_path):
			var shared = JSON.parse_string(FileAccess.get_file_as_string(shared_stash_path))
			if shared is Dictionary:
				data["stash"] = shared.get("stash", [])
		embers = int(data.get("embers", 0))
		best_level = int(data.get("best_level", 0))
		unlocks_seen = int(data.get("unlocks_seen", 0))
		var mods = data.get("dungeon_mods", [])
		dungeon_mods = (mods as Array).filter(func(m) -> bool: return DungeonMods.DATA.has(m)) if mods is Array else []
		dungeon_level = clampi(int(data.get("dungeon_level", 1)), 1, unlocked_level())
		hero_level = clampi(int(data.get("hero_level", 1)), 1, HeroLevels.MAX_LEVEL)
		hero_xp = maxi(int(data.get("hero_xp", 0)), 0)
		gold = maxi(int(data.get("gold", 0)), 0)
		ore = maxi(int(data.get("ore", 0)), 0)
		shards = maxi(int(data.get("shards", 0)), 0)
		market = Market.normalize(data.get("market", {}))
		runes = {}
		var raw_runes = data.get("runes", {})
		if raw_runes is Dictionary:
			for id in raw_runes:
				if Runes.valid(str(id)) and int(raw_runes[id]) > 0:
					runes[str(id)] = int(raw_runes[id])
		var raw_bag = data.get("bag", [])
		if raw_bag is Array:
			for raw in raw_bag:
				var item := Items.normalize(raw)
				if not item.is_empty() and bag.size() < BAG_SIZE:
					bag.append(item)
		var raw_stash = data.get("stash", [])
		if raw_stash is Array and not raw_stash.is_empty():
			stash = []
			for raw_tab in raw_stash.slice(0, STASH_TAB_LEVELS.size() + 1):
				var tab: Array = []
				if raw_tab is Array:
					for raw in raw_tab:
						var item := Items.normalize(raw)
						if not item.is_empty() and tab.size() < STASH_TAB_SIZE:
							tab.append(item)
				stash.append(tab)
		var raw_bought = data.get("weapons_bought", [])
		if raw_bought is Array:
			for id in raw_bought:
				if id is String and Weapons.has(id) and not weapons_bought.has(id):
					weapons_bought.append(id)
		var raw_start = data.get("start_weapon", Weapons.SWORD)
		start_weapon = raw_start if raw_start is String and raw_start in Weapons.START else Weapons.SWORD
		var raw_weapon = data.get("weapon", start_weapon)
		weapon = raw_weapon if raw_weapon is String and weapon_available(raw_weapon) else start_weapon
		var raw_mastery = data.get("mastery", {})
		var raw_mxp = data.get("mastery_xp", {})
		if raw_mastery is Dictionary and raw_mxp is Dictionary:
			for id in raw_mastery:
				if Weapons.has(id):
					mastery[id] = clampi(int(raw_mastery[id]), 1, Weapons.MAX_MASTERY)
					mastery_xp[id] = maxi(int(raw_mxp.get(id, 0)), 0)
		var raw_owned = data.get("skills_owned", [])
		if raw_owned is Array:
			for id in raw_owned:
				if id is String and Skills.has(id) and not skills_owned.has(id):
					skills_owned.append(id)
		skill_slots = _read_slots(data.get("skill_slots", []), weapon)
		var raw_ws = data.get("weapon_slots", {})
		if raw_ws is Dictionary:
			for id in raw_ws:
				if Weapons.has(id) and id != weapon:
					weapon_slots[id] = _read_slots(raw_ws[id], id)
		var raw_levels = data.get("skill_levels", {})
		if raw_levels is Dictionary:
			for id in raw_levels:
				if skills_owned.has(id) and int(raw_levels[id]) > 1:
					skill_levels[id] = clampi(int(raw_levels[id]), 1, Skills.MAX_LEVEL)
		var raw_gems = data.get("gems", {})
		if raw_gems is Dictionary:
			for raw_id in raw_gems:
				var id: String = Gems.LEGACY.get(raw_id, raw_id)
				if Gems.valid(id) and int(raw_gems[raw_id]) > 0:
					gems[id] = gems.get(id, 0) + int(raw_gems[raw_id])
		# kamienie z umiejętności, których już nie ma (Mgnienie miecza - 15.11.2026), wracają do sakwy
		var raw_old_sg = data.get("skill_gems", {})
		if raw_old_sg is Dictionary:
			for skill in raw_old_sg:
				if not Skills.has(skill) and raw_old_sg[skill] is Array:
					for g in raw_old_sg[skill]:
						var gid: String = Gems.LEGACY.get(g, g) if g is String else ""
						if Gems.valid(gid):
							gems[gid] = gems.get(gid, 0) + 1
		var raw_open = data.get("skill_open", {})
		if raw_open is Dictionary:
			for id in raw_open:
				if Skills.has(id):
					skill_open[id] = clampi(int(raw_open[id]), Gems.SKILL_OPEN, Gems.SKILL_SOCKETS)
		var raw_sg = data.get("skill_gems", {})
		if raw_sg is Dictionary:
			for id in raw_sg:
				if not Skills.has(id) or not raw_sg[id] is Array:
					continue
				var list: Array = []
				for i in Gems.SKILL_SOCKETS:
					var g = raw_sg[id][i] if i < raw_sg[id].size() else ""
					var dup := false
					for other in list:
						dup = dup or (other != "" and g is String and Gems.kind_of(other) == Gems.kind_of(g))
					list.append(g if g is String and Gems.is_support(g) and i < skill_open_count(id) and not dup \
							and (not Gems.is_unique(g) or Gems.unique_skill(g) == id) else "")
				skill_gems[id] = list
		var raw_eq = data.get("equipped", {})
		if raw_eq is Dictionary:
			for raw_slot in raw_eq:
				var item := Items.normalize(raw_eq[raw_slot])
				var slot: String = Items.LEGACY_SLOTS.get(raw_slot, raw_slot)
				if not item.is_empty() and item.slot == slot:
					equipped[slot] = item
		var raw_up = data.get("upgrades", {})
		if raw_up is Dictionary:
			for id in raw_up:
				if int(raw_up[id]) > 0:
					_old_upgrades[id] = clampi(int(raw_up[id]), 0, OLD_UPGRADE_PRICES.size())
		var raw_tree = data.get("tree", {})
		if raw_tree is Dictionary:
			for id in raw_tree:
				if DungeonTree.has(id) and int(raw_tree[id]) > 0:
					tree[id] = clampi(int(raw_tree[id]), 0, DungeonTree.max_of(id))
		_fix_tree()
		var raw_auras = data.get("auras", {})
		if raw_auras is Dictionary:
			for id in raw_auras:
				if Auras.is_aura(id) and int(raw_auras[id]) > 0:
					auras[id] = clampi(int(raw_auras[id]), 1, Auras.MAX_LEVEL)
		var raw_on = data.get("auras_on", [])
		if raw_on is Array:
			for id in raw_on:
				if id is String and auras.has(id) and not auras_on.has(id) \
						and Auras.reserve_sum(auras_on + [id], auras, aura_cut()) < Auras.MAX_RESERVED + 0.0001:
					auras_on.append(id)
		var raw_tal = data.get("talismans", {})
		if raw_tal is Dictionary:
			for id in raw_tal:
				if Talismans.is_talisman(id) and int(raw_tal[id]) > 0:
					talismans[id] = clampi(int(raw_tal[id]), 1, Talismans.MAX_LEVEL)
		var raw_ts = data.get("talisman_slots", [])
		if raw_ts is Array:
			for i in mini(raw_ts.size(), Talismans.SLOTS):
				var id = raw_ts[i]
				if id is String and talismans.has(id) and not talisman_slots.has(id):
					talisman_slots[i] = id
		if not data.has("mastery"):
			_migrate_mastery()
		_unlock_skills()
		_sync_stash_tabs()
		_convert_gold()


func save_game() -> void:
	_dirty = false
	if save_path == "":
		return
	var shared := _uses_shared_stash()
	if shared:
		var sf := FileAccess.open(shared_stash_path, FileAccess.WRITE)
		if sf:
			sf.store_string(JSON.stringify({"stash": stash}))
			sf.close()
	var created := _created()  # przed otwarciem pliku do zapisu (otwarcie go czyści)
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"name": char_name, "ssf": ssf, "created": created, "dev": _dev_data(),
				"embers": embers, "best_level": best_level, "unlocks_seen": unlocks_seen, "dungeon_mods": dungeon_mods, "dungeon_level": dungeon_level,
				"hero_level": hero_level, "hero_xp": hero_xp, "ore": ore, "bag": bag, "equipped": equipped,
				"stash": stash, "weapon": weapon, "start_weapon": start_weapon, "mastery": mastery, "mastery_xp": mastery_xp,
				"weapons_bought": weapons_bought, "weapon_slots": weapon_slots, "skills_owned": skills_owned, "skill_slots": skill_slots, "skill_levels": skill_levels, "gems": gems, "shards": shards, "runes": runes, "market": market,
				"skill_gems": skill_gems, "skill_open": skill_open, "tree": tree, "auras": auras, "auras_on": auras_on, "talismans": talismans, "talisman_slots": talisman_slots,
				"loot_filter": loot_filter}))


## Czy obecna postać korzysta ze wspólnej skrzyni (postać z listy, nie SSF; zapis testowy - nie).
func _uses_shared_stash() -> bool:
	return character != "" and not ssf


var _created_cache := {}


## Data utworzenia postaci z jej pliku (zachowana przy zapisie - kolejność na liście).
func _created() -> int:
	if _created_cache.has(save_path):
		return _created_cache[save_path]
	var value := 0
	if FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary:
			value = int(data.get("created", 0))
	_created_cache[save_path] = value
	return value


## Zapis tylko wtedy, gdy od ostatniego coś się zmieniło (np. doświadczenie z goblinów).
func save_if_dirty() -> void:
	if _dirty:
		save_game()


## Telefon przełącza aplikację albo gra się zamyka - zapisz doświadczenie zebrane w lochu.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		save_if_dirty()


## Ile doświadczenia brakuje do awansu (0 na najwyższym poziomie).
func xp_needed() -> int:
	return 0 if hero_level >= HeroLevels.MAX_LEVEL else HeroLevels.xp_to_next(hero_level)


## Doświadczenie dla postaci (pokonany potwór). Zwraca liczbę awansów. Awans od razu zapisuje grę,
## zwykłe doświadczenie - przy najbliższym zapisie (`save_if_dirty`).
func add_xp(amount: int) -> int:
	if amount <= 0 or hero_level >= HeroLevels.MAX_LEVEL:
		return 0
	hero_xp += amount
	var ups := 0
	while hero_level < HeroLevels.MAX_LEVEL and hero_xp >= HeroLevels.xp_to_next(hero_level):
		hero_xp -= HeroLevels.xp_to_next(hero_level)
		hero_level += 1
		ups += 1
	if hero_level >= HeroLevels.MAX_LEVEL:
		hero_xp = 0
	_dirty = true
	xp_changed.emit(hero_level, hero_xp, xp_needed())
	if ups > 0:
		save_game()
		leveled_up.emit(hero_level)
	return ups


## Tryb deweloperski: awans o jeden poziom od razu.
func dev_level_up() -> void:
	add_xp(xp_needed() - hero_xp)


## Tryb deweloperski: postać od nowa (1. poziom, bez doświadczenia, przedmiotów i rudy).
func reset_hero() -> void:
	hero_level = 1
	hero_xp = 0
	bag = []
	equipped = {}
	gold = 0
	ore = 0
	if not _uses_shared_stash():  # wspólna skrzynia należy też do innych postaci
		stash = [[]]
	weapon = start_weapon
	mastery = {}
	mastery_xp = {}
	weapons_bought = []
	weapon_slots = {}
	skills_owned = [Skills.STRIKE]
	skill_slots = _default_slots()
	skill_levels = {}
	gems = {}
	shards = 0
	runes = {}
	market = {}
	skill_gems = {}
	skill_open = {}
	auras = {}
	auras_on = []
	talismans = {}
	talisman_slots = ["", "", ""]
	save_game()
	mastery_changed.emit(mastery_level(), weapon_xp(), mastery_needed())
	xp_changed.emit(hero_level, hero_xp, xp_needed())
	inventory_changed.emit()
	skills_changed.emit()
	auras_changed.emit()
	talismans_changed.emit()


## Poziomy umiejętności `id` z założonych przedmiotów (premie skill_level i skill_level_all; walka - ProtoWeapon.level_of).
func item_skill_bonus(id: String) -> int:
	var t := Items.totals(equipped)
	return int(t.skill_bonus.get(id, 0)) + int(t.skill_level_all)


## Suma cech założonych przedmiotów (Items.totals), w trybie deweloperskim z nadpisanymi statystykami (dev_stats).
func gear() -> Dictionary:
	return Items.with_overrides(Auras.apply(Items.totals(equipped), auras_on, auras), dev_stats)


## Kamień aury podniesiony w lochu: nowa aura (poziom 1) albo poziom wyżej. Zwraca nowy poziom
## (0 - aura już na najwyższym poziomie, kamień przepada).
func add_aura(id: String) -> int:
	if not Auras.is_aura(id):
		return 0
	var lvl: int = auras.get(id, 0)
	if lvl >= Auras.MAX_LEVEL:
		return 0
	auras[id] = lvl + 1
	save_game()
	auras_changed.emit()
	inventory_changed.emit()  # premie aur liczy gear() - postać i broń przeliczają cechy
	return lvl + 1


## Talizman podniesiony w lochu: nowy (poziom 1, sam wskakuje w pierwsze wolne miejsce) albo poziom wyżej.
## Zwraca nowy poziom (0 - już najwyższy, talizman przepada).
func add_talisman(id: String) -> int:
	if not Talismans.is_talisman(id):
		return 0
	var lvl: int = talismans.get(id, 0)
	if lvl >= Talismans.MAX_LEVEL:
		return 0
	talismans[id] = lvl + 1
	if lvl == 0:
		var free := talisman_slots.find("")
		if free >= 0:
			talisman_slots[free] = id
	save_game()
	talismans_changed.emit()
	return lvl + 1


## Zakłada talizman w miejsce `slot` (był w innym miejscu - zamieniają się). Zwraca false przy złych danych.
func equip_talisman(id: String, slot: int) -> bool:
	if not talismans.has(id) or slot < 0 or slot >= Talismans.SLOTS:
		return false
	var from := talisman_slots.find(id)
	if from >= 0:
		talisman_slots[from] = talisman_slots[slot]
	talisman_slots[slot] = id
	save_game()
	talismans_changed.emit()
	return true


## Zdejmuje talizman z miejsca `slot` (zostaje w kolekcji).
func unequip_talisman(slot: int) -> void:
	if slot < 0 or slot >= Talismans.SLOTS or talisman_slots[slot] == "":
		return
	talisman_slots[slot] = ""
	save_game()
	talismans_changed.emit()


## Założone talizmany z poziomami (talizman -> poziom).
func worn_talismans() -> Dictionary:
	var worn := {}
	for id in talisman_slots:
		if id != "" and talismans.has(id):
			worn[id] = talismans[id]
	return worn


## Największa mana postaci z poziomu i przedmiotów (bez aur).
func max_mana() -> int:
	return HeroLevels.max_mana(hero_level) + roundi(Items.totals(equipped).get("mana", 0.0))


## Premia przedmiotów „mniejsza rezerwacja many” (ułamek; Auras.cut_of).
func aura_cut() -> float:
	return Auras.cut_of(Items.totals(equipped))


## Mana na najdroższą umiejętność w miejscach obecnej broni (koszt z poziomem umiejętności, bez kamieni).
func priciest_skill() -> int:
	if talisman_slots.has("blood_magic"):
		return 0  # Krwawe Serce: umiejętności płacą zdrowiem - aury mogą zająć całą dozwoloną manę
	var most := 0
	var tax := Talismans.archmage_cost(talismans["archmage"]) if talisman_slots.has("archmage") else 0.0  # Kryształ Peruna
	for id in skill_slots:
		if id != "" and Skills.has(id):
			most = maxi(most, roundi(Skills.mana_of(id) * Skills.level_mana(skill_level(id)) * (1.0 + tax)))
	return most


## Dlaczego nie da się włączyć aury ("" - da się): limit MAX_RESERVED albo za mało wolnej many na najdroższą
## założoną umiejętność (decyzja autora 19.11.2026).
func aura_problem(id: String) -> String:
	if not auras.has(id) or auras_on.has(id):
		return ""
	var after := Auras.reserve_sum(auras_on + [id], auras, aura_cut())
	if after > Auras.MAX_RESERVED + 0.0001:
		return Lang.t("Aury rezerwują już najwięcej many - wyłącz inną aurę")
	var free := floori(max_mana() * (1.0 - after))
	if free < priciest_skill():
		return Lang.t("Zostałoby %d many, a najdroższa umiejętność kosztuje %d") % [free, priciest_skill()]
	return ""


## Włącza albo wyłącza aurę. Zwraca powód, gdy się nie da ("" - zrobione).
func toggle_aura(id: String) -> String:
	if not auras.has(id):
		return Lang.t("Tej aury jeszcze nie masz")
	if auras_on.has(id):
		auras_on.erase(id)
	else:
		var problem := aura_problem(id)
		if problem != "":
			return problem
		auras_on.append(id)
	save_game()
	auras_changed.emit()
	inventory_changed.emit()
	return ""


## Tryb deweloperski: statystyka ustawiona na wartość (zamiast przedmiotów). Zapis przy zamknięciu okna.
func dev_set_stat(stat: String, value: float) -> void:
	dev_stats[stat] = value
	inventory_changed.emit()


## Tryb deweloperski: statystyka znów z przedmiotów.
func dev_clear_stat(stat: String) -> void:
	dev_stats.erase(stat)
	inventory_changed.emit()


func dev_clear_stats() -> void:
	dev_stats.clear()
	inventory_changed.emit()


## Tryb deweloperski: poziom postaci ustawiony wprost (1-HeroLevels.MAX_LEVEL, doświadczenie od zera); mistrzostwo
## obecnej broni idzie za nim (odblokowuje umiejętności jak w grze).
func dev_set_level(level: int) -> void:
	var old := hero_level
	hero_level = clampi(level, 1, HeroLevels.MAX_LEVEL)
	hero_xp = 0
	mastery[weapon] = clampi(level, 1, Weapons.MAX_MASTERY)
	mastery_xp[weapon] = 0
	_unlock_skills()
	mastery_changed.emit(mastery_level(), weapon_xp(), mastery_needed())
	save_game()
	xp_changed.emit(hero_level, hero_xp, xp_needed())
	if hero_level > old:
		leveled_up.emit(hero_level)


## Przedmiot do torby (łup) - od razu zapisany. Zwraca false, gdy torba jest pełna.
func add_item(item: Dictionary) -> bool:
	if bag.size() >= BAG_SIZE:
		return false
	bag.append(item)
	save_game()
	inventory_changed.emit()
	return true


## Zakłada przedmiot z torby; to, co było w tym miejscu, wraca do torby na jego miejsce.
func equip(index: int) -> void:
	if index < 0 or index >= bag.size():
		return
	var item: Dictionary = bag[index]
	if equipped.has(item.slot):
		bag[index] = equipped[item.slot]
	else:
		bag.remove_at(index)
	equipped[item.slot] = item
	save_game()
	inventory_changed.emit()


## Zdejmuje przedmiot do torby. Zwraca false, gdy torba jest pełna.
func unequip(slot: String) -> bool:
	if not equipped.has(slot) or bag.size() >= BAG_SIZE:
		return false
	bag.append(equipped[slot])
	equipped.erase(slot)
	save_game()
	inventory_changed.emit()
	return true


## Rozbija przedmiot z torby na rudę (kamienie z gniazd wracają do sakwy; rzadki czasem daje Runę Szlifu).
## Zwraca {"ore": ile rudy, "rune": runa albo ""} (puste - zły indeks).
func dismantle(index: int) -> Dictionary:
	if index < 0 or index >= bag.size():
		return {}
	var item: Dictionary = bag[index]
	_return_item_gems(item)
	bag.remove_at(index)
	var got := _scrap(item)
	save_game()
	inventory_changed.emit()
	return got


## Ile rudy dałoby rozbicie wszystkich przedmiotów z torby o podanych rzadkościach (np. ["common"]).
func dismantle_all_ore(rarities: Array) -> int:
	var total := 0
	for item in bag:
		if item.rarity in rarities:
			total += ore_gain(Items.ore_value(item))
	return total


## Rozbija wszystkie przedmioty z torby o podanych rzadkościach. Zwraca {"ore": razem rudy, "runes": ile run}.
func dismantle_all(rarities: Array) -> Dictionary:
	var got := {"ore": 0, "runes": 0}
	var keep: Array = []
	for item in bag:
		if item.rarity in rarities:
			_return_item_gems(item)
			var one := _scrap(item)
			got.ore += one.ore
			got.runes += 1 if one.rune != "" else 0
		else:
			keep.append(item)
	if keep.size() == bag.size():
		return got
	bag = keep
	save_game()
	inventory_changed.emit()
	return got


## Rozbija przedmiot, który nie trafia do torby (auto rozbijanie zwykłych, pełna torba przy skrzyni).
## Zwraca {"ore", "rune"} jak `dismantle`.
func dismantle_loot(item: Dictionary) -> Dictionary:
	var got := _scrap(item)
	save_game()
	inventory_changed.emit()
	return got


## Kowal wykuwa przedmiot z miejsca `slot` za Items.FORGE_ORE rudy: poziom najgłębszego przebitego lochu, rzadkość
## losowa (Items.FORGE_WEIGHTS), baza `type` (pusta - losowa; Items.BASES), trafia do torby. Zwraca przedmiot (pusty - brak
## rudy, pełna torba albo złe miejsce).
func forge(slot: String, type := "") -> Dictionary:
	if forge_problem(slot) != "":
		return {}
	ore -= Items.FORGE_ORE
	var item := Items.roll(maxi(best_level, 1), slot, "", Items.FORGE_WEIGHTS, type, false)  # kuźnia - bez legend
	bag.append(item)
	save_game()
	inventory_changed.emit()
	return item


## Czemu nie da się wykuć ("" - da się): "ore" (za mało rudy), "bag" (pełna torba), "slot" (złe miejsce).
func forge_problem(slot: String) -> String:
	if not slot in Items.SLOTS:
		return "slot"
	if ore < Items.FORGE_ORE:
		return "ore"
	if bag.size() >= BAG_SIZE:
		return "bag"
	return ""


## Ruda (i czasem runa) z jednego przedmiotu - dopisuje do zapasów.
func _scrap(item: Dictionary) -> Dictionary:
	var amount := ore_gain(Items.ore_value(item))
	ore += amount
	var rune := ""
	if item.rarity in ["rare", "legendary"] and randf() < Items.SCRAP_RUNE * treasury_mult():
		rune = Runes.POLISH
		runes[rune] = int(runes.get(rune, 0)) + 1
	return {"ore": amount, "rune": rune}


## Drzewko lochów - Skarbiec: mnożnik rudy i szans na runy.
func treasury_mult() -> float:
	return 1.0 + tree_value("gold") / 100.0


## Ruda po premii Skarbca.
func ore_gain(amount: int) -> int:
	return roundi(amount * treasury_mult() * (1.0 + Items.totals(equipped).get("ore_pct", 0.0) / 100.0))


## Ruda z lochu (Skarbnik) - z premią Skarbca; zapis przy najbliższym `save_if_dirty`. Zwraca, ile doszło.
func add_ore(amount: int) -> int:
	if amount <= 0:
		return 0
	var got := ore_gain(amount)
	ore += got
	_dirty = true
	return got


## Odpryski z lochu (Kryształ Watry) - zapis przy najbliższym `save_if_dirty`.
func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount
	_dirty = true


## Poziom lochu, po którego przebiciu dojdzie następna zakładka skrzyni (0 - są już wszystkie).
func next_tab_level() -> int:
	var i := stash.size() - 1
	return STASH_TAB_LEVELS[i] if i < STASH_TAB_LEVELS.size() else 0


## Ile zakładek skrzyni należy się za przebite lochy.
func earned_tabs() -> int:
	return 1 + STASH_TAB_LEVELS.filter(func(l: int) -> bool: return best_level >= l).size()


## Dokłada zakładki skrzyni za przebite lochy (nigdy nie zabiera - wspólna skrzynia mogła je dostać od innej postaci).
## Zwraca true, gdy doszła nowa.
func _sync_stash_tabs() -> bool:
	var added := false
	while stash.size() < earned_tabs():
		stash.append([])
		added = true
	return added


## Przeliczenie złota ze starego zapisu (i dawnych zwrotów) na runy i rudę - raz, przy wczytaniu.
func _convert_gold() -> void:
	gold_converted = Vector2i.ZERO
	if gold <= 0:
		return
	var count := mini(gold / GOLD_PER_RUNE, GOLD_RUNES_MAX)
	for i in count:
		var id := Runes.roll(maxi(best_level, 1), [Runes.SEAL])
		runes[id] = int(runes.get(id, 0)) + 1
	var amount := mini((gold - count * GOLD_PER_RUNE) / GOLD_PER_ORE, GOLD_ORE_MAX)
	ore += amount
	gold_converted = Vector2i(count, amount)
	gold = 0
	_dirty = true


## Przenosi przedmiot z torby do zakładki skrzyni. Zwraca false, gdy zakładka jest pełna.
func to_stash(bag_index: int, tab: int) -> bool:
	if bag_index < 0 or bag_index >= bag.size() or tab < 0 or tab >= stash.size() \
			or stash[tab].size() >= STASH_TAB_SIZE:
		return false
	stash[tab].append(bag[bag_index])
	bag.remove_at(bag_index)
	save_game()
	inventory_changed.emit()
	return true


## Przenosi przedmiot ze skrzyni do torby. Zwraca false, gdy torba jest pełna.
func from_stash(tab: int, index: int) -> bool:
	if tab < 0 or tab >= stash.size() or index < 0 or index >= stash[tab].size() or bag.size() >= BAG_SIZE:
		return false
	bag.append(stash[tab][index])
	stash[tab].remove_at(index)
	save_game()
	inventory_changed.emit()
	return true


## Cała torba do zakładki skrzyni (ile się zmieści). Zwraca, ile przeniesiono.
func stash_all(tab: int) -> int:
	if tab < 0 or tab >= stash.size():
		return 0
	var moved := 0
	while not bag.is_empty() and stash[tab].size() < STASH_TAB_SIZE:
		stash[tab].append(bag.pop_front())
		moved += 1
	if moved > 0:
		save_game()
		inventory_changed.emit()
	return moved


## Tryb deweloperski: losowe przedmioty z obecnego poziomu lochu (ile się zmieści). Zwraca, ile dodano.
func dev_items(count := 5) -> int:
	var added := 0
	for i in count:
		if bag.size() >= BAG_SIZE:
			break
		bag.append(Items.roll(dungeon_level, "", "", Items.CHEST_WEIGHTS))
		added += 1
	save_game()
	inventory_changed.emit()
	return added


## Tryb deweloperski: wszystkie unikaty (Items.UNIQUES) z obecnego poziomu lochu do torby (ile się zmieści).
func dev_uniques() -> int:
	var added := 0
	for id in Items.UNIQUES:
		if bag.size() >= BAG_SIZE:
			break
		bag.append(Items.make_unique(id, maxi(dungeon_level, Items.UNIQUE_FROM)))
		added += 1
	save_game()
	inventory_changed.emit()
	return added


## Żar doniesiony z lochu do Watry (powrót do bazy, nie śmierć) - od razu zapisany.
func bank_embers(amount: int) -> void:
	if amount <= 0:
		return
	embers += amount
	embers_brought += amount
	save_game()


## Najwyższy poziom lochu, na który można wejść (jeden nad najwyższym przebitym).
## W trybie deweloperskim „wszystkie poziomy” - aż do DEV_MAX_LEVEL.
func unlocked_level() -> int:
	return maxi(best_level + 1, DEV_MAX_LEVEL) if dev_all_levels else best_level + 1


## Boss pokonany na poziomie `level` - odblokowuje następny (zapis od razu). Zwraca true, gdy to nowy rekord.
func beat_level(level: int) -> bool:
	if level <= best_level:
		return false
	best_level = level
	_sync_stash_tabs()  # nowa zakładka skrzyni za przebity loch (STASH_TAB_LEVELS)
	save_game()
	return true


## Miejsca z zapisu dla broni `w`: tylko odblokowane umiejętności tej broni, bez powtórek, pod dużym przyciskiem
## tylko te, które mogą tam stać (pusty zapis - miejsca na start).
func _read_slots(raw, w: String) -> Array:
	if not raw is Array or raw.is_empty():
		return _default_slots(w)
	var slots: Array = []
	for i in Skills.SLOTS:
		var id = raw[i] if i < raw.size() else ""
		var ok: bool = id is String and skills_owned.has(id) and not slots.has(id) and Skills.weapon_of(id) == w \
				and (i != Skills.MAIN or Skills.can_be_main(id))
		slots.append(id if ok else "")
	return slots


## Miejsca na start: zwykły cios broni pod dużym przyciskiem, reszta pusta.
static func _default_slots(w := Weapons.SWORD) -> Array:
	var slots: Array = [Skills.basic_of(w)]
	for i in Skills.SLOTS - 1:
		slots.append("")
	return slots


# --- Bronie i mistrzostwo (Weapons) ---

## Czy broń można wziąć do ręki: miecz zawsze, inne po przebiciu progu lochu albo odblokowane Pieczęcią Oręża.
func weapon_available(id: String) -> bool:
	return Weapons.has(id) and (id == start_weapon or Weapons.unlocked_by(id, best_level) or weapons_bought.has(id))


## Czy ze skrzyni Wodza wypada Pieczęć Oręża: z szansą Gems.CHEST_WEAPON_SEAL x `chance_mult`, tylko gdy jakaś broń
## nie jest jeszcze dostępna, a gracz nie ma już pieczęci w sakwie.
func roll_weapon_seal(chance_mult := 1.0) -> bool:
	if gem_count(Gems.WEAPON_SEAL) > 0 or Weapons.ORDER.all(func(w: String) -> bool: return weapon_available(w)):
		return false
	return randf() < Gems.CHEST_WEAPON_SEAL * chance_mult


## Odblokowuje broń Pieczęcią Oręża (Gems.WEAPON_SEAL z sakwy) przed progiem lochu. Zwraca false, gdy broń jest już
## dostępna, nieznana albo brak pieczęci.
func unseal_weapon(id: String) -> bool:
	if not Weapons.has(id) or weapon_available(id) or not _take_gem(Gems.WEAPON_SEAL):
		return false
	weapons_bought.append(id)
	save_game()
	inventory_changed.emit()
	weapon_changed.emit()
	return true


## Bierze do ręki inną broń: jej własne miejsca umiejętności (pierwszy raz - jej zwykły cios pod „Atak”) i mistrzostwo;
## od razu odblokowuje jej umiejętności, do których starcza mistrzostwa. Zwraca false, gdy niedostępna.
func set_weapon(id: String) -> bool:
	if not weapon_available(id):
		return false
	if id == weapon:
		return true
	weapon_slots[weapon] = skill_slots
	weapon = id
	skill_slots = weapon_slots.get(id, _default_slots(id))
	weapon_slots.erase(id)
	_unlock_skills()
	save_game()
	weapon_changed.emit()
	skills_changed.emit()
	mastery_changed.emit(mastery_level(), weapon_xp(), mastery_needed())
	return true

## Poziom mistrzostwa broni (domyślnie tej w ręku).
func mastery_level(id := "") -> int:
	return mastery.get(weapon if id == "" else id, 1)


## Doświadczenie mistrzostwa na obecnym poziomie (domyślnie broni w ręku).
func weapon_xp(id := "") -> int:
	return mastery_xp.get(weapon if id == "" else id, 0)


## Ile doświadczenia mistrzostwa brakuje broni w ręku do następnego poziomu (0 na najwyższym).
func mastery_needed() -> int:
	var lvl := mastery_level()
	return 0 if lvl >= Weapons.MAX_MASTERY else Weapons.xp_to_next(lvl)


## Mistrzostwo dla broni w ręku (pokonany potwór albo boss - tyle samo co doświadczenie postaci). Nowe progi od razu
## odblokowują umiejętności (sygnał `skill_unlocked` dla każdej). Zwraca liczbę awansów mistrzostwa.
func add_mastery(amount: int) -> int:
	var lvl := mastery_level()
	if amount <= 0 or lvl >= Weapons.MAX_MASTERY:
		return 0
	var xp := weapon_xp() + amount
	var ups := 0
	while lvl < Weapons.MAX_MASTERY and xp >= Weapons.xp_to_next(lvl):
		xp -= Weapons.xp_to_next(lvl)
		lvl += 1
		ups += 1
	mastery[weapon] = lvl
	mastery_xp[weapon] = 0 if lvl >= Weapons.MAX_MASTERY else xp
	_dirty = true
	if ups > 0:
		for id in _unlock_skills():
			skill_unlocked.emit(id)
		save_game()
	mastery_changed.emit(lvl, weapon_xp(), mastery_needed())
	return ups


## Dopisuje do odblokowanych umiejętności broni w ręku te, do których starcza mistrzostwa, i wstawia każdą w pierwsze
## wolne odblokowane małe miejsce (jeśli jest). Zwraca nowo odblokowane.
func _unlock_skills() -> Array[String]:
	var added: Array[String] = []
	for id in Skills.unlocked_at(weapon, mastery_level()):
		if skills_owned.has(id):
			continue
		skills_owned.append(id)
		added.append(id)
		if skill_slots.has(id):
			continue
		for i in range(1, Skills.open_slots(hero_level)):
			if skill_slots[i] == "":
				skill_slots[i] = id
				break
	if not added.is_empty():
		skills_changed.emit()
	return added


## Przejście zapisu sprzed mistrzostwa (13.11.2026): mistrzostwo miecza = poziom postaci, a kupione umiejętności
## i ich poziomy zostają; wraca złoto wydane na umiejętności i ich poziomy oraz żar wydany na ulepszenia lochów
## (teraz są za złoto, a żar idzie na umiejętności).
func _migrate_mastery() -> void:
	mastery[Weapons.SWORD] = clampi(hero_level, 1, Weapons.MAX_MASTERY)
	mastery_xp[Weapons.SWORD] = 0
	for id in skills_owned:
		gold += Skills.LEGACY_PRICE.get(id, 0)
		for lvl in range(1, skill_level(id)):
			gold += Skills.upgrade_price(id, lvl)
	# dawne ulepszenia lochów oddaje już _fix_tree (złotem)


## Poziom umiejętności (1 - nieulepszona albo niekupiona).
func skill_level(id: String) -> int:
	return skill_levels.get(id, 1)


## Dlaczego nie da się ulepszyć umiejętności ("" - da się): "owned" - nieodblokowana, "max" - najwyższy poziom,
## "mastery" - za niskie mistrzostwo broni (Skills.level_cap), "embers" - za mało żaru.
func skill_upgrade_problem(id: String) -> String:
	if not skills_owned.has(id):
		return "owned"
	var lvl := skill_level(id)
	if lvl >= Skills.MAX_LEVEL:
		return "max"
	if lvl >= Skills.level_cap(mastery_level(Skills.weapon_of(id))):
		return "mastery"
	if embers < Skills.upgrade_price(id, lvl):
		return "embers"
	return ""


## Ulepsza umiejętność o poziom za żar z Watry. Zwraca false, gdy się nie da (skill_upgrade_problem).
func upgrade_skill(id: String) -> bool:
	if skill_upgrade_problem(id) != "":
		return false
	var lvl := skill_level(id)
	embers -= Skills.upgrade_price(id, lvl)
	skill_levels[id] = lvl + 1
	save_game()
	embers_changed.emit()
	skills_changed.emit()
	return true


## Czy miejsce jest odblokowane (duży przycisk zawsze, małe - z poziomem postaci).
func slot_open(slot: int) -> bool:
	return slot >= 0 and slot < Skills.open_slots(hero_level)


## Wstawia kupioną umiejętność w miejsce. Jeśli stała już w innym miejscu, zamienia się z tym, co było w docelowym
## (o ile to, co wraca, może tam stać - inaczej tamto miejsce zostaje puste). Zwraca false, gdy się nie da.
func assign_skill(id: String, slot: int) -> bool:
	if not skills_owned.has(id) or not slot_open(slot) or (slot == Skills.MAIN and not Skills.can_be_main(id)) \
			or Skills.weapon_of(id) != weapon:
		return false
	var from := skill_slots.find(id)
	if from == slot:
		return true
	var old: String = skill_slots[slot]
	skill_slots[slot] = id
	if from >= 0:
		skill_slots[from] = old if (from != Skills.MAIN or Skills.can_be_main(old)) else ""
	save_game()
	skills_changed.emit()
	return true


## Zdejmuje umiejętność z miejsca (puste miejsce; pusty duży przycisk to zwykły cios).
func clear_skill_slot(slot: int) -> void:
	if slot < 0 or slot >= Skills.SLOTS or skill_slots[slot] == "":
		return
	skill_slots[slot] = ""
	save_game()
	skills_changed.emit()


## Umiejętność pod dużym przyciskiem (pusty - zwykły cios).
func main_skill() -> String:
	var id: String = skill_slots[Skills.MAIN]
	return id if id != "" else Skills.basic_of(weapon)


## Tryb deweloperski: wszystkie umiejętności broni w ręku bez wymaganego mistrzostwa.
func dev_skills() -> void:
	for id in Skills.of_weapon(weapon):
		if not skills_owned.has(id):
			skills_owned.append(id)
			for i in range(1, Skills.open_slots(hero_level)):
				if skill_slots[i] == "":
					skill_slots[i] = id
					break
	save_game()
	skills_changed.emit()


# --- Kamienie (Gems) ---

## Ile sztuk kamienia (klucza, dłuta) jest w sakwie.
func gem_count(id: String) -> int:
	return gems.get(id, 0)


## Kamień (klucz, dłuto) do sakwy - łup, wyjęty z gniazda. Sakwa nie ma limitu.
func add_gem(id: String, count := 1, save := true) -> void:
	if not Gems.valid(id) or count <= 0:
		return
	gems[id] = gem_count(id) + count
	if save:
		save_game()
		inventory_changed.emit()


## Zabiera sztukę z sakwy (bez zapisu). Zwraca false, gdy jej nie ma.
func _take_gem(id: String) -> bool:
	if gem_count(id) <= 0:
		return false
	gems[id] -= 1
	if gems[id] <= 0:
		gems.erase(id)
	return true


## Przedziały poziomu w filtrze sakwy (poziom ulepszenia; szlachetny - liczba premii): [od, do].
const GEM_LEVEL_RANGES := [[1, 3], [4, 7], [8, 10]]


## Kamienie w sakwie. `filter`: "support", "jewel" albo "" - wszystkie. `sort`: "kind" - najpierw klucze i dłuta,
## potem unikalne, kamienie umiejętności i szlachetne, w rodzaju od najwyższego poziomu; "level" - od najwyższego
## poziomu (szlachetne - liczby premii), klucze i dłuta na końcu. `levels`: [od, do] poziomu (puste - wszystkie;
## klucze, dłuta i unikalne wtedy pominięte).
func gem_list(filter := "", sort := "kind", levels: Array = []) -> Array:
	var out: Array = []
	for id in gems:
		if filter == "support" and not Gems.is_support(id) or filter == "jewel" and not Gems.is_jewel(id):
			continue
		if not levels.is_empty():
			var lvl := Gems.level_of(id)
			if lvl < int(levels[0]) or lvl > int(levels[1]):
				continue
		out.append(id)
	if sort == "level":
		out.sort_custom(func(a: String, b: String) -> bool:
			var la := _gem_rank(a)
			var lb := _gem_rank(b)
			return la > lb if la != lb else _gem_order(a) < _gem_order(b))
	else:
		out.sort_custom(func(a: String, b: String) -> bool: return _gem_order(a) < _gem_order(b))
	return out


## Pozycja przy sortowaniu po rodzaju (w rodzaju: wyższy poziom, potem nazwa - stałe ułożenie szlachetnych).
static func _gem_order(id: String) -> String:
	if Gems.is_special(id):
		return "0%d" % (0 if id == Gems.KEY else 1)
	if Gems.is_unique(id):
		return "1%02d" % Skills.ORDER.find(Gems.unique_skill(id))
	var kind := Gems.kind_of(id)
	var group := "2%02d" % Gems.SUPPORT_ORDER.find(kind) if Gems.is_support(id) else "3%02d" % Gems.JEWEL_ORDER.find(kind)
	return "%s%02d%s" % [group, 99 - Gems.level_of(id), id]


## Poziom przy sortowaniu po poziomie (szlachetne z premiami jak poziomy; unikalne wysoko, klucze i dłuta na końcu).
static func _gem_rank(id: String) -> int:
	if Gems.is_special(id):
		return -1
	return Gems.MAX_LEVEL + 1 if Gems.is_unique(id) else Gems.level_of(id)


# --- ulepszanie, sprzedaż i rozbijanie kamieni ---

## Czy stać na ulepszenie kamienia (odpryski).
func can_afford_upgrade(id: String) -> bool:
	var cost := Gems.upgrade_cost(id)
	return cost > 0 and shards >= cost


## Ulepsza kamień za odpryski: sztukę z sakwy (`skill` i `item` puste), kamień w gnieździe `index`
## umiejętności `skill` albo przedmiotu `item`. Zwraca nowy identyfikator ("" - nie da się).
func upgrade_gem(id: String, skill := "", item: Dictionary = {}, index := -1) -> String:
	if not can_afford_upgrade(id):
		return ""
	if skill != "":
		if index < 0 or index >= Gems.SKILL_SOCKETS or skill_sockets(skill)[index] != id:
			return ""
	elif not item.is_empty():
		var sockets: Array = item.get("sockets", [])
		if index < 0 or index >= sockets.size() or sockets[index] != id:
			return ""
	elif gem_count(id) <= 0:
		return ""
	var cost := Gems.upgrade_cost(id)
	var new_id := Gems.upgraded(id)
	shards -= cost
	if skill != "":
		var list := skill_sockets(skill).duplicate()
		list[index] = new_id
		skill_gems[skill] = list
	elif not item.is_empty():
		item.sockets[index] = new_id
	else:
		_take_gem(id)
		gems[new_id] = gem_count(new_id) + 1
	save_game()
	inventory_changed.emit()
	if skill != "":
		skills_changed.emit()
	return new_id


## Odpryski za rozbicie wszystkich sztuk kamieni `ids` z sakwy (klucze, dłuta i pieczęcie się pomija).
func gems_value(ids: Array) -> int:
	var total := 0
	for id in ids:
		if Gems.can_shatter(id):
			total += Gems.shard_value(id) * gem_count(id)
	return total


## Rozbija na odpryski wszystkie sztuki kamieni `ids` z sakwy. Zwraca, ile odprysków dały.
func shatter_gems(ids: Array) -> int:
	var got := gems_value(ids)
	for id in ids:
		if Gems.can_shatter(id):
			gems.erase(id)
	shards += got
	save_game()
	inventory_changed.emit()
	return got


## Rozbija jedną sztukę kamienia z sakwy. Zwraca, ile odprysków dała (0 - nie da się).
func shatter_gem(id: String) -> int:
	if not Gems.can_shatter(id) or not _take_gem(id):
		return 0
	var got := Gems.shard_value(id)
	shards += got
	save_game()
	inventory_changed.emit()
	return got


## Liczba otwartych gniazd umiejętności.
func skill_open_count(skill: String) -> int:
	return skill_open.get(skill, Gems.SKILL_OPEN)


## Kamienie w gniazdach umiejętności (zawsze Gems.SKILL_SOCKETS pozycji, "" - puste).
func skill_sockets(skill: String) -> Array:
	if not skill_gems.has(skill):
		var empty: Array = []
		empty.resize(Gems.SKILL_SOCKETS)
		empty.fill("")
		return empty
	return skill_gems[skill]


## Czemu kamienia nie da się włożyć w gniazdo umiejętności ("" - da się): "owned", "locked", "kind" (nie kamień
## umiejętności), "skill" (kamień unikalny innej umiejętności), "none" (brak w sakwie), "same" (ten rodzaj już jest w innym gnieździe tej umiejętności).
func skill_socket_problem(skill: String, index: int, id: String) -> String:
	if not skills_owned.has(skill):
		return "owned"
	if index < 0 or index >= skill_open_count(skill):
		return "locked"
	if not Gems.is_support(id):
		return "kind"
	if Gems.is_unique(id) and Gems.unique_skill(id) != skill:
		return "skill"
	if not Gems.fits(id, skill):
		return "basic"
	if gem_count(id) <= 0:
		return "none"
	var sockets := skill_sockets(skill)
	for i in sockets.size():
		if i != index and sockets[i] != "" and Gems.kind_of(sockets[i]) == Gems.kind_of(id):
			return "same"
	return ""


## Wkłada kamień z sakwy w gniazdo umiejętności; to, co tam było, wraca do sakwy. Zwraca false, gdy się nie da.
func socket_skill(skill: String, index: int, id: String) -> bool:
	if skill_socket_problem(skill, index, id) != "":
		return false
	var sockets := skill_sockets(skill).duplicate()
	if sockets[index] != "":
		add_gem(sockets[index], 1, false)
	_take_gem(id)
	sockets[index] = id
	skill_gems[skill] = sockets
	save_game()
	inventory_changed.emit()
	skills_changed.emit()
	return true


## Wyjmuje kamień z gniazda umiejętności do sakwy (za darmo).
func unsocket_skill(skill: String, index: int) -> bool:
	var sockets := skill_sockets(skill).duplicate()
	if index < 0 or index >= sockets.size() or sockets[index] == "":
		return false
	add_gem(sockets[index], 1, false)
	sockets[index] = ""
	skill_gems[skill] = sockets
	save_game()
	inventory_changed.emit()
	skills_changed.emit()
	return true


## Otwiera kolejne gniazdo umiejętności Kluczem Runicznym z sakwy. Zwraca false, gdy brak klucza albo wszystkie otwarte.
func open_skill_socket(skill: String) -> bool:
	if not skills_owned.has(skill) or skill_open_count(skill) >= Gems.SKILL_SOCKETS or not _take_gem(Gems.KEY):
		return false
	skill_open[skill] = skill_open_count(skill) + 1
	save_game()
	inventory_changed.emit()
	skills_changed.emit()
	return true


## Wkłada kamień szlachetny z sakwy w gniazdo przedmiotu (przedmiot z torby, założony albo ze skrzyni - słownik
## zmienia się w miejscu); to, co było w gnieździe, wraca do sakwy. Zwraca false, gdy się nie da.
func socket_item(item: Dictionary, index: int, id: String) -> bool:
	var sockets: Array = item.get("sockets", [])
	if index < 0 or index >= sockets.size() or not Gems.is_jewel(id) or gem_count(id) <= 0:
		return false
	if sockets[index] != "":
		add_gem(sockets[index], 1, false)
	_take_gem(id)
	sockets[index] = id
	save_game()
	inventory_changed.emit()
	return true


## Wyjmuje kamień z gniazda przedmiotu do sakwy (za darmo).
func unsocket_item(item: Dictionary, index: int) -> bool:
	var sockets: Array = item.get("sockets", [])
	if index < 0 or index >= sockets.size() or sockets[index] == "":
		return false
	add_gem(sockets[index], 1, false)
	sockets[index] = ""
	save_game()
	inventory_changed.emit()
	return true


## Dorabia drugie gniazdo w przedmiocie Dłutem Jubilera z sakwy. Zwraca false, gdy brak dłuta albo gniazd jest już dość.
func add_socket(item: Dictionary) -> bool:
	if item.is_empty() or item.get("sockets", []).size() >= Items.MAX_SOCKETS or not _take_gem(Gems.CHISEL):
		return false
	item.sockets.append("")
	save_game()
	inventory_changed.emit()
	return true


## Pierwsze wolne otwarte gniazdo umiejętności (-1 - brak).
func free_skill_socket(skill: String) -> int:
	var sockets := skill_sockets(skill)
	for i in skill_open_count(skill):
		if sockets[i] == "":
			return i
	return -1


## Pierwsze wolne gniazdo przedmiotu (-1 - brak).
func free_item_socket(item: Dictionary) -> int:
	return item.get("sockets", []).find("")


## Wszystkie przedmioty: założone (w kolejności Items.SLOTS), potem torba.
func all_items() -> Array:
	var out: Array = []
	for slot in Items.SLOTS:
		if equipped.has(slot):
			out.append(equipped[slot])
	out.append_array(bag)
	return out


## Kamienie z przedmiotu (sprzedaż) wracają do sakwy - nie przepadają.
func _return_item_gems(item: Dictionary) -> void:
	for id in item.get("sockets", []):
		if id != "":
			add_gem(id, 1, false)


## Tryb deweloperski: po kamieniu każdego rodzaju (szlachetne z obecnego poziomu lochu), kamienie unikalne,
## 2 klucze, 2 dłuta i 100 odprysków.
## Tryb deweloperski: wszystkie aury - brakujące na 1. poziomie, posiadane o poziom wyżej (do Auras.MAX_LEVEL).
func dev_auras() -> void:
	for id in Auras.ORDER:
		add_aura(id)


## Tryb deweloperski: wszystkie talizmany - brakujące na 1. poziomie, posiadane o poziom wyżej (do Talismans.MAX_LEVEL).
func dev_talismans() -> void:
	for id in Talismans.ORDER:
		add_talisman(id)


func dev_gems() -> void:
	for kind in Gems.SUPPORT_ORDER:
		add_gem(Gems.make(kind), 1, false)
	for kind in Gems.JEWEL_ORDER:
		add_gem(Gems.roll_jewel(kind, dungeon_level), 1, false)
	shards += 300
	for skill in Gems.UNIQUE:
		add_gem(Gems.unique_of(skill), 1, false)
	add_gem(Gems.KEY, 2, false)
	add_gem(Gems.CHISEL, 2, false)
	save_game()
	inventory_changed.emit()


# --- Baza: drzewko lochów, kupiec i kowal ---

## Punkty drzewka lochów razem: 1 za każdy przebity poziom lochu (decyzja autora 20.11.2026).
func tree_total() -> int:
	return best_level


## Wolne punkty drzewka.
func tree_free() -> int:
	return maxi(tree_total() - DungeonTree.spent(tree), 0)


func tree_points(id: String) -> int:
	return tree.get(id, 0)


## Premia węzła drzewka (procenty, piksele albo sekundy - DungeonTree.value).
func tree_value(id: String) -> float:
	return DungeonTree.value(id, tree_points(id))


## Dlaczego nie da się dodać punktu do węzła ("" - da się).
func tree_add_problem(id: String) -> String:
	if not DungeonTree.has(id):
		return "unknown"
	if tree_points(id) >= DungeonTree.max_of(id):
		return "max"
	var parent := DungeonTree.parent_of(id)
	if parent != "" and tree_points(parent) <= 0:
		return "locked"
	if tree_free() <= 0:
		return "points"
	return ""


## +1 punkt w węźle. Zwraca false, gdy się nie da (tree_add_problem).
func tree_add(id: String) -> bool:
	if tree_add_problem(id) != "":
		return false
	tree[id] = tree_points(id) + 1
	save_game()
	inventory_changed.emit()
	return true


## -1 punkt z węzła (cofanie za darmo - decyzja autora). Ostatni punkt małego węzła zabiera też punkty z dużych
## węzłów za nim (bez niego są zamknięte). Zwraca false, gdy w węźle nie ma punktów.
func tree_remove(id: String) -> bool:
	if tree_points(id) <= 0:
		return false
	tree[id] = tree_points(id) - 1
	if tree[id] == 0:
		tree.erase(id)
		for child in DungeonTree.children_of(id):
			tree.erase(child)
	save_game()
	inventory_changed.emit()
	return true


## Cofa wszystkie punkty drzewka (za darmo).
func tree_reset() -> void:
	tree = {}
	save_game()
	inventory_changed.emit()


## Porządek po wczytaniu: duże węzły bez punktu w małym - zamknięte; więcej punktów niż przebitych lochów (np. po
## zmianie danych) - drzewko od nowa. Dawne ulepszenia lochów za złoto znikają, złoto wraca (decyzja autora 20.11.2026;
## od razu przeliczane na runy i rudę - `_convert_gold`).
func _fix_tree() -> void:
	for id in tree.keys():
		var parent := DungeonTree.parent_of(id)
		if not DungeonTree.has(id) or parent != "" and tree_points(parent) <= 0:
			tree.erase(id)
	if DungeonTree.spent(tree) > tree_total():
		tree = {}
	var refund := 0
	for id in _old_upgrades:
		for step in _old_upgrades[id]:
			refund += OLD_UPGRADE_PRICES[step]
	if refund > 0:
		gold += refund
		_dirty = true
	_old_upgrades = {}


## Czemu wymiany u kupca nie da się zrobić ("" - da się): "price" (za mało run), "none" (nie ma takiej oferty).
func shop_problem(index: int) -> String:
	if index < 0 or index >= Shop.offers().size():
		return "none"
	var offer: Dictionary = Shop.offers()[index]
	if int(runes.get(offer.pay, 0)) < offer.cost:
		return "price"
	return ""


## Wymiana u kupca (Shop.offers): oddaje `cost` run `pay`, dostaje `count` sztuk `item` (runa albo klucz / dłuto do
## sakwy). Zwraca false, gdy się nie da.
func buy_offer(index: int) -> bool:
	if shop_problem(index) != "":
		return false
	var offer: Dictionary = Shop.offers()[index]
	runes[offer.pay] = int(runes[offer.pay]) - offer.cost
	if runes[offer.pay] <= 0:
		runes.erase(offer.pay)
	if Runes.valid(offer.item):
		runes[offer.item] = int(runes.get(offer.item, 0)) + offer.count
	else:
		add_gem(offer.item, offer.count, false)
	save_game()
	inventory_changed.emit()
	return true


## Kowal: używa runy `id` na przedmiocie (z torby albo założonego - zmienia się w miejscu; `index` - wybrana premia
## dla Run Szlifu, Przekucia i Pieczęci). Zużywa jedną runę. Zwraca false, gdy brak runy albo nie da się jej użyć.
func use_rune(item: Dictionary, id: String, index := -1) -> bool:
	if int(runes.get(id, 0)) <= 0 or not Runes.apply(item, id, index):
		return false
	runes[id] = int(runes[id]) - 1
	if runes[id] <= 0:
		runes.erase(id)
	save_game()
	inventory_changed.emit()
	return true


## Runy z lochu (łup) - zapis przy najbliższym `save_if_dirty`.
func add_rune(id: String, amount := 1) -> void:
	if not Runes.valid(id) or amount <= 0:
		return
	runes[id] = int(runes.get(id, 0)) + amount
	_dirty = true
	inventory_changed.emit()


## Tryb deweloperski: po 5 sztuk każdej runy.
func dev_runes() -> void:
	for id in Runes.ORDER:
		runes[id] = int(runes.get(id, 0)) + 5
	save_game()
	inventory_changed.emit()


# --- rynek (Market) ---

## Czy postać może handlować na targu (bez SSF).
func market_open() -> bool:
	return not ssf


## Nadrabia czas rynku od ostatniej chwili (też offline, najwyżej Market.OFFLINE_MAX; cofnięty zegar - nic).
## Pierwszy raz zakłada rynek. Szlify za sprzedane oferty gracza trafiają od razu do zapasu. Zwraca liczbę chwil.
func market_catch_up() -> int:
	if not market_open():
		return 0
	var now: float = market_clock.call()
	if market.is_empty():
		market = Market.fresh(maxi(best_level, 1), now)
		save_game()
		return 0
	if now < float(market.time):
		market.time = now
		return 0
	var n := Market.ticks_between(float(market.time), now)
	if n <= 0:
		return 0
	var earned := 0
	for i in n:
		earned += Market.tick(market, maxi(best_level, 1))
	# po długiej przerwie (ponad OFFLINE_MAX) reszta czasu przepada - zegar rynku dogania teraz
	market.time = now if now - float(market.time) > Market.OFFLINE_MAX else float(market.time) + n * Market.TICK
	if earned > 0:
		runes[Runes.POLISH] = int(runes.get(Runes.POLISH, 0)) + earned
	save_game()
	inventory_changed.emit()
	return n


## Ile sztuk towaru giełdy ma gracz (runy, ruda, odpryski, klucze, dłuta, pieczęcie).
func market_have(id: String) -> int:
	match id:
		"ore":
			return ore
		"shards":
			return shards
	return int(runes.get(id, 0)) if Runes.valid(id) else gem_count(id)


## Dodaje (`amount` > 0) albo zabiera towar giełdy.
func _market_give(id: String, amount: int) -> void:
	match id:
		"ore":
			ore += amount
		"shards":
			shards += amount
		_:
			if Runes.valid(id):
				runes[id] = int(runes.get(id, 0)) + amount
				if runes[id] <= 0:
					runes.erase(id)
			elif amount > 0:
				add_gem(id, amount, false)
			else:
				for i in -amount:
					_take_gem(id)


## Ile Szlifów gracz może wydać: Szlify i inne runy po cenie skupu (bez `exclude` - towaru, który właśnie kupuje).
func market_wealth(exclude := "") -> int:
	var total := int(runes.get(Runes.POLISH, 0))
	for id in runes:
		if id != Runes.POLISH and id != exclude and market.get("prices", {}).has(id):
			total += Market.bid(market.prices[id], id) * int(runes[id])
	return total


## Płaci `cost` Szlifów: najpierw Szlifami, a brakujące sprzedaje inne runy (od najtańszej, bez `exclude`) po cenie
## skupu - reszta zostaje w Szlifach. Zwraca false (nic nie zmienia), gdy nie starcza.
func market_pay(cost: int, exclude := "") -> bool:
	if market_wealth(exclude) < cost:
		return false
	var cheap: Array = runes.keys().filter(func(id: String) -> bool:
		return id != Runes.POLISH and id != exclude and market.prices.has(id))
	cheap.sort_custom(func(a: String, b: String) -> bool: return market.prices[a] < market.prices[b])
	for id in cheap:
		while int(runes.get(Runes.POLISH, 0)) < cost and int(runes.get(id, 0)) > 0:
			_market_give(id, -1)
			runes[Runes.POLISH] = int(runes.get(Runes.POLISH, 0)) + Market.bid(market.prices[id], id)
	runes[Runes.POLISH] = int(runes.get(Runes.POLISH, 0)) - cost
	if runes[Runes.POLISH] <= 0:
		runes.erase(Runes.POLISH)
	return true


## Kupuje paczkę towaru `id` z giełdy (cena rośnie o Market.PUSH). Zwraca false, gdy nie starcza run.
func market_buy(id: String) -> bool:
	if not market_open() or not Market.COMMODITIES.has(id) or market.is_empty():
		return false
	if not market_pay(Market.ask(market.prices[id], id), id):
		return false
	_market_give(id, Market.pack_of(id))
	market.prices[id] = float(market.prices[id]) * (1.0 + Market.PUSH)
	save_game()
	inventory_changed.emit()
	return true


## Sprzedaje paczkę towaru `id` na giełdzie za Szlify (cena spada o Market.PUSH). Zwraca false, gdy brak towaru.
func market_sell(id: String) -> bool:
	if not market_open() or not Market.COMMODITIES.has(id) or market.is_empty() or market_have(id) < Market.pack_of(id):
		return false
	_market_give(id, -Market.pack_of(id))
	runes[Runes.POLISH] = int(runes.get(Runes.POLISH, 0)) + Market.bid(market.prices[id], id)
	market.prices[id] = float(market.prices[id]) * (1.0 - Market.PUSH)
	save_game()
	inventory_changed.emit()
	return true


## Czemu nie da się kupić oferty `index` ("" - da się): "price" (za mało run), "bag" (pełna torba), "none".
func market_listing_problem(index: int) -> String:
	if market.is_empty() or index < 0 or index >= market.listings.size():
		return "none"
	var l: Dictionary = market.listings[index]
	if not l.loot.has("gem") and not l.loot.has("talisman") and bag.size() >= BAG_SIZE:
		return "bag"
	if market_wealth() < int(l.price):
		return "price"
	return ""


## Kupuje ofertę innego gracza: przedmiot do torby, kamień do sakwy, talizman od razu (poziom wyżej przy duplikacie).
func market_buy_listing(index: int) -> bool:
	if market_listing_problem(index) != "" or not market_pay(int(market.listings[index].price)):
		return false
	var loot: Dictionary = market.listings[index].loot
	market.listings.remove_at(index)
	if loot.has("gem"):
		add_gem(loot.gem, 1, false)
	elif loot.has("talisman"):
		add_talisman(loot.talisman)
	else:
		bag.append(loot)
	save_game()
	inventory_changed.emit()
	return true


## Wystawia na targu przedmiot z torby (`bag_index`) albo kamień z sakwy (`gem`) za `price` Szlifów. Kamienie z gniazd
## przedmiotu wracają do sakwy. Zwraca false, gdy brak miejsca (Market.MINE_MAX) albo rzeczy.
func market_list(price: int, bag_index := -1, gem := "") -> bool:
	if not market_open() or market.is_empty() or market.mine.size() >= Market.MINE_MAX or price <= 0:
		return false
	var loot := {}
	if bag_index >= 0:
		if bag_index >= bag.size():
			return false
		loot = bag[bag_index]
		_return_item_gems(loot)
		var empty: Array = []
		for i in loot.get("sockets", []).size():
			empty.append("")
		loot.sockets = empty
		bag.remove_at(bag_index)
	elif gem != "" and Gems.can_shatter(gem) and _take_gem(gem):
		loot = {"gem": gem}
	else:
		return false
	market.mine.append({"loot": loot, "price": price, "seller": char_name, "age": 0})
	save_game()
	inventory_changed.emit()
	return true


## Zdejmuje własną ofertę z targu: przedmiot wraca do torby (pełna torba - false), kamień do sakwy.
func market_unlist(index: int) -> bool:
	if market.is_empty() or index < 0 or index >= market.mine.size():
		return false
	var loot: Dictionary = market.mine[index].loot
	if loot.has("gem"):
		add_gem(loot.gem, 1, false)
	elif bag.size() >= BAG_SIZE:
		return false
	else:
		bag.append(loot)
	market.mine.remove_at(index)
	save_game()
	inventory_changed.emit()
	return true

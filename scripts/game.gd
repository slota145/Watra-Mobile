extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen, ścieżka zapisu i ustawienia gracza.
## Ustawienia (np. przyciski po lewej) leżą osobno od zapisu gry, w user://settings.cfg.
## Zapis gry (JSON w `save_path`): żar zgromadzony w Watrze (`embers`), najwyższy przebity poziom lochu (`best_level`)
## i postać - poziom i doświadczenie (`hero_level`, `hero_xp`; dane poziomów w HeroLevels), przedmioty w torbie
## (`bag`, najwyżej BAG_SIZE), założone (`equipped`: miejsce -> przedmiot) i złoto ze sprzedaży (`gold`; dane w Items),
## skrzynia w bazie (`stash`: zakładki po STASH_TAB_SIZE miejsc; kolejne zakładki za złoto - STASH_TAB_PRICES),
## broń i mistrzostwo (`weapon`, `mastery` - broń -> poziom, `mastery_xp`; dane w Weapons), umiejętności
## (`skills_owned` - odblokowane, `skill_slots` - co stoi w miejscach, `skill_levels` - poziomy; dane w Skills), kamienie (Gems):
## sakwa (`gems`: identyfikator -> ile sztuk), kamienie w umiejętnościach (`skill_gems`: umiejętność -> lista
## Gems.SKILL_SOCKETS identyfikatorów, "" - puste) i otwarte gniazda (`skill_open`); kamienie w przedmiotach
## leżą w samych przedmiotach ("sockets"). Baza (ustalone 12.11.2026): ulepszenia lochów za złoto (`upgrades`:
## identyfikator DungeonUpgrades -> kupione stopnie), półka kupca (`shop`: oferty Shop, `shop_ready` - był już towar;
## odnawia się po każdym pokonanym bossie) i kowal (`reroll` - przeróbka jednej premii przedmiotu za złoto).
## Żywioły i mistrzostwo (13.11.2026): umiejętności odblokowuje mistrzostwo broni, ulepsza się je żarem, a ulepszenia
## lochów kupuje się złotem. Stary zapis (bez `mastery`) przechodzi raz (`_migrate_mastery`): mistrzostwo miecza = poziom
## postaci, kupione umiejętności i poziomy zostają, a wydane na nie złoto i żar wydany na ulepszenia lochów wracają.

## Zmiana doświadczenia: `xp` na obecnym poziomie, `need` - ile trzeba do awansu (0 na najwyższym poziomie).
signal xp_changed(level: int, xp: int, need: int)
## Awans postaci na poziom `level` (przy kilku awansach naraz - raz, z ostatnim poziomem).
signal leveled_up(level: int)
## Zmiana torby, założonych przedmiotów albo złota.
signal inventory_changed
## Odblokowanie lub ulepszenie umiejętności albo zmiana miejsc umiejętności.
signal skills_changed
## Zmiana mistrzostwa obecnej broni: poziom, doświadczenie na nim i ile trzeba do następnego (0 na najwyższym).
signal mastery_changed(level: int, xp: int, need: int)
## Mistrzostwo odblokowało umiejętność (arena pokazuje napis nad postacią).
signal skill_unlocked(id: String)
## Zmiana żaru w Watrze (ulepszenie umiejętności, żar z lochu).
signal embers_changed

## Miejsca w torbie (siatka 5x4 w oknie „Postać”).
const BAG_SIZE := 20
## Skrzynia w bazie: miejsca w zakładce i ceny kolejnych zakładek (pierwsza za darmo; razem najwyżej 5).
const STASH_TAB_SIZE := 20
const STASH_TAB_PRICES := [100, 300, 800, 2000]

const MENU_SCENE := "res://scenes/main_menu.tscn"
## Zapis gracza. Testy podmieniają go na osobny plik, żeby nie ruszać prawdziwego zapisu.
const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"

## Testy ustawiają osobny plik zapisu - wtedy ustawienia też idą do osobnego pliku.
var save_path := SAVE_PATH:
	set(value):
		save_path = value
		settings_path = SETTINGS_PATH if value == SAVE_PATH else TEST_SETTINGS_PATH
		load_settings()
		load_game()
var settings_path := SETTINGS_PATH
## Żar zgromadzony w Watrze (z iskier zebranych w lochach i doniesionych do bazy).
var embers := 0
## Żar doniesiony z ostatniego lochu - baza pokazuje go nad Watrą i zeruje.
var embers_brought := 0
## Najwyższy poziom lochu, na którym pokonano bossa (0 - jeszcze żaden). Odblokowany jest o jeden wyższy.
var best_level := 0
## Poziom lochu wybrany przy Watrze (na niego wchodzi scena lochu).
var dungeon_level := 1
## Poziom postaci i doświadczenie zebrane na tym poziomie.
var hero_level := 1
var hero_xp := 0
## Przedmioty w torbie (kolejność jak w siatce) i założone (miejsce -> przedmiot) - słowniki z Items.roll.
var bag: Array = []
var equipped := {}
var gold := 0
## Skrzynia w bazie: lista zakładek, każda to lista przedmiotów (najwyżej STASH_TAB_SIZE).
var stash: Array = [[]]
## Broń w ręku (Weapons) i mistrzostwo każdej broni (broń -> poziom; brak wpisu - 1. poziom) z doświadczeniem.
var weapon := Weapons.SWORD
var mastery := {}
var mastery_xp := {}
## Odblokowane umiejętności (identyfikatory ze Skills; zwykły cios zawsze) i co stoi w miejscach
## (Skills.SLOTS; 0 - duży przycisk, "" - puste miejsce).
var skills_owned: Array = [Skills.STRIKE]
var skill_slots: Array = _default_slots()
## Poziomy umiejętności (umiejętność -> poziom 2-Skills.MAX_LEVEL; brak wpisu - 1. poziom).
var skill_levels := {}
## Sakwa z kamieniami, kluczami i dłutami (identyfikator Gems -> liczba sztuk).
var gems := {}
## Kamienie w gniazdach umiejętności i liczba otwartych gniazd (brak wpisu - Gems.SKILL_OPEN).
var skill_gems := {}
var skill_open := {}
## Ulepszenia lochów za złoto (identyfikator DungeonUpgrades -> stopień).
var upgrades := {}
## Półka kupca (oferty Shop) i czy był już na niej towar (pierwszy przy pierwszym otwarciu).
var shop: Array = []
var shop_ready := false
## Doświadczenie dopisane od ostatniego zapisu (zapis przy końcu wyprawy, pauzie i przełączeniu aplikacji).
var _dirty := false
## Atak i umiejętności w lewym dolnym rogu (dla osób, które wolą trzymać je lewym kciukiem).
var left_handed := false
## Gest ręką postaci przy ataku (prototyp - porównanie wersji z gestem i bez).
var gesture := true
## Auto atak: umiejętność spod dużego przycisku (zwykle zwykły cios) rusza sama, gdy potwór jest w zasięgu.
var auto_attack := false
## Zwykłe przedmioty podniesione w lochu od razu zamieniają się w złoto (przełącznik w oknie „Postać”).
var auto_sell_common := false
## Tryb deweloperski (okno pauzy): nieśmiertelność - zdrowie schodzi, ale zamiast śmierci wraca do pełna.
var dev_immortal := false
## Tryb deweloperski: wybór dowolnego poziomu lochu (do DEV_MAX_LEVEL) bez przebijania poprzednich.
var dev_all_levels := false
## Tryb deweloperski: statystyki ustawione suwakiem (statystyka -> wartość) zamiast sumy z przedmiotów (Items.with_overrides).
var dev_stats := {}
const DEV_MAX_LEVEL := 100


func _ready() -> void:
	# jak w Watrze: gra startuje po polsku, niezależnie od języka telefonu (wybór języka dojdzie w ustawieniach)
	Lang.set_language(Lang.DEFAULT)
	load_settings()
	load_game()


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
	dev_immortal = cfg.get_value("dev", "immortal", false)
	dev_all_levels = cfg.get_value("dev", "all_levels", false)
	var raw_stats = cfg.get_value("dev", "stats", {})
	dev_stats = raw_stats if raw_stats is Dictionary else {}
	auto_sell_common = cfg.get_value("items", "auto_sell_common", false)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "gesture", gesture)
	cfg.set_value("controls", "auto_attack", auto_attack)
	cfg.set_value("dev", "immortal", dev_immortal)
	cfg.set_value("dev", "all_levels", dev_all_levels)
	cfg.set_value("dev", "stats", dev_stats)
	cfg.set_value("items", "auto_sell_common", auto_sell_common)
	cfg.save(settings_path)


func load_game() -> void:
	embers = 0
	embers_brought = 0
	best_level = 0
	dungeon_level = 1
	hero_level = 1
	hero_xp = 0
	bag = []
	equipped = {}
	gold = 0
	stash = [[]]
	weapon = Weapons.SWORD
	mastery = {}
	mastery_xp = {}
	skills_owned = [Skills.STRIKE]
	skill_slots = _default_slots()
	skill_levels = {}
	gems = {}
	skill_gems = {}
	skill_open = {}
	upgrades = {}
	shop = []
	shop_ready = false
	_dirty = false
	if not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		embers = int(data.get("embers", 0))
		best_level = int(data.get("best_level", 0))
		dungeon_level = clampi(int(data.get("dungeon_level", 1)), 1, unlocked_level())
		hero_level = clampi(int(data.get("hero_level", 1)), 1, HeroLevels.MAX_LEVEL)
		hero_xp = maxi(int(data.get("hero_xp", 0)), 0)
		gold = maxi(int(data.get("gold", 0)), 0)
		var raw_bag = data.get("bag", [])
		if raw_bag is Array:
			for raw in raw_bag:
				var item := Items.normalize(raw)
				if not item.is_empty() and bag.size() < BAG_SIZE:
					bag.append(item)
		var raw_stash = data.get("stash", [])
		if raw_stash is Array and not raw_stash.is_empty():
			stash = []
			for raw_tab in raw_stash.slice(0, STASH_TAB_PRICES.size() + 1):
				var tab: Array = []
				if raw_tab is Array:
					for raw in raw_tab:
						var item := Items.normalize(raw)
						if not item.is_empty() and tab.size() < STASH_TAB_SIZE:
							tab.append(item)
				stash.append(tab)
		var raw_weapon = data.get("weapon", Weapons.SWORD)
		weapon = raw_weapon if raw_weapon is String and Weapons.has(raw_weapon) else Weapons.SWORD
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
		var raw_slots = data.get("skill_slots", [])
		if raw_slots is Array and not raw_slots.is_empty():
			skill_slots = []
			for i in Skills.SLOTS:
				var id = raw_slots[i] if i < raw_slots.size() else ""
				var ok: bool = id is String and skills_owned.has(id) and not skill_slots.has(id) \
						and (i != Skills.MAIN or Skills.can_be_main(id))
				skill_slots.append(id if ok else "")
		var raw_levels = data.get("skill_levels", {})
		if raw_levels is Dictionary:
			for id in raw_levels:
				if skills_owned.has(id) and int(raw_levels[id]) > 1:
					skill_levels[id] = clampi(int(raw_levels[id]), 1, Skills.MAX_LEVEL)
		var raw_gems = data.get("gems", {})
		if raw_gems is Dictionary:
			for id in raw_gems:
				if Gems.valid(id) and int(raw_gems[id]) > 0:
					gems[id] = int(raw_gems[id])
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
			for slot in raw_eq:
				var item := Items.normalize(raw_eq[slot])
				if not item.is_empty() and item.slot == slot:
					equipped[slot] = item
		var raw_up = data.get("upgrades", {})
		if raw_up is Dictionary:
			for id in raw_up:
				if DungeonUpgrades.has(id) and int(raw_up[id]) > 0:
					upgrades[id] = clampi(int(raw_up[id]), 0, DungeonUpgrades.MAX_STEPS)
		shop_ready = bool(data.get("shop_ready", false))
		var raw_shop = data.get("shop", [])
		if raw_shop is Array:
			for raw in raw_shop:
				var offer := Shop.normalize(raw)
				if not offer.is_empty():
					shop.append(offer)
		if not data.has("mastery"):
			_migrate_mastery()
		_unlock_skills()


func save_game() -> void:
	_dirty = false
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"embers": embers, "best_level": best_level, "dungeon_level": dungeon_level,
				"hero_level": hero_level, "hero_xp": hero_xp, "gold": gold, "bag": bag, "equipped": equipped,
				"stash": stash, "weapon": weapon, "mastery": mastery, "mastery_xp": mastery_xp, "skills_owned": skills_owned, "skill_slots": skill_slots, "skill_levels": skill_levels, "gems": gems,
				"skill_gems": skill_gems, "skill_open": skill_open, "upgrades": upgrades, "shop": shop,
				"shop_ready": shop_ready}))


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


## Tryb deweloperski: postać od nowa (1. poziom, bez doświadczenia, przedmiotów i złota).
func reset_hero() -> void:
	hero_level = 1
	hero_xp = 0
	bag = []
	equipped = {}
	gold = 0
	stash = [[]]
	weapon = Weapons.SWORD
	mastery = {}
	mastery_xp = {}
	skills_owned = [Skills.STRIKE]
	skill_slots = _default_slots()
	skill_levels = {}
	gems = {}
	skill_gems = {}
	skill_open = {}
	save_game()
	mastery_changed.emit(mastery_level(), weapon_xp(), mastery_needed())
	xp_changed.emit(hero_level, hero_xp, xp_needed())
	inventory_changed.emit()
	skills_changed.emit()


## Suma cech założonych przedmiotów (Items.totals), w trybie deweloperskim z nadpisanymi statystykami (dev_stats).
func gear() -> Dictionary:
	return Items.with_overrides(Items.totals(equipped), dev_stats)


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


## Sprzedaje przedmiot z torby za złoto. Zwraca, ile złota dał.
func sell(index: int) -> int:
	if index < 0 or index >= bag.size():
		return 0
	var price := Items.sell_price(bag[index])
	_return_item_gems(bag[index])
	bag.remove_at(index)
	gold += price
	save_game()
	inventory_changed.emit()
	return price


## Ile złota dałaby sprzedaż wszystkich przedmiotów z torby o podanych rzadkościach (np. ["common"]).
func sell_all_price(rarities: Array) -> int:
	var total := 0
	for item in bag:
		if item.rarity in rarities:
			total += Items.sell_price(item)
	return total


## Sprzedaje wszystkie przedmioty z torby o podanych rzadkościach. Zwraca, ile złota dały.
func sell_all(rarities: Array) -> int:
	var total := sell_all_price(rarities)
	if total == 0:
		return 0
	for item in bag:
		if item.rarity in rarities:
			_return_item_gems(item)
	bag = bag.filter(func(item: Dictionary) -> bool: return not item.rarity in rarities)
	gold += total
	save_game()
	inventory_changed.emit()
	return total


## Złoto za przedmiot bez wkładania go do torby (auto sprzedaż, pełna torba przy skrzyni).
func sell_loot(item: Dictionary) -> int:
	var price := Items.sell_price(item)
	gold += price
	save_game()
	inventory_changed.emit()
	return price


## Cena następnej zakładki skrzyni (0 - kupiono już wszystkie).
func next_tab_price() -> int:
	var i := stash.size() - 1
	return STASH_TAB_PRICES[i] if i < STASH_TAB_PRICES.size() else 0


## Kupuje kolejną zakładkę skrzyni za złoto. Zwraca false, gdy brakuje złota albo kupiono wszystkie.
func buy_stash_tab() -> bool:
	var price := next_tab_price()
	if price == 0 or gold < price:
		return false
	gold -= price
	stash.append([])
	save_game()
	inventory_changed.emit()
	return true


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
	save_game()
	return true


## Miejsca na start: zwykły cios pod dużym przyciskiem, reszta pusta.
static func _default_slots() -> Array:
	var slots: Array = [Skills.STRIKE]
	for i in Skills.SLOTS - 1:
		slots.append("")
	return slots


# --- Mistrzostwo broni (Weapons) ---

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
	for id in upgrades:
		for step in upgrades[id]:
			embers += DungeonUpgrades.price(step)


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
	if not skills_owned.has(id) or not slot_open(slot) or (slot == Skills.MAIN and not Skills.can_be_main(id)):
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
	return id if id != "" else Skills.STRIKE


## Tryb deweloperski: wszystkie umiejętności bez wymaganego mistrzostwa.
func dev_skills() -> void:
	for id in Skills.ORDER:
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


## Kamienie w sakwie posortowane: najpierw klucze i dłuta, potem kamienie umiejętności, potem szlachetne;
## w rodzaju od najlepszego stopnia. `filter`: "support", "jewel" albo "" - wszystkie.
func gem_list(filter := "") -> Array:
	var out: Array = []
	for id in gems:
		if filter == "support" and not Gems.is_support(id) or filter == "jewel" and not Gems.is_jewel(id):
			continue
		out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return _gem_order(a) < _gem_order(b))
	return out


static func _gem_order(id: String) -> int:
	if Gems.is_special(id):
		return 0 if id == Gems.KEY else 1
	if Gems.is_unique(id):
		return 50 + Skills.ORDER.find(Gems.unique_skill(id))
	var kind := Gems.kind_of(id)
	var base := 100 + Gems.SUPPORT_ORDER.find(kind) * 10 if Gems.is_support(id) else 200 + Gems.JEWEL_ORDER.find(kind) * 10
	return base + (4 - Gems.grade_of(id))


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


## Tryb deweloperski: po kamieniu każdego rodzaju (stopień z obecnego poziomu lochu), kamienie unikalne, 2 klucze i 2 dłuta.
func dev_gems() -> void:
	var grade := Items.tier_for(dungeon_level)
	for kind in Gems.SUPPORT_ORDER:
		add_gem(Gems.make(kind, grade), 1, false)
	for kind in Gems.JEWEL_ORDER:
		add_gem(Gems.make(kind, grade), 1, false)
	for skill in Skills.ORDER:
		add_gem(Gems.unique_of(skill), 1, false)
	add_gem(Gems.KEY, 2, false)
	add_gem(Gems.CHISEL, 2, false)
	save_game()
	inventory_changed.emit()


# --- Baza: ulepszenia lochów, kupiec i kowal (złoto) ---

## Kupione stopnie ulepszenia lochów.
func upgrade_steps(id: String) -> int:
	return upgrades.get(id, 0)


## Premia ulepszenia lochów (procenty albo piksele - DungeonUpgrades.bonus).
func upgrade_bonus(id: String) -> float:
	return DungeonUpgrades.bonus(id, upgrade_steps(id))


## Cena następnego stopnia ulepszenia (0 - wszystkie kupione).
func upgrade_price(id: String) -> int:
	return DungeonUpgrades.price(upgrade_steps(id))


## Kupuje następny stopień ulepszenia za złoto (do 13.11.2026 za żar). Zwraca false, gdy brakuje złota albo
## kupiono wszystkie.
func buy_upgrade(id: String) -> bool:
	var price := upgrade_price(id)
	if not DungeonUpgrades.has(id) or price == 0 or gold < price:
		return false
	gold -= price
	upgrades[id] = upgrade_steps(id) + 1
	save_game()
	inventory_changed.emit()
	return true


## Półka kupca; przy pierwszym otwarciu dostaje pierwszy towar.
func shop_offers() -> Array:
	if not shop_ready:
		restock_shop()
	return shop


## Nowa dostawa u kupca (po pokonaniu bossa): przedmioty z najwyższego przebitego lochu (najmniej z `level`).
func restock_shop(level := 1) -> void:
	shop = Shop.stock(maxi(maxi(best_level, level), 1))
	shop_ready = true
	save_game()
	inventory_changed.emit()


## Czemu oferty nie da się kupić ("" - da się): "gold" (za mało złota), "bag" (pełna torba), "none" (nie ma jej).
func shop_problem(index: int) -> String:
	if index < 0 or index >= shop.size():
		return "none"
	if gold < shop[index].price:
		return "gold"
	if shop[index].has("item") and bag.size() >= BAG_SIZE:
		return "bag"
	return ""


## Kupuje ofertę z półki: kamień (klucz, dłuto) do sakwy, przedmiot do torby. Zwraca false, gdy się nie da.
func buy_offer(index: int) -> bool:
	if shop_problem(index) != "":
		return false
	var offer: Dictionary = shop[index]
	gold -= offer.price
	if offer.has("gem"):
		add_gem(offer.gem, 1, false)
	else:
		bag.append(offer.item)
	shop.remove_at(index)
	save_game()
	inventory_changed.emit()
	return true


## Kowal: przerabia premię `index` przedmiotu (z torby albo założonego - zmienia się w miejscu) za złoto.
## Zwraca false, gdy brakuje złota albo nie ma takiej premii.
func reroll(item: Dictionary, index: int) -> bool:
	if item.is_empty() or index < 0 or index >= item.affixes.size():
		return false
	var price := Items.reroll_price(item)
	if gold < price:
		return false
	gold -= price
	Items.reroll_affix(item, index)
	save_game()
	inventory_changed.emit()
	return true

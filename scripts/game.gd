extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen, ścieżka zapisu i ustawienia gracza.
## Ustawienia (np. przyciski po lewej) leżą osobno od zapisu gry, w user://settings.cfg.
## Zapis gry (JSON w `save_path`): żar zgromadzony w Watrze (`embers`), najwyższy przebity poziom lochu (`best_level`)
## i postać - poziom i doświadczenie (`hero_level`, `hero_xp`; dane poziomów w HeroLevels), przedmioty w torbie
## (`bag`, najwyżej BAG_SIZE), założone (`equipped`: miejsce -> przedmiot) i złoto ze sprzedaży (`gold`; dane w Items),
## skrzynia w bazie (`stash`: zakładki po STASH_TAB_SIZE miejsc; kolejne zakładki za złoto - STASH_TAB_PRICES).

## Zmiana doświadczenia: `xp` na obecnym poziomie, `need` - ile trzeba do awansu (0 na najwyższym poziomie).
signal xp_changed(level: int, xp: int, need: int)
## Awans postaci na poziom `level` (przy kilku awansach naraz - raz, z ostatnim poziomem).
signal leveled_up(level: int)
## Zmiana torby, założonych przedmiotów albo złota.
signal inventory_changed

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
## Doświadczenie dopisane od ostatniego zapisu (zapis przy końcu wyprawy, pauzie i przełączeniu aplikacji).
var _dirty := false
## Atak i umiejętności w lewym dolnym rogu (dla osób, które wolą trzymać je lewym kciukiem).
var left_handed := false
## Gest ręką postaci przy ataku (prototyp - porównanie wersji z gestem i bez).
var gesture := true
## Auto atak: podstawowy cios sam tnie, gdy potwór jest w zasięgu (umiejętności - nie).
var auto_attack := false
## Zwykłe przedmioty podniesione w lochu od razu zamieniają się w złoto (przełącznik w oknie „Postać”).
var auto_sell_common := false
## Tryb deweloperski (okno pauzy): nieśmiertelność - zdrowie schodzi, ale zamiast śmierci wraca do pełna.
var dev_immortal := false


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
	auto_sell_common = cfg.get_value("items", "auto_sell_common", false)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "gesture", gesture)
	cfg.set_value("controls", "auto_attack", auto_attack)
	cfg.set_value("dev", "immortal", dev_immortal)
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
		var raw_eq = data.get("equipped", {})
		if raw_eq is Dictionary:
			for slot in raw_eq:
				var item := Items.normalize(raw_eq[slot])
				if not item.is_empty() and item.slot == slot:
					equipped[slot] = item


func save_game() -> void:
	_dirty = false
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"embers": embers, "best_level": best_level, "dungeon_level": dungeon_level,
				"hero_level": hero_level, "hero_xp": hero_xp, "gold": gold, "bag": bag, "equipped": equipped,
				"stash": stash}))


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
	save_game()
	xp_changed.emit(hero_level, hero_xp, xp_needed())
	inventory_changed.emit()


## Suma cech założonych przedmiotów (Items.totals).
func gear() -> Dictionary:
	return Items.totals(equipped)


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
func unlocked_level() -> int:
	return best_level + 1


## Boss pokonany na poziomie `level` - odblokowuje następny (zapis od razu). Zwraca true, gdy to nowy rekord.
func beat_level(level: int) -> bool:
	if level <= best_level:
		return false
	best_level = level
	save_game()
	return true

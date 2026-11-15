extends SceneTree
## Test kamieni (Gems): dane i łup (od 3. poziomu lochu), sakwa, gniazda umiejętności (2 otwarte z 5, Klucz Runiczny,
## jeden rodzaj raz, wyjmowanie za darmo), gniazda przedmiotów (premia według miejsca, Dłuto Jubilera, stare zapisy,
## sprzedaż oddaje kamienie), zapis, działanie w walce (koszt many, odnowienie, podpalenie, spowolnienie, leczenie,
## piorun, Mnożenie, Szerokość), podnoszenie kamienia z ziemi, okno umiejętności (zakładka „Kamienie”) i okno „Postać”.

var _failed := 0
## Kamienie szlachetne do testów (premie zapisane w identyfikatorze).
var RUBY := Gems.make_jewel("ruby", 5, [["hp", 20], ["damage_pct", 5]])
var SAPPHIRE := Gems.make_jewel("sapphire", 3, [["mana", 12], ["xp_pct", 4]])
var ONYX := Gems.make_jewel("onyx", 4, [["protection_pct", 2], ["regen", 0.6]])


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	_test_data()
	_test_skill_sockets(game)
	_test_item_sockets(game)
	_test_upgrade_sell(game)
	await _test_combat(game)
	await _test_windows(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Gems.SUPPORT_ORDER.size() == 8 and Gems.JEWEL_ORDER.size() == 4, "8 kamieni umiejętności i 4 szlachetne")
	for kind in Gems.SUPPORT_ORDER:
		_check(Gems.SUPPORT[kind].values.size() == 2 and Gems.icon_of(Gems.make(kind)) != null, "kamień %s: siła 1. i 10. poziomu, ikona" % kind)
	for kind in Gems.JEWEL_ORDER:
		_check(Gems.JEWELS[kind].pool.size() >= Gems.JEWEL_MAX and Gems.icon_of(Gems.roll_jewel(kind, 5, 5)) != null,
				"kamień %s: pula premii i ikona z 5 premiami" % kind)
	_check(Gems.icon_of(Gems.KEY) != null and Gems.icon_of(Gems.CHISEL) != null, "ikony klucza i dłuta")
	_check(Gems.make("ember", 99) == "ember:10" and Gems.make("ember") == "ember:1" and Gems.level_of("ember:3") == 3
			and Gems.kind_of("ember:3") == "ember", "identyfikator rodzaj:poziom")
	_check(Gems.valid(RUBY) and Gems.valid(Gems.KEY) and not Gems.valid("bzdura:1") and not Gems.valid(3)
			and not Gems.valid("ruby:2") and not Gems.valid("ember:0") and not Gems.valid("ember:11"),
			"sprawdzanie identyfikatorów z zapisu (stare kamienie szlachetne ze stopniem odpadają)")
	_check(Gems.name_of("ember:2") == "Żar" and Gems.kind_line("ember:2").contains("2/10"), "nazwa bez stopnia, poziom w opisie")
	_check(Gems.jewel_stats(RUBY) == [["hp", 20.0], ["damage_pct", 5.0]] and Gems.level_of(RUBY) == 2
			and Gems.jewel_level(RUBY) == 5 and Gems.jewel_text(RUBY).contains("zdrowia"), "rubin: premie w identyfikatorze")
	_check(Gems.support_text("multi:1", "throw").contains("3 miecze"), "opis kamienia zależy od umiejętności")
	_check(Gems.support_value("ember:1") == 20.0 and Gems.support_value("ember:10") == 115.0
			and Gems.support_value("ember:5") > Gems.support_value("ember:4"), "siła rośnie z poziomem (Żar 20% -> 115%)")
	# premie szlachetnych: 2-3 z puli rodzaju, bez powtórek
	var counts := {2: 0, 3: 0}
	var pool_ok := true
	for i in 400:
		var j := Gems.roll_jewel("emerald", 8)
		var stats := Gems.jewel_stats(j)
		counts[stats.size()] = counts.get(stats.size(), 0) + 1
		var seen := {}
		for st in stats:
			pool_ok = pool_ok and Gems.JEWELS.emerald.pool.has(st[0]) and not seen.has(st[0]) and st[1] > 0.0
			seen[st[0]] = true
	_check(pool_ok and counts[2] > 200 and counts[3] > 80 and counts.size() == 2,
			"szlachetny wypada z 2-3 różnymi premiami z puli (%d / %d)" % [counts[2], counts[3]])
	# ulepszanie: koszt, kamień umiejętności o poziom wyżej, szlachetny z nową premią
	_check(Gems.upgrade_cost("ember:1") == Vector2i(80, 2) and Gems.upgrade_cost("ember:9").x > 1000
			and Gems.upgrade_cost("ember:10") == Vector2i.ZERO, "koszt ulepszenia rośnie, 10. poziom to koniec")
	_check(Gems.upgraded("ember:4") == "ember:5" and not Gems.can_upgrade(Gems.unique_of("strike")), "ulepszenie kamienia umiejętności")
	var up := Gems.upgraded(RUBY)
	_check(Gems.level_of(up) == 3 and Gems.jewel_stats(up).slice(0, 2) == Gems.jewel_stats(RUBY), "ulepszenie dokłada premię szlachetnemu")
	var full := Gems.roll_jewel("onyx", 5, 5)
	_check(not Gems.can_upgrade(full) and Gems.upgrade_cost(full) == Vector2i.ZERO, "najwyżej 5 premii")
	_check(Gems.sell_price("ember:5") > Gems.sell_price("ember:1") and Gems.shard_value("ember:5") > Gems.shard_value("ember:1")
			and Gems.sell_price(Gems.KEY) == 0 and not Gems.can_sell(Gems.CHISEL), "sprzedaż i odpryski rosną z ulepszeniem; klucz nie na sprzedaż")
	var low := true
	for i in 300:
		low = low and Gems.roll_goblin(2) == "" and Gems.roll_chest(2).is_empty()
	_check(low, "poniżej 3. poziomu lochu kamienie nie wypadają")
	var gems := 0
	var levels_ok := true
	for i in 300:
		for id in Gems.roll_chest(10):
			if not Gems.is_special(id) and not Gems.is_unique(id):
				gems += 1
				levels_ok = levels_ok and (Gems.level_of(id) == 1 if Gems.is_support(id) else Gems.jewel_level(id) == 10)
	_check(gems > 200 and levels_ok, "skrzynia Wodza zwykle daje kamień (umiejętności - 1. poziom, szlachetny z poziomu lochu) (%d)" % gems)
	# kamienie unikalne
	var ok := true
	for skill in Gems.UNIQUE:  # hydrosfera - kamienie unikalne później
		var u := Gems.unique_of(skill)
		ok = ok and Gems.is_unique(u) and Gems.is_support(u) and Gems.valid(u) and Gems.icon_of(u) != null \
				and Gems.unique_skill(u) == skill and Gems.name_of(u) != "" and Gems.short_text(u, skill) != ""
	_check(ok, "kamienie unikalne: po jednym na umiejętność, z ikoną i opisem")
	_check(Gems.support_text(Gems.unique_of("whirl"), "throw").contains(Skills.name_of("whirl")),
			"opis unikalnego w cudzej umiejętności mówi, do czego pasuje")
	var uniques := 0
	var low_unique := 0
	for i in 2000:
		for id in Gems.roll_chest(10):
			uniques += 1 if Gems.is_unique(id) else 0
		for id in Gems.roll_chest(4):
			low_unique += 1 if Gems.is_unique(id) else 0
	_check(uniques > 40 and uniques < 300 and low_unique == 0,
			"unikalne rzadko ze skrzyni (%d na 2000 na poz. 10), poniżej 5. poziomu lochu nie" % uniques)


func _test_skill_sockets(game: Node) -> void:
	game.reset_hero()
	_check(game.skill_open_count("strike") == 2 and game.skill_sockets("strike") == ["", "", "", "", ""],
			"umiejętność: 5 gniazd, otwarte 2")
	game.add_gem("ember:2")
	game.add_gem("ember:5")
	game.add_gem("rime:1", 2)
	_check(game.gem_count("rime:1") == 2 and game.gem_list().front() == "ember:5", "sakwa liczy sztuki, lepszy stopień wyżej")
	_check(game.skill_socket_problem("whirl", 0, "ember:2") == "owned", "niekupiona umiejętność nie przyjmie kamienia")
	_check(game.skill_socket_problem("strike", 2, "ember:2") == "locked", "zamknięte gniazdo nie przyjmie kamienia")
	_check(game.socket_skill("strike", 0, "ember:2") and game.gem_count("ember:2") == 0, "kamień wchodzi w gniazdo")
	_check(game.skill_socket_problem("strike", 1, "ember:5") == "same", "ten sam rodzaj drugi raz się nie zmieści")
	_check(game.socket_skill("strike", 0, "ember:5") and game.gem_count("ember:2") == 1 and game.skill_sockets("strike")[0] == "ember:5",
			"lepszy kamień w to samo gniazdo - stary wraca do sakwy")
	_check(game.socket_skill("strike", 1, "rime:1") and game.gem_count("rime:1") == 1, "drugie gniazdo")
	_check(not game.open_skill_socket("strike"), "bez klucza gniazdo się nie otworzy")
	game.add_gem(Gems.KEY, 3)
	_check(game.open_skill_socket("strike") and game.skill_open_count("strike") == 3 and game.gem_count(Gems.KEY) == 2,
			"Klucz Runiczny otwiera 3. gniazdo")
	game.open_skill_socket("strike")
	game.open_skill_socket("strike")
	_check(game.skill_open_count("strike") == 5 and game.gem_count(Gems.KEY) == 0, "wszystkie 5 gniazd za 3 klucze")
	game.add_gem(Gems.KEY)
	_check(not game.open_skill_socket("strike") and game.gem_count(Gems.KEY) == 1, "szóstego gniazda nie ma")
	game.load_game()
	_check(game.skill_sockets("strike") == ["ember:5", "rime:1", "", "", ""] and game.skill_open_count("strike") == 5
			and game.gem_count("ember:2") == 1 and game.gem_count(Gems.KEY) == 1, "gniazda i sakwa w zapisie")
	_check(game.unsocket_skill("strike", 0) and game.gem_count("ember:5") == 1 and game.skill_sockets("strike")[0] == "",
			"wyjęcie za darmo - kamień wraca do sakwy")
	game.add_gem(Gems.unique_of("whirl"))
	game.add_gem(Gems.unique_of("strike"))
	_check(game.skill_socket_problem("strike", 2, Gems.unique_of("whirl")) == "skill", "unikalny Młynka nie pasuje do zwykłego ciosu")
	_check(game.socket_skill("strike", 2, Gems.unique_of("strike")) and Gems.has_unique(game.skill_sockets("strike"), "strike"),
			"unikalny zwykłego ciosu w zwykłym gnieździe")
	_check(game.gem_list("support").front() == Gems.unique_of("whirl"), "unikalne na początku listy kamieni umiejętności")
	game.load_game()
	_check(game.skill_sockets("strike")[2] == Gems.unique_of("strike") and game.gem_count(Gems.unique_of("whirl")) == 1,
			"unikalny w zapisie")
	game.reset_hero()
	_check(game.gems.is_empty() and game.skill_gems.is_empty() and game.skill_open.is_empty(), "postać od nowa zeruje kamienie")


func _test_item_sockets(game: Node) -> void:
	game.reset_hero()
	var item := Items.roll(5, "helmet", "magic")
	_check(item.sockets.size() >= 1 and item.sockets[0] == "", "nowy przedmiot ma puste gniazdo")
	var old := Items.normalize({"slot": "helmet", "rarity": "common", "tier": 0, "level": 1, "base": {"hp": 8}, "affixes": []})
	_check(old.sockets == [""], "stary zapis dostaje jedno gniazdo")
	var bad := Items.normalize({"slot": "helmet", "rarity": "common", "base": {}, "affixes": [], "sockets": ["ember:2", RUBY, "x", "y"]})
	_check(bad.sockets == ["", RUBY], "w przedmiocie tylko kamienie szlachetne, najwyżej 2 gniazda")
	var second := 0
	for i in 2000:
		if Items.roll(5, "", "rare").sockets.size() == 2:
			second += 1
	_check(second > 10 and second < 150, "drugie gniazdo bardzo rzadko (%d / 2000 rzadkich)" % second)
	item.sockets = [""]
	game.bag = [item]
	game.equip(0)
	var hp_before: float = game.gear().hp
	game.add_gem(RUBY)
	_check(game.socket_item(game.equipped.helmet, 0, RUBY) and game.gem_count(RUBY) == 0, "rubin w hełmie")
	_check(is_equal_approx(game.gear().hp, hp_before + 20.0) and game.gear().damage_pct >= 5.0,
			"rubin w hełmie daje swoje premie")
	_check(not game.socket_item(game.equipped.helmet, 0, "ember:2"), "kamień umiejętności nie wejdzie w przedmiot")
	_check(not game.add_socket(game.equipped.helmet), "bez dłuta nie ma drugiego gniazda")
	game.add_gem(Gems.CHISEL, 2)
	_check(game.add_socket(game.equipped.helmet) and game.equipped.helmet.sockets.size() == 2 and game.gem_count(Gems.CHISEL) == 1,
			"Dłuto Jubilera dorabia drugie gniazdo")
	_check(not game.add_socket(game.equipped.helmet) and game.gem_count(Gems.CHISEL) == 1, "trzeciego gniazda nie ma")
	game.load_game()
	_check(game.equipped.helmet.sockets == [RUBY, ""], "kamienie przedmiotu w zapisie")
	_check(game.unequip("helmet"), "zdjęcie hełmu z kamieniem")
	game.sell(0)
	_check(game.gem_count(RUBY) == 1, "sprzedaż przedmiotu oddaje kamień do sakwy")
	var it2 := Items.roll(3, "ring", "common")
	it2.sockets = [""]
	game.bag = [it2]
	game.socket_item(game.bag[0], 0, RUBY)
	game.sell_all(["common"])
	_check(game.gem_count(RUBY) == 1 and game.bag.is_empty(), "sprzedaż hurtem też oddaje kamienie")
	game.reset_hero()


## Ulepszanie (sakwa, gniazdo umiejętności, gniazdo przedmiotu), sprzedaż i rozbijanie, sortowanie i filtr sakwy.
func _test_upgrade_sell(game: Node) -> void:
	game.reset_hero()
	game.add_gem("ember:1", 2)
	_check(game.upgrade_gem("ember:1") == "", "bez złota i odprysków nie ma ulepszenia")
	game.gold = 1000
	game.shards = 10
	_check(game.upgrade_gem("ember:1") == "ember:2" and game.gold == 920 and game.shards == 8
			and game.gem_count("ember:1") == 1 and game.gem_count("ember:2") == 1, "ulepszenie sztuki ze stosu: złoto i odpryski")
	game.socket_skill("strike", 0, "ember:2")
	_check(game.upgrade_gem("ember:2", "strike", {}, 0) == "ember:3" and game.skill_sockets("strike")[0] == "ember:3",
			"ulepszenie kamienia w gnieździe umiejętności")
	var item := Items.roll(5, "helmet", "magic")
	item.sockets = [RUBY]
	game.bag = [item]
	game.gold = 5000
	game.shards = 50
	var up: String = game.upgrade_gem(RUBY, "", game.bag[0], 0)
	_check(Gems.level_of(up) == 3 and game.bag[0].sockets[0] == up, "ulepszenie kamienia w gnieździe przedmiotu")
	game.load_game()
	_check(game.shards == 45, "odpryski w zapisie (%d)" % game.shards)
	_check(game.skill_sockets("strike")[0] == "ember:3" and game.bag[0].sockets[0] == up, "ulepszone kamienie w zapisie")
	# sprzedaż i rozbijanie
	game.add_gem("rime:1", 3)
	game.add_gem(ONYX)
	game.add_gem(Gems.KEY)
	var gold: int = game.gold
	var got: Vector2i = game.sell_gems(["rime:1", Gems.KEY])
	_check(got.x == Gems.sell_price("rime:1") * 3 and game.gold == gold + got.x and game.gem_count("rime:1") == 0
			and game.gem_count(Gems.KEY) == 1, "sprzedaż kilku naraz: cały stos, klucz zostaje")
	var shards: int = game.shards
	got = game.sell_gems([ONYX], true)
	_check(got.y == Gems.shard_value(ONYX) and game.shards == shards + got.y and game.gem_count(ONYX) == 0, "rozbicie na odpryski")
	game.add_gem("haste:1", 2)
	_check(game.sell_gem("haste:1", true).y == Gems.SHATTER_BASE and game.gem_count("haste:1") == 1, "rozbicie jednej sztuki")
	# sortowanie i filtr poziomu
	game.gems = {}
	for id in ["ember:2", "ember:9", "area:5", RUBY, Gems.KEY, Gems.unique_of("strike")]:
		game.add_gem(id, 1, false)
	var by_kind: Array = game.gem_list()
	_check(by_kind.front() == Gems.KEY and by_kind.find("ember:9") < by_kind.find("ember:2") and by_kind.back() == RUBY,
			"sortowanie po rodzaju: klucz, unikalne, umiejętności (wyższy poziom wyżej), szlachetne")
	var by_level: Array = game.gem_list("", "level")
	_check(by_level[0] == Gems.unique_of("strike") and by_level[1] == "ember:9" and by_level[2] == "area:5"
			and by_level.back() == Gems.KEY, "sortowanie po poziomie")
	_check(game.gem_list("", "kind", [4, 7]) == ["area:5"] and game.gem_list("jewel") == [RUBY]
			and game.gem_list("support", "kind", [1, 3]) == ["ember:2"], "filtr rodzaju i poziomu")
	game.reset_hero()


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.dev_skills()
	game.add_gem(Gems.KEY, 6)
	for s in ["strike", "strike", "strike", "whirl", "throw", "slam"]:
		game.open_skill_socket(s)
	for id in ["thrift:10", "haste:10", "ember:3", "rime:3", "leech:10", "discharge:10", "multi:10", "area:10"]:
		game.add_gem(id, 4)
	game.socket_skill("whirl", 0, "thrift:10")
	game.socket_skill("whirl", 1, "haste:10")
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	_check(weapon.skill_gems.has("whirl"), "miecz zna kamienie umiejętności")
	_check(weapon.mana_cost("whirl") == 14 and weapon.mana_cost("throw") == 15, "Oszczędność: Młynek za 14 zamiast 25 many")
	_check(is_equal_approx(weapon.cooldown_full("whirl"), 8.0 * 0.67), "Pośpiech: odnowienie krótsze o 33%")
	hero.position = Vector2(0, 200)
	await _wait(0.3)
	var mana := hero.mana
	_check(weapon.cast("whirl") and hero.mana == mana - 14 and weapon.cooldown_left("whirl") < 5.4, "Młynek płaci mniej i krócej się odnawia")
	await _wait(3.2)
	# podpalenie, spowolnienie, leczenie, mana, piorun - na zwykłym ciosie
	game.socket_skill("strike", 0, "ember:3")
	game.socket_skill("strike", 1, "rime:3")
	game.socket_skill("strike", 2, "leech:10")
	game.socket_skill("strike", 3, "discharge:10")
	game.socket_skill("strike", 4, "thrift:10")
	var g1 := _goblin(arena, hero.position + Vector2(200, 0))
	var g2 := _goblin(arena, hero.position + Vector2(230, 0))
	await process_frame
	hero.hp = 10
	hero.mana = 0
	var hp2 := g2.hp
	weapon._chained = false
	weapon.crit_chance = 0.0  # bez trafienia krytycznego - leczenie liczy się od równych 100 obrażeń
	weapon._deal(g1, 100, hero.global_position, "strike")
	_check(g2.hp < hp2, "Piorun przeskakuje na pobliskiego goblina")
	_check(hero.hp == 18 and hero.mana == Gems.thrift_mana(10), "Krwiopijca leczy 8%, Oszczędność oddaje manę")
	_check(g1.speed_factor() < 0.8, "Szron spowalnia")
	var hp1 := g1.hp
	await _wait(1.2)
	_check(g1.hp < hp1, "Żar podpala - goblin traci zdrowie bez ciosów (%d)" % (hp1 - g1.hp))
	await _wait(2.5)
	_check(g1.speed_factor() == 1.0 and g1.get_node_or_null(^"_Status") == null, "efekty wygasają")
	g1.queue_free()
	g2.queue_free()
	await process_frame
	# Mnożenie i Szerokość
	for i in 5:
		game.unsocket_skill("strike", i)
	game.socket_skill("strike", 0, "multi:10")
	game.socket_skill("slam", 0, "multi:10")
	game.socket_skill("throw", 0, "multi:10")
	game.socket_skill("whirl", 2, "area:10")
	_check(is_equal_approx(weapon._area("whirl"), 1.55), "Szerokość: +55% zasięgu")
	var dummy: ProtoDummy = weapon.targets[0]
	hero.position = dummy.position + Vector2(0, 20)
	await _wait(0.8)
	var count := dummy._count
	weapon.attack_held = true
	await _wait(0.2)
	weapon.attack_held = false
	await _wait(0.7)
	_check(dummy._count == count + 2, "Mnożenie: po cięciu pada drugie (%d)" % (dummy._count - count))
	await _wait(0.8)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	count = dummy._count
	weapon.cast("slam")
	await _wait(0.9)
	_check(dummy._count == count + 2, "Mnożenie: Rozłupanie robi drugą falę")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(0, 90)
	await _wait(0.3)
	weapon.cast("throw")
	await _wait(0.15)
	_check(weapon._ghosts[0].visible and weapon._ghosts[1].visible, "Mnożenie: przy Rzucie lecą widmowe miecze")
	await _wait(1.5)
	_check(not weapon._ghosts[0].visible, "widmowe miecze znikają po powrocie")
	# kamień na ziemi trafia do sakwy
	var have: int = game.gem_count(ONYX)
	var loot := ProtoLoot.new()
	loot.hero = hero
	loot.item = {"gem": ONYX}
	loot.position = hero.position + Vector2(10, 0)
	arena.get_node("World").add_child(loot)
	await _wait(1.0)
	_check(game.gem_count(ONYX) == have + 1, "kamień z ziemi trafia do sakwy")
	arena.queue_free()
	await process_frame
	game.reset_hero()


func _test_windows(game: Node) -> void:
	game.hero_level = 6
	game.dev_skills()
	game.add_gem("ember:1")
	game.add_gem("rime:1")
	game.add_gem(Gems.KEY)
	game.add_gem(SAPPHIRE)
	game.add_gem(Gems.CHISEL)
	var item := Items.roll(4, "earring", "rare")
	item.sockets = [""]
	game.bag = [item]
	game.equip(0)
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var win: SkillsWindow = arena.skills_window
	arena.open_skills()
	win.set_gems_mode(true)
	await process_frame
	_check(win.gems_box.visible and not win.slots_row.visible, "zakładka „Kamienie” pokazuje gniazda zamiast miejsc")
	_check(win.socket_slots.size() == 5 and win.socket_slots[2].locked and not win.socket_slots[1].locked,
			"5 gniazd, od trzeciego zamknięte")
	var small := false
	for s in win.socket_slots:
		small = small or s.custom_minimum_size.x < 44
	_check(not small, "gniazda co najmniej 44 px")
	win.list_icons[Skills.ORDER.find("throw")].pressed.emit()
	_check(win.gem_skill == "throw", "stuknięcie umiejętności wybiera jej gniazda")
	var pouch: Array = win.pouch_row.get_children()
	_check(pouch.size() == 3 and pouch[0].gem == Gems.KEY, "sakwa: klucz i 2 kamienie umiejętności")
	_check(win.socket_labels[0].text == "puste" and win.socket_labels[2].text == "zamknięte", "pod gniazdami: puste / zamknięte")
	# sakwa: tylko kamienie pasujące do umiejętności, jej kamień unikalny za złotą kreską (15.11.2026)
	game.add_gem(Gems.unique_of("throw"), 1, false)
	game.add_gem(Gems.unique_of("whirl"), 1, false)
	win.refresh()
	pouch = win.pouch_row.get_children()
	var gems_shown: Array = pouch.filter(func(c: Node) -> bool: return c is GemSlot).map(func(c: GemSlot) -> String: return c.gem)
	_check(gems_shown.has(Gems.unique_of("throw")) and not gems_shown.has(Gems.unique_of("whirl")) and pouch.size() == 5
			and not (pouch[3] is GemSlot) and pouch[4].gem == Gems.unique_of("throw"),
			"sakwa: tylko unikalny tej umiejętności, za kreską „Unikalny”")
	game.gems.erase(Gems.unique_of("throw"))
	game.gems.erase(Gems.unique_of("whirl"))
	win.refresh()
	# najpierw gniazdo: lista pasujących kamieni z działaniem w tej umiejętności
	win.socket_slots[0].pressed.emit()
	var picker: GemPicker = win.picker
	_check(picker.visible and picker.actions.has("ember:1") and picker.actions.has("rime:1") and not picker.actions.has(Gems.KEY),
			"gniazdo: tylko pasujące kamienie")
	var effect_shown := false
	for l in picker.list.find_children("*", "Label", true, false):
		effect_shown = effect_shown or l.text == Gems.support_text("ember:1", "throw")
	_check(effect_shown, "przy kamieniu widać, co zrobi w tej umiejętności")
	_check(picker.actions["ember:1"].get_global_rect().size.y >= 44.0 and picker.close_button.get_global_rect().get_center().y \
			> root.get_visible_rect().size.y * 0.5, "przyciski wyboru 44 px, „Zamknij” na dole")
	picker.actions["ember:1"].pressed.emit()
	_check(game.skill_sockets("throw")[0] == "ember:1" and game.gem_count("ember:1") == 0 and not picker.visible,
			"„Włóż” wkłada kamień i zamyka wybór")
	_check(win.socket_labels[0].text == Gems.short_text("ember:1", "throw"), "pod gniazdem krótki opis („%s”)" % win.socket_labels[0].text)
	win.socket_slots[1].dropped.emit("rime:1", "pouch", 0)
	_check(game.skill_sockets("throw")[1] == "rime:1", "przeciągnięcie kamienia na gniazdo")
	game.add_gem("ember:2")
	win.socket_slots[1].pressed.emit()
	_check(picker.actions["ember:2"].disabled, "ten sam rodzaj w innym gnieździe - przygaszony z powodem")
	picker.actions["out"].pressed.emit()
	_check(game.skill_sockets("throw")[1] == "" and game.gem_count("rime:1") == 1, "„Wyjmij” odkłada kamień do sakwy")
	# najpierw kamień: gdzie pasuje
	var rime_slot: GemSlot = null
	for p in win.pouch_row.get_children():
		if p is GemSlot and p.gem == "rime:1" and not p.is_queued_for_deletion():
			rime_slot = p
	rime_slot.pressed.emit()
	_check(picker.visible and picker.mode == "gem" and picker.actions.has("throw") and picker.actions.has("strike"),
			"kamień z sakwy: lista umiejętności, gdzie pasuje")
	picker.actions["strike"].pressed.emit()
	_check(game.skill_sockets("strike")[0] == "rime:1", "„Włóż” w pierwsze wolne gniazdo umiejętności")
	game.add_gem("rime:1")
	game.skill_gems["whirl"] = ["leech:1", "area:1", "", "", ""]  # oba otwarte gniazda zajęte
	win.refresh()
	for p in win.pouch_row.get_children():
		if p is GemSlot and p.gem == "rime:1" and not p.is_queued_for_deletion():
			rime_slot = p
	rime_slot.pressed.emit()
	_check(picker.actions["whirl"].disabled, "pełna umiejętność przygaszona („brak wolnego gniazda”)")
	picker.close()
	game.skill_gems.erase("whirl")
	game.gems.erase("ember:2")
	game.gems.erase("rime:1")
	win.socket_slots[2].pressed.emit()
	_check(game.skill_open_count("throw") == 2 and win._key_armed, "pierwsze stuknięcie zamkniętego gniazda pyta")
	win.socket_slots[2].pressed.emit()
	_check(game.skill_open_count("throw") == 3 and game.gem_count(Gems.KEY) == 0, "drugie otwiera gniazdo kluczem")
	win.set_gems_mode(false)
	_check(win.slots_row.visible and not win.gems_box.visible, "powrót do zakładki „Miejsca”")
	win.close()
	# okno „Postać”: kamień szlachetny w broni
	await process_frame
	var stats: HeroStats = arena.stats_window
	arena.stats_icon.pressed.emit()
	await process_frame
	stats.set_tab("pouch")
	_check(stats.page_pouch.visible and not stats.page_equip.visible and stats.pouch_grid.get_child_count() == game.gem_list().size()
			and game.gem_list().has(Gems.CHISEL) and game.gem_list().has(SAPPHIRE), "zakładka „Sakwa”: kamienie, dłuto")
	stats.set_tab("equip")
	stats._select_equipped("earring")
	await process_frame
	var sockets: Array = stats.socket_row.find_children("*", "GemSlot", true, false)
	_check(sockets.size() == 1 and stats.chisel_button != null and stats.socket_labels[0].text == "puste",
			"opis broni: gniazdo z opisem i przycisk dłuta")
	sockets[0].pressed.emit()
	_check(stats.picker.visible and stats.picker.actions.has(SAPPHIRE) and stats.picker.actions.size() == 1,
			"gniazdo przedmiotu: tylko kamienie szlachetne")
	stats.picker.actions[SAPPHIRE].pressed.emit()
	_check(game.equipped.earring.sockets[0] == SAPPHIRE and game.gem_count(SAPPHIRE) == 0, "szafir w kolczyku")
	_check(stats.detail.visible and stats.socket_labels[0].text == Gems.short_text(SAPPHIRE),
			"opis zostaje, pod gniazdem premia („%s”)" % stats.socket_labels[0].text)
	stats.chisel_button.pressed.emit()
	stats.chisel_button.pressed.emit()
	_check(game.equipped.earring.sockets.size() == 2 and game.gem_count(Gems.CHISEL) == 0, "dłuto: drugie stuknięcie dorabia gniazdo")
	sockets = stats.socket_row.find_children("*", "GemSlot", true, false).filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())
	sockets[0].pressed.emit()
	stats.picker.actions["out"].pressed.emit()
	_check(game.equipped.earring.sockets[0] == "" and game.gem_count(SAPPHIRE) == 1, "„Wyjmij” wyjmuje kamień z przedmiotu")
	stats.back()
	# najpierw kamień: szafir z sakwy do przedmiotu
	stats.set_tab("pouch")
	var sapphire: GemSlot = null
	for g in stats.pouch_grid.get_children():
		if g is GemSlot and g.gem == SAPPHIRE and not g.is_queued_for_deletion():
			sapphire = g
	sapphire.pressed.emit()
	_check(stats.picker.visible and stats.picker.actions.has("item_0"), "kamień z sakwy: lista przedmiotów, gdzie pasuje")
	stats.picker.actions["item_0"].pressed.emit()
	_check(game.equipped.earring.sockets[0] == SAPPHIRE, "„Włóż” w pierwsze wolne gniazdo przedmiotu")
	# sakwa: ulepszanie z okna kamienia, filtry, zaznaczanie kilku i sprzedaż
	game.gold = 3000
	game.shards = 40
	game.add_gem("ember:1", 2)
	game.add_gem("rime:4")
	game.add_gem(ONYX)
	stats.set_tab("pouch")
	_check(stats.pouch_bar.visible and stats.pouch_select_button.visible and not stats.pouch_sell_button.get_parent().visible,
			"pasek sakwy nad zakładkami: „Zaznacz kilka”")
	stats.picker.open_gem("ember:1")
	_check(stats.picker.actions.has("upgrade") and stats.picker.actions.has("sell") and stats.picker.actions.has("shatter"),
			"okno kamienia: Ulepsz, Sprzedaj, Rozbij")
	stats.picker.actions["upgrade"].pressed.emit()
	_check(stats.picker.visible and stats.picker.gem == "ember:2" and game.gem_count("ember:2") == 1 and game.shards == 38,
			"„Ulepsz” zostawia okno otwarte z ulepszonym kamieniem")
	stats.picker.actions["sell"].pressed.emit()
	_check(game.gem_count("ember:2") == 1, "„Sprzedaj” najpierw pyta")
	stats.picker.actions["sell"].pressed.emit()
	_check(game.gem_count("ember:2") == 0 and not stats.picker.visible, "druga sprzedaż sprzedaje ostatnią sztukę i zamyka okno")
	stats.pouch_kind_buttons["jewel"].pressed.emit()
	_check(stats.pouch_grid.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion()).size()
			== game.gem_list("jewel").size(), "filtr: tylko szlachetne")
	stats.pouch_kind_buttons[""].pressed.emit()
	stats.pouch_range_button.pressed.emit()  # poziom 1-3
	_check(stats.pouch_range == 0 and stats.pouch_range_button.text.contains("1-3"), "filtr poziomu 1-3")
	stats.pouch_select_button.pressed.emit()
	stats.pouch_all_button.pressed.emit()
	var marked: Array = stats.pouch_marked.keys()
	_check(stats.pouch_select and marked.has("ember:1") and marked.has(ONYX) and not marked.has("rime:4")
			and not marked.has(Gems.CHISEL), "„Zaznacz widoczne” bierze kamienie z filtra (bez kluczy i dłut)")
	var gold_before: int = game.gold
	var expect: int = game.gems_value(marked, false).x
	stats.pouch_sell_button.pressed.emit()
	_check(stats.pouch_sell_button.text.contains("Na pewno"), "sprzedaż kilku: pierwsze stuknięcie pyta")
	stats.pouch_sell_button.pressed.emit()
	_check(game.gold == gold_before + expect and game.gem_count("ember:1") == 0 and game.gem_count(ONYX) == 0
			and game.gem_count("rime:4") == 1 and not stats.pouch_select, "sprzedaż kilku naraz")
	stats.close()
	arena.pause_menu.visible = false
	paused = false
	arena.queue_free()
	await process_frame

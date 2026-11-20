extends SceneTree
## Test run (Runes): działanie każdej runy na premiach przedmiotu, kiedy runy nie da się użyć, losowanie z poziomu
## lochu (Pieczęć dopiero od 20.), łup ze skrzyni Wodza, zapis zapasu run w Game i nagrody celów (Żertwa, Kryształ),
## przeliczenie złota ze starego zapisu na runy i rudę, rozbijanie przedmiotów hurtem.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	_test_actions()
	_test_drops()
	_test_save(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _stats(item: Dictionary) -> Array:
	return item.affixes.map(func(a: Dictionary) -> String: return a.stat)


func _unique(item: Dictionary) -> bool:
	var s := _stats(item)
	for x in s:
		if s.count(x) != 1:
			return false
	return true


func _test_actions() -> void:
	_check(Runes.ORDER.size() == 6, "6 run")
	var ok := true
	for id in Runes.ORDER:
		ok = ok and Runes.name_of(id) != "" and Runes.text_of(id) != "" and Runes.icon_of(id) != null and Runes.value_of(id) > 0
	_check(ok, "każda runa ma nazwę, opis, ikonę i kurs")
	_check(Runes.value_of(Runes.POLISH) == 1 and Runes.value_of(Runes.SEAL) > Runes.value_of(Runes.CHAOS),
			"kurs: Szlifu najtańsza, Pieczęci najdroższa")
	# Szlifu: ten sam rodzaj, wartość w zakresie
	var same := true
	for i in 30:
		var it := Items.roll(10, "helmet", "rare")
		var st: String = it.affixes[0].stat
		Runes.apply(it, Runes.POLISH, 0)
		same = same and it.affixes[0].stat == st and it.affixes[0].value <= Items.affix_max(st, 10) + 0.5
	_check(same, "Runa Szlifu: ta sama premia, nowa wartość w zakresie")
	# Przydania
	var magic := Items.roll(5, "boots", "magic")
	while magic.affixes.size() > 1:
		magic.affixes.pop_back()
	_check(Runes.apply(magic, Runes.GROWTH) and magic.affixes.size() == 2 and _unique(magic), "Runa Przydania: +premia")
	_check(Runes.blocker(magic, Runes.GROWTH) != "" and not Runes.apply(magic, Runes.GROWTH), "magiczny ma najwyżej 2 premie")
	var common := Items.roll(5, "boots", "common")
	_check(Runes.blocker(common, Runes.GROWTH) != "", "zwykły - bez Przydania")
	_check(Runes.blocker(common, Runes.CHAOS) != "" and Runes.blocker(common, Runes.POLISH, 0) != "", "zwykły - bez Zmiany i Szlifu")
	# Wyniesienia
	_check(Runes.apply(common, Runes.ASCEND) and common.rarity == "magic" and common.affixes.size() >= 1,
			"Wyniesienie: zwykły -> magiczny z premią")
	_check(Runes.apply(common, Runes.ASCEND) and common.rarity == "rare" and common.affixes.size() >= 3 and _unique(common),
			"Wyniesienie: magiczny -> rzadki, premie dolosowane")
	_check(Runes.blocker(common, Runes.ASCEND) != "", "rzadki wyżej nie wejdzie")
	# Zmiany
	var counts_ok := true
	for i in 30:
		var it := Items.roll(8, "amulet", "rare")
		Runes.apply(it, Runes.CHAOS)
		counts_ok = counts_ok and it.affixes.size() >= 3 and it.affixes.size() <= 4 and _unique(it) and it.rarity == "rare"
	_check(counts_ok, "Runa Zmiany: premie od nowa w liczbie rzadkości")
	# Pieczęci
	var sealed := true
	for i in 30:
		var it := Items.roll(25, "armor", "rare")
		var kept: Dictionary = it.affixes[1].duplicate()
		var n: int = it.affixes.size()
		Runes.apply(it, Runes.SEAL, 1)
		sealed = sealed and it.affixes[0] == kept and it.affixes.size() == n and _unique(it)
	_check(sealed, "Runa Pieczęci: wybrana premia zostaje, liczba ta sama")
	var one := Items.roll(5, "ring", "magic")
	while one.affixes.size() > 1:
		one.affixes.pop_back()
	_check(Runes.blocker(one, Runes.SEAL, 0) != "", "Pieczęć potrzebuje dwóch premii")
	_check(Runes.blocker(one, Runes.REFORGE, -1) != "", "runa na premię bez wskazanej premii - nie")


func _test_drops() -> void:
	var seen := {}
	for i in 3000:
		seen[Runes.roll(5)] = true
	_check(not seen.has(Runes.SEAL) and seen.has(Runes.POLISH) and seen.has(Runes.ASCEND), "loch 5: bez Pieczęci")
	var seal := false
	for i in 3000:
		seal = seal or Runes.roll(25) == Runes.SEAL
	_check(seal, "loch 25: Pieczęć się trafia")
	var skip := true
	for i in 500:
		skip = skip and Runes.roll(10, [Runes.POLISH]) != Runes.POLISH
	_check(skip, "pomijanie Szlifu (nagroda Żertwy)")
	_check(Runes.roll_chest(3).size() >= Runes.CHEST_SURE, "skrzynia Wodza: co najmniej 2 runy")
	var offer := DungeonGoals.zertwa_offer(6)
	_check(offer.any(func(o: Dictionary) -> bool: return o.has("item") and o.item.has("rune")), "Krąg Żertwy: runa do wyboru")
	_check(DungeonGoals.crystal_runes(1.0) == 2 and DungeonGoals.crystal_runes(0.2) == 1, "Kryształ: 1-2 runy")
	var loot := {"rune": Runes.CHAOS}
	_check(ProtoLoot.name_of(loot) == Runes.name_of(Runes.CHAOS) and ProtoLoot.icon_of(loot) != null, "runa jako łup na ziemi")


func _test_save(game: Node) -> void:
	game.reset_hero()
	game.add_rune(Runes.POLISH, 3)
	game.add_rune("zła", 2)
	game.save_game()
	game.runes = {}
	game.load_game()
	_check(game.runes == {Runes.POLISH: 3}, "zapas run zapisany (zła runa pominięta)")
	var it := Items.roll(4, "helmet", "rare")
	_check(game.use_rune(it, Runes.POLISH, 0) and game.runes[Runes.POLISH] == 2, "użycie zabiera jedną runę")
	game.dev_runes()
	_check(game.runes[Runes.CHAOS] == 5 and game.runes[Runes.POLISH] == 7, "tryb deweloperski: +5 każdej runy")
	# stary zapis ze złotem: runy (1000 zł za runę, najwyżej 20, bez Pieczęci) i ruda z reszty (100 zł, najwyżej 100)
	for case in [[3450, 3, 4], [25350, 20, 53], [999999, 20, 100]]:
		var f := FileAccess.open(game.save_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"best_level": 30, "gold": case[0]}))
		f.close()
		game.load_game()
		var count := 0
		for id in game.runes:
			count += game.runes[id]
		_check(count == case[1] and game.ore == case[2] and not game.runes.has(Runes.SEAL) and game.gold == 0
				and game.gold_converted == Vector2i(case[1], case[2]), "%d zł -> %d run i %d rudy" % case)
	game.save_game()
	game.load_game()
	_check(game.gold_converted == Vector2i.ZERO and game.ore == 100, "przeliczenie tylko raz, „ore” w zapisie")
	game.dismantle_all(["common"])
	game.bag = [Items.roll(5, "ring", "rare"), Items.roll(5, "ring", "common")]
	var got: Dictionary = game.dismantle_all(["common", "magic", "rare"])
	_check(got.ore == 5 and game.ore == 105 and game.bag.is_empty(), "rozbijanie hurtem: 4 + 1 rudy")

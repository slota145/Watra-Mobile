extends SceneTree
## Test żywiołów i mistrzostwa broni: dane żywiołów (8 + fizyczne, nazwy, kolory, opisy działania), obrażenia
## z odpornością i sufitem combo (Elements.reduce), broń w ręku i jej dane (Weapons), mistrzostwo z pokonanych potworów
## w lochu (tyle samo co doświadczenie postaci), napis nad postacią przy odblokowaniu umiejętności.

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
	_test_elements()
	_test_weapons(game)
	await _test_mastery(game)
	await _test_resists(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_elements() -> void:
	_check(Elements.ALL.size() == 8 and not Elements.ALL.has(Elements.PHYSICAL), "8 żywiołów bez fizycznych")
	var ok := true
	for id in Elements.ALL + [Elements.PHYSICAL]:
		ok = ok and Elements.is_element(id) and Elements.name_of(id) != "" and Elements.COLORS.has(id)
	for id in Elements.ALL:
		ok = ok and Elements.effect_text(id) != ""
	_check(ok, "każdy żywioł ma nazwę, kolor i opis działania")
	_check(Elements.name_of(Elements.LIGHTNING) == "Grom" and Elements.name_of(Elements.NAWIA) == "Nawia"
			and not Elements.is_element("chaos"), "nazwy ustalone z autorem (Grom, Nawia)")
	_check(Elements.reduce(100, 0.0) == 100 and Elements.reduce(100, 0.3) == 70 and Elements.reduce(100, -0.5) == 150,
			"odporność zmniejsza, wrażliwość zwiększa")
	_check(Elements.reduce(100, 0.99) == 25 and Elements.reduce(100, -3.0) == 200, "odporność najwyżej 75%, wrażliwość najwyżej x2")
	_check(Elements.reduce(100, -0.5, 1.6) == 200 and Elements.reduce(100, 0.0, 1.3) == 130, "combo żywiołów najwyżej x2 (balans)")
	_check(Elements.reduce(1, 0.75) == 1 and Elements.reduce(0, 0.0) == 0, "trafienie zawsze za co najmniej 1")
	_check(Elements.resistance("goblin", Elements.FIRE) == 0.0, "gobliny bez odporności")


func _test_weapons(game: Node) -> void:
	_check(game.weapon == Weapons.SWORD and Weapons.element_of(Weapons.SWORD) == Elements.PHYSICAL
			and Weapons.unlocked_by(Weapons.SWORD, 0), "miecz w ręku od początku, fizyczny (decyzja autora)")
	var ok := true
	for id in Skills.ORDER:
		ok = ok and Weapons.has(Skills.weapon_of(id))
	_check(ok, "każda umiejętność należy do broni")
	_check(Weapons.xp_to_next(5) == HeroLevels.xp_to_next(5), "mistrzostwo rośnie po krzywej poziomów postaci")


func _test_mastery(game: Node) -> void:
	game.reset_hero()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var labels := func() -> Array:
		var out: Array = []
		for c in arena.hero.get_children():
			if c is Label and c.text.contains(Skills.name_of("whirl")):
				out.append(c)
		return out
	arena._gain_xp(30)
	_check(game.weapon_xp() == 30 and game.hero_xp == 30, "pokonany potwór: tyle samo mistrzostwa co doświadczenia")
	arena._gain_xp(Weapons.xp_to_next(1) + Weapons.xp_to_next(2))
	_check(game.mastery_level() == 3 and game.skills_owned.has("whirl") and labels.call().size() == 1,
			"mistrzostwo 3 w lochu: Młynek odblokowany, napis nad postacią")
	arena.queue_free()
	await process_frame


## Odporności lochów (Dungeons.RESISTS, 17.11.2026): potwory i boss dostają je ze swojego lochu, broń żywiołu zadaje
## mniej (odporność) albo więcej (wrażliwość), fizyczne bez zmian, podpalenie słabsze na odpornych na ogień,
## opis w wyborze poziomu; zdrowie potworów rośnie w głębi szybciej (DungeonLevels.hp_mult).
func _test_resists(game: Node) -> void:
	_check(Dungeons.resists(Dungeons.GOBLINS).is_empty() and Dungeons.resists(Dungeons.VOLCANO)[Elements.FIRE] > 0.0,
			"gobliny bez odporności, wulkan odporny na ogień")
	_check(Dungeons.resist_text(Dungeons.VOLCANO).contains("Odporne") and Dungeons.resist_text(Dungeons.VOLCANO).contains("Wrażliwe"),
			"opis odporności: " + Dungeons.resist_text(Dungeons.VOLCANO))
	_check(DungeonLevels.hp_mult(1) == 1.0 and DungeonLevels.hp_mult(101) > 2.0 and DungeonLevels.hp_mult(10) < 1.1,
			"zdrowie w głębi rośnie szybciej (101. x%.2f)" % DungeonLevels.hp_mult(101))
	game.best_level = 45
	game.dungeon_level = 45
	game.dev_immortal = true
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	var weapon: ProtoWeapon = arena.weapon
	weapon.crit_chance = 0.0
	var g := horde.spawn_at(arena.hero.position + Vector2(200, 0))
	await process_frame
	_check(g.resist(Elements.FIRE) == Dungeons.RESISTS[Dungeons.VOLCANO][Elements.FIRE], "salamandra zna odporności lochu")
	g.hp = 1000000
	weapon.element = Elements.PHYSICAL
	weapon._deal(g, 1000, g.global_position, Skills.STRIKE)
	var physical := 1000000 - g.hp
	g.hp = 1000000
	weapon.element = Elements.FIRE
	weapon._deal(g, 1000, g.global_position, Skills.STRIKE)
	var fire := 1000000 - g.hp
	g.hp = 1000000
	weapon.element = Elements.WATER
	weapon._deal(g, 1000, g.global_position, Skills.STRIKE)
	var water := 1000000 - g.hp
	_check(physical == 1000 and fire == 400 and water == 1300, "fizyczne 1000, ogień 400 (odporność), woda 1300 (wrażliwość): %d / %d / %d" % [physical, fire, water])
	weapon.element = Elements.PHYSICAL
	arena.queue_free()
	await process_frame
	game.dev_immortal = false


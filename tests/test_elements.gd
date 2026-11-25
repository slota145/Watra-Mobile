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
	_check(Elements.ALL.size() == 10 and Elements.ALL.has(Elements.ARCANE) and Elements.ALL.has(Elements.PRAWIA)
			and not Elements.ALL.has(Elements.PHYSICAL), "10 żywiołów (z Arkanami i Prawią) bez fizycznych")
	var ok := true
	for id in Elements.ALL + [Elements.PHYSICAL]:
		ok = ok and Elements.is_element(id) and Elements.name_of(id) != "" and Elements.COLORS.has(id)
	for id in Elements.ALL:
		ok = ok and Elements.effect_text(id) != ""
	_check(ok, "każdy żywioł ma nazwę, kolor i opis działania")
	_check(Elements.name_of(Elements.LIGHTNING) == "Grom" and Elements.name_of(Elements.NAWIA) == "Nawia"
			and Elements.name_of(Elements.PRAWIA) == "Prawia" and not Elements.is_element("chaos"), "nazwy ustalone z autorem (Grom, Nawia, Prawia)")
	_check(Elements.reduce(100, 0.0) == 100 and Elements.reduce(100, 0.3) == 70 and Elements.reduce(100, -0.5) == 150,
			"odporność zmniejsza, wrażliwość zwiększa")
	_check(Elements.reduce(100, 0.99) == 25 and Elements.reduce(100, -3.0) == 200, "odporność najwyżej 75%, wrażliwość najwyżej x2")
	_check(Elements.reduce(100, -0.5, 1.6) == 200 and Elements.reduce(100, 0.0, 1.3) == 130, "combo żywiołów najwyżej x2 (balans)")
	_check(Elements.reduce(1, 0.75) == 1 and Elements.reduce(0, 0.0) == 0, "trafienie zawsze za co najmniej 1")
	_check(Elements.resistance("goblin", Elements.FIRE) == 0.0, "gobliny bez odporności")


func _test_weapons(game: Node) -> void:
	_check(game.weapon == Weapons.SWORD and Weapons.element_of(Weapons.SWORD) == Elements.PHYSICAL
			and game.weapon_available(Weapons.SWORD), "miecz w ręku od początku (domyślna broń startowa), fizyczny")
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


## Odporności potworów (17.11.2026): wspólna odporność na wszystko (też fizyczne) rośnie z głębią, lochy mają łagodny
## charakter (Dungeons.RESISTS, ±20%), przebicie odporności postaci (`pen_pct`) ją zmniejsza (najwyżej do zera),
## podpalenie też podlega odporności, opis w wyborze poziomu.
func _test_resists(game: Node) -> void:
	_check(DungeonLevels.base_resist(1) == 0.0 and is_equal_approx(DungeonLevels.base_resist(101), DungeonLevels.RESIST_MAX)
			and DungeonLevels.base_resist(500) == DungeonLevels.RESIST_MAX, "wspólna odporność: 0% na 1., %d%% na 101." % roundi(DungeonLevels.base_resist(101) * 100))
	var lvl := Dungeons.cycle_length() + Dungeons.first_level(Dungeons.VOLCANO)  # Wulkaniczne w drugim kręgu
	var r: Dictionary = Dungeons.resists(Dungeons.VOLCANO, lvl)
	var base := DungeonLevels.base_resist(lvl)
	_check(is_equal_approx(r[Elements.PHYSICAL], base) and is_equal_approx(r[Elements.FIRE], base + 0.2)
			and is_equal_approx(r[Elements.WATER], base - 0.2), "wulkan: fizyczne %.2f, ogień +20%%, woda -20%%" % base)
	_check(Dungeons.resist_text(Dungeons.VOLCANO, lvl).contains("Odporność potworów") and Dungeons.resist_text(Dungeons.VOLCANO, lvl).contains("Mniej"),
			"opis odporności: " + Dungeons.resist_text(Dungeons.VOLCANO, lvl))
	_check(Items.AFFIXES.has("pen_pct") and Gems.JEWELS.ruby.pool.has("pen_pct") and Items.CAPS.pen_pct > 0.0,
			"przebicie odporności: premia przedmiotów i rubinów, z sufitem")
	game.best_level = lvl
	game.dungeon_level = lvl
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
	_check(is_equal_approx(g.resist(Elements.FIRE), base + 0.2), "salamandra zna odporności lochu")
	var hits := {}
	for e in [Elements.PHYSICAL, Elements.FIRE, Elements.WATER]:
		g.hp = 1000000
		weapon.element = e
		weapon._deal(g, 1000, g.global_position, Skills.STRIKE)
		hits[e] = 1000000 - g.hp
	_check(hits[Elements.PHYSICAL] == roundi(1000 * (1.0 - base)) and hits[Elements.FIRE] < hits[Elements.PHYSICAL]
			and hits[Elements.WATER] > hits[Elements.PHYSICAL], "fizyczne %d, ogień %d (mniej), woda %d (więcej)" % [hits[Elements.PHYSICAL], hits[Elements.FIRE], hits[Elements.WATER]])
	weapon.element = Elements.PHYSICAL
	weapon.penetration = 0.15
	g.hp = 1000000
	weapon._deal(g, 1000, g.global_position, Skills.STRIKE)
	_check(1000000 - g.hp == roundi(1000 * (1.0 - (base - 0.15))), "przebicie 15%% zmniejsza odporność (%d)" % (1000000 - g.hp))
	weapon.penetration = 1.0
	_check(g.resist(Elements.PHYSICAL, 1.0) == 0.0 and g.resist(Elements.WATER, 1.0) == minf(base - 0.2, 0.0), "przebicie najwyżej do zera")
	weapon.penetration = 0.0
	arena.queue_free()
	await process_frame
	game.dev_immortal = false

extends SceneTree
## Test unikatów (przebudowa przedmiotów krok 3, 21.11.2026): dane i losowanie (stała baza, wąskie widełki, szansa od
## lochu 10), opis, zapis i wczytanie, kowal ich nie przerabia, suma cech (procent zdrowia, kary) i działanie w walce:
## Oko Licha, Korona Czarnoboga, Ostatnia Warownia, Ślady Swaroga, Pierścień Strzyboga, Zwierciadło Mokoszy.

var _failed := 0


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
	await _test_combat(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Items.UNIQUES.size() == 8, "8 unikatów (6 z łupu i 2 Żmija)")
	var slots := {}
	for id in Items.UNIQUES:
		var u: Dictionary = Items.UNIQUES[id]
		if not u.has("source"):
			slots[u.slot] = true
		var item := Items.make_unique(id, 25)
		var ok: bool = Items.is_unique(item) and item.type == u.type and item.affixes.is_empty() \
				and Items.potential_of(item).x == 0 and item.base.size() > 0
		for stat in u.stats:
			ok = ok and item.ustats[stat] >= u.stats[stat][0] and item.ustats[stat] <= u.stats[stat][1]
		ok = ok and item.upower >= u.power[0] and item.upower <= u.power[1]
		_check(ok, "%s: stała baza, premie w widełkach, bez potencjału" % Items.name_of(item))
		_check(Items.affix_lines(item).size() == u.stats.size() + 2 and Items.kind_line(item).begins_with("Unikat"),
				"%s: opis (premie, działanie, cytat)" % id)
		_check(Runes.blocker(item, Runes.POLISH, 0) != "", "%s: kowal go nie przerabia" % id)
		var back := Items.normalize(JSON.parse_string(JSON.stringify(item)))
		_check(back == item, "%s: zapis i wczytanie bez zmian" % id)
	_check(slots.size() == 6, "po jednym unikacie z łupu na miejsce")
	var bad := Items.make_unique("crown", 10)
	bad.ustats.damage_pct = 999.0
	_check(Items.normalize(bad).ustats.damage_pct == 40.0, "wczytanie przycina premie do widełek")
	bad.unique = "nie_ma"
	_check(Items.normalize(bad).is_empty(), "nieznany unikat odrzucony")
	var boots := Items.make_unique("swarog", 30)
	_check(Items.affix_lines(boots)[1].begins_with("-15%"), "kara pokazana z minusem (%s)" % Items.affix_lines(boots)[1])
	_check(Items.unique_chance(9) == 0.0 and is_equal_approx(Items.unique_chance(10), 0.002)
			and is_equal_approx(Items.unique_chance(Items.MAX_LEVEL), 0.005)
			and is_equal_approx(Items.unique_chance(90), 0.005 * Items.deep_loot(90)),
			"szansa: od lochu 10 0,2%%, na %d 0,5%%, w Głębinach więcej" % Items.MAX_LEVEL)
	var found := 0
	var wrong := 0
	for i in 6000:
		var it := Items.roll(40, "ring")
		if Items.is_unique(it):
			found += 1
			wrong += 0 if it.unique == "strzybog" else 1
		if Items.is_unique(Items.roll(9)) or Items.is_unique(Items.roll(40, "", "", Items.FORGE_WEIGHTS, "", false)):
			wrong += 1
	_check(found > 5 and found < 80 and wrong == 0, "łup: unikat pasuje do miejsca, nie z kuźni ani przed lochem 10 (%d)" % found)
	var t := Items.totals({"helmet": Items.make_unique("crown", 20), "boots": boots, "armor": Items.make_unique("bastion", 20)})
	_check(t.uniques.has("crown") and t.uniques.has("swarog") and t.uniques.has("bastion"), "suma cech: założone unikaty")
	_check(t.hp_pct == t.hp_pct and t.hp_pct >= 0.0 and t.hp_pct <= 5.0, "suma cech: procent zdrowia z kary i premii (%d)" % t.hp_pct)
	_check(t.move_pct <= boots.base.move_pct + 10.0 - 20.0, "Warownia spowalnia (%d%%)" % t.move_pct)


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 5000.0
	g.position = at
	arena.get_node("World").add_child(g)
	arena.weapon.targets.append(g)
	g.stun(30.0)
	return g


func _equip(game: Node, items: Dictionary) -> void:
	game.equipped = items
	game.inventory_changed.emit()
	await process_frame


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.equipped = {}
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	hero.position = Vector2.ZERO
	var g := _goblin(arena, Vector2(30, 0))
	await process_frame
	# Oko Licha: bez krytyków, co 4. trafienie x3
	await _equip(game, {"earring": Items.make_unique("licho", 20)})
	weapon.crit_chance = 1.0
	weapon._licho_hits = 0
	var hits: Array[int] = []
	for i in 8:
		var hp := g.hp
		weapon._deal(g, 10, hero.global_position, "strike")
		hits.append(hp - g.hp)
	_check(hits[0] == hits[1] and hits[3] >= hits[0] * 3 - 1 and hits[7] == hits[3] and hits[4] == hits[0],
			"Oko Licha: zwykłe trafienia bez krytyków, co 4. x3 (%s)" % str(hits))
	# Korona Czarnoboga: zdrowie zamiast many, więcej zdrowia i obrażeń
	var plain_hp := hero.max_hp
	await _equip(game, {"helmet": Items.make_unique("crown", 20)})
	_check(hero.crown and hero.max_hp > plain_hp, "Korona: więcej zdrowia (%d -> %d)" % [plain_hp, hero.max_hp])
	hero.hp = hero.max_hp
	var mana := hero.mana
	_check(hero.spend_mana(10) and hero.mana == mana and hero.hp == hero.max_hp - 10, "Korona: umiejętność płaci zdrowiem")
	game.auras = {"krzepa": 1}
	game.auras_on = ["krzepa"]
	game.auras_changed.emit()
	game.inventory_changed.emit()
	await process_frame
	var gear: Dictionary = game.gear()
	var no_reserve := gear.duplicate()
	no_reserve.aura_reserve = 0.0
	_check(gear.get("aura_reserve", 0.0) > 0.0 and hero.reserved == 0
			and HeroStats.max_hp(15, gear) < HeroStats.max_hp(15, no_reserve), "Korona: aura rezerwuje zdrowie, nie manę")
	game.auras_on = []
	game.auras_changed.emit()
	# Ostatnia Warownia: wrogowie blisko - obrażenia i odporność
	await _equip(game, {"armor": Items.make_unique("bastion", 20)})
	var crowd: Array[ProtoGoblin] = []
	for i in 4:
		crowd.append(_goblin(arena, Vector2(-30 + i * 10, 25)))
	await _wait(0.3)
	_check(weapon.bastion_count == 5 and is_equal_approx(hero.bastion_res, 0.05),
			"Warownia: 5 wrogów blisko (%d), 5%% odporności" % weapon.bastion_count)
	var hp_b := g.hp
	weapon._deal(g, 100, hero.global_position, "strike")
	var with_b := hp_b - g.hp
	_check(with_b >= 109, "Warownia: +10%% obrażeń przy 5 wrogach (%d)" % with_b)
	for c in crowd:
		c.queue_free()
		weapon.targets.erase(c)
	# Pierścień Strzyboga: odłamki z trafienia pociskiem
	await _equip(game, {"ring": Items.make_unique("strzybog", 20)})
	var other := _goblin(arena, Vector2(60, 10))
	var hp_o := other.hp
	weapon._deal(g, 50, hero.global_position, "throw")
	await _wait(0.5)
	_check(other.hp < hp_o, "Strzybóg: odłamek trafia innego wroga")
	hp_o = other.hp
	uniques_wait_reset(arena)
	weapon._deal(g, 50, hero.global_position, "strike")
	await _wait(0.5)
	_check(other.hp == hp_o, "Strzybóg: cios wręcz się nie dzieli")
	# Ślady Swaroga: płonący ślad za postacią
	await _equip(game, {"boots": Items.make_unique("swarog", 20)})
	other.position = Vector2(-60, 60)
	var hp_s := other.hp
	for i in 10:
		hero.position = Vector2(-60 + i * 3, 60)
		await process_frame
	await _wait(0.7)
	_check(arena.uniques_node._flames.size() > 0, "Swaróg: płomienie za postacią (%d)" % arena.uniques_node._flames.size())
	_check(other.hp < hp_s and other.is_burning(), "Swaróg: ślad rani i podpala")
	await _equip(game, {})
	_check(arena.uniques_node._flames.is_empty(), "Swaróg: zdjęte buty gaszą ślad")
	# Zwierciadło Mokoszy: droższe umiejętności i odbicie
	var cost := weapon.mana_cost("throw")
	await _equip(game, {"amulet": Items.make_unique("mokosz", 20)})
	_check(weapon.mana_cost("throw") == roundi(cost * Items.MOKOSZ_COST) or absi(weapon.mana_cost("throw") - roundi(cost * 1.8)) <= 1,
			"Mokosz: koszt many x1,8 (%d -> %d)" % [cost, weapon.mana_cost("throw")])
	_check(weapon.mirror_echoes("throw") and not weapon.mirror_echoes(weapon.basic), "Mokosz: zwykły atak się nie odbija")
	weapon.skill_used.emit("throw")
	await _wait(Items.MOKOSZ_DELAY + 0.1)
	_check(weapon._echo_pending == "throw" or weapon._state == "throw", "Mokosz: umiejętność powtarza się sama")
	arena.queue_free()
	await process_frame


## Pierścień Strzyboga dzieli pocisk najwyżej raz na chwilę - w teście odblokowujemy od razu.
func uniques_wait_reset(arena: Node) -> void:
	arena.uniques_node._split_ready = 0.0

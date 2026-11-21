extends SceneTree
## Test mrocznej kosy (21.11.2026, krok 1): dane (żywioł Nawia, loch 25, 3 umiejętności z kamieniami unikalnymi,
## poziomami i ikonami), Nawia (wysysa życie, osłabia ciosy wroga), a w walce: Żniwo (łuk przed postacią, obrót co
## trzeci zamach z 5. poziomu, smuga z 10.), Cięcie Światowida (4 cięcia w kwadrat, potem wybuch na zewnątrz; 10. -
## dwa wybuchy), Pokos (ładowany stożek - im dłużej, tym dalej); kamienie unikalne (fala Nawii po 15 trafieniach,
## 4 kwadraty, rzędy wybuchów od prawej do lewej).

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	DungeonLevels.enemy_hp = 1.0
	DungeonLevels.enemy_damage = 1.0
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
	await _test_nawia(game)
	await _test_combat(game)
	await _test_unique(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Weapons.element_of("scythe") == Elements.NAWIA and int(Weapons.DATA.scythe.unlock) == 25
			and Weapons.script_of("scythe") == ProtoScythe, "kosa: Nawia, od lochu 25")
	_check(Skills.basic_of("scythe") == "s_reap" and Skills.is_charged("s_mow") and Skills.of_weapon("scythe").size() == 3,
			"Żniwo zwykłym atakiem, Pokos ładowany")
	var ok := true
	for id in Skills.of_weapon("scythe"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu i ikonę")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _scythe_arena(game: Node) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 30
	game.set_weapon("scythe")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	arena.hero.position = Vector2.ZERO
	return [arena, arena.weapon as ProtoScythe]


func _stunned(arena: Node, spots: Array) -> Array:
	var out: Array = []
	for p in spots:
		out.append(_goblin(arena, p))
	await _wait(0.2)
	for g in out:
		g._stunned = 60.0
		g.position = spots[out.find(g)]
	await process_frame
	return out


func _hp(list: Array) -> int:
	var s := 0
	for g in list:
		s += g.hp
	return s


func _test_nawia(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	_check(scythe != null and scythe.element == Elements.NAWIA, "w lochu kosa w ręku (Nawia)")
	var gs: Array = await _stunned(arena, [Vector2(40, 0)])
	var g: ProtoGoblin = gs[0]
	g.max_hp = 100000
	g.hp = 100000
	hero.hp = hero.max_hp / 2
	var before: int = hero.hp
	for i in 20:
		scythe._deal(g, 200, hero.global_position, "s_reap")
	_check(hero.hp > before, "Nawia wysysa życie (%d -> %d)" % [before, hero.hp])
	_check(g.is_withered(), "trafiony wróg osłabiony Nawią")
	hero.hp = hero.max_hp
	var hp: int = hero.hp
	g.hit_hero(hero, 100)
	var weak: int = hp - hero.hp
	_check(weak > 0 and weak < 100, "osłabiony wróg zadaje mniej (%d z 100 przed ochroną)" % weak)
	arena.queue_free()
	await process_frame


func _test_combat(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	# Żniwo: przed postacią trafia, za plecami nie
	var gs: Array = await _stunned(arena, [Vector2(40, 0), Vector2(-45, 0)])
	var front: ProtoGoblin = gs[0]
	var back: ProtoGoblin = gs[1]
	var f_hp := front.hp
	var b_hp := back.hp
	scythe._attack()
	await _wait(0.6)
	_check(front.hp < f_hp and back.hp == b_hp, "Żniwo tnie łukiem przed postacią, nie za plecami")
	# 5. poziom: co trzeci zamach - pełny obrót
	scythe.skill_levels["s_reap"] = 5
	scythe.reap_count = 2
	b_hp = back.hp
	scythe._state = "follow"
	scythe._attack()
	_check(scythe._full_spin, "5. poziom: trzeci zamach to obrót")
	await _wait(0.7)
	_check(back.hp < b_hp, "obrót trafia też za plecami")
	# 10. poziom: smuga Nawii
	scythe.skill_levels["s_reap"] = 10
	scythe._state = "follow"
	scythe._attack()
	await _wait(0.45)
	_check(scythe._trails.size() == 1, "10. poziom: zamach zostawia smugę")
	f_hp = front.hp
	await _wait(0.5)
	_check(front.hp < f_hp, "smuga rani")
	await _wait(1.0)
	_check(scythe._trails.is_empty(), "smuga gaśnie")
	# Cięcie Światowida: wróg na boku obrywa od cięcia, wróg za bokiem - od wybuchu i jest odpychany
	front.position = Vector2(0, -50)  # na górnym łuku (wygięty na zewnątrz)
	back.position = Vector2(0, 60)  # za dolnym bokiem
	await process_frame
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	f_hp = front.hp
	b_hp = back.hp
	scythe._start("s_square")
	_check(scythe._squares.size() == 1, "kwadrat Światowida")
	await _wait(0.33)
	_check(front.hp < f_hp and back.hp == b_hp, "cięcia boków ranią stojących na nich, wybuchu jeszcze nie ma")
	_check(scythe._squares[0].lines.size() == 8, "4 cięcia po łuku zostają do wybuchu")
	await _wait(0.4)
	_check(back.hp < b_hp, "bok wybucha na zewnątrz")
	# 10. poziom: dwa wybuchy
	scythe.skill_levels["s_square"] = 10
	await _wait(0.6)
	scythe._cd.clear()
	scythe._state = "follow"
	hero.mana = hero.max_mana
	scythe._start("s_square")
	await _wait(0.85)
	_check(scythe._squares.size() == 1 and scythe._squares[0].bursts == 1, "10. poziom: po pierwszym wybuchu czeka drugi")
	await _wait(0.5)
	_check(scythe._squares.is_empty(), "drugi wybuch i koniec")
	# Pokos: krótko trzymany sięga blisko, długo - daleko
	front.position = Vector2(100, 0)
	back.position = Vector2(400, 400)
	await process_frame
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	f_hp = front.hp
	scythe.charge_held = true
	scythe._start("s_mow")
	_check(scythe._state == "mow_charge" and scythe._mow_poly != null, "Pokos się ładuje, stożek na ziemi")
	await _wait(0.1)
	scythe.charge_held = false
	await _wait(0.1)
	_check(front.hp == f_hp and scythe._state == "follow", "krótkie ładowanie - wróg poza stożkiem")
	await _wait(0.2)
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.charge_held = true
	scythe._start("s_mow")
	await _wait(1.5)
	var reach: float = scythe._mow_shape(1.0).y
	scythe.charge_held = false
	await _wait(0.1)
	_check(front.hp < f_hp and reach >= 100.0, "pełne ładowanie sięga daleko (%d px)" % reach)
	arena.queue_free()
	await process_frame


func _test_unique(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	for id in Skills.of_weapon("scythe"):
		scythe.skill_gems[id] = [Gems.unique_of(id)]
	var gs: Array = await _stunned(arena, [Vector2(35, 0), Vector2(30, 20), Vector2(30, -20), Vector2(-70, 0)])
	var far: ProtoGoblin = gs[3]
	# Żniwiarz: po 15 trafieniach fala dookoła (trafia też wroga za plecami)
	scythe.reap_hits = ProtoScythe.REAP_CHARGE - 3
	var far_hp := far.hp
	scythe._attack()
	await _wait(0.6)
	_check(scythe.reap_hits < 3 and far.hp < far_hp, "Kamień Żniwiarza: fala Nawii dookoła")
	# Czterech Stron: 4 kwadraty z widmowymi kosami
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	scythe._start("s_square")
	_check(scythe._squares.size() == 4 and scythe._squares.all(func(s: Dictionary) -> bool: return s.ghost != null),
			"Kamień Czterech Stron: 4 kwadraty, widmowe kosy")
	var centers: Array = scythe._squares.map(func(s: Dictionary) -> Vector2: return s.center - hero.global_position)
	var off: float = scythe._squares[0].half * ProtoScythe.SQUARE_SPREAD
	_check(centers.has(Vector2(-1, -1) * off) and centers.has(Vector2(1, 1) * off) and off > scythe._squares[0].half,
			"kwadraty 2x2 dookoła postaci, oddalone od siebie")
	await _wait(1.0)
	# Rzędy Nawii: rzędy wybuchów, każdy od prawej do lewej
	scythe._mow_rows(hero.global_position, 0.0, scythe._mow_shape(1.0), 1.0)
	var first: Array = scythe._mow_blasts.filter(func(b: Dictionary) -> bool: return b.row == 0)
	_check(first.size() >= 3 and first[0].at.y > first[-1].at.y, "pierwszy rząd od prawej (dół ekranu przy celowaniu w prawo) do lewej")
	var n: int = scythe._mow_blasts.size()
	await _wait(1.0)
	_check(scythe.mow_blasts_done >= n and scythe._mow_blasts.is_empty(), "wszystkie wybuchy rzędów (%d)" % n)
	arena.queue_free()
	await process_frame

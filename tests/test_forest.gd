extends SceneTree
## Test ósmego lochu - Prastary Bór (Dungeons.FOREST, 25.11.2026): miejsce na drabince (36-40, po Lodowych jaskiniach,
## krąg 40 poziomów), odporności (natura +20%, ogień -20%), potwory (Błędnik - przypala, Borowiec - cierń, dziki
## drzewiec - korzenie trzymają), Żywa puszcza (ProtoGrove: zapowiedź pod postacią, korzenie ranią i trzymają, uniknięcie)
## i boss Leszy z Watry (korzenie pasem, wir liści, przebudzenie dzikich drzewców).

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
	_check(Dungeons.first_level(Dungeons.FOREST) == 36 and Dungeons.for_level(40) == Dungeons.FOREST
			and Dungeons.for_level(41) == Dungeons.GOBLINS and Dungeons.cycle_length() == 40,
			"drabinka: Prastary Bór 36-40, drugi krąg od 41")
	var r := Dungeons.resists(Dungeons.FOREST, 36)
	var base := DungeonLevels.base_resist(36)
	_check(is_equal_approx(r[Elements.NATURE], base + 0.2) and is_equal_approx(r[Elements.FIRE], base - 0.2),
			"odporności: natura +20%, ogień -20%")
	_check(ProtoHorde.make_monster(Dungeons.FOREST, "goblin") is ProtoBlednik
			and ProtoHorde.make_monster(Dungeons.FOREST, "archer") is ProtoBorowiec
			and ProtoHorde.make_monster(Dungeons.FOREST, "brute") is ProtoWildTreant, "potwory: Błędnik, Borowiec, dziki drzewiec")
	_check(Unlocks.all().any(func(u: Dictionary) -> bool: return int(u.level) == 36 and str(u.text).contains("Prastary Bór")),
			"drabinka odblokowań: nowy loch na 36")
	await _test_grove(game)
	await _test_monsters(game)
	await _test_boss(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _arena(game: Node, level: int) -> Node:
	game.reset_hero()
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _setup(arena: Node) -> ProtoHero:
	var hero: ProtoHero = arena.hero
	arena.horde_spawner.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	ProtoDecor.obstacles.clear()
	hero.obstacles.clear()
	return hero


func _test_grove(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FOREST))
	await process_frame
	var hero := _setup(arena)
	var grove: ProtoGrove = arena.grove
	_check(arena.climate == Dungeons.FOREST and arena.summon_button.text == "Przyzwij Leszego" and grove != null,
			"poziom 36: Prastary Bór z Żywą puszczą")
	grove.passive = true
	hero.position = Vector2(0, 40)
	grove.start()
	await _wait(ProtoGrove.WARN + 0.1)
	_check(grove.grabs == 1 and hero.hp < hero.max_hp and hero.chill >= 0.79,
			"korzenie pod postacią: ranią i trzymają")
	await _wait(1.2)
	hero.hp = hero.max_hp
	grove.start()
	hero.position += Vector2(60, 0)  # odchodzi z koła
	await _wait(ProtoGrove.WARN + 0.1)
	_check(grove.grabs == 1 and hero.hp == hero.max_hp, "kto zejdzie z koła, ten uniknie korzeni")
	arena.queue_free()
	await process_frame


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FOREST))
	await process_frame
	var hero := _setup(arena)
	arena.grove.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	# Błędnik: przypala
	var b: ProtoBlednik = horde.spawn_at(hero.position + Vector2(16, 0), "goblin")
	await process_frame
	b._cooldown = 0.0
	for i in 60:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and hero.burn_left > 0.0, "Błędnik parzy zielonym ogniem i przypala")
	b.queue_free()
	# Borowiec: cierń z daleka
	await _wait(0.5)
	hero.burn_left = 0.0  # Błędnik przypalił - inaczej ogień rani w czasie testu Borowca
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var w: ProtoBorowiec = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	w._cooldown = 0.0
	var thorn := false
	for i in 80:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.thorn and c.element == Elements.NATURE:
				thorn = true
		if hero.hp < hero.max_hp:
			break
	_check(thorn and hero.hp < hero.max_hp, "Borowiec strzela cierniem")
	w.queue_free()
	# dziki drzewiec: cios w koło - korzenie trzymają
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var g: ProtoWildTreant = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	for i in 80:
		await _wait(0.05)
		if g._telegraph and is_instance_valid(g._telegraph):
			hero.position = g._telegraph.global_position
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and hero.chill >= ProtoWildTreant.ROOT_SLOW - 0.01, "dziki drzewiec: cios w koło, korzenie trzymają")
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_boss(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FOREST) + 1)
	await process_frame
	var hero := _setup(arena)
	arena.grove.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var l := arena.chief as ProtoLeszy
	_check(l != null and arena.boss_box.get_child(0).text == "Leszy", "przyzwany Leszy")
	l.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# korzenie pasem
	hero.position = l.position + Vector2(90, 0)
	hero._invulnerable = 0.0
	l.start_attack("roots")
	_check(l._telegraph != null and l._telegraph.length > 0.0 and l._telegraph.contains(hero.global_position), "korzenie: pas przez postać")
	await _wait(ProtoLeszy.ROOTS_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.chill >= 0.79, "korzenie ranią i trzymają postać")
	# wir liści
	await _wait(0.9)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	hero.position = l.position + Vector2(0, 70)
	l.start_attack("leaves")
	_check(l._telegraph != null and l._telegraph.arc > 0.0 and l._telegraph.contains(hero.global_position), "wir liści: wachlarz przez postać")
	await _wait(ProtoLeszy.LEAVES_WARN + 0.1)
	_check(hero.hp < hero.max_hp, "wir liści rani postać")
	# przebudzenie dzikich drzewców
	await _wait(0.9)
	var before := 0
	for c in arena.get_node("World").get_children():
		before += 1 if c is ProtoWildTreant else 0
	l.start_attack("awaken")
	await _wait(ProtoLeszy.AWAKEN_TIME + 0.2)
	var after := 0
	for c in arena.get_node("World").get_children():
		after += 1 if c is ProtoWildTreant else 0
	_check(after - before == ProtoLeszy.AWAKEN, "przebudzenie: z ziemi wyrastają %d dzikie drzewce" % (after - before))
	arena.queue_free()
	await process_frame

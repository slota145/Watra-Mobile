extends SceneTree
## Test jedenastego lochu - Wieża Kościeja (Dungeons.TOWER, 26.11.2026): miejsce na drabince (51-55, ostatni loch
## kręgu, drugi krąg od 56), odporności (Arkana +20%, Prawia -20%), potwory (latająca księga - gryzie i wysysa manę,
## uczeń czarnoksiężnika - pocisk Arkanów, runiczny golem - cios w koło), Magiczne pieczęcie (ProtoSeals: czerwona
## wybucha, niebieska daje manę i szybkość) i boss Kościej Nieśmiertelny (pieczęcie, pociski, teleport; odradza się,
## dopóki jajo jest całe, a po zniszczeniu jaja ginie).

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
	_check(Dungeons.first_level(Dungeons.TOWER) == 51 and Dungeons.for_level(55) == Dungeons.TOWER
			and Dungeons.for_level(50) == Dungeons.MINE and Dungeons.cycle_length() == 55
			and Dungeons.is_deep(56) and not Dungeons.is_deep(55),
			"drabinka: Wieża Kościeja 51-55, ostatnia, od 56 Głębiny")
	var r := Dungeons.resists(Dungeons.TOWER, 51)
	var base := DungeonLevels.base_resist(51)
	_check(is_equal_approx(r[Elements.ARCANE], base + 0.2) and is_equal_approx(r[Elements.PRAWIA], base - 0.2),
			"odporności: Arkana +20%, Prawia -20%")
	_check(ProtoHorde.make_monster(Dungeons.TOWER, "goblin") is ProtoFlyingBook
			and ProtoHorde.make_monster(Dungeons.TOWER, "archer") is ProtoApprentice
			and ProtoHorde.make_monster(Dungeons.TOWER, "brute") is ProtoRuneGolem,
			"potwory: latająca księga, uczeń czarnoksiężnika, runiczny golem")
	_check(Unlocks.all().any(func(u: Dictionary) -> bool: return int(u.level) == 51 and str(u.text).contains("Wieża Kościeja")),
			"drabinka odblokowań: nowy loch na 51")
	_check(not ProtoDecor.DATA[Dungeons.TOWER].is_empty() and ProtoDecor.DATA[Dungeons.TOWER].all(
			func(d: Dictionary) -> bool: return ResourceLoader.exists("res://assets/watra/decor/tower/%s.png" % d.f)),
			"ozdoby wieży: wszystkie pliki są")
	await _test_seals(game)
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


func _test_seals(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TOWER))
	await process_frame
	var hero := _setup(arena)
	var seals: ProtoSeals = arena.seals
	_check(arena.climate == Dungeons.TOWER and arena.summon_button.text == "Przyzwij Kościeja" and seals != null,
			"poziom 51: Wieża Kościeja z Magicznymi pieczęciami")
	seals.passive = true
	hero.position = Vector2(0, 40)
	# czerwona pod postacią wybucha po zapowiedzi
	seals.add_seal(hero.global_position, "red")
	await _wait(ProtoSeals.RED_WARN * 0.5)
	_check(hero.hp == hero.max_hp and seals.count("red") == 1, "czerwona pieczęć: najpierw tylko zapowiedź")
	await _wait(ProtoSeals.RED_WARN * 0.5 + 0.1)
	_check(seals.blasts == 1 and seals.hits == 1 and hero.hp < hero.max_hp, "czerwona pieczęć wybucha pod postacią")
	# czerwona obok - nie rani
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	seals.add_seal(hero.global_position + Vector2(60, 0), "red")
	await _wait(ProtoSeals.RED_WARN + 0.1)
	_check(seals.blasts == 2 and seals.hits == 1 and hero.hp == hero.max_hp, "wybuch obok postaci nie rani")
	# niebieska: mana i szybkość
	hero.mana = 0
	var mult := hero.move_mult
	seals.add_seal(hero.global_position + Vector2(4, 2), "blue")
	await _wait(0.1)
	_check(seals.boosts == 1 and hero.mana > 0 and hero.move_mult > mult and seals.count("blue") == 0,
			"niebieska pieczęć: mana %d, szybkość x%.2f" % [hero.mana, hero.move_mult / mult])
	await _wait(ProtoSeals.BLUE_TIME + 0.1)
	_check(is_equal_approx(hero.move_mult, mult), "premia szybkości mija")
	# niebieska, w którą nikt nie wszedł, gaśnie
	seals.add_seal(hero.global_position + Vector2(80, 0), "blue")
	await _wait(ProtoSeals.BLUE_LIFE + 0.1)
	_check(seals.count("blue") == 0 and seals.boosts == 1, "niewzięta niebieska pieczęć gaśnie")
	# grupa: 3 czerwone i 1 niebieska, niebieska nie leży na czerwonej
	seals.light_up()
	var blue_ok := true
	for s in seals.seals:
		if s.kind == "blue":
			for o in seals.seals:
				if o.kind == "red" and (o.pos as Vector2).distance_to(s.pos) <= ProtoSeals.RADIUS * 2.0:
					blue_ok = false
	_check(seals.count("red") == ProtoSeals.RED_COUNT and seals.count("blue") == ProtoSeals.BLUE_COUNT and blue_ok,
			"zapalenie: %d czerwone i %d niebieska, osobno" % [seals.count("red"), seals.count("blue")])
	arena.queue_free()
	await process_frame


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TOWER))
	await process_frame
	var hero := _setup(arena)
	arena.seals.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	# latająca księga: gryzie Arkanami i wysysa manę
	hero.mana = hero.mana_cap()
	var b: ProtoFlyingBook = horde.spawn_at(hero.position + Vector2(16, 0), "goblin")
	await process_frame
	_check(b.speed > ProtoGoblin.SPEED, "latająca księga jest szybsza od goblina")
	b._cooldown = 0.0
	for i in 60:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and b.drains >= 1 and hero.mana < hero.mana_cap(), "księga gryzie i wysysa manę")
	b.queue_free()
	# uczeń: pocisk Arkanów z daleka
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var a: ProtoApprentice = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	a._cooldown = 0.0
	var bolt := false
	for i in 80:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.arcane and c.element == Elements.ARCANE:
				bolt = true
		if hero.hp < hero.max_hp:
			break
	_check(bolt and hero.hp < hero.max_hp, "uczeń czarnoksiężnika strzela pociskiem Arkanów")
	a.queue_free()
	# runiczny golem: cios w koło
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var g: ProtoRuneGolem = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	for i in 80:
		await _wait(0.05)
		if g._telegraph and is_instance_valid(g._telegraph):
			hero.position = g._telegraph.global_position
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp, "runiczny golem: cios pięścią w koło")
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_boss(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TOWER) + 1)
	await process_frame
	var hero := _setup(arena)
	arena.seals.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var k := arena.chief as ProtoKosciej
	_check(k != null and arena.boss_box.get_child(0).text == "Kościej", "przyzwany Kościej")
	k.passive = true
	var died := [false]
	k.died.connect(func(_c: ProtoChief) -> void: died[0] = true)
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	var egg := k.egg
	_check(egg != null and is_instance_valid(egg) and egg.is_in_group(ProtoWeapon.TARGETS)
			and egg.global_position.distance_to(hero.global_position) < ProtoKosciej.EGG_DISTANCE * 1.5,
			"jajo na postumencie przy postaci (cel dla broni)")
	# pieczęcie
	k.position = hero.position + Vector2(-90, 0)
	hero._invulnerable = 0.0
	k.start_attack("cast")
	await _wait(ProtoKosciej.CAST_TIME + 0.05)
	_check(k.seals_pending() == ProtoKosciej.SEALS, "pieczęcie: %d kół wokół postaci" % k.seals_pending())
	await _wait(ProtoKosciej.SEAL_WARN + ProtoKosciej.SEAL_STEP * ProtoKosciej.SEALS + 0.2)
	_check(k.seal_hits >= 1 and hero.hp < hero.max_hp and k.seals_pending() == 0, "pieczęć pod postacią wybucha i rani")
	# pociski
	await _wait(0.8)
	k.start_attack("bolt")
	await _wait(ProtoKosciej.BOLT_TIME + 0.05)
	var bolts := 0
	for c in arena.get_node("World").get_children():
		bolts += 1 if c is ProtoArrow and c.arcane else 0
	_check(bolts == ProtoKosciej.BOLTS, "wachlarz %d pocisków Arkanów" % bolts)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	await _wait(1.2)
	_check(hero.hp < hero.max_hp, "pocisk trafia postać")
	# teleport
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	k.start_attack("teleport")
	await _wait(ProtoKosciej.TELE_OUT + 0.05)
	_check(k.state == "teleport_in" and not k.is_in_group(ProtoWeapon.TARGETS) and k._telegraph != null
			and k._telegraph.contains(hero.global_position), "teleport: znika, koło przy postaci")
	await _wait(ProtoKosciej.TELE_WARN + 0.05)
	_check(k.tele_hits == 1 and hero.hp < hero.max_hp and k.is_in_group(ProtoWeapon.TARGETS)
			and k.global_position.distance_to(hero.global_position) < ProtoKosciej.TELE_RADIUS,
			"wyłania się przy postaci z wybuchem")
	# odrodzenie przy całym jaju
	await _wait(0.8)
	_check(k.remaining_hp() == 0, "przy całym jaju nie da się go dobić (Egzekucja)")
	k.take_damage(k.hp + 50, hero.global_position)
	_check(k.state == "revive" and k.alive() and not died[0], "zdrowie do zera przy całym jaju: odradza się, nie ginie")
	var hp0 := k.hp
	k.take_damage(100, hero.global_position)
	_check(k.hp == hp0, "w czasie odradzania nietykalny")
	await _wait(ProtoKosciej.REVIVE_TIME + 0.1)
	_check(k.revives == 1 and k.hp == roundi(k.max_hp * ProtoKosciej.REVIVE_SHARE) and arena.boss_bar.value == k.hp
			and arena.phase == "boss", "wstaje z %d%% zdrowia" % roundi(ProtoKosciej.REVIVE_SHARE * 100))
	# zniszczenie jaja i śmierć
	egg.take_damage(egg.hp, hero.global_position)
	_check(k.egg_broken and not egg.alive() and not egg.is_in_group(ProtoWeapon.TARGETS) and k.state == "stagger",
			"jajo rozbite: igła złamana, Kościej się chwieje")
	await _wait(0.2)
	k.take_damage(k.hp + 50, hero.global_position)
	_check(died[0] and k.state == "dead" and arena.phase == "loot" and k.revives == 1, "bez jaja Kościej ginie")
	arena.queue_free()
	await process_frame

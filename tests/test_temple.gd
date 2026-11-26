extends SceneTree
## Test dziewiątego lochu - Świątynia Słońca (Dungeons.TEMPLE, 26.11.2026): miejsce na drabince (41-45, po Prastarym
## Borze, krąg 45 poziomów), odporności (Prawia +20%, Nawia -20%), potwory (Południca - oślepia, Żar-ptak - promień,
## kumir - cios w koło), Promienie słońca (ProtoSunbeams: zapowiedź, pas parzy, cień kolumny chroni) i boss Swarożyc
## (wypad włócznią, promienie z nieba, przywołanie mniejszych Swarożyców).

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
	_check(Dungeons.first_level(Dungeons.TEMPLE) == 41 and Dungeons.for_level(45) == Dungeons.TEMPLE
			and Dungeons.for_level(46) == Dungeons.GOBLINS and Dungeons.cycle_length() == 45,
			"drabinka: Świątynia Słońca 41-45, drugi krąg od 46")
	var r := Dungeons.resists(Dungeons.TEMPLE, 41)
	var base := DungeonLevels.base_resist(41)
	_check(is_equal_approx(r[Elements.PRAWIA], base + 0.2) and is_equal_approx(r[Elements.NAWIA], base - 0.2),
			"odporności: Prawia +20%, Nawia -20%")
	_check(ProtoHorde.make_monster(Dungeons.TEMPLE, "goblin") is ProtoPoludnica
			and ProtoHorde.make_monster(Dungeons.TEMPLE, "archer") is ProtoZarPtak
			and ProtoHorde.make_monster(Dungeons.TEMPLE, "brute") is ProtoKumir
			and ProtoHorde.make_monster(Dungeons.TEMPLE, "swarozyc") is ProtoSwarozycMinion,
			"potwory: Południca, Żar-ptak, kumir, mniejszy Swarożyc")
	_check(Unlocks.all().any(func(u: Dictionary) -> bool: return int(u.level) == 41 and str(u.text).contains("Świątynia Słońca")),
			"drabinka odblokowań: nowy loch na 41")
	await _test_sunbeams(game)
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


func _test_sunbeams(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TEMPLE))
	await process_frame
	var hero := _setup(arena)
	var beams: ProtoSunbeams = arena.sunbeams
	_check(arena.climate == Dungeons.TEMPLE and arena.summon_button.text == "Przyzwij Swarożyca" and beams != null,
			"poziom 41: Świątynia Słońca z Promieniami słońca")
	beams.passive = true
	hero.position = Vector2(0, 40)
	beams.start(Vector2.RIGHT)
	_check(beams.state == "warn" and not beams.covers(hero.global_position), "zapowiedź: pas blado świeci obok postaci")
	await _wait(ProtoSunbeams.WARN + ProtoSunbeams.START / ProtoSunbeams.SPEED + 0.3)
	_check(beams.burns >= 1 and hero.hp < hero.max_hp, "pas światła przechodzi przez postać i parzy (%d)" % beams.burns)
	await _wait(ProtoSunbeams.TRAVEL / ProtoSunbeams.SPEED)
	_check(beams.state == "", "pas przechodzi i znika")
	# cień kolumny chroni: kolumna przed postacią od strony światła (pas idzie w prawo - cień pada w prawo)
	hero.hp = hero.max_hp
	ProtoDecor.obstacles.append(Vector3(hero.position.x - 12.0, hero.position.y, 9.0))
	beams.burns = 0
	beams.start(Vector2.RIGHT)
	await _wait(ProtoSunbeams.WARN + ProtoSunbeams.START / ProtoSunbeams.SPEED + 0.4)
	_check(beams.burns == 0 and beams.shelters >= 1 and hero.hp == hero.max_hp, "w cieniu kolumny promień nie parzy")
	ProtoDecor.obstacles.clear()
	arena.queue_free()
	await process_frame


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TEMPLE))
	await process_frame
	var hero := _setup(arena)
	arena.sunbeams.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	# Południca: oślepia
	var p: ProtoPoludnica = horde.spawn_at(hero.position + Vector2(16, 0), "goblin")
	await process_frame
	p._cooldown = 0.0
	for i in 60:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and hero.blind_left > 0.0, "Południca tnie sierpem i oślepia")
	p.queue_free()
	# oślepienie osłabia ciosy postaci
	var dummy: ProtoGoblin = horde.spawn_at(hero.position + Vector2(-60, 0), "goblin")
	await process_frame
	dummy.max_hp = 1000000
	dummy.hp = dummy.max_hp
	dummy._stunned = 60.0
	var weapon: ProtoWeapon = arena.weapon
	weapon.crit_chance = 0.0
	hero.blind_left = 0.0
	var a := 0
	for i in 20:
		var hp0 := dummy.hp
		weapon._deal(dummy, 100, hero.global_position, weapon.basic)
		a += hp0 - dummy.hp
	hero.blind(5.0)
	var b := 0
	for i in 20:
		var hp0 := dummy.hp
		weapon._deal(dummy, 100, hero.global_position, weapon.basic)
		b += hp0 - dummy.hp
	_check(b < a * 0.85, "oślepiona postać zadaje mniej (%d zamiast %d)" % [b, a])
	hero.blind_left = 0.0
	dummy.queue_free()
	# Żar-ptak: promień z daleka
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var z: ProtoZarPtak = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	z._cooldown = 0.0
	var ray := false
	for i in 80:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.ray and c.element == Elements.PRAWIA:
				ray = true
		if hero.hp < hero.max_hp:
			break
	_check(ray and hero.hp < hero.max_hp, "Żar-ptak strzela promieniem światła")
	z.queue_free()
	# kumir: cios w koło
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var k: ProtoKumir = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	k._cooldown = 0.0
	for i in 80:
		await _wait(0.05)
		if k._telegraph and is_instance_valid(k._telegraph):
			hero.position = k._telegraph.global_position
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp, "kumir: cios pięściami w koło")
	k.queue_free()
	arena.queue_free()
	await process_frame


func _test_boss(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.TEMPLE) + 1)
	await process_frame
	var hero := _setup(arena)
	arena.sunbeams.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var s := arena.chief as ProtoSwarozyc
	_check(s != null and arena.boss_box.get_child(0).text == "Swarożyc", "przyzwany Swarożyc")
	s.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# wypad włócznią
	hero.position = s.position + Vector2(100, 0)
	hero._invulnerable = 0.0
	s.start_attack("lunge")
	_check(s._telegraph != null and s._telegraph.length > 0.0 and s._telegraph.contains(hero.global_position),
			"wypad: pas przez postać")
	await _wait(ProtoSwarozyc.LUNGE_WARN + ProtoSwarozyc.LUNGE_DASH + 0.15)
	_check(s.lunge_hits == 1 and hero.hp < hero.max_hp and hero.blind_left > 0.0, "wypad rani i oślepia")
	_check(s.position.distance_to(hero.position) < 80.0, "Swarożyc przelatuje do postaci")
	# promienie z nieba
	await _wait(0.9)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	s.start_attack("beams")
	_check(s.beams_pending() == ProtoSwarozyc.BEAMS, "promienie z nieba: %d kół" % s.beams_pending())
	await _wait(ProtoSwarozyc.BEAM_WARN + 0.1)
	_check(s.beam_hits >= 1 and hero.hp < hero.max_hp, "promień pod postacią rani")
	await _wait(ProtoSwarozyc.BEAM_STEP * ProtoSwarozyc.BEAMS + 0.2)
	_check(s.beams_pending() == 0, "wszystkie promienie uderzyły")
	# przywołanie mniejszych Swarożyców
	await _wait(0.5)
	var before := 0
	for c in arena.get_node("World").get_children():
		before += 1 if c is ProtoSwarozycMinion else 0
	s.start_attack("summon")
	await _wait(ProtoSwarozyc.SUMMON_TIME + 0.2)
	var after := 0
	for c in arena.get_node("World").get_children():
		after += 1 if c is ProtoSwarozycMinion else 0
	_check(after - before == ProtoSwarozyc.SUMMON_COUNT, "przywołanie: %d mniejszych Swarożyców" % (after - before))
	arena.queue_free()
	await process_frame

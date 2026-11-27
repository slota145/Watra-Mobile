extends SceneTree
## Test dziesiątego lochu - Kopalnia karłów (Dungeons.MINE, 26.11.2026): miejsce na drabince (46-50, po Świątyni
## Słońca, przed Wieżą Kościeja), odporności (ziemia +20%, powietrze -20%), potwory (kretołak - zakopany, wyskakuje
## spod ziemi; karzeł-procarz - kamień z procy; skalny golem - cios w koło), Osuwiska (ProtoRockfall: zapowiedź, głaz
## rani, zostaje jako przeszkoda i osłona przed pociskami, potem się kruszy) i boss Król Karłów (uderzenie młotem
## z falami, deszcz odłamków, przywołanie skalnych golemów).

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	DungeonLevels.enemy_hp = 1.0
	DungeonLevels.ramp_start = 1.0  # bez Rozruchu (27.11.2026)
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
	_check(Dungeons.first_level(Dungeons.MINE) == 46 and Dungeons.for_level(46) == Dungeons.MINE
			and Dungeons.for_level(50) == Dungeons.MINE and Dungeons.for_level(51) == Dungeons.TOWER,
			"drabinka: Kopalnia karłów 46-50, po niej Wieża Kościeja")
	var r := Dungeons.resists(Dungeons.MINE, 46)
	var base := DungeonLevels.base_resist(46)
	_check(is_equal_approx(r[Elements.EARTH], base + 0.2) and is_equal_approx(r[Elements.AIR], base - 0.2),
			"odporności: ziemia +20%, powietrze -20%")
	_check(ProtoHorde.make_monster(Dungeons.MINE, "goblin") is ProtoKretolak
			and ProtoHorde.make_monster(Dungeons.MINE, "archer") is ProtoProcarz
			and ProtoHorde.make_monster(Dungeons.MINE, "brute") is ProtoStoneGolem,
			"potwory: kretołak, karzeł-procarz, skalny golem")
	_check(ProtoDecor.DATA[Dungeons.MINE].size() >= 10 and ProtoDecor.DATA[Dungeons.MINE].all(func(d: Dictionary) -> bool:
			return ResourceLoader.exists("res://assets/watra/decor/mine/%s.png" % d.f)), "ozdoby kopalni mają grafiki")
	await _test_rockfall(game)
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


func _fresh(hero: ProtoHero) -> void:
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0


func _test_rockfall(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.MINE))
	await process_frame
	var hero := _setup(arena)
	var rf: ProtoRockfall = arena.rockfall
	_check(arena.climate == Dungeons.MINE and arena.summon_button.text == "Przyzwij Króla Karłów" and rf != null,
			"poziom 46: Kopalnia karłów z Osuwiskami")
	rf.passive = true
	hero.position = Vector2(0, 40)
	rf.start()
	_check(rf.pending() == ProtoRockfall.ROCKS and rf.hits == 0, "zapowiedź: %d koła głazów" % rf.pending())
	await _wait(ProtoRockfall.WARN + 0.2)
	_check(rf.hits == 1 and hero.hp < hero.max_hp, "głaz spada na postać i rani")
	_check(rf.rock_count() == ProtoRockfall.ROCKS and ProtoDecor.obstacles.size() == ProtoRockfall.ROCKS
			and hero.obstacles.size() == ProtoRockfall.ROCKS, "głazy zostają jako przeszkody")
	# osłona: kamień leci przez głaz w postać za nim - rozbija się na głazie
	var at: Vector2 = rf._rocks[0].at
	hero.position = at + Vector2(40, 0)
	_fresh(hero)
	var b := ProtoArrow.new()
	b.hero = hero
	b.direction = Vector2.RIGHT
	b.damage = 10
	b.position = at + Vector2(-50, 0)
	arena.get_node("World").add_child(b)
	await _wait(1.0)
	_check(rf.blocked >= 1 and hero.hp == hero.max_hp, "pocisk rozbija się na głazie, postać za nim cała")
	await _wait(ProtoRockfall.STAY)
	_check(rf.rock_count() == 0 and ProtoDecor.obstacles.is_empty() and hero.obstacles.is_empty(),
			"głazy kruszą się i przestają zawadzać")
	arena.queue_free()
	await process_frame


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.MINE))
	await process_frame
	var hero := _setup(arena)
	arena.rockfall.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	# kretołak: zakopany sunie do postaci, wyskakuje spod niej
	var k: ProtoKretolak = horde.spawn_at(hero.position + Vector2(70, 0), "goblin")
	await process_frame
	_check(k.burrow == "dig" and not k.is_in_group(ProtoWeapon.TARGETS), "kretołak zakopany - nie da się go trafić")
	for i in 60:
		await _wait(0.05)
		if k.burrow == "":
			break
	_check(k.burrow == "" and k.rise_hits == 1 and hero.hp < hero.max_hp and k.is_in_group(ProtoWeapon.TARGETS),
			"kretołak wyskakuje spod postaci i rani")
	_fresh(hero)
	k._cooldown = 0.0
	for i in 40:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp, "kretołak tnie pazurami")
	hero.position = k.position + Vector2(220, 0)
	k._reburrow_cd = 0.0
	await _wait(0.8)
	_check(k.burrow == "dig", "postać odbiegła - kretołak znów się zakopuje")
	k.queue_free()
	# karzeł-procarz: kamień z procy
	await _wait(0.3)
	hero.position = Vector2(0, 40)
	_fresh(hero)
	var p: ProtoProcarz = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	p._cooldown = 0.0
	var stone := false
	for i in 80:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.element == Elements.EARTH and c._sprite.texture == ProtoProcarz.STONE_TEX:
				stone = true
		if hero.hp < hero.max_hp:
			break
	_check(stone and hero.hp < hero.max_hp, "karzeł-procarz ciska kamieniem z procy")
	p.queue_free()
	# skalny golem: cios w koło
	await _wait(0.5)
	_fresh(hero)
	var g: ProtoStoneGolem = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	for i in 80:
		await _wait(0.05)
		if g._telegraph and is_instance_valid(g._telegraph):
			hero.position = g._telegraph.global_position
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp, "skalny golem: cios pięścią w koło")
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_boss(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.MINE) + 1)
	await process_frame
	var hero := _setup(arena)
	arena.rockfall.passive = true
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var king := arena.chief as ProtoDwarfKing
	_check(king != null and arena.boss_box.get_child(0).text == "Król Karłów", "przyzwany Król Karłów")
	king.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# uderzenie młotem: postać na pasie fali, poza kołem
	hero.position = king.position + Vector2(100, 0)
	_fresh(hero)
	king.start_attack("hammer")
	_check(king._telegraph != null and king._waves.size() == ProtoDwarfKing.WAVES
			and not king._telegraph.contains(hero.global_position)
			and king._waves.any(func(t: ProtoTelegraph) -> bool: return t.contains(hero.global_position)),
			"młot: koło i %d pasy fali w stronę postaci" % king._waves.size())
	await _wait(ProtoDwarfKing.HAMMER_WARN + 0.1)
	_check(king.hammer_hits == 1 and hero.hp < hero.max_hp and king._waves.is_empty(), "fala młota rani na pasie")
	# młot w kole
	await _wait(1.0)
	hero.position = king.position + Vector2(0, 20)
	_fresh(hero)
	king.start_attack("hammer")
	await _wait(ProtoDwarfKing.HAMMER_WARN + 0.1)
	_check(king.hammer_hits == 2 and hero.hp < hero.max_hp, "młot rani w kole wokół Króla")
	# deszcz odłamków
	await _wait(1.0)
	hero.position = king.position + Vector2(90, 30)
	_fresh(hero)
	king.start_attack("shards")
	_check(king.shards_pending() == ProtoDwarfKing.SHARDS, "deszcz odłamków: %d kół" % king.shards_pending())
	await _wait(ProtoDwarfKing.SHARD_WARN + 0.1)
	_check(king.shard_hits >= 1 and hero.hp < hero.max_hp, "odłamek pod postacią rani")
	await _wait(ProtoDwarfKing.SHARD_STEP * ProtoDwarfKing.SHARDS + 0.2)
	_check(king.shards_pending() == 0, "wszystkie odłamki spadły")
	# przywołanie skalnych golemów
	await _wait(0.5)
	var before := 0
	for c in arena.get_node("World").get_children():
		before += 1 if c is ProtoStoneGolem else 0
	king.start_attack("summon")
	await _wait(ProtoDwarfKing.SUMMON_TIME + 0.2)
	var after := 0
	for c in arena.get_node("World").get_children():
		after += 1 if c is ProtoStoneGolem else 0
	_check(after - before == ProtoDwarfKing.SUMMON_COUNT, "przywołanie: %d skalne golemy" % (after - before))
	arena.queue_free()
	await process_frame

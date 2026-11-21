extends SceneTree
## Test czwartego lochu - Górskie równiny (Dungeons.PLAINS, 15.11.2026): od 16. poziomu, porażenie bohatera (więcej
## obrażeń przez chwilę), potwory (ptakoczłek wojownik z doskokiem po czerwonym pasie, miotacz oszczepów, szaman
## burzy z piorunem w kole pod postacią) i boss Gromoskrzydły (orzeł z Watry: burza piorunów, nurkowanie w pasie,
## podmuch z odrzutem i piórami; lata - ozdoby go nie zatrzymują).

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
	_check(Dungeons.for_level(Dungeons.first_level(Dungeons.PLAINS)) == Dungeons.PLAINS and ProtoHorde.make_monster(Dungeons.PLAINS, "goblin") is ProtoBirdman
			and ProtoHorde.make_monster(Dungeons.PLAINS, "archer") is ProtoBirdmanThrower
			and ProtoHorde.make_monster(Dungeons.PLAINS, "brute") is ProtoBirdmanShaman,
			"od 16: Górskie równiny - wojownik, miotacz, szaman burzy")
	await _test_monsters(game)
	await _test_eagle(game)
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


## Bez ozdób na drodze (losowy układ nie może psuć testów ruchu).
func _clear_decor(hero: ProtoHero) -> void:
	ProtoDecor.obstacles.clear()
	hero.obstacles.clear()


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.PLAINS))
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	_clear_decor(hero)
	_check(arena.climate == Dungeons.PLAINS and arena.summon_button.text == "Przyzwij Gromoskrzydłego", "poziom 16: Górskie równiny")
	# porażenie: więcej obrażeń przez chwilę
	hero.protection = 0.0
	hero.dodge = 0.0
	hero.take_damage(100)
	var plain := hero.max_hp - hero.hp
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	hero.shock(1.0)
	hero.take_damage(100)
	_check(hero.max_hp - hero.hp == roundi(plain * ProtoHero.SHOCK_MULT), "porażenie: +25%% obrażeń (%d -> %d)" % [plain, hero.max_hp - hero.hp])
	await _wait(1.1)
	_check(hero.shock_left <= 0.0, "porażenie mija")
	# wojownik: doskok po czerwonym pasie
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	var b: ProtoBirdman = horde.spawn_at(hero.position + Vector2(80, 0), "goblin")
	await process_frame
	b._leap_cooldown = 0.0
	await _wait(0.1)
	_check(b.leaping() and b._leap_line != null and b._leap_line.contains(hero.global_position), "wojownik: czerwony pas doskoku do postaci")
	await _wait(ProtoBirdman.LEAP_WARN + ProtoBirdman.LEAP_TIME + 0.1)
	_check(hero.hp < hero.max_hp and b.position.distance_to(hero.position) < 30.0, "doskok rani stojącą postać")
	b.queue_free()
	var b2: ProtoBirdman = horde.spawn_at(hero.position + Vector2(80, 0), "goblin")
	await process_frame
	b2._leap_cooldown = 0.0
	await _wait(0.1)
	hero.position += Vector2(0, 40)  # zejście z pasa
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	b2._cooldown = 99.0
	await _wait(ProtoBirdman.LEAP_WARN + ProtoBirdman.LEAP_TIME + 0.05)
	_check(hero.hp == hero.max_hp, "zejście z pasa - doskok chybia")
	b2.queue_free()
	# miotacz: oszczep (większa strzała)
	var t: ProtoBirdmanThrower = horde.spawn_at(hero.position + Vector2(100, 0), "archer")
	await process_frame
	t._cooldown = 0.0
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	var javelin := false
	for i in 60:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.scale.x > 1.2:
				javelin = true
		if hero.hp < hero.max_hp:
			break
	_check(javelin and hero.hp < hero.max_hp, "miotacz rzuca oszczepem")
	t.queue_free()
	# szaman: piorun w kole pod postacią, porażenie
	await _wait(0.4)
	hero._invulnerable = 0.0
	hero.shock_left = 0.0
	var s: ProtoBirdmanShaman = horde.spawn_at(hero.position + Vector2(90, 0), "brute")
	await process_frame
	s._cooldown = 0.0
	hero.hp = hero.max_hp
	await _wait(0.1)
	_check(s._state == "attack" and is_instance_valid(s._telegraph) and s._telegraph.contains(hero.global_position)
			and s._telegraph.global_position.distance_to(hero.global_position) < 5.0, "szaman: koło ostrzeżenia pod postacią")
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp < hero.max_hp and hero.shock_left > 0.0, "piorun szamana rani i poraża")
	s.queue_free()
	arena.queue_free()
	await process_frame


func _test_eagle(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.PLAINS) + 1)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	_clear_decor(hero)
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var e := arena.chief as ProtoStormEagle
	_check(e != null and arena.boss_box.get_child(0).text == "Gromoskrzydły" and not e.grounded, "przyzwany Gromoskrzydły (lata)")
	e.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# burza
	hero.position = e.position + Vector2(0, 90)
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	e.start_attack("storm")
	await _wait(ProtoStormEagle.STORM_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.shock_left > 0.0, "burza: piorun w kole pod postacią rani i poraża")
	await _wait(ProtoStormEagle.STORM_STEP * ProtoStormEagle.STORM_BOLTS + ProtoStormEagle.STORM_WARN)
	_check(e.storm_pending() == 0, "burza się kończy")
	# nurkowanie
	await _wait(0.6)
	hero.position = e.position + Vector2(0, 90)
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	var start := e.position
	e.start_attack("dive")
	_check(e._telegraph != null and e._telegraph.length > 0.0 and e._telegraph.contains(hero.global_position), "nurkowanie: pas do postaci")
	await _wait(ProtoStormEagle.DIVE_WARN + ProtoStormEagle.DIVE_TIME + 0.1)
	_check(hero.hp < hero.max_hp and e.position.distance_to(start) > 100.0, "orzeł przelatuje pasem i rani")
	# podmuch: odrzut i pióra
	await _wait(0.6)
	hero.position = e.position + Vector2(0, 25)
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	e.start_attack("gust")
	await _wait(ProtoStormEagle.GUST_WARN + 0.05)
	var feathers := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoArrow and c.element == Elements.LIGHTNING:
			feathers += 1
	_check(hero.hp < hero.max_hp and hero.leaping(), "podmuch rani i odrzuca")
	_check(feathers >= ProtoStormEagle.FEATHERS - 2, "podmuch rozsiewa pióra (%d)" % feathers)
	await _wait(0.4)
	_check(hero.position.distance_to(e.position) > 40.0, "postać odrzucona od orła")
	e.take_damage(10000000, hero.global_position)
	await process_frame
	_check(not e.alive() and arena.phase == "loot", "Gromoskrzydły pada, skrzynia")
	arena.queue_free()
	await process_frame

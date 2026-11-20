extends SceneTree
## Test piątego lochu - Wulkaniczne równiny (Dungeons.VOLCANO, 15.11.2026): od 41. poziomu, podpalenie bohatera
## (płomienie co pół sekundy, mniej o odporność), płonąca ziemia (ProtoFirePatch), potwory (salamandra podpala
## ugryzieniem, ognik pluje podpalającym żarem, żużlowy golem zostawia płonącą ziemię) i boss Żywiołak ognia
## (fala ognia w pierścieniu, deszcz lawy, ognisty taran ze śladem ognia).

var _failed := 0


func _initialize() -> void:
	DungeonLevels.enemy_hp = 1.0  # liczby w testach bez próby x3 zdrowia / x2 obrażeń wrogów (20.11.2026)
	DungeonLevels.enemy_damage = 1.0
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
	_check(Dungeons.for_level(41) == Dungeons.VOLCANO and ProtoHorde.make_monster(Dungeons.VOLCANO, "goblin") is ProtoSalamander
			and ProtoHorde.make_monster(Dungeons.VOLCANO, "archer") is ProtoFireWisp
			and ProtoHorde.make_monster(Dungeons.VOLCANO, "brute") is ProtoSlagGolem,
			"od 41: Wulkaniczne równiny - salamandra, ognik, żużlowy golem")
	var t := ProtoTelegraph.new()
	t.radius = 100.0
	t.inner = 26.0
	root.add_child(t)
	t.global_position = Vector2.ZERO
	_check(t.contains(Vector2(60, 0)) and not t.contains(Vector2(10, 0)) and not t.contains(Vector2(120, 0)),
			"pierścień: groźny pas, bezpiecznie przy środku i daleko")
	t.queue_free()
	await _test_monsters(game)
	await _test_elemental(game)
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


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, 41)
	await process_frame
	var hero := _setup(arena)
	var horde: ProtoHorde = arena.horde_spawner
	_check(arena.climate == Dungeons.VOLCANO and arena.summon_button.text == "Przyzwij Żywiołaka", "poziom 41: Wulkaniczne równiny")
	# podpalenie: płomienie co pół sekundy, mniej o odporność, bez nietykalności
	hero.element_res = 0.5
	hero.ignite(20, 1.1)
	await _wait(0.6)
	_check(hero.max_hp - hero.hp == 10 and hero._invulnerable <= 0.0, "podpalenie: płomień 20 - połowa przez odporność (%d)" % (hero.max_hp - hero.hp))
	await _wait(0.8)
	_check(hero.max_hp - hero.hp == 20 and hero.burn_left <= 0.0, "dwa płomienie i koniec podpalenia")
	hero.element_res = 0.0
	# płonąca ziemia
	hero.hp = hero.max_hp
	var patch := ProtoFirePatch.spawn(arena.get_node("World"), hero.global_position, hero, 20.0, 1.0, 5)
	await _wait(0.1)
	_check(hero.burn_left > 0.0, "płonąca ziemia podpala stojącą postać")
	await _wait(1.2)
	_check(not is_instance_valid(patch), "płonąca ziemia gaśnie")
	await _wait(2.5)
	# salamandra
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var s: ProtoSalamander = horde.spawn_at(hero.position + Vector2(12, 0), "goblin")
	await process_frame
	s._cooldown = 0.0
	await _wait(1.0)
	_check(hero.hp < hero.max_hp and hero.burn_left > 0.0, "salamandra gryzie i podpala")
	s.queue_free()
	# ognik
	hero.burn_left = 0.0
	hero._invulnerable = 0.0
	var w: ProtoFireWisp = horde.spawn_at(hero.position + Vector2(100, 0), "archer")
	await process_frame
	w._cooldown = 0.0
	var ember := false
	for i in 60:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.element == Elements.FIRE and c.ignite > 0:
				ember = true
		if hero.burn_left > 0.0:
			break
	_check(ember and hero.burn_left > 0.0, "ognik pluje żarem, który podpala")
	w.queue_free()
	# golem: płonąca ziemia po ciosie
	await _wait(0.5)
	var g: ProtoSlagGolem = horde.spawn_at(hero.position + Vector2(25, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	await _wait(ProtoGoblinBrute.SLAM_WARN + 0.2)
	var patches := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoFirePatch:
			patches += 1
	_check(patches >= 1, "golem zostawia płonącą ziemię")
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_elemental(game: Node) -> void:
	var arena := _arena(game, 42)
	await process_frame
	var hero := _setup(arena)
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var e := arena.chief as ProtoFireElemental
	_check(e != null and arena.boss_box.get_child(0).text == "Żywiołak ognia", "przyzwany Żywiołak ognia")
	e.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# fala ognia: w pasie obrywasz, przy nim nie
	hero.position = e.position + Vector2(0, 40)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	e.start_attack("wave")
	_check(e._telegraph != null and e._telegraph.inner > 0.0 and e._telegraph.contains(hero.global_position), "fala ognia: pierścień wokół Żywiołaka")
	await _wait(ProtoFireElemental.WAVE_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.burn_left > 0.0, "fala rani i podpala w pierścieniu")
	await _wait(0.8)
	hero.position = e.position + Vector2(0, 8)
	hero.hp = hero.max_hp
	hero.burn_left = 0.0
	hero._invulnerable = 0.0
	e.start_attack("wave")
	await _wait(ProtoFireElemental.WAVE_WARN + 0.1)
	_check(hero.hp == hero.max_hp, "tuż przy Żywiołaku bezpiecznie")
	# deszcz lawy
	await _wait(0.8)
	hero.position = e.position + Vector2(0, 90)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	e.start_attack("rain")
	_check(e.rain_pending() == ProtoFireElemental.RAIN_DROPS, "deszcz lawy: %d kół" % e.rain_pending())
	await _wait(ProtoFireElemental.RAIN_WARN + 0.1)
	_check(hero.hp < hero.max_hp, "lawa trafia stojącą postać")
	await _wait(1.2)
	_check(e.rain_pending() == 0, "cała lawa spadła")
	# ognisty taran
	await _wait(0.5)
	hero.burn_left = 0.0
	hero.position = e.position + Vector2(0, 90)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var start := e.position
	e.start_attack("charge")
	_check(e._telegraph != null and e._telegraph.length > 0.0 and e._telegraph.contains(hero.global_position), "taran: pas do postaci")
	await _wait(ProtoFireElemental.CHARGE_WARN + ProtoFireElemental.CHARGE_TIME + 0.1)
	var trail := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoFirePatch:
			trail += 1
	_check(hero.hp < hero.max_hp and e.position.distance_to(start) > 100.0 and trail >= 3, "taran rani i zostawia ślad ognia (%d)" % trail)
	e.take_damage(10000000, hero.global_position)
	await process_frame
	_check(not e.alive() and arena.phase == "loot", "Żywiołak pada, skrzynia")
	arena.queue_free()
	await process_frame

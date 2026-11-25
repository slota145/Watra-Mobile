extends SceneTree
## Test szóstego lochu - Podniebne wyspy (Dungeons.SKY, 21.11.2026): miejsce na drabince (21-25, przed Wulkanicznymi),
## odporności (powietrze +20%, ziemia -20%), potwory (latawiec przelatuje przez postać, wiła ciska ostrze wiatru, które
## odpycha, wichrowiec wciąga do koła), wiatr (podmuch spycha postać i potwory, wędrowna trąba wciąga, rani i wyrzuca)
## i boss Gryf (pikowanie, podmuch z ostrzami wiatru, szpony, trąby w pościgu).

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
	_check(Dungeons.first_level(Dungeons.SKY) == 21 and Dungeons.for_level(25) == Dungeons.SKY
			and Dungeons.for_level(26) == Dungeons.VOLCANO and Dungeons.for_level(20) == Dungeons.PLAINS
			and Dungeons.cycle_length() == 40 and Dungeons.for_level(61) == Dungeons.SKY,
			"drabinka: Podniebne wyspy 21-25 (po Górskich równinach), drugi krąg 61-65 (od 25.11.2026 krąg ma 40 poziomów)")
	var r := Dungeons.resists(Dungeons.SKY, 21)
	var base := DungeonLevels.base_resist(21)
	_check(is_equal_approx(r[Elements.AIR], base + 0.2) and is_equal_approx(r[Elements.EARTH], base - 0.2),
			"odporności: powietrze +20%, ziemia -20%")
	_check(ProtoHorde.make_monster(Dungeons.SKY, "goblin") is ProtoLatawiec
			and ProtoHorde.make_monster(Dungeons.SKY, "archer") is ProtoWila
			and ProtoHorde.make_monster(Dungeons.SKY, "brute") is ProtoWichrowiec, "potwory: latawiec, wiła, wichrowiec")
	await _test_monsters(game)
	await _test_wind(game)
	await _test_gryf(game)
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
	if arena.wind:
		arena.wind.passive = true
		for t in arena.wind.tornadoes:
			t.queue_free()
		arena.wind.tornadoes.clear()
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	ProtoDecor.obstacles.clear()
	hero.obstacles.clear()
	return hero


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.SKY))
	await process_frame
	var hero := _setup(arena)
	var horde: ProtoHorde = arena.horde_spawner
	_check(arena.climate == Dungeons.SKY and arena.summon_button.text == "Przyzwij Gryfa" and arena.wind != null,
			"poziom 21: Podniebne wyspy z wiatrem")
	# latawiec: zawisa, przelatuje przez postać i rani
	hero.position = Vector2(0, 40)
	var l: ProtoLatawiec = horde.spawn_at(hero.position + Vector2(70, 0), "goblin")
	await process_frame
	l._swoop_cooldown = 0.0
	var seen_swoop := false
	for i in 40:
		await _wait(0.05)
		seen_swoop = seen_swoop or l.swooping()
		if hero.hp < hero.max_hp:
			break
	_check(seen_swoop and hero.hp < hero.max_hp, "latawiec przelatuje przez postać i rani")
	await _wait(0.3)
	_check(l.position.x < hero.position.x, "latawiec jest już za postacią")
	l.queue_free()
	# wiła: ostrze wiatru, odpycha
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var w: ProtoWila = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	w._cooldown = 0.0
	var blade := false
	var before := hero.position
	for i in 70:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.wind and c.element == Elements.AIR:
				blade = true
		if hero.hp < hero.max_hp:
			break
	_check(blade and hero.hp < hero.max_hp and hero.position.x < before.x, "wiła ciska ostrze wiatru: rani i odpycha")
	w.queue_free()
	# wichrowiec: wciąga do koła w czasie zamachu
	await _wait(0.5)
	hero.hp = hero.max_hp
	var g: ProtoWichrowiec = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	await _wait(0.1)
	_check(g.pulling(), "wichrowiec zaczyna zamach z wirem")
	var center: Vector2 = g._telegraph.global_position if g._telegraph else g.global_position
	hero.position = center + Vector2(-60, 0)
	var d0 := hero.position.distance_to(center)
	await _wait(0.5)
	_check(hero.position.distance_to(center) < d0 - 8.0, "wichrowiec wciąga postać (%.0f -> %.0f)" % [d0, hero.position.distance_to(center)])
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_wind(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.SKY))
	await process_frame
	var hero := _setup(arena)
	var wind: ProtoWind = arena.wind
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	var g: ProtoGoblin = horde.spawn_at(Vector2(0, -150), "goblin")
	await process_frame
	g.stun(10.0)
	var g0 := g.position
	wind.passive = false
	wind.start_gust(Vector2.RIGHT)
	await _wait(ProtoWind.WARN * 0.5)
	_check(wind.state == "warn" and hero.position.x == 0.0, "zapowiedź podmuchu: strzałki, jeszcze nie wieje")
	await _wait(ProtoWind.WARN * 0.5 + ProtoWind.BLOW * 0.7)
	_check(wind.state == "blow" and hero.position.x > 25.0 and g.position.x > g0.x + 20.0,
			"podmuch spycha postać (%.0f px) i potwory (%.0f px)" % [hero.position.x, g.position.x - g0.x])
	await _wait(ProtoWind.BLOW * 0.4)
	_check(wind.state == "calm", "podmuch cichnie")
	wind.passive = true
	g.queue_free()
	# trąba: wciąga, rani i wyrzuca
	var t := ProtoTornado.new()
	t.hero = hero
	t.bounds = Rect2(-1, -1, 2, 2)
	t.damage = 30
	t.position = hero.position + Vector2(40, 0)
	arena.get_node("World").add_child(t)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	var hit := false
	for i in 60:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			hit = true
			break
	await _wait(0.4)
	_check(hit and hero.position.distance_to(t.position) > 40.0, "trąba wciąga, rani i wyrzuca postać")
	t.queue_free()
	arena.queue_free()
	await process_frame


func _test_gryf(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.SKY) + 1)
	await process_frame
	var hero := _setup(arena)
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var gr := arena.chief as ProtoGryf
	_check(gr != null and arena.boss_box.get_child(0).text == "Gryf", "przyzwany Gryf")
	gr.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# pikowanie
	hero.position = gr.position + Vector2(0, 90)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	gr.start_attack("dive")
	_check(gr._telegraph != null and gr._telegraph.length > 0.0 and gr._telegraph.contains(hero.global_position), "pikowanie: pas przez postać")
	await _wait(ProtoGryf.DIVE_WARN + ProtoGryf.DIVE_TIME + 0.1)
	_check(hero.hp < hero.max_hp, "pikowanie rani postać w pasie")
	# podmuch: wachlarz, odrzut, ostrza wiatru
	await _wait(0.8)
	hero.position = gr.position + Vector2(0, 60)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	gr.start_attack("gust")
	_check(gr._telegraph != null and gr._telegraph.arc > 0.0 and gr._telegraph.contains(hero.global_position), "podmuch: wachlarz w stronę postaci")
	var y0 := hero.position.y
	await _wait(ProtoGryf.GUST_WARN + 0.05)
	var blades := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoArrow and c.wind:
			blades += 1
	await _wait(0.3)
	_check(hero.hp < hero.max_hp and hero.position.y > y0 + 30.0 and blades == ProtoGryf.BLADES,
			"podmuch rani, odrzuca i wypuszcza %d ostrzy wiatru" % blades)
	# szpony
	await _wait(0.8)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	gr.start_attack("talons")
	var spot := hero.global_position
	_check(gr._telegraph != null and gr._telegraph.contains(spot), "szpony: koło pod postacią")
	await _wait(ProtoGryf.SLAM_WARN_G + ProtoGryf.SLAM_TIME + 0.1)
	_check(hero.hp < hero.max_hp and gr.global_position.distance_to(spot) < 5.0, "gryf spada szponami na postać")
	# trąby w pościgu
	await _wait(0.8)
	gr.start_attack("twisters")
	await _wait(ProtoGryf.TWISTER_WARN + 0.1)
	_check(gr.twisters.size() == ProtoGryf.TWISTERS and gr.twisters[0].chase, "trąby powietrzne w pościgu (%d)" % gr.twisters.size())
	await _wait(ProtoGryf.TWISTER_LIFE + 0.3)
	gr._clean_twisters()
	_check(gr.twisters.is_empty(), "trąby znikają po czasie")
	gr.take_damage(10000000, hero.global_position)
	await process_frame
	_check(not gr.alive() and arena.phase == "loot", "Gryf pada, skrzynia")
	arena.queue_free()
	await process_frame

extends SceneTree
## Test drugiego lochu - Zatopione podziemia (Dungeons, 15.11.2026): wspólna drabinka poziomów (po 5 poziomów: 1-5 gobliny, 6-10
## podziemia, potem kolejne kręgi, od 101 losowo), odporność na żywioły (premia przedmiotów, sufit, tylko ciosy żywiołów), potwory
## (topielec przemacza, żabołak pluje wodą, topielica mrozi koło wokół siebie) i boss Wodnik (fala w pasie, wir,
## lodowe krople, wezwanie topielców).

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
	_test_levels()
	_test_resistance()
	await _test_monsters(game)
	await _test_wodnik(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_levels() -> void:
	_check(Dungeons.for_level(1) == Dungeons.GOBLINS and Dungeons.for_level(5) == Dungeons.GOBLINS
			and Dungeons.for_level(6) == Dungeons.FLOODED and Dungeons.for_level(10) == Dungeons.FLOODED
			and Dungeons.for_level(11) == Dungeons.CATACOMBS and Dungeons.for_level(15) == Dungeons.CATACOMBS
			and Dungeons.for_level(16) == Dungeons.PLAINS and Dungeons.for_level(20) == Dungeons.PLAINS
			and Dungeons.for_level(21) == Dungeons.SKY and Dungeons.for_level(25) == Dungeons.SKY
			and Dungeons.for_level(26) == Dungeons.VOLCANO and Dungeons.for_level(30) == Dungeons.VOLCANO,
			"drabinka po 5 poziomów: gobliny, podziemia, Katakumby, Górskie równiny, Podniebne wyspy, Wulkaniczne równiny")
	var cycle := Dungeons.cycle_length()
	_check(Dungeons.for_level(cycle + 1) == Dungeons.GOBLINS and Dungeons.for_level(cycle + 6) == Dungeons.FLOODED
			and Dungeons.cycle_of(cycle) == 1 and Dungeons.cycle_of(cycle + 1) == 2 and Dungeons.for_level(100) == Dungeons.ORDER[(99 / 5) % Dungeons.ORDER.size()]
			and Dungeons.first_level(Dungeons.FLOODED) == 6, "drugi krąg od %d. poziomu, krąg za kręgiem do 100." % (cycle + 1))
	var seen := {}
	for i in 200:
		seen[Dungeons.for_level(101 + i % 50)] = true
	_check(seen.size() == Dungeons.ORDER.size() and Dungeons.is_random(101) and not Dungeons.is_random(100),
			"od 101 loch losowy przy każdym wejściu")
	_check(ProtoHorde.make_monster(Dungeons.FLOODED, "goblin") is ProtoDrowner
			and ProtoHorde.make_monster(Dungeons.FLOODED, "archer") is ProtoFrogman
			and ProtoHorde.make_monster(Dungeons.FLOODED, "brute") is ProtoRusalka
			and not ProtoHorde.make_monster(Dungeons.GOBLINS, "goblin") is ProtoDrowner,
			"potwory według lochu: topielec, żabołak, topielica")


func _test_resistance() -> void:
	_check(Items.STAT_FORMATS.has("element_res_pct") and Items.AFFIXES.has("element_res_pct")
			and Items.CAPS.element_res_pct == 75.0 and Gems.JEWELS.onyx.pool.has("element_res_pct"),
			"odporność na żywioły: premia przedmiotów i onyksu, sufit 75%")


func _arena(game: Node, level: int) -> Node:
	game.reset_hero()
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FLOODED))
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	_check(arena.climate == Dungeons.FLOODED and horde.climate == Dungeons.FLOODED
			and arena.summon_button.text == "Przyzwij Wodnika", "poziom 6: Zatopione podziemia, przyzwanie Wodnika")
	var props := 0
	var near := 0
	for c in arena.get_node("World").get_children():
		if c is Sprite2D and c.texture and c.texture.resource_path.contains("/decor/flooded/"):
			props += 1
			if c.position.distance_to(Vector2(0, 40)) < ProtoDecor.CLEAR_RADIUS:
				near += 1
	_check(arena.decor != null and props == ProtoDecor.COUNT and near == 0 and arena.decor.glow_count() > 0,
			"wystrój: %d ozdób podziemi, wolne miejsce startu, poświaty (%d)" % [props, arena.decor.glow_count()])
	# kolizje: wysokie ozdoby to przeszkody dla postaci i potworów
	_check(not ProtoDecor.obstacles.is_empty() and hero.obstacles.size() >= ProtoDecor.obstacles.size(),
			"wysokie ozdoby mają przeszkody (%d), postać je zna" % ProtoDecor.obstacles.size())
	var o: Vector3 = ProtoDecor.obstacles[0]
	var inside := Vector2(o.x, o.y)
	var out := ProtoDecor.push_out(inside)
	_check(out.distance_to(inside) >= o.z * 0.49, "punkt w ozdobie zostaje z niej wypchnięty")
	var g: ProtoGoblin = horde.spawn_at(inside + Vector2(1, 0), "goblin")
	await process_frame
	await process_frame
	var gap := Vector2(g.position.x - o.x, (g.position.y - o.y) * 2.0).length()
	_check(gap >= o.z, "potwór nie stoi w ozdobie (%.1f >= %.1f)" % [gap, o.z])
	g.queue_free()
	# odporność: tylko ciosy żywiołów
	hero.element_res = 0.5
	hero.protection = 0.0
	hero.dodge = 0.0
	hero.hp = hero.max_hp
	hero.take_damage(40, Elements.WATER)
	_check(hero.hp == hero.max_hp - 20, "odporność 50%% zmniejsza cios wody o połowę (%d)" % (hero.max_hp - hero.hp))
	hero._invulnerable = 0.0
	hero.hp = hero.max_hp
	hero.take_damage(40)
	_check(hero.hp == hero.max_hp - 40, "cios fizyczny bez odporności")
	hero._invulnerable = 0.0
	hero.element_res = 0.0
	hero.set_level(game.hero_level, {"element_res_pct": 300.0})
	_check(is_equal_approx(hero.element_res, 0.75), "sufit odporności 75%")
	hero.set_level(game.hero_level, {})
	# topielec: cios wodą przemacza (spowolnienie)
	var d: ProtoDrowner = horde.spawn_at(hero.position + Vector2(12, 0), "goblin")
	await process_frame
	_check(d is ProtoDrowner and d.element == Elements.WATER, "w strumieniu topielec")
	hero.hp = hero.max_hp
	d._cooldown = 0.0
	await _wait(1.0)
	_check(hero.hp < hero.max_hp and hero.chill > 0.0 and hero.chill_left > 0.0, "topielec rani i przemacza (spowolnienie %.2f)" % hero.chill)
	var x0 := hero.position.x
	hero.velocity = Vector2.ZERO
	d.queue_free()
	await _wait(ProtoDrowner.SOAK_TIME + 0.1)
	_check(hero.chill == 0.0 and x0 == hero.position.x, "przemoczenie mija")
	# żabołak: kula wody z przemoczeniem
	hero._invulnerable = 0.0
	var f: ProtoFrogman = horde.spawn_at(hero.position + Vector2(100, 0), "archer")
	await process_frame
	f._cooldown = 0.0
	hero.hp = hero.max_hp
	var shot := false
	for i in 60:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.water:
				shot = true
		if hero.hp < hero.max_hp:
			break
	_check(shot and hero.hp < hero.max_hp and hero.chill > 0.0, "żabołak pluje kulą wody, która przemacza")
	f.queue_free()
	# topielica: koło wokół niej samej, lód mocno spowalnia
	await _wait(0.3)
	hero._invulnerable = 0.0
	hero.chill = 0.0
	hero.chill_left = 0.0
	var r: ProtoRusalka = horde.spawn_at(hero.position + Vector2(20, 0), "brute")
	await process_frame
	r._cooldown = 0.0
	hero.max_hp = 100000  # mocniejsze potwory (17.11.2026) zabijałyby postać - nieśmiertelność leczy do pełna
	hero.hp = hero.max_hp
	await _wait(0.15)
	_check(r._state == "attack" and is_instance_valid(r._telegraph) and r._telegraph.position == r.position
			and r._telegraph.radius == ProtoRusalka.RING_RADIUS, "topielica: koło ostrzeżenia wokół niej")
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp < hero.max_hp and is_equal_approx(hero.chill, ProtoRusalka.FREEZE_SLOW), "lód rani i mocno spowalnia")
	r.queue_free()
	arena.queue_free()
	await process_frame


func _test_wodnik(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FLOODED) + 1)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var w: ProtoChief = arena.chief
	_check(w is ProtoWodnik and arena.boss_box.get_child(0).text == "Wodnik", "przyzwany Wodnik z paskiem zdrowia")
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	var wod := w as ProtoWodnik
	wod.passive = true
	wod._cooldown = 99.0
	wod._summon_cooldown = 99.0
	# fala: pas od Wodnika w stronę postaci
	hero.position = wod.position + Vector2(60, 0)
	hero.max_hp = 100000  # mocniejszy Wodnik (17.11.2026) zabijałby postać - nieśmiertelność leczy do pełna
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	wod.start_attack("wave")
	_check(wod._telegraph != null and wod._telegraph.length == ProtoWodnik.WAVE_LENGTH
			and wod._telegraph.contains(hero.global_position), "fala: czerwony pas do postaci")
	await _wait(ProtoWodnik.WAVE_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.chill > 0.0, "fala rani i przemacza")
	# zejście z pasa ratuje
	await _wait(0.8)
	wod._cooldown = 99.0
	hero._invulnerable = 0.0
	hero.position = wod.position + Vector2(60, 0)
	wod.start_attack("wave")
	hero.position = wod.position + Vector2(60, 40)
	hero.hp = hero.max_hp
	await _wait(ProtoWodnik.WAVE_WARN + 0.1)
	_check(hero.hp == hero.max_hp, "zejście z pasa - fala chybia")
	# wir: koło pod postacią, potem wciąga
	await _wait(0.8)
	wod._cooldown = 99.0
	hero._invulnerable = 0.0
	hero.position = wod.position + Vector2(80, 0)
	wod.start_attack("vortex")
	var center: Vector2 = wod._vortex_at
	await _wait(0.05)
	_check(wod.aura_active(), "krople krążą wokół Wodnika przy zapowiedzi")
	await _wait(ProtoWodnik.VORTEX_WARN + 0.05)
	_check(wod.vortex_active(), "wir kręci się w miejscu ostrzeżenia")
	hero.position = center + Vector2(50, 0)
	var before := hero.position.distance_to(center)
	await _wait(0.5)
	_check(hero.position.distance_to(center) < before - 10.0, "wir wciąga postać (%.0f -> %.0f)" % [before, hero.position.distance_to(center)])
	await _wait(ProtoWodnik.VORTEX_TIME)
	_check(not wod.vortex_active(), "wir znika po czasie")
	_check(not wod.aura_active(), "krople znikają po ataku")
	# lodowe krople
	wod._cooldown = 99.0
	wod._set_state("walk")
	wod._cooldown = 99.0
	hero.position = wod.position + Vector2(80, 0)
	hero.max_hp = 100000  # mocniejszy Wodnik (17.11.2026) zabijałby postać - nieśmiertelność leczy do pełna
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	wod.start_attack("cast")
	_check(wod._drops.size() == ProtoWodnik.DROPS and wod._drops[0].contains(hero.global_position), "lodowe krople: koła, jedno pod postacią (%d, %s, %s)" % [wod._drops.size(), wod._drops[0].global_position, hero.global_position])
	await _wait(ProtoWodnik.DROP_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.chill >= ProtoWodnik.ICE_SLOW - 0.01, "sopel rani i spowalnia")
	await _wait(1.2)
	_check(wod._drops.is_empty(), "wszystkie sople spadły")
	# wezwanie topielców
	wod._cooldown = 99.0
	var before_drowners := horde.count(ProtoDrowner)
	wod.start_attack("summon")
	await _wait(ProtoWodnik.SUMMON_TIME + 0.1)
	_check(horde.count(ProtoDrowner) == before_drowners + ProtoWodnik.SUMMON_COUNT, "wezwanie: z gejzerów wychodzą topielce")
	# śmierć
	wod.take_damage(1000000, hero.global_position)
	await process_frame
	_check(not wod.alive() and arena.phase == "loot", "Wodnik pada, skrzynia")
	arena.queue_free()
	await process_frame

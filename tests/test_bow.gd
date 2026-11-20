extends SceneTree
## Test łuku (20.11.2026): dostępność (loch 5 albo 1500 zł), powietrze, zmiana broni (węzeł ProtoBow, strzał pod „Atak”),
## a w walce: strzał (leci, trafia, odpycha), Poszukująca strzała (skręca, przebija, szuka kolejnych), Deszcz strzał
## (rani w kręgu), Potężny strzał (ładowanie, podmuch odpycha, strzała przebija), Balista (stoi, obraca się, strzela);
## kamienie unikalne (wielostrzał, przywołanie z rezerwacją many, 3 deszcze, podmuch na boki, powtórki balisty).

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
	_test_unlock(game)
	await _test_combat(game)
	await _test_unique(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_unlock(game: Node) -> void:
	game.reset_hero()
	game.best_level = 4
	_check(Weapons.element_of("bow") == Elements.AIR and Weapons.unlock_level("bow") == 5 and Weapons.price_of("bow") == 1500,
			"łuk: powietrze, loch 5 albo 1500 zł")
	_check(Skills.of_weapon("bow").size() == 5 and Skills.basic_of("bow") == "b_shot" and Skills.is_charged("b_power"),
			"5 umiejętności, zwykły strzał, Potężny strzał ładowany")
	var unique_ok := true
	for id in Skills.of_weapon("bow"):
		unique_ok = unique_ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null
	_check(unique_ok, "każda umiejętność łuku ma kamień unikalny z ikoną")
	_check(not game.weapon_available("bow"), "przed 5. lochem łuk zamknięty")
	game.best_level = 5
	_check(game.set_weapon("bow") and game.main_skill() == "b_shot", "po 5. lochu łuk w ręku, strzał pod „Atak”")
	_check(Weapons.make("bow") is ProtoBow, "węzeł broni - ProtoBow")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _arena(game: Node) -> Node:
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _test_combat(game: Node) -> void:
	game.dev_set_level(20)
	game.best_level = 20
	game.set_weapon("bow")
	game.dev_skills()
	var arena := _arena(game)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var bow := arena.weapon as ProtoBow
	_check(bow != null, "w lochu łuk w ręku")
	hero.position = Vector2.ZERO
	var a := _goblin(arena, Vector2(90, 0))
	var b := _goblin(arena, Vector2(-90, 30))
	await _wait(0.2)
	for g in [a, b]:
		g._stunned = 60.0
	# strzał
	var hp := a.hp
	bow._aim = 0.0
	bow._shot_target = a
	bow._fire_shot()
	_check(bow._arrows.size() == 1, "strzał: strzała w locie")
	await _wait(0.5)
	_check(a.hp < hp and bow._arrows.is_empty(), "strzała trafia i znika")
	# Poszukująca: przyspiesza na wroga, po przebiciu hamuje
	hp = a.hp
	var hpb := b.hp
	bow._aim = PI / 2.0
	bow._spawn_seeker(hero.global_position, PI / 2.0)
	var speeds: Array[float] = []
	for i in 25:
		await _wait(0.1)
		var sk := bow._arrows.filter(func(x: Dictionary) -> bool: return x.has("seek"))
		if not sk.is_empty():
			speeds.append(sk[0].speed)
	_check(speeds.size() > 3 and speeds.max() > ProtoBow.SEEK_SPEED + 60.0 and speeds.min() < ProtoBow.SEEK_SPEED - 40.0,
			"Poszukująca zmienia prędkość (%d-%d)" % [roundi(speeds.min()), roundi(speeds.max())])
	_check(a.hp < hp and b.hp < hpb, "Poszukująca: skręca i trafia kolejnych wrogów")
	# kilka Poszukujących naraz: różne cele, stożek
	for s in bow._arrows:
		s.fx.queue_free()
	bow._arrows.clear()
	var c2 := _goblin(arena, Vector2(0, -100))
	await process_frame
	c2._stunned = 60.0
	bow._aim = 0.0
	for an in bow.fan(0.0, 3, ProtoBow.SEEK_PAIR, false):
		bow._spawn_seeker(hero.global_position, an)
	var tg := {}
	var starts: Array[Vector2] = []
	for s in bow._arrows:
		tg[s.target] = true
		starts.append((s.fx as Node2D).global_position)
	_check(tg.size() == 3 and starts[0].distance_to(starts[2]) > 5.0,
			"3 Poszukujące: każda na innego wroga, wylatują w stożku")
	for s in bow._arrows:
		s.fx.queue_free()
	bow._arrows.clear()
	c2.queue_free()
	await process_frame
	# Deszcz strzał
	for s in bow._arrows:  # Poszukująca mogła jeszcze lecieć
		s.fx.queue_free()
	bow._arrows.clear()
	hp = a.hp
	hpb = b.hp
	bow._add_rain(a.global_position, 1.0)
	await _wait(0.6)
	_check(a.hp < hp and b.hp == hpb, "Deszcz strzał rani w kręgu (i tylko w nim)")
	await _wait(0.8)
	_check(bow._rains.is_empty(), "deszcz się kończy")
	# Potężny strzał
	var c := _goblin(arena, Vector2(60, 0))
	await process_frame
	c._stunned = 60.0
	var cx := c.global_position.x
	hp = a.hp
	bow._power_release(hero.global_position, 0.0, 1.0, 1.0)
	await _wait(0.6)
	_check(c.global_position.x > cx + 5.0, "Potężny strzał: podmuch odpycha do przodu")
	_check(a.hp < hp, "Potężny strzał: strzała przebija i trafia dalszych")
	# Balista
	bow._aim = 0.0
	bow._add_ballista(Vector2(30, -30))
	_check(bow._ballistas.size() == 1, "balista stoi")
	hp = a.hp
	await _wait(1.5)
	_check(a.hp < hp or c.hp < c.full_hp, "balista strzela w wrogów")
	var bal: Dictionary = bow._ballistas[0]
	_check((bal.base as Node2D).global_position.distance_to(Vector2(30, -30)) < 1.0, "podstawa balisty stoi w miejscu")
	arena.queue_free()
	await process_frame


func _test_unique(game: Node) -> void:
	for id in Skills.of_weapon("bow"):
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	var arena := _arena(game)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var bow := arena.weapon as ProtoBow
	hero.position = Vector2.ZERO
	var a := _goblin(arena, Vector2(90, 0))
	var b := _goblin(arena, Vector2(-120, 60))
	var c := _goblin(arena, Vector2(20, -140))
	await _wait(0.2)
	for g in [a, b, c]:
		g._stunned = 60.0
	bow._aim = 0.0
	bow._strike_count = 1
	bow._fire_shot()
	_check(bow._arrows.size() == ProtoBow.SHOT_FAN_COUNT, "Wielostrzał: 5 strzał w stożku")
	bow._arrows.clear()
	game.skill_levels["b_shot"] = 10
	bow.skill_levels = game.skill_levels
	bow._strike_count = 3
	bow._fire_shot()
	_check(bow._arrows.size() == ProtoBow.SHOT_FAN_COUNT + 2, "10. poziom z Wielostrzałem: co trzeci strzał 7 strzał")
	for s in bow._arrows:
		s.fx.queue_free()
	bow._arrows.clear()
	# Rój Strzyboga
	game.auras = {"roj": 5}
	game.auras_on = ["roj"]
	game.inventory_changed.emit()
	await process_frame
	_check(bow.extra_projectiles == 2 and bow.projectile_mult < 1.0, "Rój Strzyboga: +2 pociski od 5. poziomu")
	bow._strike_count = 1
	bow._fire_shot()
	_check(bow._arrows.size() == ProtoBow.SHOT_FAN_COUNT + 2, "Rój: Wielostrzał z 2 strzałami więcej")
	for s in bow._arrows:
		s.fx.queue_free()
	bow._arrows.clear()
	game.auras_on = []
	game.inventory_changed.emit()
	await process_frame
	game.skill_levels["b_shot"] = 1
	bow.skill_levels = game.skill_levels
	await _wait(0.6)
	# przywołanie
	hero.mana = hero.mana_cap()
	bow.reset_cooldowns()
	_check(bow.cast("b_seeker"), "Wierny Tropiciel: przywołanie")
	await _wait(0.1)
	_check(bow._summon != null and hero.summon_reserved > 0 and hero.mana <= hero.mana_cap(),
			"przywołanie krąży i rezerwuje manę")
	var hp := a.hp
	await _wait(2.5)
	_check(a.hp < hp or b.hp < b.full_hp or c.hp < c.full_hp, "przywołanie wypuszcza Poszukujące strzały")
	bow.cast("b_seeker")
	_check(bow._summon == null and hero.summon_reserved == 0, "drugie użycie odwołuje przywołanie i oddaje rezerwację")
	# 3 deszcze
	bow._rain_volley(a.global_position, 1.0)
	_check(bow._rains.size() == 3, "Ulewa: 3 deszcze strzał na różnych wrogów")
	await _wait(1.5)
	# podmuch na boki
	var side := _goblin(arena, Vector2(70, 20))
	await process_frame
	side._stunned = 60.0
	var sy := side.global_position.y
	hp = side.hp
	bow._power_release(hero.global_position, 0.0, 0.0, 1.0)
	await _wait(0.6)
	_check(side.hp < hp and side.global_position.y > sy + 3.0, "Wichura: podmuch na boki rani i odpycha od toru")
	# powtórki balisty
	bow._aim = 0.0
	bow._add_ballista(Vector2(-40, -40))
	bow._arrows.clear()
	bow._rains.clear()
	bow._ballista_echo("b_rain")
	_check(bow._rains.size() >= 1, "Oblężnik: balista powtarza Deszcz strzał")
	bow._ballista_echo("b_seeker")
	_check(bow._arrows.any(func(x: Dictionary) -> bool: return x.has("seek")), "Oblężnik: balista powtarza Poszukującą")
	arena.queue_free()
	await process_frame
	game.dev_immortal = false

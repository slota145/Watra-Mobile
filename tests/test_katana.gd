extends SceneTree
## Test elektrycznej katany i combo z przemoczeniem (15.11.2026): dostępność (Wódz 20. poziomu albo 6000 zł), zmiana
## broni (węzeł ProtoKatana), porażenie (+15% obrażeń, przeskok na sąsiada), przemoczenie (krople, +30% od Gromu,
## dłuższy przeskok, zamrożenie lodem z odpornością), a w walce: cięcie, Iaido, Łańcuch piorunów, Sąd Peruna,
## Burza ostrzy.

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
	_test_unlock(game)
	await _test_combat(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_unlock(game: Node) -> void:
	game.reset_hero()
	game.best_level = 15
	_check(Weapons.element_of("katana") == Elements.LIGHTNING and Weapons.unlock_level("katana") == 20
			and Weapons.price_of("katana") == 6000, "katana: Grom, Wódz 20. poziomu albo 6000 zł")
	_check(Skills.of_weapon("katana").size() == 5 and Skills.basic_of("katana") == "k_slash",
			"5 umiejętności, zwykły cios - błyskawiczne cięcie")
	_check(not game.weapon_available("katana") and game.weapon_available("hydrosphere"), "po 15. poziomie bez katany")
	game.best_level = 20
	_check(game.set_weapon("katana") and game.main_skill() == "k_slash" and game.skill_slots[0] == "k_slash",
			"po 20. poziomie katana w ręku, cięcie pod „Atak”")
	_check(Weapons.make("katana") is ProtoKatana, "węzeł broni - ProtoKatana")
	_check(is_equal_approx(Elements.soak_bonus(Elements.LIGHTNING, true), Elements.SOAK_BONUS)
			and is_equal_approx(Elements.soak_bonus(Elements.COLD, true), Elements.SOAK_BONUS)
			and Elements.soak_bonus(Elements.FIRE, true) == 1.0 and Elements.soak_bonus(Elements.LIGHTNING, false) == 1.0,
			"combo: Grom i lód mocniej tylko na przemoczonym")


func _test_combat(game: Node) -> void:
	game.dev_set_level(20)
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoKatana = arena.weapon
	_check(weapon != null and weapon.element == Elements.LIGHTNING, "w lochu katana (żywioł Grom)")
	weapon.damage = Vector2i(20, 20)
	weapon.damage_mult = 1.0
	weapon.crit_chance = 0.0
	weapon.elite_mult = 1.0
	hero.position = Vector2.ZERO

	# porażenie i przemoczenie
	var a := _goblin(arena, Vector2(30, 0))
	var b := _goblin(arena, Vector2(-120, 200))
	await _wait(0.1)
	for g in [a, b]:
		g._stunned = 60.0
	var hp := a.hp
	weapon._hit(a, 1.0, hero.global_position, "k_slash", 0)
	var dry := hp - a.hp
	_check(a.is_shocked(), "trafienie kataną poraża")
	hp = a.hp
	weapon._hit(a, 1.0, hero.global_position, "k_slash", 0)
	_check(hp - a.hp == roundi(dry * (1.0 + Elements.SHOCK_BONUS)), "porażony dostaje +15%% (%d -> %d)" % [dry, hp - a.hp])
	b.soak(0.2, 3.0)
	_check(b.is_soaked() and b.get_node("_Status")._drips != null, "przemoczony wróg - krople")
	await _wait(0.05)
	_check(b.get_node("_Status")._drips.visible, "krople widać")
	hp = b.hp
	weapon._hit(b, 1.0, hero.global_position, "k_slash", 0)
	_check(hp - b.hp == roundi(dry * Elements.SOAK_BONUS), "przemoczony dostaje od Gromu +30%% (%d)" % (hp - b.hp))
	var c := _goblin(arena, Vector2(-100, 200))
	var d := _goblin(arena, Vector2(-140, 200))
	var e := _goblin(arena, Vector2(-120, 220))
	await process_frame
	var hit: Array = weapon._chain_from(b, 5, 1, ProtoKatana.ARC_RANGE)
	_check(hit.size() == 1 + Elements.SOAK_CHAIN_EXTRA, "piorun z przemoczonego przeskakuje na 3 wrogów zamiast 1")
	_check(b.freeze(0.5) and not b.freeze(0.5), "zamrożenie przemoczonego, potem chwila odporności")
	for g in [b, c, d, e]:
		g.queue_free()
	await process_frame

	# cięcie
	a._stunned = 60.0
	hp = a.hp
	weapon._attack()
	await _wait(0.3)
	_check(a.hp < hp, "błyskawiczne cięcie trafia wroga obok")
	# Iaido
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = Vector2(-60, 0)
	await process_frame
	hp = a.hp
	var from := hero.global_position
	_check(weapon.cast("k_iaido"), "Iaido rusza")
	await process_frame
	_check(hero.global_position.x > a.global_position.x and a.hp < hp, "Iaido: postać przemyka na wylot przez wroga i go rani")
	_check(hero.global_position.distance_to(from) >= 60.0, "Iaido: zryw co najmniej 60 px")
	# Łańcuch piorunów
	hero.position = Vector2.ZERO
	var line: Array = [a]  # a stoi najbliżej - łańcuch zaczyna od niego
	for i in 6:
		var g := _goblin(arena, Vector2(30 + i * 40, 40))
		line.append(g)
	await process_frame
	for g in line:
		g._stunned = 60.0
	var hps: Array = line.map(func(g: ProtoGoblin) -> int: return g.hp)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon._state = "follow"
	weapon.cast("k_chain")
	await _wait(0.6)
	var struck := 0
	for i in line.size():
		if line[i].hp < hps[i]:
			struck += 1
	_check(struck >= ProtoKatana.CHAIN_JUMPS, "Łańcuch piorunów trafia po kolei co najmniej 5 wrogów (%d)" % struck)
	# Sąd Peruna
	hps = line.map(func(g: ProtoGoblin) -> int: return g.hp)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon._state = "follow"
	weapon.cast("k_perun")
	_check(weapon._strikes.size() == ProtoKatana.PERUN_BOLTS, "Sąd Peruna: 3 pioruny")
	await _wait(0.7)
	struck = 0
	for i in line.size():
		if line[i].hp < hps[i]:
			struck += 1
	_check(weapon._strikes.is_empty() and struck >= 3, "pioruny uderzyły (%d trafionych)" % struck)
	# Burza ostrzy
	hps = line.map(func(g: ProtoGoblin) -> int: return g.hp)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon._state = "follow"
	weapon.cast("k_storm")
	_check(weapon._state == "storm", "Burza ostrzy rusza")
	await _wait(1.0)
	_check(weapon.global_position.distance_to(hero.global_position) > 20.0, "katana skacze między wrogami z dala od postaci")
	struck = 0
	for i in line.size():
		if line[i].hp < hps[i]:
			struck += 1
	_check(struck >= 3, "Burza rani kilku wrogów (%d)" % struck)
	await _wait(2.5)
	_check(weapon._state == "follow", "po 3 s Burza się kończy")
	game.dev_immortal = false
	arena.queue_free()
	await process_frame


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g

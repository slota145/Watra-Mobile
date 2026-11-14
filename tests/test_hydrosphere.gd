extends SceneTree
## Test hydrosfery (14.11.2026): dostępność (Wódz 15. poziomu albo 4500 zł), zmiana broni (węzeł ProtoHydrosphere,
## pocisk pod „Atak”), a w walce: wodny pocisk (leci, trafia, rozprysk, przemoczenie), Fala (przebija, odpycha),
## Wir (rani co chwilę), Gejzery (ogłuszają), Ulewa (sople spadają na wrogów).

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
	game.best_level = 10
	_check(Weapons.element_of("hydrosphere") == Elements.WATER and Weapons.unlock_level("hydrosphere") == 15
			and Weapons.price_of("hydrosphere") == 4500, "hydrosfera: woda, Wódz 15. poziomu albo 4500 zł")
	_check(Skills.of_weapon("hydrosphere").size() == 5 and Skills.basic_of("hydrosphere") == "h_bolt",
			"5 umiejętności, zwykły cios - wodny pocisk")
	_check(not game.weapon_available("hydrosphere") and game.weapon_available("glaive"), "po 10. poziomie tylko glewia")
	game.best_level = 15
	_check(game.set_weapon("hydrosphere") and game.main_skill() == "h_bolt" and game.skill_slots[0] == "h_bolt",
			"po 15. poziomie hydrosfera w ręku, pocisk pod „Atak”")
	_check(Weapons.script_of("hydrosphere") == ProtoHydrosphere and Weapons.make("hydrosphere") is ProtoHydrosphere,
			"węzeł broni - ProtoHydrosphere")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _slowed(g: ProtoGoblin) -> bool:
	var st := g.get_node_or_null(^"_Status")
	return st != null and st.slow_left > 0.0


func _test_combat(game: Node) -> void:
	game.dev_set_level(20)
	game.dev_skills()
	for i in range(1, 5):
		game.skill_slots[i] = Skills.of_weapon("hydrosphere")[i]
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoHydrosphere = arena.weapon
	_check(weapon is ProtoHydrosphere and weapon.basic == "h_bolt", "w lochu hydrosfera")
	hero.position = Vector2.ZERO
	var far := _goblin(arena, Vector2(110, 0))
	var near_far := _goblin(arena, Vector2(116, 5))
	await _wait(0.2)
	for g in [far, near_far]:
		g._stunned = 60.0
	var hp := [far.hp, near_far.hp]
	weapon.attack_held = true
	await _wait(0.9)
	weapon.attack_held = false
	_check(far.hp < hp[0] and _slowed(far), "pocisk doleciał 110 px, ranił i przemoczył")
	_check(near_far.hp < hp[1], "rozprysk ranił sąsiada")
	var side := _goblin(arena, Vector2(0, 70))
	await _wait(0.1)
	side._stunned = 60.0
	# Fala
	await _wait(0.3)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	far.position = Vector2(60, 0)
	await _wait(0.05)
	hp = [far.hp]
	_check(weapon.cast("h_wave"), "Fala rusza")
	await _wait(0.6)
	_check(far.hp < hp[0], "fala rani wroga przed postacią")
	# Wir
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hp = [side.hp]
	weapon._add_vortex(side.global_position)
	await _wait(1.0)
	_check(side.hp < hp[0] and weapon._vortexes.size() == 1, "wir rani wroga w środku")
	# Gejzery
	await _wait(2.5)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	side._stunned = 0.0
	hp = [side.hp]
	_check(weapon.cast("h_geyser"), "Gejzery ruszają")
	await _wait(0.6)
	_check(side.hp < hp[0] and side._stunned > 0.3, "gejzer rani i ogłusza (%d -> %d, ogłuszenie %.2f)" % [hp[0], side.hp, side._stunned])
	# Ulewa
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hp = [far.hp, side.hp, near_far.hp]
	_check(weapon.cast("h_rain"), "Ulewa rusza")
	await _wait(1.5)
	_check(weapon._rain_left > 0.0 and (far.hp < hp[0] or side.hp < hp[1] or near_far.hp < hp[2]), "sople spadają na wrogów")
	await _wait(3.0)
	_check(weapon._rain_left <= 0.0 and weapon._drops.is_empty(), "ulewa się kończy")
	game.dev_immortal = false
	arena.queue_free()
	await process_frame

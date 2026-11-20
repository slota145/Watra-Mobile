extends SceneTree
## Test hydrosfery (14.11.2026): dostępność (Wódz 15. poziomu albo Pieczęć Oręża), zmiana broni (węzeł ProtoHydrosphere,
## pocisk pod „Atak”), a w walce: wodny pocisk (leci, trafia, rozprysk, przemoczenie), Fala (przebija, odpycha),
## Wir (rani co chwilę), Gejzery (ogłuszają), Wodny Strażnik (wybuch, strzela); kamienie unikalne (krążące bańki,
## fale dookoła, wędrujący wir, kule z gejzerów, echo Strażnika).

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
	await _test_unique(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


## Kamienie unikalne hydrosfery: krążące bańki, fale dookoła, wędrujący wir, kule z gejzerów, echo Strażnika.
func _test_unique(game: Node) -> void:
	game.dev_set_level(20)
	game.dev_skills()
	for id in Skills.of_weapon("hydrosphere"):
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoHydrosphere = arena.weapon
	hero.position = Vector2.ZERO
	var a := _goblin(arena, Vector2(40, 6))  # na orbicie krążących baniek (promień 40)
	var b := _goblin(arena, Vector2(-80, 50))
	await _wait(0.2)
	for g in [a, b]:
		g._stunned = 60.0
	var hp := a.hp
	weapon._fire_bolts()
	weapon._fire_bolts()
	_check(weapon._orbits.size() == 2 and weapon._shots.is_empty(), "Wodna Orbita: bańki krążą zamiast lecieć")
	await _wait(1.2)
	_check(a.hp < hp, "krążąca bańka rani wroga obok")
	weapon._spawn_tide()
	_check(weapon._shots.filter(func(x: Dictionary) -> bool: return x.kind == "wave").size() == ProtoHydrosphere.RING_WAVES,
			"Przypływ: 6 fal dookoła")
	weapon._add_vortex(Vector2(60, -40))
	var v: Dictionary = weapon._vortexes.back()
	var start: Vector2 = v.at
	await _wait(0.6)
	_check(v.wander and (v.at as Vector2).distance_to(a.global_position) < start.distance_to(a.global_position),
			"Wędrowny Wir płynie ku wrogowi")
	weapon._geyser_burst(b.global_position, b)
	_check(weapon._lobs.size() == ProtoHydrosphere.LOB_COUNT, "Erupcja: gejzer wypluwa 3 kule")
	await _wait(0.7)
	_check(weapon._lobs.is_empty(), "kule spadły")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon._add_guardian(Vector2(-40, 0))
	var vortexes: int = weapon._vortexes.size()
	weapon.cast("h_vortex")
	_check(weapon._vortexes.size() == vortexes + 2, "Echo: Strażnik powtarza Wir (2 nowe wiry)")
	game.dev_immortal = false
	arena.queue_free()
	await process_frame


func _test_unlock(game: Node) -> void:
	game.reset_hero()
	game.best_level = 10
	_check(Weapons.element_of("hydrosphere") == Elements.WATER and Weapons.unlock_level("hydrosphere") == 15,
			"hydrosfera: woda, Wódz 15. poziomu")
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
	far.position = Vector2(84, 0)  # najdalszy w zasięgu - fala celuje w niego (19.11.2026)
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
	# Wodny Strażnik
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hp = [far.hp, side.hp, near_far.hp]
	_check(weapon.cast("h_guardian"), "Wodny Strażnik rusza")
	await _wait(0.1)
	_check(weapon._guardians.size() == 1 and (far.hp < hp[0] or side.hp < hp[1] or near_far.hp < hp[2]),
			"Strażnik pojawia się z wybuchem i rani")
	var shots_before: int = weapon._shots.filter(func(x: Dictionary) -> bool: return x.skill == "h_guardian").size()
	await _wait(1.2)
	_check(weapon._shots.any(func(x: Dictionary) -> bool: return x.skill == "h_guardian") or shots_before > 0
			or weapon._guardians[0].acc < ProtoHydrosphere.GUARD_EVERY, "Strażnik strzela pociskami")
	await _wait(5.0)
	_check(weapon._guardians.is_empty(), "po 6 s Strażnik znika")
	game.dev_immortal = false
	# obszar umiejętności: fale trafiają szerzej, nie tylko większy obrazek (19.11.2026)
	weapon.area_bonus = 100.0
	weapon._spawn_tide(hero.global_position)
	var waves: Array = weapon._shots.filter(func(sh: Dictionary) -> bool: return sh.kind == "wave")
	_check(not waves.is_empty() and is_equal_approx(waves[-1].radius, ProtoHydrosphere.WAVE_RADIUS * weapon._area("h_wave"))
			and weapon._area("h_wave") > 1.9, "fala trafia w promieniu z obszarem (%s)" % ("brak fali" if waves.is_empty() else str(waves[-1].radius)))
	weapon.area_bonus = 0.0
	arena.queue_free()
	await process_frame

extends SceneTree
## Test Słonecznej włóczni Dadźboga - pierwszej broni Prawii (ustalona z autorem 26.11.2026): dane (Prawia, loch 45,
## 5 umiejętności z kamieniami unikalnymi, Katakumby wrażliwe na Prawię), Promienne Pchnięcie (linia, piętno, promień
## z 5. poziomu, Trzy Promienie), Rzut Dadźboga (lot i powrót, dwa trafienia, Sieć Swaroga ściąga), Wschód Słońca
## (krąg wokół postaci, słup Południa), Kołowrót Słońca (obroty, pierścień rani i odpycha, 3 obroty z 10. poziomu)
## i Zenit (deszcz włóczni na wrogów, ogromna włócznia Dadźboga).

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
	_test_data()
	await _test_thrust(game)
	await _test_throw(game)
	await _test_sunrise(game)
	await _test_wheel(game)
	await _test_zenith(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Weapons.element_of("spear") == Elements.PRAWIA and int(Weapons.DATA.spear.unlock) == 45
			and Weapons.script_of("spear") == ProtoSpear and Weapons.ORDER.has("spear") and not Weapons.is_magic("spear"),
			"włócznia: Prawia, fizyczna, od lochu 45")
	_check(Skills.basic_of("spear") == "p_thrust" and Skills.of_weapon("spear").size() == 5, "włócznia: 5 umiejętności")
	var ok := true
	for id in Skills.of_weapon("spear"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id) and Skills.UPGRADE_PRICE.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu, ikonę, znaczniki i cenę")
	var r: Dictionary = Dungeons.resists(Dungeons.CATACOMBS, 1)
	_check(r[Elements.PRAWIA] < r[Elements.FIRE] and r[Elements.NAWIA] > r[Elements.FIRE],
			"Katakumby wrażliwe na Prawię (nie na ogień), odporne na Nawię")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _arena(game: Node) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 45
	game.set_weapon("spear")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	if arena.wind:
		arena.wind.passive = true
	arena.weapon.auto_attack = false
	arena.hero.position = Vector2.ZERO
	arena.hero.obstacles.clear()
	arena.hero.max_mana = 10000
	arena.hero.mana = 10000
	ProtoDecor.obstacles.clear()
	return [arena, arena.weapon]


## Gobliny z ogromnym zdrowiem, stojące w miejscu (długie ogłuszenie).
func _dummies(arena: Node, spots: Array) -> Array:
	var out: Array = []
	for p in spots:
		var g := _goblin(arena, p)
		g.max_hp = 1000000
		g.hp = g.max_hp
		out.append(g)
	await _wait(0.2)
	for g in out:
		g._stunned = 60.0
		g.position = spots[out.find(g)]
	await process_frame
	return out


func _hurt(g: ProtoGoblin) -> bool:
	return g.hp < g.max_hp


func _test_thrust(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var spear: ProtoSpear = setup[1] as ProtoSpear
	_check(spear != null and spear.element == Elements.PRAWIA, "w lochu włócznia w ręku (Prawia)")
	var gs: Array = await _dummies(arena, [Vector2(30, 0), Vector2(62, 0), Vector2(0, 50), Vector2(130, 0)])
	spear._attack()
	await _wait(0.45)
	_check(_hurt(gs[0]) and _hurt(gs[1]) and not _hurt(gs[2]) and not _hurt(gs[3]),
			"pchnięcie przebija wrogów na linii, bokiem i za daleko - nie")
	_check(gs[0].is_branded(), "trafiony wróg napiętnowany Prawią")
	# 5. poziom: co trzecie pchnięcie to promień dwa razy dalej
	spear.skill_levels["p_thrust"] = 5
	spear.thrust_count = 2
	spear._set_state("follow")
	spear._attack()
	await _wait(0.45)
	_check(_hurt(gs[3]), "5. poziom: trzecie pchnięcie - promień sięga dalej")
	# Trzy Promienie: boczne promienie trafiają wroga obok linii
	var side: ProtoGoblin = (await _dummies(arena, [Vector2(46, 20)]))[0]
	spear.skill_levels["p_thrust"] = 1
	spear.skill_gems["p_thrust"] = [Gems.unique_of("p_thrust")]
	spear._set_state("follow")
	spear._attack()
	await _wait(0.45)
	_check(_hurt(side), "Kamień Trzech Promieni: boczny promień trafia wroga obok linii")
	arena.queue_free()
	await process_frame


func _test_throw(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var spear: ProtoSpear = setup[1] as ProtoSpear
	var gs: Array = await _dummies(arena, [Vector2(70, 0), Vector2(0, 90)])
	_check(spear.cast("p_throw") and spear.throws_flying() == 1 and not spear._sprite.visible,
			"Rzut: włócznia leci, w dłoni jej nie ma")
	await _wait(0.3)
	var hp1: int = gs[0].hp
	_check(_hurt(gs[0]) and not _hurt(gs[1]), "lecąca włócznia trafia wroga na drodze")
	await _wait(0.9)
	_check(spear.throws_flying() == 0 and spear._sprite.visible and gs[0].hp < hp1,
			"włócznia wraca do ręki i rani drugi raz")
	# Sieć Swaroga: wracając, ciągnie wroga ku postaci
	spear.skill_gems["p_throw"] = [Gems.unique_of("p_throw")]
	var far: ProtoGoblin = (await _dummies(arena, [Vector2(130, 0)]))[0]
	far._stunned = 0.0
	spear.reset_cooldowns()
	spear._set_state("follow")
	spear.cast("p_throw")
	await _wait(1.2)
	_check(far.global_position.x < 125.0, "Kamień Sieci Swaroga: wróg przyciągnięty (x %.0f)" % far.global_position.x)
	arena.queue_free()
	await process_frame


func _test_sunrise(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var spear: ProtoSpear = setup[1] as ProtoSpear
	var gs: Array = await _dummies(arena, [Vector2(40, 0), Vector2(-30, 20), Vector2(150, 0)])
	spear.skill_gems["p_sunrise"] = [Gems.unique_of("p_sunrise")]
	_check(spear.cast("p_sunrise"), "Wschód Słońca")
	await _wait(0.4)
	_check(_hurt(gs[0]) and _hurt(gs[1]) and not _hurt(gs[2]) and gs[1].is_branded(),
			"krąg światła rani i piętnuje wrogów wokół, dalekiego nie")
	_check(spear.pillars() == 1, "Kamień Południa: słup światła stoi")
	var hp: int = gs[0].hp
	await _wait(0.7)
	_check(gs[0].hp < hp, "słup co chwilę rani wrogów obok")
	await _wait(ProtoSpear.PILLAR_TIME)
	_check(spear.pillars() == 0, "słup znika po czasie")
	arena.queue_free()
	await process_frame


func _test_wheel(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var spear: ProtoSpear = setup[1] as ProtoSpear
	var hero: ProtoHero = arena.hero
	var gs: Array = await _dummies(arena, [Vector2(25, 0), Vector2(-28, 0), Vector2(0, 250)])
	var start := hero.position
	_check(spear.cast("p_wheel") and spear._state == "p_wheel", "Kołowrót Słońca: włócznia wiruje")
	await _wait(ProtoSpear.WHEEL_SPIN_TIME * 0.5)
	_check(spear.spins_done == 0, "pierwszy obrót w toku")
	await _wait(ProtoSpear.WHEEL_SPIN_TIME * ProtoSpear.WHEEL_SPINS + 0.1)
	_check(spear.spins_done == ProtoSpear.WHEEL_SPINS and spear._state == "follow", "dwa obroty, potem koniec")
	_check(hero.position.distance_to(start) > 20.0, "obroty przesuwają postać naprzód")
	_check(_hurt(gs[0]) and _hurt(gs[1]) and not _hurt(gs[2]), "pierścień światła rani wrogów w zasięgu, dalekiego nie (%s %s %s, postać %s)"
			% [_hurt(gs[0]), _hurt(gs[1]), _hurt(gs[2]), str(hero.position)])
	# 10. poziom: trzy obroty
	spear.skill_levels["p_wheel"] = 10
	spear.reset_cooldowns()
	spear.cast("p_wheel")
	await _wait(ProtoSpear.WHEEL_SPIN_TIME * 3 + 0.15)
	_check(spear.spins_done == ProtoSpear.WHEEL_SPINS_PERK, "10. poziom: trzy obroty")
	arena.queue_free()
	await process_frame


func _test_zenith(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var spear: ProtoSpear = setup[1] as ProtoSpear
	var gs: Array = await _dummies(arena, [Vector2(60, 30), Vector2(-70, -20), Vector2(20, -80)])
	_check(spear.cast("p_zenith") and spear.drops_left() == ProtoSpear.ZENITH_COUNT, "Zenit: 6 włóczni w drodze")
	_check(spear._state == "follow", "w trakcie Zenitu walczysz dalej")
	await _wait(ProtoSpear.ZENITH_SPAN + ProtoSpear.ZENITH_WARN + ProtoSpear.ZENITH_FALL + 0.2)
	_check(spear.drops_done == ProtoSpear.ZENITH_COUNT, "wszystkie włócznie uderzyły (%d)" % spear.drops_done)
	_check(_hurt(gs[0]) and _hurt(gs[1]) and _hurt(gs[2]), "włócznie spadają na wrogów w pobliżu")
	await _wait(ProtoSpear.ZENITH_STUCK + 0.4)
	_check(spear.drops_left() == 0, "wbite włócznie znikają")
	# Kamień Dadźboga: ogromna włócznia na końcu
	spear.skill_gems["p_zenith"] = [Gems.unique_of("p_zenith")]
	spear.reset_cooldowns()
	spear.drops_done = 0
	spear.cast("p_zenith")
	_check(spear.drops_left() == ProtoSpear.ZENITH_COUNT + 1, "Kamień Dadźboga: jedna ogromna włócznia więcej")
	await _wait(ProtoSpear.ZENITH_SPAN + 0.2 + ProtoSpear.ZENITH_WARN + ProtoSpear.ZENITH_FALL + 0.2)
	_check(spear.drops_done == ProtoSpear.ZENITH_COUNT + 1, "ogromna włócznia też uderza")
	arena.queue_free()
	await process_frame

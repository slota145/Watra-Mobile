extends SceneTree
## Test młota - broni ziemi i Widmowych ostrzy miecza (ustalone z autorem 21.11.2026): dane (ziemia, loch 30,
## 5 umiejętności z kamieniami unikalnymi, Rozłupanie Ziemi przy młocie, Widmowe ostrza przy mieczu na jego miejscu),
## stary zapis (Rozłupanie z poziomem i kamieniem przechodzi do młota, na pasku miecza w jego miejscu Widmowe ostrza),
## walka młotem (uderzenie odpycha, 5. - co trzecie ogłusza, Lawina; rzut odbija się i wraca; skok - krater
## i Grzęzawisko; trzęsienie - fale, dopóki trzymasz; Rozłupanie Ziemi) i ostrza (rezerwacja many, same atakują,
## Lustrzane Ostrza naśladują umiejętności).

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
	_test_old_save(game)
	await _test_smash(game)
	await _test_skills(game)
	await _test_blades(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Weapons.element_of("hammer") == Elements.EARTH and int(Weapons.DATA.hammer.unlock) == 30
			and Weapons.script_of("hammer") == ProtoHammer, "młot: ziemia, od lochu 30")
	_check(Skills.basic_of("hammer") == "m_smash" and Skills.of_weapon("hammer").size() == 5
			and Skills.weapon_of("slam") == "hammer" and Skills.is_charged("m_quake"),
			"młot: 5 umiejętności, Rozłupanie Ziemi przy młocie, Trzęsienie trzymane")
	_check(Skills.weapon_of("spectral_blades") == "sword" and Skills.mastery_of("spectral_blades") == 10
			and Skills.is_toggle("spectral_blades") and Skills.of_weapon("sword").size() == 5,
			"miecz: Widmowe ostrza (przełącznik) na mistrzostwie 10")
	var ok := true
	for id in Skills.of_weapon("hammer") + ["spectral_blades"]:
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu, ikonę i znaczniki")


## Zapis sprzed 21.11.2026: miecz z Rozłupaniem Ziemi (5. poziom, kamień unikalny) w miejscu nr 2.
func _test_old_save(game: Node) -> void:
	game.reset_hero()
	game.mastery = {"sword": 12}
	game.skills_owned = ["strike", "whirl", "throw", "slam"]
	game.skill_levels = {"slam": 5}
	game.skill_gems = {"slam": [Gems.unique_of("slam")]}
	game.skill_slots = ["strike", "whirl", "slam", "", ""]
	game.weapon = "sword"
	game.save_game()
	game.load_game()
	_check(game.skills_owned.has("spectral_blades") and game.skills_owned.has("slam"),
			"stary zapis: Widmowe ostrza odblokowane, Rozłupanie zostaje (dla młota)")
	_check(game.skill_slots[2] == "spectral_blades" and not game.skill_slots.has("slam"),
			"na pasku miecza Widmowe ostrza w miejscu Rozłupania: %s" % str(game.skill_slots))
	_check(game.skill_level("slam") == 5 and Gems.has_unique(game.skill_sockets("slam"), "slam"),
			"poziom i kamień unikalny Rozłupania zostają (przejdą do młota)")
	game.reset_hero()


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _arena(game: Node, weapon: String) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 30
	game.set_weapon(weapon)
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
	ProtoDecor.obstacles.clear()
	return [arena, arena.weapon]


func _stunned(arena: Node, spots: Array) -> Array:
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


func _test_smash(game: Node) -> void:
	var setup: Array = await _arena(game, "hammer")
	var arena: Node = setup[0]
	var hammer: ProtoHammer = setup[1] as ProtoHammer
	_check(hammer != null and hammer.element == Elements.EARTH, "w lochu młot w ręku (ziemia)")
	var gs: Array = await _stunned(arena, [Vector2(30, 0), Vector2(-60, 40)])
	var near: ProtoGoblin = gs[0]
	var far: ProtoGoblin = gs[1]
	var start: Vector2 = near.position
	hammer._attack()
	await _wait(0.7)
	_check(near.hp < near.max_hp and far.hp == far.max_hp, "uderzenie trafia najbliższego, dalekiego nie")
	near._stunned = 0.0
	await _wait(0.3)
	_check(near.position.distance_to(start) > 4.0, "uderzenie odpycha (%.0f px)" % near.position.distance_to(start))
	# 5. poziom: co trzecie uderzenie ogłusza; kamień Lawiny: co czwarte odłamki
	hammer.skill_levels["m_smash"] = 5
	hammer.smash_count = 2
	near.position = Vector2(30, 0)
	near._stunned = 0.0
	hammer._cooldown = 0.0
	hammer._attack()
	await _wait(0.5)
	_check(near._stunned > 0.3, "5. poziom: trzecie uderzenie ogłusza")
	hammer.skill_gems["m_smash"] = [Gems.unique_of("m_smash")]
	var hp: int = far.hp
	far.position = Vector2(60, 30)
	hammer.smash_count = 3
	hammer._set_state("follow")
	hammer._attack()
	await _wait(1.0)
	_check(far.hp < hp, "Kamień Lawiny: odłamki spadają na pobliskich wrogów")
	arena.queue_free()
	await process_frame


func _test_skills(game: Node) -> void:
	var setup: Array = await _arena(game, "hammer")
	var arena: Node = setup[0]
	var hammer: ProtoHammer = setup[1] as ProtoHammer
	var hero: ProtoHero = arena.hero
	hero.max_mana = 10000
	hero.mana = 10000
	# rzut: odbija się po wrogach i wraca
	var gs: Array = await _stunned(arena, [Vector2(60, 0), Vector2(110, 20), Vector2(150, -10), Vector2(-200, 0)])
	hammer.reset_cooldowns()
	_check(hammer.cast("m_throw"), "rzut młotem")
	await _wait(1.6)
	var hit := 0
	for g in gs.slice(0, 3):
		if g.hp < g.max_hp:
			hit += 1
	_check(hit == 3 and gs[3].hp == gs[3].max_hp and hammer._state == "follow",
			"młot odbija się po 3 wrogach i wraca (trafionych: %d)" % hit)
	for g in gs:
		g.queue_free()
	# skok: krater rani wrogów przy lądowaniu, Grzęzawisko zostaje
	await _wait(0.3)
	hammer.skill_gems["m_leap"] = [Gems.unique_of("m_leap")]
	gs = await _stunned(arena, [Vector2(80, 0), Vector2(95, 15)])
	hammer.reset_cooldowns()
	hammer.cast("m_leap")
	await _wait(ProtoHammer.LEAP_TIME + 0.25)
	_check(hero.position.distance_to(Vector2(80, 0)) < 20.0 and gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp,
			"skok do wroga, krater rani wrogów wokół")
	_check(hammer.pits() == 1, "Kamień Grzęzawiska: krater zostaje")
	await _wait(ProtoHammer.LEAP_PIT_TIME + 0.3)
	_check(hammer.pits() == 0, "krater znika po czasie")
	for g in gs:
		g.queue_free()
	# trzęsienie: fale, dopóki trzymasz
	hero.position = Vector2.ZERO
	gs = await _stunned(arena, [Vector2(30, 10)])
	hammer.reset_cooldowns()
	hammer.cast("m_quake")
	hammer.charge_held = true
	await _wait(1.3)
	_check(hammer.quake_waves >= 2 and gs[0].hp < gs[0].max_hp and hero.form_speed < 1.0,
			"trzęsienie: %d fale, postać idzie wolniej" % hammer.quake_waves)
	hammer.charge_held = false
	await _wait(0.2)
	_check(hammer._state == "follow" and hero.form_speed == 1.0, "puszczenie kończy trzęsienie")
	# Rozłupanie Ziemi młotem
	var hp: int = gs[0].hp
	hammer.reset_cooldowns()
	hammer.cast("slam")
	await _wait(0.9)
	_check(gs[0].hp < hp, "Rozłupanie Ziemi młotem")
	arena.queue_free()
	await process_frame


func _test_blades(game: Node) -> void:
	var setup: Array = await _arena(game, "sword")
	var arena: Node = setup[0]
	var sword: ProtoWeapon = setup[1]
	var hero: ProtoHero = arena.hero
	var gs: Array = await _stunned(arena, [Vector2(60, 0), Vector2(-50, 30)])
	_check(sword.cast("spectral_blades") and sword.spectral_on and hero.summon_reserved > 0,
			"Widmowe ostrza włączone, rezerwują manę")
	await _wait(2.5)
	var hit := 0
	for g in gs:
		if g.hp < g.max_hp:
			hit += 1
	_check(hit >= 1, "ostrza same tną wrogów w pobliżu (trafionych: %d)" % hit)
	sword.skill_levels["spectral_blades"] = 10
	await _wait(0.1)
	_check(sword._spectral.size() == 4, "10. poziom: 4 ostrza")
	# Lustrzane ostrza: po Młynku ostrza wirują przy wrogach
	sword.skill_gems["spectral_blades"] = [Gems.unique_of("spectral_blades")]
	await _wait(1.5)
	for b in sword._spectral:
		b.mode = "orbit"
	sword._spectral_mirror("whirl")
	var spins := 0
	for b in sword._spectral:
		if b.mode == "spin":
			spins += 1
	_check(spins == 4, "Kamień Lustrzanych Ostrzy: po Młynku każde ostrze wiruje przy wrogu")
	sword.cast("spectral_blades")
	_check(not sword.spectral_on and hero.summon_reserved == 0 and sword._spectral.is_empty(), "drugie stuknięcie wyłącza ostrza")
	arena.queue_free()
	await process_frame

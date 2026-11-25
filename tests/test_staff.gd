extends SceneTree
## Test Kostura Leszego - pierwszej broni natury (pomysły autora 25.11.2026): dane (natura, loch 40, magiczna,
## 5 umiejętności z kamieniami unikalnymi), trucizna (znaki kumulują się, ranią z czasem - ProtoTarget.poison),
## Biegnące Korzenie (łańcuch po wrogach, Zasiew), Żołądź (przebija, sadzonka, Muchołówka kłapie), Uścisk Boru
## (chwyta, wciąga słabych, zawsze jednego, Głóg strzela cierniami), Pylenie Mchu (przy postaci i sadzonkach,
## Purchawka), limit sadzonek, Strażnicy Boru (przy postaci i sadzonkach, biją, limit, znikają).

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
	_check(Weapons.element_of("staff") == Elements.NATURE and int(Weapons.DATA.staff.unlock) == 40
			and Weapons.is_magic("staff") and Weapons.script_of("staff") == ProtoStaff, "kostur: natura, magiczny, od lochu 40")
	_check(Skills.basic_of("staff") == "l_roots" and Skills.of_weapon("staff").size() == 5, "kostur: 5 umiejętności")
	var ok := true
	for id in Skills.of_weapon("staff"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id) and Skills.UPGRADE_PRICE.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu, ikonę, znaczniki i cenę")
	await _test_roots(game)
	await _test_seeds(game)
	await _test_spores_treants(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _goblin(arena: Node, at: Vector2, hp := 1000000) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	g.max_hp = hp
	g.full_hp = hp
	g.hp = hp
	return g


func _arena(game: Node) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 40
	game.set_weapon("staff")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	if arena.wind:
		arena.wind.passive = true
	if arena.frost:
		arena.frost.set_process(false)
	arena.weapon.auto_attack = false
	arena.hero.position = Vector2.ZERO
	arena.hero.obstacles.clear()
	arena.hero.max_mana = 10000
	arena.hero.mana = 10000
	ProtoDecor.obstacles.clear()
	return [arena, arena.weapon]


## Gobliny stojące w miejscu (długie ogłuszenie).
func _dummies(arena: Node, spots: Array, hp := 1000000) -> Array:
	var out: Array = []
	for p in spots:
		out.append(_goblin(arena, p, hp))
	await _wait(0.15)
	for i in out.size():
		out[i]._stunned = 60.0
		out[i].position = spots[i]
	await process_frame
	return out


func _test_roots(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var staff := setup[1] as ProtoStaff
	_check(staff != null and staff.element == Elements.NATURE, "w lochu kostur w ręku (natura)")
	var gs: Array = await _dummies(arena, [Vector2(40, 0), Vector2(90, 10), Vector2(140, 0), Vector2(190, 10), Vector2(-150, 0)])
	staff._attack()
	await _wait(0.7)
	var hit := 0
	for g in gs.slice(0, 4):
		hit += 1 if g.hp < g.max_hp else 0
	_check(hit == ProtoStaff.ROOT_TARGETS and gs[4].hp == gs[4].max_hp, "korzenie biegną łańcuchem po %d wrogach (dalekiego nie)" % hit)
	_check(gs[0].poison_stacks() == 1 and gs[0].is_poisoned(), "natura truje: znak trucizny")
	var hp0: int = gs[0].hp
	await _wait(1.2)
	_check(gs[0].hp < hp0, "trucizna rani z czasem")
	staff._cooldown = 0.0
	staff._set_state("follow")
	staff._attack()
	await _wait(0.6)
	_check(gs[0].poison_stacks() == 2, "znaki trucizny się kumulują (%d)" % gs[0].poison_stacks())
	# 5. poziom: 5 wrogów
	staff.skill_levels["l_roots"] = 5
	for g in gs:
		g.hp = g.max_hp
	staff._set_state("follow")
	staff._attack()
	await _wait(0.8)
	_check(gs[3].hp < gs[3].max_hp, "5. poziom: korzenie sięgają dalej w łańcuchu")
	for g in gs:
		g.queue_free()
	# Kamień Zasiewu: zabici korzeniami zostawiają sadzonki (z szansą)
	staff.skill_gems["l_roots"] = [Gems.unique_of("l_roots")]
	staff.skill_levels["l_roots"] = 1
	var seeded := false
	for i in 12:
		gs = await _dummies(arena, [Vector2(40, 0), Vector2(80, 0), Vector2(120, 0)], 1)
		staff._set_state("follow")
		staff._attack()
		await _wait(0.6)
		if staff.saplings() > 0:
			seeded = true
			break
	_check(seeded, "Kamień Zasiewu: zabity korzeniami wróg zostawia sadzonkę")
	arena.queue_free()
	await process_frame


func _test_seeds(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var staff := setup[1] as ProtoStaff
	var hero: ProtoHero = arena.hero
	# Żołądź (zmiana 25.11.2026): zatrzymuje się na pierwszym trafionym, wybuch korzeni rani obok, wyrasta sadzonka
	var gs: Array = await _dummies(arena, [Vector2(60, 0), Vector2(80, 10), Vector2(170, 0)])
	staff.reset_cooldowns()
	_check(staff.cast("l_acorn"), "Żołądź Leszego")
	await _wait(1.0)
	var sap: Array = staff._saplings
	_check(gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp and gs[2].hp == gs[2].max_hp and staff.saplings("sapling") == 1
			and (sap[0].at as Vector2).distance_to(gs[0].global_position) < 4.0,
			"żołądź zatrzymuje się na pierwszym wrogu: korzenie ranią obok, wyrasta przy nim sadzonka")
	# bez wrogów - nie wylatuje za planszę
	for g in gs:
		g.queue_free()
	await process_frame
	staff._saplings.clear()
	hero.position = Vector2(hero.bounds.end.x - 20.0, 0)
	hero.facing = Vector2.RIGHT
	staff.reset_cooldowns()
	staff.cast("l_acorn")
	await _wait(1.2)
	_check(staff.saplings() == 1 and hero.bounds.has_point(staff._saplings[0].at), "bez wrogów żołądź spada w granicach planszy")
	hero.position = Vector2.ZERO
	staff._saplings.clear()
	gs = []
	# Muchołówka: mięsożerna roślina kłapie
	staff.skill_gems["l_acorn"] = [Gems.unique_of("l_acorn")]
	staff.reset_cooldowns()
	staff.cast("l_acorn")
	await _wait(1.2)
	_check(staff.saplings("carnivore") == 1, "Kamień Muchołówki: mięsożerna roślina")
	var plant: Dictionary = staff._saplings.filter(func(s: Dictionary) -> bool: return s.kind == "carnivore")[0]
	var prey: ProtoGoblin = (await _dummies(arena, [plant.at + Vector2(14, 0)]))[0]
	await _wait(1.3)
	_check(prey.hp < prey.max_hp, "mięsożerna roślina kłapie na wroga obok")
	prey.queue_free()
	# Uścisk Boru: chwyta, wciąga słabych (zawsze przynajmniej jednego)
	await _wait(0.2)
	staff._saplings.clear()
	gs = await _dummies(arena, [Vector2(30, 0), Vector2(-30, 10), Vector2(0, 40), Vector2(20, -30)])
	staff.reset_cooldowns()
	staff.cast("l_grasp")
	await _wait(ProtoStaff.CAST_TIME + 0.1)
	var held := 0
	for g in gs:
		held += 1 if g.hp < g.max_hp else 0
	_check(held == ProtoStaff.GRASP_TARGETS, "Uścisk Boru chwyta %d wrogów" % held)
	await _wait(ProtoStaff.GRASP_PULL_DELAY + 0.2)
	var dead := gs.filter(func(g: ProtoGoblin) -> bool: return not g.alive()).size()
	_check(staff.pulled == 1 and dead == 1 and staff.saplings() == 1,
			"przy pełnym zdrowiu wciąga przynajmniej jednego - wyrasta sadzonka")
	for g in gs:
		if is_instance_valid(g):
			g.queue_free()
	# słabi wciągnięci wszyscy; Głóg - cierniowe sadzonki strzelają
	staff.skill_gems["l_grasp"] = [Gems.unique_of("l_grasp")]
	gs = await _dummies(arena, [Vector2(30, 0), Vector2(-30, 10), Vector2(0, 40)])
	for g in gs:
		g.hp = roundi(g.max_hp * 0.3)
	staff.pulled = 0
	staff.reset_cooldowns()
	staff.cast("l_grasp")
	await _wait(ProtoStaff.CAST_TIME + ProtoStaff.GRASP_PULL_DELAY + 0.3)
	_check(staff.pulled == 3 and staff.saplings("thorn") == 3, "słabi wciągnięci wszyscy (%d), Głóg: cierniowe sadzonki" % staff.pulled)
	var target: ProtoGoblin = (await _dummies(arena, [Vector2(0, 90)]))[0]
	await _wait(ProtoStaff.THORN_EVERY + 1.0)
	_check(target.hp < target.max_hp, "cierniowe sadzonki strzelają cierniami")
	target.queue_free()
	# limit sadzonek
	for i in 20:
		staff.add_sapling(hero.global_position + Vector2(-100 + i * 8, 120), "sapling")
	_check(staff.saplings() == ProtoStaff.MAX_SAPLINGS, "najwyżej %d sadzonek (najstarsza więdnie)" % ProtoStaff.MAX_SAPLINGS)
	arena.queue_free()
	await process_frame


func _test_spores_treants(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var staff := setup[1] as ProtoStaff
	var hero: ProtoHero = arena.hero
	staff.add_sapling(hero.global_position + Vector2(150, 0), "sapling")
	staff.add_sapling(hero.global_position + Vector2(-150, 0), "sapling")
	var gs: Array = await _dummies(arena, [Vector2(20, 0), Vector2(160, 0), Vector2(-160, 0), Vector2(0, 220)])
	staff.reset_cooldowns()
	staff.cast("l_spores")
	await _wait(ProtoStaff.CAST_TIME + 0.15)
	_check(gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp and gs[2].hp < gs[2].max_hp and gs[3].hp == gs[3].max_hp,
			"Pylenie Mchu: zarodniki przy postaci i przy każdej sadzonce")
	_check(gs[1].poison_stacks() >= ProtoStaff.SPORE_POISON and staff.saplings() == 2,
			"zarodniki dokładają %d znaki trucizny, sadzonki zostają" % gs[1].poison_stacks())
	# Purchawka: zatruty wróg po śmierci może wybuchnąć - szansa 5% za znak trucizny (do 50%)
	staff.skill_gems["l_spores"] = [Gems.unique_of("l_spores")]
	var probe: ProtoGoblin = (await _dummies(arena, [Vector2(0, -200)]))[0]
	staff._hit(probe, 0.01, Vector2.ZERO, "l_roots")
	_check(probe.is_poisoned() and is_equal_approx(ProtoStaff.puff_chance(probe), ProtoStaff.PUFF_PER_STACK),
			"szansa wybuchu: 1 znak - %d%%" % roundi(ProtoStaff.puff_chance(probe) * 100))
	for i in 12:
		staff._hit(probe, 0.01, Vector2.ZERO, "l_roots")
	_check(is_equal_approx(ProtoStaff.puff_chance(probe), 0.5), "pełna trucizna (10 znaków) - 50%")
	probe.queue_free()
	var booms := 0
	var tries := 30
	for i in tries:
		var victim: ProtoGoblin = (await _dummies(arena, [Vector2(0, -120)], 20))[0]
		var near: ProtoGoblin = (await _dummies(arena, [Vector2(14, -120)]))[0]
		for k in 10:
			staff._hit(victim, 0.0001, Vector2.ZERO, "l_roots")
		var hp_near := near.hp
		staff._hit(victim, 100.0, Vector2.ZERO, "l_roots")
		await process_frame
		if near.hp < hp_near:
			booms += 1
		near.queue_free()
	_check(booms > 3 and booms < tries - 3, "Kamień Purchawki: przy pełnej truciźnie wybucha mniej więcej co drugi (%d z %d)" % [booms, tries])
	# Strażnicy Boru: przy postaci i przy każdej sadzonce
	staff.reset_cooldowns()
	staff.cast("l_treants")
	await _wait(ProtoStaff.CAST_TIME + 0.1)
	_check(staff.treants() == 3, "Strażnicy Boru: drzewiec przy postaci i przy 2 sadzonkach (%d)" % staff.treants())
	var hp1: int = gs[1].hp
	await _wait(1.8)
	_check(gs[1].hp < hp1, "drzewce biją wrogów")
	for i in 6:
		staff.add_sapling(hero.global_position + Vector2(-60 + i * 20, 60), "sapling")
	staff.reset_cooldowns()
	staff.cast("l_treants")
	await _wait(ProtoStaff.CAST_TIME + 0.1)
	_check(staff.treants() == ProtoStaff.MAX_TREANTS, "najwyżej %d drzewców naraz" % ProtoStaff.MAX_TREANTS)
	await _wait(ProtoStaff.TREANT_LIFE + 1.0)
	_check(staff.treants() == 0, "drzewce znikają po czasie")
	arena.queue_free()
	await process_frame

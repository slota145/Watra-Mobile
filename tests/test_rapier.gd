extends SceneTree
## Test lodowego rapiera - pierwszej broni lodu (ustalone z autorem 25.11.2026): dane (lód, loch 35, 5 umiejętności
## z kamieniami unikalnymi), chłód lodu (znaki chłodu, zamrożenie, odporność po zamrożeniu - ProtoTarget.chill),
## roztrzaskanie zamrożonych, zwykły atak w cyklu (pchnięcie, cięcie w prawo, pchnięcie, cięcie w lewo; Sople), wypad
## (do wroga, zatrzymanie przed nim, ścieżka szronu, Zamieć), Riposta Morozka (krąg - szansa na ripostę, Mroźna Riposta
## zamraża), Grad Pchnięć (trzymany, kamień - lecące kolce) i Rój Sopli (chmura strzela w losowych wrogów).

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
	await _test_chill(game)
	await _test_thrust(game)
	await _test_skills(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Weapons.element_of("rapier") == Elements.COLD and int(Weapons.DATA.rapier.unlock) == 35
			and Weapons.script_of("rapier") == ProtoRapier and Weapons.ORDER.has("rapier"), "rapier: lód, od lochu 35")
	_check(Skills.basic_of("rapier") == "r_thrust" and Skills.of_weapon("rapier").size() == 5
			and Skills.is_charged("r_flurry"), "rapier: 5 umiejętności, Grad Pchnięć trzymany")
	var ok := true
	for id in Skills.of_weapon("rapier"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id) and Skills.UPGRADE_PRICE.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu, ikonę, znaczniki i cenę")


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
	game.best_level = 35
	game.set_weapon("rapier")
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


func _test_chill(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var rapier: ProtoRapier = setup[1] as ProtoRapier
	_check(rapier != null and rapier.element == Elements.COLD, "w lochu rapier w ręku (lód)")
	var g: ProtoGoblin = (await _dummies(arena, [Vector2(200, 0)]))[0]
	var froze := false
	for i in Elements.CHILL_STACKS - 1:
		froze = froze or g.chill()
	_check(not froze and g.chill_stacks() == Elements.CHILL_STACKS - 1 and g.speed_factor() < 1.0 and not g.is_frozen(),
			"lód spowalnia i zbiera znaki chłodu (%d)" % g.chill_stacks())
	_check(g.chill() and g.is_frozen() and g.chill_stacks() == 0, "%d. znak chłodu zamraża" % Elements.CHILL_STACKS)
	g.thaw()
	_check(not g.is_frozen() and not g.chill(Elements.CHILL_SLOW, 1.0, Elements.CHILL_STACKS),
			"po zamrożeniu chwila odporności - nie zamarza od razu znowu")
	# roztrzaskanie: zamrożony wróg trafiony rapierem pęka, sąsiad obrywa
	var gs: Array = await _dummies(arena, [Vector2(-150, 0), Vector2(-160, 12), Vector2(-150, 200)])
	var frozen: ProtoGoblin = gs[0]
	var near: ProtoGoblin = gs[1]
	var far: ProtoGoblin = gs[2]
	_check(frozen.freeze(2.0) and frozen.is_frozen(), "zamrożenie wroga")
	rapier._hit(frozen, 1.0, Vector2.ZERO, "r_thrust")
	_check(not frozen.is_frozen() and rapier.shatters == 1 and near.hp < near.max_hp and far.hp == far.max_hp,
			"roztrzaskanie: lód pęka, sąsiad obrywa, daleki nie")
	var hp: int = near.hp
	rapier._hit(frozen, 1.0, Vector2.ZERO, "r_thrust")
	_check(near.hp == hp and rapier.shatters == 1, "niezamrożony już nie pęka")
	arena.queue_free()
	await process_frame


func _test_thrust(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var rapier: ProtoRapier = setup[1] as ProtoRapier
	_check(ProtoRapier.cycle_move(1) == "thrust" and ProtoRapier.cycle_move(2) == "right"
			and ProtoRapier.cycle_move(3) == "thrust" and ProtoRapier.cycle_move(4) == "left"
			and ProtoRapier.cycle_move(5) == "thrust", "cykl: pchnięcie, cięcie w prawo, pchnięcie, cięcie w lewo")
	var gs: Array = await _dummies(arena, [Vector2(30, 0), Vector2(52, 0), Vector2(0, 50), Vector2(84, 0)])
	rapier._attack()
	await _wait(0.4)
	_check(gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp and gs[2].hp == gs[2].max_hp
			and gs[3].hp == gs[3].max_hp, "pchnięcie przebija wrogów na linii, bokiem i za daleko - nie")
	_check(gs[0].chill_stacks() == 1 and gs[0].speed_factor() < 1.0, "pchnięcie schładza (1 znak)")
	# cięcie: wrogowie w łuku przed postacią (też obok linii pchnięcia), daleki - nie
	var side: ProtoGoblin = (await _dummies(arena, [Vector2(22, 22)]))[0]
	var hp1: int = gs[1].hp
	rapier._cooldown = 0.0
	rapier._attack()
	await _wait(0.4)
	_check(rapier._move == "right" and side.hp < side.max_hp and gs[1].hp == hp1,
			"cięcie trafia wrogów w łuku obok, dalekiego nie")
	# 5. poziom: pchnięcia sięgają o połowę dalej
	side.queue_free()
	await process_frame
	rapier.skill_levels["r_thrust"] = 5
	rapier.thrust_count = 2
	rapier._set_state("follow")
	rapier._attack()
	await _wait(0.4)
	_check(gs[3].hp < gs[3].max_hp, "5. poziom: pchnięcie sięga dalej")
	# kamień Sopli: drugie pchnięcie cyklu wystrzeliwuje sopel
	rapier.skill_gems["r_thrust"] = [Gems.unique_of("r_thrust")]
	rapier.thrust_count = 2
	rapier._set_state("follow")
	rapier._attack()
	await _wait(0.16)
	_check(rapier.icicles() == 1, "Kamień Sopli: drugie pchnięcie cyklu wystrzeliwuje sopel")
	await _wait(1.0)
	_check(rapier.icicles() == 0, "sopel znika za zasięgiem")
	arena.queue_free()
	await process_frame


func _test_skills(game: Node) -> void:
	var setup: Array = await _arena(game)
	var arena: Node = setup[0]
	var rapier: ProtoRapier = setup[1] as ProtoRapier
	var hero: ProtoHero = arena.hero
	hero.max_mana = 10000
	hero.mana = 10000
	# wypad bez gałki: do najdalszego wroga w zasięgu, zatrzymanie przed nim, po drodze przebija; Zamieć
	var gs: Array = await _dummies(arena, [Vector2(40, 0), Vector2(100, 0), Vector2(40, 60)])
	rapier.skill_gems["r_lunge"] = [Gems.unique_of("r_lunge")]
	rapier.reset_cooldowns()
	_check(rapier.cast("r_lunge"), "wypad")
	await _wait(ProtoRapier.LUNGE_TIME + 0.15)
	var gap := hero.position.distance_to(Vector2(100, 0))
	_check(gap < ProtoRapier.LUNGE_STOP + 6.0 and gap > 4.0 and gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp,
			"wypad do najdalszego: postać staje przed nim (%.0f px), po drodze przebija" % gap)
	_check(rapier.frost_paths() == 1, "ścieżka szronu leży na ziemi")
	var mana := hero.mana
	_check(rapier.can_use("r_lunge") and rapier.mana_cost("r_lunge") == 0, "Kamień Zamieci: drugi wypad za darmo")
	# wypad z gałką: pierwszy wróg na drodze w tę stronę
	var start := hero.position
	_check(rapier._lunge_target_for(Vector2.LEFT, 200.0) == gs[0] and rapier._lunge_target_for(Vector2.UP, 200.0) == null,
			"z gałką: pierwszy wróg w tę stronę (start %s)" % str(start))
	rapier.cast("r_lunge")
	await _wait(ProtoRapier.LUNGE_TIME + 0.15)
	_check(hero.mana >= mana and rapier.cooldown_left("r_lunge") > 0.0, "drugi wypad bez many, potem odnowienie")
	for g in gs:
		g.queue_free()
	await _wait(ProtoRapier.LUNGE_PATH_TIME)
	_check(rapier.frost_paths() == 0, "ścieżka szronu znika po czasie")
	# Riposta Morozka: krąg na ziemi, w nim szansa na ripostę (z kamieniem - zamraża)
	hero.position = Vector2.ZERO
	game.dev_immortal = false
	gs = await _dummies(arena, [Vector2(25, 0)])
	rapier.skill_gems["r_riposte"] = [Gems.unique_of("r_riposte")]
	rapier.reset_cooldowns()
	_check(rapier.cast("r_riposte") and rapier.circle_left() > 0.0, "Riposta Morozka: krąg na ziemi")
	await process_frame
	_check(rapier.in_circle() and is_equal_approx(hero.parry_chance, ProtoRapier.RIPOSTE_CHANCE + ProtoRapier.RIPOSTE_CHANCE_GEM),
			"w kręgu szansa na ripostę (%.2f)" % hero.parry_chance)
	var hp := hero.hp
	var hits := 0
	for i in 40:
		hero._invulnerable = 0.0
		hero.take_damage(1)
		hits += 1
		await process_frame
	_check(rapier.ripostes > 5 and rapier.ripostes < 35 and hero.hp > hp - hits and gs[0].hp < gs[0].max_hp,
			"część ciosów odbita (%d z %d), kontra rani wroga" % [rapier.ripostes, hits])
	_check(gs[0].is_frozen() or rapier.shatters > 0, "Kamień Mroźnej Riposty: skontrowany wróg zamarza (i pęka przy kolejnej)")
	hero.position = Vector2(150, 0)
	await process_frame
	_check(not rapier.in_circle() and hero.parry_chance == 0.0, "poza kręgiem bez riposty")
	await _wait(ProtoRapier.CIRCLE_TIME)
	_check(rapier.circle_left() == 0.0, "krąg znika po czasie")
	game.dev_immortal = true
	hero.position = Vector2.ZERO
	for g in gs:
		g.queue_free()
	# Grad Pchnięć: pchnięcia, dopóki trzymasz; kamień Gradu - lecące kolce
	await _wait(0.3)
	gs = await _dummies(arena, [Vector2(30, 0), Vector2(-90, 60)])
	rapier.skill_gems["r_flurry"] = [Gems.unique_of("r_flurry")]
	rapier.reset_cooldowns()
	rapier.cast("r_flurry")
	rapier.charge_held = true
	await _wait(1.0)
	for i in 4:  # kolce lecą w losowych wrogów - jeśli los ominął tego z tyłu, jeszcze chwila gradu
		if gs[1].hp < gs[1].max_hp:
			break
		await _wait(0.6)
	_check(rapier.flurry_thrusts >= 5 and gs[0].hp < gs[0].max_hp and hero.form_speed < 1.0,
			"Grad Pchnięć: %d pchnięć, postać idzie wolniej" % rapier.flurry_thrusts)
	_check(gs[1].hp < gs[1].max_hp, "Kamień Gradu: kolce lecą też w wroga z tyłu")
	rapier.charge_held = false
	await _wait(0.2)
	_check(rapier._state == "follow" and hero.form_speed == 1.0, "puszczenie kończy grad")
	for g in gs:
		g.queue_free()
	# Rój Sopli: sople pojawiają się za plecami, tworzą chmurę, potem wylatują po kolei w losowych wrogów
	await _wait(0.6)
	gs = await _dummies(arena, [Vector2(80, -30), Vector2(-90, 40)])
	rapier.reset_cooldowns()
	_check(rapier.cast("r_swarm") and rapier.swarm_left() == ProtoRapier.SWARM_COUNT and rapier._state == "follow",
			"Rój Sopli: %d sopli w chmurze, walczysz dalej" % rapier.swarm_left())
	await _wait(ProtoRapier.SWARM_FORM)
	_check(rapier.swarm_shots == 0, "najpierw chmura się formuje")
	await _wait(ProtoRapier.SWARM_HOLD + ProtoRapier.SWARM_EVERY * ProtoRapier.SWARM_COUNT + 0.3)
	_check(rapier.swarm_shots == ProtoRapier.SWARM_COUNT and rapier.swarm_left() == 0
			and gs[0].hp < gs[0].max_hp and gs[1].hp < gs[1].max_hp,
			"potem wszystkie wylatują po kolei w losowych wrogów (%d)" % rapier.swarm_shots)
	for g in gs:
		g.queue_free()
	await _wait(0.8)
	rapier.reset_cooldowns()
	rapier.cast("r_swarm")
	await _wait(ProtoRapier.SWARM_FORM + ProtoRapier.SWARM_HOLD + 0.5)
	_check(rapier.swarm_left() == ProtoRapier.SWARM_COUNT, "bez wrogów sople czekają w chmurze")
	for i in 5:  # przy dużej redukcji odnowienia rój się nakłada - sople dołączają do chmury, do sufitu
		rapier.reset_cooldowns()
		hero.mana = hero.max_mana
		rapier.cast("r_swarm")
		if i == 0:
			_check(rapier.swarm_left() == ProtoRapier.SWARM_COUNT * 2, "drugi rój dokłada sople do chmury (%d)" % rapier.swarm_left())
	_check(rapier.swarm_left() == ProtoRapier.SWARM_MAX, "najwyżej %d sopli naraz" % ProtoRapier.SWARM_MAX)
	var late: ProtoGoblin = (await _dummies(arena, [Vector2(60, 0)]))[0]
	await _wait(ProtoRapier.SWARM_FORM + ProtoRapier.SWARM_HOLD + ProtoRapier.SWARM_EVERY * 10)
	_check(rapier.swarm_left() < ProtoRapier.SWARM_MAX and late.hp < late.max_hp, "gdy wróg się pojawi, nałożony rój strzela")
	late.queue_free()
	await _wait(ProtoRapier.SWARM_WAIT)
	_check(rapier.swarm_left() == 0, "po chwili bez wrogów topnieją")
	arena.queue_free()
	await process_frame

extends SceneTree
## Test elektrycznej katany i combo z przemoczeniem (15.11.2026): dostępność (Wódz 20. poziomu albo 6000 zł), zmiana
## broni (węzeł ProtoKatana), porażenie (+15% obrażeń, przeskok na sąsiada), przemoczenie (krople, +30% od Gromu,
## dłuższy przeskok, zamrożenie lodem z odpornością), a w walce: cięcie, Taniec ostrza, Riposta (garda, kontra),
## ładowany Sąd Peruna, Błysk Peruna.

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
	# stary zapis: kamienie z Mgnienia miecza wracają do sakwy, jego kamień unikalny przechodzi na Błysk Peruna
	game.save_game()
	var f := FileAccess.open(game.save_path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	data["gems"] = {"unique:blink": 1}
	data["skill_gems"] = {"blink": ["unique:blink", "multi:2", ""]}
	data["skills_owned"] = ["strike", "blink"]
	f = FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	game.load_game()
	_check(game.gems.get("unique:k_flash", 0) == 2 and game.gems.get("multi:2", 0) == 1
			and not game.skills_owned.has("blink"), "stary zapis: kamienie Mgnienia w sakwie, unikalny dla Błysku Peruna")
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
	_check(weapon._cut_t < 0.0 and not weapon._slash.visible, "efekt cięcia zagrał do końca i znikł")
	# Taniec ostrza
	var line: Array = [a]
	for i in 4:
		line.append(_goblin(arena, Vector2(50 + i * 25, (i % 2) * 14 - 7)))
	await process_frame
	for g in line:
		g._stunned = 60.0
	var hps: Array = line.map(func(g: ProtoGoblin) -> int: return g.hp)
	_fresh(weapon, hero)
	hero.position = Vector2.ZERO
	var from := hero.global_position
	_check(weapon.cast("k_dance") and weapon._state == "dance", "Taniec ostrza rusza")
	await _wait(0.9)
	var struck := 0
	for i in line.size():
		if line[i].hp < hps[i]:
			struck += 1
	_check(hero.global_position.x - from.x >= 60.0, "Taniec: postać idzie naprzód (%.0f px)" % (hero.global_position.x - from.x))
	_check(struck >= 3 and weapon._state == "follow", "Taniec: cięcia i piorun ranią kilku wrogów (%d)" % struck)
	# Riposta
	_fresh(weapon, hero)
	hero.position = Vector2.ZERO
	await process_frame
	_check(weapon.cast("k_riposte") and weapon._state == "guard" and hero.parry_left > 0.0, "Riposta: garda")
	var hero_hp := hero.hp
	hps = line.map(func(g: ProtoGoblin) -> int: return g.hp)
	hero._invulnerable = 0.0
	hero.take_damage(10)
	_check(hero.hp == hero_hp and weapon._state == "riposte", "garda blokuje cios i rusza kontrę")
	hero.take_damage(10)
	_check(hero.hp == hero_hp and hero._invulnerable >= ProtoKatana.RIPOSTE_SAFE - 0.05, "w trakcie kontry postać jest nietykalna")
	await _wait(0.6)
	struck = 0
	for i in line.size():
		if line[i].hp < hps[i]:
			struck += 1
	_check(struck >= 2 and weapon._state == "follow", "kontra rani wrogów wokół (%d)" % struck)
	_check(hero.global_position.length() > 10.0, "kontra: wyskok ku wrogowi")
	_fresh(weapon, hero)
	weapon.cast("k_riposte")
	await _wait(ProtoKatana.RIPOSTE_WAIT + 0.2)
	_check(weapon._state == "follow" and hero.parry_left <= 0.0, "bez ciosu garda mija po 3 s")
	# Sąd Peruna
	_fresh(weapon, hero)
	hero.position = Vector2(-150, 0)
	var far := _goblin(arena, Vector2(30, 0))
	await process_frame
	far._stunned = 60.0
	hp = far.hp
	_check(weapon.cast("k_perun") and weapon._state == "charge", "Sąd Peruna: ładowanie")
	weapon.charge_held = true
	await _wait(0.2)
	weapon.charge_held = false
	await _wait(0.1)
	_check(weapon._state == "follow" and far.hp == hp, "krótkie ładowanie - krótkie cięcie nie sięga daleko")
	_fresh(weapon, hero)
	weapon.cast("k_perun")
	weapon.charge_held = true
	await _wait(ProtoKatana.PERUN_CHARGE + 0.1)
	weapon.charge_held = false
	await _wait(0.1)
	_check(far.hp < hp, "pełne ładowanie - cięcie sięga 180 px dalej")
	_check(not Skills.can_be_main("k_perun") and Skills.is_charged("k_perun"), "Sąd Peruna ładowany, nie pod „Atak”")
	# Błysk Peruna
	_fresh(weapon, hero)
	hero.position = Vector2.ZERO
	hp = far.hp
	_check(weapon.blink_skill == "k_flash" and weapon.cast("k_flash"), "Błysk Peruna skacze")
	await process_frame
	_check(far.hp < hp and far.is_shocked(), "Błysk Peruna rani i poraża")
	_check(not Skills.can_be_main("k_flash") and not game.assign_skill("k_flash", 0), "Błysk Peruna nie może stać pod „Atak”")
	# Błysk Peruna jak dawne Mgnienie miecza: na wylot, mana, stuknięcie - jeden skok, trzymanie - seria bez odnowienia
	await _wait(0.4)
	_fresh(weapon, hero)
	hero.position = far.position + Vector2(-260, 0)  # dalej niż zasięg skoku (220)
	await process_frame
	for g in get_nodes_in_group(ProtoWeapon.TARGETS):
		if g != far:
			g.queue_free()
	await process_frame
	_check(not weapon.cast("k_flash"), "Błysk bez wroga w zasięgu się nie uda")
	hero.position = far.position + Vector2(-60, 0)
	await process_frame
	var mana := hero.mana
	_check(weapon.cast("k_flash"), "Błysk rusza")
	_check(hero.position.x > far.position.x + 10.0 and absf(hero.position.y - far.position.y) < 2.0,
			"postać ląduje za wrogiem, na wylot")
	_check(hero.mana == mana - weapon.mana_cost("k_flash"), "skok kosztuje manę")
	var jumps := weapon._blink_jumps
	await _wait(0.5)
	_check(weapon._blink_jumps == jumps, "samo stuknięcie - jeden skok")
	weapon.flicker_held = true
	await _wait(1.8)
	weapon.flicker_held = false
	_check(weapon._blink_jumps - jumps > 3 and weapon.cooldown_full("k_flash") == 0.0,
			"trzymanie - skoki bez odnowienia (%d)" % (weapon._blink_jumps - jumps))
	weapon.flicker_held = true
	hero.mana = 3
	jumps = weapon._blink_jumps
	await _wait(0.4)
	weapon.flicker_held = false
	_check(weapon._blink_jumps == jumps and hero.mana >= 3, "bez many nie skacze")
	game.add_gem(Gems.unique_of("k_flash"), 1, false)
	game.socket_skill("k_flash", 0, Gems.unique_of("k_flash"))
	weapon.skill_gems = game.skill_gems
	_check(weapon.mana_cost("k_flash") == roundi(Skills.mana_of("k_flash") * 0.5), "Kamień Nieskończonej Mgły: skoki za pół many")
	# skoki omijają 3 ostatnie cele: przy 4 wrogach w grupie każdy kolejny skok w innego
	var group: Array = []
	for at in [Vector2(0, 0), Vector2(30, 10), Vector2(10, 35), Vector2(-25, 20)]:
		group.append(_goblin(arena, far.position + Vector2(0, 80) + at))
	await process_frame
	for g in group:
		g._stunned = 60.0
		g.hp = 100000
	hero.position = far.position + Vector2(0, 40)
	weapon._recent_targets.clear()
	var order: Array = []
	for i in 4:
		var next: ProtoTarget = weapon._flicker_target()
		order.append(next)
		weapon._flicker_jump(next)
	var distinct := {}
	for t in order:
		distinct[t] = true
	_check(distinct.size() == 4, "4 skoki w grupie - 4 różne cele (pamięć 3 ostatnich)")
	_check(ProtoWeapon.FLICKER_RANGE >= 220.0, "zasięg skoku 220 px - sięga między kukłami w bazie")
	for g in group:
		g.queue_free()
	await process_frame
	# 5. i 10. poziom: zabicie skokiem zwraca 2x więcej many, co 5. skok wyładowanie
	weapon.skill_levels = {"k_flash": 10}
	hero.mana = 30
	far.hp = 1
	weapon._flicker_jump(far)
	_check(not far.alive() and hero.mana == 30 + Skills.BLINK_MANA_ON_KILL * 2, "5. poziom: zabicie skokiem zwraca 4 many")
	game.dev_immortal = false
	arena.queue_free()
	await process_frame


## Kamienie unikalne katany: Gromowe Ostrze (łuk pioruna z cięcia), Wir Ostrza (taniec w miejscu dookoła), Łańcuch
## Kontr (trafieni kontrą tną dookoła siebie), Wędrowne Gromy (pioruny pełzną do innych wrogów, więcej przy dłuższym
## ładowaniu).
func _test_unique(game: Node) -> void:
	game.reset_hero()
	game.best_level = 20
	game.set_weapon("katana")
	game.dev_set_level(20)
	game.dev_skills()
	for id in Skills.of_weapon("katana"):
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoKatana = arena.weapon
	hero.position = Vector2.ZERO
	await process_frame
	_check(weapon._unique("k_slash") and weapon._unique("k_perun"), "katana widzi swoje kamienie unikalne")
	# Gromowe Ostrze: wróg 100 px dalej, poza zasięgiem cięcia
	var far := _goblin(arena, Vector2(100, 0))
	await process_frame
	far._stunned = 60.0
	var hp := far.hp
	weapon._aim = 0.0
	weapon._slash_hit()
	_check(weapon._sparks_fly.size() == 1, "Gromowe Ostrze: z cięcia leci łuk pioruna")
	await _wait(0.6)
	_check(far.hp < hp and weapon._sparks_fly.is_empty(), "łuk trafia wroga poza zasięgiem cięcia i gaśnie")
	# Wir Ostrza: postać zostaje w miejscu, cięcia dookoła
	var around: Array = []
	for at in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 30), Vector2(0, -30)]:
		around.append(_goblin(arena, at))
	await process_frame
	for g in around:
		g._stunned = 60.0
	var hps: Array = around.map(func(g: ProtoGoblin) -> int: return g.hp)
	_fresh(weapon, hero)
	hero.position = Vector2.ZERO
	await process_frame
	weapon.cast("k_dance")
	await _wait(1.2)
	var struck := 0
	for i in around.size():
		if around[i].hp < hps[i]:
			struck += 1
	_check(hero.position.length() < 2.0, "Wir Ostrza: postać zostaje w miejscu")
	_check(struck == 4, "cięcia dookoła trafiają wrogów ze wszystkich stron (%d z 4)" % struck)
	# Łańcuch Kontr: wróg obok postaci trafiony kontrą, a od niego dalszy wróg poza zasięgiem kontry
	for g in around:
		g.queue_free()
	far.queue_free()
	var near := _goblin(arena, Vector2(0, 200))
	var chain := _goblin(arena, Vector2(25, 200))
	var chain2 := _goblin(arena, Vector2(50, 200))
	await process_frame
	for g in [near, chain, chain2]:
		g._stunned = 60.0
	_fresh(weapon, hero)
	hero.position = Vector2(0, -200)  # z dala - rani tylko łańcuch kontr
	await process_frame
	var hp_c := chain.hp
	var hp_c2 := chain2.hp
	weapon._echoed = []
	weapon._echo_from(near)
	await _wait(0.6)
	_check(chain.hp < hp_c and chain2.hp < hp_c2 and weapon._echoed.size() == 3,
			"Łańcuch Kontr: od trafionego kontra przechodzi łańcuchem dalej (%d kontr)" % weapon._echoed.size())
	weapon._echo_from(near)
	_check(weapon._echoes.is_empty(), "każdy wróg tnie najwyżej raz na Ripostę")
	_fresh(weapon, hero)
	hero.position = near.position + Vector2(-30, 0)
	await process_frame
	weapon.cast("k_riposte")
	hero.take_damage(5)
	_check(weapon._echoed.has(near), "prawdziwa kontra też odpala łańcuch")
	# Wędrowne Gromy: krótkie ładowanie - 2 pioruny, pełne - 6
	for g in [near, chain, chain2]:
		g.queue_free()
	await process_frame
	var crowd: Array = []
	for i in 7:
		crowd.append(_goblin(arena, Vector2(-120 + i * 40, 120)))
	await process_frame
	for g in crowd:
		g._stunned = 60.0
		g.hp = 100000
	_fresh(weapon, hero)
	hero.position = Vector2.ZERO
	await process_frame
	weapon._aim = PI / 2.0
	weapon._perun_cut(0.0)
	_check(weapon._crawlers.size() == ProtoKatana.CRAWL_COUNT.x, "krótkie ładowanie - 2 pełzające pioruny")
	await _wait(1.5)
	weapon._crawlers.clear()
	_fresh(weapon, hero)
	weapon._aim = PI / 2.0
	weapon._perun_cut(1.0)
	var targets := {}
	for c in weapon._crawlers:
		if c.target != null:
			targets[c.target] = true
	_check(weapon._crawlers.size() == ProtoKatana.CRAWL_COUNT.y and targets.size() == weapon._crawlers.size(),
			"pełne ładowanie - 6 piorunów, każdy do innego wroga")
	hps = crowd.map(func(g: ProtoGoblin) -> int: return g.hp)
	await _wait(2.0)
	struck = 0
	for i in crowd.size():
		if crowd[i].hp < hps[i]:
			struck += 1
	_check(struck >= 5 and weapon._crawlers.is_empty(), "pioruny dopełzły do wrogów (%d)" % struck)
	game.dev_immortal = false
	# obszar umiejętności poszerza łuk Gromowego Ostrza (19.11.2026)
	for f in weapon._sparks_fly:
		f.node.queue_free()
	weapon._sparks_fly.clear()
	weapon.area_bonus = 100.0
	weapon._aim = 0.0
	weapon._slash_hit()
	_check(weapon._sparks_fly.size() == 1 and is_equal_approx(weapon._sparks_fly[0].node.scale.x, weapon._area(weapon.basic)),
			"obszar poszerza łuk Gromowego Ostrza (x%.1f)" % weapon._area(weapon.basic))
	weapon.area_bonus = 0.0
	arena.queue_free()
	await process_frame


func _fresh(weapon: ProtoKatana, hero: ProtoHero) -> void:
	weapon.reset_cooldowns()
	weapon._end_skill()
	hero.mana = hero.max_mana


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g

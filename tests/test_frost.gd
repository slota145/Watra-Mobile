extends SceneTree
## Test siódmego lochu - Lodowe jaskinie (Dungeons.FROST, 25.11.2026): miejsce na drabince (31-35, po Wulkanicznych,
## krąg 35 poziomów), odporności (lód +20%, ogień -20%), potwory (Zmarzlak - lód i chłód, Śnieżnica - sopel, Lodowy
## olbrzym - cios zamraża), wymarzanie i koksowniki (ProtoFrost: chłód rośnie, spowalnia, przy pełnym rani; koksownik
## rozgrzewa i daje Rozgrzanie) i boss Dziad Mróz (tchnienie, deszcz sopli, lodowe kolce, zamieć poniżej połowy).

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
	_check(Dungeons.first_level(Dungeons.FROST) == 31 and Dungeons.for_level(35) == Dungeons.FROST
			and Dungeons.for_level(30) == Dungeons.VOLCANO and Dungeons.for_level(36) == Dungeons.GOBLINS
			and Dungeons.cycle_length() == 35, "drabinka: Lodowe jaskinie 31-35, drugi krąg od 36")
	var r := Dungeons.resists(Dungeons.FROST, 31)
	var base := DungeonLevels.base_resist(31)
	_check(is_equal_approx(r[Elements.COLD], base + 0.2) and is_equal_approx(r[Elements.FIRE], base - 0.2),
			"odporności: lód +20%, ogień -20%")
	_check(ProtoHorde.make_monster(Dungeons.FROST, "goblin") is ProtoZmarzlak
			and ProtoHorde.make_monster(Dungeons.FROST, "archer") is ProtoSniezyca
			and ProtoHorde.make_monster(Dungeons.FROST, "brute") is ProtoIceGiant, "potwory: Zmarzlak, Śnieżnica, Lodowy olbrzym")
	_check(Unlocks.all().any(func(u: Dictionary) -> bool: return int(u.level) == 31 and str(u.text).contains("Lodowe jaskinie")),
			"drabinka odblokowań: nowy loch na 31")
	await _test_frost(game)
	await _test_monsters(game)
	await _test_boss(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _arena(game: Node, level: int) -> Node:
	game.reset_hero()
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _setup(arena: Node) -> ProtoHero:
	var hero: ProtoHero = arena.hero
	arena.horde_spawner.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	ProtoDecor.obstacles.clear()
	hero.obstacles.clear()
	return hero


func _test_frost(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FROST))
	await process_frame
	var hero := _setup(arena)
	var frost: ProtoFrost = arena.frost
	_check(arena.climate == Dungeons.FROST and arena.summon_button.text == "Przyzwij Dziada Mroza" and frost != null
			and frost.braziers.size() == ProtoFrost.BRAZIERS, "poziom 31: Lodowe jaskinie z %d koksownikami" % frost.braziers.size())
	# z dala od koksowników chłód rośnie i spowalnia
	hero.position = Vector2(2000, 2000)
	frost.braziers.clear()
	hero.frost_cold = 0.0
	await _wait(1.0)
	_check(hero.frost_cold > ProtoFrost.COLD_RATE * 0.7 and hero.frost_cold < ProtoFrost.COLD_RATE * 1.5,
			"chłód rośnie (%.1f na sekundę)" % hero.frost_cold)
	hero.frost_cold = 80.0
	await _wait(0.1)
	_check(hero.chill > 0.25, "zmarznięta postać idzie wolniej (%.0f%%)" % (hero.chill * 100.0))
	# pełny chłód: zamarza i traci zdrowie
	hero.frost_cold = ProtoFrost.MAX_COLD
	var hp := hero.hp
	hero._invulnerable = 0.0
	await _wait(0.2)
	_check(hero.hp < hp, "przy pełnym chłodzie postać zamarza i traci zdrowie")
	# koksownik rozgrzewa i daje Rozgrzanie
	frost.braziers.append(hero.global_position + Vector2(10, 0))
	await _wait(0.5)
	_check(hero.frost_cold < ProtoFrost.MAX_COLD - 10.0 and frost.warm_left > 0.0
			and is_equal_approx(arena.weapon.warm_mult, 1.0 + ProtoFrost.WARM_BONUS),
			"koksownik rozgrzewa (%.0f) i daje +%d%% obrażeń" % [hero.frost_cold, roundi(ProtoFrost.WARM_BONUS * 100)])
	await _wait(ProtoFrost.MAX_COLD / ProtoFrost.WARM_RATE)
	_check(hero.frost_cold == 0.0, "przy koksowniku chłód schodzi do zera (pełny w ok. %.0f s)" % (ProtoFrost.MAX_COLD / ProtoFrost.WARM_RATE))
	frost.braziers.clear()
	await _wait(ProtoFrost.WARM_TIME + 0.2)
	_check(frost.warm_left == 0.0 and arena.weapon.warm_mult == 1.0, "Rozgrzanie mija po %d s" % ProtoFrost.WARM_TIME)
	arena.queue_free()
	await process_frame
	_check(ProtoFrost.current == null, "po wyjściu z lochu chłód nie działa")


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FROST))
	await process_frame
	var hero := _setup(arena)
	arena.frost.set_process(false)  # tylko chłód od potworów
	var horde: ProtoHorde = arena.horde_spawner
	hero.position = Vector2(0, 40)
	# Zmarzlak: cios lodem spowalnia i dokłada chłodu
	var z: ProtoZmarzlak = horde.spawn_at(hero.position + Vector2(16, 0), "goblin")
	await process_frame
	z._cooldown = 0.0
	for i in 60:
		await _wait(0.05)
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and hero.frost_cold >= ProtoZmarzlak.COLD and hero.chill > 0.0,
			"Zmarzlak rąbie lodem: spowalnia i dokłada chłodu (%.0f)" % hero.frost_cold)
	z.queue_free()
	# Śnieżnica: sopel z daleka
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	hero.frost_cold = 0.0
	var s: ProtoSniezyca = horde.spawn_at(hero.position + Vector2(110, 0), "archer")
	await process_frame
	s._cooldown = 0.0
	var icicle := false
	for i in 80:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.ice and c.element == Elements.COLD:
				icicle = true
		if hero.hp < hero.max_hp:
			break
	_check(icicle and hero.hp < hero.max_hp and hero.frost_cold > 0.0, "Śnieżnica ciska sopel: rani i schładza")
	s.queue_free()
	# Lodowy olbrzym: cios w koło prawie zamraża
	await _wait(0.5)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	hero.frost_cold = 0.0
	var g: ProtoIceGiant = horde.spawn_at(hero.position + Vector2(26, 0), "brute")
	await process_frame
	g._cooldown = 0.0
	for i in 80:
		await _wait(0.05)
		if g._telegraph and is_instance_valid(g._telegraph):
			hero.position = g._telegraph.global_position  # stoi w kole
		if hero.hp < hero.max_hp:
			break
	_check(hero.hp < hero.max_hp and hero.frost_cold >= ProtoIceGiant.COLD and hero.chill >= ProtoIceGiant.FREEZE_SLOW - 0.01,
			"Lodowy olbrzym: cios w koło prawie zamraża postać")
	g.queue_free()
	arena.queue_free()
	await process_frame


func _test_boss(game: Node) -> void:
	var arena := _arena(game, Dungeons.first_level(Dungeons.FROST) + 1)
	await process_frame
	var hero := _setup(arena)
	arena.frost.set_process(false)
	var horde: ProtoHorde = arena.horde_spawner
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var m := arena.chief as ProtoDziadMroz
	_check(m != null and arena.boss_box.get_child(0).text == "Dziad Mróz", "przyzwany Dziad Mróz")
	m.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# mroźne tchnienie: wachlarz przed nim
	hero.position = m.position + Vector2(0, 70)
	hero.frost_cold = 0.0
	hero._invulnerable = 0.0
	m.start_attack("breath")
	_check(m._telegraph != null and m._telegraph.arc > 0.0 and m._telegraph.contains(hero.global_position), "tchnienie: wachlarz przez postać")
	await _wait(ProtoDziadMroz.BREATH_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.frost_cold >= ProtoDziadMroz.BREATH_COLD, "tchnienie rani i mocno schładza")
	# deszcz sopli
	await _wait(0.8)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	m.start_attack("rain")
	_check(m.rain_pending() == ProtoDziadMroz.RAIN_DROPS, "deszcz: %d sopli" % m.rain_pending())
	await _wait(ProtoDziadMroz.RAIN_WARN + ProtoDziadMroz.RAIN_STEP * ProtoDziadMroz.RAIN_DROPS + 0.2)
	_check(m.rain_pending() == 0 and hero.hp < hero.max_hp, "sople spadają, pierwszy trafia postać")
	# lodowe kolce: pas do postaci
	await _wait(0.8)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	hero.position = m.position + Vector2(90, 0)
	m.start_attack("spikes")
	_check(m._telegraph != null and m._telegraph.length > 0.0 and m._telegraph.contains(hero.global_position), "kolce: pas przez postać")
	await _wait(ProtoDziadMroz.SPIKES_WARN + 0.1)
	_check(hero.hp < hero.max_hp, "lodowe kolce ranią postać w pasie")
	# zamieć poniżej połowy zdrowia
	await _wait(0.8)
	m.passive = false
	m.hp = roundi(m.max_hp * 0.45)
	m._cooldown = 0.0
	arena.frost.set_process(true)
	for i in 40:
		await _wait(0.05)
		if m.blizzard:
			break
	_check(m.blizzard and m._snow != null, "poniżej połowy zdrowia zrywa się zamieć")
	m.passive = true
	arena.queue_free()
	await process_frame

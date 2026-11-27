extends SceneTree
## Test aur rezerwujących manę (Auras): dane i rezerwacja, zdobywanie z kamienia (poziomy za duplikaty), zapis,
## limit 75% i zasada „mana na najdroższą umiejętność”, łup ze skrzyń od lochu 8, premie postaci (Krzepa, Strzybóg,
## odnowa), rezerwacja na pasku many, działanie w walce (Swaróg, Perun, Szron, Ognik), podniesienie kamienia z ziemi
## i zakładka „Aury” w oknie umiejętności. Krok 2: pozostałe 13 aur (premie, tarcza, Kamienna Krew, kręgi na wrogów,
## Zwiastuny, Złość Licha) i premia przedmiotów „mniejsza rezerwacja many”.

var _failed := 0


func _initialize() -> void:
	DungeonLevels.enemy_hp = 1.0  # liczby w testach bez próby x3 zdrowia / x2 obrażeń wrogów (20.11.2026)
	DungeonLevels.ramp_start = 1.0  # bez Rozruchu (27.11.2026)
	DungeonLevels.enemy_damage = 1.0
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
	_test_data()
	_test_game(game)
	await _test_combat(game)
	await _test_window(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s (błędów: %d)" % ["OK" if _failed == 0 else "BŁĘDY", _failed])
	quit(1 if _failed > 0 else 0)


func _test_data() -> void:
	var ok := true
	for id in Auras.ORDER:
		ok = ok and Auras.is_aura(id) and Auras.name_of(id) != "" and Auras.effect_text(id, 1) != ""
		ok = ok and Auras.reserve_of(id, 1) >= 0.15 and Auras.reserve_of(id, 1) <= 0.35
	_check(ok and Auras.ORDER.size() == 22 and Auras.DATA.size() == 22, "22 aury z nazwą, opisem i rezerwacją 15-35%")
	_check(Auras.reserve_of("perun", 10) < Auras.reserve_of("perun", 1), "wyższy poziom aury rezerwuje mniej")
	_check(Auras.power("krzepa", 10) > Auras.power("krzepa", 1), "wyższy poziom - mocniejsza aura")
	var none := true
	for i in 200:
		none = none and Auras.roll_chest(Auras.MIN_LEVEL - 1, false, 10.0) == ""
	_check(none, "przed lochem %d kamienie aur nie wypadają" % Auras.MIN_LEVEL)
	var some := false
	for i in 200:
		some = some or Auras.is_aura(Auras.roll_chest(Auras.MIN_LEVEL, false, 1.0))
	_check(some, "od lochu %d skrzynia Wodza daje czasem kamień aury" % Auras.MIN_LEVEL)
	var g := Auras.apply({"move_pct": 45.0}, ["strzybog", "krzepa"], {"strzybog": 1})
	_check(g.move_pct == Items.CAPS.move_pct and g.attack_speed_pct == 10.0 and g.aura_hp_pct == 0.2,
			"Strzybóg i Krzepa w cechach postaci (z sufitem szybkości ruchu)")
	_check(is_equal_approx(g.aura_reserve, 0.55), "rezerwacja dwóch aur: 30% + 25%")
	g = Auras.apply({"reserve_pct": 20.0}, ["strzybog", "krzepa"], {})
	_check(is_equal_approx(g.aura_reserve, 0.44), "premia przedmiotów: 20% mniejsza rezerwacja")
	var gear := Items.totals({})
	gear.element_res_raw = 90.0
	gear.element_res_pct = 75.0
	g = Auras.apply(gear, ["hart"], {"hart": 10})
	_check(is_equal_approx(g.element_res_pct, 75.0 + Auras.power("hart", 10)) and g.element_res_pct <= 85.0,
			"Hart Żywiołów: sufit odporności do 85%% (%.1f)" % g.element_res_pct)
	g = Auras.apply(Items.totals({}), ["pieczec", "jarylo", "trzyglow", "weles"], {})
	_check(g.element_res_pct == 12.0 and g.crit_pct == 5.0 and g.crit_dmg_pct == 20.0 and g.protection_pct == 8.0
			and g.pickup_pct == 50.0 and g.xp_pct == 5.0, "Pieczęć, Jaryło, Trzygłów i Weles w cechach postaci")
	var slots_ok := true
	var seen := false
	for i in 600:
		var item := Items.roll(20, "", "rare")
		for a in item.affixes:
			if a.stat == "reserve_pct":
				seen = true
				slots_ok = slots_ok and item.slot in ["ring", "amulet"]
	_check(seen and slots_ok, "premia „mniejsza rezerwacja” tylko na pierścieniu i amulecie")
	_check(not Items.affix_fits("reserve_pct", "helmet") and Items.affix_fits("hp", "helmet"), "premie według miejsca")


func _test_game(game: Node) -> void:
	game.hero_level = 1
	_check(game.add_aura("krzepa") == 1 and game.auras.krzepa == 1, "kamień aury uczy aury")
	_check(game.add_aura("krzepa") == 2, "kolejny taki sam kamień - poziom 2")
	game.auras["krzepa"] = Auras.MAX_LEVEL
	_check(game.add_aura("krzepa") == 0, "na najwyższym poziomie kamień przepada")
	_check(game.add_aura("nie_ma") == 0, "nieznana aura - nic")
	var before: Dictionary = game.auras.duplicate()
	game.dev_auras()
	_check(game.auras.size() == Auras.ORDER.size() and game.auras.krzepa == Auras.MAX_LEVEL,
			"tryb deweloperski: wszystkie aury")
	game.auras = before
	game.auras["krzepa"] = 1
	# 1. poziom: 50 many, zwykły cios nic nie kosztuje - jedna aura wchodzi
	_check(game.toggle_aura("krzepa") == "" and game.auras_on.has("krzepa"), "włączenie aury")
	game.dev_skills()
	game.hero_level = 15
	game.add_aura("perun")
	game.add_aura("strzybog")
	game.add_aura("ognik")
	_check(game.toggle_aura("perun") == "", "druga aura na 15. poziomie")
	game.auras_on = ["perun"]
	game.hero_level = 8  # 106 many: Perun 35% + Krzepa 25% zostawia 42, a Krąg stali kosztuje 45
	game.assign_skill("steel_ring", 1)
	var problem: String = game.aura_problem("krzepa")
	_check(problem.contains("45"), "aura nie zabiera many na najdroższą umiejętność: " + problem)
	game.hero_level = 15
	game.auras_on = ["ognik", "perun"]
	_check(game.aura_problem("krzepa") != "", "limit 75% many: 35% + 35% + 25% się nie mieści")
	game.auras_on = []
	game.save_game()
	game.auras_on = ["perun"]
	game.save_game()
	game.load_game()
	_check(game.auras.get("perun", 0) == 1 and game.auras.get("krzepa", 0) == 1 and game.auras_on == ["perun"],
			"aury i włączone zapisują się")
	game.auras_on = []
	var chest_aura := false
	for i in 400:
		for loot in DungeonGoals.chest_items(Auras.MIN_LEVEL, 1.0):
			chest_aura = chest_aura or loot.has("aura")
	_check(chest_aura, "skrzynia na mapie lochu daje czasem kamień aury")
	_check(ProtoLoot.name_of({"aura": "perun"}).contains(Auras.name_of("perun")), "nazwa kamienia aury na ziemi")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	arena.weapon.targets.append(g)
	return g


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.auras = {"krzepa": 1, "strzybog": 1, "swarog": 1, "perun": 1, "szron": 1, "ognik": 1, "zywia": 1, "mana": 1}
	game.auras_on = ["krzepa", "strzybog"]
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	var base_hp := HeroLevels.max_hp(15)  # bez przedmiotów
	_check(hero.max_hp == roundi(base_hp * 1.2), "Krzepa: +20%% zdrowia (%d)" % hero.max_hp)
	_check(is_equal_approx(hero.move_mult, 1.1), "Strzybóg: szybszy ruch")
	var reserved := roundi(hero.max_mana * 0.55)
	_check(hero.reserved == reserved and hero.mana == hero.max_mana - reserved, "aury rezerwują manę (%d)" % hero.reserved)
	hero.add_mana(1000)
	_check(hero.mana == hero.mana_cap(), "mana nie rośnie ponad rezerwację")
	_check(arena.mana_reserved.visible and arena.aura_icons.get_child_count() == 2, "pasek many: rezerwacja i 2 ikonki aur")
	_check(arena.auras_node.on.size() == 2, "kręgi aur pod postacią")
	# wyłączenie aury nie dolewa many od razu
	var before := hero.mana
	game.toggle_aura("krzepa")
	await process_frame
	_check(hero.mana == before and hero.mana_cap() > before, "wyłączona aura nie dolewa many")
	_check(hero.max_hp == HeroLevels.max_hp(15), "bez Krzepy - zwykłe zdrowie")
	# działanie w walce
	game.auras_on = ["swarog", "perun", "szron"]
	game.auras_changed.emit()
	game.inventory_changed.emit()
	await process_frame
	_check(weapon.aura_fire > 0.0, "Swaróg: broń dodaje ogień")
	hero.position = Vector2.ZERO
	var g := _goblin(arena, hero.position + Vector2(30, 0))
	g.power = 5000.0
	await process_frame
	var hp := g.hp
	weapon._deal(g, 10, hero.global_position, "strike")
	_check(hp - g.hp > 10, "Swaróg: cios + ogień (%d)" % (hp - g.hp))
	arena.auras_node._perun_next = 0.0
	hp = g.hp
	await _wait(0.2)
	_check(g.hp < hp and g.is_shocked(), "Perun: piorun trafia i poraża")
	hp = g.hp
	arena.auras_node._szron_next = 0.0
	await process_frame
	await process_frame
	_check(g.hp < hp and g.speed_factor() < 1.0, "Szron: rany od mrozu i spowolnienie w kręgu")
	game.auras_on = ["ognik"]
	game.auras_changed.emit()
	g.position = hero.position
	g.stun(5.0)
	hp = g.hp
	var hit := false
	for i in 40:
		await _wait(0.06)
		g.position = hero.position + arena.auras_node._wisp.position
		hit = hit or g.hp < hp
	_check(hit, "Błędny Ognik rani wroga, przez którego przelatuje")
	# kamień aury z ziemi
	var drop: ProtoLoot = arena.horde_spawner.drop_item({"aura": "zywia"}, hero.position + Vector2(10, 0))
	drop.magnet = 1000.0
	await _wait(1.0)
	_check(game.auras.get("zywia", 0) == 2, "podniesiony kamień aury podnosi poziom")
	await _test_step2(game, arena, hero, weapon)
	arena.queue_free()
	await process_frame
	game.auras_on = []


func _test_step2(game: Node, arena: Node, hero: ProtoHero, weapon: ProtoWeapon) -> void:
	for t in weapon.targets:  # gobliny z poprzednich sprawdzeń znikają, postać nie może zginąć
		if t is ProtoGoblin:
			t.queue_free()
	weapon.targets = weapon.targets.filter(func(t: ProtoTarget) -> bool: return not t is ProtoGoblin)
	hero.immortal = true
	game.auras = {"mokosz": 1, "kamienna_krew": 1, "postrach": 1, "mgla": 1, "czarnobog": 1, "popiol": 1, "mroz": 1,
			"licho": 1}
	game.auras_on = ["mokosz", "kamienna_krew"]
	game.auras_changed.emit()
	game.inventory_changed.emit()
	await _wait(0.6)
	_check(hero.shield_max == roundi(hero.max_hp * 0.15) and hero.shield == hero.shield_max and arena.shield_bar.visible,
			"Opieka Mokoszy: tarcza 15%% zdrowia (%d) na pasku zdrowia" % hero.shield)
	hero.protection = 0.0
	hero.hp = hero.max_hp
	var hp := hero.hp
	hero._invulnerable = 0.0
	hero.take_damage(hero.shield - 1)
	_check(hero.hp == hp and hero.shield == 1, "tarcza bierze cios na siebie")
	hero._invulnerable = 0.0
	hero.take_damage(11)
	_check(hero.hp == hp - 10 and hero.shield == 0, "nadwyżka ciosu przechodzi na zdrowie")
	hero._shield_wait = 0.01
	await _wait(0.1)
	_check(hero.shield == hero.shield_max, "tarcza odnawia się po chwili bez trafienia")
	hero.shield = 0
	hero._shield_wait = 99.0
	hero.hp = roundi(hero.max_hp * 0.2)
	hp = hero.hp
	hero._invulnerable = 0.0
	hero.take_damage(100)
	_check(hp - hero.hp == 70, "Kamienna Krew: przy niskim zdrowiu 30%% mniej (%d)" % (hp - hero.hp))
	hero.hp = hero.max_hp
	# kręgi na wrogów
	game.auras_on = ["postrach", "czarnobog"]
	game.auras_changed.emit()
	game.inventory_changed.emit()
	var g := _goblin(arena, hero.position + Vector2(20, 0))
	g.power = 5000.0
	g.stun(10.0)
	await _wait(1.2)
	_check(g.aura_weak > 0.0 and g.speed_factor() < 1.0, "Postrach: wróg w kręgu słabszy i wolniejszy")
	_check(g.pride > 0.0 and g.pride < Auras.power("czarnobog"), "Piętno Czarnoboga rośnie w kręgu (%.2f)" % g.pride)
	hero.shield_max = 0
	hero._invulnerable = 0.0
	hp = hero.hp
	g.hit_hero(hero, 100)
	_check(hp - hero.hp == 85, "Postrach: cios wroga 15%% słabszy (%d)" % (hp - hero.hp))
	g.aura_miss = 1.0
	hero._invulnerable = 0.0
	hp = hero.hp
	g.hit_hero(hero, 100)
	_check(hero.hp == hp, "Mgła Nawii: wróg chybia")
	g.aura_miss = 0.0
	g.position = hero.position + Vector2(300, 0)
	await _wait(1.0)
	_check(g.pride == 0.0, "Piętno gaśnie poza kręgiem")
	# Zwiastuny
	game.auras_on = ["popiol", "mroz"]
	game.auras_changed.emit()
	var near := _goblin(arena, hero.position + Vector2(200, 0))
	near.power = 5000.0
	var dead := _goblin(arena, hero.position + Vector2(215, 0))
	await process_frame
	hp = near.hp
	arena.auras_node.on_monster_died(dead)
	await process_frame
	await process_frame
	_check(near.hp < hp and near.speed_factor() < 1.0, "Zwiastuny: wybuch zabitego rani i spowalnia sąsiada")
	# Złość Licha
	game.auras_on = ["licho"]
	game.inventory_changed.emit()
	_check(is_equal_approx(ProtoTarget.burn_power, 1.25) and is_equal_approx(ProtoTarget.burn_length, 1.3),
			"Złość Licha: mocniejsze i dłuższe podpalenia")
	game.auras_on = []
	game.inventory_changed.emit()
	_check(ProtoTarget.burn_power == 1.0, "bez Licha zwykłe podpalenia")


func _test_window(game: Node) -> void:
	game.auras = {"krzepa": 3, "perun": 1}
	game.auras_on = []
	game.hero_level = 15
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var win: SkillsWindow = arena.skills_window
	arena.open_skills()
	win.set_aura_mode()
	await process_frame
	_check(win.aura_scroll.visible and not win.skill_scroll.visible and not win.slots_row.visible,
			"zakładka „Aury” zamiast listy umiejętności")
	_check(win.aura_list.get_child_count() == Auras.ORDER.size() + 1, "wiersz każdej aury i suma rezerwacji")
	var button: Button = null
	for b in win.aura_list.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.size.y < 44:
			button = b
	_check(button == null, "przyciski aur mają co najmniej 44 px")
	win._on_aura_pressed("krzepa")
	await process_frame
	_check(game.auras_on == ["krzepa"], "przycisk włącza aurę")
	win.set_gems_mode(false)
	await process_frame
	_check(win.skill_scroll.visible and not win.aura_scroll.visible, "powrót do listy umiejętności")
	win.close()
	arena.queue_free()
	await process_frame

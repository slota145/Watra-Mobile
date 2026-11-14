extends SceneTree
## Test glewii ognia (13.11.2026): dostępność (próg Wodza 10. poziomu albo 3000 zł), kupno, zmiana broni (osobne
## miejsca umiejętności i mistrzostwo, odblokowanie zwykłego ciosu glewii), podmiana węzła broni w bazie, przyciski
## broni w oknie umiejętności, a w walce: pchnięcie na linii z podpaleniem, Ognisty zamach w łuku, Płonący ślad
## (doskok i pas ognia, który rani), Słup ognia (wybuch i płonący krąg) i Taniec płomieni (lecące cięcia).

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
	await _test_base(game)
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
	game.best_level = 0
	_check(Weapons.element_of("glaive") == Elements.FIRE and Weapons.unlock_level("glaive") == 10
			and Weapons.price_of("glaive") == 3000, "glewia ognia: ogień, Wódz 10. poziomu albo 3000 zł")
	_check(Skills.of_weapon("glaive").size() == 5 and Skills.basic_of("glaive") == "g_thrust" and Skills.is_basic("g_thrust")
			and not Skills.is_basic("g_sweep"), "5 umiejętności glewii, zwykły cios - pchnięcie")
	_check(not game.weapon_available("glaive") and not game.set_weapon("glaive"), "na start glewii nie ma")
	game.gold = 2999
	_check(not game.buy_weapon("glaive") and game.gold == 2999, "za mało złota - nie kupi")
	game.best_level = 10
	_check(game.weapon_available("glaive"), "po przebiciu 10. poziomu glewia za darmo")
	game.best_level = 0
	game.gold = 3500
	_check(game.buy_weapon("glaive") and game.gold == 500 and game.weapon_available("glaive"), "kupno glewii za 3000 zł")
	_check(not game.buy_weapon("glaive") and game.gold == 500, "drugi raz się nie kupi")
	game.hero_level = 15
	game.mastery["sword"] = 6
	game._unlock_skills()
	var sword_slots: Array = game.skill_slots.duplicate()
	_check(game.set_weapon("glaive") and game.weapon == "glaive" and game.skill_slots == ["g_thrust", "", "", "", ""]
			and game.main_skill() == "g_thrust" and game.skills_owned.has("g_thrust"), "glewia w ręku: pchnięcie pod „Atak”")
	_check(game.mastery_level() == 1 and game.mastery_level("sword") == 6, "glewia ma własne mistrzostwo")
	game.add_mastery(Weapons.xp_to_next(1) + Weapons.xp_to_next(2))
	_check(game.skills_owned.has("g_sweep") and game.skill_slots[1] == "g_sweep" and not game.skills_owned.has("g_trail"),
			"mistrzostwo glewii 3 odblokowuje Ognisty zamach")
	_check(not game.assign_skill("whirl", 2), "umiejętności miecza nie wstawi się przy glewii")
	game.save_game()
	game.load_game()
	_check(game.weapon == "glaive" and game.skill_slots[1] == "g_sweep" and game.weapons_bought == ["glaive"],
			"broń w ręku, miejsca i kupno w zapisie")
	_check(game.set_weapon("sword") and game.skill_slots == sword_slots and game.mastery_level() == 6,
			"powrót do miecza: jego miejsca i mistrzostwo")
	game.save_game()
	game.load_game()
	_check(game.set_weapon("glaive") and game.skill_slots[1] == "g_sweep", "miejsca glewii zostają po zapisie")


func _test_base(game: Node) -> void:
	game.set_weapon("sword")
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	_check(not (arena.weapon is ProtoGlaive), "w bazie miecz")
	arena.skills_window.open(true)
	await process_frame
	var win: SkillsWindow = arena.skills_window
	var gb: Button = win.weapon_buttons["glaive"]
	_check(gb.get_global_rect().size.y >= 44.0 and win.row_boxes[0].visible and not win.row_boxes[Skills.ORDER.find("g_thrust")].visible,
			"przyciski broni min. 44 px, lista tylko umiejętności miecza")
	gb.pressed.emit()
	await process_frame
	_check(game.weapon == "glaive" and arena.weapon is ProtoGlaive and arena.weapon.basic == "g_thrust"
			and arena.weapon.main_skill == "g_thrust" and arena.actions.attack.icon == Skills.icon_of("g_thrust"),
			"stuknięcie glewii: broń w ręku, nowy węzeł, ikona pchnięcia na „Atak”")
	_check(not win.row_boxes[0].visible and win.row_boxes[Skills.ORDER.find("g_thrust")].visible
			and win.mastery_label.text.contains(Weapons.name_of("glaive")), "lista i mistrzostwo glewii")
	_check(arena.weapon.targets.size() == arena.DUMMIES.size(), "glewia zna kukły")
	win.close()
	arena.skills_window.open(false)
	win.weapon_buttons["sword"].pressed.emit()
	_check(game.weapon == "glaive", "z pauzy (bez kamienia run) broni się nie zmienia")
	win.close()
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


func _burning(g: ProtoGoblin) -> bool:
	var st := g.get_node_or_null(^"_Status")
	return st != null and st.burn_left > 0.0


func _test_combat(game: Node) -> void:
	game.hero_level = 20
	game.dev_set_level(20)
	game.dev_skills()
	for i in range(1, 5):
		game.skill_slots[i] = Skills.of_weapon("glaive")[i]
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoGlaive = arena.weapon
	_check(weapon is ProtoGlaive and game.skills_owned.has("g_dance"), "w lochu glewia ze wszystkimi umiejętnościami")
	hero.position = Vector2.ZERO
	var near := _goblin(arena, Vector2(30, 0))
	var far := _goblin(arena, Vector2(58, 0))
	var side := _goblin(arena, Vector2(0, 40))
	await _wait(0.2)
	for g in [near, far, side]:
		g._stunned = 30.0
	var hp := [near.hp, far.hp, side.hp]
	weapon._aim = 0.0
	weapon._attack()
	weapon._aim = 0.0
	await _wait(0.4)
	_check(near.hp < hp[0] and far.hp < hp[1] and side.hp == hp[2], "pchnięcie rani wszystkich na linii, nie z boku")
	_check(_burning(near) and _burning(far), "pchnięcie podpala")
	await _wait(0.05)
	var st := near.get_node(^"_Status")
	_check(st._flames.visible and st._front.visible and st._flames.material is CanvasItemMaterial,
			"podpalony goblin płonie (płomienie za nim i przed nim, świecące)")
	# Ognisty zamach
	await _wait(0.5)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hp = [near.hp, side.hp]
	_check(weapon.cast("g_sweep"), "Ognisty zamach rusza")
	await _wait(0.8)
	_check(near.hp < hp[0], "zamach rani wroga przed postacią")
	# Słup ognia: wybuch i płonący krąg
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	await _wait(0.3)
	hp = [near.hp]
	_check(weapon.cast("g_pillar"), "Słup ognia rusza")
	await _wait(0.5)
	_check(near.hp < hp[0] and weapon._zones.size() >= 1, "wybuch rani, ziemia płonie")
	var after: int = near.hp
	await _wait(1.2)
	_check(near.hp < after, "płonący krąg dalej rani")
	# Płonąca bruzda: postać stoi, glewia ryje pas ognia, 3 szybkie cięcia w wachlarzu
	await _wait(0.6)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = Vector2(-60, 0)
	var start := hero.global_position
	hp = [near.hp]
	_check(weapon.cast("g_trail"), "Płonąca bruzda rusza")
	await _wait(0.4)
	var furrow_cuts := weapon._cuts.filter(func(c: Dictionary) -> bool: return c.skill == "g_trail")
	_check(hero.global_position.distance_to(start) < 2.0 and furrow_cuts.size() == 3, "postać stoi, 3 cięcia w wachlarzu")
	_check(weapon._zones.any(func(z: Dictionary) -> bool: return z.skill == "g_trail"), "bruzda płonie")
	await _wait(0.3)
	_check(near.hp < hp[0], "cięcia bruzdy ranią wroga przed postacią")
	# Taniec płomieni: cięcia lecą na zewnątrz
	await _wait(0.4)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = Vector2.ZERO
	hp = [near.hp, side.hp]
	_check(weapon.cast("g_dance"), "Taniec płomieni rusza")
	await _wait(1.0)
	_check(weapon._state == "dance" and weapon._cuts.size() >= 2 and not weapon._whirl_fx.visible,
			"seria cięć bez wiru, sierpy lecą (%d)" % weapon._cuts.size())
	await _wait(1.5)
	_check(near.hp < hp[0] or side.hp < hp[1], "cięcia ranią wrogów wokół")
	await _wait(1.5)
	_check(weapon._state == "follow", "po tańcu glewia wraca do postaci")
	game.dev_immortal = false
	arena.queue_free()
	await process_frame


## Kamienie unikalne glewii (14.11.2026): 3 pchnięcia w stożku, płonąca ziemia zamachu, powrót cięć bruzdy,
## 3 upadki Słupa ognia, odbicia sierpów tańca.
func _test_unique(game: Node) -> void:
	game.dev_set_level(20)
	game.dev_skills()
	for id in Skills.of_weapon("glaive"):
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	var hero: ProtoHero = arena.hero
	var weapon: ProtoGlaive = arena.weapon
	_check(weapon._unique("g_thrust") and weapon._unique("g_dance"), "kamienie unikalne glewii w gniazdach")
	hero.position = Vector2.ZERO
	var front := _goblin(arena, Vector2(40, 0))
	var up := _goblin(arena, Vector2(40, -9))
	var down := _goblin(arena, Vector2(40, 9))
	await _wait(0.2)
	for g in [front, up, down]:
		g._stunned = 60.0
	var hp := [front.hp, up.hp, down.hp]
	weapon._aim = 0.0
	weapon._thrust_hit()
	_check(front.hp < hp[0] and up.hp < hp[1] and down.hp < hp[2], "Trójząb: trzy pchnięcia w stożku")
	# Pogorzelisko: płonąca ziemia po zamachu
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("g_sweep")
	await _wait(0.5)
	_check(weapon._zones.any(func(z: Dictionary) -> bool: return z.skill == "g_sweep" and z.has("circles")), "Pogorzelisko: płonąca ziemia wzdłuż łuku")
	# Bumerang: cięcia bruzdy wracają
	await _wait(0.3)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon.cast("g_trail")
	await _wait(0.9)
	_check(weapon._cuts.any(func(c: Dictionary) -> bool: return c.skill == "g_trail" and c.get("returning", false)), "Bumerang: cięcia zawracają")
	await _wait(1.0)
	_check(not weapon._cuts.any(func(c: Dictionary) -> bool: return c.skill == "g_trail"), "cięcia wróciły i zniknęły")
	# Ognisty Deszcz: 3 upadki w 3 wrogów
	up.queue_free()
	down.queue_free()
	var far := _goblin(arena, Vector2(-70, 40))
	var far2 := _goblin(arena, Vector2(0, -80))
	await _wait(0.2)
	far2._stunned = 60.0
	far._stunned = 60.0
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	var far_hp: int = far.hp
	weapon.cast("g_pillar")
	_check(weapon._pillar_queue.size() == 2, "Ognisty Deszcz: jeszcze 2 cele w kolejce")
	await _wait(2.0)
	_check(far.hp < far_hp and weapon._state == "follow", "glewia spadła też na dalszego wroga")
	# Rykoszet Płomieni: sierp odbija się w kolejnego wroga
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	weapon._spin = 0.0
	weapon._spawn_cut(0.0)
	var cut: Dictionary = weapon._cuts.back()
	var side := _goblin(arena, Vector2(70, 50))
	await _wait(0.05)
	side._stunned = 60.0
	await _wait(1.0)
	_check(cut.bounces < ProtoGlaive.DANCE_GEM_BOUNCES, "Rykoszet: sierp odbił się (zostało %d)" % cut.bounces)
	game.dev_immortal = false
	arena.queue_free()
	await process_frame


extends SceneTree
## Test talizmanów (Talismans): dane, zdobywanie (poziomy za duplikaty, samo zakładanie w wolne miejsce), zakładanie
## i zdejmowanie, zapis, łup (skrzynie na mapie lochu i Krąg Żertwy od lochu 5), działanie w walce każdego z 10
## efektów i zakładka „Talizmany” w oknie „Postać”.

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
	for id in Talismans.ORDER:
		ok = ok and Talismans.name_of(id) != "" and Talismans.icon_of(id) != null and Talismans.effect_text(id, 1) != ""
		ok = ok and Talismans.chance(id, 10) >= Talismans.chance(id, 1) and Talismans.power(id, 10) > Talismans.power(id, 1)
	_check(ok and Talismans.ORDER.size() == 10, "10 talizmanów z nazwą, ikoną, opisem i siłą rosnącą z poziomem")
	var none := true
	for i in 200:
		none = none and Talismans.roll_chest(Talismans.MIN_LEVEL - 1, 10.0) == ""
	_check(none, "przed lochem %d talizmany nie wypadają" % Talismans.MIN_LEVEL)
	var chest := false
	for i in 400:
		for loot in DungeonGoals.chest_items(Talismans.MIN_LEVEL, 1.0):
			chest = chest or loot.has("talisman")
	_check(chest, "skrzynia na mapie lochu daje czasem talizman")
	var offer := DungeonGoals.zertwa_offer(Talismans.MIN_LEVEL)
	_check(offer.size() == 4 and offer[2].item.has("talisman") and offer[3].has("embers"), "Krąg Żertwy: talizman do wyboru")
	_check(DungeonGoals.zertwa_offer(1).size() == 3, "Krąg Żertwy przed lochem 5 bez talizmanu")
	_check(ProtoLoot.name_of({"talisman": "thunder"}).contains(Talismans.name_of("thunder")), "nazwa talizmanu na ziemi")


func _test_game(game: Node) -> void:
	_check(game.add_talisman("thunder") == 1 and game.talisman_slots[0] == "thunder", "nowy talizman sam się zakłada")
	_check(game.add_talisman("thunder") == 2 and game.talisman_slots.count("thunder") == 1, "duplikat podnosi poziom")
	game.add_talisman("kaboom")
	game.add_talisman("devour")
	game.add_talisman("tremor")
	_check(game.talisman_slots == ["thunder", "kaboom", "devour"] and game.talismans.has("tremor"),
			"czwarty czeka w kolekcji (3 miejsca)")
	game.equip_talisman("tremor", 1)
	_check(game.talisman_slots == ["thunder", "tremor", "devour"], "zamiana w miejscu")
	game.equip_talisman("devour", 0)
	_check(game.talisman_slots == ["devour", "tremor", "thunder"], "przełożenie założonego - miejsca się zamieniają")
	game.unequip_talisman(1)
	_check(game.talisman_slots[1] == "" and game.talismans.has("tremor"), "zdjęty zostaje w kolekcji")
	game.talismans["thunder"] = Talismans.MAX_LEVEL
	_check(game.add_talisman("thunder") == 0, "na najwyższym poziomie talizman przepada")
	var before: Dictionary = game.talismans.duplicate()
	game.dev_talismans()
	_check(game.talismans.size() == Talismans.ORDER.size() and game.talismans.devour == before.devour + 1
			and game.talismans.thunder == Talismans.MAX_LEVEL, "tryb deweloperski: wszystkie talizmany")
	game.talismans = before
	game.save_game()
	game.load_game()
	_check(game.talismans.thunder == Talismans.MAX_LEVEL and game.talisman_slots == ["devour", "", "thunder"],
			"talizmany zapisują się")


func _goblin(arena: Node, at: Vector2, power := 5000.0) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = power
	g.position = at
	arena.get_node("World").add_child(g)
	arena.weapon.targets.append(g)
	return g


func _wear(game: Node, ids: Array) -> void:
	game.talismans = {}
	for id in ids:
		game.talismans[id] = Talismans.MAX_LEVEL
	game.talisman_slots = ["", "", ""]
	for i in ids.size():
		game.talisman_slots[i] = ids[i]
	game.talismans_changed.emit()


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.dev_skills()
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	hero.immortal = true
	hero.position = Vector2.ZERO
	_check(weapon.talismans == arena.talismans_node, "broń zna talizmany")
	# przy trafieniu (szansa 100% na potrzeby testu przez wiele prób)
	for id in ["shockwave", "thunder", "whirlpool", "roots"]:
		_wear(game, [id])
		var a := _goblin(arena, hero.position + Vector2(150, 0))
		var b := _goblin(arena, hero.position + Vector2(165, 0))
		a.stun(10.0)
		b.stun(10.0)
		await process_frame
		var hp := b.hp
		for i in 60:
			arena.talismans_node._hit_ready.clear()
			arena.talismans_node.on_hit(a)
			if b.hp < hp:
				break
		await _wait(0.4)
		_check(b.hp < hp, "%s: efekt przy trafieniu rani sąsiada" % Talismans.name_of(id))
		a.queue_free()
		b.queue_free()
		weapon.targets.erase(a)
		weapon.targets.erase(b)
	# ciernie
	_wear(game, ["thorns"])
	var g := _goblin(arena, hero.position + Vector2(10, 0))
	g.stun(10.0)
	await process_frame
	var hp := g.hp
	for i in 40:
		arena.talismans_node._hit_ready.clear()
		hero._invulnerable = 0.0
		hero.take_damage(1)
	_check(g.hp < hp, "Kora Leszego: ciernie, gdy postać dostaje cios")
	# zabójstwa
	_wear(game, ["bloodlust", "devour", "kaboom"])
	var near := _goblin(arena, hero.position + Vector2(10, 0))
	hp = near.hp
	hero.hp = hero.max_hp / 2
	var hero_hp := hero.hp
	for i in 30:
		arena.talismans_node.on_kill(g)
	await process_frame
	await process_frame
	_check(weapon.bonus_mult > 1.0, "Czaszka Biesa: więcej obrażeń po zabójstwach (x%.2f)" % weapon.bonus_mult)
	_check(hero.hp > hero_hp, "Ząb Pożeracza: pokonany wróg leczy")
	_check(near.hp < hp, "Serce Goblina: pokonany wróg wybucha")
	# Serce Głębin i Kryształ Peruna
	_wear(game, ["tremor", "archmage"])
	await process_frame
	_check(weapon.mana_tax > 0.0 and weapon.mana_cost("whirl") > roundi(Skills.mana_of("whirl")),
			"Kryształ Peruna: umiejętności droższe")
	hp = near.hp
	arena.talismans_node._tremor_next = 0.0
	await _wait(0.1)
	_check(near.hp < hp, "Serce Głębin: drżenie ziemi rani wrogów wokół")
	hp = near.hp
	arena.talismans_node.on_skill("whirl")
	_check(near.hp < hp and near.is_shocked(), "Kryształ Peruna: umiejętność ciska piorun")
	_wear(game, [])
	await process_frame
	_check(weapon.mana_tax == 0.0 and weapon.bonus_mult == 1.0, "bez talizmanów broń jak zwykle")
	# premia przedmiotów „+% obrażeń od żywiołów” (20.11.2026)
	_check(Items.STAT_FORMATS.has("elem_dmg_pct") and Items.AFFIXES.has("elem_dmg_pct"), "premia „+% obrażeń od żywiołów”")
	game.equipped = {"ring": {"slot": "ring", "tier": 0, "level": 1, "rarity": "magic", "base": {}, "sockets": [],
			"affixes": [{"stat": "elem_dmg_pct", "value": 100.0}]}}
	game.inventory_changed.emit()
	_check(is_equal_approx(weapon.elem_mult, 2.0), "broń dostaje premię żywiołów z przedmiotów")
	var dummy := _goblin(arena, hero.position + Vector2(250, 0), 50000.0)
	dummy.stun(10.0)
	await process_frame
	var fire_sum := 0
	var phys_sum := 0
	for i in 40:
		var h := dummy.hp
		weapon.aura_hit(dummy, 1.0, Elements.FIRE, hero.global_position)
		fire_sum += h - dummy.hp
		h = dummy.hp
		weapon.aura_hit(dummy, 1.0, Elements.PHYSICAL, hero.global_position)
		phys_sum += h - dummy.hp
	_check(fire_sum > phys_sum * 1.6, "żywioł x2, fizyczne bez zmian (%d / %d)" % [fire_sum, phys_sum])
	game.equipped = {}
	game.inventory_changed.emit()
	# talizman z ziemi
	var drop: ProtoLoot = arena.horde_spawner.drop_item({"talisman": "roots"}, hero.position + Vector2(10, 0))
	drop.magnet = 1000.0
	await _wait(1.0)
	_check(game.talismans.get("roots", 0) == 1 and game.talisman_slots[0] == "roots", "podniesiony talizman od razu założony")
	arena.queue_free()
	await process_frame


func _test_window(game: Node) -> void:
	game.talismans = {"thunder": 3, "kaboom": 1, "devour": 2, "tremor": 1}
	game.talisman_slots = ["thunder", "kaboom", "devour"]
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var win: HeroStats = arena.stats_window
	arena.open_stats()
	win.set_tab("talismans")
	win.refresh()
	await process_frame
	_check(win.page_talismans.visible and win.talisman_list.get_child_count() == 4, "zakładka „Talizmany”: 4 talizmany")
	win._on_talisman_button("tremor")
	_check(win.talisman_pick == "tremor", "pełne miejsca - wybór miejsca do zamiany")
	win._on_talisman_slot(1)
	_check(game.talisman_slots == ["thunder", "tremor", "devour"] and win.talisman_pick == "", "stuknięte miejsce dostaje talizman")
	win._on_talisman_button("thunder")
	_check(game.talisman_slots[0] == "", "„Zdejmij” zwalnia miejsce")
	await process_frame
	var small := false
	for b in win.page_talismans.find_children("*", "Button", true, false):
		small = small or (b.is_visible_in_tree() and (b.size.y < 44 or b.size.x < 44))
	_check(not small, "przyciski talizmanów co najmniej 44 px")
	win.close()
	arena.queue_free()
	await process_frame

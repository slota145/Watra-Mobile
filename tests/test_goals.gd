extends SceneTree
## Test celów na mapie lochu (DungeonGoals): pula rośnie z poziomem (skrzynia od 1., kapliczka od 5.), losowanie bez
## powtórek, progi paska żaru wywołują cele, cel z dala od postaci w polanie, strzałka przy krawędzi ekranu dla celu
## poza kadrem, skrzynia-cel otwiera się dopiero po staniu przy niej (odejście cofa postęp), kapliczka daje dar
## (cechy w postaci i broni, napis z czasem), dar gaśnie po czasie, cel zostaje po przyzwaniu Wodza.

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
	_test_data()
	await _test_arena()
	DirAccess.remove_absolute(root.get_node("Game").save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(DungeonGoals.pool(1) == ["chest"], "poziom 1: tylko skrzynia")
	_check(DungeonGoals.pool(5).has("shrine") and not DungeonGoals.pool(4).has("shrine"), "kapliczka od 5. poziomu")
	var used: Array[String] = []
	for i in 2:
		used.append(DungeonGoals.roll(5, used))
	_check(used.has("chest") and used.has("shrine"), "bez powtórek, póki pula pozwala")
	_check(DungeonGoals.roll(1, ["chest"]) == "chest", "mała pula - powtórka dozwolona")
	_check(DungeonGoals.thresholds_passed(24, 100) == 0 and DungeonGoals.thresholds_passed(25, 100) == 1
			and DungeonGoals.thresholds_passed(80, 100) == 3, "progi 25/50/75%")
	var items := DungeonGoals.chest_items(10)
	_check(items.size() >= 1 and items[0].has("rarity"), "skrzynia-cel: przedmiot")


func _test_arena() -> void:
	var game: Node = root.get_node("Game")
	game.dev_immortal = true
	game.dungeon_level = 5
	game.best_level = 5
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	var cost := DungeonLevels.summon_cost(arena.level)
	horde.add_embers(ceili(cost * 0.25) - 1)
	_check(arena.goals.is_empty(), "przed progiem nie ma celu")
	horde.add_embers(1)
	_check(arena.goals.size() == 1, "25% paska - pojawia się cel")
	var first: Node2D = arena.goals[0]
	await process_frame
	_check(first.is_in_group(GoalArrows.GROUP) and first.goal_active(), "cel w grupie strzałek")
	_check(first.position.distance_to(hero.position) >= DungeonGoals.MIN_DIST - 1.0
			and arena.ARENA.grow(-DungeonGoals.EDGE_MARGIN + 1.0).has_point(first.position),
			"cel z dala od postaci, w polanie (%.0f px)" % first.position.distance_to(hero.position))
	_check(arena.banner.visible, "napis o pojawieniu się celu")
	# strzałka: cel daleko poza kadrem
	first.position = hero.position + Vector2(0, 400)
	await process_frame
	await process_frame
	var arrows: Array = arena.goal_arrows.arrows()
	_check(arrows.size() == 1 and arrows[0]["dir"].y > 0.9, "strzałka przy dolnej krawędzi wskazuje cel")
	first.position = hero.position + Vector2(40, 0)
	await process_frame
	await process_frame
	_check(arena.goal_arrows.arrows().is_empty(), "cel w kadrze - bez strzałki")

	# skrzynia-cel: trzeba postać
	var box: ProtoChest = arena.spawn_goal("chest")
	box.position = hero.position + Vector2(10, 0)
	await _wait(0.5 + DungeonGoals.CHEST_HOLD * 0.5)
	_check(not box.is_open and box._hold > 0.0, "skrzynia-cel: postęp, jeszcze zamknięta")
	hero.position += Vector2(100, 0)
	await _wait(0.4)
	_check(box._hold < DungeonGoals.CHEST_HOLD * 0.5 - 0.2, "odejście cofa postęp")
	hero.position = box.position
	await _wait(DungeonGoals.CHEST_HOLD + 0.2)
	_check(box.is_open and not box.goal_active(), "po staniu przy niej skrzynia się otwiera")

	# kapliczka: dar Perun
	var damage_before: float = arena.weapon.damage_mult
	var shrine: ProtoShrine = arena.spawn_goal("shrine")
	shrine.gift = "might"
	shrine.goal_color = DungeonGoals.GIFTS["might"]["color"]
	shrine.position = hero.position + Vector2(-60, 0)
	await process_frame
	hero.position = shrine.position
	await _wait(DungeonGoals.PRAY_TIME + 0.2)
	_check(shrine.used and arena.gift == "might", "modlitwa daje dar")
	_check(is_equal_approx(arena.weapon.damage_mult, damage_before * 1.5), "Moc Peruna: +50%% obrażeń (%.2f -> %.2f)" % [damage_before, arena.weapon.damage_mult])
	_check(arena.gift_label.visible and arena.gift_label.text.contains("60"), "napis daru z czasem: %s" % arena.gift_label.text)
	# Hojność Dadźboga: więcej łupu
	var loot_before: float = horde.loot_mult
	arena.grant_gift("fortune")
	_check(is_equal_approx(arena.weapon.damage_mult, damage_before) and is_equal_approx(horde.loot_mult, loot_before * 2.0),
			"nowy dar zastępuje poprzedni (łup x2)")
	arena.grant_gift("ward")
	_check(hero.regen > 0.0 and hero.dodge >= 0.2, "Opieka Mokoszy: leczenie i unik")
	arena.gift_left = 0.05
	await _wait(0.15)
	_check(arena.gift == "" and not arena.gift_label.visible and hero.dodge < 0.2, "dar gaśnie po czasie")

	# cel zostaje po przyzwaniu Wodza
	var waiting: ProtoChest = arena.spawn_goal("chest")
	waiting.position = hero.position + Vector2(300, 0)
	horde.add_embers(cost)
	arena.summon_chief()
	await process_frame
	_check(arena.phase == "boss" and is_instance_valid(waiting) and waiting.goal_active(), "cel zostaje po przyzwaniu Wodza")
	_check(arena.goals.size() == 4, "w fazie bossa nie pojawiają się nowe cele")
	arena.queue_free()
	await process_frame
	game.dev_immortal = false

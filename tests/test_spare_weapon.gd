extends SceneTree
## Test broni zapasowej i doganiania mistrzostwa (decyzja autora 26.11.2026): mnożnik dla broni słabszej od najlepszej
## (Weapons.CATCH_UP), mistrzostwo dla obu broni, odblokowanie umiejętności zapasowej w jej miejscach, ustawianie
## i zdejmowanie, zamiana (miejsca umiejętności, broń w ręku staje się zapasową), zapis, przycisk zamiany w bazie
## (widoczność, ikona, węzeł broni, odnowienie, blokada w trakcie umiejętności), okno broni („Zapas” / „Odłóż”)
## i zamiana każdej broni w lochu z Hordą (walka trwa, mistrzostwo rośnie obu).

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	_test_game(game)
	_test_memory(game)
	await _test_arena(game)
	await _test_horde(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_game(game: Node) -> void:
	game.hero_level = 15
	game.best_level = 10  # glewia dostępna
	_check(game.mastery_mult() == 1.0, "jedyna broń - bez doganiania")
	_check(not game.set_spare("katana"), "niedostępna broń nie będzie zapasową")
	_check(not game.set_spare("sword"), "broń w ręku nie będzie zapasową")
	_check(game.set_spare("glaive") and game.spare_weapon == "glaive", "glewia zapasowa")
	game.mastery["sword"] = 10
	game.mastery_xp["sword"] = 0
	_check(game.best_mastery() == 10 and game.mastery_mult("glaive") == Weapons.CATCH_UP and game.mastery_mult() == 1.0,
			"glewia słabsza od miecza - doganianie x%d" % roundi(Weapons.CATCH_UP))
	var need: int = Weapons.xp_to_next(1) + Weapons.xp_to_next(2)
	var amount := ceili(need / Weapons.CATCH_UP)
	game.add_mastery(amount)
	_check(game.weapon_xp("sword") == amount and game.mastery_level("sword") == 10, "miecz dostaje zwykłe mistrzostwo")
	_check(game.mastery_level("glaive") == 3, "zapasowa glewia dostaje mistrzostwo x3 (poziom %d)" % game.mastery_level("glaive"))
	_check(game.skills_owned.has("g_sweep") and game.weapon_slots.get("glaive", [])[1] == "g_sweep"
			and not game.skill_slots.has("g_sweep"), "nowa umiejętność zapasowej trafia w jej miejsca, nie miecza")
	var sword_slots: Array = game.skill_slots.duplicate()
	_check(game.swap_weapons() and game.weapon == "glaive" and game.spare_weapon == "sword"
			and game.skill_slots[1] == "g_sweep" and game.weapon_slots["sword"] == sword_slots,
			"zamiana: glewia w ręku z jej miejscami, miecz zapasowy")
	game.save_game()
	game.load_game()
	_check(game.weapon == "glaive" and game.spare_weapon == "sword", "broń w ręku i zapasowa w zapisie")
	_check(game.set_weapon("sword") and game.spare_weapon == "glaive", "wzięcie zapasowej w oknie też zamienia")
	_check(game.set_spare("") and game.spare_weapon == "" and not game.swap_weapons(), "zdjęcie zapasowej - nie ma czego zamienić")
	game.mastery["glaive"] = 10
	_check(game.mastery_mult("glaive") == 1.0, "dogoniona broń - bez mnożnika")


## Pamięć oręża: poziomy do najwyżej ulepszonej umiejętności innej broni za ćwierć ceny żaru.
func _test_memory(game: Node) -> void:
	game.reset_hero()
	game.hero_level = 20
	game.best_level = 12
	game.mastery["sword"] = 20
	game.dev_skills()
	game.skill_levels["whirl"] = 4
	game.set_weapon("glaive")
	game.mastery["glaive"] = 20
	game._unlock_skills()
	_check(game.memory_level("g_sweep") == 4 and game.memory_level("whirl") == 0, "Pamięć oręża: Młynek miecza na 4")
	var full: int = Skills.upgrade_price("g_sweep", 1)
	_check(game.memory_discount("g_sweep") and game.skill_upgrade_cost("g_sweep") == ceili(full * Skills.MEMORY_DISCOUNT),
			"glewia: 2. poziom za ćwierć ceny (%d zamiast %d)" % [game.skill_upgrade_cost("g_sweep"), full])
	game.embers = 100000
	var before: int = game.embers
	game.upgrade_skill("g_sweep")
	_check(before - game.embers == ceili(full * Skills.MEMORY_DISCOUNT), "ulepszenie pobiera tańszą cenę")
	game.skill_levels["g_sweep"] = 4
	_check(not game.memory_discount("g_sweep") and game.skill_upgrade_cost("g_sweep") == Skills.upgrade_price("g_sweep", 4),
			"powyżej poziomu innej broni - pełna cena")
	game.set_weapon("sword")
	game.reset_hero()


func _test_arena(game: Node) -> void:
	game.set_spare("glaive")
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var actions: ActionCluster = arena.actions
	_check(actions.swap.visible and actions.swap.icon == Weapons.icon_of("glaive"), "przycisk zamiany z ikoną glewii")
	var r := actions.swap.get_global_rect()
	_check(r.size.x >= 44.0 and not r.intersects(actions.attack.get_global_rect())
			and actions.skills.all(func(b: ActionButton) -> bool: return not r.intersects(b.get_global_rect())),
			"przycisk zamiany 44 px, nie nachodzi na inne")
	arena.weapon._state = "whirl"
	arena._on_swap_pressed()
	_check(game.weapon == "sword", "w trakcie umiejętności zamiana czeka")
	arena.weapon._state = "follow"
	arena._on_swap_pressed()
	await process_frame
	_check(game.weapon == "glaive" and arena.weapon is ProtoGlaive and actions.swap.icon == Weapons.icon_of("sword")
			and actions.attack.icon == Skills.icon_of("g_thrust"), "zamiana: glewia w ręku, na przycisku miecz")
	arena._on_swap_pressed()
	_check(game.weapon == "glaive", "odnowienie zamiany")
	await create_timer(ActionCluster.SWAP_COOLDOWN + 0.1).timeout
	arena.weapon._state = "follow"
	arena._on_swap_pressed()
	await process_frame
	_check(game.weapon == "sword" and arena.weapon.get_script() == Weapons.script_of("sword"), "po odnowieniu wraca miecz")
	# okno broni: „Zapas” w wierszu dostępnej broni, „Odłóż” przy zapasowej
	arena.skills_window.can_shop = true
	arena.skills_window.open_weapons()
	var rows: Dictionary = arena.skills_window.weapon_rows
	_check(rows["glaive"].spare.visible and rows["glaive"].spare.text == "Odłóż" and not rows["sword"].spare.visible
			and not rows["katana"].spare.visible, "okno broni: „Odłóż” przy zapasowej, bez przycisku przy broni w ręku i zamkniętej")
	arena.skills_window._on_spare("glaive")
	_check(game.spare_weapon == "" and not actions.swap.visible, "„Odłóż” zdejmuje zapasową i chowa przycisk")
	arena.queue_free()
	await process_frame


func _test_horde(game: Node) -> void:
	game.best_level = 60  # wszystkie bronie dostępne
	game.dungeon_level = 1
	game.set_weapon("sword")
	game.set_spare("bow")
	game.dev_immortal = true
	game.auto_attack = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var order: Array = Weapons.ORDER.duplicate()
	var ok := true
	for w: String in order:
		if w == game.weapon:
			continue
		game.set_spare(w)
		await create_timer(ActionCluster.SWAP_COOLDOWN + 0.6).timeout
		arena.weapon._state = "follow"
		arena.hero.form_speed = 1.0
		arena._on_swap_pressed()
		await process_frame
		if game.weapon != w or arena.weapon.get_script() != Weapons.script_of(w):
			ok = false
			print("  nie zamieniono na ", w)
	_check(ok, "w lochu zamiana na każdą broń po kolei")
	var start_hand: int = game.mastery_level() * 100000 + game.weapon_xp()
	var spare: String = game.spare_weapon
	var start_spare: int = game.mastery_level(spare) * 100000 + game.weapon_xp(spare)
	await create_timer(6.0).timeout
	_check(arena.run_xp > 0, "w lochu z zamianami walka trwa (doświadczenie %d)" % arena.run_xp)
	_check(game.mastery_level() * 100000 + game.weapon_xp() > start_hand
			and game.mastery_level(spare) * 100000 + game.weapon_xp(spare) > start_spare, "mistrzostwo rośnie obu broniom z wyprawy")
	game.dev_immortal = false
	game.auto_attack = false
	arena.queue_free()
	await process_frame

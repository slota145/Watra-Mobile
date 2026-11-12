extends SceneTree
## Test rozwoju postaci: krzywa doświadczenia i statystyki z poziomu (HeroLevels), dodawanie doświadczenia z awansami
## i zapis (Game), doświadczenie za gobliny i Wodza w lochu, awans leczy i zwiększa zdrowie, pasek doświadczenia,
## miejsca na umiejętności zablokowane do swoich poziomów, podsumowanie w oknie wyniku, auto atak (sam tnie kukłę
## w zasięgu, bez celu - nie), liczby na paskach zdrowia, many i doświadczenia, okno „Postać” ze statystykami
## oraz skróty deweloperskie w oknie pauzy (+1 poziom, +100 żaru, postać od nowa).

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
	game.auto_attack = false
	_test_data(game)
	await _test_dungeon(game)
	await _test_base(game)
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data(game: Node) -> void:
	_check(HeroLevels.xp_to_next(1) == 50 and HeroLevels.xp_to_next(2) > 50, "krzywa doświadczenia rośnie (%d, %d)" % [HeroLevels.xp_to_next(1), HeroLevels.xp_to_next(2)])
	_check(HeroLevels.max_hp(1) == ProtoHero.MAX_HP and HeroLevels.max_hp(5) > HeroLevels.max_hp(1), "zdrowie rośnie z poziomem")
	_check(is_equal_approx(HeroLevels.damage_mult(1), 1.0) and HeroLevels.damage_mult(5) > 1.0, "obrażenia rosną z poziomem")
	_check(HeroLevels.skill_slots(1) == 0 and HeroLevels.skill_slots(3) == 1 and HeroLevels.skill_slots(99) == 4, "miejsca na umiejętności odblokowują się z poziomem")
	_check(HeroLevels.chief_xp(1) > HeroLevels.goblin_xp(1) * 10 and HeroLevels.goblin_xp(5) > HeroLevels.goblin_xp(1), "Wódz daje dużo, wyższy loch więcej")
	var ups := [0]
	var on_up := func(_l: int) -> void: ups[0] += 1
	game.leveled_up.connect(on_up)
	game.add_xp(30)
	_check(game.hero_level == 1 and game.hero_xp == 30, "doświadczenie bez awansu")
	var n: int = game.add_xp(20 + HeroLevels.xp_to_next(2) + 5)
	_check(n == 2 and game.hero_level == 3 and game.hero_xp == 5 and ups[0] == 1, "kilka awansów naraz (poziom %d, reszta %d)" % [game.hero_level, game.hero_xp])
	game.load_game()
	_check(game.hero_level == 3 and game.hero_xp == 5, "awans od razu w zapisie")
	game.add_xp(7)
	game.load_game()
	_check(game.hero_xp == 5, "zwykłe doświadczenie czeka na zapis")
	game.add_xp(7)
	game.save_if_dirty()
	game.load_game()
	_check(game.hero_xp == 12, "zapis przy przerwie zachowuje doświadczenie")
	game.leveled_up.disconnect(on_up)
	game.reset_hero()
	_check(game.hero_level == 1 and game.hero_xp == 0, "postać od nowa")


func _test_dungeon(game: Node) -> void:
	game.dungeon_level = 1
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	_check(arena.xp_bar != null and arena.hero_level_label.text == "Poz. 1" and arena.level_label.text == "Loch 1", "pasek doświadczenia i poziom postaci, loch osobno")
	var hp_bar: Rect2 = arena.health_bar.get_global_rect()
	var xp_rect: Rect2 = arena.xp_bar.get_global_rect()
	_check(xp_rect.position.y > hp_bar.position.y and xp_rect.size.y <= 12.0, "cienki pasek pod paskiem zdrowia")
	_check(arena.actions.skills[0].locked_level == 3 and arena.actions.skills[3].locked_level == 15, "miejsca na umiejętności zablokowane")
	var g := horde.spawn_at(hero.position + Vector2(200, 0))
	await process_frame
	g.take_damage(10000, hero.global_position)
	await process_frame
	_check(game.hero_xp == HeroLevels.goblin_xp(1) and arena.run_xp == game.hero_xp, "goblin daje doświadczenie (%d)" % game.hero_xp)
	_check(is_equal_approx(arena.xp_bar.value, game.hero_xp), "pasek doświadczenia rośnie")
	_check(arena.xp_text.text == "%d / %d" % [game.hero_xp, game.xp_needed()], "liczby na pasku doświadczenia (%s)" % arena.xp_text.text)
	_check(arena.health_text.text == "100 / 100" and arena.mana_text.text == "50 / 50", "liczby na paskach zdrowia i many")
	var mana_rect: Rect2 = arena.mana_bar.get_global_rect()
	_check(mana_rect.position.y > hp_bar.position.y and mana_rect.position.y < xp_rect.position.y, "pasek many między zdrowiem a doświadczeniem")
	# awans w lochu: pełne zdrowie, więcej zdrowia, efekt
	hero.take_damage(40)
	game.add_xp(game.xp_needed() - game.hero_xp)
	await process_frame
	_check(game.hero_level == 2 and hero.max_hp == HeroLevels.max_hp(2) and hero.hp == hero.max_hp, "awans leczy do pełna i dodaje zdrowia (%d)" % hero.max_hp)
	_check(arena.health_text.text == "110 / 110" and arena.mana_text.text == "55 / 55", "po awansie więcej zdrowia i many na paskach")
	_check(arena.health_bar.max_value == hero.max_hp and arena.hero_level_label.text == "Poz. 2", "pasek zdrowia i numer poziomu po awansie")
	_check(is_equal_approx(arena.weapon.damage_mult, HeroLevels.damage_mult(2)), "miecz bije mocniej")
	var effect := false
	for c in hero.get_children():
		effect = effect or (c is Label and c.text == "Poziom 2!")
	_check(effect, "napis awansu nad postacią")
	# skróty deweloperskie: +1 poziom odblokowuje miejsce na 3. poziomie, +100 żaru do paska wyprawy
	arena._open_menu()
	var menu: PauseMenu = arena.pause_menu
	_check(menu.level_button.get_global_rect().size.y >= 44.0, "skróty deweloperskie w pauzie, 44 px")
	menu.level_button.pressed.emit()
	_check(game.hero_level == 3 and arena.actions.skills[0].locked_level == 0 and arena.actions.skills[1].locked_level == 6, "+1 poziom - odblokowane miejsce")
	# okno „Postać”: statystyki obecnego poziomu i przyrost z następnym
	menu.stats_button.pressed.emit()
	var stats: HeroStats = menu.stats
	_check(stats.visible and stats._title.text == "Poziom 3", "okno „Postać” z poziomem")
	_check(stats.rows["hp"][0].text == str(HeroLevels.max_hp(3)) and stats.rows["hp"][1].text == "+10", "zdrowie i przyrost z awansem")
	var dmg := HeroStats.damage_range(3)
	_check(stats.rows["damage"][0].text == "%d-%d" % [dmg.x, dmg.y] and dmg.x > ProtoWeapon.DAMAGE.x, "obrażenia miecza rosną (%s)" % stats.rows["damage"][0].text)
	_check(stats.rows["slots"][0].text == "1 / 4" and stats.rows["slots"][1].text == "na poz. 6", "miejsca na umiejętności i następne")
	_check(stats.back_button.get_global_rect().size.y >= 44.0, "przycisk „Wróć” 44 px")
	menu.back()
	_check(not stats.visible and menu.visible, "„wstecz” zamyka okno „Postać”, pauza zostaje")
	var before: int = horde.embers
	menu.embers_button.pressed.emit()
	_check(horde.embers == before + PauseMenu.DEV_EMBERS, "+100 żaru do paska wyprawy")
	menu.close()
	# Wódz daje dużo doświadczenia; okno zwycięstwa je pokazuje
	arena.summon_chief()
	await process_frame
	var xp_before: int = arena.run_xp
	await _wait(ProtoChief.ENTER_TIME + 0.1)
	arena.chief.take_damage(100000, hero.global_position)
	await process_frame
	_check(arena.run_xp == xp_before + HeroLevels.chief_xp(1), "Wódz daje doświadczenie (+%d)" % HeroLevels.chief_xp(1))
	arena.victory()
	_check(arena.result.visible and "Doświadczenie: +%d" % arena.run_xp in arena.result._summary.text and "Awans na poziom" in arena.result._summary.text, "okno zwycięstwa: doświadczenie i awans")
	paused = false
	arena.queue_free()
	await process_frame
	_check(game.hero_level >= 3, "poziom zostaje po wyprawie")


func _test_base(game: Node) -> void:
	game.reset_hero()
	game.auto_attack = true
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	_check(arena.xp_bar != null and arena.hero_level_label.text == "Poz. 1", "baza: poziom postaci obok „Menu”")
	var dummy: ProtoDummy = null
	for n in arena.get_node("World").get_children():
		if n is ProtoDummy:
			dummy = n
	hero.position = Vector2(0, 300)  # daleko od kukieł
	await _wait(1.0)
	_check(arena.weapon._state == "follow" and dummy._hits.size() == 0, "auto atak bez celu nie tnie")
	hero.position = dummy.position + Vector2(-30, 0)
	await _wait(1.0)
	_check(dummy._hits.size() > 0 and not arena.weapon.attack_held, "auto atak sam tnie kukłę w zasięgu (%d)" % dummy._hits.size())
	game.auto_attack = false
	arena._apply_settings()
	await _wait(0.9)
	var hits: int = dummy._hits.size()
	await _wait(1.0)
	_check(dummy._hits.size() == hits, "bez auto ataku miecz czeka na przycisk")
	var embers: int = game.embers
	arena._on_dev_embers(100)
	_check(game.embers == embers + 100 and arena.watra.embers == game.embers, "baza: +100 żaru do Watry")
	arena.queue_free()
	await process_frame

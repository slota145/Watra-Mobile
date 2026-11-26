extends SceneTree
## Test kamieni „rzuć, gdy…” (Odwet, Przebłysk, Stypa - Gems.TRIGGERS, decyzje autora 26.11.2026): dane (pasują tylko
## do umiejętności natychmiastowych, opis, przerwa z poziomu, łup dopiero od lochu 10), wkładanie (zwykły cios - odmowa),
## widmowe kopie broni w ręku i zapasowej (powstają i znikają z kamieniami), rzut przy trafieniu krytycznym, zabiciu
## i po zebraniu obrażeń (bez many, bez odnowienia umiejętności w ręku, słabszy, przerwa kamienia) i walka w lochu.

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
	_test_data()
	_test_socket(game)
	await _test_arena(game)
	await _test_horde(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	var g1 := Gems.make("cast_crit", 1)
	var g10 := Gems.make("cast_crit", 10)
	_check(Gems.is_trigger(g1) and not Gems.is_trigger(Gems.make("echo")), "Przebłysk to kamień „rzuć, gdy…”, Echo nie")
	_check(is_equal_approx(Gems.trigger_gap(g1), 1.5) and is_equal_approx(Gems.trigger_gap(g10), 0.5)
			and Gems.support_value(g1) == 50.0 and Gems.support_value(g10) == 80.0, "poziom 1: 50%, 1,5 s; poziom 10: 80%, 0,5 s")
	_check(Gems.fits(g1, "throw") and not Gems.fits(g1, "strike") and not Gems.fits(g1, "k_flash")
			and not Gems.fits(g1, "whirl") and not Gems.fits(g1, "s_mara") and not Gems.fits(g1, "b_ballista"),
			"pasuje do Rzutu mieczem, nie do zwykłego ciosu, skoku, Młynka, formy i przywołania")
	_check(Gems.support_text(Gems.make("cast_hurt"), "throw").contains("15%"), "opis Odwetu: próg 15% zdrowia")
	_check(Gems.support_text(g1, "strike").begins_with("Nie działa"), "opis w złej umiejętności: nie działa")
	var low := false
	var high := false
	for i in 3000:
		if Gems.is_trigger(Gems.roll(9)):
			low = true
		if Gems.is_trigger(Gems.roll(10)):
			high = true
	_check(not low and high, "z łupu dopiero od lochu %d" % Gems.TRIGGER_MIN_LEVEL)
	_check(Gems.icon_of(g1) != null and Gems.icon_of(Gems.make("cast_hurt")) != null
			and Gems.icon_of(Gems.make("cast_kill")) != null, "ikony trzech kamieni")


func _test_socket(game: Node) -> void:
	game.hero_level = 20
	game.dev_skills()
	game.add_gem(Gems.make("cast_crit"), 1, false)
	game.add_gem(Gems.make("cast_hurt"), 1, false)
	_check(game.skill_socket_problem("strike", 0, Gems.make("cast_crit")) == "trigger", "w zwykłym ciosie - odmowa")
	_check(game.socket_skill("throw", 0, Gems.make("cast_crit")) and game.socket_skill("throw", 1, Gems.make("cast_hurt")),
			"Przebłysk i Odwet w Rzucie mieczem")


func _test_arena(game: Node) -> void:
	game.best_level = 12
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	_check(arena.ghosts.has("sword") and arena.ghosts.size() == 1, "widmowa kopia miecza (ma kamienie)")
	var ghost: ProtoWeapon = arena.ghosts["sword"]
	_check(ghost.ghost and ghost.modulate.a < 0.05, "kopia niewidoczna, dopóki nic nie robi")
	await create_timer(0.5).timeout
	var mana := hero.mana
	arena._fire_trigger("crit")
	await process_frame
	var gap_now: float = ghost.cooldown_left("throw")
	var seen := false
	for i in 20:
		await process_frame
		seen = seen or ghost.modulate.a > 0.2
	_check(seen, "w trakcie rzutu kopię widać")
	_check(hero.mana == mana and arena.weapon.cooldown_left("throw") == 0.0,
			"krytyk: kopia rzuca miecz bez many i bez odnowienia Rzutu w ręku")
	_check(is_equal_approx(ghost.trigger_mult, 0.5) and absf(gap_now - 1.5) < 0.05,
			"rzut słabszy (50%), przerwa kamienia 1,5 s")
	var used := [0]
	ghost.skill_used.connect(func(_id: String) -> void: used[0] += 1)
	arena._fire_trigger("crit")
	await process_frame
	_check(used[0] == 0, "w przerwie kamień nie rzuca")
	await create_timer(1.0).timeout
	ghost.reset_cooldowns()
	var part := ceili(hero.max_hp * Gems.TRIGGER_HURT / 2.0) - 1
	arena._on_hurt_trigger(part)
	await create_timer(1.5).timeout
	ghost.reset_cooldowns()
	_check(used[0] == 0, "Odwet czeka, aż zbierze %d%% zdrowia" % roundi(Gems.TRIGGER_HURT * 100.0))
	arena._on_hurt_trigger(part + 3)
	await process_frame
	_check(used[0] == 1, "Odwet po zebraniu obrażeń")
	# broń zapasowa: jej umiejętności też rzucają kamienie
	game.mastery["glaive"] = 10
	game.set_spare("glaive")
	game.add_gem(Gems.make("cast_kill", 10), 1, false)
	_check(game.socket_skill("g_sweep", 0, Gems.make("cast_kill", 10)), "Stypa w Ognistym zamachu glewii (zapasowej)")
	await process_frame
	_check(arena.ghosts.has("glaive") and arena.ghosts.has("sword"), "kopie miecza w ręku i glewii zapasowej")
	var g2: ProtoWeapon = arena.ghosts["glaive"]
	await create_timer(1.6).timeout
	arena._fire_trigger("kill")
	await process_frame
	_check(g2._state != "follow" and is_equal_approx(g2.trigger_mult, 0.8), "zabicie: glewia zapasowa rzuca zamach (80%)")
	game.unsocket_skill("throw", 0)
	game.unsocket_skill("throw", 1)
	await process_frame
	_check(not arena.ghosts.has("sword") and arena.ghosts.has("glaive"), "bez kamieni kopia miecza znika")
	arena.queue_free()
	await process_frame


func _test_horde(game: Node) -> void:
	game.socket_skill("throw", 0, Gems.make("cast_crit"))
	game.dev_immortal = true
	game.auto_attack = true
	game.dungeon_level = 1
	game.dev_stats = {"crit_pct": 60.0}
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var count := [0]
	for w: String in arena.ghosts:
		arena.ghosts[w].skill_used.connect(func(_id: String) -> void: count[0] += 1)
	await create_timer(15.0).timeout
	print("  xp %d, stan kopii: %s" % [arena.run_xp, str(arena.ghosts.keys())])
	_check(arena.ghosts.size() == 2, "w lochu dwie widmowe kopie")
	_check(count[0] >= 2, "w lochu kamienie same rzucają umiejętności (%d razy)" % count[0])
	game.dev_immortal = false
	game.auto_attack = false
	game.dev_stats = {}
	arena.queue_free()
	await process_frame

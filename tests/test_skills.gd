extends SceneTree
## Test umiejętności miecza: kupno za złoto (poziom, cena), miejsca (zamiana, Mgnienie nie pod „Atak”, zablokowane
## miejsca), zapis, działanie w walce (Młynek, Rzut mieczem, Rozłupanie Ziemi z ogłuszeniem, Mgnienie), mana
## i odnowienie, zwykły cios przy braku many pod dużym przyciskiem, auto atak z umiejętnością, przyciski walki
## (ikony, odnowienie, stuknięcie), kamień run w bazie i okno umiejętności (kupno, przypisywanie, przeciąganie,
## pola 44 px, „wstecz”), poziomy umiejętności (ulepszanie za złoto, limit z poziomu postaci, zapis, obrażenia,
## mana, odnowienie, obszar i nowe działania z 5. i 10. poziomu, przycisk „Ulepsz” w oknie).

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
	_test_game(game)
	await _test_levels(game)
	await _test_unique(game)
	await _test_combat(game)
	await _test_window(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_game(game: Node) -> void:
	_check(game.skills_owned == ["strike"] and game.skill_slots == ["strike", "", "", "", ""] and game.main_skill() == "strike",
			"na start tylko zwykły cios pod „Atak”")
	game.gold = 5000
	_check(not game.buy_skill("whirl"), "Młynka nie kupi się przed 3. poziomem")
	game.hero_level = 3
	_check(game.buy_skill("whirl") and game.gold == 4900 and game.skill_slots[1] == "whirl", "Młynek za 100 złota trafia w 1. miejsce")
	_check(not game.buy_skill("whirl"), "drugi raz się nie kupi")
	_check(not game.assign_skill("whirl", 2), "zablokowane miejsce nic nie przyjmuje")
	_check(game.assign_skill("whirl", 0) and game.skill_slots == ["whirl", "strike", "", "", ""] and game.main_skill() == "whirl",
			"Młynek pod „Atak”, zwykły cios zamienia się z nim miejscami")
	game.hero_level = 15
	game.gold = 0
	_check(not game.buy_skill("blink"), "bez złota nie kupi się")
	game.gold = 3000
	_check(game.buy_skill("blink") and game.gold == 1500 and game.skill_slots[2] == "blink", "Mgnienie za 1500 w wolne miejsce")
	_check(not game.assign_skill("blink", 0) and game.skill_slots[0] == "whirl", "Mgnienie nie może stać pod „Atak”")
	_check(game.assign_skill("whirl", 2) and game.skill_slots[0] == "" and game.skill_slots[2] == "whirl",
			"zamiana z Mgnieniem zostawia „Atak” pusty")
	_check(game.main_skill() == "strike", "pusty „Atak” to zwykły cios")
	game.load_game()
	_check(game.skills_owned == ["strike", "whirl", "blink"] and game.skill_slots == ["", "strike", "whirl", "", ""],
			"umiejętności i miejsca w zapisie")
	game.clear_skill_slot(1)
	_check(game.skill_slots[1] == "", "zdjęcie z miejsca")
	game.reset_hero()
	_check(game.skills_owned == ["strike"] and game.skill_slots == ["strike", "", "", "", ""], "postać od nowa zeruje umiejętności")


func _test_levels(game: Node) -> void:
	game.reset_hero()
	_check(game.skill_level("strike") == 1 and game.skill_upgrade_problem("whirl") == "owned", "na start 1. poziom, niekupionej się nie ulepszy")
	_check(game.skill_upgrade_problem("strike") == "hero" and Skills.level_cap(1) == 1 and Skills.level_cap(4) == 2
			and Skills.level_cap(19) == 10 and Skills.level_cap(50) == 10, "limit: połowa poziomu postaci w górę, najwyżej 10")
	game.hero_level = 3
	game.gold = 39
	_check(game.skill_upgrade_problem("strike") == "gold", "bez złota się nie ulepszy")
	game.gold = 1000
	_check(game.upgrade_skill("strike") and game.skill_level("strike") == 2 and game.gold == 960, "zwykły cios na 2. poziom za 40 zł")
	_check(game.skill_upgrade_problem("strike") == "hero" and not game.upgrade_skill("strike"), "3. poziom dopiero od 5. poziomu postaci")
	_check(Skills.upgrade_price("strike", 2) == 80 and Skills.upgrade_price("blink", 9) == 1800 and Skills.upgrade_price("blink", 10) == 0,
			"cena rośnie z poziomem, na 10. koniec")
	game.load_game()
	_check(game.skill_level("strike") == 2, "poziom w zapisie")
	game.hero_level = 20
	game.gold = 100000
	while game.upgrade_skill("strike"):
		pass
	_check(game.skill_level("strike") == 10 and game.skill_upgrade_problem("strike") == "max", "najwyżej 10. poziom")
	_check(is_equal_approx(Skills.level_damage(10), 1.9) and is_equal_approx(Skills.level_cost(7), 0.8)
			and is_equal_approx(Skills.level_cost(6), 0.9) and is_equal_approx(Skills.level_area(8), 1.2)
			and Skills.perks_at(4) == 0 and Skills.perks_at(5) == 1 and Skills.perks_at(10) == 2, "premie poziomów")
	_check(Skills.next_level_text("whirl", 4).contains(tr("nowe działanie")) and Skills.next_level_text("whirl", 10) == "",
			"opis następnego poziomu")
	game.reset_hero()
	_check(game.skill_levels.is_empty(), "postać od nowa zeruje poziomy")
	# w walce: mana, odnowienie, obrażenia i nowe działania
	game.hero_level = 20
	game.dev_skills()
	for id in Skills.ORDER:
		game.skill_levels[id] = 10
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	_check(weapon.level_of("whirl") == 10 and weapon.mana_cost("whirl") == 20 and is_equal_approx(weapon.cooldown_full("whirl"), 6.4)
			and is_equal_approx(weapon._area("slam"), 1.2), "miecz zna poziomy: mniej many, krótsze odnowienie, większy obszar")
	var dummy: ProtoDummy = weapon.targets[0]
	# Młynek 10. poziomu: 4 s i wybuch odpychający goblina na koniec
	var goblin := ProtoGoblin.new()
	goblin.hero = hero
	goblin.bounds = Rect2(-400, -600, 800, 1200)
	goblin.power = 50.0
	hero.position = dummy.position + Vector2(0, 160)
	goblin.position = hero.position + Vector2(30, 0)
	arena.get_node("World").add_child(goblin)
	await _wait(0.1)
	hero.mana = hero.max_mana
	_check(weapon.cast("whirl"), "Młynek 10. poziomu rusza")
	await _wait(3.4)
	_check(weapon._state == "whirl", "Młynek 5. poziomu wiruje dłużej niż 3 s")
	await _wait(0.8)
	_check(weapon._state != "whirl" and goblin._push.length() > ProtoGoblin.KNOCKBACK, "na koniec wybuch odpycha goblina")
	# Rozłupanie: dłuższe ogłuszenie i druga fala
	await _wait(0.4)
	goblin.position = hero.position + Vector2(30, 0)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	_check(weapon.cast("slam"), "Rozłupanie 10. poziomu rusza")
	await _wait(0.45)
	var hp := goblin.hp
	_check(goblin._stunned > 1.2, "5. poziom: dłuższe ogłuszenie (%.1f s)" % goblin._stunned)
	await _wait(0.6)
	_check(goblin.hp < hp, "10. poziom: druga fala pęknięć rani po chwili")
	goblin.queue_free()
	# Rzut 10. poziomu: drugi miecz, odbicie i powrót; zwykły cios: co trzeci podwójny
	await _wait(0.6)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(0, 90)
	await _wait(0.4)
	_check(weapon.cast("throw") and weapon._ghosts[0].visible, "Rzut 10. poziomu: drugi miecz leci obok")
	await _wait(2.0)
	_check(weapon._state == "follow", "Rzut z odbiciem wraca do postaci")
	hero.position = dummy.position + Vector2(0, 20)
	var swings := weapon._strike_count
	weapon.attack_held = true
	await _wait(2.5)
	weapon.attack_held = false
	_check(weapon._strike_count - swings >= 3, "zwykły cios tnie dalej z poziomem (%d)" % (weapon._strike_count - swings))
	# Mgnienie 10. poziomu: każdy skok za manę, co 5. skok wir; zabicie skokiem zwraca 2x więcej many (5. poziom)
	await _wait(0.6)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(-60, 0)
	await _wait(0.8)
	var mana := hero.mana
	_check(weapon.cast("blink"), "Mgnienie 10. poziomu rusza")
	_check(hero.mana == mana - weapon.mana_cost("blink"), "każdy skok kosztuje manę")
	await _wait(0.1)
	weapon.flicker_held = true
	await _wait(2.0)
	weapon.flicker_held = false
	_check(weapon._blink_jumps >= Skills.BLINK_SPIN_EVERY and weapon._blink_spins == weapon._blink_jumps / Skills.BLINK_SPIN_EVERY,
			"10. poziom: wir co 5. skok (%d skoków, %d wirów)" % [weapon._blink_jumps, weapon._blink_spins])
	var victim := ProtoGoblin.new()
	victim.hero = hero
	victim.bounds = Rect2(-400, -600, 800, 1200)
	victim.position = hero.position + Vector2(50, 0)
	arena.get_node("World").add_child(victim)
	await _wait(0.4)
	victim.hp = 1
	hero.mana = 30
	weapon.crit_chance = 0.0
	weapon._flicker_jump(victim)
	_check(not victim.alive() and hero.mana == 30 + Skills.BLINK_MANA_ON_KILL * 2,
			"5. poziom: zabicie skokiem zwraca %d many" % (hero.mana - 30))
	arena.queue_free()
	await process_frame
	game.reset_hero()


## Kamienie unikalne w walce: fala cięcia, Młynek bez odnowienia, odbicia Rzutu, fale z Rozłupania, Mgnienie bez limitu.
func _test_unique(game: Node) -> void:
	game.reset_hero()
	game.hero_level = 20
	game.dev_skills()
	for id in Skills.ORDER:
		game.add_gem(Gems.unique_of(id), 1, false)
		game.socket_skill(id, 0, Gems.unique_of(id))
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	var dummy: ProtoDummy = weapon.targets[0]
	_check(weapon._unique("whirl") and not weapon._unique("x") and weapon.cooldown_full("whirl") == 0.0
			and weapon.mana_cost("blink") == roundi(Skills.mana_of("blink") * 0.5) and weapon.cooldown_full("throw") > 0.0,
			"miecz widzi kamienie unikalne (Mgnienie za pół many: %d)" % weapon.mana_cost("blink"))
	# fala cięcia: kukła 90 px dalej, poza zasięgiem ciosu
	hero.position = dummy.position + Vector2(-90, 0)
	hero.facing = Vector2.RIGHT
	await _wait(0.3)
	var hits := dummy._count
	weapon._attack()
	await _wait(0.3)
	_check(not weapon._waves.is_empty(), "cięcie wypuszcza falę")
	await _wait(0.5)
	_check(dummy._count > hits and weapon._waves.is_empty(), "fala trafia kukłę 90 px dalej i znika")
	# Młynek bez odnowienia: wiruje dłużej niż 4 s, wyłącza go drugie stuknięcie
	hero.position = dummy.position + Vector2(0, 20)
	hero.mana = hero.max_mana
	await _wait(0.4)
	_check(weapon.cast("whirl"), "Młynek z kamieniem rusza")
	await _wait(4.5)
	_check(weapon._state == "whirl" and hero.mana < hero.max_mana, "wiruje dłużej niż 4 s i zużywa manę")
	_check(weapon.cast("whirl") and weapon._state != "whirl", "drugie stuknięcie wyłącza Młynek")
	hero.mana = 30
	weapon.cast("whirl")
	await _wait(5.0)
	_check(weapon._state != "whirl", "bez many Młynek się kończy")
	# Rzut: odbicia między goblinami
	var goblins: Array = []
	for i in 3:
		var g := ProtoGoblin.new()
		g.hero = hero
		g.bounds = Rect2(-400, -600, 800, 1200)
		g.power = 50.0
		g.position = hero.position + Vector2(-150 + 60 * i, -140 + 50 * (i % 2))
		arena.get_node("World").add_child(g)
		goblins.append(g)
	hero.position += Vector2(0, 0)
	await _wait(0.2)
	for g in goblins:
		g._stunned = 10.0
	hero.mana = hero.max_mana
	weapon.reset_cooldowns()
	hero.position = goblins[0].position + Vector2(0, 60)
	await _wait(0.1)
	var full: int = goblins[2].hp
	_check(weapon.cast("throw"), "Rzut z kamieniem rusza")
	await _wait(1.5)
	_check(weapon._bounces_left < ProtoWeapon.THROW_GEM_BOUNCES and goblins[2].hp < full,
			"miecz odbija się od trafionego w kolejnych (%d odbić)" % (ProtoWeapon.THROW_GEM_BOUNCES - weapon._bounces_left))
	# Rozłupanie: fale z trafionych ranią sąsiadów poza falą główną
	await _wait(1.5)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	var g0: ProtoGoblin = goblins[0]
	var g1: ProtoGoblin = goblins[1]
	g0.position = hero.position + Vector2(30, 0)
	g1.position = g0.position + Vector2(25, 0)
	await _wait(0.05)
	var far_hp := g1.hp
	weapon._slam_hit(g0.position - Vector2(30, 0))  # g1 55 px od uderzenia (poza falą), 25 px od g0
	await _wait(0.3)
	_check(g1.hp < far_hp, "fala z trafionego rani goblina poza zasięgiem uderzenia")
	for g in goblins:
		g.queue_free()
	arena.queue_free()
	await process_frame
	game.reset_hero()


## Suma trafień we wszystkie kukły w bazie.
func _dummy_hits(weapon: ProtoWeapon) -> int:
	var n := 0
	for t in weapon.targets:
		if t is ProtoDummy:
			n += t._count
	return n


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.dev_skills()
	_check(game.skills_owned.size() == Skills.ORDER.size(), "skrót deweloperski daje wszystkie umiejętności")
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	var actions: ActionCluster = arena.actions
	_check(actions.skills[0].icon == Skills.icon_of(game.skill_slots[1]) and actions.attack.icon == Skills.icon_of("strike"),
			"przyciski walki pokazują ikony umiejętności z miejsc")
	var dummy: ProtoDummy = weapon.targets[0]
	# Młynek: mana, odnowienie, trafienia wokół
	hero.position = dummy.position + Vector2(0, 20)
	await _wait(0.6)
	var mana := hero.mana
	var total := dummy._total
	_check(weapon.cast("whirl"), "Młynek rusza")
	_check(hero.mana == mana - 25 and weapon.cooldown_left("whirl") > 7.0, "Młynek zjada 25 many i odnawia się 8 s")
	await _wait(1.0)
	_check(dummy._count >= 3 and dummy._total > total, "Młynek rani kukłę kilka razy (%d)" % dummy._count)
	_check(not weapon.cast("whirl"), "w czasie odnowienia się nie da")
	await _wait(0.1)
	var slot: int = game.skill_slots.find("whirl")
	_check(actions.button(slot).cooldown_left > 5.0 and actions.button(slot).cooldown_total == 8.0, "przycisk pokazuje odnowienie")
	await _wait(2.5)
	_check(weapon._state == "follow", "po 3 s Młynek się kończy")
	# Rzut mieczem: leci w kukłę z daleka, wraca
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(0, 90)
	await _wait(0.4)
	total = dummy._count
	_check(weapon.cast("throw"), "Rzut mieczem rusza")
	await _wait(0.4)
	_check(dummy._count > total, "miecz trafia kukłę 90 px dalej")
	await _wait(1.0)
	_check(weapon._state == "follow" and dummy._count >= total + 2, "miecz wraca i trafia drugi raz (%d)" % (dummy._count - total))
	# Rozłupanie Ziemi: ogłusza goblina
	var goblin := ProtoGoblin.new()
	goblin.hero = hero
	goblin.bounds = Rect2(-400, -600, 800, 1200)
	goblin.power = 50.0
	goblin.position = hero.position + Vector2(30, 0)
	arena.get_node("World").add_child(goblin)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	_check(weapon.cast("slam"), "Rozłupanie Ziemi rusza")
	await _wait(0.45)
	_check(goblin._stunned > 0.5 and goblin.hp < goblin.MAX_HP * 50, "fala rani i ogłusza goblina")
	var at := goblin.position
	await _wait(0.4)
	_check(goblin.position.distance_to(at) < 3.0, "ogłuszony goblin stoi")
	goblin.queue_free()
	# Mgnienie jak w Watrze: skok na wylot przez najbliższego wroga, przy trzymaniu kolejne skoki za manę
	await _wait(0.4)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(-200, 0)
	await _wait(0.1)
	_check(not weapon.cast("blink"), "Mgnienie bez wroga w zasięgu się nie uda")
	hero.position = dummy.position + Vector2(-60, 0)
	await _wait(0.1)
	total = dummy._count
	mana = hero.mana
	_check(weapon.cast("blink"), "Mgnienie rusza")
	_check(hero.position.x > dummy.position.x + 10.0 and absf(hero.position.y - dummy.position.y) < 2.0,
			"postać ląduje za kukłą, na wylot")
	_check(dummy._count == total + 1 and hero.mana == mana - 7, "skok tnie kukłę i kosztuje 7 many")
	await _wait(0.5)
	_check(dummy._count == total + 1, "samo stuknięcie - jeden skok")
	var jumps := weapon._blink_jumps
	weapon.flicker_held = true
	await _wait(1.8)
	weapon.flicker_held = false
	_check(weapon._blink_jumps - jumps > 3 and weapon.cooldown_left("blink") == 0.0 and weapon.cooldown_full("blink") == 0.0,
			"trzymanie - skoki bez limitu i bez odnowienia (%d)" % (weapon._blink_jumps - jumps))
	_check(weapon._blink_spins == 0, "bez 10. poziomu nie ma wiru")
	await _wait(0.4)
	_check(weapon.cast("blink"), "zaraz po serii znów skacze")
	var hp0 := hero.hp
	hero._invulnerable = 0.0
	weapon._flicker_jump(dummy)
	hero.take_damage(5)
	_check(hero.hp < hp0, "skok nie daje nietykalności")
	await _wait(0.5)
	var after := dummy._count
	weapon.flicker_held = true
	hero.mana = 3
	await _wait(0.4)
	weapon.flicker_held = false
	_check(dummy._count == after and hero.mana >= 3, "bez many nie skacze")
	# brak many
	await _wait(0.3)
	weapon.reset_cooldowns()
	hero.mana = 5
	_check(not weapon.cast("throw"), "bez many się nie da")
	# duży przycisk: umiejętność z auto atakiem, bez many - zwykły cios
	game.assign_skill("whirl", 0)
	_check(weapon.main_skill == "whirl" and actions.attack.icon == Skills.icon_of("whirl"), "Młynek pod dużym przyciskiem")
	hero.position = dummy.position + Vector2(0, 20)
	weapon.auto_attack = true
	hero.mana = 0
	await _wait(0.8)
	_check(weapon._state != "whirl" and dummy._count > total + 1, "bez many auto atak tnie zwykłym ciosem")
	hero.mana = hero.max_mana
	await _wait(0.8)
	_check(weapon._state == "whirl" or weapon.cooldown_left("whirl") > 0.0, "z maną auto atak sam rusza Młynek")
	weapon.auto_attack = false
	# stuknięcie małego przycisku
	await _wait(3.0)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	var throw_slot: int = game.skill_slots.find("throw")
	if throw_slot > 0:
		actions.button(throw_slot).pressed.emit()
		_check(weapon.cooldown_left("throw") > 0.0, "stuknięcie małego przycisku używa umiejętności")
	else:
		_check(false, "Rzut mieczem stoi w małym miejscu")
	# kamień run otwiera okno z kupnem
	_check(arena.rune_stone != null and not arena.skills_window.visible, "kamień run stoi w bazie")
	hero.position = arena.rune_stone.position + Vector2(0, 18)
	await _wait(0.3)
	_check(arena.skills_window.visible and arena.skills_window.can_shop and paused, "podejście do kamienia otwiera okno z kupnem")
	arena.skills_window.close()
	_check(not paused, "zamknięcie wznawia grę")
	arena.queue_free()
	await process_frame
	game.reset_hero()


func _test_window(game: Node) -> void:
	game.hero_level = 6
	game.gold = 1000
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.open_skills()
	await process_frame
	var win: SkillsWindow = arena.skills_window
	var small := false
	for b in win.slots + win.list_icons + [win.back_button, win.clear_button]:
		var r: Rect2 = b.get_global_rect()
		small = small or r.size.x < 44.0 or r.size.y < 44.0
	for b in win.buy_buttons:
		small = small or (b.visible and b.get_global_rect().size.y < 44.0)
	_check(not small, "pola i przyciski co najmniej 44 px")
	var view := win.get_viewport_rect()
	_check(view.encloses(win.back_button.get_global_rect()) and win.slots[0].get_global_rect().position.y > view.size.y / 2.0,
			"okno mieści się na ekranie, miejsca w dolnej połowie")
	_check(win.slots[0].locked_level == 0 and win.slots[2].locked_level == 0 and win.slots[3].locked_level == 10,
			"na 6. poziomie 2 małe miejsca, 3. od poz. 10")
	var whirl_i := Skills.ORDER.find("whirl")
	var slam_i := Skills.ORDER.find("slam")
	_check(win.buy_buttons[slam_i].disabled and win.buy_buttons[slam_i].visible, "Rozłupanie Ziemi (poz. 10) - kupno nieaktywne")
	win.buy_buttons[whirl_i].pressed.emit()
	_check(not game.skills_owned.has("whirl") and win.buy_buttons[whirl_i].text == tr("Na pewno?"), "kupno pyta „Na pewno?”")
	win.buy_buttons[whirl_i].pressed.emit()
	_check(game.skills_owned.has("whirl") and game.gold == 900 and win.buy_buttons[whirl_i].text == tr("Ulepsz"), "Młynek kupiony - przycisk „Ulepsz”")
	win.buy_buttons[whirl_i].pressed.emit()
	win.buy_buttons[whirl_i].pressed.emit()
	_check(game.skill_level("whirl") == 2 and game.gold == 840 and win.name_labels[whirl_i].text.contains("2/10"),
			"„Ulepsz” (dwa stuknięcia) - Młynek na 2. poziomie za 60 zł")
	_check(win.buy_buttons[whirl_i].visible and not win.buy_buttons[whirl_i].disabled, "na 6. poziomie postaci można dalej (do 3.)")
	# stuknij umiejętność, potem miejsce
	win.list_icons[whirl_i].pressed.emit()
	win.slots[0].pressed.emit()
	_check(game.skill_slots[0] == "whirl" and arena.weapon.main_skill == "whirl", "stuknięcie: Młynek pod „Atak”")
	# przeciąganie z listy na miejsce i z miejsca na listę
	var data = win.list_icons[0]._get_drag_data(Vector2.ZERO)
	_check(win.slots[2]._can_drop_data(Vector2.ZERO, data) and not win.slots[3]._can_drop_data(Vector2.ZERO, data),
			"przeciąganie tylko na odblokowane miejsce")
	win.slots[2]._drop_data(Vector2.ZERO, data)
	_check(game.skill_slots[2] == "strike", "przeciągnięty zwykły cios w 2. miejscu")
	_check(win.list_icons[Skills.ORDER.find("throw")]._get_drag_data(Vector2.ZERO) == null, "niekupionej nie da się przeciągnąć")
	var back = win.slots[2]._get_drag_data(Vector2.ZERO)
	win.list_icons[0]._drop_data(Vector2.ZERO, back)
	_check(game.skill_slots[2] == "", "przeciągnięcie na listę zdejmuje z miejsca")
	# wybór miejsca i „Zdejmij”
	win.slots[0].pressed.emit()
	_check(win.selected_slot == 0 and not win.clear_button.disabled, "stuknięcie zajętego miejsca je wybiera")
	win.clear_button.pressed.emit()
	_check(game.skill_slots[0] == "" and arena.weapon.main_skill == "strike", "„Zdejmij” - pod „Atak” znów zwykły cios")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not win.visible and not paused, "„wstecz” zamyka okno")
	arena.queue_free()
	await process_frame
	# w lochu: ikonka w górnym rzędzie, bez kupowania
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	_check(arena.skills_icon.get_global_rect().size.y >= 44.0, "ikonka umiejętności w górnym rzędzie lochu, 44 px")
	arena.skills_icon.pressed.emit()
	var pwin: SkillsWindow = arena.skills_window
	_check(pwin.visible and paused and not pwin.can_shop and not pwin.buy_buttons[slam_i].visible,
			"w lochu okno z ikonki bez kupowania, gra stoi")
	pwin.close()
	_check(not paused, "zamknięcie wznawia grę")
	arena.queue_free()
	await process_frame

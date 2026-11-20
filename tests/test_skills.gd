extends SceneTree
## Test umiejętności miecza: odblokowanie mistrzostwem broni (progi, wolne miejsca, napis), przejście starego zapisu
## (zwrot złota i żaru), miejsca (zamiana, Mgnienie nie pod „Atak”, zablokowane
## miejsca), zapis, działanie w walce (Młynek, Rzut mieczem, Rozłupanie Ziemi z ogłuszeniem, Mgnienie), mana
## i odnowienie, zwykły cios przy braku many pod dużym przyciskiem, auto atak z umiejętnością, przyciski walki
## (ikony, odnowienie, stuknięcie), kamień run w bazie i okno umiejętności (mistrzostwo, przypisywanie, przeciąganie,
## pola 44 px, „wstecz”), poziomy umiejętności (ulepszanie za żar, limit z mistrzostwa, zapis, obrażenia,
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
	_test_migration(game)
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
	_check(game.mastery_level() == 1 and game.weapon == "sword" and Skills.unlocked_at("sword", 1) == ["strike"],
			"na start mistrzostwo miecza 1")
	var unlocked: Array = []
	game.skill_unlocked.connect(func(id: String) -> void: unlocked.append(id))
	game.hero_level = 3
	var need: int = Weapons.xp_to_next(1) + Weapons.xp_to_next(2)
	_check(game.add_mastery(need - 1) == 1 and game.mastery_level() == 2 and not game.skills_owned.has("whirl"),
			"mistrzostwo 2 - Młynka jeszcze nie ma")
	_check(game.add_mastery(1) == 1 and game.mastery_level() == 3 and game.skills_owned.has("whirl")
			and game.skill_slots[1] == "whirl" and unlocked == ["whirl"], "mistrzostwo 3 odblokowuje Młynek w 1. miejscu (napis)")
	_check(game.gold == 0, "odblokowanie nic nie kosztuje")
	_check(not game.assign_skill("whirl", 2), "zablokowane miejsce nic nie przyjmuje")
	_check(game.assign_skill("whirl", 0) and game.skill_slots == ["whirl", "strike", "", "", ""] and game.main_skill() == "whirl",
			"Młynek pod „Atak”, zwykły cios zamienia się z nim miejscami")
	game.hero_level = 15
	game.mastery["sword"] = 14
	game.mastery_xp["sword"] = 0
	game.add_mastery(Weapons.xp_to_next(14))
	_check(unlocked == ["whirl", "throw", "slam", "steel_ring"] and game.skill_slots == ["whirl", "strike", "throw", "slam", "steel_ring"],
			"skok na mistrzostwo 15: reszta umiejętności w wolnych miejscach")
	game.skill_slots = ["whirl", "strike", "steel_ring", "", ""]
	game.skills_owned = ["strike", "whirl", "steel_ring"]
	game.mastery["sword"] = 2
	_check(not game.assign_skill("steel_ring", 0) and game.skill_slots[0] == "whirl", "Krąg stali nie może stać pod „Atak”")
	_check(game.assign_skill("whirl", 2) and game.skill_slots[0] == "" and game.skill_slots[2] == "whirl",
			"zamiana z Kręgiem stali zostawia „Atak” pusty")
	_check(game.main_skill() == "strike", "pusty „Atak” to zwykły cios")
	game.save_game()
	game.load_game()
	_check(game.skills_owned == ["strike", "whirl", "steel_ring"] and game.skill_slots == ["", "strike", "whirl", "", ""]
			and game.mastery_level() == 2, "umiejętności, miejsca i mistrzostwo w zapisie")
	game.clear_skill_slot(1)
	_check(game.skill_slots[1] == "", "zdjęcie z miejsca")
	game.reset_hero()
	_check(game.skills_owned == ["strike"] and game.skill_slots == ["strike", "", "", "", ""] and game.mastery_level() == 1,
			"postać od nowa zeruje umiejętności i mistrzostwo")


## Stary zapis (sprzed mistrzostwa): mistrzostwo = poziom postaci, kupione zostają, złoto wraca (też za dawne ulepszenia lochów).
func _test_migration(game: Node) -> void:
	var f := FileAccess.open(game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hero_level": 7, "gold": 10, "embers": 5, "skills_owned": ["strike", "whirl"],
			"skill_slots": ["strike", "whirl", "", "", ""], "skill_levels": {"strike": 3, "whirl": 2},
			"upgrades": {"xp": 2}}))
	f.close()
	game.load_game()
	# złoto: Młynek 100 + poziomy zwykłego ciosu 40 + 80 + Młynka 60 + dawne ulepszenie lochów 50 + 120 (zastąpiło je drzewko)
	_check(game.mastery_level() == 7 and game.gold == 10 + 100 + 40 + 80 + 60 + 50 + 120 and game.embers == 5,
			"stary zapis: mistrzostwo 7, zwrot złota (%d) i żaru (%d)" % [game.gold, game.embers])
	_check(game.skills_owned == ["strike", "whirl", "throw"] and game.skill_level("strike") == 3 and game.tree.is_empty()
			and game.skill_slots == ["strike", "whirl", "throw", "", ""],
			"kupione i poziomy zostają, Rzut mieczem (mistrz. 6) odblokowany")
	game.save_game()
	game.load_game()
	_check(game.gold == 460 and game.embers == 5, "zwrot tylko raz")
	game.reset_hero()


func _test_levels(game: Node) -> void:
	game.reset_hero()
	_check(game.skill_level("strike") == 1 and game.skill_upgrade_problem("whirl") == "owned", "na start 1. poziom, nieodblokowanej się nie ulepszy")
	_check(game.skill_upgrade_problem("strike") == "mastery" and Skills.level_cap(1) == 1 and Skills.level_cap(4) == 2
			and Skills.level_cap(19) == 10 and Skills.level_cap(50) == 10, "limit: połowa mistrzostwa w górę, najwyżej 10")
	game.hero_level = 20
	game.mastery["sword"] = 3
	game.embers = 39
	_check(game.skill_upgrade_problem("strike") == "embers", "bez żaru się nie ulepszy (poziom postaci nie pomaga)")
	game.embers = 1000
	game.gold = 0
	_check(game.upgrade_skill("strike") and game.skill_level("strike") == 2 and game.embers == 960, "zwykły cios na 2. poziom za 40 żaru")
	_check(game.skill_upgrade_problem("strike") == "mastery" and not game.upgrade_skill("strike"), "3. poziom dopiero od 5. mistrzostwa")
	_check(Skills.upgrade_price("strike", 2) == 80 and Skills.upgrade_price("steel_ring", 9) == 1800 and Skills.upgrade_price("steel_ring", 10) == 0,
			"cena rośnie z poziomem, na 10. koniec")
	game.load_game()
	_check(game.skill_level("strike") == 2, "poziom w zapisie")
	game.mastery["sword"] = 20
	game.embers = 100000
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
	_check(weapon.level_of("whirl") == 10 and weapon.mana_cost("whirl") == roundi(Skills.mana_of("whirl") * Skills.level_mana(10))
			and weapon.mana_cost("whirl") > Skills.mana_of("whirl") and weapon.cooldown_full("whirl") == 0.0
			and is_equal_approx(weapon.cooldown_full("throw"), 3.2) and is_equal_approx(weapon._area("slam"), 1.2),
			"miecz zna poziomy: więcej many (jak w PoE), krótsze odnowienie, większy obszar (Młynek bez odnowienia)")
	var dummy: ProtoDummy = weapon.targets[0]
	# Młynek 10. poziomu: wiruje, dopóki trzymany; wybuch co WHIRL_BLAST_EVERY s odpycha goblina
	var goblin := ProtoGoblin.new()
	goblin.hero = hero
	goblin.bounds = Rect2(-400, -600, 800, 1200)
	goblin.power = 50.0
	hero.position = dummy.position + Vector2(0, 160)
	goblin.position = hero.position + Vector2(30, 0)
	arena.get_node("World").add_child(goblin)
	await _wait(0.1)
	hero.mana = hero.max_mana
	weapon.whirl_held = true
	_check(weapon.cast("whirl"), "Młynek 10. poziomu rusza")
	await _wait(ProtoWeapon.WHIRL_BLAST_EVERY - 0.3)
	await _wait(0.4)
	_check(weapon._state == "whirl" and weapon.whirl_blasts == 1, "trzymany wiruje, po %.1f s wybuch" % ProtoWeapon.WHIRL_BLAST_EVERY)
	weapon._whirl_blast()
	_check(goblin._push.length() > ProtoGoblin.KNOCKBACK, "wybuch odpycha goblina")
	weapon.whirl_held = false
	await _wait(0.1)
	_check(weapon._state != "whirl", "puszczony przycisk kończy Młynek")
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
	# Krąg stali 10. poziomu: 5 widmowych mieczy przez 8 s (5. poziom), miecz w ręku tnie w tym czasie normalnie
	await _wait(0.6)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(0, 26)
	await _wait(0.3)
	var hits0 := dummy._count
	var swings0 := weapon._strike_count
	_check(weapon.cast("steel_ring") and weapon._ring.size() == ProtoWeapon.STEEL_SWORDS_PERK, "Krąg stali 10. poziomu: 5 mieczy")
	_check(weapon._state == "follow", "miecz w ręku zostaje wolny")
	weapon.attack_held = true
	await _wait(2.0)
	weapon.attack_held = false
	_check(weapon._strike_count - swings0 >= 2, "w trakcie kręgu miecz tnie normalnie (%d)" % (weapon._strike_count - swings0))
	_check(dummy._count - hits0 > weapon._strike_count - swings0, "widmowe miecze też tną kukłę")
	_check(weapon.ring_left() > ProtoWeapon.STEEL_TIME - 2.5, "5. poziom: krąg trwa 8 s")
	await _wait(ProtoWeapon.STEEL_TIME_LONG - 1.8)
	_check(weapon.ring_left() == 0.0 and weapon._ring.is_empty(), "krąg znika po czasie")
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
			and weapon.cooldown_full("throw") > 0.0, "miecz widzi kamienie unikalne")
	# Kamień Wiecznej Stali: krąg bez końca, płaci manę co sekundę, drugie stuknięcie albo brak many go wyłącza
	hero.mana = hero.max_mana
	_check(weapon.cooldown_full("steel_ring") == 0.0 and weapon.cast("steel_ring") and is_inf(weapon.ring_left()),
			"Krąg stali z kamieniem unikalnym: bez końca i bez odnowienia")
	_check(not weapon.can_use("steel_ring"), "krąży - auto atak nie rusza go od nowa (tnie zwykłym ciosem)")
	var ring_mana := hero.mana
	await _wait(1.6)
	_check(hero.mana < ring_mana and not weapon._ring.is_empty(), "krąg zużywa manę co sekundę (%d)" % (ring_mana - hero.mana))
	_check(weapon.cast("steel_ring") and weapon._ring.is_empty(), "drugie stuknięcie wyłącza krąg")
	weapon.cast("steel_ring")
	hero.mana = 0
	await _wait(1.0)
	_check(weapon._ring.is_empty(), "bez many krąg znika")
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
	# Kamień Wiecznego Wiru: wir rośnie z czasem (zasięg i obrażenia do +100%)
	hero.position = dummy.position + Vector2(0, 20)
	hero.mana = hero.max_mana
	await _wait(0.4)
	weapon.whirl_held = true
	_check(weapon.cast("whirl"), "Młynek z kamieniem rusza")
	var small_radius := weapon._whirl_radius()
	await _wait(ProtoWeapon.WHIRL_GROW_TIME + 0.3)
	_check(weapon._state == "whirl" and is_equal_approx(weapon._whirl_grow(), 1.0 + ProtoWeapon.WHIRL_GROW)
			and weapon._whirl_radius() > small_radius * 1.9, "wir urósł do x%.1f" % weapon._whirl_grow())
	weapon.whirl_held = false
	await _wait(0.1)
	weapon.whirl_held = true
	hero.mana = weapon.mana_cost("whirl") + 2  # starczy na start i chwilę wirowania
	weapon.cast("whirl")
	_check(is_equal_approx(weapon._whirl_grow(), 1.0), "nowe wirowanie zaczyna od małego wiru")
	await _wait(3.0)
	_check(weapon._state != "whirl", "bez many Młynek się kończy")
	weapon.whirl_held = false
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
	_check(game.skills_owned.size() == Skills.of_weapon("sword").size(), "skrót deweloperski daje wszystkie umiejętności broni")
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
	# Młynek: wiruje, dopóki palec trzyma mały przycisk (mana co sekundę, bez odnowienia), trafienia wokół
	hero.position = dummy.position + Vector2(0, 20)
	await _wait(0.6)
	var mana := hero.mana
	var total := dummy._total
	var slot: int = game.skill_slots.find("whirl")
	arena._on_skill_pressed(slot)
	await process_frame
	_check(weapon._state == "whirl" and weapon.whirl_held, "Młynek rusza, dopóki palec trzyma przycisk")
	_check(mana - hero.mana >= 10 and weapon.cooldown_left("whirl") == 0.0, "Młynek zjada 10 many na start, bez odnowienia")
	await _wait(1.0)
	_check(dummy._count >= 3 and dummy._total > total, "Młynek rani kukłę kilka razy (%d)" % dummy._count)
	_check(hero.mana < mana - 15, "co sekundę zużywa manę (%d -> %d)" % [mana, hero.mana])
	_check(weapon.cast("whirl") and weapon._state == "whirl", "drugie stuknięcie w trakcie nic nie psuje")
	await _wait(1.5)
	_check(weapon._state == "whirl", "trzymany wiruje dłużej niż 2 s")
	arena._on_skill_released()
	await _wait(0.1)
	_check(weapon._state == "follow", "puszczenie przycisku kończy Młynek")
	# Rzut mieczem: leci w kukłę z daleka, wraca
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(-90, 0)  # inne kukły poza zasięgiem - Rzut celuje w najdalszego (19.11.2026)
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
	total = dummy._count
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
	_check(weapon._state != "whirl" and dummy._count > total, "bez many auto atak tnie zwykłym ciosem")
	hero.mana = hero.max_mana
	await _wait(0.8)
	_check(weapon._state == "whirl", "z maną auto atak sam rusza Młynek i wiruje przy wrogach")
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
	game.mastery["sword"] = 5
	game.embers = 1000
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
	_check(not win.buy_buttons[slam_i].visible and win.status_labels[slam_i].text == tr("od mistrz. %d") % 10,
			"Rozłupanie Ziemi - bez kupna, próg mistrzostwa 10")
	_check(win.mastery_label.text.contains(Weapons.name_of("sword")) and win.embers_label.text == "1000", "mistrzostwo i żar w oknie")
	game.add_mastery(Weapons.xp_to_next(5))
	await process_frame
	_check(game.skills_owned.has("throw") and win.status_labels[Skills.ORDER.find("throw")].text.begins_with(tr("W miejscu %d") % 2),
			"mistrzostwo 6 przy otwartym oknie: Rzut mieczem odblokowany i w miejscu")
	win.buy_buttons[whirl_i].pressed.emit()
	_check(game.skill_level("whirl") == 1 and win.buy_buttons[whirl_i].text == tr("Na pewno?"), "„Ulepsz” pyta „Na pewno?”")
	win.buy_buttons[whirl_i].pressed.emit()
	_check(game.skill_level("whirl") == 2 and game.embers == 940 and win.name_labels[whirl_i].text.contains("2/10")
			and win.embers_label.text == "940", "„Ulepsz” (dwa stuknięcia) - Młynek na 2. poziomie za 60 żaru")
	_check(win.buy_buttons[whirl_i].visible and not win.buy_buttons[whirl_i].disabled, "przy mistrzostwie 6 można dalej (do 3.)")
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
	_check(win.list_icons[Skills.ORDER.find("throw")]._get_drag_data(Vector2.ZERO) != null
			and win.list_icons[Skills.ORDER.find("slam")]._get_drag_data(Vector2.ZERO) == null, "nieodblokowanej nie da się przeciągnąć")
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

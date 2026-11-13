extends SceneTree
## Test umiejętności miecza: kupno za złoto (poziom, cena), miejsca (zamiana, Mgnienie nie pod „Atak”, zablokowane
## miejsca), zapis, działanie w walce (Młynek, Rzut mieczem, Rozłupanie Ziemi z ogłuszeniem, Mgnienie), mana
## i odnowienie, zwykły cios przy braku many pod dużym przyciskiem, auto atak z umiejętnością, przyciski walki
## (ikony, odnowienie, stuknięcie), kamień run w bazie i okno umiejętności (kupno, przypisywanie, przeciąganie,
## pola 44 px, „wstecz”).

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
	weapon.flicker_held = true
	await _wait(1.0)
	weapon.flicker_held = false
	var jumps := dummy._count - total - 1
	_check(jumps >= 2 and jumps <= 4, "trzymanie - skok co 0,32 s, bez innego celu znów przez tę samą kukłę (%d)" % jumps)
	var after := dummy._count
	await _wait(0.5)
	_check(dummy._count == after, "puszczenie przycisku kończy skoki")
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
	_check(game.skills_owned.has("whirl") and game.gold == 900 and not win.buy_buttons[whirl_i].visible, "Młynek kupiony")
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

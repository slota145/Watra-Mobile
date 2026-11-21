extends SceneTree
## Test esencji i poziomów unikatów (ankieta autora 21.11.2026): rozbicie unikatu daje jego esencję (z esencjami
## włożonymi w poziomy), koszt 1-2-3-4, poziom podnosi dodatnie premie i siłę działania o 10% (kary bez zmian),
## suma cech założonych, opis, zapis i odczyt, okno „Postać” (gwiazdki, esencje, „Ulepsz” z potwierdzeniem, pola 44 px).

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
	_test_game(game)
	await _test_window(game)
	print("WYNIK: " + ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	DirAccess.remove_absolute(game.save_path)
	quit(1 if _failed > 0 else 0)


func _test_data() -> void:
	_check(Items.essence_cost(1) == 1 and Items.essence_cost(4) == 4 and Items.essence_cost(5) == 0, "koszt 1-2-3-4, na 5. koniec")
	var licho := Items.make_unique("licho", 20)
	_check(Items.unique_level(licho) == 1 and is_equal_approx(Items.unique_power(licho), 3.0), "nowy unikat - 1. poziom")
	licho.ulevel = 5
	_check(is_equal_approx(Items.unique_power(licho), 4.2), "Oko Licha na 5. poziomie x4,2")
	_check(Items.essences_in(licho) == 10, "w 5. poziom włożono 10 esencji")
	var speed: float = licho.ustats.attack_speed_pct
	_check(is_equal_approx(Items.unique_stat(licho, "attack_speed_pct"), speed * 1.4), "premia +40% na 5. poziomie")
	_check(Items.unique_lines(licho)[2].contains("x4.2"), "opis działania z poziomem: " + Items.unique_lines(licho)[2])
	var bastion := Items.make_unique("bastion", 20)
	bastion.ulevel = 3
	_check(Items.unique_stat(bastion, "move_pct") == -20.0, "kara bez zmian")
	var t := Items.totals({"armor": bastion, "earring": licho})
	_check(is_equal_approx(t.uniques.bastion, 2.4) and is_equal_approx(t.uniques.licho, 4.2), "suma cech: siła po poziomie")
	var strzy := Items.make_unique("strzybog", 20)
	_check(is_equal_approx(Items.strzybog_power(Items.unique_power(strzy)), Items.STRZYBOG_POWER), "Strzybog 1. poziom - stara siła odłamków")
	var saved := Items.normalize(JSON.parse_string(JSON.stringify(licho)))
	_check(Items.unique_level(saved) == 5, "poziom unikatu po zapisie")
	licho.ulevel = 99
	_check(Items.unique_level(Items.normalize(licho)) == 5, "zły poziom przycięty")


func _test_game(game: Node) -> void:
	var u := Items.make_unique("swarog", 20)
	game.bag = [u]
	var got: Dictionary = game.dismantle(0)
	_check(got.essence == 1 and game.essences.get("swarog", 0) == 1, "rozbicie unikatu: +1 esencja")
	var u2 := Items.make_unique("swarog", 20)
	game.bag = [u2]
	_check(game.unique_problem(u2) == "" and game.upgrade_unique(u2) and Items.unique_level(u2) == 2
			and not game.essences.has("swarog"), "ulepszenie za 1 esencję")
	_check(game.unique_problem(u2) == "essence" and not game.upgrade_unique(u2), "bez esencji - nie da się")
	game.essences["swarog"] = 20
	for i in 3:
		game.upgrade_unique(u2)
	_check(Items.unique_level(u2) == 5 and game.essences.swarog == 20 - 2 - 3 - 4, "do 5. poziomu: 2+3+4 esencje")
	_check(game.unique_problem(u2) == "max", "najwyższy poziom")
	game.save_game()
	game.load_game()
	_check(game.essences.get("swarog", 0) == 11 and Items.unique_level(game.bag[0]) == 5, "esencje i poziom w zapisie")
	game.dismantle(0)
	_check(game.essences.swarog == 11 + 11, "rozbicie 5. poziomu oddaje 10 włożonych + 1")
	_check(game.unique_problem(Items.roll(5, "boots", "rare")) == "not_unique", "zwykły przedmiot - nie unikat")


func _test_window(game: Node) -> void:
	game.essences = {"licho": 1}
	var u := Items.make_unique("licho", 20)
	game.bag = [u]
	var stats := HeroStats.new()
	root.add_child(stats)
	await process_frame
	stats.open()
	stats._select_bag(0)
	await process_frame
	_check(stats.upgrade_button.visible and not stats.upgrade_button.disabled and stats.detail_stars.visible
			and stats.detail_stars.level == 1, "opis unikatu: gwiazdki i „Ulepsz”")
	_check(stats.upgrade_button.size.y >= 44, "„Ulepsz” 44 px")
	stats.upgrade_button.pressed.emit()
	_check(stats.upgrade_button.text == tr("Na pewno?") and Items.unique_level(u) == 1, "pierwsze stuknięcie pyta")
	stats.upgrade_button.pressed.emit()
	_check(Items.unique_level(u) == 2 and stats.detail_stars.level == 2 and stats.upgrade_button.disabled,
			"drugie ulepsza, brak esencji - przycisk nieaktywny")
	_check(stats.bag_buttons[0].get_node("Stars").count() == 1, "w torbie gwiazdka poziomu ponad 1.")
	var rare := Items.roll(5, "boots", "rare")
	game.bag.append(rare)
	stats.refresh()
	stats._select_bag(1)
	_check(not stats.upgrade_button.visible and stats.bag_buttons[1].get_node("Stars").count() == 0, "zwykły przedmiot bez esencji")
	stats.close()
	stats.queue_free()
	game.bag = []
	game.essences = {}

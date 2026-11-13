extends SceneTree
## Test przedmiotów: losowanie (rzadkości i liczba premii, stopnie z poziomu lochu, siła rośnie z lochem), suma cech
## z sufitami, cena sprzedaży, torba, zakładanie, zdejmowanie, sprzedaż i zapis (Game), przedmiot z goblina leci
## do torby (pełna torba - odskakuje), cechy przedmiotów działają na postać i miecz w lochu (także po zmianie
## w pauzie), okno „Postać” z ekwipunkiem i torbą (opis przedmiotu, „Załóż”, „Sprzedaj” z potwierdzeniem, pola
## 44 px, „wstecz”) i skrót deweloperski „+5 przedm.”. Nowe premie (13.11.2026): krytyki (złota liczba z „!”), zdrowie
## za zabicie, krótsze odnowienie, przeciw elitom i bossom, odnowa many - z sufitami i w oknie „Postać”.

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
	await _test_dungeon(game)
	await _test_window(game)
	await _test_new_stats(game)
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	var counts_ok := true
	for r in Items.RARITIES:
		for i in 30:
			var item := Items.roll(3, "", r)
			var n: int = item.affixes.size()
			counts_ok = counts_ok and n >= Items.AFFIX_COUNT[r].x and n <= Items.AFFIX_COUNT[r].y
	_check(counts_ok, "liczba premii według rzadkości (zwykły 0, magiczny 1-2, rzadki 3-4)")
	var rare := Items.roll(1, "helmet", "rare")
	var stats := {}
	for a in rare.affixes:
		stats[a.stat] = true
	_check(stats.size() == rare.affixes.size(), "premie się nie powtarzają")
	_check(Items.tier_for(1) == 0 and Items.tier_for(5) == 1 and Items.tier_for(99) == 4, "stopnie przedmiotów z poziomu lochu")
	_check(Items.name_of(Items.roll(1, "weapon")) == "Żelazny miecz" and Items.name_of(Items.roll(9, "armor")) == "Mithrilowy napierśnik", "nazwy z Watry według stopnia")
	_check(Items.icon_of(rare) != null and Items.icon_of(Items.roll(20, "amulet", "magic")) != null, "ikony wszystkich wersji")
	var low := Items.roll(1, "armor", "common")
	var high := Items.roll(10, "armor", "common")
	_check(high.base.hp > low.base.hp, "zbroja z wyższego lochu daje więcej zdrowia (%d > %d)" % [high.base.hp, low.base.hp])
	var mid := 0.0
	var deep := 0.0
	for k in 40:
		mid += Items.roll_affix("damage_pct", 17)
		deep += Items.roll_affix("damage_pct", 30)
	_check(deep > mid and Items.roll(30, "ring").base.damage_pct > Items.roll(17, "ring").base.damage_pct, "procenty rosną dalej po lochu 17")
	var w := Items.roll(1, "weapon", "common")
	_check(w.base.damage[0] > 0 and w.base.damage[1] > w.base.damage[0], "broń ma obrażenia cięcia (%d-%d)" % w.base.damage)
	var t := Items.totals({"helmet": {"slot": "helmet", "base": {"hp": 10}, "affixes": [{"stat": "protection_pct", "value": 40.0}]},
			"armor": {"slot": "armor", "base": {"hp": 20}, "affixes": [{"stat": "protection_pct", "value": 40.0}]}})
	_check(is_equal_approx(t.hp, 30.0) and is_equal_approx(t.protection_pct, Items.CAPS.protection_pct), "suma cech z sufitem ochrony")
	_check(Items.sell_price(Items.roll(1, "", "rare")) > Items.sell_price(Items.roll(1, "", "common")), "rzadki droższy")
	var chest := Items.roll_chest(2)
	_check(chest.size() == Items.CHEST_ITEMS and chest[0].rarity != "common", "skrzynia: %d przedmioty, pierwszy co najmniej magiczny" % chest.size())
	_check(Items.stat_text("hp", 12) == "+12 do zdrowia" and Items.stat_text("regen", 0.8) == "+0.8 zdrowia na sekundę", "opisy premii")
	_check(Items.normalize({"slot": "x"}).is_empty() and Items.normalize(JSON.parse_string(JSON.stringify(rare))) == rare, "wczytany przedmiot taki jak zapisany")


func _test_game(game: Node) -> void:
	var item := Items.roll(2, "helmet", "magic")
	_check(game.add_item(item) and game.bag.size() == 1, "przedmiot do torby")
	game.equip(0)
	_check(game.bag.is_empty() and game.equipped.helmet == item, "założony")
	var other := Items.roll(2, "helmet", "common")
	game.add_item(other)
	game.equip(0)
	_check(game.equipped.helmet == other and game.bag == [item], "zamiana - stary hełm wraca do torby")
	game.load_game()
	_check(game.equipped.helmet == other and game.bag == [item], "torba i ekwipunek w zapisie")
	var price := Items.sell_price(item)
	_check(game.sell(0) == price and game.gold == price and game.bag.is_empty(), "sprzedaż za złoto (%d)" % price)
	_check(game.unequip("helmet") and game.bag.size() == 1 and not game.equipped.has("helmet"), "zdjęcie do torby")
	for i in game.BAG_SIZE:
		game.add_item(Items.roll(1))
	_check(game.bag.size() == game.BAG_SIZE and not game.add_item(Items.roll(1)), "pełna torba nie przyjmuje")
	game.equip(0)
	game.add_item(Items.roll(1))
	_check(not game.unequip(game.equipped.keys()[0]), "przy pełnej torbie nie da się zdjąć")
	game.reset_hero()
	_check(game.bag.is_empty() and game.equipped.is_empty() and game.gold == 0, "postać od nowa czyści przedmioty")
	game.dungeon_level = 4
	_check(game.dev_items(5) == 5 and game.bag[0].level == 4, "skrót deweloperski: 5 przedmiotów z obecnego lochu")
	game.reset_hero()
	game.dungeon_level = 1


func _test_dungeon(game: Node) -> void:
	game.dungeon_level = 1
	var helmet := Items.roll(1, "helmet", "common")
	game.add_item(helmet)
	game.equip(0)
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	_check(hero.max_hp == HeroLevels.max_hp(1) + helmet.base.hp and hero.hp == hero.max_hp, "hełm dodaje zdrowia (%d)" % hero.max_hp)
	_check(arena.health_text.text == "%d / %d" % [hero.max_hp, hero.max_hp], "pasek zdrowia z hełmem")
	_check(arena.weapon.damage == ProtoWeapon.DAMAGE, "bez broni - zwykły miecz")
	_check(arena.ember_text.text == "0 / %d" % DungeonLevels.SUMMON_COST, "liczby na pasku żaru: " + arena.ember_text.text)
	horde._on_ember(37)
	_check(arena.ember_text.text == "37 / %d" % DungeonLevels.SUMMON_COST, "pasek żaru liczy zebrany żar")
	# broń, ochrona, szybkość - założone w trakcie wyprawy (pauza)
	var sword := Items.roll(1, "weapon", "common")
	sword.affixes = [{"stat": "attack_speed_pct", "value": 20.0}, {"stat": "damage_pct", "value": 10.0}]
	var boots := Items.roll(1, "boots", "common")
	boots.affixes = [{"stat": "protection_pct", "value": 20.0}]
	game.add_item(sword)
	game.add_item(boots)
	hero.take_damage(30)
	var hp_before := hero.hp
	game.equip(0)
	game.equip(0)
	_check(arena.weapon.damage == Vector2i(sword.base.damage[0], sword.base.damage[1]), "miecz bije obrażeniami założonej broni")
	_check(is_equal_approx(arena.weapon.damage_mult, 1.1) and is_equal_approx(arena.weapon.speed_mult, 1.2), "premie obrażeń i szybkości ataku")
	_check(hero.hp == hp_before and hero.move_mult > 1.0, "zmiana ekwipunku nie leczy, buty przyspieszają")
	hero._invulnerable = 0.0
	hero.take_damage(10)
	_check(hero.hp == hp_before - 8, "ochrona zmniejsza obrażenia (20%%: 10 -> %d)" % (hp_before - hero.hp))
	# przedmiot z goblina leci do torby; przy pełnej torbie odskakuje
	var loot := horde.drop_item(Items.roll(1, "ring", "rare"), hero.position + Vector2(20, 0))
	await _wait(0.9)
	_check(not is_instance_valid(loot) or loot._taken, "przedmiot z ziemi podniesiony")
	_check(game.bag.size() == 1 and game.bag[0].slot == "ring" and arena.run_items == 1, "pierścień w torbie, licznik wyprawy")
	while game.bag.size() < game.BAG_SIZE:
		game.add_item(Items.roll(1))
	var full := horde.drop_item(Items.roll(1), hero.position + Vector2(20, 0))
	await _wait(0.9)
	_check(is_instance_valid(full) and not full._taken and full._blocked, "pełna torba - przedmiot zostaje na ziemi")
	var feed_text := ""
	for p in arena.loot_feed.get_children():
		feed_text += p.get_child(0).get_child(1).text
	_check(feed_text.contains(tr("Podniesiono: %s") % ""), "powiadomienie o podniesionym przedmiocie: " + feed_text)
	# auto sprzedaż zwykłych: złoto zamiast torby, także przy pełnej torbie
	game.auto_sell_common = true
	var gold_before: int = game.gold
	var common := Items.roll(1, "boots", "common")
	horde.drop_item(common, hero.position + Vector2(20, 0))
	await _wait(0.9)
	_check(game.gold == gold_before + Items.sell_price(common) and arena.run_sold_gold == Items.sell_price(common), "auto sprzedaż zwykłego (+%d złota)" % (game.gold - gold_before))
	var last: Label = arena.loot_feed.get_child(arena.loot_feed.get_child_count() - 1).get_child(0).get_child(1)
	_check(last.text.begins_with(tr("Sprzedano: %s (+%d złota)").split(":")[0]), "powiadomienie o sprzedaży: " + last.text)
	game.auto_sell_common = false
	var g := horde.spawn_at(hero.position + Vector2(200, 0))
	await process_frame
	var xp_before: int = game.hero_xp
	g.take_damage(10000, hero.global_position)
	await process_frame
	_check(game.hero_xp - xp_before == HeroLevels.goblin_xp(1), "bez premii doświadczenia - zwykłe doświadczenie")
	# wyjście z lochu pyta „Na pewno?”
	arena._open_menu()
	var menu: PauseMenu = arena.pause_menu
	menu.base_button.pressed.emit()
	_check(menu.base_button.text == tr("Na pewno?") and arena.is_inside_tree(), "„Uciekaj do bazy” pyta „Na pewno?”")
	menu.quit_button.pressed.emit()
	_check(menu.quit_button.text == tr("Na pewno?") and menu.base_button.text == tr("Uciekaj do bazy"), "„Menu główne” też pyta, poprzednie pytanie znika")
	menu.close()
	arena._open_menu()
	_check(menu.quit_button.text == tr("Menu główne"), "ponowne otwarcie pauzy kasuje pytanie")
	menu.close()
	arena.queue_free()
	await process_frame
	game.reset_hero()


func _test_window(game: Node) -> void:
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var menu: PauseMenu = arena.pause_menu
	arena._open_menu()
	menu.items_button.pressed.emit()
	_check(game.bag.size() == PauseMenu.DEV_ITEMS, "„+5 łupu” w pauzie")
	menu.close()
	_check(arena.stats_icon.get_global_rect().size.x >= 44.0 and arena.stats_icon.get_global_rect().size.y >= 44.0,
			"ikonka „Postać” w górnym rzędzie, 44 px")
	arena.stats_icon.pressed.emit()
	await process_frame
	await process_frame
	var stats: HeroStats = arena.stats_window
	_check(paused, "okno „Postać” zatrzymuje grę")
	_check(stats.visible and stats.bag_buttons.size() == game.BAG_SIZE and stats.equip_buttons.size() == 6, "okno: 6 miejsc ekwipunku i torba")
	_check(stats.bag_buttons[0].icon != null and stats.bag_buttons[game.bag.size()].icon == null, "ikony przedmiotów w torbie")
	var small := false
	for b in stats.bag_buttons + stats.equip_buttons.values():
		var r: Rect2 = b.get_global_rect()
		small = small or r.size.x < 44.0 or r.size.y < 44.0
	_check(not small, "pola przedmiotów co najmniej 44 px")
	var vp := stats.get_viewport_rect()
	_check(vp.encloses(stats._scroll.get_global_rect()), "okno mieści się na ekranie")
	var sword := Items.roll(3, "weapon", "rare")
	game.bag[0] = sword
	stats.refresh()
	stats.bag_buttons[0].pressed.emit()
	await process_frame
	_check(stats.detail.visible and stats.detail_name.text == Items.name_of(sword), "opis przedmiotu: " + stats.detail_name.text)
	var r: Rect2 = stats.equip_button.get_global_rect()
	_check(r.position.y > vp.size.y / 2.0 and r.size.y >= 44.0, "przyciski opisu w dolnej połowie, 44 px")
	var compare := false
	for l in stats.detail_lines.get_children():
		compare = compare or (l is Label and l.text.begins_with(tr("Obrażenia miecza")))
	_check(compare, "porównanie obrażeń po założeniu")
	stats.back()
	_check(not stats.detail.visible and stats.visible, "„wstecz” zamyka najpierw opis")
	stats.bag_buttons[0].pressed.emit()
	stats.equip_button.pressed.emit()
	_check(game.equipped.get("weapon") == sword and not stats.detail.visible, "„Załóż”")
	_check(stats.rows["damage"][0].text == "%d-%d" % [HeroStats.damage_range(1, game.gear()).x, HeroStats.damage_range(1, game.gear()).y], "statystyki z bronią")
	_check(arena.weapon.damage == HeroStats.weapon_damage(game.gear()), "miecz w bazie też dostaje broń")
	# sprzedaż: magiczny/rzadki wymaga drugiego stuknięcia
	game.bag[0] = Items.roll(1, "ring", "rare")
	stats.refresh()
	var n: int = game.bag.size()
	stats.bag_buttons[0].pressed.emit()
	stats.sell_button.pressed.emit()
	_check(game.bag.size() == n and stats.sell_button.text == tr("Na pewno?"), "rzadki - „Na pewno?”")
	stats.sell_button.pressed.emit()
	_check(game.bag.size() == n - 1 and game.gold > 0 and stats.gold_label.text == str(game.gold), "sprzedany, złoto w oknie (%d)" % game.gold)
	stats.equip_buttons["weapon"].pressed.emit()
	_check(stats.detail.visible and stats.equip_button.text == tr("Zdejmij") and not stats.sell_button.visible, "założony: „Zdejmij” bez sprzedaży")
	stats.equip_button.pressed.emit()
	_check(not game.equipped.has("weapon"), "zdjęty")
	arena._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not stats.visible and not paused, "„wstecz” zamyka okno „Postać” i wznawia grę")
	# sprzedaż hurtem: zwykłe osobno, magiczne i rzadkie osobno, z potwierdzeniem
	game.bag.clear()
	for rar in ["common", "common", "magic", "rare"]:
		game.add_item(Items.roll(2, "", rar))
	stats.open()
	var common_price: int = game.sell_all_price(["common"])
	var gold_start: int = game.gold
	stats.sell_common_button.pressed.emit()
	_check(game.bag.size() == 4 and stats.sell_common_button.text == tr("Na pewno? +%d złota") % common_price, "„Sprzedaj zwykłe” pyta i podaje cenę")
	stats.sell_common_button.pressed.emit()
	_check(game.bag.size() == 2 and game.gold == gold_start + common_price and stats.sell_common_button.disabled, "zwykłe sprzedane, przycisk nieaktywny")
	stats.sell_better_button.pressed.emit()
	stats.sell_better_button.pressed.emit()
	_check(game.bag.is_empty(), "magiczne i rzadkie sprzedane")
	stats.auto_sell_toggle.button_pressed = true
	_check(game.auto_sell_common, "przełącznik auto sprzedaży")
	stats.auto_sell_toggle.button_pressed = false
	stats.close()
	menu.close()
	arena.queue_free()
	await process_frame
	game.reset_hero()


func _test_new_stats(game: Node) -> void:
	var fresh := ["crit_pct", "crit_dmg_pct", "life_on_kill", "cdr_pct", "elite_dmg_pct", "mana_regen"]
	var known := true
	for stat in fresh:
		known = known and Items.AFFIXES.has(stat) and Items.STAT_FORMATS.has(stat)
	_check(known, "nowe premie w puli losowania i z opisem")
	_check(Items.stat_text("mana_regen", 0.8) == "+0.8 many na sekundę", "opis odnowy many z ułamkiem: " + Items.stat_text("mana_regen", 0.8))
	var big := {"ring": {"slot": "ring", "base": {}, "affixes": [{"stat": "crit_pct", "value": 80.0}, {"stat": "cdr_pct", "value": 90.0}], "sockets": []}}
	var t := Items.totals(big)
	_check(t.crit_pct == Items.CAPS.crit_pct and t.cdr_pct == Items.CAPS.cdr_pct, "sufity: krytyk %d%%, odnowienie %d%%" % [t.crit_pct, t.cdr_pct])
	_check(HeroStats.summary(1, {}).crit == "5%" and HeroStats.summary(1, {}).crit_dmg == "150%", "bazowy krytyk: 5% za 150%")
	# premie w lochu
	var ring := Items.roll(1, "ring", "common")
	ring.affixes = [{"stat": "crit_pct", "value": 15.0}, {"stat": "crit_dmg_pct", "value": 50.0},
		{"stat": "elite_dmg_pct", "value": 20.0}, {"stat": "cdr_pct", "value": 20.0},
		{"stat": "mana_regen", "value": 2.0}, {"stat": "life_on_kill", "value": 5.0}]
	game.equipped = {"ring": ring}
	game.dungeon_level = 2
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var weapon: ProtoWeapon = arena.weapon
	horde.running = false
	weapon.auto_attack = false
	_check(is_equal_approx(weapon.crit_chance, 0.2) and is_equal_approx(weapon.crit_mult, 2.0)
		and is_equal_approx(weapon.elite_mult, 1.2) and is_equal_approx(weapon.cooldown_cut, 0.2), "premie trafiają do miecza")
	var full := weapon.cooldown_full("whirl")
	weapon.cooldown_cut = 0.0
	_check(is_equal_approx(full, weapon.cooldown_full("whirl") * 0.8), "krótsze odnowienie umiejętności (%.1f s)" % full)
	weapon.cooldown_cut = 0.2
	var g := horde.spawn_at(hero.position + Vector2(150, 0))
	await process_frame
	weapon.crit_chance = 1.0
	var hp := g.hp
	weapon._deal(g, 10, hero.global_position, Skills.STRIKE)
	var crit_label := false
	for c in g.get_children():
		crit_label = crit_label or (c is Label and c.text == "20!")
	_check(g.hp == hp - 20 and crit_label, "trafienie krytyczne: x2 i złota liczba „20!”")
	weapon.crit_chance = 0.0
	var e := horde.spawn_at(hero.position + Vector2(-150, 0), "goblin", ["fast"] as Array[String])
	await process_frame
	hp = e.hp
	weapon._deal(e, 10, hero.global_position, Skills.STRIKE)
	_check(e.hp == hp - 12, "przeciw elitom +20%% (%d)" % (hp - e.hp))
	hero.hp = 50
	g.take_damage(100000, hero.global_position)
	_check(hero.hp == 55, "zdrowie za zabicie potwora (%d)" % hero.hp)
	hero.mana = 0
	await _wait(1.0)
	_check(hero.mana >= 4 and hero.mana <= 6, "odnowa many z premią (%d na s)" % hero.mana)
	arena.queue_free()
	await process_frame
	game.equipped = {}
	game.save_game()

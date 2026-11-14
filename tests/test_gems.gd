extends SceneTree
## Test kamieni (Gems): dane i łup (od 3. poziomu lochu), sakwa, gniazda umiejętności (2 otwarte z 5, Klucz Runiczny,
## jeden rodzaj raz, wyjmowanie za darmo), gniazda przedmiotów (premia według miejsca, Dłuto Jubilera, stare zapisy,
## sprzedaż oddaje kamienie), zapis, działanie w walce (koszt many, odnowienie, podpalenie, spowolnienie, leczenie,
## piorun, Mnożenie, Szerokość), podnoszenie kamienia z ziemi, okno umiejętności (zakładka „Kamienie”) i okno „Postać”.

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
	_test_skill_sockets(game)
	_test_item_sockets(game)
	await _test_combat(game)
	await _test_windows(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.settings_path)
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Gems.SUPPORT_ORDER.size() == 8 and Gems.JEWEL_ORDER.size() == 4, "8 kamieni umiejętności i 4 szlachetne")
	for kind in Gems.SUPPORT_ORDER:
		_check(Gems.SUPPORT[kind].values.size() == 5 and Gems.icon_of(Gems.make(kind, 0)) != null, "kamień %s: 5 stopni i ikona" % kind)
	for kind in Gems.JEWEL_ORDER:
		_check(Gems.icon_of(Gems.make(kind, 4)) != null, "kamień %s: ikona najwyższego stopnia" % kind)
	_check(Gems.icon_of(Gems.KEY) != null and Gems.icon_of(Gems.CHISEL) != null, "ikony klucza i dłuta")
	_check(Gems.make("ember", 9) == "ember:4" and Gems.grade_of("ember:2") == 2 and Gems.kind_of("ember:2") == "ember",
			"identyfikator rodzaj:stopień")
	_check(Gems.valid("ruby:0") and Gems.valid(Gems.KEY) and not Gems.valid("bzdura:1") and not Gems.valid(3),
			"sprawdzanie identyfikatorów z zapisu")
	_check(Gems.name_of("ember:1") == "Żar - Odłamek", "nazwa kamienia ze stopniem")
	_check(Gems.jewel_stat("ruby:0", "earring")[0] == "damage_pct" and Gems.jewel_stat("ruby:0", "helmet")[0] == "hp"
			and Gems.jewel_stat("ruby:0", "ring")[0] == "regen", "rubin: premia zależy od miejsca")
	_check(Gems.support_text("multi:0", "throw").contains("3 miecze"), "opis kamienia zależy od umiejętności")
	var low := true
	for i in 300:
		low = low and Gems.roll_goblin(2) == "" and Gems.roll_chest(2).is_empty()
	_check(low, "poniżej 3. poziomu lochu kamienie nie wypadają")
	var gems := 0
	var grades_ok := true
	for i in 300:
		for id in Gems.roll_chest(10):
			if not Gems.is_special(id) and not Gems.is_unique(id):
				gems += 1
				grades_ok = grades_ok and Gems.grade_of(id) == Items.tier_for(10)
	_check(gems > 200 and grades_ok, "skrzynia Wodza zwykle daje kamień, stopień z poziomu lochu (%d)" % gems)
	# kamienie unikalne
	var ok := true
	for skill in Gems.UNIQUE:  # hydrosfera - kamienie unikalne później
		var u := Gems.unique_of(skill)
		ok = ok and Gems.is_unique(u) and Gems.is_support(u) and Gems.valid(u) and Gems.icon_of(u) != null \
				and Gems.unique_skill(u) == skill and Gems.name_of(u) != "" and Gems.short_text(u, skill) != ""
	_check(ok, "kamienie unikalne: po jednym na umiejętność, z ikoną i opisem")
	_check(Gems.support_text(Gems.unique_of("whirl"), "throw").contains(Skills.name_of("whirl")),
			"opis unikalnego w cudzej umiejętności mówi, do czego pasuje")
	var uniques := 0
	var low_unique := 0
	for i in 2000:
		for id in Gems.roll_chest(10):
			uniques += 1 if Gems.is_unique(id) else 0
		for id in Gems.roll_chest(4):
			low_unique += 1 if Gems.is_unique(id) else 0
	_check(uniques > 40 and uniques < 300 and low_unique == 0,
			"unikalne rzadko ze skrzyni (%d na 2000 na poz. 10), poniżej 5. poziomu lochu nie" % uniques)


func _test_skill_sockets(game: Node) -> void:
	game.reset_hero()
	_check(game.skill_open_count("strike") == 2 and game.skill_sockets("strike") == ["", "", "", "", ""],
			"umiejętność: 5 gniazd, otwarte 2")
	game.add_gem("ember:1")
	game.add_gem("ember:3")
	game.add_gem("rime:0", 2)
	_check(game.gem_count("rime:0") == 2 and game.gem_list().front() == "ember:3", "sakwa liczy sztuki, lepszy stopień wyżej")
	_check(game.skill_socket_problem("whirl", 0, "ember:1") == "owned", "niekupiona umiejętność nie przyjmie kamienia")
	_check(game.skill_socket_problem("strike", 2, "ember:1") == "locked", "zamknięte gniazdo nie przyjmie kamienia")
	_check(game.socket_skill("strike", 0, "ember:1") and game.gem_count("ember:1") == 0, "kamień wchodzi w gniazdo")
	_check(game.skill_socket_problem("strike", 1, "ember:3") == "same", "ten sam rodzaj drugi raz się nie zmieści")
	_check(game.socket_skill("strike", 0, "ember:3") and game.gem_count("ember:1") == 1 and game.skill_sockets("strike")[0] == "ember:3",
			"lepszy kamień w to samo gniazdo - stary wraca do sakwy")
	_check(game.socket_skill("strike", 1, "rime:0") and game.gem_count("rime:0") == 1, "drugie gniazdo")
	_check(not game.open_skill_socket("strike"), "bez klucza gniazdo się nie otworzy")
	game.add_gem(Gems.KEY, 3)
	_check(game.open_skill_socket("strike") and game.skill_open_count("strike") == 3 and game.gem_count(Gems.KEY) == 2,
			"Klucz Runiczny otwiera 3. gniazdo")
	game.open_skill_socket("strike")
	game.open_skill_socket("strike")
	_check(game.skill_open_count("strike") == 5 and game.gem_count(Gems.KEY) == 0, "wszystkie 5 gniazd za 3 klucze")
	game.add_gem(Gems.KEY)
	_check(not game.open_skill_socket("strike") and game.gem_count(Gems.KEY) == 1, "szóstego gniazda nie ma")
	game.load_game()
	_check(game.skill_sockets("strike") == ["ember:3", "rime:0", "", "", ""] and game.skill_open_count("strike") == 5
			and game.gem_count("ember:1") == 1 and game.gem_count(Gems.KEY) == 1, "gniazda i sakwa w zapisie")
	_check(game.unsocket_skill("strike", 0) and game.gem_count("ember:3") == 1 and game.skill_sockets("strike")[0] == "",
			"wyjęcie za darmo - kamień wraca do sakwy")
	game.add_gem(Gems.unique_of("whirl"))
	game.add_gem(Gems.unique_of("strike"))
	_check(game.skill_socket_problem("strike", 2, Gems.unique_of("whirl")) == "skill", "unikalny Młynka nie pasuje do zwykłego ciosu")
	_check(game.socket_skill("strike", 2, Gems.unique_of("strike")) and Gems.has_unique(game.skill_sockets("strike"), "strike"),
			"unikalny zwykłego ciosu w zwykłym gnieździe")
	_check(game.gem_list("support").front() == Gems.unique_of("whirl"), "unikalne na początku listy kamieni umiejętności")
	game.load_game()
	_check(game.skill_sockets("strike")[2] == Gems.unique_of("strike") and game.gem_count(Gems.unique_of("whirl")) == 1,
			"unikalny w zapisie")
	game.reset_hero()
	_check(game.gems.is_empty() and game.skill_gems.is_empty() and game.skill_open.is_empty(), "postać od nowa zeruje kamienie")


func _test_item_sockets(game: Node) -> void:
	game.reset_hero()
	var item := Items.roll(5, "helmet", "magic")
	_check(item.sockets.size() >= 1 and item.sockets[0] == "", "nowy przedmiot ma puste gniazdo")
	var old := Items.normalize({"slot": "helmet", "rarity": "common", "tier": 0, "level": 1, "base": {"hp": 8}, "affixes": []})
	_check(old.sockets == [""], "stary zapis dostaje jedno gniazdo")
	var bad := Items.normalize({"slot": "helmet", "rarity": "common", "base": {}, "affixes": [], "sockets": ["ember:1", "ruby:9", "x", "y"]})
	_check(bad.sockets == ["", "ruby:4"], "w przedmiocie tylko kamienie szlachetne, najwyżej 2 gniazda")
	var second := 0
	for i in 2000:
		if Items.roll(5, "", "rare").sockets.size() == 2:
			second += 1
	_check(second > 10 and second < 150, "drugie gniazdo bardzo rzadko (%d / 2000 rzadkich)" % second)
	item.sockets = [""]
	game.bag = [item]
	game.equip(0)
	var hp_before: float = game.gear().hp
	game.add_gem("ruby:2")
	_check(game.socket_item(game.equipped.helmet, 0, "ruby:2") and game.gem_count("ruby:2") == 0, "rubin w hełmie")
	_check(is_equal_approx(game.gear().hp, hp_before + Gems.JEWEL_VALUES.hp[2]), "rubin w hełmie daje zdrowie")
	_check(not game.socket_item(game.equipped.helmet, 0, "ember:1"), "kamień umiejętności nie wejdzie w przedmiot")
	_check(not game.add_socket(game.equipped.helmet), "bez dłuta nie ma drugiego gniazda")
	game.add_gem(Gems.CHISEL, 2)
	_check(game.add_socket(game.equipped.helmet) and game.equipped.helmet.sockets.size() == 2 and game.gem_count(Gems.CHISEL) == 1,
			"Dłuto Jubilera dorabia drugie gniazdo")
	_check(not game.add_socket(game.equipped.helmet) and game.gem_count(Gems.CHISEL) == 1, "trzeciego gniazda nie ma")
	game.load_game()
	_check(game.equipped.helmet.sockets == ["ruby:2", ""], "kamienie przedmiotu w zapisie")
	_check(game.unequip("helmet"), "zdjęcie hełmu z kamieniem")
	game.sell(0)
	_check(game.gem_count("ruby:2") == 1, "sprzedaż przedmiotu oddaje kamień do sakwy")
	var it2 := Items.roll(3, "ring", "common")
	it2.sockets = [""]
	game.bag = [it2]
	game.socket_item(game.bag[0], 0, "ruby:2")
	game.sell_all(["common"])
	_check(game.gem_count("ruby:2") == 1 and game.bag.is_empty(), "sprzedaż hurtem też oddaje kamienie")
	game.reset_hero()


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _test_combat(game: Node) -> void:
	game.hero_level = 15
	game.dev_skills()
	game.add_gem(Gems.KEY, 6)
	for s in ["strike", "strike", "strike", "whirl", "throw", "slam"]:
		game.open_skill_socket(s)
	for id in ["thrift:4", "haste:4", "ember:2", "rime:2", "leech:4", "discharge:4", "multi:4", "area:4"]:
		game.add_gem(id, 4)
	game.socket_skill("whirl", 0, "thrift:4")
	game.socket_skill("whirl", 1, "haste:4")
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var weapon: ProtoWeapon = arena.weapon
	_check(weapon.skill_gems.has("whirl"), "miecz zna kamienie umiejętności")
	_check(weapon.mana_cost("whirl") == 15 and weapon.mana_cost("throw") == 15, "Oszczędność: Młynek za 15 zamiast 25 many")
	_check(is_equal_approx(weapon.cooldown_full("whirl"), 8.0 * 0.7), "Pośpiech: odnowienie krótsze o 30%")
	hero.position = Vector2(0, 200)
	await _wait(0.3)
	var mana := hero.mana
	_check(weapon.cast("whirl") and hero.mana == mana - 15 and weapon.cooldown_left("whirl") < 5.7, "Młynek płaci mniej i krócej się odnawia")
	await _wait(3.2)
	# podpalenie, spowolnienie, leczenie, mana, piorun - na zwykłym ciosie
	game.socket_skill("strike", 0, "ember:2")
	game.socket_skill("strike", 1, "rime:2")
	game.socket_skill("strike", 2, "leech:4")
	game.socket_skill("strike", 3, "discharge:4")
	game.socket_skill("strike", 4, "thrift:4")
	var g1 := _goblin(arena, hero.position + Vector2(200, 0))
	var g2 := _goblin(arena, hero.position + Vector2(230, 0))
	await process_frame
	hero.hp = 10
	hero.mana = 0
	var hp2 := g2.hp
	weapon._chained = false
	weapon._deal(g1, 100, hero.global_position, "strike")
	_check(g2.hp < hp2, "Piorun przeskakuje na pobliskiego goblina")
	_check(hero.hp == 17 and hero.mana == Gems.THRIFT_STRIKE[4], "Krwiopijca leczy 7%, Oszczędność oddaje manę")
	_check(g1.speed_factor() < 0.8, "Szron spowalnia")
	var hp1 := g1.hp
	await _wait(1.2)
	_check(g1.hp < hp1, "Żar podpala - goblin traci zdrowie bez ciosów (%d)" % (hp1 - g1.hp))
	await _wait(2.5)
	_check(g1.speed_factor() == 1.0 and g1.get_node_or_null(^"_Status") == null, "efekty wygasają")
	g1.queue_free()
	g2.queue_free()
	await process_frame
	# Mnożenie i Szerokość
	for i in 5:
		game.unsocket_skill("strike", i)
	game.socket_skill("strike", 0, "multi:4")
	game.socket_skill("slam", 0, "multi:4")
	game.socket_skill("throw", 0, "multi:4")
	game.socket_skill("whirl", 2, "area:4")
	_check(is_equal_approx(weapon._area("whirl"), 1.5), "Szerokość: +50% zasięgu")
	var dummy: ProtoDummy = weapon.targets[0]
	hero.position = dummy.position + Vector2(0, 20)
	await _wait(0.8)
	var count := dummy._count
	weapon.attack_held = true
	await _wait(0.2)
	weapon.attack_held = false
	await _wait(0.7)
	_check(dummy._count == count + 2, "Mnożenie: po cięciu pada drugie (%d)" % (dummy._count - count))
	await _wait(0.8)
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	count = dummy._count
	weapon.cast("slam")
	await _wait(0.9)
	_check(dummy._count == count + 2, "Mnożenie: Rozłupanie robi drugą falę")
	weapon.reset_cooldowns()
	hero.mana = hero.max_mana
	hero.position = dummy.position + Vector2(0, 90)
	await _wait(0.3)
	weapon.cast("throw")
	await _wait(0.15)
	_check(weapon._ghosts[0].visible and weapon._ghosts[1].visible, "Mnożenie: przy Rzucie lecą widmowe miecze")
	await _wait(1.5)
	_check(not weapon._ghosts[0].visible, "widmowe miecze znikają po powrocie")
	# kamień na ziemi trafia do sakwy
	var have: int = game.gem_count("onyx:1")
	var loot := ProtoLoot.new()
	loot.hero = hero
	loot.item = {"gem": "onyx:1"}
	loot.position = hero.position + Vector2(10, 0)
	arena.get_node("World").add_child(loot)
	await _wait(1.0)
	_check(game.gem_count("onyx:1") == have + 1, "kamień z ziemi trafia do sakwy")
	arena.queue_free()
	await process_frame
	game.reset_hero()


func _test_windows(game: Node) -> void:
	game.hero_level = 6
	game.dev_skills()
	game.add_gem("ember:0")
	game.add_gem("rime:0")
	game.add_gem(Gems.KEY)
	game.add_gem("sapphire:1")
	game.add_gem(Gems.CHISEL)
	var item := Items.roll(4, "earring", "rare")
	item.sockets = [""]
	game.bag = [item]
	game.equip(0)
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var win: SkillsWindow = arena.skills_window
	arena.open_skills()
	win.set_gems_mode(true)
	await process_frame
	_check(win.gems_box.visible and not win.slots_row.visible, "zakładka „Kamienie” pokazuje gniazda zamiast miejsc")
	_check(win.socket_slots.size() == 5 and win.socket_slots[2].locked and not win.socket_slots[1].locked,
			"5 gniazd, od trzeciego zamknięte")
	var small := false
	for s in win.socket_slots:
		small = small or s.custom_minimum_size.x < 44
	_check(not small, "gniazda co najmniej 44 px")
	win.list_icons[Skills.ORDER.find("throw")].pressed.emit()
	_check(win.gem_skill == "throw", "stuknięcie umiejętności wybiera jej gniazda")
	var pouch: Array = win.pouch_row.get_children()
	_check(pouch.size() == 3 and pouch[0].gem == Gems.KEY, "sakwa: klucz i 2 kamienie umiejętności")
	_check(win.socket_labels[0].text == "puste" and win.socket_labels[2].text == "zamknięte", "pod gniazdami: puste / zamknięte")
	# najpierw gniazdo: lista pasujących kamieni z działaniem w tej umiejętności
	win.socket_slots[0].pressed.emit()
	var picker: GemPicker = win.picker
	_check(picker.visible and picker.actions.has("ember:0") and picker.actions.has("rime:0") and not picker.actions.has(Gems.KEY),
			"gniazdo: tylko pasujące kamienie")
	var effect_shown := false
	for l in picker.list.find_children("*", "Label", true, false):
		effect_shown = effect_shown or l.text == Gems.support_text("ember:0", "throw")
	_check(effect_shown, "przy kamieniu widać, co zrobi w tej umiejętności")
	_check(picker.actions["ember:0"].get_global_rect().size.y >= 44.0 and picker.close_button.get_global_rect().get_center().y \
			> root.get_visible_rect().size.y * 0.5, "przyciski wyboru 44 px, „Zamknij” na dole")
	picker.actions["ember:0"].pressed.emit()
	_check(game.skill_sockets("throw")[0] == "ember:0" and game.gem_count("ember:0") == 0 and not picker.visible,
			"„Włóż” wkłada kamień i zamyka wybór")
	_check(win.socket_labels[0].text == Gems.short_text("ember:0", "throw"), "pod gniazdem krótki opis („%s”)" % win.socket_labels[0].text)
	win.socket_slots[1].dropped.emit("rime:0", "pouch", 0)
	_check(game.skill_sockets("throw")[1] == "rime:0", "przeciągnięcie kamienia na gniazdo")
	game.add_gem("ember:1")
	win.socket_slots[1].pressed.emit()
	_check(picker.actions["ember:1"].disabled, "ten sam rodzaj w innym gnieździe - przygaszony z powodem")
	picker.actions["out"].pressed.emit()
	_check(game.skill_sockets("throw")[1] == "" and game.gem_count("rime:0") == 1, "„Wyjmij” odkłada kamień do sakwy")
	# najpierw kamień: gdzie pasuje
	var rime_slot: GemSlot = null
	for p in win.pouch_row.get_children():
		if p is GemSlot and p.gem == "rime:0" and not p.is_queued_for_deletion():
			rime_slot = p
	rime_slot.pressed.emit()
	_check(picker.visible and picker.mode == "gem" and picker.actions.has("throw") and picker.actions.has("strike"),
			"kamień z sakwy: lista umiejętności, gdzie pasuje")
	picker.actions["strike"].pressed.emit()
	_check(game.skill_sockets("strike")[0] == "rime:0", "„Włóż” w pierwsze wolne gniazdo umiejętności")
	game.add_gem("rime:0")
	game.skill_gems["whirl"] = ["leech:0", "area:0", "", "", ""]  # oba otwarte gniazda zajęte
	win.refresh()
	for p in win.pouch_row.get_children():
		if p is GemSlot and p.gem == "rime:0" and not p.is_queued_for_deletion():
			rime_slot = p
	rime_slot.pressed.emit()
	_check(picker.actions["whirl"].disabled, "pełna umiejętność przygaszona („brak wolnego gniazda”)")
	picker.close()
	game.skill_gems.erase("whirl")
	game.gems.erase("ember:1")
	game.gems.erase("rime:0")
	win.socket_slots[2].pressed.emit()
	_check(game.skill_open_count("throw") == 2 and win._key_armed, "pierwsze stuknięcie zamkniętego gniazda pyta")
	win.socket_slots[2].pressed.emit()
	_check(game.skill_open_count("throw") == 3 and game.gem_count(Gems.KEY) == 0, "drugie otwiera gniazdo kluczem")
	win.set_gems_mode(false)
	_check(win.slots_row.visible and not win.gems_box.visible, "powrót do zakładki „Miejsca”")
	win.close()
	# okno „Postać”: kamień szlachetny w broni
	await process_frame
	var stats: HeroStats = arena.stats_window
	arena.stats_icon.pressed.emit()
	await process_frame
	stats.set_tab("pouch")
	_check(stats.page_pouch.visible and not stats.page_equip.visible and stats.pouch_grid.get_child_count() == game.gem_list().size()
			and game.gem_list().has(Gems.CHISEL) and game.gem_list().has("sapphire:1"), "zakładka „Sakwa”: kamienie, dłuto")
	stats.set_tab("equip")
	stats._select_equipped("earring")
	await process_frame
	var sockets: Array = stats.socket_row.find_children("*", "GemSlot", true, false)
	_check(sockets.size() == 1 and stats.chisel_button != null and stats.socket_labels[0].text == "puste",
			"opis broni: gniazdo z opisem i przycisk dłuta")
	sockets[0].pressed.emit()
	_check(stats.picker.visible and stats.picker.actions.has("sapphire:1") and stats.picker.actions.size() == 1,
			"gniazdo przedmiotu: tylko kamienie szlachetne")
	stats.picker.actions["sapphire:1"].pressed.emit()
	_check(game.equipped.earring.sockets[0] == "sapphire:1" and game.gem_count("sapphire:1") == 0, "szafir w kolczyku")
	_check(stats.detail.visible and stats.socket_labels[0].text == Gems.jewel_text("sapphire:1", "earring"),
			"opis zostaje, pod gniazdem premia („%s”)" % stats.socket_labels[0].text)
	stats.chisel_button.pressed.emit()
	stats.chisel_button.pressed.emit()
	_check(game.equipped.earring.sockets.size() == 2 and game.gem_count(Gems.CHISEL) == 0, "dłuto: drugie stuknięcie dorabia gniazdo")
	sockets = stats.socket_row.find_children("*", "GemSlot", true, false).filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())
	sockets[0].pressed.emit()
	stats.picker.actions["out"].pressed.emit()
	_check(game.equipped.earring.sockets[0] == "" and game.gem_count("sapphire:1") == 1, "„Wyjmij” wyjmuje kamień z przedmiotu")
	stats.back()
	# najpierw kamień: szafir z sakwy do przedmiotu
	stats.set_tab("pouch")
	var sapphire: GemSlot = null
	for g in stats.pouch_grid.get_children():
		if g is GemSlot and g.gem == "sapphire:1" and not g.is_queued_for_deletion():
			sapphire = g
	sapphire.pressed.emit()
	_check(stats.picker.visible and stats.picker.actions.has("item_0"), "kamień z sakwy: lista przedmiotów, gdzie pasuje")
	stats.picker.actions["item_0"].pressed.emit()
	_check(game.equipped.earring.sockets[0] == "sapphire:1", "„Włóż” w pierwsze wolne gniazdo przedmiotu")
	stats.close()
	arena.pause_menu.visible = false
	paused = false
	arena.queue_free()
	await process_frame

extends SceneTree
## Test filtra łupu (LootFilter, okno LootFilterWindow): decyzje (rzadkości, próg stopnia, ile premii z listy, pusta
## lista, bezpiecznik, lepsze od założonego, legendy i unikaty), osobne ustawienia miejsc, Automat (premie z broni
## i umiejętności, próg z głębokości lochu), zapis i odczyt z poprawianiem, przejście z dawnego przełącznika
## „rozbijaj zwykłe”, okno (przełączniki, miejsca, zakładki, pola 44 px, pauza zostaje), znaczek ognia w torbie,
## linia w podsumowaniu wyprawy.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


## Przedmiot z podanymi premiami [[premia, stopień], ...].
func _item(rarity: String, affixes: Array, slot := "helmet") -> Dictionary:
	var it := Items.roll(10, slot, "common", Items.GOBLIN_WEIGHTS, "", false)
	it.rarity = rarity
	it.sockets = [""]
	it.affixes = []
	for a in affixes:
		it.affixes.append(Items.make_affix(a[0], 40, a[1]))
	return it


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.auto_sell_common = false
	game.load_game()
	_test_rules()
	_test_auto()
	_test_save(game)
	await _test_window(game)
	print("WYNIK: " + ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	DirAccess.remove_absolute(game.save_path)
	quit(1 if _failed > 0 else 0)


func _test_rules() -> void:
	var f := LootFilter.defaults()
	var ctx := {"weapon": Weapons.SWORD, "skills": ["strike"], "level": 1, "equipped": {}}
	var common := _item("common", [])
	_check(LootFilter.verdict(f, common, ctx) == "", "filtr wyłączony - zwykły zostaje")
	f.on = true
	_check(LootFilter.verdict(f, common, ctx) == "", "nic nie założono - każdy jest „lepszy” i zostaje")
	f.upgrade = false
	_check(LootFilter.verdict(f, common, ctx) != "", "zwykły rozbity (domyślnie rozbija zwykłe)")
	var magic := _item("magic", [["hp", 6]])
	_check(LootFilter.verdict(f, magic, ctx) == "", "magiczny nie jest zaznaczony - zostaje")
	f.slots.all.rarities = ["common", "magic", "rare"]
	_check(LootFilter.verdict(f, magic, ctx) == "", "pusta lista, próg każdy - premia się liczy, zostaje")
	f.slots.all.tier = 5
	_check(LootFilter.verdict(f, magic, ctx) != "", "próg T5 - przedmiot z samym T6 rozbity")
	var good := _item("rare", [["hp", 7], ["mana", 7], ["damage_pct", 4]])
	_check(LootFilter.verdict(f, good, ctx) == "", "próg T5 - premia T4 zostaje")
	f.slots.all.stats = ["move_pct"]
	_check(LootFilter.verdict(f, good, ctx) != "", "lista bez premii przedmiotu - rozbity")
	f.slots.all.stats = ["move_pct", "damage_pct"]
	_check(LootFilter.verdict(f, good, ctx) == "", "premia z listy w progu - zostaje")
	f.slots.all.count = 2
	_check(LootFilter.verdict(f, good, ctx) != "", "potrzeba 2 premii z listy, jest 1 - rozbity")
	good.affixes.append(Items.make_affix("move_pct", 40, 3))
	_check(LootFilter.verdict(f, good, ctx) == "", "2 premie z listy - zostaje")
	f.slots.all.count = 1
	# bezpiecznik
	var above := _item("rare", [["mana", 7]])
	Items.make_above(above, 0)
	_check(LootFilter.verdict(f, above, ctx) == "", "bezpiecznik: ponad widełki zostaje")
	f.safe_above = false
	_check(LootFilter.verdict(f, above, ctx) != "", "bez bezpiecznika ponad widełki - rozbity")
	var two := _item("rare", [["mana", 7]])
	two.sockets = ["", ""]
	_check(LootFilter.verdict(f, two, ctx) == "", "bezpiecznik: 2 gniazda zostaje")
	var legend := _item("legendary", [["mana", 7]])
	_check(LootFilter.verdict(f, legend, ctx) == "", "legenda zawsze zostaje")
	var uniq := Items.make_unique(Items.UNIQUES.keys()[0], 20)
	_check(LootFilter.verdict(f, uniq, ctx) == "", "unikat zawsze zostaje")
	# lepszy od założonego
	f.upgrade = true
	var weak := _item("rare", [["mana", 7]])
	var ctx2 := ctx.duplicate()
	ctx2.equipped = {"helmet": _item("magic", [])}
	_check(LootFilter.verdict(f, weak, ctx2) == "", "lepszy od założonego zostaje")
	ctx2.equipped = {"helmet": good}
	_check(LootFilter.verdict(f, weak, ctx2) != "", "słabszy od założonego - rozbity")
	# osobne ustawienia miejsc
	f.upgrade = false
	f.slots.boots.own = true
	f.slots.boots.rarities = []
	var boots := _item("rare", [["mana", 7]], "boots")
	_check(LootFilter.verdict(f, boots, ctx2) == "", "buty z własnymi ustawieniami (nic nie rozbija) - zostają")
	f.slots.boots.own = false
	_check(LootFilter.verdict(f, boots, ctx2) != "", "buty bez własnych - wspólne ustawienia, rozbite")


func _test_auto() -> void:
	var bow := LootFilter.auto_stats(Weapons.BOW, ["b_shot", "b_ballista"])
	_check(bow.has("proj_dmg_pct") and bow.has("proj_speed_pct") and bow.has("attack_speed_pct") and bow.has("minion_dmg_pct")
			and bow.has("elem_dmg_pct") and not bow.has("magic_dmg_pct"), "Automat: łuk - pociski, szybkość ataku, przywołańcy")
	var book := LootFilter.auto_stats(Weapons.BOOK, ["a_missiles"])
	_check(book.has("magic_dmg_pct") and book.has("cast_speed_pct") and not book.has("attack_speed_pct") and book.has("hp"),
			"Automat: księga - obrażenia magiczne i szybkość rzucania, premie ogólne")
	_check(LootFilter.auto_tier(1) == 7 and LootFilter.auto_tier(40) == 3, "próg Automatu z głębokości lochu (1: T7, 40: T3)")
	var f := LootFilter.defaults()
	f.on = true
	f.auto = true
	f.upgrade = false
	f.slots.all.rarities = ["magic"]
	var ctx := {"weapon": Weapons.BOOK, "skills": ["a_missiles"], "level": 40, "equipped": {}}
	var magic_item := _item("magic", [["magic_dmg_pct", 2]])
	_check(LootFilter.verdict(f, magic_item, ctx) == "", "Automat: premia księgi T2 zostaje")
	var bow_item := _item("magic", [["proj_speed_pct", 1]])
	_check(LootFilter.verdict(f, bow_item, ctx) == "", "Automat: pociski czaru Arkanów - szybkość pocisków zostaje")
	var off := _item("magic", [["melee_dmg_pct", 1]])
	_check(LootFilter.verdict(f, off, ctx) != "", "Automat: obrażenia wręcz przy księdze - rozbite")
	f.slots.all.stats = ["melee_dmg_pct"]
	_check(LootFilter.verdict(f, off, ctx) == "", "ręcznie zaznaczona premia wygrywa z Automatem")
	var low := _item("magic", [["magic_dmg_pct", 5]])
	_check(LootFilter.verdict(f, low, ctx) != "", "Automat na lochu 40: T5 poniżej progu - rozbity")
	var skill := _item("magic", [["skill_level", 6]])
	skill.affixes[0].skill = "a_missiles"
	f.slots.all.stats = []
	ctx.level = 1
	_check(LootFilter.verdict(f, skill, ctx) == "", "Automat: poziom założonej umiejętności zostaje")
	skill.affixes[0].skill = "strike"
	_check(LootFilter.verdict(f, skill, ctx) != "", "Automat: poziom niezałożonej umiejętności - rozbity")


func _test_save(game: Node) -> void:
	game.loot_filter = LootFilter.defaults()
	game.loot_filter.on = true
	game.loot_filter.slots.ring.own = true
	game.loot_filter.slots.ring.stats = ["hp"]
	game.loot_filter.slots.ring.tier = 3
	game.save_game()
	game.loot_filter = LootFilter.defaults()
	game.load_game()
	_check(game.loot_filter.on and game.loot_filter.slots.ring.own and game.loot_filter.slots.ring.stats == ["hp"]
			and int(game.loot_filter.slots.ring.tier) == 3, "filtr łupu w zapisie postaci")
	var bad := LootFilter.normalize({"on": true, "slots": {"all": {"rarities": ["common", "xyz"], "tier": 99,
			"count": -3, "stats": ["hp", "nie_ma"]}}})
	_check(bad.slots.all.rarities == ["common"] and bad.slots.all.tier == 7 and bad.slots.all.count == 1
			and bad.slots.all.stats == ["hp"] and bad.slots.helmet.own == false, "zły zapis poprawiony")
	# dawny przełącznik „rozbijaj zwykłe”: zapis bez filtra - filtr włączony
	var f = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	f.erase("loot_filter")
	var w := FileAccess.open(game.save_path, FileAccess.WRITE)
	w.store_string(JSON.stringify(f))
	w.close()
	game.auto_sell_common = true
	game.load_game()
	_check(game.loot_filter.on and game.loot_filter.slots.all.rarities == ["common"], "dawny przełącznik - filtr rozbija zwykłe")
	game.auto_sell_common = false
	game.load_game()
	_check(not game.loot_filter.on, "bez dawnego przełącznika - filtr wyłączony")


func _test_window(game: Node) -> void:
	game.loot_filter = LootFilter.defaults()
	var menu := PauseMenu.new()
	root.add_child(menu)
	await process_frame
	menu.open()
	menu.filter_button.pressed.emit()
	var w: LootFilterWindow = menu.filter_window
	_check(w.visible and paused, "„Filtr łupu” z pauzy otwiera okno")
	w.on_toggle.button_pressed = true
	_check(game.loot_filter.on and w.on_toggle.text == tr("Filtr: włączony"), "przełącznik filtra")
	w.slot_buttons["helmet"].pressed.emit()
	var own: CheckButton = null
	for c in w.content.get_children():
		if c is CheckButton and c.text.begins_with(tr("Własne ustawienia: %s").split(":")[0]):
			own = c
	_check(own != null, "miejsce: przełącznik własnych ustawień")
	if own:
		own.button_pressed = true
		_check(game.loot_filter.slots.helmet.own and w.slot_buttons["helmet"].get_node("Own").visible,
				"własne ustawienia hełmu z kropką na przycisku")
	w.tab_buttons["stats"].pressed.emit()
	var boxes: Array = []
	for c in w.content.get_children():
		if c is CheckBox:
			boxes.append(c)
	_check(boxes.size() > 20 and boxes.all(func(b: CheckBox) -> bool: return b.custom_minimum_size.y >= 44),
			"zakładka „Premie”: %d premii, pola 44 px" % boxes.size())
	var hp_box: CheckBox = boxes.filter(func(b: CheckBox) -> bool: return b.text == LootFilter.stat_name("hp"))[0]
	hp_box.button_pressed = true
	_check(game.loot_filter.slots.helmet.stats == ["hp"] and game.loot_filter.slots.all.stats.is_empty(),
			"zaznaczona premia trafia tylko do hełmu")
	var no_reserve := true
	for c in w.content.get_children():
		if c is CheckBox and c.text == LootFilter.stat_name("reserve_pct"):
			no_reserve = false
	_check(no_reserve, "hełm: bez premii, które w nim nie wypadają (rezerwacja many)")
	w.auto_toggle.button_pressed = true
	var auto_marked := false
	for c in w.content.get_children():
		if c is CheckBox and c.text.ends_with("A"):
			auto_marked = true
	_check(game.loot_filter.auto and auto_marked, "Automat zaznacza swoje premie znaczkiem A")
	await process_frame
	await process_frame
	for b in [w.back_button, w.on_toggle, w.auto_toggle] + w.slot_buttons.values() + w.tab_buttons.values():
		if b.size.y < 44 or b.size.x < 44:
			_check(false, "pole za małe: %s %s" % [b.text, b.size])
	menu.back()
	_check(not w.visible and menu.visible and paused, "„wstecz” zamyka filtr, pauza zostaje")
	menu.close()
	menu.queue_free()
	# znaczek ognia w torbie
	game.loot_filter = LootFilter.defaults()
	game.loot_filter.on = true
	game.loot_filter.upgrade = false
	game.bag = [_item("common", []), _item("rare", [["hp", 1]])]
	game.equipped = {}
	var stats := HeroStats.new()
	root.add_child(stats)
	await process_frame
	stats.open()
	_check(stats.bag_buttons[0].get_node("Burn").visible and not stats.bag_buttons[1].get_node("Burn").visible,
			"znaczek ognia przy zwykłym w torbie, bez niego przy rzadkim")
	_check(stats.filter_button.text == tr("Filtr łupu: włączony"), "przycisk filtra w torbie pokazuje stan")
	stats.close()
	stats.queue_free()
	var result := RunResult.new()
	root.add_child(result)
	await process_frame
	result.show_result(10, 30.0)
	result.add_filter_line(3, 7)
	_check(result._summary.text.contains(Lang.n(3, "Filtr łupu rozbił %d przedmiot (+%d rudy)",
			"Filtr łupu rozbił %d przedmioty (+%d rudy)", "Filtr łupu rozbił %d przedmiotów (+%d rudy)") % [3, 7]),
			"podsumowanie wyprawy: ile rozbił filtr")
	result.queue_free()
	paused = false
	game.bag = []

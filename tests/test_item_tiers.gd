extends SceneTree
## Test przebudowy przedmiotów (21.11.2026): stopnie premii T7-T1 z poziomu lochu, sufit siły na lochu 40, 3 bazy na
## miejsce ze stałą cechą i ikonami, rzadki 3-5 premii, nowe premie (poziom umiejętności, znaczniki, osłabieni, pełne
## zdrowie, szybkość po zabiciu, łup, ruda), przeliczenie starych przedmiotów, Runa Szlifu w stopniu, wykuwanie bazy
## i wolniejszy wzrost potworów po lochu 40.

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
	_test_tiers()
	_test_bases()
	_test_convert()
	_test_effects(game)
	_test_forge(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_tiers() -> void:
	_check(Items.best_tier(1) == 7 and Items.best_tier(5) == 6 and Items.best_tier(39) == 2 and Items.best_tier(40) == 1
			and Items.best_tier(100) == 1, "najlepszy stopień: loch 1 - T7, 39 - T2, 40 - T1")
	var low_ok := true
	var seen := {}
	for i in 400:
		low_ok = low_ok and Items.roll_tier(4) == 7
		seen[Items.roll_tier(40)] = true
	_check(low_ok and seen.size() == 7, "na lochu 4 tylko T7, na 40 wypadają wszystkie stopnie (%d)" % seen.size())
	var t1 := 0
	for i in 2000:
		t1 += 1 if Items.roll_tier(40) == 1 else 0
	_check(t1 > 40 and t1 < 180, "T1 rzadki (~5%%: %d na 2000)" % t1)
	var r7 := Items.tier_range("damage_pct", 7)
	var r6 := Items.tier_range("damage_pct", 6)
	var r1 := Items.tier_range("damage_pct", 1)
	_check(r1.x > r7.y and r6.x < r7.y and r6.y > r7.y, "widełki rosną i zachodzą na siebie (T7 %d-%d, T6 %d-%d, T1 %d-%d)"
			% [r7.x, r7.y, r6.x, r6.y, r1.x, r1.y])
	var in_range := true
	for stat in Items.AFFIXES:
		for k in 5:
			var a := Items.make_affix(stat, 40)
			var r := Items.tier_range(stat, a.tier)
			in_range = in_range and a.value >= r.x - 0.5 and a.value <= r.y + 0.5 and Items.STAT_FORMATS.has(stat)
	_check(in_range, "każda premia w widełkach swojego stopnia")
	_check(Items.affix_max("damage_pct", 100) == Items.affix_max("damage_pct", 40), "sufit siły premii na lochu 40")
	_check(Items.tier_range("skill_level", 2).x == 2.0 and Items.tier_range("skill_level", 3).x == 1.0, "poziom umiejętności: T2-T1 +2, reszta +1")
	_check(not Items.affix_fits("skill_level_all", "amulet", 21) and Items.affix_fits("skill_level_all", "amulet", 22)
			and not Items.affix_fits("skill_level_all", "ring", 40), "poziom wszystkich umiejętności: tylko amulet, od lochu 22")
	var counts := true
	for i in 40:
		var n: int = Items.roll(30, "", "rare").affixes.size()
		counts = counts and n >= 3 and n <= 5
	_check(counts, "rzadki: 3-5 premii")
	var lines := Items.affix_lines({"affixes": [{"stat": "hp", "value": 50.0, "tier": 3}]})
	_check(lines[0].begins_with("T3") and lines[0].contains("50"), "znaczek stopnia w opisie („%s”)" % lines[0])
	# Runa Szlifu - stopień zostaje
	var item := Items.roll(40, "helmet", "rare")
	var keep := true
	for i in 30:
		var tier: int = item.affixes[0].tier
		Runes.apply(item, Runes.POLISH, 0)
		keep = keep and item.affixes[0].tier == tier
	_check(keep, "Runa Szlifu: nowa wartość w tym samym stopniu")


func _test_bases() -> void:
	var icons := true
	var names := true
	for slot in Items.SLOTS:
		_check(Items.bases_of(slot).size() == 3, "%s: 3 bazy" % slot)
		for type in Items.bases_of(slot):
			for tier in 5:
				for suffix in ["", "_magic", "_rare"]:
					icons = icons and Items.base_icon(slot, type, tier, suffix) != null
			names = names and Items.BASES[slot][type].names.size() == 5
	_check(icons and names, "każda baza: 5 stopni ikon (zwykła, magiczna, rzadka) i nazw")
	var hood := Items.roll(10, "helmet", "common", Items.GOBLIN_WEIGHTS, "hood")
	var horned := Items.roll(10, "helmet", "common", Items.GOBLIN_WEIGHTS, "horned")
	_check(hood.base.has("mana") and not hood.base.has("hp") and horned.base.has("element_res_pct"), "bazy hełmu: kaptur - mana, rogaty - odporność")
	var stud := Items.roll(1, "earring", "common", Items.GOBLIN_WEIGHTS, "stud")
	_check(stud.base.has("damage") and stud.base.has("attack_speed_pct") and stud.base.has("cast_speed_pct"),
			"kolczyk z pazurem: obrażenia ciosu + szybkość ataku i rzucania")
	var p40 := Items.roll(40, "armor", "common", Items.GOBLIN_WEIGHTS, "plate")
	var p100 := Items.roll(100, "armor", "common", Items.GOBLIN_WEIGHTS, "plate")
	var p20 := Items.roll(20, "armor", "common", Items.GOBLIN_WEIGHTS, "plate")
	_check(p40.base.hp == p100.base.hp and p20.base.hp < p40.base.hp, "stała cecha rośnie do lochu 40 (%d, %d, %d)"
			% [p20.base.hp, p40.base.hp, p100.base.hp])
	_check(Items.name_of(Items.roll(1, "boots", "common", Items.GOBLIN_WEIGHTS, "bast")) == "Łapcie z łyka"
			and Items.name_of(Items.roll(40, "ring", "common", Items.GOBLIN_WEIGHTS, "gold")) == "Pierścień złotego runa", "nazwy baz według stopnia")


func _test_convert() -> void:
	var old := Items.normalize({"slot": "helmet", "rarity": "rare", "level": 60, "tier": 4, "base": {"hp": 900},
			"affixes": [{"stat": "damage_pct", "value": 45.0}, {"stat": "move_pct", "value": 4.0}]})
	_check(old.type == "helm" and old.base.hp == Items.implicit_value("hp", Items.BASES.helmet.helm.implicit.hp, 40),
			"stary hełm: pierwsza baza, zdrowie z sufitu lochu 40 (%d)" % old.base.hp)
	_check(old.affixes[0].tier == 1 and old.affixes[0].value == Items.tier_range("damage_pct", 1).y and old.affixes[1].tier == 7,
			"stare premie: najbliższy stopień (T%d, T%d)" % [old.affixes[0].tier, old.affixes[1].tier])
	var again := Items.normalize(JSON.parse_string(JSON.stringify(old)))
	_check(again == old, "nowy przedmiot przechodzi zapis bez zmian")
	var sk := Items.normalize({"slot": "amulet", "type": "runic", "rarity": "magic", "level": 30, "base": {"elem_dmg_pct": 9},
			"affixes": [{"stat": "skill_level", "value": 1, "tier": 4, "skill": "whirl"}, {"stat": "skill_level", "value": 1, "tier": 4, "skill": "nie_ma"}]})
	_check(sk.affixes.size() == 1 and sk.affixes[0].skill == "whirl", "premia poziomu umiejętności: zła umiejętność odpada")


func _test_effects(game: Node) -> void:
	var amulet := {"slot": "amulet", "type": "amber", "tier": 4, "level": 40, "rarity": "rare", "base": {"mana": 60.0}, "sockets": [""],
			"affixes": [{"stat": "skill_level", "value": 2.0, "tier": 1, "skill": "whirl"}, {"stat": "skill_level_all", "value": 1.0, "tier": 2},
				{"stat": "melee_dmg_pct", "value": 30.0, "tier": 1}, {"stat": "afflicted_dmg_pct", "value": 20.0, "tier": 3},
				{"stat": "kill_haste_pct", "value": 20.0, "tier": 1}]}
	var t := Items.totals({"amulet": amulet})
	_check(t.skill_bonus.get("whirl", 0) == 2 and t.skill_level_all == 1.0, "suma: +2 Młynek, +1 wszystkie")
	game.equipped = {"amulet": amulet}
	_check(game.item_skill_bonus("whirl") == 3 and game.item_skill_bonus("throw") == 1, "Game: poziomy z przedmiotów")
	var w := ProtoWeapon.new()
	w.skill_levels = {"whirl": 10}
	w.item_skill_levels = t.skill_bonus
	w.item_all_levels = 1
	_check(w.level_of("whirl") == Skills.MAX_LEVEL + Items.ITEM_LEVELS_MAX and w.level_of("throw") == 2,
			"umiejętność ponad 10. poziom do %d (Młynek %d)" % [Skills.MAX_LEVEL + Items.ITEM_LEVELS_MAX, w.level_of("whirl")])
	w.tag_bonus = {"melee": 0.3}
	w.afflicted_bonus = 0.2
	w.full_hp_bonus = 0.1
	var dummy := ProtoDummy.new()
	root.add_child(dummy)
	_check(is_equal_approx(w.item_hit_bonus(dummy, "whirl"), 0.4) and is_equal_approx(w.item_hit_bonus(dummy, "throw"), 0.1),
			"znaczniki: wręcz +30%% dla Młynka, nie dla rzutu; pełne zdrowie +10%%")
	dummy.shock(2.0)
	_check(is_equal_approx(w.item_hit_bonus(dummy, "throw"), 0.3), "porażony wróg: premia przeciw osłabionym")
	dummy.queue_free()
	w.free()
	var hero := ProtoHero.new()
	hero.gear = t
	hero.kill_haste = 0.2
	_check(hero.haste() == 0.0, "bez zabicia - bez przyspieszenia")
	hero.on_kill()
	_check(is_equal_approx(hero.haste(), 0.2) and hero.haste_left >= Items.KILL_HASTE_TIME - 0.01, "po zabiciu +20% na 3 s")
	hero.free()
	var boosted := Items.boosted_weights(Items.GOBLIN_WEIGHTS, 100.0)
	_check(boosted.rare == Items.GOBLIN_WEIGHTS.rare * 3 and boosted.magic == Items.GOBLIN_WEIGHTS.magic * 2,
			"rzadkość łupu +100%: magiczne x2, rzadkie x3")
	var many := 0
	for i in 200:
		many += Items.roll_chest(10, 0.0, 100.0).size()
	_check(many == 200 * (Items.CHEST_ITEMS + 1), "ilość łupu +100%: skrzynia zawsze o przedmiot więcej")
	game.equipped = {"ring": {"slot": "ring", "type": "gold", "tier": 0, "level": 1, "rarity": "magic", "base": {}, "sockets": [""],
			"affixes": [{"stat": "ore_pct", "value": 100.0, "tier": 1}]}}
	_check(game.ore_gain(4) == roundi(4 * game.treasury_mult() * 2.0), "ruda z rozbijania +100%")
	game.equipped = {}
	_check(DungeonLevels.power(41) > DungeonLevels.power(40) and DungeonLevels.power(100) < 95.0
			and is_equal_approx(DungeonLevels.power(50), DungeonLevels.power(40) * 1.6), "potwory po lochu 40 rosną wolniej (100. x%.0f)" % DungeonLevels.power(100))


func _test_forge(game: Node) -> void:
	game.ore = 100
	game.best_level = 70
	game.bag = []
	var item: Dictionary = game.forge("ring", "signet")
	_check(item.type == "signet" and item.base.has("mana_regen") and item.level == 70, "kowal wykuwa wybraną bazę")
	var r: Dictionary = game.forge("ring")
	_check(r.type in Items.bases_of("ring"), "bez wyboru - losowa baza")

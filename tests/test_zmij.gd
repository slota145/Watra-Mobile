extends SceneTree
## Test bossa szczytowego Żmija Gorynycza (Pinnacles, 22.11.2026): klucz ze skrzyni bossa od lochu 30 (zapis, łup,
## wybór przy Watrze), Pogorzelisko bez Hordy, ataki (zionięcie, kule ognia, skok), gasnące głowy przy 66% i 33%
## (drugie zionięcie, krąg słupów), skrzynia Żmija (legenda) i zwycięstwo zużywające klucz, unikaty Żmija.

var _failed := 0


func _initialize() -> void:
	DungeonLevels.enemy_hp = 1.0  # liczby w testach bez próby x3 zdrowia / x2 obrażeń wrogów
	DungeonLevels.ramp_start = 1.0  # bez Rozruchu (27.11.2026)
	DungeonLevels.enemy_damage = 1.0
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
	game.reset_hero()
	_test_data(game)
	await _test_key_drop(game)
	await _test_picker(game)
	await _test_fight(game)
	await _test_uniques(game)
	game.reset_hero()
	game.pinnacle_key = 0
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data(game: Node) -> void:
	var low := false
	for i in 200:
		low = low or Pinnacles.roll_key(Pinnacles.KEY_FROM - 1, 100.0)
	_check(not low and Pinnacles.roll_key(Pinnacles.KEY_FROM, 100.0), "klucz dopiero od lochu %d" % Pinnacles.KEY_FROM)
	var drops := 0
	for i in 4000:
		drops += 1 if Pinnacles.roll_key(35) else 0
	_check(drops > 120 and drops < 290, "klucz ok. 5%% skrzyń bossa (%d/4000)" % drops)
	# zapis kluczy
	game.add_zmij_key(34)
	game.add_zmij_key(31, 2)
	game.save_game()
	game.load_game()
	_check(game.zmij_key_count(34) == 1 and game.zmij_key_count(31) == 2, "klucze w zapisie postaci")
	_check(Pinnacles.key_list(game.zmij_keys) == [[34, 1], [31, 2]], "klucze od najsilniejszego")
	_check(game.use_zmij_key(34) and not game.use_zmij_key(34) and game.zmij_key_count(34) == 0, "zużycie klucza")
	game.zmij_keys = {}
	# łup: nazwa, kolor, ikona
	var key := {Pinnacles.KEY: 33}
	_check(ProtoLoot.name_of(key) == "Klucz do Gniazda Żmija (poziom 33)" and ProtoLoot.icon_of(key) == Pinnacles.KEY_ICON
			and ProtoLoot.color_of(key) == Pinnacles.KEY_COLOR, "klucz jako łup: nazwa, ikona, kolor")
	# unikaty Żmija nie wypadają ze zwykłego łupu
	var zmij_loot := false
	for i in 300:
		var it := Items.roll(40, "", "unique")
		zmij_loot = zmij_loot or Items.UNIQUES[it.unique].has("source")
	_check(not zmij_loot, "unikaty Żmija nie wypadają ze zwykłego łupu")
	for id in Pinnacles.UNIQUES:
		var u := Items.make_unique(id, 35)
		_check(Items.is_unique(u) and Items.unique_lines(u).size() == Items.UNIQUES[id].stats.size() + 2,
				"%s: unikat z opisem" % Items.name_of(u))
	var chest := Pinnacles.chest_items(35)
	_check(chest[0].get("rarity", "") == "legendary" and chest.size() >= 3, "skrzynia Żmija: pewna legenda (%d rzeczy)" % chest.size())


## Skrzynia bossa lochu 30 daje klucz (łup podbity ulepszeniem), a podniesiony trafia do Game.zmij_keys.
func _test_key_drop(game: Node) -> void:
	game.reset_hero()
	game.best_level = 30
	game.dungeon_level = 30
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	arena.horde_spawner.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	_check(not arena.pinnacle and arena.area == arena.ARENA, "zwykły loch bez Pogorzeliska")
	arena.horde_spawner.loot_mult = 1000.0
	arena.horde_spawner.add_embers(DungeonLevels.summon_cost(30))
	arena.summon_chief()
	await _wait(ProtoChief.ENTER_TIME + 0.1)
	arena.chief.take_damage(100000000, hero.global_position)
	await _wait(1.7)
	var has_key := false
	for it in arena.chest.items:
		has_key = has_key or it.get(Pinnacles.KEY, 0) == 30
	_check(has_key, "skrzynia bossa lochu 30 z kluczem do Gniazda Żmija")
	hero.position = arena.chest.position
	await _wait(3.0)
	_check(game.zmij_key_count(30) == 1, "podniesiony klucz w zapasie")
	arena.queue_free()
	await process_frame
	get_root_unpause()


func get_root_unpause() -> void:
	paused = false


## Wybór przy Watrze: przycisk Żmija tylko z kluczem, strzałki przy kluczach z różnych poziomów.
func _test_picker(game: Node) -> void:
	game.zmij_keys = {}
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await process_frame
	base.open_picker()
	_check(not base.picker._zmij_row.visible, "bez klucza nie ma przycisku Żmija")
	base.picker.close()
	game.add_zmij_key(32)
	game.add_zmij_key(30)
	base.open_picker()
	var got := [0]
	base.picker.pinnacle.disconnect(base.enter_pinnacle)
	base.picker.pinnacle.connect(func(l: int) -> void: got[0] = l)
	_check(base.picker._zmij_row.visible and base.picker.zmij_button.text.contains("32") and base.picker._zmij_next.visible,
			"przycisk Żmija z najsilniejszym kluczem i strzałkami")
	base.picker._zmij_next.pressed.emit()
	base.picker.zmij_button.pressed.emit()
	_check(got[0] == 30, "wybrany słabszy klucz (30)")
	paused = false
	base.queue_free()
	await process_frame
	game.zmij_keys = {}


func _fight_arena(game: Node, level: int) -> Node:
	game.reset_hero()
	game.best_level = level
	game.add_zmij_key(level)
	game.pinnacle_key = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _test_fight(game: Node) -> void:
	var arena := _fight_arena(game, 32)
	await process_frame
	await process_frame
	var hero: ProtoHero = arena.hero
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000
	hero.hp = hero.max_hp
	ProtoDecor.obstacles.clear()
	hero.obstacles.clear()
	var z := arena.chief as ProtoZmij
	_check(arena.pinnacle and arena.area == arena.PINNACLE_ARENA and arena.climate == Dungeons.VOLCANO and arena.level == 32,
			"Pogorzelisko: mała arena, podłoga Wulkanicznych równin, poziom klucza")
	_check(z != null and arena.boss_box.visible and arena.boss_box.get_child(0).text == "Żmij Gorynycz"
			and not arena.horde_spawner.running and not arena.ember_bar.visible, "od razu Żmij Gorynycz, bez Hordy i żaru")
	z.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# zionięcie
	hero.position = z.position + Vector2(0, 60)
	hero._invulnerable = 0.0
	z.start_attack("breath")
	_check(z._telegraph != null and z._telegraph.arc > 0.0 and z._telegraph.contains(hero.global_position), "zionięcie: wachlarz do postaci")
	await _wait(ProtoZmij.BREATH_WARN + 0.1)
	_check(hero.hp < hero.max_hp and hero.burn_left > 0.0 and _patches(arena) >= 3, "zionięcie rani, podpala i pali ziemię")
	_check(z.state == "recover", "w 1. fazie jedno zionięcie")
	# kule ognia
	await _wait(1.0)
	hero.position = z.position + Vector2(0, 110)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	z.start_attack("balls")
	_check(z.balls_pending() == 3, "Trzy Głowy: 3 kule w 1. fazie")
	await _wait(ProtoZmij.BALL_WARN + 0.4)
	_check(hero.hp < hero.max_hp and z.balls_pending() == 0, "kula trafia stojącą postać")
	# skok
	await _wait(1.0)
	var target := z.position + Vector2(40, 120)
	hero.position = target
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	z.start_attack("jump")
	await _wait(ProtoZmij.JUMP_WARN + ProtoZmij.JUMP_TIME + 0.1)
	_check(z.position.distance_to(target) < 5.0 and hero.hp < hero.max_hp, "skok: ląduje na postaci i rani")
	# 1. głowa gaśnie
	await _wait(1.0)
	z.take_damage(roundi(z.max_hp * 0.4), hero.global_position)
	_check(z.phase == 2 and z._sprite.texture == ProtoZmij.SHEETS[1] and z.state == "rage" and arena.banner.visible,
			"66%: głowa gaśnie, gniew i napis")
	await _wait(ProtoZmij.RAGE_TIME + 0.1)
	hero.position = z.position + Vector2(0, 60)
	z.start_attack("breath")
	await _wait(ProtoZmij.BREATH_WARN + 0.1)
	_check(z.state == "breath" and z._telegraph != null and z._second, "2. faza: drugie zionięcie w drugą stronę")
	await _wait(ProtoZmij.BREATH_SECOND_WARN + 0.1)
	_check(z.state == "recover", "po drugim zionięciu odpoczynek")
	# 2. głowa
	z.take_damage(roundi(z.max_hp * 0.3), hero.global_position)
	_check(z.phase == 3 and z._sprite.texture == ProtoZmij.SHEETS[2], "33%: druga głowa gaśnie")
	await _wait(ProtoZmij.RAGE_TIME + 0.1)
	z.start_attack("balls")
	_check(z.balls_pending() == 5, "3. faza: 5 kul ognia")
	await _wait(ProtoZmij.BALL_WARN + 0.5)
	z.start_attack("jump")
	await _wait(ProtoZmij.JUMP_WARN + ProtoZmij.JUMP_TIME + 0.1)
	var ring := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoFirePatch and absf((c.position - z.position).length() - ProtoZmij.PILLAR_RING * 0.8) < ProtoZmij.PILLAR_RING * 0.25:
			ring += 1
	_check(ring >= ProtoZmij.PILLARS, "3. faza: krąg ognistych słupów po skoku (%d)" % ring)
	# śmierć, skrzynia, zwycięstwo
	z.take_damage(100000000, hero.global_position)
	await process_frame
	_check(not z.alive() and arena.phase == "loot", "Żmij pada")
	await _wait(1.6)
	_check(arena.chest != null and arena.chest.items[0].get("rarity", "") == "legendary", "skrzynia Żmija z legendą")
	arena.chest.open()
	await _wait(2.6)
	_check(arena.phase == "won" and game.zmij_key_count(32) == 0 and game.pinnacle_key == 0 and game.best_level == 32,
			"zwycięstwo zużywa klucz, bez przebicia poziomu")
	_check(arena.result.visible and arena.result._title.text == "Żmij Gorynycz pokonany!" and not arena.result.retry_button.visible,
			"okno zwycięstwa nad Żmijem")
	paused = false
	arena.queue_free()
	await process_frame
	# śmierć nie zabiera klucza
	arena = _fight_arena(game, 30)
	await process_frame
	await process_frame
	arena.hero.take_damage(100000000)
	await _wait(1.5)
	_check(arena.hero.dead and game.zmij_key_count(30) == 1, "śmierć nie zabiera klucza")
	paused = false
	arena.queue_free()
	await process_frame
	game.zmij_keys = {}
	game.pinnacle_key = 0


func _patches(arena: Node) -> int:
	var n := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoFirePatch:
			n += 1
	return n


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 5000.0
	g.position = at
	arena.get_node("World").add_child(g)
	arena.weapon.targets.append(g)
	g.stun(30.0)
	return g


## Kieł Gorynycza: kule ognia w najbliższych wrogów; Łuska Gorynycza: krąg ognia, gdy postać oberwie.
func _test_uniques(game: Node) -> void:
	game.reset_hero()
	game.hero_level = 15
	game.dungeon_level = 1
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	arena.horde_spawner.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.position = Vector2.ZERO
	var near := _goblin(arena, Vector2(50, 0))
	var far := _goblin(arena, Vector2(0, 260))
	await process_frame
	game.equipped = {"earring": Items.make_unique("zmij_fang", 30)}
	game.inventory_changed.emit()
	await process_frame
	arena.uniques_node._fang_t = 0.0
	var hp_n := near.hp
	var hp_f := far.hp
	await _wait(0.5)
	_check(near.hp < hp_n and near.is_burning() and far.hp == hp_f, "Kieł Gorynycza: kula w bliskiego wroga, daleki cały")
	game.equipped = {"armor": Items.make_unique("zmij_scale", 30)}
	game.inventory_changed.emit()
	await process_frame
	hp_n = near.hp
	hero._invulnerable = 0.0
	hero.take_damage(5)
	await process_frame
	_check(near.hp < hp_n, "Łuska Gorynycza: zraniona postać wybucha kręgiem ognia")
	hp_n = near.hp
	hero._invulnerable = 0.0
	hero.take_damage(5)
	await process_frame
	_check(near.hp == hp_n, "Łuska Gorynycza: krąg najwyżej co %d s" % roundi(Items.ZMIJ_SCALE_COOLDOWN))
	game.equipped = {}
	arena.queue_free()
	await process_frame

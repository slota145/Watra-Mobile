extends SceneTree
## Test Księgi Arkanów (21.11.2026): żywioł Arkana (wysysa manę), premie przedmiotów (obrażenia magiczne, szybkość
## rzucania - broń magiczna przyspiesza tylko od niej), wybór broni na start (miecz / łuk / księga, reszta od lochu 5;
## stare postacie - miecz), a w walce: Pociski Arkanów (lecą, ogon za pociskiem, trafiają), Krąg Mocy (rani w kręgu),
## Kule Arkanów (przełącznik, rezerwacja many, ranią przy dotyku), Promień Arkanów (trzymany, mana co sekundę),
## Pieczęcie Wybuchu (wybuch po chwili); kamienie unikalne (odłamki, trwały krąg z premią, druga orbita, emanacja,
## wiązki między pieczęciami).

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	DungeonLevels.enemy_hp = 1.0
	DungeonLevels.enemy_damage = 1.0
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
	_test_data(game)
	_test_start(game)
	await _test_combat(game)
	await _test_unique(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data(game: Node) -> void:
	_check(Weapons.element_of("book") == Elements.ARCANE and Weapons.is_magic("book") and Weapons.is_magic("hydrosphere")
			and not Weapons.is_magic("sword"), "księga: Arkana, broń magiczna (też hydrosfera)")
	_check(Skills.of_weapon("book").size() == 5 and Skills.basic_of("book") == "a_missiles" and Skills.is_toggle("a_orbs")
			and Skills.is_charged("a_beam"), "5 czarów: pociski, kule jako przełącznik, promień trzymany")
	var ok := true
	for id in Skills.of_weapon("book"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id)
	_check(ok, "każdy czar ma kamień unikalny z ikoną i działania 5. i 10. poziomu")
	_check(Items.AFFIXES.has("magic_dmg_pct") and Items.AFFIXES.has("cast_speed_pct"), "nowe premie przedmiotów")
	var gear := {"attack_speed_pct": 50.0, "cast_speed_pct": 20.0}
	_check(is_equal_approx(HeroStats.weapon_speed_mult("book", gear), 1.2) and is_equal_approx(HeroStats.weapon_speed_mult("sword", gear), 1.5),
			"księga przyspiesza od szybkości rzucania, miecz od szybkości ataku")


func _test_start(game: Node) -> void:
	var dir := "user://test_chars/"
	game.chars_dir = dir
	var id: String = game.create_character("Mag", false, "book")
	game.select_character(id)
	_check(game.weapon == "book" and game.start_weapon == "book" and game.weapon_available("book")
			and not game.weapon_available("sword") and not game.weapon_available("bow"), "postać z księgą: miecz i łuk zamknięte")
	_check(game.skills_owned.has("a_missiles") and game.skill_slots[0] == "a_missiles", "Pociski Arkanów pod „Atak”")
	game.best_level = 5
	_check(game.weapon_available("sword") and game.weapon_available("bow"), "od lochu 5 miecz i łuk")
	game.save_game()
	game.load_game()
	_check(game.start_weapon == "book" and game.weapon == "book", "broń startowa w zapisie")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	DirAccess.remove_absolute(dir)
	game.save_path = "user://test_savegame.json"
	game.character = ""
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	_check(game.start_weapon == "sword" and game.weapon == "sword" and game.weapon_available("sword")
			and not game.weapon_available("book"), "stara postać: miecz, księga od lochu 5")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _arena(game: Node) -> Node:
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _book_arena(game: Node) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 20
	game.set_weapon("book")
	game.dev_skills()
	var arena := _arena(game)
	await process_frame
	arena.horde_spawner.set_process(false)
	arena.hero.position = Vector2.ZERO
	return [arena, arena.weapon as ProtoBook]


func _test_combat(game: Node) -> void:
	var setup: Array = await _book_arena(game)
	var arena: Node = setup[0]
	var book: ProtoBook = setup[1]
	var hero: ProtoHero = arena.hero
	_check(book != null and book.element == Elements.ARCANE, "w lochu księga w ręku (Arkana)")
	var a := _goblin(arena, Vector2(80, 0))
	var b := _goblin(arena, Vector2(-70, 30))
	var c := _goblin(arena, Vector2(10, -90))
	await _wait(0.2)
	for g in [a, b, c]:
		g._stunned = 60.0
	# Pociski Arkanów
	hero.mana = 10
	var hp := a.hp + b.hp + c.hp
	book._aim = 0.0
	book._fire_missiles()
	_check(book._missiles.size() == 1 and book._volley.size() == book.missile_count() - 1, "pierwszy pocisk od razu, reszta czeka")
	await _wait(0.3)
	_check(book._missiles.size() == book.missile_count() and book._volley.is_empty() and book.missile_count() >= ProtoBook.MISSILES,
			"pociski wylatują po kolei (%d)" % book._missiles.size())
	_check((book._missiles[0].tail as Line2D).points.size() > 2, "za pociskiem ogon z jego toru")
	await _wait(1.6)
	_check(a.hp + b.hp + c.hp < hp and book._missiles.is_empty(), "pociski trafiają i znikają")
	_check(hero.mana > 10, "Arkana wysysają manę (%d)" % hero.mana)
	# Krąg Mocy
	a.position = Vector2(30, 0)
	b.position = Vector2(-30, 8)
	await process_frame
	hero.mana = hero.max_mana
	hp = a.hp + b.hp
	book._cd.clear()
	book._start("a_circle")
	await _wait(0.3)
	_check(a.hp + b.hp < hp, "Krąg Mocy rani wrogów wokół")
	# Kule Arkanów: przełącznik z rezerwacją many
	_check(book.cast("a_orbs") and book.orbs_on() and hero.summon_reserved > 0 and book._orbs.size() == book._orb_count(),
			"Kule włączone: %d kul, rezerwacja %d many" % [book._orbs.size(), hero.summon_reserved])
	hp = a.hp + b.hp
	await _wait(1.5)
	_check(a.hp + b.hp < hp, "kule ranią dotkniętych wrogów")
	_check(book.cast("a_orbs") and not book.orbs_on() and hero.summon_reserved == 0 and book._orbs.is_empty(), "drugie stuknięcie wyłącza kule")
	# Promień Arkanów (trzymany)
	hero.mana = hero.max_mana
	var mana: int = hero.mana
	hp = a.hp
	book.charge_held = true
	book._start("a_beam")
	_check(book._state == "beam", "promień trwa, gdy trzymasz")
	await _wait(0.1)
	var hand: Vector2 = book._hand_point()
	_check(book._beam != null and book._beam.points[0].distance_to(hand) < 1.0 and hand.y > book._sprite.global_position.y,
			"promień z dłoni postaci (niżej niż księga), błysk w dłoniach")
	_check(book._beam_cast_fx != null and book._beam_hit_fx != null, "efekty na obu końcach promienia")
	await _wait(0.7)
	_check(a.hp < hp or b.hp < b.max_hp, "promień rani")
	_check(hero.mana < mana + 30, "promień zużywa manę")
	book.charge_held = false
	await _wait(0.1)
	_check(book._state == "follow" and book._beam == null, "puszczenie kończy promień")
	# Pieczęcie Wybuchu
	a.position = Vector2(100, 0)
	b.position = Vector2(-100, 0)
	c.position = Vector2(0, 100)
	await process_frame
	hero.mana = hero.max_mana
	book._cd.clear()
	hp = a.hp + b.hp + c.hp
	book._start("a_seals")
	_check(book._seals.size() == 1 and book._seals[0].spots.size() == 3, "pieczęcie pod 3 oddalonymi wrogami")
	var before := a.hp + b.hp + c.hp
	await _wait(0.4)
	_check(a.hp + b.hp + c.hp == before, "przed wybuchem nic")
	await _wait(0.7)
	_check(a.hp + b.hp + c.hp < hp and book._seals.is_empty(), "po chwili wybuch rani")
	arena.queue_free()
	await process_frame


func _test_unique(game: Node) -> void:
	var setup: Array = await _book_arena(game)
	var arena: Node = setup[0]
	var book: ProtoBook = setup[1]
	var hero: ProtoHero = arena.hero
	for id in Skills.of_weapon("book"):
		book.skill_gems[id] = [Gems.unique_of(id)]
	var a := _goblin(arena, Vector2(70, 0))
	var b := _goblin(arena, Vector2(95, 20))
	var c := _goblin(arena, Vector2(-60, 40))
	await _wait(0.2)
	for g in [a, b, c]:
		g._stunned = 60.0
	# odłamki z trafionego
	var far := _goblin(arena, Vector2(160, 0))
	far._stunned = 60.0
	await process_frame
	book._spawn_shards(a, 10.0)
	var aims: Array = book._shards.map(func(x: Dictionary) -> ProtoTarget: return x.target)
	_check(book._shards.size() >= 2 and aims.has(far)
			and (book._shards[0].target as ProtoTarget).center().distance_to(a.center()) >= ProtoBook.SHARD_MIN,
			"odłamki: najpierw w dalszych wrogów (%d)" % book._shards.size())
	await _wait(0.15)
	_check((book._shards[0].tail as Line2D).points.size() > 2, "odłamek z ogonem")
	# trwały krąg z premią
	hero.mana = hero.max_mana
	book._cd.clear()
	book._start("a_circle")
	_check(book._circles.size() == 1 and is_equal_approx(book._circle_buff(), ProtoBook.CIRCLE_BUFF)
			and book.missile_count() > ProtoBook.MISSILES, "krąg zostaje: czary silniejsze, pocisk więcej")
	hero.position = Vector2(300, 300)
	await process_frame
	_check(book._circle_buff() == 1.0, "poza kręgiem bez premii")
	hero.position = Vector2.ZERO
	# druga orbita
	book.cast("a_orbs")
	_check(book._orbs.size() == book._orb_count() * 2, "druga orbita (%d kul)" % book._orbs.size())
	var p0: Vector2 = book.orb_position(0, 0)
	var p1: Vector2 = book.orb_position(1, 0)
	var centre := hero.global_position + Vector2(0, -ProtoWeapon.ORBIT_HEIGHT)
	var d0 := p0 - centre
	var d1 := p1 - centre
	d0.y *= 2.0
	d1.y *= 2.0
	_check(d1.length() > d0.length() * 1.5, "zewnętrzna orbita dalej")
	book.extra_projectiles = 2  # aura Rój Strzyboga
	await process_frame
	_check(book._orbs.size() == (book._orb_count()) * 2 and book._orb_count() == ProtoBook.ORBS + 2,
			"Rój Strzyboga dokłada kule (%d na orbicie)" % book._orb_count())
	book.extra_projectiles = 0
	book.cast("a_orbs")
	# emanacja podczas promienia
	c.position = Vector2(-30, 10)
	await process_frame
	hero.mana = hero.max_mana
	var hpc := c.hp
	book.charge_held = true
	book._start("a_beam")
	await _wait(0.6)
	book.charge_held = false
	_check(c.hp < hpc, "emanacja rani wrogów wokół postaci")
	await _wait(0.1)
	# wiązki między pieczęciami
	a.position = Vector2(80, 0)
	b.position = Vector2(-80, 0)
	var mid := _goblin(arena, Vector2(0, 0))
	await process_frame
	mid._stunned = 60.0
	hero.position = Vector2(0, 120)
	await process_frame
	hero.mana = hero.max_mana
	book._cd.clear()
	var hpm := mid.hp
	book._start("a_seals")
	_check(book._seals.size() == 1 and book._seals[0].links != null, "pieczęcie połączone wiązką")
	await _wait(0.5)
	_check(mid.hp < hpm, "wiązka rani wroga między pieczęciami")
	arena.queue_free()
	await process_frame

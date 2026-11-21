extends SceneTree
## Test mrocznej kosy (21.11.2026, krok 1): dane (żywioł Nawia, loch 25, 3 umiejętności z kamieniami unikalnymi,
## poziomami i ikonami), Nawia (wysysa życie, osłabia ciosy wroga), a w walce: Żniwo (łuk przed postacią, obrót co
## trzeci zamach z 5. poziomu, smuga z 10.), Cięcie Światowida (4 cięcia w kwadrat, potem wybuch na zewnątrz; 10. -
## dwa wybuchy), Pokos (ładowany stożek - im dłużej, tym dalej); kamienie unikalne (fala Nawii po 15 trafieniach,
## 4 kwadraty, rzędy wybuchów od prawej do lewej).

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
	_test_data()
	await _test_nawia(game)
	await _test_combat(game)
	await _test_unique(game)
	await _test_dance_mara(game)
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _test_data() -> void:
	_check(Weapons.element_of("scythe") == Elements.NAWIA and int(Weapons.DATA.scythe.unlock) == 25
			and Weapons.script_of("scythe") == ProtoScythe, "kosa: Nawia, od lochu 25")
	_check(Skills.basic_of("scythe") == "s_reap" and Skills.is_charged("s_mow") and Skills.of_weapon("scythe").size() == 5,
			"Żniwo zwykłym atakiem, Pokos ładowany")
	var ok := true
	for id in Skills.of_weapon("scythe"):
		ok = ok and Gems.UNIQUE.has(id) and Gems.icon_of(Gems.unique_of(id)) != null and Skills.PERKS.has(id) \
				and Skills.icon_of(id) != null and Skills.TAGS.has(id)
	_check(ok, "każda umiejętność ma kamień unikalny z ikoną, działania 5. i 10. poziomu i ikonę")


func _goblin(arena: Node, at: Vector2) -> ProtoGoblin:
	var g := ProtoGoblin.new()
	g.hero = arena.hero
	g.bounds = Rect2(-400, -600, 800, 1200)
	g.power = 50.0
	g.position = at
	arena.get_node("World").add_child(g)
	return g


func _scythe_arena(game: Node) -> Array:
	game.reset_hero()
	game.dev_set_level(20)
	game.best_level = 30
	game.set_weapon("scythe")
	game.dev_skills()
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.horde_spawner.set_process(false)
	arena.hero.position = Vector2.ZERO
	return [arena, arena.weapon as ProtoScythe]


func _stunned(arena: Node, spots: Array) -> Array:
	var out: Array = []
	for p in spots:
		out.append(_goblin(arena, p))
	await _wait(0.2)
	for g in out:
		g._stunned = 60.0
		g.position = spots[out.find(g)]
	await process_frame
	return out


func _hp(list: Array) -> int:
	var s := 0
	for g in list:
		s += g.hp
	return s


func _test_nawia(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	_check(scythe != null and scythe.element == Elements.NAWIA, "w lochu kosa w ręku (Nawia)")
	var gs: Array = await _stunned(arena, [Vector2(40, 0)])
	var g: ProtoGoblin = gs[0]
	g.max_hp = 100000
	g.hp = 100000
	hero.hp = hero.max_hp / 2
	var before: int = hero.hp
	for i in 20:
		scythe._deal(g, 200, hero.global_position, "s_reap")
	_check(hero.hp > before, "Nawia wysysa życie (%d -> %d)" % [before, hero.hp])
	_check(g.is_withered(), "trafiony wróg osłabiony Nawią")
	hero.hp = hero.max_hp
	var hp: int = hero.hp
	g.hit_hero(hero, 100)
	var weak: int = hp - hero.hp
	_check(weak > 0 and weak < 100, "osłabiony wróg zadaje mniej (%d z 100 przed ochroną)" % weak)
	arena.queue_free()
	await process_frame


func _test_combat(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	# Żniwo: przed postacią trafia, za plecami nie
	var gs: Array = await _stunned(arena, [Vector2(40, 0), Vector2(-45, 0)])
	var front: ProtoGoblin = gs[0]
	var back: ProtoGoblin = gs[1]
	var f_hp := front.hp
	var b_hp := back.hp
	scythe._attack()
	await _wait(0.6)
	_check(front.hp < f_hp and back.hp == b_hp, "Żniwo tnie łukiem przed postacią, nie za plecami")
	# 5. poziom: co trzeci zamach - pełny obrót
	scythe.skill_levels["s_reap"] = 5
	scythe.reap_count = 2
	b_hp = back.hp
	scythe._state = "follow"
	scythe._attack()
	_check(scythe._full_spin, "5. poziom: trzeci zamach to obrót")
	await _wait(0.7)
	_check(back.hp < b_hp, "obrót trafia też za plecami")
	# 10. poziom: smuga Nawii
	scythe.skill_levels["s_reap"] = 10
	scythe._state = "follow"
	scythe._attack()
	await _wait(0.45)
	_check(scythe._trails.size() == 1, "10. poziom: zamach zostawia smugę")
	f_hp = front.hp
	await _wait(0.5)
	_check(front.hp < f_hp, "smuga rani")
	await _wait(1.0)
	_check(scythe._trails.is_empty(), "smuga gaśnie")
	# Cięcie Światowida: wróg na boku obrywa od cięcia, wróg za bokiem - od wybuchu i jest odpychany
	front.position = Vector2(0, -50)  # na górnym łuku (wygięty na zewnątrz)
	back.position = Vector2(0, 60)  # za dolnym bokiem
	await process_frame
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	f_hp = front.hp
	b_hp = back.hp
	scythe._start("s_square")
	_check(scythe._squares.size() == 1, "kwadrat Światowida")
	await _wait(0.33)
	_check(front.hp < f_hp and back.hp == b_hp, "cięcia boków ranią stojących na nich, wybuchu jeszcze nie ma")
	_check(scythe._squares[0].lines.size() == 12, "4 cięcia po łuku (dym, środek, krawędź) zostają do wybuchu")
	await _wait(0.4)
	_check(back.hp < b_hp, "bok wybucha na zewnątrz")
	# 10. poziom: dwa wybuchy
	scythe.skill_levels["s_square"] = 10
	await _wait(0.6)
	scythe._cd.clear()
	scythe._state = "follow"
	hero.mana = hero.max_mana
	scythe._start("s_square")
	await _wait(0.85)
	_check(scythe._squares.size() == 1 and scythe._squares[0].bursts == 1, "10. poziom: po pierwszym wybuchu czeka drugi")
	await _wait(0.5)
	_check(scythe._squares.is_empty(), "drugi wybuch i koniec")
	# Pokos: krótko trzymany sięga blisko, długo - daleko
	front.position = Vector2(100, 0)
	back.position = Vector2(400, 400)
	await process_frame
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	f_hp = front.hp
	scythe.charge_held = true
	scythe._start("s_mow")
	_check(scythe._state == "mow_charge" and scythe._mow_poly != null, "Pokos się ładuje, stożek na ziemi")
	await _wait(0.1)
	scythe.charge_held = false
	await _wait(0.1)
	_check(front.hp == f_hp and scythe._state == "follow", "krótkie ładowanie - wróg poza stożkiem")
	await _wait(0.2)
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.charge_held = true
	scythe._start("s_mow")
	await _wait(1.5)
	var reach: float = scythe._mow_shape(1.0).y
	scythe.charge_held = false
	await _wait(0.1)
	_check(front.hp < f_hp and reach >= 100.0, "pełne ładowanie sięga daleko (%d px)" % reach)
	arena.queue_free()
	await process_frame


func _test_unique(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	for id in Skills.of_weapon("scythe"):
		scythe.skill_gems[id] = [Gems.unique_of(id)]
	var gs: Array = await _stunned(arena, [Vector2(35, 0), Vector2(30, 20), Vector2(30, -20), Vector2(-70, 0)])
	var far: ProtoGoblin = gs[3]
	# Żniwiarz: po 15 trafieniach fala dookoła (trafia też wroga za plecami)
	scythe.reap_hits = ProtoScythe.REAP_CHARGE - 3
	var far_hp := far.hp
	scythe._attack()
	await _wait(0.6)
	_check(scythe.reap_hits < 3 and far.hp < far_hp, "Kamień Żniwiarza: fala Nawii dookoła")
	# Czterech Stron: 4 kwadraty z widmowymi kosami
	hero.mana = hero.max_mana
	scythe._cd.clear()
	scythe._state = "follow"
	scythe._start("s_square")
	_check(scythe._squares.size() == 4 and scythe._squares.all(func(s: Dictionary) -> bool: return s.ghost != null),
			"Kamień Czterech Stron: 4 kwadraty, widmowe kosy")
	var centers: Array = scythe._squares.map(func(s: Dictionary) -> Vector2: return s.center - hero.global_position)
	var off: float = scythe._squares[0].half * ProtoScythe.SQUARE_SPREAD
	var near_corner: float = INF
	for sq in scythe._squares:
		for side in ProtoScythe.square_sides(sq.center, sq.half, sq.rot):
			near_corner = minf(near_corner, (side[0] as Vector2).distance_to(hero.global_position))
	_check(centers.any(func(c: Vector2) -> bool: return c.is_equal_approx(Vector2(0, -off))) and is_equal_approx(scythe._squares[0].rot, PI / 4.0)
			and absf(near_corner - (off - scythe._squares[0].half * sqrt(2.0))) < 0.5 and near_corner > 20.0,
			"kwadraty po 4 stronach, rogiem do postaci, oddalone (najbliższy róg %d px)" % near_corner)
	await _wait(1.0)
	# Rzędy Nawii: fala wybuchów od lewej do prawej krawędzi stożka
	scythe._mow_rows(hero.global_position, 0.0, scythe._mow_shape(1.0), 1.0)
	var first: Array = scythe._mow_blasts.filter(func(b: Dictionary) -> bool: return b.row == 0)
	_check(first.size() >= 3 and first[0].at.y < first[-1].at.y, "rząd od lewej (góra ekranu przy celowaniu w prawo) do prawej")
	var early: Array = scythe._mow_blasts.filter(func(b: Dictionary) -> bool: return b.t < 0.2)
	_check(early.size() >= 3 and early.all(func(b: Dictionary) -> bool: return b.at.y < hero.global_position.y),
			"na początku wybuchają wszystkie rzędy przy lewej krawędzi (fala w bok, nie od postaci)")
	var shape: Vector3 = scythe._mow_shape(1.0)
	var rows: Array = []
	for b in scythe._mow_blasts:
		if not rows.has(b.row):
			rows.append(b.row)
	var edge := first.map(func(b: Dictionary) -> float: return absf(angle_difference(0.0, (b.at - hero.global_position).angle())))
	_check(rows.size() >= 5 and rows.size() == ProtoScythe.mow_row_count(shape) and edge.max() > shape.z * 0.9,
			"pełne ładowanie: %d rzędów, wybuchy do krawędzi stożka" % rows.size())
	var n: int = scythe._mow_blasts.size()
	await _wait(1.0)
	_check(scythe.mow_blasts_done >= n and scythe._mow_blasts.is_empty(), "wszystkie wybuchy rzędów (%d)" % n)
	# arkusz wybuchu Światowida: każda klatka coś rysuje (źle pocięty arkusz zostawiał tylko pierwszą kreskę)
	var sheet: Image = ProtoScythe.SQUARE_BURST_FX.get_image()
	var fw := sheet.get_width() / ProtoScythe.SQUARE_BURST_FRAMES
	var mid_frame := sheet.get_region(Rect2i(fw * 6, 0, fw, sheet.get_height()))
	_check(mid_frame.get_used_rect().size.y > 20,
			"wybuch Światowida ma narysowane klatki (fala w połowie animacji)")
	# duży obszar: wybuchy fali żyją prawie wszystkie naraz - muszą się zmieścić w limicie efektów (inaczej znikają)
	scythe.area_bonus = 150.0
	scythe._mow_rows(hero.global_position, 0.0, scythe._mow_shape(1.0), 1.0)
	var big: int = scythe._mow_blasts.size()
	_check(big <= ProtoScythe.MOW_BLAST_CAP - 20, "duży obszar: %d wybuchów mieści się w limicie efektów" % big)
	await _wait(1.4)
	scythe.area_bonus = 0.0
	_check(scythe._mow_blasts.is_empty(), "duży obszar: wszystkie wybuchy wystrzeliły (%d)" % big)
	arena.queue_free()
	await process_frame


func _test_dance_mara(game: Node) -> void:
	var setup: Array = await _scythe_arena(game)
	var arena: Node = setup[0]
	var scythe: ProtoScythe = setup[1]
	var hero: ProtoHero = arena.hero
	var gs: Array = await _stunned(arena, [Vector2(60, 0), Vector2(150, 0), Vector2(-120, 80)])
	var a: ProtoGoblin = gs[0]
	var b: ProtoGoblin = gs[1]
	var c: ProtoGoblin = gs[2]
	# Taniec Marzanny: kroki ku wrogowi, wir rani, przedłużenie stuknięciem, końcowe cięcie odpycha
	hero.mana = hero.max_mana
	var a_hp := a.hp
	_check(scythe.cast("s_dance") and scythe._state == "dance" and hero.leaping(), "Taniec: kroki naprzód")
	await _wait(0.3)
	_check(scythe.cooldown_left("s_dance") == 0.0, "w trakcie tańca przycisk gotowy do przedłużenia")
	var mana: int = hero.mana
	_check(scythe.cast("s_dance") and hero.mana < mana and hero.mana > mana - scythe.mana_cost("s_dance"),
			"przedłużenie za pół many")
	await _wait(0.4)
	_check(scythe.dance_uses == 2 and scythe._dance_time == ProtoScythe.DANCE_TIME_FAST, "drugi taniec szybszy")
	_check(a.hp < a_hp and hero.global_position.x > 40.0, "wir rani po drodze, postać przeszła do przodu")
	var b_pos := b.global_position
	await _wait(0.4)
	_check(scythe._state == "follow" and scythe.cooldown_left("s_dance") > 0.0, "po drugim tańcu końcowe cięcie i odnowienie")
	_check(b.global_position.distance_to(b_pos) > 1.0 or b.hp < b.max_hp, "końcowe cięcie trafia i odpycha")
	# cięcia wiru na stałych okręgach, rosną z obszarem umiejętności (też na ekranie - uwaga autora)
	var r0: float = scythe._dance_radius()
	scythe.area_bonus = 100.0
	_check(scythe._dance_radius() > r0 * 1.9, "obszar powiększa wir Tańca")
	var world: Node = scythe.get_parent()
	scythe._dance_cut(scythe._dance_radius())
	var holder: Node2D = world.get_child(world.get_child_count() - 1)
	var cut: Node2D = holder.get_child(0)
	_check(absf(cut.scale.x) > 1.5 and ProtoScythe.DANCE_RINGS.any(func(r: Array) -> bool: return is_equal_approx(holder.scale.y, r[1])),
			"cięcie na stałym okręgu, większe przy większym obszarze (%.2f)" % absf(cut.scale.x))
	scythe.area_bonus = 0.0
	# bez przedłużenia - cięcie po oknie
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.cast("s_dance")
	await _wait(ProtoScythe.DANCE_TIME + 0.1)
	_check(scythe._state == "dance_wait", "po krokach chwila na przedłużenie")
	await _wait(ProtoScythe.DANCE_WINDOW + 0.1)
	_check(scythe._state == "follow" and scythe.dance_uses == 0, "bez przedłużenia - cięcie po chwili")
	# Kamień Wirującego Ostrza
	scythe.skill_gems["s_dance"] = [Gems.unique_of("s_dance")]
	scythe._cd.clear()
	hero.mana = hero.max_mana
	for g in gs:
		g.position = hero.global_position + (g.position - hero.global_position).limit_length(90.0)
	scythe.cast("s_dance")
	await _wait(ProtoScythe.DANCE_TIME + ProtoScythe.DANCE_WINDOW + 0.2)
	_check(scythe._blades.size() == 1, "kamień: wirujące ostrze wylatuje")
	var hp_all := a.hp + b.hp + c.hp
	await _wait(ProtoScythe.BLADE_TIME + 0.2)
	_check(scythe._blades.is_empty() and a.hp + b.hp + c.hp < hp_all, "ostrze leci od wroga do wroga i wybucha")
	# Postać Mary: nietykalna chmura, klątwa na dotkniętych, wybuch po końcu
	scythe._cd.clear()
	hero.mana = hero.max_mana
	hero.position = Vector2(-200, -200)
	a.position = Vector2(-150, -200)
	b.position = Vector2(-100, -200)
	await process_frame
	_check(scythe.cast("s_mara") and scythe._state == "mara" and hero.form_speed > 1.0 and scythe._clouds.size() == 1,
			"Mara: forma chmury, szybciej")
	var hp: int = hero.hp
	a.hit_hero(hero, 50)
	_check(hero.hp == hp, "w formie chmury nic nie rani")
	hero.joystick.vector = Vector2.RIGHT  # palec na gałce - chmura mknie w prawo przez obu wrogów
	await _wait(0.6)
	hero.joystick.vector = Vector2.ZERO
	_check(hero.global_position.x > -100.0, "chmura szybka (%d px)" % (hero.global_position.x + 200.0))
	_check(scythe.cursed.has(a) and scythe.cursed.has(b), "przelot przez wrogów - klątwa (%d)" % scythe.cursed.size())
	var cloud: Node = scythe._clouds[0].node
	_check(cloud._tail.get_point_count() > 3, "za chmurą ogon z jej toru")
	a_hp = a.hp
	_check(scythe.cooldown_left("s_mara") == 0.0 and scythe.cast("s_mara"), "drugie stuknięcie kończy formę")
	_check(a.hp < a_hp and scythe.cursed.is_empty() and hero.form_speed == 1.0 and scythe._state == "follow",
			"pod przeklętymi wybuch, postać wraca")
	# Kamień Bliźniaczych Mar: dwie chmury same przeklinają
	scythe.skill_gems["s_mara"] = [Gems.unique_of("s_mara")]
	scythe._cd.clear()
	hero.mana = hero.max_mana
	scythe.cast("s_mara")
	_check(scythe._clouds.size() == 3, "kamień: dwie dodatkowe chmury")
	await _wait(1.5)
	_check(scythe.cursed.size() >= 2, "bliźniacze chmury same przeklinają wrogów (%d)" % scythe.cursed.size())
	await _wait(1.5)
	_check(scythe.mara_left <= 0.0 and scythe._state == "follow" and not scythe.mara_on, "forma kończy się sama")
	_check(hero._sprite.modulate.a == 1.0 and scythe._clouds.is_empty() and hero.form_speed == 1.0,
			"po końcu czasu postać widoczna, chmury znikają (błąd zgłoszony przez autora)")
	arena.queue_free()
	await process_frame

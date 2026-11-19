extends SceneTree
## Test trzeciego lochu - Katakumby (Dungeons.CATACOMBS, 15.11.2026): od 21. poziomu, potwory (szkielet rozpada się
## w kupkę kości i wstaje z połową zdrowia, kupkę niszczy trafienie; szkielet łucznik strzela strzałą Nawii;
## rycerz-szkielet tnie w wachlarzu przed sobą) i boss Nekromanta (kule Nawii, kościany krąg z luką, wyssanie
## życia, przywołanie szkieletów).

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
	_check(Dungeons.for_level(21) == Dungeons.CATACOMBS and ProtoHorde.make_monster(Dungeons.CATACOMBS, "goblin") is ProtoSkeleton
			and ProtoHorde.make_monster(Dungeons.CATACOMBS, "archer") is ProtoSkeletonArcher
			and ProtoHorde.make_monster(Dungeons.CATACOMBS, "brute") is ProtoSkeletonKnight,
			"od 21: Katakumby - szkielet, szkielet łucznik, rycerz-szkielet")
	var t := ProtoTelegraph.new()
	t.radius = 40.0
	t.arc = deg_to_rad(120.0)
	t.angle = 0.0
	root.add_child(t)
	t.global_position = Vector2.ZERO
	_check(t.contains(Vector2(30, 0)) and t.contains(Vector2(15, 10)) and not t.contains(Vector2(-30, 0))
			and not t.contains(Vector2(60, 0)), "wachlarz: trafia przed sobą, nie z tyłu i nie za daleko")
	t.queue_free()
	await _test_monsters(game)
	await _test_necromancer(game)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


func _arena(game: Node, level: int) -> Node:
	game.reset_hero()
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	return arena


func _test_monsters(game: Node) -> void:
	var arena := _arena(game, 21)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000  # na 21. poziomie cios zabiłby postać 1. poziomu (nieśmiertelność wróciłaby jej pełne zdrowie)
	hero.hp = hero.max_hp
	_check(arena.climate == Dungeons.CATACOMBS and arena.summon_button.text == "Przyzwij Nekromantę", "poziom 21: Katakumby")
	# szkielet: kupka kości, wstaje z połową zdrowia, drugi raz ginie na dobre
	var s: ProtoSkeleton = horde.spawn_at(hero.position + Vector2(120, 0), "goblin")
	await process_frame
	var kills := horde.kills
	s.take_damage(100000, hero.global_position)
	_check(s.is_pile() and s.alive() and horde.kills == kills, "szkielet rozpada się w kupkę (nie liczy się jako pokonany)")
	await _wait(ProtoSkeleton.PILE_TIME + ProtoSkeleton.RISE_TIME + 0.2)
	_check(not s.is_pile() and s.revived and s.hp == roundi(ProtoSkeleton.SKELETON_HP * horde.power * s.hp_mult * ProtoSkeleton.REVIVE_HP),
			"po chwili wstaje z połową zdrowia (%d)" % s.hp)
	s.take_damage(100000, hero.global_position)
	_check(not s.alive() and horde.kills == kills + 1, "drugi raz ginie na dobre")
	var s2: ProtoSkeleton = horde.spawn_at(hero.position + Vector2(120, 30), "goblin")
	await process_frame
	s2.take_damage(100000, hero.global_position)
	s2.take_damage(1, hero.global_position)
	_check(not s2.alive() and horde.kills == kills + 2, "trafienie kupki niszczy szkielet od razu")
	# łucznik: strzała Nawii
	var a: ProtoSkeletonArcher = horde.spawn_at(hero.position + Vector2(100, 0), "archer")
	await process_frame
	a._cooldown = 0.0
	hero.max_hp = 100000  # mocniejsze potwory (17.11.2026) zabijałyby postać - nieśmiertelność leczy do pełna
	hero.hp = hero.max_hp
	var nawia := false
	for i in 60:
		await _wait(0.05)
		for c in arena.get_node("World").get_children():
			if c is ProtoArrow and c.element == Elements.NAWIA:
				nawia = true
		if hero.hp < hero.max_hp:
			break
	_check(nawia and hero.hp < hero.max_hp, "szkielet łucznik strzela strzałą Nawii")
	a.queue_free()
	# rycerz: wachlarz przed nim, z tyłu bezpiecznie
	await _wait(0.4)
	hero._invulnerable = 0.0
	var k: ProtoSkeletonKnight = horde.spawn_at(hero.position + Vector2(25, 0), "brute")
	await process_frame
	k._cooldown = 0.0
	hero.max_hp = 100000  # awans z zabitych szkieletów przywrócił zwykłe zdrowie
	hero.hp = hero.max_hp
	await _wait(0.15)
	_check(k._state == "attack" and is_instance_valid(k._telegraph) and k._telegraph.arc > 0.0
			and k._telegraph.contains(hero.global_position), "rycerz: wachlarz w stronę postaci")
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp == hero.max_hp - roundi(ProtoSkeletonKnight.SWEEP_DAMAGE * horde.power * DungeonLevels.MONSTER_DAMAGE), "zamach rani w wachlarzu (%d / %d, %s)" % [hero.hp, hero.max_hp, k._state])
	await _wait(0.6)
	hero._invulnerable = 0.0
	k._cooldown = 0.0
	hero.position = k.position + Vector2(-25, 0)
	await _wait(0.15)
	if k._state == "attack":
		hero.position = k.position + Vector2(25, 0) - (k._telegraph.position - k.position) - Vector2.from_angle(k._telegraph.angle) * 30.0
	hero.hp = hero.max_hp
	if k._state == "attack" and is_instance_valid(k._telegraph):
		hero.position = k.position - Vector2.from_angle(k._telegraph.angle) * Vector2(20, 12)
		_check(not k._telegraph.contains(hero.global_position), "za plecami rycerza poza wachlarzem")
	await _wait(ProtoGoblinBrute.SLAM_WARN)
	_check(hero.hp == hero.max_hp, "zajście od tyłu ratuje")
	arena.queue_free()
	await process_frame


func _test_necromancer(game: Node) -> void:
	var arena := _arena(game, 22)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	horde.running = false
	arena.weapon.auto_attack = false
	hero.immortal = true
	hero.max_hp = 100000  # na 21. poziomie cios zabiłby postać 1. poziomu (nieśmiertelność wróciłaby jej pełne zdrowie)
	hero.hp = hero.max_hp
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var n := arena.chief as ProtoNecromancer
	_check(n != null and arena.boss_box.get_child(0).text == "Nekromanta", "przyzwany Nekromanta")
	n.passive = true
	await _wait(ProtoChief.ENTER_TIME + 0.2)
	# kule Nawii
	hero.position = n.position + Vector2(0, 90)
	n.start_attack("bolts")
	await _wait(ProtoNecromancer.BOLT_WARN + 0.05)
	var bolts := 0
	for c in arena.get_node("World").get_children():
		if c is ProtoArrow and c.nawia and c.element == Elements.NAWIA:
			bolts += 1
	_check(bolts == ProtoNecromancer.BOLTS, "wachlarz %d kul Nawii" % bolts)
	await _wait(1.5)
	# kościany krąg: luka i środek
	hero.position = n.position + Vector2(0, 90)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	n.start_attack("ring")
	_check(n.ring_pending() == ProtoNecromancer.RING_COUNT - ProtoNecromancer.RING_GAP + 1, "krąg: kolce z luką i środek (%d)" % n.ring_pending())
	await _wait(ProtoNecromancer.RING_CENTER_WARN + 0.1)
	_check(hero.hp < hero.max_hp and n.ring_pending() == 0, "stojąc w środku obrywasz (%d, %d, %s)" % [hero.hp, n.ring_pending(), hero.position])
	await _wait(0.5)
	hero.position = n.position + Vector2(0, 90)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	n.start_attack("ring")
	hero.position += Vector2(0, 90)  # wybiegnięcie przez lukę (z dala od Nekromanty)
	await _wait(ProtoNecromancer.RING_CENTER_WARN + 0.1)
	_check(hero.hp == hero.max_hp, "ucieczka przez lukę ratuje")
	# wyssanie życia: leczy Nekromantę, wyjście z koła przerywa
	await _wait(0.5)
	n.hp = n.max_hp - 500
	hero.position = n.position + Vector2(0, 50)
	hero.hp = hero.max_hp
	hero._invulnerable = 0.0
	n.start_attack("drain")
	await _wait(ProtoNecromancer.DRAIN_START + 0.9)
	_check(n.draining() and hero.hp < hero.max_hp and n.hp > n.max_hp - 500, "wiązka wysysa zdrowie i leczy Nekromantę")
	_check(n._beam_fx != null and n._beam_fx.get_child_count() >= 1 and n.aura_active(), "drobinki płyną wiązką, za Nekromantą dym Nawii")
	hero.position = n.position + Vector2(0, 150)
	await _wait(0.1)
	_check(not n.draining() and n.state == "recover", "wyjście z koła przerywa wiązkę")
	_check(n._beam_fx == null and not n.aura_active(), "drobinki i dym znikają z wiązką")
	# przywołanie szkieletów
	await _wait(0.8)
	var before := horde.count(ProtoSkeleton)
	n.start_attack("summon")
	await _wait(ProtoNecromancer.SUMMON_TIME + 0.1)
	_check(horde.count(ProtoSkeleton) == before + ProtoNecromancer.SUMMON_COUNT, "z ziemi wstają szkielety")
	n.take_damage(10000000, hero.global_position)
	await process_frame
	_check(not n.alive() and arena.phase == "loot", "Nekromanta pada, skrzynia")
	arena.queue_free()
	await process_frame

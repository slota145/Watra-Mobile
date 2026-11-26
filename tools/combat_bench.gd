extends SceneTree
## Pomiar wydajności ciężkiej walki (prośba autora 20.11.2026, przy Gęstszej Hordzie do +60%): tłum potworów,
## katana z Błyskiem Peruna co 0,25 s i pozostałymi umiejętnościami, wszystkie aury, 3 talizmany na 10. poziomie,
## wszystkie modyfikatory lochu. Mierzy średni i najgorszy czas logiki w klatce (wszystkie _process i _physics_process,
## bez rysowania) oraz liczbę węzłów. Telefon ma na całą klatkę 16,7 ms, a jego procesor jest kilka razy wolniejszy.
## Użycie: godot --headless --path . -s res://tools/combat_bench.gd -- [poziom lochu] [potwory] [tryb: full|plain]
##   [talizmany po przecinku]
## Przykład: godot --headless --path . -s res://tools/combat_bench.gd -- 45 150 full kaboom,thunder,shockwave
## Zmienne do szukania winnego (wyłączają część): NO_AURA, ONLY_AURA=perun,szron, NO_TAL, NO_MODS, NO_CAST, NO_AUTO.
## Inna broń i umiejętność: WEAPON=bow SKILL=b_seeker EVERY=0.1 (co ile s), ONLY_SKILL=1 (bez reszty umiejętności),
## PROJ=3 (dodatkowe pociski na stałe, np. Poszukująca 10. poziomu: 2 + 3 = 5 strzał naraz).
## SPEED=200 - szybkość ataku i rzucania z przedmiotów (%, jak sufit Items.CAPS - pomiar przy pełnej szybkości).
## Na końcu wypisuje najliczniejsze węzły (Label<proto_goblin.gd - liczby obrażeń nad potworami itd.).
## Wyniki 20.11.2026 (poziom 5, 136 potworów): przed poprawkami 20 ms średnio, najgorsza klatka 198 ms; po nich ok. 4,3 ms
## i 14 ms (wspólny limit dźwięków trafień i liczb obrażeń - ProtoTarget, spis celów raz na klatkę - ProtoWeapon).

## Mierzy czas od pierwszego do ostatniego _process w klatce (dwa węzły o skrajnych priorytetach).
class Stamp extends Node:
	var first := false
	var t0 := 0
	var other: Stamp
	var times: Array[int] = []

	func _process(_d: float) -> void:
		if first:
			t0 = Time.get_ticks_usec()
		else:
			times.append(Time.get_ticks_usec() - other.t0)


class PhysStamp extends Node:
	var first := false
	var t0 := 0
	var other: PhysStamp
	var times: Array[int] = []

	func _physics_process(_d: float) -> void:
		if first:
			t0 = Time.get_ticks_usec()
		else:
			times.append(Time.get_ticks_usec() - other.t0)


func _initialize() -> void:
	root.get_node("Game").save_path = "user://bench_savegame.json"
	DungeonLevels.enemy_hp = 1000.0  # tłum ma przeżyć cały pomiar
	_run.call_deferred()


func _stats(times: Array[int]) -> String:
	if times.is_empty():
		return "-"
	var sorted := times.duplicate()
	sorted.sort()
	var total := 0
	for t in times:
		total += t
	var slow := times.filter(func(x: int) -> bool: return x > 16700).size()
	return "śr. %.2f ms, 95%% %.2f ms, max %.2f ms, klatek ponad 16,7 ms: %d" % [total / 1000.0 / times.size(),
			sorted[int(sorted.size() * 0.95)] / 1000.0, sorted[-1] / 1000.0, slow]


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var level := int(args[0]) if args.size() > 0 else 45
	var count := int(args[1]) if args.size() > 1 else 150
	var full := (args[2] if args.size() > 2 else "full") == "full"
	var tal: Array = (args[3] if args.size() > 3 else "kaboom,thunder,shockwave").split(",")
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	game.reset_hero()
	game.dev_set_level(60)
	game.best_level = level
	game.dungeon_level = level
	game.dev_immortal = true
	var weapon_id := OS.get_environment("WEAPON") if OS.has_environment("WEAPON") else "katana"
	var spam := OS.get_environment("SKILL") if OS.has_environment("SKILL") else "k_flash"
	var every := float(OS.get_environment("EVERY")) if OS.has_environment("EVERY") else 0.25
	var others := not OS.has_environment("ONLY_SKILL")
	var proj := int(OS.get_environment("PROJ")) if OS.has_environment("PROJ") else -1
	game.set_weapon(weapon_id)
	if OS.has_environment("SPEED"):
		var sp := float(OS.get_environment("SPEED"))
		game.dev_stats = {"attack_speed_pct": sp, "cast_speed_pct": sp}
	game.dev_skills()
	for id in Skills.of_weapon(weapon_id):
		game.skill_levels[id] = 10
	if full:
		for i in 10:
			game.dev_auras()
			game.dev_talismans()
		game.auras_on = [] if OS.has_environment("NO_AURA") else (OS.get_environment("ONLY_AURA").split(",") if OS.has_environment("ONLY_AURA") else Auras.ORDER.duplicate())
		for i in 3:
			game.talisman_slots[i] = tal[i] if i < tal.size() and not OS.has_environment("NO_TAL") else ""
		game.dungeon_mods = [] if OS.has_environment("NO_MODS") else DungeonMods.ORDER.duplicate()
		game.tree = {"horde": 15}
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var weapon: ProtoWeapon = arena.weapon
	hero.immortal = true
	weapon.auto_attack = not OS.has_environment("NO_AUTO")
	horde.running = false
	for i in count:
		horde.spawn_at(hero.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 220.0))
	for i in 30:
		await process_frame
	var a := Stamp.new()
	a.first = true
	a.process_priority = -100000
	var b := Stamp.new()
	b.other = a
	b.process_priority = 100000
	var pa := PhysStamp.new()
	pa.first = true
	pa.process_physics_priority = -100000
	var pb := PhysStamp.new()
	pb.other = pa
	pb.process_physics_priority = 100000
	for n in [a, b, pa, pb]:
		root.add_child(n)
	var casts := 0
	var deaths := 0
	var t := 0.0
	var nodes_max := 0
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 6000:
		await process_frame
		t += 1.0 / 60.0
		hero.mana = hero.mana_cap()
		nodes_max = maxi(nodes_max, root.get_tree().get_node_count())
		if proj >= 0:
			weapon.extra_projectiles = proj
		if t >= every and not OS.has_environment("NO_CAST"):
			t = 0.0
			weapon.reset_cooldowns()
			if weapon.cast(spam):
				casts += 1
			for id in game.skill_slots if others else []:
				if id != "" and id != spam:
					weapon.cast(id)
		# tłum ma zostać - dosypuje, gdy ktoś padnie
		deaths += maxi(count - horde._alive, 0)
		for i in maxi(count - horde._alive, 0):
			horde.spawn_at(hero.position + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 220.0))
	var kinds := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var sc: Script = n.get_script()
		var key: String = sc.resource_path.get_file() if sc and sc.resource_path != "" else n.get_class()
		if key == "Label" or key == "Sprite2D":
			var p := n.get_parent()
			var ps: Script = p.get_script() if p else null
			key += "<" + (ps.resource_path.get_file() if ps and ps.resource_path != "" else (p.get_class() + ":" + String(p.name).left(12) if p else "?"))
		kinds[key] = kinds.get(key, 0) + 1
		stack.append_array(n.get_children())
	var top := kinds.keys()
	top.sort_custom(func(x, y) -> bool: return kinds[x] > kinds[y])
	print("  węzły: %s" % ", ".join(top.slice(0, 14).map(func(k) -> String: return "%s %d" % [k, kinds[k]])))
	print("  zabitych: %d" % deaths)
	print("POZIOM %d, POTWORY %d, %s, talizmany %s, aury %d, modyfikatory %d" % [level, count,
			"pełna walka" if full else "bez dodatków", game.talisman_slots, game.auras_on.size(), game.dungeon_mods.size()])
	print("  _process: %s" % _stats(b.times))
	print("  _physics: %s" % _stats(pb.times))
	print("  %s %s co %.2f s: %d użyć, węzłów najwięcej: %d, klatek: %d" % [weapon_id, spam, every, casts, nodes_max, b.times.size()])
	arena.queue_free()
	await process_frame
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

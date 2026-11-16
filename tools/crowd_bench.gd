extends SceneTree
## Pomiar wydajności tłumu: N potworów wokół postaci, średni czas logiki gry w klatce (wszystkie _process, bez rysowania).
## Telefon ma na całą klatkę 16,7 ms (60 klatek/s), a jego procesor jest kilka razy wolniejszy niż komputer w chmurze.
## Użycie: godot --headless --path . -s res://tools/crowd_bench.gd -- [poziom lochu] [liczby potworów...]
## Przykład: godot --headless --path . -s res://tools/crowd_bench.gd -- 1 70 120 150

## Mierzy czas od pierwszego do ostatniego _process w klatce (dwa węzły o skrajnych priorytetach).
class Stamp extends Node:
	var first := false
	var t0 := 0
	var other: Stamp
	var total := 0
	var frames := 0

	func _process(_d: float) -> void:
		if first:
			t0 = Time.get_ticks_usec()
		else:
			total += Time.get_ticks_usec() - other.t0
			frames += 1


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var level := int(args[0]) if args.size() > 0 else 1
	var counts: Array[int] = []
	for i in range(1, args.size()):
		counts.append(int(args[i]))
	if counts.is_empty():
		counts = [70, 120, 150]
	var game: Node = root.get_node("Game")
	game.best_level = level
	game.dungeon_level = level
	for n in counts:
		var arena: Node = load("res://scenes/horde.tscn").instantiate()
		root.add_child(arena)
		await process_frame
		var hero: ProtoHero = arena.hero
		var horde: ProtoHorde = arena.horde_spawner
		hero.immortal = true
		arena.weapon.auto_attack = false
		horde.running = false
		for i in n:
			horde.spawn_at(hero.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 200.0))
		for i in 30:
			await process_frame
		var a := Stamp.new()
		a.first = true
		a.process_priority = -100000
		var b := Stamp.new()
		b.other = a
		b.process_priority = 100000
		root.add_child(a)
		root.add_child(b)
		await create_timer(3.0).timeout
		print("POTWORY %d: logika %.2f ms na klatkę" % [n, b.total / 1000.0 / maxi(b.frames, 1)])
		a.queue_free()
		b.queue_free()
		arena.queue_free()
		await process_frame
	quit()

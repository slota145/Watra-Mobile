extends SceneTree
## Zrzuty po poprawkach z pierwszej wyprawy (17.11.2026): okno zwycięstwa z wieloma liniami (odblokowania, łup)
## i piorun z kamienia (niebieski zygzak z poświatą, niebieskie liczby).
## Użycie: SCRIPT=tools/result_shots.gd tools/screenshot.sh <prefiks> [RESOLUTION]
## Pliki: <prefiks>_1_wynik.png, _2_piorun.png

var _prefix := "/tmp/wynik"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.best_level = 4
	game.dungeon_level = 4
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	var hero: ProtoHero = arena.hero
	hero.immortal = true
	arena.horde_spawner.running = false
	var horde: ProtoHorde = arena.horde_spawner
	var targets: Array = []
	for p in [Vector2(40, -20), Vector2(80, -40), Vector2(90, 20), Vector2(60, 50)]:
		targets.append(horde.spawn_at(hero.position + p))
	await create_timer(0.2).timeout
	arena.weapon._chain_from(targets[0], 25)
	await create_timer(0.05).timeout
	await _shot("2_piorun")
	arena.result.show_victory(4, 87, 5, 264, 97.0)
	arena.result.add_unlock_lines(Unlocks.on_beat(4))
	arena.result.add_xp_lines(904, 0)
	arena.result.add_loot_lines(6, 3, 17)
	await create_timer(0.3).timeout
	await _shot("1_wynik")
	DirAccess.remove_absolute(game.save_path)
	quit()

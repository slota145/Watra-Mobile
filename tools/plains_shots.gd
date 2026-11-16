extends SceneTree
## Zrzuty Górskich równin (Dungeons.PLAINS): ptakoludzie (doskok wojownika z pasem, miotacze, szaman z kołem pioruna),
## potem Gromoskrzydły - burza, nurkowanie i podmuch.
## Użycie: SCRIPT=tools/plains_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_szaman.png, _3_burza.png, _4_nurkowanie.png, _5_podmuch.png

var _prefix := "/tmp/rowniny"


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
	game.best_level = 31
	game.dungeon_level = 31
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, 80), Vector2(-20, -90)]:
		horde.spawn_at(hero.position + p)
	var leaper := horde.spawn_at(hero.position + Vector2(90, -10)) as ProtoBirdman
	leaper._leap_cooldown = 0.0
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(0.4).timeout
	await _shot("1_tlum")
	var s := horde.spawn_at(hero.position + Vector2(-80, 60), "brute") as ProtoGoblinBrute
	s._cooldown = 0.0
	await create_timer(0.6).timeout
	await _shot("2_szaman")
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var e := arena.chief as ProtoStormEagle
	e.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.2).timeout
	hero.position = e.position + Vector2(10, 90)
	e.start_attack("storm")
	await create_timer(1.3).timeout
	await _shot("3_burza")
	await create_timer(2.5).timeout
	e.start_attack("dive")
	await create_timer(0.6).timeout
	await _shot("4_nurkowanie")
	await create_timer(1.5).timeout
	hero.position = e.position + Vector2(10, 30)
	e.start_attack("gust")
	await create_timer(1.15).timeout
	await _shot("5_podmuch")
	quit()

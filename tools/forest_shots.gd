extends SceneTree
## Zrzuty Prastarego Boru (Dungeons.FOREST): tłum (Błędniki, Borowcy), dziki drzewiec z kołem ciosu, zapowiedź i wybuch
## korzeni Żywej puszczy, potem Leszy - korzenie pasem, wir liści, przebudzenie dzikich drzewców.
## Użycie: SCRIPT=tools/forest_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_drzewiec.png, _3_zapowiedz.png, _4_korzenie.png, _5_leszy_korzenie.png,
## _6_wir_lisci.png, _7_przebudzenie.png

var _prefix := "/tmp/bor"


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
	var level := Dungeons.first_level(Dungeons.FOREST) + 1
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var grove: ProtoGrove = arena.grove
	grove.passive = true
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, -80), Vector2(-20, -90)]:
		horde.spawn_at(hero.position + p)
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(0.8).timeout
	await _shot("1_tlum")
	var g := horde.spawn_at(hero.position + Vector2(-26, 10), "brute") as ProtoGoblinBrute
	g._cooldown = 0.0
	await create_timer(0.6).timeout
	await _shot("2_drzewiec")
	await create_timer(1.0).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	grove.start()
	await create_timer(ProtoGrove.WARN * 0.6).timeout
	await _shot("3_zapowiedz")
	await create_timer(ProtoGrove.WARN * 0.4 + 0.15).timeout
	await _shot("4_korzenie")
	await create_timer(0.8).timeout
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var l := arena.chief as ProtoLeszy
	l.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.3).timeout
	l.position = hero.position + Vector2(-90, -40)
	l.start_attack("roots")
	await create_timer(ProtoLeszy.ROOTS_WARN + 0.25).timeout
	await _shot("5_leszy_korzenie")
	await create_timer(0.8).timeout
	l.start_attack("leaves")
	await create_timer(ProtoLeszy.LEAVES_WARN + 0.2).timeout
	await _shot("6_wir_lisci")
	await create_timer(0.8).timeout
	l.start_attack("awaken")
	await create_timer(ProtoLeszy.AWAKEN_TIME + 0.4).timeout
	await _shot("7_przebudzenie")
	quit()

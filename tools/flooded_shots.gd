extends SceneTree
## Zrzuty Zatopionych podziemi (Dungeons.FLOODED): tłum topielców z żabołakami i topielica z kołem lodu, potem
## Wodnik - fala w pasie, wir, lodowe krople i wezwanie topielców.
## Użycie: SCRIPT=tools/flooded_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_topielica.png, _3_fala.png, _4_wir.png, _5_krople.png, _6_wezwanie.png

var _prefix := "/tmp/zatopione"


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
	game.best_level = 11
	game.dungeon_level = 11
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, 80), Vector2(80, -20), Vector2(-20, -90)]:
		horde.spawn_at(hero.position + p)
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(0.8).timeout
	await _shot("1_tlum")
	var r := horde.spawn_at(hero.position + Vector2(22, -10), "brute") as ProtoGoblinBrute
	r._cooldown = 0.0
	await create_timer(0.75).timeout
	await _shot("2_topielica")
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	horde.add_embers(DungeonLevels.SUMMON_COST)
	arena.summon_chief()
	var w := arena.chief as ProtoWodnik
	w._summon_cooldown = 99.0
	w.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.2).timeout
	w._cooldown = 99.0
	hero.position = w.position + Vector2(10, 70)
	w.start_attack("wave")
	await create_timer(ProtoWodnik.WAVE_WARN + 0.2).timeout
	await _shot("3_fala")
	await create_timer(0.7).timeout
	w._cooldown = 99.0
	w.start_attack("vortex")
	await create_timer(ProtoWodnik.VORTEX_WARN + 0.5).timeout
	await _shot("4_wir")
	await create_timer(2.5).timeout
	w._cooldown = 99.0
	w.start_attack("cast")
	await create_timer(0.8).timeout
	await _shot("5_krople")
	await create_timer(1.5).timeout
	w._cooldown = 99.0
	w.start_attack("summon")
	await create_timer(0.7).timeout
	await _shot("6_wezwanie")
	quit()

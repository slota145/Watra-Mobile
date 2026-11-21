extends SceneTree
## Zrzuty Podniebnych wysp (Dungeons.SKY): latawce, wiły i wichrowiec z wirem, zapowiedź i podmuch wiatru,
## wędrowna trąba, potem Gryf - podmuch z ostrzami wiatru, szpony i trąby w pościgu.
## Użycie: SCRIPT=tools/sky_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_wichrowiec.png, _3_zapowiedz.png, _4_podmuch.png, _5_gryf_podmuch.png,
## _6_szpony.png, _7_traby.png

var _prefix := "/tmp/niebo"


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
	var level := Dungeons.first_level(Dungeons.SKY)
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var wind: ProtoWind = arena.wind
	wind.passive = true
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	# jedna wędrowna trąba w kadrze
	if not wind.tornadoes.is_empty():
		wind.tornadoes[0].position = hero.position + Vector2(110, 120)
		wind.tornadoes[0].hero = null
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, 80), Vector2(-20, -90)]:
		horde.spawn_at(hero.position + p)
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(0.6).timeout
	await _shot("1_tlum")
	var w := horde.spawn_at(hero.position + Vector2(-24, 10), "brute") as ProtoGoblinBrute
	w._cooldown = 0.0
	await create_timer(0.6).timeout  # w czasie zamachu - wir wciąga
	await _shot("2_wichrowiec")
	await create_timer(1.0).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.stun(30.0)
	wind.passive = false
	wind.start_gust(Vector2(1, 0.4).normalized())
	await create_timer(0.5).timeout
	await _shot("3_zapowiedz")
	await create_timer(ProtoWind.WARN + 0.4).timeout
	await _shot("4_podmuch")
	wind.passive = true
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var gr := arena.chief as ProtoGryf
	gr.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.2).timeout
	hero.position = gr.position + Vector2(10, 70)
	gr.start_attack("gust")
	await create_timer(ProtoGryf.GUST_WARN + 0.15).timeout
	await _shot("5_gryf_podmuch")
	await create_timer(1.5).timeout
	gr.start_attack("talons")
	await create_timer(ProtoGryf.SLAM_WARN_G + 0.25).timeout
	await _shot("6_szpony")
	await create_timer(1.5).timeout
	gr.start_attack("twisters")
	await create_timer(ProtoGryf.TWISTER_WARN + 0.8).timeout
	await _shot("7_traby")
	quit()

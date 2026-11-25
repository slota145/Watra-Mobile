extends SceneTree
## Zrzuty Lodowych jaskiń (Dungeons.FROST): tłum (Zmarzlaki, Śnieżnice), Lodowy olbrzym z kołem ciosu, zmarznięta postać
## przy koksowniku, potem Dziad Mróz - tchnienie, deszcz sopli, lodowe kolce i zamieć.
## Użycie: SCRIPT=tools/frost_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_olbrzym.png, _3_koksownik.png, _4_tchnienie.png, _5_sople.png, _6_kolce.png,
## _7_zamiec.png

var _prefix := "/tmp/mroz"


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
	var level := Dungeons.first_level(Dungeons.FROST) + 1
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var frost: ProtoFrost = arena.frost
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	frost.add_brazier(arena.get_node("World"), hero.position + Vector2(70, 60))
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, -80), Vector2(-20, -90)]:
		horde.spawn_at(hero.position + p)
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	hero.frost_cold = 55.0
	await create_timer(0.8).timeout
	await _shot("1_tlum")
	var g := horde.spawn_at(hero.position + Vector2(-26, 10), "brute") as ProtoGoblinBrute
	g._cooldown = 0.0
	await create_timer(0.55).timeout
	await _shot("2_olbrzym")
	await create_timer(1.0).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	hero.position += Vector2(66, 56)
	await create_timer(0.4).timeout
	await _shot("3_koksownik")
	hero.position -= Vector2(66, 56)
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var m := arena.chief as ProtoDziadMroz
	m.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.3).timeout
	m.position = hero.position + Vector2(0, -80)
	m.start_attack("breath")
	await create_timer(ProtoDziadMroz.BREATH_WARN * 0.6).timeout
	await _shot("4_tchnienie")
	await create_timer(ProtoDziadMroz.BREATH_WARN * 0.4 + 0.05).timeout
	await _shot("4b_tchnienie_mroz")
	await create_timer(0.8).timeout
	m.start_attack("rain")
	await create_timer(ProtoDziadMroz.RAIN_WARN * 0.9).timeout
	await _shot("5_sople")
	await create_timer(1.2).timeout
	hero.position = m.position + Vector2(90, 30)
	m.start_attack("spikes")
	await create_timer(ProtoDziadMroz.SPIKES_WARN + 0.25).timeout
	await _shot("6_kolce")
	await create_timer(0.8).timeout
	m.start_blizzard()
	await create_timer(1.0).timeout
	await _shot("7_zamiec")
	quit()

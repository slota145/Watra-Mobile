extends SceneTree
## Zrzuty Świątyni Słońca (Dungeons.TEMPLE): tłum (Południce, Żar-ptaki), kumir z kołem ciosu, zapowiedź i przejście
## pasa Promieni słońca (z cieniami kolumn), potem Swarożyc - wypad włócznią, promienie z nieba, przywołanie sług.
## Użycie: SCRIPT=tools/temple_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_kumir.png, _3_zapowiedz.png, _4_promien.png, _5_wypad.png, _6_promienie.png,
## _7_przywolanie.png

var _prefix := "/tmp/swiatynia"


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
	var level := Dungeons.first_level(Dungeons.TEMPLE) + 1
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var beams: ProtoSunbeams = arena.sunbeams
	beams.passive = true
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
	await _shot("2_kumir")
	await create_timer(1.2).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	beams.start(Vector2(1, 0.3))
	await create_timer(ProtoSunbeams.WARN * 0.6).timeout
	await _shot("3_zapowiedz")
	await create_timer(ProtoSunbeams.WARN * 0.4 + ProtoSunbeams.START / ProtoSunbeams.SPEED * 0.8).timeout
	await _shot("4_promien")
	await create_timer(3.0).timeout
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var s := arena.chief as ProtoSwarozyc
	s.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.3).timeout
	s.position = hero.position + Vector2(-100, -40)
	s.start_attack("lunge")
	await create_timer(ProtoSwarozyc.LUNGE_WARN * 0.7).timeout
	await _shot("5_wypad")
	await create_timer(1.2).timeout
	s.start_attack("beams")
	await create_timer(ProtoSwarozyc.BEAM_WARN - 0.05).timeout
	await _shot("6_promienie")
	await create_timer(1.2).timeout
	s.start_attack("summon")
	await create_timer(ProtoSwarozyc.SUMMON_TIME * 0.6 + 0.25).timeout
	await _shot("7_przywolanie")
	quit()

extends SceneTree
## Zrzuty Kopalni karłów (Dungeons.MINE): tłum (kretołaki pod ziemią i na powierzchni, karły-procarze), skalny golem
## z kołem ciosu, zapowiedź Osuwiska i leżące głazy (kamień procarza rozbija się na głazie), potem Król Karłów -
## uderzenie młotem z falami, deszcz odłamków, przywołanie golemów.
## Użycie: SCRIPT=tools/mine_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_golem.png, _3_zapowiedz.png, _4_glazy.png, _5_mlot.png, _6_odlamki.png,
## _7_przywolanie.png

var _prefix := "/tmp/kopalnia"


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
	var level := Dungeons.first_level(Dungeons.MINE) + 1
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var rf: ProtoRockfall = arena.rockfall
	rf.passive = true
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	for p in [Vector2(-70, -40), Vector2(-60, 50), Vector2(40, -80)]:
		var k := horde.spawn_at(hero.position + p) as ProtoKretolak
		k.emerge(false)
	for p in [Vector2(-130, 90), Vector2(120, 60)]:
		horde.spawn_at(hero.position + p)  # zakopane - kopczyki
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(0.8).timeout
	await _shot("1_tlum")
	var g := horde.spawn_at(hero.position + Vector2(-26, 10), "brute") as ProtoGoblinBrute
	g._cooldown = 0.0
	await create_timer(0.6).timeout
	await _shot("2_golem")
	await create_timer(1.2).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	rf.start()
	await create_timer(ProtoRockfall.WARN * 0.75).timeout
	await _shot("3_zapowiedz")
	await create_timer(ProtoRockfall.WARN * 0.25 + 0.4).timeout
	# procarz za głazem: kamień rozbija się na głazie
	var at: Vector2 = rf._rocks[0].at
	hero.position = at + Vector2(30, 6)
	var p := horde.spawn_at(at + Vector2(-110, 0), "archer") as ProtoProcarz
	p._cooldown = 0.0
	await create_timer(ProtoGoblinArcher.RELEASE_TIME + 0.4).timeout
	await _shot("4_glazy")
	p.queue_free()
	await create_timer(1.0).timeout
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var king := arena.chief as ProtoDwarfKing
	king.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.3).timeout
	king.position = hero.position + Vector2(-90, -30)
	king.start_attack("hammer")
	await create_timer(ProtoDwarfKing.HAMMER_WARN * 0.7).timeout
	await _shot("5_mlot")
	await create_timer(1.4).timeout
	king.start_attack("shards")
	await create_timer(ProtoDwarfKing.SHARD_WARN - 0.1).timeout
	await _shot("6_odlamki")
	await create_timer(1.4).timeout
	king.start_attack("summon")
	await create_timer(ProtoDwarfKing.SUMMON_TIME * 0.6 + 0.25).timeout
	await _shot("7_przywolanie")
	quit()

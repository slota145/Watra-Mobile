extends SceneTree
## Zrzuty Wieży Kościeja (Dungeons.TOWER): tłum (latające księgi, uczniowie), runiczny golem z kołem ciosu, Magiczne
## pieczęcie (zapowiedź czerwonych i niebieska, potem wybuch), potem Kościej - jajo z nicią, pieczęcie, pociski,
## teleport i odrodzenie.
## Użycie: SCRIPT=tools/tower_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_golem.png, _3_pieczecie.png, _4_wybuch.png, _5_jajo.png, _6_pieczecie_bossa.png,
## _7_pociski.png, _8_teleport.png, _9_odrodzenie.png

var _prefix := "/tmp/wieza"


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
	var level := Dungeons.first_level(Dungeons.TOWER) + 1
	game.best_level = level
	game.dungeon_level = level
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	var seals: ProtoSeals = arena.seals
	seals.passive = true
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
	await _shot("2_golem")
	await create_timer(1.2).timeout
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	seals.add_seal(hero.global_position + Vector2(6, 4), "red")
	seals.add_seal(hero.global_position + Vector2(-60, -30), "red")
	seals.add_seal(hero.global_position + Vector2(50, 60), "red")
	seals.add_seal(hero.global_position + Vector2(70, -40), "blue")
	await create_timer(ProtoSeals.RED_WARN * 0.6).timeout
	await _shot("3_pieczecie")
	await create_timer(ProtoSeals.RED_WARN * 0.4 + 0.08).timeout
	await _shot("4_wybuch")
	await create_timer(2.0).timeout
	seals.seals.clear()
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var k := arena.chief as ProtoKosciej
	k.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.3).timeout
	k.position = hero.position + Vector2(-80, -60)
	k.place_egg(hero.position + Vector2(70, 50))
	await create_timer(0.1).timeout
	await _shot("5_jajo")
	k.start_attack("cast")
	await create_timer(ProtoKosciej.CAST_TIME + ProtoKosciej.SEAL_WARN * 0.6).timeout
	await _shot("6_pieczecie_bossa")
	await create_timer(1.2).timeout
	k.start_attack("bolt")
	await create_timer(ProtoKosciej.BOLT_TIME + 0.25).timeout
	await _shot("7_pociski")
	await create_timer(1.2).timeout
	hero.position += Vector2(30, 0)
	k.start_attack("teleport")
	await create_timer(ProtoKosciej.TELE_OUT + ProtoKosciej.TELE_WARN * 0.6).timeout
	await _shot("8_teleport")
	await create_timer(1.2).timeout
	k.take_damage(k.hp + 10, hero.global_position)
	await create_timer(ProtoKosciej.REVIVE_TIME * 0.5).timeout
	await _shot("9_odrodzenie")
	quit()

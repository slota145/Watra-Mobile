extends SceneTree
## Zrzuty Katakumb (Dungeons.CATACOMBS): tłum szkieletów z łucznikami i kupką kości, rycerz-szkielet z wachlarzem,
## potem Nekromanta - kule Nawii, kościany krąg, wyssanie życia i przywołanie szkieletów.
## Użycie: SCRIPT=tools/catacombs_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_tlum.png, _2_rycerz.png, _3_kule.png, _4_krag.png, _5_wyssanie.png, _6_przywolanie.png

var _prefix := "/tmp/katakumby"


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
	game.best_level = 21
	game.dungeon_level = 21
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
	var pile := horde.spawn_at(hero.position + Vector2(50, 20)) as ProtoSkeleton
	pile.take_damage(100000, hero.global_position)
	horde.spawn_at(hero.position + Vector2(-110, -120), "archer")
	horde.spawn_at(hero.position + Vector2(100, -130), "archer")
	await create_timer(1.0).timeout
	await _shot("1_tlum")
	var k := horde.spawn_at(hero.position + Vector2(26, -8), "brute") as ProtoGoblinBrute
	k._cooldown = 0.0
	await create_timer(0.75).timeout
	await _shot("2_rycerz")
	for n in arena.get_node("World").get_children():
		if n is ProtoGoblin:
			n.queue_free()
	horde.add_embers(DungeonLevels.summon_cost(horde.level))
	arena.summon_chief()
	var nec := arena.chief as ProtoNecromancer
	nec.passive = true
	await create_timer(ProtoChief.ENTER_TIME + 0.2).timeout
	hero.position = nec.position + Vector2(10, 100)
	nec.start_attack("bolts")
	await create_timer(ProtoNecromancer.BOLT_WARN + 0.5).timeout
	await _shot("3_kule")
	await create_timer(2.5).timeout
	nec.start_attack("ring")
	await create_timer(ProtoNecromancer.RING_WARN + 0.25).timeout
	await _shot("4_krag")
	await create_timer(1.0).timeout
	hero.position = nec.position + Vector2(10, 45)
	nec.start_attack("drain")
	await create_timer(ProtoNecromancer.DRAIN_START + 0.5).timeout
	await _shot("5_wyssanie")
	await create_timer(2.0).timeout
	nec.start_attack("summon")
	await create_timer(0.7).timeout
	await _shot("6_przywolanie")
	quit()

extends SceneTree
## Zrzuty celów na mapie lochu (DungeonGoals) do oceny wyglądu: skrzynia-cel pod słupem światła z kółkiem postępu
## i kapliczka poza kadrem ze strzałką przy krawędzi; potem kapliczka z bliska i napis daru.
## Użycie: SCRIPT=tools/goal_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Na koniec Skarbnik: czeka pod słupem światła, potem ucieka i wybija złoto przy trafieniu.
## Pliki: <prefiks>_1_cele.png, _2_kapliczka.png, _3_dar.png, _4_skarbnik.png, _5_poscig.png

var _prefix := "/tmp/cele"


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
	game.best_level = 7
	game.dungeon_level = 7
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var horde: ProtoHorde = arena.horde_spawner
	hero.immortal = true
	arena.weapon.auto_attack = false
	horde.running = false
	var h := hero.position
	for p in [Vector2(-110, -80), Vector2(-30, -120), Vector2(90, 60), Vector2(120, -40), Vector2(-90, 110)]:
		horde.spawn_at(h + p)
	var box: ProtoChest = arena.spawn_goal("chest")
	box.position = h + Vector2(70, -60)
	var shrine: ProtoShrine = arena.spawn_goal("shrine")
	shrine.position = h + Vector2(-260, 330)
	var far: ProtoChest = arena.spawn_goal("chest")
	far.position = h + Vector2(250, -420)
	await create_timer(0.6).timeout
	hero.position = box.position + Vector2(-12, 4)
	await create_timer(1.0).timeout
	await _shot("1_cele")
	hero.position = shrine.position + Vector2(0, 60)
	await create_timer(1.2).timeout
	await _shot("2_kapliczka")
	hero.position = shrine.position
	await create_timer(DungeonGoals.PRAY_TIME + 0.4).timeout
	await _shot("3_dar")
	var spirit: ProtoSkarbnik = arena.spawn_goal("skarbnik")
	spirit.position = hero.position + Vector2(40, -150)
	await create_timer(0.8).timeout
	await _shot("4_skarbnik")
	hero.position = spirit.position + Vector2(-20, 60)
	await create_timer(0.5).timeout
	spirit.take_damage(1, hero.position)
	await create_timer(0.15).timeout
	await _shot("5_poscig")
	quit()

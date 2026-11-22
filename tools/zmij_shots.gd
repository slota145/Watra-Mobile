extends SceneTree
## Zrzuty bossa szczytowego Żmija Gorynycza (Pinnacles): wybór przy Watrze z kluczem, wejście na Pogorzelisko,
## zionięcie (ostrzeżenie i ogień), Trzy Głowy, zgaśnięcie głowy, krąg słupów w 3. fazie i okno zwycięstwa.
## Użycie: SCRIPT=tools/zmij_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_wybor.png, _2_wejscie.png, _3_ostrzezenie.png, _4_zioniecie.png, _5_kule.png, _6_glowa.png,
## _7_slupy.png, _8_zwyciestwo.png

var _prefix := "/tmp/zmij"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_hero()
	game.best_level = 34
	game.dungeon_level = 34
	game.hero_level = 30
	game.zmij_keys = {"34": 1, "31": 2}
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await _wait(0.5)
	base.open_picker()
	await _wait(0.2)
	await _shot("1_wybor")
	paused = false
	base.queue_free()
	await process_frame
	game.pinnacle_key = 34
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	var hero: ProtoHero = arena.hero
	hero.immortal = true
	arena.weapon.auto_attack = false
	var z := arena.chief as ProtoZmij
	z.passive = true
	await _wait(0.45)
	await _shot("2_wejscie")
	await _wait(ProtoChief.ENTER_TIME)
	hero.position = z.position + Vector2(25, 95)
	await _wait(0.3)
	z.start_attack("breath")
	await _wait(0.6)
	await _shot("3_ostrzezenie")
	await _wait(0.5)
	await _shot("4_zioniecie")
	await _wait(1.5)
	hero.position = z.position + Vector2(-20, 140)
	z.start_attack("balls")
	await _wait(ProtoZmij.BALL_WARN - 0.05)
	await _shot("5_kule")
	await _wait(1.2)
	z.take_damage(roundi(z.max_hp * 0.4), hero.global_position)
	await _wait(0.35)
	await _shot("6_glowa")
	await _wait(ProtoZmij.RAGE_TIME)
	z.take_damage(roundi(z.max_hp * 0.3), hero.global_position)
	await _wait(ProtoZmij.RAGE_TIME + 0.2)
	hero.position = z.position + Vector2(0, 150)
	z.start_attack("jump")
	await _wait(ProtoZmij.JUMP_WARN + ProtoZmij.JUMP_TIME + 0.25)
	hero.position = z.position + Vector2(0, 120)
	await _shot("7_slupy")
	z.take_damage(100000000, hero.global_position)
	await _wait(1.7)
	arena.chest.open()
	await _wait(2.8)
	await _shot("8_zwyciestwo")
	game.zmij_keys = {}
	game.pinnacle_key = 0
	game.reset_hero()
	quit()

extends SceneTree
## Zrzuty elektrycznej katany: okno umiejętności z czterema broniami (baza) i walka w lochu - cięcie, Taniec ostrza,
## Riposta (garda, kontra, okrąg), Sąd Peruna (ładowanie, cięcie), Błysk Peruna i przemoczone, porażone gobliny
## (krople, iskry). Mierzy klatki na sekundę w Błysku Peruna.
## Użycie: SCRIPT=tools/katana_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Pliki: <prefiks>_1_okno.png, _2_ciecie.png, _3_taniec.png, _4_garda/_4b_kontra/_4c_okrag.png, _5_ladowanie.png,
## _5b_perun.png, _6_blysk.png, _7_mokre.png

var _prefix := "/tmp/katana"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _fresh(weapon: ProtoKatana, hero: ProtoHero) -> void:
	weapon.reset_cooldowns()
	weapon._end_skill()
	hero.mana = hero.max_mana
	hero.position = Vector2(-40, 0)


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_hero()
	game.best_level = 20
	game.set_weapon("katana")
	game.dev_set_level(20)
	game.dev_skills()
	game.skill_slots = ["k_slash", "k_dance", "k_riposte", "k_perun", "k_flash"]
	game.dev_immortal = true
	game.save_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.skills_window.open(true)
	await create_timer(0.3).timeout
	await _shot("1_okno")
	arena.skills_window.close()
	arena.queue_free()
	game.dungeon_level = 4
	game.save_game()
	arena = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	arena.horde_spawner.set_process(false)
	var weapon: ProtoKatana = arena.weapon
	var hero: ProtoHero = arena.hero
	hero.position = Vector2.ZERO
	for at in [Vector2(28, -6), Vector2(70, 20), Vector2(110, -10), Vector2(-40, 40), Vector2(-80, -30), Vector2(10, 70),
			Vector2(60, 80), Vector2(-20, -60)]:
		var g := ProtoGoblin.new()
		g.hero = hero
		g.bounds = Rect2(-400, -600, 800, 1200)
		g.power = 80.0
		g.position = hero.position + at
		hero.get_parent().add_child(g)
	await process_frame
	for g in get_nodes_in_group(ProtoWeapon.TARGETS):
		g.set("_stunned", 60.0)
	weapon._attack()
	await create_timer(0.11).timeout
	await _shot("2_ciecie")
	await create_timer(0.4).timeout
	weapon._attack()
	await create_timer(0.11).timeout
	await _shot("2b_ciecie")
	await create_timer(0.4).timeout
	_fresh(weapon, hero)
	weapon.cast("k_dance")
	await create_timer(0.36).timeout
	await _shot("3_taniec")
	await create_timer(0.3).timeout
	await _shot("3b_piorun")
	await create_timer(0.4).timeout
	_fresh(weapon, hero)
	weapon.cast("k_riposte")
	await create_timer(0.3).timeout
	await _shot("4_garda")
	hero.take_damage(5)
	await create_timer(0.1).timeout
	await _shot("4b_kontra")
	await create_timer(0.27).timeout
	await _shot("4c_okrag")
	await create_timer(0.6).timeout
	_fresh(weapon, hero)
	weapon.cast("k_perun")
	weapon.charge_held = true
	await create_timer(1.2).timeout
	await _shot("5_ladowanie")
	weapon.charge_held = false
	await create_timer(0.12).timeout
	await _shot("5b_perun")
	await create_timer(0.5).timeout
	_fresh(weapon, hero)
	var frames := Engine.get_frames_drawn()
	weapon.flicker_held = true
	weapon.cast("k_flash")
	await create_timer(0.05).timeout
	await _shot("6_blysk")
	await create_timer(0.08).timeout
	await _shot("6b_blysk")
	await create_timer(0.08).timeout
	await _shot("6c_blysk")
	await create_timer(1.29).timeout
	weapon.flicker_held = false
	print("klatki/s w Błysku Peruna: %.0f" % ((Engine.get_frames_drawn() - frames) / 1.5))
	for g in get_nodes_in_group(ProtoWeapon.TARGETS):
		(g as ProtoTarget).soak(0.2, 10.0)
		(g as ProtoTarget).shock(10.0)
	await create_timer(0.4).timeout
	await _shot("7_mokre")
	game.dev_immortal = false
	game.reset_hero()
	game.best_level = 0
	game.save_game()
	DirAccess.remove_absolute(game.save_path)
	quit()

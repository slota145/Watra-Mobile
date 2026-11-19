extends SceneTree
## Zrzut wiązki piorunów (10. poziom Błysku Peruna katany, 19.11.2026): z postaci w najdalszego wroga w zasięgu, potem
## przeskoki po kolejnych (najdalszy nietrafiony). Użycie: SCRIPT=tools/chain_shots.gd tools/screenshot.sh <prefiks>
## Plik: <prefiks>_1_wiazka.png

var _prefix := "/tmp/wiazka"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.best_level = 20
	game.dungeon_level = 5
	game.set_weapon("katana")
	game.dev_skills()
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	var hero: ProtoHero = arena.hero
	hero.immortal = true
	arena.horde_spawner.running = false
	var weapon: ProtoWeapon = arena.weapon
	weapon.skill_levels = {"k_flash": 10}
	for p in [Vector2(-90, -60), Vector2(-40, -110), Vector2(30, -130), Vector2(80, -60), Vector2(100, 30), Vector2(-60, 70)]:
		var g: ProtoGoblin = arena.horde_spawner.spawn_at(hero.position + p)
		g._stunned = 60.0
	await create_timer(0.3).timeout
	weapon._flicker_spin()
	await create_timer(0.06).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_1_wiazka.png" % _prefix)
	DirAccess.remove_absolute(game.save_path)
	quit()

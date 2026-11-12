extends SceneTree
## Zrzuty walki z Wodzem Goblinów do oceny wyglądu: pełny pasek żaru z przyciskiem przyzwania, wejście Wodza,
## ostrzeżenie ciosu w ziemię, rzut tasakiem i okno zwycięstwa; w bazie wybór poziomu lochu.
## Użycie: SCRIPT=tools/boss_shots.gd tools/screenshot.sh <prefiks> [rozdzielczość jako RESOLUTION]
## Pliki: <prefiks>_1_pasek.png, _2_wodz.png, _3_cios.png, _4_rzut.png, _5_wygrana.png, _6_wybor.png

var _prefix := "/tmp/boss"


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
	game.best_level = 2
	game.dungeon_level = 3
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(6.0).timeout
	var horde: ProtoHorde = arena.horde_spawner
	arena.hero.hp = 1000
	horde.embers = DungeonLevels.SUMMON_COST + 17
	horde._on_ember(0)
	await create_timer(0.3).timeout
	await _shot("1_pasek")
	arena.summon_chief()
	await create_timer(0.5).timeout
	await _shot("2_wodz")
	var chief: ProtoChief = arena.chief
	await create_timer(1.2).timeout
	arena.hero.position = chief.position + Vector2(24, 10)
	chief._start_slam()
	await create_timer(0.8).timeout
	await _shot("3_cios")
	await create_timer(1.5).timeout
	arena.hero.position = chief.position + Vector2(90, 40)
	chief._start_throw()
	await create_timer(0.7).timeout
	await _shot("4_rzut")
	chief.take_damage(100000, arena.hero.global_position)
	await create_timer(arena.CHEST_DELAY + 0.3).timeout
	arena.hero.position = arena.chest.position + Vector2(0, 8)
	await create_timer(0.6).timeout
	await _shot("5_skrzynia")
	await create_timer(arena.VICTORY_DELAY).timeout
	await _shot("6_wygrana")
	arena.queue_free()
	paused = false
	var base: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(base)
	await create_timer(0.5).timeout
	base.open_picker()
	await create_timer(0.2).timeout
	await _shot("7_wybor")
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.settings_path)
	quit()

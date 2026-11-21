extends SceneTree
## Zrzut pokazu łupu: rząd przedmiotów na ziemi (zwykły, magiczny, rzadki z premią ponad widełki, legendarny, unikat,
## anielski) ze słupami, gwiazdką i strzałkami „lepszy”, napis o unikacie i strzałka przy krawędzi do legendy poza kadrem.
## Użycie: SCRIPT=tools/loot_show_shots.gd tools/screenshot.sh <prefiks> (rozdzielczość jako RESOLUTION)
## Plik: <prefiks>_lup.png

var _prefix := "/tmp/pokaz"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_hero()
	game.dungeon_level = 30
	game.equipped = {"helmet": Items.roll(30, "helmet", "rare", Items.GOBLIN_WEIGHTS, "", false)}
	game.save_game()
	var arena: Node = load("res://scenes/horde.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	arena.horde_spawner.running = false
	var hero: ProtoHero = arena.hero
	var rare := Items.roll(30, "boots", "rare")
	Items.make_above(rare, 0)
	var angel := Items.roll(30, "armor", "magic")
	for k in angel.affixes.size():
		Items.make_above(angel, k)
	var drops := [Items.roll(30, "helmet", "common"), Items.roll(30, "ring", "magic"), rare,
			Items.roll(30, "earring", "legendary"), angel, Items.make_unique("crown", 30)]
	for i in drops.size():
		var loot: ProtoLoot = arena.horde_spawner.drop_item(drops[i], hero.position + Vector2(-100 + 40 * i, -60))
		loot.magnet = 0.0
		loot.spread = 0.0
	var far: ProtoLoot = arena.horde_spawner.drop_item(Items.roll(30, "amulet", "legendary"), hero.position + Vector2(500, -300))
	far.magnet = 0.0
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_lup.png" % _prefix)
	game.reset_hero()
	DirAccess.remove_absolute(game.save_path)
	quit()

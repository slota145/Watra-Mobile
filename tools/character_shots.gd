extends SceneTree
## Zrzuty wyboru postaci (CharacterSelect): karty trzech postaci (zwykła, z trybem deweloperskim, SSF) i formularz
## nowej postaci. Postacie w osobnym katalogu testowym (sprzątany na końcu).
## Użycie: SCRIPT=tools/character_shots.gd tools/screenshot.sh <prefiks> [RESOLUTION]
## Pliki: <prefiks>_1_karty.png, _2_nowa.png

const DIR := "user://shot_test_characters/"
var _prefix := "/tmp/postacie"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s_%s.png" % [_prefix, name])


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.chars_dir = DIR
	game.shared_stash_path = "user://shot_test_shared.json"
	var a: String = game.create_character("Wojciech", false)
	game.select_character(a)
	game.hero_level = 14
	game.best_level = 23
	game.weapon = Weapons.GLAIVE
	game.save_game()
	var b: String = game.create_character("Testowy", false)
	game.select_character(b)
	game.hero_level = 40
	game.best_level = 101
	game.dev_immortal = true
	game.save_game()
	var c: String = game.create_character("Samotna Mira", true)
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await create_timer(0.3).timeout
	menu.characters.open()
	await create_timer(0.3).timeout
	await _shot("1_karty")
	menu.characters.open_form()
	menu.characters.name_edit.text = "Bolko"
	menu.characters._set_ssf(true)
	await create_timer(0.3).timeout
	await _shot("2_nowa")
	for id in [a, b, c]:
		DirAccess.remove_absolute(DIR + id + ".json")
	DirAccess.remove_absolute("user://shot_test_shared.json")
	quit()

extends SceneTree
## Test szkieletu projektu: orientacja pionowa, rozdzielczość, wersja i ekran startowy.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	_check(h > w, "obraz gry w pionie (%dx%d)" % [w, h])
	_check(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_PORTRAIT,
		"telefon trzymany pionowo")
	_check(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse") == true,
		"mysz udaje dotyk na komputerze")
	_check(root.get_node("Game").version() != "0.0.0", "numer wersji w project.godot")
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	_check(menu.get_node("%Play") is Button, "ekran startowy z przyciskiem Graj")
	_check(menu.get_node("%Version").text.contains(root.get_node("Game").version()), "wersja w rogu menu")
	_check(ResourceLoader.exists(menu.PROTOTYPE_SCENE), "Graj prowadzi do istniejącej sceny")
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)

extends SceneTree
## Test prototypu walki: palec (zdarzenia myszy jak na telefonie) prowadzi postać do kukły, miecz sam atakuje,
## kukła liczy trafienia; przycisk gestu przełącza gest postaci. Z oknem (tools/screenshot.sh) zapisuje
## klatki zamachu do podanego folderu: SCRIPT=tests/test_prototype.gd tools/screenshot.sh <folder>

var _failed := 0
var _shots := ""


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and DisplayServer.get_name() != "headless":
		_shots = args[0]
		DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	root.push_input(e)


func _mouse_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var dummy: ProtoDummy = arena.weapon.targets[0]
	var start := hero.position
	# palec w dolnej części ekranu, przeciągnięcie w górę - postać idzie w stronę kukły (0, -70)
	var view := root.get_visible_rect().size
	var finger := Vector2(view.x / 2, view.y * 0.75)
	_mouse_button(finger, true)
	await process_frame
	_mouse_move(finger + Vector2(0, -40))
	await _wait(0.5)
	_check(hero.position.y < start.y - 20.0, "postać idzie za palcem (%.0f -> %.0f)" % [start.y, hero.position.y])
	_check(hero.facing.y < -0.5, "postać patrzy w stronę ruchu")
	_mouse_button(finger + Vector2(0, -40), false)
	await process_frame
	_check(arena.joystick.vector == Vector2.ZERO, "puszczenie palca zatrzymuje postać")
	# podejście aż kukła będzie w zasięgu miecza
	hero.position = dummy.position + Vector2(-14, 22)
	if _shots != "":
		await _wait(0.8)  # kamera i miecz dojeżdżają po przestawieniu postaci
		await _capture_swing(arena)
	await _wait(2.0)
	_check(dummy._count >= 2, "miecz sam atakuje kukłę (trafień: %d)" % dummy._count)
	_check(dummy._total >= 28, "kukła liczy obrażenia (suma %d)" % dummy._total)
	var far: ProtoDummy = arena.weapon.targets[2]
	_check(far._count == 0, "daleka kukła nietknięta")
	arena.gesture_button.button_pressed = false
	_check(not hero.gesture and arena.gesture_button.text.contains("wył"), "przycisk wyłącza gest")
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)


## Klatki od początku zamachu, co 1/30 s.
func _capture_swing(arena: Node) -> void:
	while arena.weapon._state != "windup":
		await process_frame
	for i in 12:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/swing_%02d.png" % [_shots, i])
		await _wait(1.0 / 30.0)

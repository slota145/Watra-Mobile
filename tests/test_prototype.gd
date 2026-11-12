extends SceneTree
## Test prototypu walki: palce (zdarzenia dotyku z numerem palca) prowadzą postać i trzymają przycisk ataku,
## miecz tnie kukłę, kukła liczy trafienia; 4 puste miejsca na umiejętności; przycisk gestu przełącza gest postaci. Z oknem (tools/screenshot.sh) zapisuje
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


func _touch(pos: Vector2, pressed: bool, finger := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.pressed = pressed
	e.position = pos
	root.push_input(e, true)  # pozycje w pikselach gry, nie okna


func _drag(pos: Vector2, finger := 0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = finger
	e.position = pos
	root.push_input(e, true)  # pozycje w pikselach gry, nie okna


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
	var finger := Vector2(view.x * 0.3, view.y * 0.6)
	_touch(finger, true)
	await process_frame
	_drag(finger + Vector2(0, -40))
	await _wait(0.5)
	_check(hero.position.y < start.y - 20.0, "postać idzie za palcem (%.0f -> %.0f)" % [start.y, hero.position.y])
	_check(hero.facing.y < -0.5, "postać patrzy w stronę ruchu")
	# drugi palec na przycisku ataku w trakcie marszu: gałka dalej działa, atak trzymany
	var attack: ActionButton = arena.actions.attack
	var attack_at := attack.get_global_rect().get_center()
	_check(attack_at.x > view.x * 0.6 and attack_at.y > view.y * 0.7, "przycisk ataku w prawym dolnym rogu")
	_touch(attack_at, true, 1)
	await process_frame
	_check(attack.held and arena.weapon.attack_held, "przycisk ataku trzymany drugim palcem")
	_check(arena.joystick.vector.y < -0.5, "gałka działa razem z atakiem")
	_touch(attack_at, false, 1)
	_touch(finger + Vector2(0, -40), false)
	await process_frame
	_check(arena.joystick.vector == Vector2.ZERO and not arena.weapon.attack_held, "puszczenie palców zatrzymuje postać i atak")
	_touch(attack_at, true)
	await process_frame
	_check(arena.joystick._finger == -1, "dotyk przycisku nie uruchamia gałki")
	_touch(attack_at, false)
	var skills: Array = arena.actions.skills
	var inside := skills.size() == 4
	for sk in skills:
		var r: Rect2 = sk.get_global_rect()
		inside = inside and Rect2(Vector2.ZERO, view).encloses(r) and r.size.x >= 44.0
		inside = inside and r.intersection(attack.get_global_rect()).get_area() < 1.0
	_check(inside, "4 miejsca na umiejętności na ekranie, po 44 px, nie nachodzą na atak")
	# przy kukle: bez przycisku miecz nie tnie, z przyciskiem tnie
	await _wait(0.5)  # wcześniejsze stuknięcia kończą swoje cięcia
	hero.position = dummy.position + Vector2(-14, 22)
	await _wait(1.0)
	_check(dummy._count == 0, "bez przycisku miecz nie atakuje")
	_touch(attack_at, true, 1)
	if _shots != "":
		await _capture_swing(arena)
	await _wait(2.0)
	_touch(attack_at, false, 1)
	_check(dummy._count >= 2, "trzymany atak tnie kukłę (trafień: %d)" % dummy._count)
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

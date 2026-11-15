extends SceneTree
## Test dotyku nad interfejsem (zgłoszenie autora 15.11.2026): stuknięcie w przycisk górnego rzędu („Umiejętności”)
## nad skrzynią albo Watrą nie otwiera ich (TouchUi.covers), a stuknięcie w samą skrzynię i Watrę dalej działa.

var _failed := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _tap(at: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = at
	e.pressed = true
	root.push_input(e, true)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = at
	up.pressed = false
	root.push_input(up, true)


## Stawia węzeł świata tak, żeby punkt ekranu `screen` wypadł w jego polu stuknięcia (tuż nad podstawą).
func _put_under(node: Node2D, screen: Vector2) -> void:
	var world: Vector2 = node.get_viewport().get_canvas_transform().affine_inverse() * screen
	node.global_position = world + Vector2(0, 5)


func _run() -> void:
	var game: Node = root.get_node("Game")
	DirAccess.remove_absolute(game.save_path)
	game.load_game()
	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.5).timeout
	var icon: Button = arena.skills_icon
	var icon_at := icon.get_global_rect().get_center()
	var empty := Vector2(icon_at.x, root.get_visible_rect().size.y * 0.45)
	_check(TouchUi.covers(self, icon_at), "przycisk „Umiejętności” to interfejs")
	_check(not TouchUi.covers(self, empty), "środek ekranu to świat, nie interfejs")
	var stash: ProtoStash = arena.stash
	var watra: ProtoWatra = arena.watra
	var opened := [0]
	var entered := [0]
	stash.opened.connect(func() -> void: opened[0] += 1)
	watra.entered.connect(func() -> void: entered[0] += 1)
	arena.hero.position = Vector2(0, 600)  # z dala - skrzynia nie otwiera się sama przy podejściu
	watra.global_position = Vector2(0, 2000)
	await create_timer(2.0).timeout  # kamera dojeżdża do postaci
	_put_under(stash, icon_at)
	await process_frame
	_tap(icon_at)
	await process_frame
	_check(opened[0] == 0 and arena.skills_window.visible, "stuknięcie w przycisk nad skrzynią otwiera okno, nie skrzynię")
	arena.skills_window.close()
	_put_under(stash, empty)
	await process_frame
	_tap(empty)
	await process_frame
	_check(opened[0] == 1, "stuknięcie w samą skrzynię ją otwiera")
	stash.global_position = Vector2(0, 2000)
	arena.stash_window.close()
	_put_under(watra, icon_at)
	await process_frame
	_tap(icon_at)
	await process_frame
	_check(entered[0] == 0, "stuknięcie w przycisk nad Watrą nie otwiera wyboru poziomu")
	arena.skills_window.close()
	_put_under(watra, empty)
	await process_frame
	_tap(empty)
	await process_frame
	_check(entered[0] == 1, "stuknięcie w samą Watrę działa")
	arena.queue_free()
	DirAccess.remove_absolute(game.save_path)
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)

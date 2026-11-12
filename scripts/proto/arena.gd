extends Node2D
## Prototyp walki: polana z trawy, Wojciech z lewitującym mieczem i kukły treningowe z Watry.
## Chodzenie: przeciągnij palcem w dowolnym miejscu ekranu (pływająca gałka). Miecz atakuje sam, gdy kukła
## jest blisko. Przycisk „Gest” włącza i wyłącza gest ręką postaci przy ataku (porównanie obu wersji).
## Wszystko budowane w kodzie, żeby prototyp łatwo było zmieniać i wyrzucić.

const ARENA := Rect2(-360, -560, 720, 1120)
const DUMMIES := [Vector2(0, -70), Vector2(-80, 40), Vector2(90, 60)]

var hero: ProtoHero
var weapon: ProtoWeapon
var joystick: Joystick
var gesture_button: Button


func _ready() -> void:
	_make_ground()
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	_make_hud()
	hero = ProtoHero.new()
	hero.name = "Hero"
	hero.position = Vector2(0, 40)
	hero.joystick = joystick
	hero.bounds = ARENA.grow(-16)
	world.add_child(hero)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)
	hero.add_child(camera)

	var trail := Line2D.new()
	trail.width = 3.0
	trail.z_index = 10
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.gradient = Gradient.new()
	trail.gradient.set_color(0, Color(1.0, 0.75, 0.4, 0.0))
	trail.gradient.set_color(1, Color(1.0, 0.95, 0.8, 0.9))
	add_child(trail)

	weapon = ProtoWeapon.new()
	weapon.name = "Weapon"
	weapon.hero = hero
	weapon.trail = trail
	for p in DUMMIES:
		var dummy := ProtoDummy.new()
		dummy.position = p
		world.add_child(dummy)
		weapon.targets.append(dummy)
	world.add_child(weapon)


## Trawa z Watry powtarzana na całej polanie, z ciemniejszym brzegiem.
func _make_ground() -> void:
	var edge := ColorRect.new()
	edge.color = Color(0.11, 0.16, 0.1)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.position = ARENA.position - Vector2(400, 400)
	edge.size = ARENA.size + Vector2(800, 800)
	add_child(edge)
	var grass := Sprite2D.new()
	grass.texture = preload("res://assets/watra/grass.png")
	grass.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grass.region_enabled = true
	grass.region_rect = Rect2(Vector2.ZERO, ARENA.size)
	grass.centered = false
	grass.position = ARENA.position
	add_child(grass)


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	joystick = Joystick.new()  # pierwsze dziecko: pod przyciskami
	layer.add_child(joystick)
	var safe := SafeArea.new()
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(safe)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var back := Button.new()
	back.text = tr("Menu")
	back.custom_minimum_size = Vector2(72, 44)
	back.pressed.connect(func() -> void: Game.change_scene(Game.MENU_SCENE))
	top.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	gesture_button = Button.new()
	gesture_button.toggle_mode = true
	gesture_button.button_pressed = true
	gesture_button.custom_minimum_size = Vector2(110, 44)
	gesture_button.toggled.connect(_on_gesture_toggled)
	top.add_child(gesture_button)
	_on_gesture_toggled(true)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(fill)
	var hint := Label.new()
	hint.text = tr("Przeciągnij palcem, żeby iść. Miecz atakuje sam.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 0.8))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hint)


func _on_gesture_toggled(on: bool) -> void:
	gesture_button.text = tr("Gest: wł.") if on else tr("Gest: wył.")
	if hero:
		hero.gesture = on

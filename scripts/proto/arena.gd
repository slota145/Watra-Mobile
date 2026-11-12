extends Node2D
## Prototyp walki: polana z trawy, Wojciech z lewitującym mieczem i kukły treningowe z Watry.
## Chodzenie: przeciągnij palcem w dowolnym miejscu ekranu (pływająca gałka). Atak: trzymaj przycisk miecza
## w dolnym rogu (wokół niego 4 puste miejsca na umiejętności). „Menu” otwiera okno pauzy: przyciski po lewej
## stronie, gest ręką postaci przy ataku, wyjście do menu głównego.
## Wszystko budowane w kodzie, żeby prototyp łatwo było zmieniać i wyrzucić.

const ARENA := Rect2(-360, -560, 720, 1120)
const DUMMIES := [Vector2(0, -70), Vector2(-80, 40), Vector2(90, 60)]

var hero: ProtoHero
var weapon: ProtoWeapon
var joystick: Joystick
var menu_button: Button
var actions: ActionCluster
var pause_menu: PauseMenu


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
	hero.gesture = Game.gesture
	world.add_child(hero)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)
	hero.add_child(camera)

	weapon = ProtoWeapon.new()
	weapon.name = "Weapon"
	weapon.hero = hero
	for p in DUMMIES:
		var dummy := ProtoDummy.new()
		dummy.position = p
		world.add_child(dummy)
		weapon.targets.append(dummy)
	world.add_child(weapon)
	actions.attack.pressed.connect(func() -> void: weapon.attack_held = true)
	actions.attack.released.connect(func() -> void: weapon.attack_held = false)


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
	menu_button = Button.new()
	menu_button.text = tr("Menu")
	menu_button.custom_minimum_size = Vector2(72, 44)
	menu_button.pressed.connect(_open_menu)
	top.add_child(menu_button)
	var hint := Label.new()
	hint.text = tr("Przeciągnij palcem, żeby iść. Trzymaj miecz, żeby atakować.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 0.8))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hint)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(fill)
	# dolny róg (prawy albo lewy - ustawienie): atak i miejsca na umiejętności
	actions = ActionCluster.new()
	actions.left_handed = Game.left_handed
	column.add_child(actions)
	joystick.blocked = [top, actions]
	pause_menu = PauseMenu.new()  # ostatnie dziecko: nad całym interfejsem
	pause_menu.visible = false
	pause_menu.closed.connect(_apply_settings)
	layer.add_child(pause_menu)


func _open_menu() -> void:
	joystick.release()
	actions.attack.release()
	pause_menu.open()


## Po zamknięciu okna pauzy: ustawienia z Game na przyciski i postać.
func _apply_settings() -> void:
	actions.left_handed = Game.left_handed
	hero.gesture = Game.gesture


## Przycisk „wstecz” na Androidzie otwiera i zamyka pauzę; przełączenie telefonu na inną aplikację ją otwiera.
func _notification(what: int) -> void:
	if not pause_menu:
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and pause_menu.visible:
		pause_menu.close()
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED] and not pause_menu.visible:
		_open_menu()

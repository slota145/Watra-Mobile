extends Node2D
## Prototyp walki: polana z trawy, Wojciech z lewitującym mieczem i kukły treningowe z Watry.
## Chodzenie: przeciągnij palcem w dowolnym miejscu ekranu (pływająca gałka). Atak: trzymaj przycisk miecza
## w dolnym rogu (wokół niego 4 puste miejsca na umiejętności). „Menu” otwiera okno pauzy: przyciski po lewej
## stronie, gest ręką postaci przy ataku, wyjście do menu głównego.
## Wszystko budowane w kodzie, żeby prototyp łatwo było zmieniać i wyrzucić.
## Dwa tryby: baza (prototype.tscn - kukły i Watra; dotknięcie Watry przenosi do lochu) i loch z Hordą
## (horde.tscn, `horde = true` - ciągły strumień goblinów, pasek zdrowia, licznik pokonanych, po śmierci okno wyniku).

const ARENA := Rect2(-360, -560, 720, 1120)
const DUMMIES := [Vector2(0, -70), Vector2(-80, 40), Vector2(90, 60)]
const WATRA_POS := Vector2(0, -190)
const BASE_SCENE := "res://scenes/prototype.tscn"
const HORDE_SCENE := "res://scenes/horde.tscn"
## Po śmierci postaci okno wyniku pojawia się po tylu sekundach (widać, jak pada).
const RESULT_DELAY := 1.2

## Loch z Hordą zamiast bazy.
@export var horde := false

var hero: ProtoHero
var weapon: ProtoWeapon
var joystick: Joystick
var menu_button: Button
var actions: ActionCluster
var pause_menu: PauseMenu
var watra: ProtoWatra
var horde_spawner: ProtoHorde
var health_bar: ProgressBar
var kills_label: Label
var time_label: Label
var result: RunResult


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
	if horde:
		horde_spawner = ProtoHorde.new()
		horde_spawner.name = "Horde"
		horde_spawner.hero = hero
		horde_spawner.world = world
		horde_spawner.bounds = ARENA.grow(-8)
		horde_spawner.kills_changed.connect(func(k: int) -> void: kills_label.text = tr("Pokonane: %d") % k)
		add_child(horde_spawner)
		hero.health_changed.connect(func(hp: int, max_hp: int) -> void:
			health_bar.max_value = max_hp
			health_bar.value = hp)
		hero.died.connect(_on_hero_died)
	else:
		for p in DUMMIES:
			var dummy := ProtoDummy.new()
			dummy.position = p
			world.add_child(dummy)
			weapon.targets.append(dummy)
		watra = ProtoWatra.new()
		watra.name = "Watra"
		watra.position = WATRA_POS
		watra.entered.connect(func() -> void: Game.change_scene(HORDE_SCENE))
		world.add_child(watra)
		hero.obstacles.append(Vector3(WATRA_POS.x, WATRA_POS.y, ProtoWatra.RADIUS))
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
	if horde:
		grass.modulate = Color(0.72, 0.68, 0.8)  # loch: ta sama trawa, chłodniej i ciemniej (Horda)
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
	if horde:
		_make_horde_bar(top)
	else:
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
	if horde:
		result = RunResult.new()
		result.visible = false
		result.retry.connect(func() -> void: Game.change_scene(HORDE_SCENE))
		result.back_to_base.connect(func() -> void: Game.change_scene(BASE_SCENE))
		safe.add_child(result)
	pause_menu = PauseMenu.new()  # ostatnie dziecko: nad całym interfejsem
	pause_menu.visible = false
	if horde:
		pause_menu.base_scene = BASE_SCENE
	pause_menu.closed.connect(_apply_settings)
	layer.add_child(pause_menu)


## Pasek u góry w lochu: zdrowie Wojciecha, a pod nim liczba pokonanych potworów i czas.
func _make_horde_bar(top: HBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(box)
	health_bar = ProgressBar.new()
	health_bar.max_value = ProtoHero.MAX_HP
	health_bar.value = ProtoHero.MAX_HP
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 14)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.05, 0.05, 0.85)
	bg.border_color = Color(0.85, 0.62, 0.3)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.16, 0.12)
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(health_bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	kills_label = _hud_label(tr("Pokonane: %d") % 0)
	kills_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kills_label)
	time_label = _hud_label("0:00")
	row.add_child(time_label)


func _hud_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(_delta: float) -> void:
	if horde_spawner and time_label:
		var s := int(horde_spawner.time)
		time_label.text = "%d:%02d" % [s / 60, s % 60]


## Śmierć Wojciecha w lochu: chwila na upadek, potem okno wyniku i pauza.
func _on_hero_died() -> void:
	joystick.release()
	actions.attack.release()
	weapon.attack_held = false
	await get_tree().create_timer(RESULT_DELAY).timeout
	result.show_result(horde_spawner.kills, horde_spawner.time)
	get_tree().paused = true


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
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED] and not pause_menu.visible \
			and not (result and result.visible):
		_open_menu()

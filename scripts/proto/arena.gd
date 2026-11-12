extends Node2D
## Prototyp walki: polana z trawy, Wojciech z lewitującym mieczem i kukły treningowe z Watry.
## Chodzenie: przeciągnij palcem w dowolnym miejscu ekranu (pływająca gałka). Atak: trzymaj przycisk miecza
## w dolnym rogu (wokół niego 4 puste miejsca na umiejętności). „Menu” otwiera okno pauzy: przyciski po lewej
## stronie, gest ręką postaci przy ataku, wyjście do menu głównego.
## Wszystko budowane w kodzie, żeby prototyp łatwo było zmieniać i wyrzucić.
## Dwa tryby: baza (prototype.tscn - kukły i Watra; dotknięcie Watry przenosi do lochu) i loch z Hordą
## (horde.tscn, `horde = true` - ciągły strumień goblinów, pasek zdrowia, licznik pokonanych, po śmierci okno wyniku).
## Żar: iskry z goblinów liczy ProtoHorde i zapełniają pasek żaru (DungeonLevels.SUMMON_COST). Pełny pasek pokazuje
## przycisk „Przyzwij Wodza”: przyzwanie zjada żar z paska, gobliny uciekają, wchodzi Wódz Goblinów (ProtoChief) z własnym
## paskiem zdrowia. Po jego śmierci spada skrzynia z żarem (ProtoChest), a po jej otwarciu cały żar z wyprawy trafia do
## Watry (`Game.bank_embers`), poziom lochu zostaje przebity (`Game.beat_level`) i pokazuje się okno zwycięstwa.
## Ucieczka (okno pauzy) i śmierć gaszą żar z wyprawy. W bazie Watra pokazuje zgromadzony żar, a jej dotknięcie
## otwiera wybór poziomu lochu (LevelPicker).
## Rozwój postaci (HeroLevels, stan w Game): gobliny i Wódz dają doświadczenie (śmierć go nie zabiera), cienki pasek
## doświadczenia (złoty) z poziomem postaci u góry (w lochu pod paskami zdrowia i many, liczby na paskach, w bazie obok „Menu”), awans leczy i pokazuje
## efekt na postaci, odblokowuje miejsca na umiejętności. Okno wyniku podsumowuje zdobyte doświadczenie.

const ARENA := Rect2(-360, -560, 720, 1120)
const DUMMIES := [Vector2(-100, 0), Vector2(100, 10), Vector2(0, 170)]
const WATRA_POS := Vector2(0, -115)
const BASE_SCENE := "res://scenes/prototype.tscn"
const HORDE_SCENE := "res://scenes/horde.tscn"
## Po śmierci postaci okno wyniku pojawia się po tylu sekundach (widać, jak pada).
const RESULT_DELAY := 1.2
## Wódz pojawia się w takiej odległości od postaci (nad nią - widać go od razu).
const CHIEF_OFFSET := Vector2(0, -110)
## Skrzynia spada po tylu sekundach od śmierci Wodza.
const CHEST_DELAY := 1.4
## Okno zwycięstwa po tylu sekundach od otwarcia skrzyni (iskry zdążą dolecieć).
const VICTORY_DELAY := 2.2
## Ziemia pod wszystkim - także pod ciałami i czerwonymi kołami ostrzeżeń (z_index -1).
const GROUND_Z := -10
const EMBER_FILL := Color(1.0, 0.55, 0.12)
const EMBER_FULL := Color(1.0, 0.8, 0.3)

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
var embers_label: Label
var level_label: Label
## Poziom postaci i pasek doświadczenia.
var hero_level_label: Label
var xp_bar: ProgressBar
## Pasek many między zdrowiem a doświadczeniem (na razie pełny - manę zużyją umiejętności).
var mana_bar: ProgressBar
## Liczby na paskach („obecne / największe”).
var health_text: Label
var mana_text: Label
var xp_text: Label
## Doświadczenie zdobyte w tej wyprawie i poziom postaci na jej starcie (do podsumowania).
var run_xp := 0
var _start_hero_level := 1
## Licznik zgonów w trybie deweloperskim (widoczny, gdy nieśmiertelność jest włączona).
var deaths_label: Label
var ember_bar: ProgressBar
var summon_button: Button
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var result: RunResult
var picker: LevelPicker
## Poziom lochu tej wyprawy (Game.dungeon_level).
var level := 1
var chief: ProtoChief
var chest: ProtoChest
## Etap wyprawy: horde (zbieranie żaru), boss (walka z Wodzem), loot (skrzynia), won (po zwycięstwie).
var phase := "horde"
var _fill_style: StyleBoxFlat
var _time := 0.0


func _ready() -> void:
	if horde:
		level = Game.dungeon_level
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
	hero.immortal = Game.dev_immortal
	world.add_child(hero)
	_start_hero_level = Game.hero_level
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
	weapon.auto_attack = Game.auto_attack
	weapon.damage_mult = HeroLevels.damage_mult(Game.hero_level)
	if horde:
		horde_spawner = ProtoHorde.new()
		horde_spawner.name = "Horde"
		horde_spawner.hero = hero
		horde_spawner.world = world
		horde_spawner.bounds = ARENA.grow(-8)
		horde_spawner.power = DungeonLevels.power(level)
		horde_spawner.kills_changed.connect(func(k: int) -> void:
			kills_label.text = tr("Pokonane: %d") % k
			_gain_xp(HeroLevels.goblin_xp(level)))
		horde_spawner.embers_changed.connect(_on_embers)
		add_child(horde_spawner)
		hero.health_changed.connect(func(hp: int, max_hp: int) -> void:
			health_bar.max_value = max_hp
			health_bar.value = hp
			health_text.text = "%d / %d" % [hp, max_hp])
		hero.mana_changed.connect(func(mana: int, max_mana: int) -> void:
			mana_bar.max_value = max_mana
			mana_bar.value = mana
			mana_text.text = "%d / %d" % [mana, max_mana])
		hero.set_level(Game.hero_level)
		hero.died.connect(_on_hero_died)
		hero.death_avoided.connect(func(n: int) -> void: deaths_label.text = tr("Zgony: %d") % n)
	else:
		for p in DUMMIES:
			var dummy := ProtoDummy.new()
			dummy.position = p
			world.add_child(dummy)
			weapon.targets.append(dummy)
		watra = ProtoWatra.new()
		watra.name = "Watra"
		watra.position = WATRA_POS
		watra.embers = Game.embers
		watra.brought = Game.embers_brought
		Game.embers_brought = 0
		watra.entered.connect(open_picker)
		world.add_child(watra)
		hero.obstacles.append(Vector3(WATRA_POS.x, WATRA_POS.y, ProtoWatra.RADIUS))
	world.add_child(weapon)
	if not horde:
		hero.set_level(Game.hero_level)
	actions.set_hero_level(Game.hero_level)
	_on_xp(Game.hero_level, Game.hero_xp, Game.xp_needed())
	Game.xp_changed.connect(_on_xp)
	Game.leveled_up.connect(_on_level_up)
	actions.attack.pressed.connect(func() -> void: weapon.attack_held = true)
	actions.attack.released.connect(func() -> void: weapon.attack_held = false)


## Trawa z Watry powtarzana na całej polanie, z ciemniejszym brzegiem.
func _make_ground() -> void:
	var edge := ColorRect.new()
	edge.color = Color(0.11, 0.16, 0.1)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.position = ARENA.position - Vector2(400, 400)
	edge.size = ARENA.size + Vector2(800, 800)
	edge.z_index = GROUND_Z
	add_child(edge)
	var grass := Sprite2D.new()
	grass.texture = preload("res://assets/watra/grass.png")
	grass.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grass.region_enabled = true
	grass.region_rect = Rect2(Vector2.ZERO, ARENA.size)
	grass.centered = false
	grass.position = ARENA.position
	grass.z_index = GROUND_Z
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
	if not horde:  # baza: poziom postaci i doświadczenie obok „Menu”
		var xp_box := VBoxContainer.new()
		xp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		xp_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		xp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(xp_box)
		_make_xp_row(xp_box)
	if horde:
		_make_horde_bar(top)
		_make_boss_bar(column)
		_make_summon_button(column)
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
		joystick.blocked.append(summon_button)
		result = RunResult.new()
		result.visible = false
		result.retry.connect(_on_retry)
		result.back_to_base.connect(func() -> void: Game.change_scene(BASE_SCENE))
		safe.add_child(result)
	pause_menu = PauseMenu.new()  # ostatnie dziecko: nad całym interfejsem
	pause_menu.visible = false
	if horde:
		pause_menu.base_scene = BASE_SCENE
	else:
		picker = LevelPicker.new()
		picker.visible = false
		picker.enter.connect(enter_dungeon)
		safe.add_child(picker)
	pause_menu.closed.connect(_apply_settings)
	pause_menu.dev_embers.connect(_on_dev_embers)
	layer.add_child(pause_menu)


## Pasek u góry w lochu: zdrowie Wojciecha, pod nim pasek żaru (do przyzwania Wodza), a niżej poziom lochu,
## liczba pokonanych potworów, żar z wyprawy i czas.
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
	health_text = _bar_text(health_bar, 10)
	mana_bar = ProgressBar.new()
	mana_bar.max_value = HeroLevels.MANA_BASE
	mana_bar.value = HeroLevels.MANA_BASE
	mana_bar.show_percentage = false
	mana_bar.custom_minimum_size = Vector2(0, 11)
	mana_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mana_bg := StyleBoxFlat.new()
	mana_bg.bg_color = Color(0.03, 0.05, 0.12, 0.85)
	mana_bg.border_color = Color(0.3, 0.45, 0.7)
	mana_bg.set_border_width_all(1)
	mana_bg.set_corner_radius_all(2)
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.2, 0.42, 0.9)
	mana_fill.set_corner_radius_all(2)
	mana_bar.add_theme_stylebox_override("background", mana_bg)
	mana_bar.add_theme_stylebox_override("fill", mana_fill)
	box.add_child(mana_bar)
	mana_text = _bar_text(mana_bar, 9)
	_make_xp_row(box)
	ember_bar = ProgressBar.new()
	ember_bar.max_value = DungeonLevels.SUMMON_COST
	ember_bar.value = 0
	ember_bar.show_percentage = false
	ember_bar.custom_minimum_size = Vector2(0, 8)
	ember_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ember_bg := StyleBoxFlat.new()
	ember_bg.bg_color = Color(0.1, 0.05, 0.02, 0.85)
	ember_bg.border_color = Color(0.6, 0.35, 0.12)
	ember_bg.set_border_width_all(1)
	ember_bg.set_corner_radius_all(3)
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = EMBER_FILL
	_fill_style.set_corner_radius_all(3)
	ember_bar.add_theme_stylebox_override("background", ember_bg)
	ember_bar.add_theme_stylebox_override("fill", _fill_style)
	box.add_child(ember_bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	level_label = _hud_label(tr("Loch %d") % level)
	level_label.custom_minimum_size = Vector2(46, 0)
	row.add_child(level_label)
	kills_label = _hud_label(tr("Pokonane: %d") % 0)
	kills_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kills_label)
	var icon := TextureRect.new()
	icon.texture = preload("res://assets/watra/ember_icon.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	embers_label = _hud_label("0")
	embers_label.custom_minimum_size = Vector2(34, 0)
	row.add_child(embers_label)
	time_label = _hud_label("0:00")
	row.add_child(time_label)
	deaths_label = _hud_label(tr("Zgony: %d") % 0)
	deaths_label.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
	deaths_label.visible = Game.dev_immortal
	box.add_child(deaths_label)


## Wiersz postaci: „Poz. N” i cienki pasek doświadczenia.
func _make_xp_row(parent: Container) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	hero_level_label = _hud_label(tr("Poz. %d") % Game.hero_level)
	hero_level_label.add_theme_font_size_override("font_size", 11)
	hero_level_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	row.add_child(hero_level_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 11)
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.02, 0.85)
	bg.border_color = Color(0.55, 0.45, 0.2)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.8, 0.25)
	fill.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("background", bg)
	xp_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(xp_bar)
	xp_text = _bar_text(xp_bar, 9)


## Liczba na środku paska (z obwódką, czytelna na każdym kolorze wypełnienia).
func _bar_text(bar: ProgressBar, font_size: int) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_constant_override("line_spacing", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(l)
	return l


## Doświadczenie dla postaci (pokonany potwór) - liczone też do podsumowania wyprawy.
func _gain_xp(amount: int) -> void:
	if hero.dead:
		return
	run_xp += amount
	Game.add_xp(amount)


## Zmiana doświadczenia w Game: pasek i numer poziomu (na najwyższym poziomie pasek pełny).
func _on_xp(lvl: int, xp: int, need: int) -> void:
	hero_level_label.text = tr("Poz. %d") % lvl
	xp_bar.max_value = maxi(need, 1)
	xp_bar.value = xp if need > 0 else xp_bar.max_value
	xp_text.text = "%d / %d" % [xp, need] if need > 0 else tr("Najwyższy poziom")
	actions.set_hero_level(lvl, true)
	weapon.damage_mult = HeroLevels.damage_mult(lvl)
	if hero.max_hp != HeroLevels.max_hp(lvl) and not hero.dead:
		hero.set_level(lvl)  # np. reset postaci w trybie deweloperskim


## Awans: efekt na postaci (pełne zdrowie, napis, dźwięk), miga numer poziomu.
func _on_level_up(lvl: int) -> void:
	hero.level_up(lvl)
	hero_level_label.modulate = Color(2.0, 1.7, 0.8)
	hero_level_label.create_tween().tween_property(hero_level_label, "modulate", Color.WHITE, 0.8)


## Tryb deweloperski: żar na skróty - w lochu do paska wyprawy (szybkie przyzwanie Wodza), w bazie do Watry.
func _on_dev_embers(amount: int) -> void:
	if horde_spawner:
		horde_spawner._on_ember(amount)
	else:
		Game.embers += amount
		Game.save_game()
		watra.embers = Game.embers
		watra.embers_label.text = tr("Żar Watry: %d") % Game.embers


## Pasek zdrowia Wodza pod górnym rzędem (ukryty do przyzwania).
func _make_boss_bar(column: VBoxContainer) -> void:
	boss_box = VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 0)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.visible = false
	column.add_child(boss_box)
	var name_label := _hud_label(tr("Wódz Goblinów"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.45))
	boss_box.add_child(name_label)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size = Vector2(0, 10)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.03, 0.03, 0.9)
	bg.border_color = Color(0.55, 0.15, 0.1)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.62, 0.1, 0.08)
	fill.set_corner_radius_all(3)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar.add_theme_stylebox_override("fill", fill)
	boss_box.add_child(boss_bar)


## Przycisk „Przyzwij Wodza” u góry pod paskiem żaru (prośba autora: daleko od kciuka, żeby nie przyzwać
## Wodza przypadkiem w ferworze walki), widoczny przy pełnym pasku żaru.
func _make_summon_button(column: VBoxContainer) -> void:
	summon_button = Button.new()
	summon_button.text = tr("Przyzwij Wodza")
	summon_button.icon = preload("res://assets/watra/ember_icon.png")
	summon_button.add_theme_constant_override("icon_max_width", 22)
	summon_button.custom_minimum_size = Vector2(200, 52)
	summon_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summon_button.add_theme_font_size_override("font_size", 17)
	summon_button.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	summon_button.visible = false
	summon_button.pressed.connect(summon_chief)
	column.add_child(summon_button)


func _hud_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_time += delta
	if horde_spawner and time_label:
		var s := int(horde_spawner.time)
		time_label.text = "%d:%02d" % [s / 60, s % 60]
	if summon_button and summon_button.visible:  # pełny pasek pulsuje
		var k := 0.5 + 0.5 * sin(_time * 6.0)
		_fill_style.bg_color = EMBER_FILL.lerp(EMBER_FULL, k)
		summon_button.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.1, 0.85), k)


## Zmiana żaru z wyprawy: licznik, pasek (do kosztu przyzwania) i przycisk przyzwania przy pełnym pasku.
func _on_embers(e: int) -> void:
	embers_label.text = str(e)
	if phase != "horde":
		return
	ember_bar.value = mini(e, DungeonLevels.SUMMON_COST)
	var full := e >= DungeonLevels.SUMMON_COST
	summon_button.visible = full and not hero.dead
	if not full:
		_fill_style.bg_color = EMBER_FILL


## Przyzwanie Wodza: zjada żar z paska (nadwyżka zostaje), gobliny uciekają, Wódz wchodzi nad postacią.
func summon_chief() -> void:
	if phase != "horde" or hero.dead or horde_spawner.embers < DungeonLevels.SUMMON_COST:
		return
	phase = "boss"
	horde_spawner.embers -= DungeonLevels.SUMMON_COST
	embers_label.text = str(horde_spawner.embers)
	summon_button.visible = false
	ember_bar.visible = false
	horde_spawner.call_boss()
	chief = ProtoChief.new()
	chief.name = "Chief"
	chief.hero = hero
	chief.bounds = ARENA.grow(-24)
	chief.power = DungeonLevels.power(level)
	var spot := hero.position + CHIEF_OFFSET
	if not ARENA.grow(-40).has_point(spot):
		spot = hero.position - CHIEF_OFFSET
	chief.position = spot.clamp(ARENA.position + Vector2(40, 40), ARENA.end - Vector2(40, 40))
	chief.health_changed.connect(func(hp: int, max_hp: int) -> void:
		boss_bar.max_value = max_hp
		boss_bar.value = hp)
	chief.summon_minions.connect(func(points: Array) -> void:
		for p in points:
			horde_spawner.spawn_at(p))
	chief.died.connect(_on_chief_died)
	$World.add_child(chief)
	boss_bar.max_value = chief.max_hp
	boss_bar.value = chief.hp
	boss_box.visible = true


## Wódz padł: pozostałe gobliny uciekają, po chwili spada skrzynia.
func _on_chief_died(_c: ProtoChief) -> void:
	phase = "loot"
	_gain_xp(HeroLevels.chief_xp(level))
	horde_spawner.scatter()
	boss_box.visible = false
	var at := chief.position
	await get_tree().create_timer(CHEST_DELAY).timeout
	if hero.dead:
		return
	chest = ProtoChest.new()
	chest.name = "Chest"
	chest.hero = hero
	chest.embers = DungeonLevels.chest_embers(level)
	chest.position = at
	chest.ember_spawned.connect(func(e: ProtoEmber) -> void: e.collected.connect(horde_spawner._on_ember))
	chest.opened.connect(_on_chest_opened)
	$World.add_child(chest)


func _on_chest_opened() -> void:
	await get_tree().create_timer(VICTORY_DELAY).timeout
	victory()


## Zwycięstwo: cały żar z wyprawy do Watry, poziom przebity, okno zwycięstwa i pauza.
func victory() -> void:
	if phase == "won" or hero.dead:
		return
	phase = "won"
	horde_spawner.clock = false
	joystick.release()
	actions.attack.release()
	weapon.attack_held = false
	var banked := horde_spawner.embers
	_bank()
	var unlocked := level + 1 if Game.beat_level(level) else 0
	Game.save_if_dirty()
	result.show_victory(level, banked, unlocked, horde_spawner.kills, horde_spawner.time, hero.deaths)
	result.add_xp_lines(run_xp, Game.hero_level if Game.hero_level > _start_hero_level else 0)
	get_tree().paused = true


## „Jeszcze raz” po śmierci albo „Następny poziom” po zwycięstwie.
func _on_retry() -> void:
	if phase == "won":
		Game.dungeon_level = mini(level + 1, Game.unlocked_level())
		Game.save_game()
	Game.change_scene(HORDE_SCENE)


## Baza: wybór poziomu lochu po dotknięciu Watry.
func open_picker() -> void:
	joystick.release()
	actions.attack.release()
	picker.open(Game.dungeon_level, Game.unlocked_level())


func enter_dungeon(chosen: int) -> void:
	Game.dungeon_level = chosen
	Game.save_game()
	Game.change_scene(HORDE_SCENE)


## Śmierć Wojciecha w lochu: chwila na upadek, potem okno wyniku i pauza.
func _on_hero_died() -> void:
	joystick.release()
	actions.attack.release()
	weapon.attack_held = false
	await get_tree().create_timer(RESULT_DELAY).timeout
	summon_button.visible = false
	Game.save_if_dirty()
	result.show_result(horde_spawner.kills, horde_spawner.time, horde_spawner.embers)
	result.add_xp_lines(run_xp, Game.hero_level if Game.hero_level > _start_hero_level else 0)
	get_tree().paused = true


## Zebrany żar trafia do Watry (raz - licznik lochu się zeruje). Tylko po zwycięstwie nad Wodzem.
func _bank() -> void:
	if horde_spawner and not hero.dead:
		Game.bank_embers(horde_spawner.embers)
		horde_spawner.embers = 0


func _open_menu() -> void:
	joystick.release()
	actions.attack.release()
	Game.save_if_dirty()
	pause_menu.open(horde_spawner.embers if horde_spawner and phase != "won" else 0)


## Po zamknięciu okna pauzy: ustawienia z Game na przyciski i postać (także tryb deweloperski).
func _apply_settings() -> void:
	actions.left_handed = Game.left_handed
	hero.gesture = Game.gesture
	hero.immortal = Game.dev_immortal
	weapon.auto_attack = Game.auto_attack
	if deaths_label:
		deaths_label.visible = Game.dev_immortal


## Przycisk „wstecz” na Androidzie otwiera i zamyka pauzę; przełączenie telefonu na inną aplikację ją otwiera.
func _notification(what: int) -> void:
	if not pause_menu:
		return
	if picker and picker.visible:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			picker.close()
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and pause_menu.visible:
		pause_menu.back()
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED] and not pause_menu.visible \
			and not (result and result.visible):
		_open_menu()

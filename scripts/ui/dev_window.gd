class_name DevWindow
extends Control
## Okno trybu deweloperskiego (z pauzy, przycisk „Tryb deweloperski”) - do testów balansu (prośba autora 13.11.2026):
## nieśmiertelność, wszystkie poziomy lochu bez przebijania poprzednich (`Game.dev_all_levels`), skróty (+1 poziom,
## +100 żaru, +5 łupu, wszystkie umiejętności, kamienie, postać od nowa), poziom postaci ustawiany wprost
## (`Game.dev_set_level`) i każda statystyka przedmiotów ustawiana suwakiem do sufitu (`Game.dev_stats` - zastępuje
## sumę z założonych przedmiotów, ↺ przywraca przedmioty). Wszystko zapisuje się w ustawieniach (`user://settings.cfg`).
## Leży nad pauzą i działa przy zatrzymanej grze; przewija się palcem, gdy nie mieści się na ekranie.

## Żar do dodania (pauza przekazuje go arenie).
signal dev_embers(amount: int)
signal closed

const DEV_EMBERS := 100
const DEV_ITEMS := 5
const ACCENT := Color(1, 0.7, 0.5)
const CHANGED := Color(0.55, 0.95, 0.5)
## Górna granica suwaka dla statystyk bez sufitu w Items.CAPS (sufity mają pierwszeństwo).
const STAT_MAX := {"hp": 2000.0, "mana": 1000.0, "damage_pct": 500.0, "regen": 50.0, "xp_pct": 500.0,
	"crit_dmg_pct": 500.0, "life_on_kill": 200.0, "elite_dmg_pct": 500.0, "mana_regen": 50.0, Items.WEAPON_DAMAGE: 1000.0}

var immortal_toggle: CheckButton
var all_levels_toggle: CheckButton
var level_button: Button
var embers_button: Button
var items_button: Button
var skills_dev_button: Button
var gems_dev_button: Button
var reset_button: Button
var hero_level_label: Label
var clear_stats_button: Button
var close_button: Button
## Wiersze statystyk: statystyka -> {"label", "slider", "reset"}.
var stat_rows := {}
var _reset_armed := false
## Ustawianie suwaków przy otwarciu nie może zapisywać wartości (to nie ruch gracza).
var _syncing := false
var _scroll: ScrollContainer
var _column: VBoxContainer
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.06, 0.97)
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	var margin := MarginContainer.new()  # miejsce na pasek przewijania z prawej
	margin.add_theme_constant_override("margin_right", 10)
	_scroll.add_child(margin)
	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(290, 0)
	_column.add_theme_constant_override("separation", 6)
	margin.add_child(_column)
	_column.resized.connect(_fit)
	_label(_column, tr("Tryb deweloperski"), 20, Color(1, 0.78, 0.35)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	immortal_toggle = _toggle(tr("Nieśmiertelność"))
	immortal_toggle.toggled.connect(func(on: bool) -> void:
		_game.dev_immortal = on
		_game.save_settings())
	all_levels_toggle = _toggle(tr("Wszystkie poziomy lochu (bez przebijania)"))
	all_levels_toggle.toggled.connect(func(on: bool) -> void:
		_game.dev_all_levels = on
		_game.save_settings())
	var row := _row()
	level_button = _button(row, tr("+1 poz."))
	level_button.pressed.connect(func() -> void: _game.dev_level_up())
	embers_button = _button(row, tr("+%d żaru") % DEV_EMBERS)
	embers_button.pressed.connect(func() -> void: dev_embers.emit(DEV_EMBERS))
	items_button = _button(row, tr("+%d łupu") % DEV_ITEMS)
	items_button.pressed.connect(func() -> void: _game.dev_items(DEV_ITEMS))
	row = _row()
	skills_dev_button = _button(row, tr("+umiejętności"))
	skills_dev_button.pressed.connect(func() -> void: _game.dev_skills())
	gems_dev_button = _button(row, tr("+kamienie"))
	gems_dev_button.pressed.connect(func() -> void: _game.dev_gems())
	reset_button = _button(row, tr("Od nowa"))
	reset_button.pressed.connect(_on_reset)
	_make_level_row()
	_label(_column, tr("Statystyki"), 16, Color(1, 0.78, 0.35))
	var note := _label(_column, tr("Suwak zastępuje premię z przedmiotów (najwyżej do sufitu), ↺ wraca do przedmiotów."), 11, Color(1, 0.85, 0.6, 0.8))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clear_stats_button = _button(_column, tr("Wszystkie z przedmiotów"))
	clear_stats_button.pressed.connect(func() -> void:
		_game.dev_clear_stats()
		_sync())
	for stat in [Items.WEAPON_DAMAGE] + Items.STAT_FORMATS.keys():
		_make_stat_row(stat)
	close_button = _button(_column, tr("Wróć"))
	close_button.add_theme_color_override("font_color", Color(1, 0.92, 0.78))
	close_button.pressed.connect(close)


func open() -> void:
	_sync()
	_disarm_reset()
	visible = true
	_fit.call_deferred()


func close() -> void:
	visible = false
	_game.save_settings()
	closed.emit()


## Przycisk „wstecz”: zamyka okno (pauza zostaje).
func back() -> void:
	close()


## Najwyższa wartość suwaka: sufit z Items.CAPS albo STAT_MAX.
static func stat_max(stat: String) -> float:
	return Items.CAPS.get(stat, STAT_MAX.get(stat, 100.0))


## Opis wartości statystyki jak na przedmiocie („+25% obszaru umiejętności”).
static func stat_line(stat: String, value: float) -> String:
	if stat == Items.WEAPON_DAMAGE:
		var d := Items.weapon_damage_from(value)
		return Lang.t("Obrażenia broni: %d-%d") % [d.x, d.y]
	return Items.stat_text(stat, value)


## Ustawia suwaki, przełączniki i poziom postaci według Game (bez zapisywania).
func _sync() -> void:
	_syncing = true
	immortal_toggle.set_pressed_no_signal(_game.dev_immortal)
	all_levels_toggle.set_pressed_no_signal(_game.dev_all_levels)
	hero_level_label.text = tr("Poziom postaci: %d") % _game.hero_level
	var gear: Dictionary = _game.gear()
	for stat in stat_rows:
		var value: float = float(gear.damage.x) if stat == Items.WEAPON_DAMAGE else gear[stat]
		if stat == Items.WEAPON_DAMAGE and gear.damage == Vector2i.ZERO:
			value = ProtoWeapon.DAMAGE.x  # bez broni postać tnie zwykłym mieczem
		stat_rows[stat].slider.value = value
		_show_stat(stat, value)
		if stat == Items.WEAPON_DAMAGE and gear.damage == Vector2i.ZERO:
			stat_rows[stat].label.text = tr("Obrażenia ciosu: bez kolczyka %d-%d") % [ProtoWeapon.DAMAGE.x, ProtoWeapon.DAMAGE.y]
	_syncing = false


func _show_stat(stat: String, value: float) -> void:
	var r: Dictionary = stat_rows[stat]
	var changed: bool = _game.dev_stats.has(stat)
	r.label.text = stat_line(stat, value)
	r.label.add_theme_color_override("font_color", CHANGED if changed else Color(1, 0.92, 0.78))
	r.reset.disabled = not changed


func _make_level_row() -> void:
	hero_level_label = _label(_column, "", 14, Color(1, 0.92, 0.78))
	var row := _row()
	for step in [-10, -1, 1, 10]:
		var b := _button(row, ("%+d" % step))
		b.pressed.connect(func() -> void:
			_game.dev_set_level(_game.hero_level + step)
			_sync())


func _make_stat_row(stat: String) -> void:
	var label := _label(_column, "", 12, Color(1, 0.92, 0.78))
	var row := _row()
	var step := 1.0 if stat not in Items.DECIMAL_STATS else 0.1
	var minus := _button(row, "−")
	minus.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	minus.custom_minimum_size = Vector2(44, 44)
	var slider := HSlider.new()
	slider.min_value = 1.0 if stat == Items.WEAPON_DAMAGE else 0.0
	slider.max_value = stat_max(stat)
	slider.step = step
	slider.custom_minimum_size = Vector2(0, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_FILL
	row.add_child(slider)
	var plus := _button(row, "+")
	plus.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	plus.custom_minimum_size = Vector2(44, 44)
	var reset := _button(row, "↺")
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.custom_minimum_size = Vector2(44, 44)
	stat_rows[stat] = {"label": label, "slider": slider, "reset": reset}
	slider.value_changed.connect(func(v: float) -> void:
		if _syncing:
			return
		_game.dev_set_stat(stat, v)
		_show_stat(stat, v))
	minus.pressed.connect(func() -> void: slider.value -= step)
	plus.pressed.connect(func() -> void: slider.value += step)
	reset.pressed.connect(func() -> void:
		_game.dev_clear_stat(stat)
		_sync())


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = tr("Na pewno?")
		return
	_disarm_reset()
	_game.reset_hero()
	_sync()


func _disarm_reset() -> void:
	_reset_armed = false
	reset_button.text = tr("Od nowa")


## Okno nie wyższe niż ekran (minus margines) - reszta przewija się palcem.
func _fit() -> void:
	var limit := get_viewport_rect().size.y - 40.0
	_scroll.custom_minimum_size = Vector2(300, minf(maxf(_column.size.y, _column.get_combined_minimum_size().y), limit))


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_column.add_child(row)
	return row


func _toggle(text: String) -> CheckButton:
	var t := CheckButton.new()
	t.text = text
	t.custom_minimum_size = Vector2(0, 44)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_color_override("font_color", ACCENT)
	_column.add_child(t)
	return t


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", ACCENT)
	b.clip_text = true
	parent.add_child(b)
	return b


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

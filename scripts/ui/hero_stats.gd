class_name HeroStats
extends Control
## Okno „Postać” (z okna pauzy): poziom i doświadczenie, statystyki postaci na obecnym poziomie (zdrowie, mana, obrażenia
## miecza, szybkość ataku, szybkość ruchu, miejsca na umiejętności) i to, co da następny awans - żeby było widać,
## co daje poziom. Liczby bierze z HeroLevels, ProtoHero i ProtoWeapon. Działa przy zatrzymanej grze (PROCESS_MODE_ALWAYS).

signal closed

const GOLD := Color(1, 0.78, 0.35)
const TEXT := Color(1, 0.92, 0.78)
const UP := Color(0.55, 0.95, 0.5)

var back_button: Button
## Wiersze statystyk: nazwa -> [etykieta wartości, etykieta przyrostu z następnym poziomem].
var rows := {}
var _title: Label
var _xp_label: Label
var _grid: GridContainer
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
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
	style.border_color = Color(0.85, 0.62, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(280, 0)
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	_title = _label(column, "", 22, GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label = _label(column, "", 13, TEXT)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var head := HBoxContainer.new()
	column.add_child(head)
	var spacer := _label(head, "", 11, TEXT)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var next := _label(head, tr("Następny poziom"), 11, UP)
	next.custom_minimum_size = Vector2(96, 0)
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(_grid)
	for key in ["hp", "mana", "damage", "speed", "move", "slots"]:
		var name_label := _label(_grid, _stat_name(key), 14, TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := _label(_grid, "", 14, GOLD)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var up := _label(_grid, "", 13, UP)
		up.custom_minimum_size = Vector2(70, 0)
		up.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rows[key] = [value, up]
	var note := _label(column, tr("Awans leczy do pełna."), 11, Color(1, 0.85, 0.6, 0.8))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button = Button.new()
	back_button.text = tr("Wróć")
	back_button.custom_minimum_size = Vector2(0, 48)
	back_button.pressed.connect(close)
	column.add_child(back_button)


## Pokazuje okno z liczbami na obecny poziom postaci.
func open() -> void:
	refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


## Wpisuje statystyki obecnego poziomu i przyrost z następnym poziomem.
func refresh() -> void:
	var lvl: int = _game.hero_level
	var top := lvl >= HeroLevels.MAX_LEVEL
	_title.text = tr("Poziom %d") % lvl
	var need: int = _game.xp_needed()
	_xp_label.text = tr("Doświadczenie: %d / %d") % [_game.hero_xp, need] if need > 0 else tr("Najwyższy poziom")
	var nxt := mini(lvl + 1, HeroLevels.MAX_LEVEL)
	var dmg := damage_range(lvl)
	_put("hp", str(HeroLevels.max_hp(lvl)), "+%d" % (HeroLevels.max_hp(nxt) - HeroLevels.max_hp(lvl)), top)
	_put("mana", str(HeroLevels.max_mana(lvl)), "+%d" % (HeroLevels.max_mana(nxt) - HeroLevels.max_mana(lvl)), top)
	_put("damage", "%d-%d" % [dmg.x, dmg.y], "+%d%%" % roundi(HeroLevels.DAMAGE_STEP * 100.0), top)
	_put("speed", tr("%.2f /s") % attacks_per_second(), "", true)
	_put("move", str(roundi(ProtoHero.SPEED)), "", true)
	var slots := HeroLevels.skill_slots(lvl)
	var next_slot := ""
	for l in HeroLevels.SKILL_SLOT_LEVELS:
		if l > lvl:
			next_slot = tr("na poz. %d") % l
			break
	_put("slots", "%d / %d" % [slots, HeroLevels.SKILL_SLOT_LEVELS.size()], next_slot, next_slot == "")


## Obrażenia jednego cięcia miecza na danym poziomie (od-do).
static func damage_range(level: int) -> Vector2i:
	var m := HeroLevels.damage_mult(level)
	return Vector2i(roundi(ProtoWeapon.DAMAGE.x * m), roundi(ProtoWeapon.DAMAGE.y * m))


## Ile cięć na sekundę przy trzymanym ataku (rozbieg + cięcie + powrót + odpoczynek).
static func attacks_per_second() -> float:
	return 1.0 / (ProtoWeapon.WINDUP + ProtoWeapon.SWING + ProtoWeapon.RECOVER + ProtoWeapon.COOLDOWN)


func _put(key: String, value: String, up: String, no_up: bool) -> void:
	rows[key][0].text = value
	rows[key][1].text = "" if no_up else up


func _stat_name(key: String) -> String:
	match key:
		"hp":
			return tr("Zdrowie")
		"mana":
			return tr("Mana")
		"damage":
			return tr("Obrażenia miecza")
		"speed":
			return tr("Szybkość ataku")
		"move":
			return tr("Szybkość ruchu")
	return tr("Miejsca na umiejętności")


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

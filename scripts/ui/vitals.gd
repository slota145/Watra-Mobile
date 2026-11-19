class_name Vitals
extends Control
## Paski zdrowia i many u góry ekranu (obok przycisku „Menu”), pod nimi ikonki włączonych aur.
## Część many zarezerwowana przez aury jest ciemna i kreskowana po prawej stronie paska.

const BAR := Vector2(150, 9)
const GAP := 3.0
const ICON := 9.0
const HEALTH := Color(0.8, 0.18, 0.15)
const MANA := Color(0.25, 0.45, 0.95)
const BACK := Color(0.05, 0.03, 0.03, 0.75)
const RESERVED := Color(0.12, 0.14, 0.3, 0.95)

var hero: ProtoHero


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(BAR.x + 2, BAR.y * 2 + GAP * 2 + ICON + 2)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not hero:
		return
	var font := ThemeDB.fallback_font
	var y := 1.0
	_bar(y, hero.health / hero.max_health(), HEALTH, 0.0)
	_label(font, y, "%d/%d" % [ceili(hero.health), roundi(hero.max_health())])
	y += BAR.y + GAP
	var reserved := hero.reserved()
	_bar(y, hero.mana / hero.full_mana(), MANA, reserved)
	_label(font, y, "%d/%d" % [floori(hero.mana), roundi(hero.max_mana())])
	y += BAR.y + GAP
	var x := ICON / 2.0 + 1.0
	for id in hero.auras:
		if AuraData.is_aura(id):
			var c := Vector2(x, y + ICON / 2.0)
			draw_circle(c, ICON / 2.0, Color(0, 0, 0, 0.6))
			draw_circle(c, ICON / 2.0 - 1.5, AuraData.color_of(id))
			x += ICON + 3.0


## Pasek: tło, wypełnienie i (dla many) zarezerwowana część po prawej.
func _bar(y: float, fill: float, color: Color, reserved: float) -> void:
	var rect := Rect2(Vector2(1, y), BAR)
	draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.8))
	draw_rect(rect, BACK)
	draw_rect(Rect2(rect.position, Vector2(BAR.x * clampf(fill, 0.0, 1.0), BAR.y)), color)
	if reserved > 0.0:
		var w := BAR.x * reserved
		var r := Rect2(rect.end.x - w, y, w, BAR.y)
		draw_rect(r, RESERVED)
		var sx := r.position.x + 2.0
		while sx < r.end.x:
			draw_line(Vector2(sx, r.end.y), Vector2(minf(sx + BAR.y, r.end.x), y), Color(0.4, 0.5, 0.9, 0.5), 1.0)
			sx += 4.0
	draw_rect(Rect2(rect.position, Vector2(BAR.x, 2)), Color(1, 1, 1, 0.15))


func _label(font: Font, y: float, text: String) -> void:
	var size := 8
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(1 + (BAR.x - w) / 2.0, y + BAR.y - 1)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 0.97, 0.9))

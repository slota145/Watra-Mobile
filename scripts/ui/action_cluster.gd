class_name ActionCluster
extends Control
## Przyciski pod kciuk: duży przycisk ataku w dolnym rogu ekranu i 4 miejsca na umiejętności na łuku wokół niego
## (od boku ekranu do góry, jak w grach mobilnych). Domyślnie w prawym rogu; `left_handed` przenosi całość
## do lewego (lustrzane odbicie). Umiejętności jeszcze nie ma - miejsca są puste.

## Bok kwadratu, w którym leżą przyciski (piksele gry).
const SIZE := 156.0
const ATTACK_RADIUS := 32.0
const SKILL_RADIUS := 22.0
## Odległość środków umiejętności od środka ataku i ich kąty po prawej stronie (180 - w lewo, 270 - w górę).
const ORBIT := 96.0
const SKILL_ANGLES := [180.0, 210.0, 240.0, 270.0]
const SKILL_SLOTS := 4

var attack: ActionButton
var skills: Array[ActionButton] = []
## Przyciski w lewym dolnym rogu.
var left_handed := false:
	set(value):
		left_handed = value
		if is_node_ready():
			_layout()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SIZE, SIZE)
	attack = _add_button(ATTACK_RADIUS)
	attack.icon = preload("res://assets/watra/iron_sword_icon.png")
	for i in SKILL_SLOTS:
		var b := _add_button(SKILL_RADIUS)
		b.empty = true
		skills.append(b)
	_layout()


## Ustawia przyciski w prawym albo lewym rogu (w rodzicu-kontenerze: do prawej albo do lewej krawędzi).
func _layout() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if left_handed else Control.SIZE_SHRINK_END
	var margin := ATTACK_RADIUS + 2.0
	var center := Vector2(margin if left_handed else SIZE - margin, SIZE - margin)
	_place(attack, center)
	for i in SKILL_SLOTS:
		var angle: float = SKILL_ANGLES[i]
		if left_handed:
			angle = 180.0 - angle  # odbicie: 180 -> 0 (w prawo), 270 -> -90 (w górę)
		_place(skills[i], center + Vector2.from_angle(deg_to_rad(angle)) * ORBIT)


func _add_button(radius: float) -> ActionButton:
	var b := ActionButton.new()
	b.radius = radius
	add_child(b)
	return b


func _place(b: ActionButton, center: Vector2) -> void:
	b.position = center - Vector2.ONE * b.radius

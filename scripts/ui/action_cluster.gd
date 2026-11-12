class_name ActionCluster
extends Control
## Prawy dolny róg ekranu, pod prawy kciuk: duży przycisk ataku i 4 miejsca na umiejętności na łuku wokół niego
## (od lewej do góry, jak w grach mobilnych). Umiejętności jeszcze nie ma - miejsca są puste.

## Bok kwadratu, w którym leżą przyciski (piksele gry).
const SIZE := 156.0
const ATTACK_RADIUS := 32.0
const SKILL_RADIUS := 22.0
## Odległość środków umiejętności od środka ataku i ich kąty (180 - w lewo, 270 - w górę).
const ORBIT := 96.0
const SKILL_ANGLES := [180.0, 210.0, 240.0, 270.0]
const SKILL_SLOTS := 4

var attack: ActionButton
var skills: Array[ActionButton] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SIZE, SIZE)
	var center := Vector2(SIZE - ATTACK_RADIUS - 2.0, SIZE - ATTACK_RADIUS - 2.0)
	attack = _add_button(center, ATTACK_RADIUS)
	attack.icon = preload("res://assets/watra/iron_sword_icon.png")
	for i in SKILL_SLOTS:
		var b := _add_button(center + Vector2.from_angle(deg_to_rad(SKILL_ANGLES[i])) * ORBIT, SKILL_RADIUS)
		b.empty = true
		skills.append(b)


func _add_button(center: Vector2, radius: float) -> ActionButton:
	var b := ActionButton.new()
	b.radius = radius
	b.position = center - Vector2.ONE * radius
	add_child(b)
	return b

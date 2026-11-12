class_name ActionCluster
extends Control
## Przyciski pod kciuk: duży przycisk ataku w dolnym rogu ekranu i 4 miejsca na umiejętności na łuku wokół niego
## (od boku ekranu do góry, jak w grach mobilnych). Domyślnie w prawym rogu; `left_handed` przenosi całość
## do lewego (lustrzane odbicie). `show_skills` wstawia ikony umiejętności z miejsc (Game.skill_slots: 0 - duży
## przycisk, pusty duży przycisk to zwykły cios), puste miejsce ma plus. Miejsca odblokowują się
## z poziomem postaci (`set_hero_level`, HeroLevels.SKILL_SLOT_LEVELS; zablokowane - kłódka i poziom).

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


## Blokuje miejsca na umiejętności powyżej poziomu postaci; `flash` - błysk na świeżo odblokowanych (awans).
func set_hero_level(level: int, flash := false) -> void:
	for i in SKILL_SLOTS:
		var need: int = HeroLevels.SKILL_SLOT_LEVELS[i]
		var was := skills[i].locked_level
		skills[i].locked_level = need if level < need else 0
		if flash and was > 0 and skills[i].locked_level == 0:
			skills[i].unlock_flash()


## Ikony umiejętności z miejsc (`slots` - Game.skill_slots). `slot_skills[i]` - co stoi w przycisku i (0 - atak).
var slot_skills: Array = ["", "", "", "", ""]


func show_skills(slots: Array) -> void:
	slot_skills = slots.duplicate()
	var main: String = slots[0] if slots[0] != "" else Skills.STRIKE
	attack.icon = Skills.icon_of(main)
	attack.queue_redraw()
	for i in SKILL_SLOTS:
		var id: String = slots[i + 1] if i + 1 < slots.size() else ""
		skills[i].empty = id == ""
		skills[i].icon = Skills.icon_of(id) if id != "" else null
		skills[i].queue_redraw()


## Przycisk miejsca `slot` (0 - atak, 1-4 - małe).
func button(slot: int) -> ActionButton:
	return attack if slot == 0 else skills[slot - 1]


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

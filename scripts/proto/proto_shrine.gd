class_name ProtoShrine
extends Node2D
## Kapliczka - cel na mapie lochu (DungeonGoals): omszały kamień z runą bóstwa z Watry (assets/watra/shrine.png),
## podbarwiony kolorem daru, pod słupem światła (GoalBeam). Postać musi na niej postać PRAY_TIME s (kółko postępu
## na ziemi; odejście cofa postęp) - wtedy bóstwo daje dar (DungeonGoals.GIFTS, sygnał `prayed`; działanie liczy arena),
## kapliczka gaśnie i szarzeje. Działa raz. Strzałka przy krawędzi ekranu - grupa GoalArrows.GROUP.

signal prayed(gift: String)

const TEXTURE := preload("res://assets/watra/shrine.png")
const SOUND := preload("res://assets/watra/shrine_pray.ogg")
const SCALE := 1.5
const RANGE := 30.0
const RING_RADIUS := 26.0

var hero: ProtoHero
var gift := "might"
var used := false
var goal_color := Color.WHITE
var goal_icon: Texture2D = TEXTURE

var _sprite: Sprite2D
var _label: Label
var _beam: GoalBeam
var _hold := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group(GoalArrows.GROUP)
	goal_color = DungeonGoals.GIFTS[gift]["color"]
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2.ONE * SCALE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 2.0)
	_sprite.modulate = Color.WHITE.lerp(goal_color, 0.35)
	add_child(_sprite)
	_label = Label.new()
	_label.text = "%s\n%s" % [tr("Kapliczka"), tr(DungeonGoals.GIFTS[gift]["name"])]
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.size = Vector2(140, 28)
	_label.position = Vector2(-70, -TEXTURE.get_height() * SCALE - 32.0)
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", goal_color.lightened(0.45))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 6
	add_child(_label)
	_beam = GoalBeam.new()
	_beam.color = goal_color
	add_child(_beam)
	# pojawienie się: błysk
	_sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE.lerp(goal_color, 0.35), 0.6)


func _process(delta: float) -> void:
	_time += delta
	if used or hero == null or hero.dead:
		return
	if hero.global_position.distance_to(global_position) <= RANGE:
		_hold += delta
	else:
		_hold = maxf(0.0, _hold - delta * 2.0)
	queue_redraw()
	if _hold >= DungeonGoals.PRAY_TIME:
		pray()


func goal_active() -> bool:
	return not used


## Modlitwa wysłuchana: dźwięk, błysk, kapliczka szarzeje, słup światła gaśnie, sygnał z darem.
func pray() -> void:
	if used:
		return
	used = true
	var audio := AudioStreamPlayer2D.new()
	audio.stream = SOUND
	audio.volume_db = -6.0
	add_child(audio)
	audio.play()
	_label.visible = false
	_beam.fade_out()
	var tween := create_tween()
	_sprite.modulate = goal_color * 2.5
	tween.tween_property(_sprite, "modulate", Color(0.55, 0.55, 0.6), 0.8)
	queue_redraw()
	prayed.emit(gift)


func _draw() -> void:
	if used:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 30.0, Color(goal_color, 0.15 + 0.05 * sin(_time * 3.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	GoalBeam.draw_ring(self, _hold / DungeonGoals.PRAY_TIME, RING_RADIUS, goal_color)

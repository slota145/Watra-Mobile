class_name ProtoZertwa
extends Node2D
## Krąg Żertwy - cel na mapie lochu (DungeonGoals, od 15. poziomu; jak w Watrze - zertwa.gd, uproszczony na telefon).
## Pień ofiarny z porożem (assets/watra/zertwa_stump.png) pod słupem światła. Postać staje przy nim na PRAY_TIME s
## (kółko postępu) - pień zapala krwawy krąg (DungeonGoals.ZER_RADIUS, spłaszczony jak cień), a zza jego brzegu co
## ZER_PACK_EVERY s wychodzą paczki potworów lochu (sygnał `pack` - spawnuje arena przez ProtoHorde.spawn_pack).
## Każdy potwór pokonany w kręgu to danina (`offer_kill`; elita - ZER_ELITE). Po ZER_GOAL daninie krąg gaśnie
## zwycięsko (sygnał `completed` - arena pokazuje wybór nagrody 1 z 3, ZertwaOffer). Po ZER_TIME s bez kompletu krąg
## gaśnie (sygnał `failed`). Napis nad pniem: danina i pozostały czas. Strzałka przy krawędzi - grupa GoalArrows.GROUP.

signal pack(at: Vector2, count: int)
signal completed(at: Vector2)
signal failed

const TEXTURE := preload("res://assets/watra/zertwa_stump.png")
const SOUND := preload("res://assets/watra/chief_roar.ogg")
const SCALE := 0.75
const RANGE := 30.0
const RING_RADIUS := 26.0
const PRAY_TIME := 1.0
const BLOOD := Color(0.85, 0.12, 0.1)

var hero: ProtoHero
var goal_color := Color(0.95, 0.3, 0.25)
var goal_icon: Texture2D = TEXTURE
## "sleep" - czeka, "active" - krąg płonie, "done" - nagroda wydana, "failed" - zgasł.
var state := "sleep"
var tribute := 0
var time_left := DungeonGoals.ZER_TIME

var _sprite: Sprite2D
var _beam: GoalBeam
var _label: Label
var _ring: Node2D
var _hold := 0.0
var _time := 0.0
var _pack_next := 0.5


func _ready() -> void:
	add_to_group(GoalArrows.GROUP)
	_ring = Node2D.new()  # krąg pod potworami (z_index -1, jak koła ostrzeżeń)
	_ring.z_index = -1
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(1.6, 1.3)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2.ONE * SCALE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 6.0)
	add_child(_sprite)
	_label = Label.new()
	_label.text = tr("Krąg Żertwy")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(140, 14)
	_label.position = Vector2(-70, -TEXTURE.get_height() * SCALE - 18.0)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", goal_color.lightened(0.35))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.02))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 6
	add_child(_label)
	_beam = GoalBeam.new()
	_beam.color = goal_color
	add_child(_beam)


func goal_active() -> bool:
	return state == "sleep" or state == "active"


func _process(delta: float) -> void:
	_time += delta
	_ring.queue_redraw()
	if hero == null or hero.dead:
		return
	match state:
		"sleep":
			if hero.global_position.distance_to(global_position) <= RANGE:
				_hold += delta
			else:
				_hold = maxf(0.0, _hold - delta * 2.0)
			queue_redraw()
			if _hold >= PRAY_TIME:
				ignite()
		"active":
			time_left -= delta
			_update_label()
			if time_left <= 0.0:
				_fail()
				return
			_pack_next -= delta
			if _pack_next <= 0.0:
				_pack_next = DungeonGoals.ZER_PACK_EVERY
				var at := global_position + Vector2.from_angle(randf() * TAU) * (DungeonGoals.ZER_RADIUS + 40.0) * Vector2(1.0, 0.5)
				pack.emit(at, randi_range(DungeonGoals.ZER_PACK.x, DungeonGoals.ZER_PACK.y))


## Czy punkt jest w kręgu (elipsa: w pionie połowa promienia).
func in_circle(p: Vector2) -> bool:
	var d := p - global_position
	return Vector2(d.x, d.y * 2.0).length() <= DungeonGoals.ZER_RADIUS


## Pień dotknięty: krąg się zapala, ryk, słup światła gaśnie, ruszają paczki potworów.
func ignite() -> void:
	if state != "sleep":
		return
	state = "active"
	_hold = 0.0
	queue_redraw()
	_beam.fade_out()
	_beam = null
	var audio := AudioStreamPlayer2D.new()
	audio.stream = SOUND
	audio.volume_db = -8.0
	audio.pitch_scale = 0.8
	add_child(audio)
	audio.play()
	_sprite.modulate = Color(2.5, 1.2, 1.1)
	create_tween().tween_property(_sprite, "modulate", Color(1.2, 0.85, 0.8), 0.6)
	_update_label()


## Potwór padł - jeśli w kręgu, liczy się do daniny.
func offer_kill(g: ProtoGoblin) -> void:
	if state != "active" or not in_circle(g.global_position):
		return
	tribute += DungeonGoals.ZER_ELITE if g.elite else 1
	_update_label()
	if tribute >= DungeonGoals.ZER_GOAL:
		state = "done"
		_finish(Color(1.6, 1.4, 1.0))
		completed.emit(global_position)


func _update_label() -> void:
	_label.text = tr("Danina %d / %d · %d s") % [mini(tribute, DungeonGoals.ZER_GOAL), DungeonGoals.ZER_GOAL, ceili(maxf(time_left, 0.0))]


func _fail() -> void:
	state = "failed"
	_finish(Color(0.5, 0.45, 0.45))
	failed.emit()


func _finish(tint: Color) -> void:
	_label.text = tr("Krąg zgasł") if state == "failed" else tr("Danina złożona!")
	create_tween().tween_property(_sprite, "modulate", tint, 0.6)
	var tween := _label.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_label, "modulate:a", 0.0, 0.5)


func _draw() -> void:
	if state == "sleep":
		GoalBeam.draw_ring(self, _hold / PRAY_TIME, RING_RADIUS, goal_color)


## Krwawy krąg na ziemi: obwódka z pulsującymi kreskami i słaba poświata w środku; przy końcu czasu miga.
func _draw_ring() -> void:
	if state != "active":
		return
	var r := DungeonGoals.ZER_RADIUS
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var alpha := 1.0
	if time_left < 10.0:
		alpha = 0.55 + 0.45 * absf(sin(_time * 6.0))
	_ring.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	_ring.draw_circle(Vector2.ZERO, r, Color(BLOOD, 0.1 * alpha))
	_ring.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(BLOOD, 0.85 * alpha), 3.0)
	_ring.draw_arc(Vector2.ZERO, r - 6.0, 0.0, TAU, 64, Color(BLOOD.lightened(0.2), (0.25 + 0.25 * pulse) * alpha), 1.5)
	# postęp daniny: jasny łuk po wewnętrznej stronie
	var done := clampf(float(tribute) / DungeonGoals.ZER_GOAL, 0.0, 1.0)
	if done > 0.0:
		_ring.draw_arc(Vector2.ZERO, r - 3.0, -PI / 2.0, -PI / 2.0 + TAU * done, 64, Color(1.0, 0.55, 0.3, alpha), 3.0)
	_ring.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

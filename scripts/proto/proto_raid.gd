class_name ProtoRaid
extends Node2D
## Napad Hordy - cel na mapie lochu (DungeonGoals, od 5. poziomu; pomysł autora 20.11.2026, ROADMAP punkt 4, krok 3).
## Obóz goblinów (namiot i przewrócony wóz z rudą - grafiki z Watry, assets/watra/raid_*.png) pod słupem światła.
## Gdy postać podejdzie bliżej niż WAKE, zaczyna się napad: przez RAID_TIME s co RAID_WAVE_EVERY s z RAID_SIDES stron
## nadbiegają paczki potworów (sygnał `wave` - arena spawnuje przez ProtoHorde.spawn_pack; potwory gonią postać).
## Czas płynie tylko, gdy postać stoi w kręgu obozu (RAID_RADIUS; spłaszczony jak cień); poza nim napis „Wróć do
## kręgu!”. Po czasie (`looted`) z wozu sypie się ruda - arena daje rudę (RAID_ORE) i z szansą RAID_RUNE runę.
## Strzałka przy krawędzi ekranu - grupa GoalArrows.GROUP.

signal wave(at: Vector2, count: int)
signal looted(at: Vector2)

const TENT := preload("res://assets/watra/raid_tent.png")
const CART := preload("res://assets/watra/raid_cart.png")
const ORE_BITS := preload("res://assets/watra/raid_ore.png")
const WIN_SOUND := preload("res://assets/watra/chest_open.ogg")
const SCALE := 0.85
const WAKE := 90.0
const RING := Color(1.0, 0.55, 0.35)

var hero: ProtoHero
var goal_color := Color(0.95, 0.6, 0.4)
var goal_icon: Texture2D = CART
## "sleep" - czeka, "active" - napad, "done" - obóz ograbiony.
var state := "sleep"
var time_left := DungeonGoals.RAID_TIME
## Czy postać stoi teraz w kręgu (czas płynie).
var inside := false

var _beam: GoalBeam
var _label: Label
var _ring: Node2D
var _cart: Sprite2D
var _time := 0.0
var _wave_next := 0.0


func _ready() -> void:
	add_to_group(GoalArrows.GROUP)
	_ring = Node2D.new()  # krąg pod potworami (z_index -1, jak koła ostrzeżeń)
	_ring.z_index = -1
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	var tent := Sprite2D.new()
	tent.texture = TENT
	tent.scale = Vector2.ONE * SCALE
	tent.position = Vector2(-22, -8)
	tent.offset = Vector2(0, -TENT.get_height() / 2.0 + 6.0)
	add_child(tent)
	_cart = Sprite2D.new()
	_cart.texture = CART
	_cart.scale = Vector2.ONE * SCALE
	_cart.position = Vector2(24, 4)
	_cart.offset = Vector2(0, -CART.get_height() / 2.0 + 4.0)
	add_child(_cart)
	_label = Label.new()
	_label.text = tr("Obóz Hordy")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(160, 14)
	_label.position = Vector2(-80, -TENT.get_height() * SCALE - 20.0)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", goal_color.lightened(0.35))
	_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 6
	add_child(_label)
	_beam = GoalBeam.new()
	_beam.color = goal_color
	add_child(_beam)


func goal_active() -> bool:
	return state != "done"


func _process(delta: float) -> void:
	_time += delta
	_ring.queue_redraw()
	if hero == null or hero.dead:
		return
	match state:
		"sleep":
			if hero.global_position.distance_to(global_position) <= WAKE:
				start()
		"active":
			inside = in_ring(hero.global_position)
			if inside:
				time_left -= delta
				_label.text = tr("Odeprzyj napad: %d s") % ceili(maxf(time_left, 0.0))
			else:
				_label.text = tr("Wróć do kręgu obozu!")
			if time_left <= 0.0:
				_finish()
				return
			_wave_next -= delta
			if _wave_next <= 0.0 and time_left > 3.0:
				_wave_next = DungeonGoals.RAID_WAVE_EVERY
				var base := randf() * TAU
				for i in DungeonGoals.RAID_SIDES:
					var angle := base + TAU * i / DungeonGoals.RAID_SIDES + randf_range(-0.4, 0.4)
					wave.emit(global_position + Vector2.from_angle(angle) * DungeonGoals.RAID_SPAWN_DIST,
							randi_range(DungeonGoals.RAID_PACK.x, DungeonGoals.RAID_PACK.y))


## Czy punkt jest w kręgu obozu (elipsa spłaszczona o połowę, jak cień).
func in_ring(point: Vector2) -> bool:
	var d := point - global_position
	d.y *= 2.0
	return d.length() <= DungeonGoals.RAID_RADIUS


## Początek napadu: krąg na ziemi, pierwsza fala od razu.
func start() -> void:
	if state != "sleep":
		return
	state = "active"
	if _beam:
		_beam.fade_out()
		_beam = null


func _finish() -> void:
	state = "done"
	inside = false
	var audio := AudioStreamPlayer2D.new()
	audio.stream = WIN_SOUND
	audio.volume_db = -6.0
	add_child(audio)
	audio.play()
	var ore := Sprite2D.new()  # ruda wysypana z wozu
	ore.texture = ORE_BITS
	ore.scale = Vector2.ONE * SCALE
	ore.position = _cart.position + Vector2(0, 8)
	add_child(ore)
	_cart.modulate = Color(1.8, 1.4, 1.0)
	create_tween().tween_property(_cart, "modulate", Color(0.85, 0.8, 0.8), 0.8)
	_label.text = tr("Napad odparty!")
	var tween := _label.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_label, "modulate:a", 0.0, 0.5)
	looted.emit(global_position)


## Krąg obozu na ziemi: obwódka, słaba poświata w środku i łuk postępu; poza kręgiem miga.
func _draw_ring() -> void:
	if state != "active":
		return
	var r := DungeonGoals.RAID_RADIUS
	var alpha := 1.0 if inside else 0.55 + 0.45 * absf(sin(_time * 6.0))
	_ring.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	_ring.draw_circle(Vector2.ZERO, r, Color(RING, 0.08 * alpha))
	_ring.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(RING, 0.85 * alpha), 3.0)
	var done := clampf(1.0 - time_left / DungeonGoals.RAID_TIME, 0.0, 1.0)
	if done > 0.0:
		_ring.draw_arc(Vector2.ZERO, r - 4.0, -PI / 2.0, -PI / 2.0 + TAU * done, 64, Color(1.0, 0.85, 0.5, alpha), 3.0)
	_ring.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

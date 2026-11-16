class_name ProtoChest
extends Node2D
## Skrzynia Wodza: pojawia się po pokonaniu bossa (wyskakuje z błyskiem). Otwiera się, gdy postać podejdzie
## (albo po stuknięciu palcem) - wtedy sypie iskry żaru, które same lecą do postaci (`embers` żaru, duże po 5).
## Razem z żarem wysypują się przedmioty (`items`, Items.roll_chest) - też same lecą do postaci.
## Grafika: skrzynia z Watry (assets/watra/chest.png).
## Ta sama skrzynia jest celem na mapie lochu (DungeonGoals, `hold_time` > 0): stoi pod słupem światła (GoalBeam),
## otwiera się dopiero, gdy postać postoi przy niej `hold_time` s (kółko postępu na ziemi; odejście cofa postęp),
## i ma strzałkę przy krawędzi ekranu (grupa GoalArrows.GROUP).

signal opened
## Z każdej iskry ze skrzyni (wartość) - podpina ją arena do licznika żaru.
signal ember_spawned(ember: ProtoEmber)
## Z każdego przedmiotu ze skrzyni.
signal loot_spawned(loot: ProtoLoot)

const TEXTURE := preload("res://assets/watra/chest.png")
const SCALE := 1.6
const SOUND := preload("res://assets/watra/chest_open.ogg")
## Z tej odległości (stopy-stopy) postać otwiera skrzynię.
const OPEN_RANGE := 22.0
## Obszar do stukania wokół skrzyni (piksele gry względem węzła).
const TAP_RECT := Rect2(-26, -42, 52, 50)
## Skrzynia-cel: z tej odległości liczy się stanie przy niej (stopy-stopy) i promień kółka postępu.
const HOLD_RANGE := 30.0
const RING_RADIUS := 26.0

var hero: ProtoHero
var embers := 20
## Przedmioty do wysypania (słowniki z Items).
var items: Array = []
var is_open := false
## Skrzynia-cel: ile sekund trzeba przy niej postać (0 - otwiera się od razu, jak skrzynia Wodza).
var hold_time := 0.0
## Kolor słupa światła, kółka i strzałki celu; ikonka na strzałce.
var goal_color := Color(1.0, 0.8, 0.4)
var goal_icon: Texture2D = TEXTURE
var _hold := 0.0
var _beam: GoalBeam

var _sprite: Sprite2D
var _hint: Label
var _time := 0.0


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2.ONE * SCALE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 2.0)
	add_child(_sprite)
	_hint = Label.new()
	_hint.text = "▼"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.size = Vector2(30, 16)
	_hint.position = Vector2(-15, -58)
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(1, 0.8, 0.35))
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	_hint.add_theme_constant_override("outline_size", 4)
	add_child(_hint)
	# wyskok: spada z góry i odbija się
	_sprite.position.y = -40.0
	_sprite.modulate = Color(3, 2.4, 1.6)
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position:y", 0.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.6)
	if hold_time > 0.0:
		add_to_group(GoalArrows.GROUP)
		_beam = GoalBeam.new()
		_beam.color = goal_color
		add_child(_beam)


func _process(delta: float) -> void:
	_time += delta
	_hint.position.y = -58.0 - 3.0 * (0.5 + 0.5 * sin(_time * 5.0))
	if is_open or hero == null or hero.dead or _time <= 0.5:
		return
	var dist := hero.global_position.distance_to(global_position)
	if hold_time <= 0.0:
		if dist <= OPEN_RANGE:
			open()
		return
	if dist <= HOLD_RANGE:
		_hold += delta
	else:
		_hold = maxf(0.0, _hold - delta * 2.0)
	queue_redraw()
	if _hold >= hold_time:
		open()


## Cel na mapie jeszcze czeka (strzałka przy krawędzi ekranu).
func goal_active() -> bool:
	return not is_open


func _draw() -> void:
	if hold_time > 0.0 and not is_open:
		GoalBeam.draw_ring(self, _hold / hold_time, RING_RADIUS, goal_color)


func _input(event: InputEvent) -> void:
	if is_open or hold_time > 0.0 or not (event is InputEventScreenTouch and event.pressed) or TouchUi.covers(get_tree(), event.position):
		return
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	if TAP_RECT.has_point(local):
		open()


## Otwiera skrzynię: dźwięk, podskok, iskry rozsypują się dookoła i lecą do postaci.
func open() -> void:
	if is_open:
		return
	is_open = true
	_hint.visible = false
	if _beam:
		_beam.fade_out()
		_beam = null
	queue_redraw()
	var audio := AudioStreamPlayer2D.new()
	audio.stream = SOUND
	audio.volume_db = -4.0
	add_child(audio)
	audio.play()
	var tween := create_tween()
	_sprite.modulate = Color(2.5, 2.0, 1.4)
	tween.tween_property(_sprite, "scale", Vector2(SCALE * 1.2, SCALE * 0.85), 0.08)
	tween.tween_property(_sprite, "scale", Vector2.ONE * SCALE, 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_sprite, "modulate", Color(0.75, 0.7, 0.65), 0.5)
	var left := embers
	var i := 0
	while left > 0:
		var ember := ProtoEmber.new()
		ember.hero = hero
		ember.value = ProtoEmber.BIG if left >= ProtoEmber.BIG else 1
		left -= ember.value
		ember.spread = 34.0
		ember.magnet = 1000.0
		ember.delay = 0.5 + 0.05 * i
		ember.position = position + Vector2(0, -6)
		i += 1
		ember_spawned.emit(ember)
		get_parent().add_child.call_deferred(ember)
	for j in items.size():
		var loot := ProtoLoot.new()
		loot.hero = hero
		loot.item = items[j]
		loot.spread = 30.0
		loot.magnet = 1000.0
		loot.sell_if_full = true
		loot.delay = 0.7 + 0.25 * j
		loot.position = position + Vector2(0, -4)
		loot_spawned.emit(loot)
		get_parent().add_child.call_deferred(loot)
	opened.emit()

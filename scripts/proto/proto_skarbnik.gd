class_name ProtoSkarbnik
extends ProtoTarget
## Skarbnik - cel na mapie lochu (DungeonGoals, od 10. poziomu): złocista zjawa starego górnika (grafika górnika
## z Kryształu Watry, assets/watra/skarbnik.png, shader zjawy shaders/ghost.gdshader - jak Skarbnik w Watrze, ale
## działa inaczej: zamiast oferty z falami - pościg). Czeka pod słupem światła; gdy postać podejdzie bliżej niż WAKE,
## budzi się i ucieka (trochę wolniej niż postać, z zakosami, ślizga się wzdłuż brzegu polany). Każde trafienie bronią
## wybija złoto (sygnał `gold`, najwyżej co HIT_GAP s) - złote liczby „+N”, brzęk monet. Po CATCH_HITS trafieniach
## jest złapany: wielka garść złota (JACKPOT) i kamień (sygnał `caught`). Po FLEE_TIME s ucieczki zapada się pod ziemię
## (sygnał `escaped`). Strzałka przy krawędzi ekranu - grupa GoalArrows.GROUP.

signal gold(amount: int)
signal caught(at: Vector2)
signal escaped

const TEXTURE := preload("res://assets/watra/skarbnik.png")
const SHADER := preload("res://shaders/ghost.gdshader")
const COIN_SOUND := preload("res://assets/watra/handleCoins.ogg")
const GHOST := Color(1.0, 0.85, 0.5)
const SCALE := 0.75
## Z tej odległości (piksele gry) śpiący Skarbnik budzi się i ucieka.
const WAKE := 110.0
const SPEED := 58.0
## Zakosy: co tyle sekund nowy kąt odchylenia od kierunku ucieczki (do ZIGZAG radianów).
const ZIGZAG_EVERY := 0.7
const ZIGZAG := 0.7
const FLEE_TIME := 15.0
const CATCH_HITS := 8
const HIT_GAP := 0.2
## Po trafieniu zwalnia na chwilę (podstawowy atak to około 1 cios na sekundę).
const STAGGER_SLOW := 0.5
const STAGGER_TIME := 0.5
## Złoto za trafienie: ułamek ceny zwykłego przedmiotu z tego poziomu (Items.SELL_BASE x DungeonLevels.power).
const GOLD_HIT := 0.8
## Złapanie: tyle razy złoto za trafienie.
const JACKPOT := 10

var hero: ProtoHero
var level := 1
var bounds := Rect2(-300, -300, 600, 600)
var goal_color := Color(1.0, 0.85, 0.4)
var goal_icon: Texture2D = TEXTURE
## "sleep" - czeka, "flee" - ucieka, "gone" - złapany albo uciekł.
var state := "sleep"
var hits := 0
var flee_left := FLEE_TIME
var gold_total := 0

var _sprite: Sprite2D
var _beam: GoalBeam
var _audio: AudioStreamPlayer2D
var _label: Label
var _time := randf() * 10.0
var _zig := 0.0
var _zig_next := 0.0
var _hit_ready := 0.0
var _stagger := 0.0


func _ready() -> void:
	add_to_group(GoalArrows.GROUP)
	center_height = 22.0
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.modulate = Color(1, 1, 1, 0.6)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2.ONE * SCALE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 4.0)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ghost", GHOST)
	mat.set_shader_parameter("phase", randf() * 10.0)
	_sprite.material = mat
	add_child(_sprite)
	_label = Label.new()
	_label.text = tr("Skarbnik")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(100, 14)
	_label.position = Vector2(-50, -TEXTURE.get_height() * SCALE - 20.0)
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", goal_color.lightened(0.4))
	_label.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 6
	add_child(_label)
	_beam = GoalBeam.new()
	_beam.color = goal_color
	add_child(_beam)
	_audio = AudioStreamPlayer2D.new()
	_audio.stream = COIN_SOUND
	_audio.volume_db = -6.0
	add_child(_audio)
	add_to_group(ProtoWeapon.TARGETS)


func alive() -> bool:
	return state != "gone"


func goal_active() -> bool:
	return state != "gone"


## Złoto za jedno trafienie na poziomie `lvl`.
static func gold_per_hit(lvl: int) -> int:
	return maxi(1, roundi(Items.SELL_BASE * DungeonLevels.power(lvl) * GOLD_HIT))


func _process(delta: float) -> void:
	_time += delta
	if state == "gone" or hero == null:
		return
	_sprite.position.y = -3.0 * (0.5 + 0.5 * sin(_time * 2.5))  # unosi się
	queue_redraw()
	_hit_ready -= delta
	if state == "sleep":
		if not hero.dead and hero.global_position.distance_to(global_position) <= WAKE:
			wake()
		return
	flee_left -= delta
	if flee_left <= 0.0:
		_vanish()
		return
	_zig_next -= delta
	if _zig_next <= 0.0:
		_zig_next = ZIGZAG_EVERY
		_zig = randf_range(-ZIGZAG, ZIGZAG)
	var away := global_position - hero.global_position
	var dir := (away if away.length() > 1.0 else Vector2.RIGHT).normalized().rotated(_zig)
	_stagger -= delta
	var speed := SPEED * speed_factor() * (1.0 - STAGGER_SLOW if _stagger > 0.0 else 1.0)
	var next := position + dir * speed * delta
	# przy brzegu: ślizg wzdłuż niego (sama składowa równoległa), zamiast utknąć w rogu
	if not bounds.has_point(next):
		var along := Vector2(dir.x if bounds.has_point(Vector2(next.x, position.y)) else 0.0,
				dir.y if bounds.has_point(Vector2(position.x, next.y)) else 0.0)
		if along.length() < 0.2:  # róg - ucieka wzdłuż ściany w stronę środka
			along = (bounds.get_center() - position).normalized()
		next = position + along.normalized() * speed * delta
	position = next.clamp(bounds.position, bounds.end)
	_sprite.flip_h = dir.x < 0.0
	# ostatnie sekundy: miga
	if flee_left < 3.0:
		_sprite.modulate.a = 0.5 + 0.5 * absf(sin(_time * 10.0))


## Złota poświata pod zjawą (widać ją w tłumie i na trawie).
func _draw() -> void:
	if state == "gone":
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 22.0, Color(goal_color, 0.22 + 0.08 * sin(_time * 4.0)))
	draw_circle(Vector2.ZERO, 12.0, Color(goal_color.lightened(0.3), 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Przebudzenie: słup światła gaśnie, napis „ucieka!”, ucieczka.
func wake() -> void:
	if state != "sleep":
		return
	state = "flee"
	_beam.fade_out()
	_beam = null
	_label.text = tr("Skarbnik ucieka!")
	var tween := _label.create_tween()  # napis znika, żeby nie zasłaniał złotych liczb
	tween.tween_interval(1.5)
	tween.tween_property(_label, "modulate:a", 0.0, 0.4)


func take_damage(_amount: int, _from: Vector2) -> void:
	crit_next = false
	if state == "gone":
		return
	if state == "sleep":
		wake()
	if _hit_ready > 0.0:
		return
	_hit_ready = HIT_GAP
	hits += 1
	_stagger = STAGGER_TIME  # zachwiał się - łatwiej trafić znowu (bez znaczka spowolnienia)
	var flash := _sprite.material as ShaderMaterial
	flash.set_shader_parameter("flash", 0.8)
	create_tween().tween_method(func(v: float) -> void: flash.set_shader_parameter("flash", v), 0.8, 0.0, 0.15)
	_audio.pitch_scale = randf_range(0.95, 1.2)
	_audio.play()
	if hits >= CATCH_HITS:
		_pay(gold_per_hit(level) * JACKPOT, 16)
		state = "gone"
		_label.text = tr("Złapany!")
		_label.modulate.a = 1.0
		caught.emit(global_position)
		_fade(0.8)
	else:
		_pay(gold_per_hit(level), 12)


func _pay(amount: int, size: int) -> void:
	gold_total += amount
	gold.emit(amount)
	var num := Label.new()
	num.text = "+%d" % amount
	num.add_theme_font_size_override("font_size", size)
	num.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	num.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	num.add_theme_constant_override("outline_size", 4)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(60, 18)
	num.position = Vector2(-30 + randf_range(-10, 10), -center_height - 30)
	num.z_index = 20
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", num.position.y - 22, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.tween_callback(num.queue_free)


## Czas minął: Skarbnik zapada się pod ziemię.
func _vanish() -> void:
	state = "gone"
	_label.text = tr("Skarbnik uciekł")
	_label.modulate.a = 1.0
	escaped.emit()
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position:y", 20.0, 1.0)
	_fade(1.0)


func _fade(time: float) -> void:
	remove_from_group(ProtoWeapon.TARGETS)
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.tween_callback(queue_free)

class_name ProtoCrystal
extends Node2D
## Kryształ Watry - cel na mapie lochu (DungeonGoals, od 20. poziomu; jak w Watrze - watra_crystal.gd, wariant
## „obroń kryształ” bez górników). Przygaszony kryształ (assets/watra/watra_crystal_dim.png) pod słupem światła; gdy
## postać podejdzie bliżej niż WAKE, budzi się (jasna grafika) i przez CRYSTAL_TIME s z kilku stron nadchodzą fale
## potworów (sygnał `wave` - arena spawnuje przez ProtoHorde.spawn_pack z `objective` = ten kryształ). Potwory idą
## bić kryształ (ProtoGoblin.objective), chyba że postać jest blisko nich. Pasek zdrowia nad kryształem.
## Po czasie (`defended`, zdrowie 0-1): kryształ rozpada się i sypie kamienie i odpryski - tym więcej, im mniej
## ucierpiał. Rozbity przez potwory (`destroyed`): gruz i garść odprysków. Strzałka - grupa GoalArrows.GROUP.

signal wave(at: Vector2, count: int)
signal defended(at: Vector2, health: float)
signal destroyed(at: Vector2)

const TEXTURE := preload("res://assets/watra/watra_crystal.png")
const TEXTURE_DIM := preload("res://assets/watra/watra_crystal_dim.png")
const RUBBLE := preload("res://assets/watra/watra_crystal_rubble.png")
const HIT_SOUND := preload("res://assets/watra/glass_002.ogg")
const BREAK_SOUND := preload("res://assets/watra/chief_slam.ogg")
const SCALE := 0.6
## Potwory biją kryształ z tej odległości od jego środka (stopy).
const RADIUS := 20.0
const WAKE := 90.0

var hero: ProtoHero
var power := 1.0
var goal_color := Color(1.0, 0.6, 0.25)
var goal_icon: Texture2D = TEXTURE
## "sleep" - czeka, "defend" - obrona, "done" - obroniony, "broken" - rozbity.
var state := "sleep"
var max_hp := DungeonGoals.CRYSTAL_HP
var hp := DungeonGoals.CRYSTAL_HP
var time_left := DungeonGoals.CRYSTAL_TIME

var _sprite: Sprite2D
var _beam: GoalBeam
var _label: Label
var _bar: ProgressBar
var _audio: AudioStreamPlayer2D
var _wave_next := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group(GoalArrows.GROUP)
	max_hp = roundi(DungeonGoals.CRYSTAL_HP * power)
	hp = max_hp
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(1.5, 1.2)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE_DIM
	_sprite.scale = Vector2.ONE * SCALE
	_sprite.offset = Vector2(0, -TEXTURE.get_height() / 2.0 + 6.0)
	add_child(_sprite)
	var top := -TEXTURE.get_height() * SCALE - 8.0
	_label = Label.new()
	_label.text = tr("Kryształ Watry")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(140, 14)
	_label.position = Vector2(-70, top - 22.0)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", goal_color.lightened(0.35))
	_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 6
	add_child(_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.size = Vector2(44, 5)
	_bar.position = Vector2(-22, top - 6.0)
	_bar.max_value = max_hp
	_bar.value = hp
	_bar.z_index = 6
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.02, 0.85)
	var fill := StyleBoxFlat.new()
	fill.bg_color = goal_color
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.visible = false
	add_child(_bar)
	_beam = GoalBeam.new()
	_beam.color = goal_color
	add_child(_beam)
	_audio = AudioStreamPlayer2D.new()
	_audio.stream = HIT_SOUND
	_audio.volume_db = -14.0
	add_child(_audio)


func goal_active() -> bool:
	return state == "sleep" or state == "defend"


## Czy potwory mają go bić.
func under_attack() -> bool:
	return state == "defend"


func _process(delta: float) -> void:
	_time += delta
	if hero == null or hero.dead:
		return
	match state:
		"sleep":
			if hero.global_position.distance_to(global_position) <= WAKE:
				wake()
		"defend":
			_sprite.modulate = Color.WHITE.lerp(Color(1.4, 1.2, 1.0), 0.5 + 0.5 * sin(_time * 3.0))
			time_left -= delta
			_label.text = tr("Obroń kryształ: %d s") % ceili(maxf(time_left, 0.0))
			if time_left <= 0.0:
				_finish(true)
				return
			_wave_next -= delta
			if _wave_next <= 0.0 and time_left > 3.0:
				_wave_next = DungeonGoals.CRYSTAL_WAVE_EVERY
				var base := randf() * TAU
				for i in DungeonGoals.CRYSTAL_SIDES:
					var angle := base + TAU * i / DungeonGoals.CRYSTAL_SIDES + randf_range(-0.4, 0.4)
					wave.emit(global_position + Vector2.from_angle(angle) * DungeonGoals.CRYSTAL_SPAWN_DIST,
							randi_range(DungeonGoals.CRYSTAL_PACK.x, DungeonGoals.CRYSTAL_PACK.y))


## Przebudzenie: jasny kryształ, pasek zdrowia, pierwsza fala od razu.
func wake() -> void:
	if state != "sleep":
		return
	state = "defend"
	_sprite.texture = TEXTURE
	_bar.visible = true
	_beam.fade_out()
	_beam = null


## Cios potwora (ProtoGoblin._objective_move).
func take_hit(amount: int) -> void:
	if state != "defend":
		return
	hp = maxi(hp - amount, 0)
	_bar.value = hp
	_sprite.modulate = Color(2.5, 1.2, 1.0)
	if not _audio.playing:
		_audio.pitch_scale = randf_range(0.9, 1.2)
		_audio.play()
	if hp <= 0:
		_finish(false)


func _finish(success: bool) -> void:
	state = "done" if success else "broken"
	_bar.visible = false
	var audio := AudioStreamPlayer2D.new()
	audio.stream = BREAK_SOUND
	audio.volume_db = -6.0
	audio.pitch_scale = 1.3
	add_child(audio)
	audio.play()
	_sprite.texture = RUBBLE
	_sprite.offset = Vector2(0, -RUBBLE.get_height() / 2.0 + 4.0)
	_sprite.modulate = Color(2, 1.6, 1.2) if success else Color(0.7, 0.65, 0.65)
	create_tween().tween_property(_sprite, "modulate", Color(0.8, 0.75, 0.75), 0.8)
	_label.text = tr("Kryształ obroniony!") if success else tr("Kryształ rozbity")
	var tween := _label.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_label, "modulate:a", 0.0, 0.5)
	if success:
		defended.emit(global_position, float(hp) / max_hp)
	else:
		destroyed.emit(global_position)

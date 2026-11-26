class_name ProtoKosciejEgg
extends ProtoTarget
## Jajo Kościeja (Wieża Kościeja, ustalone z autorem 26.11.2026): w nim igła, a na końcu igły - śmierć Kościeja.
## Stoi na kamiennym postumencie w świetlistej, fioletowej kapsule; po posadzce biegnie do Kościeja pulsująca nić
## magii (widać, że to jajo trzyma go przy życiu). Cel dla broni jak potwór (ProtoTarget, grupa celów): ma własne
## zdrowie (pasek nad kapsułą), pęka coraz bardziej, a po zniszczeniu wysyła `broken` - Kościej staje się śmiertelny.
## Dopóki jajo jest całe, Kościej po spadku zdrowia do zera odradza się (ProtoKosciej). Tworzy je boss; rysowane w kodzie.

signal broken

## Środek jaja nad ziemią (tam celuje broń) i promień kapsuły.
const EGG_Y := -21.0
const CAPSULE := 11.0
const VIOLET := Color(0.72, 0.45, 1.0)
const SHELL := Color(0.93, 0.9, 0.82)
const BLAST_FX := preload("res://assets/effects/arcane_blast.png")
const HIT_FX := preload("res://assets/effects/arcane_hit.png")
const BREAK_SOUND := preload("res://assets/watra/chief_slam.ogg")
## Po rozbiciu skorupki leżą tyle sekund, potem gasną.
const SHELL_TIME := 4.0
## Całość (postument, kapsuła) powiększona - czytelny cel na telefonie.
const SIZE := 1.3

## Kościej (nić magii biegnie do jego stóp).
var boss: ProtoTarget
var max_hp := 300
var hp := 300
var is_broken := false
var _flash := 0.0
var _pulse := 0.0
var _time := 0.0
var _audio: AudioStreamPlayer2D
var _thread: _Thread


func _ready() -> void:
	scale = Vector2.ONE * SIZE
	center_height = -EGG_Y * SIZE
	hp = max_hp
	add_to_group(ProtoWeapon.TARGETS)
	_thread = _Thread.new()
	_thread.egg = self
	add_child(_thread)
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = -8.0
	add_child(_audio)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)


func alive() -> bool:
	return not is_broken


func health_fraction() -> float:
	return clampf(float(hp) / maxf(max_hp, 1.0), 0.0, 1.0)


func remaining_hp() -> int:
	return maxi(hp, 0) if not is_broken else 0


func take_damage(amount: int, _from: Vector2) -> void:
	if is_broken or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	spawn_number(amount)
	_flash = 1.0
	if hit_sound_ok():
		_audio.stream = ProtoGoblin.HIT_SOUNDS.pick_random()
		_audio.pitch_scale = randf_range(1.4, 1.6)
		_audio.play()
	if hp <= 0:
		_break()


## Kościej się odradza - kapsuła i nić rozbłyskują (jajo oddaje mu życie).
func pulse() -> void:
	_pulse = 1.0


## Jajo pęka: wybuch magii, skorupki i złamana igła zostają chwilę na postumencie.
func _break() -> void:
	is_broken = true
	remove_from_group(ProtoWeapon.TARGETS)
	var at := global_position + Vector2(0, EGG_Y * SIZE)
	Fx.once(get_parent(), BLAST_FX, 9, 18.0, global_position.round(), Vector2(36, 20), 2, 1.3)
	Fx.once(get_parent(), HIT_FX, 6, 14.0, at.round(), Vector2(23, 21), 21, 1.4)
	_audio.stream = BREAK_SOUND
	_audio.pitch_scale = 1.5
	_audio.play()
	broken.emit()
	var tween := create_tween()
	tween.tween_interval(SHELL_TIME)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 5.0, 0.0)
	_pulse = maxf(_pulse - delta * 0.8, 0.0)
	queue_redraw()
	_thread.queue_redraw()


func _draw() -> void:
	# cień i postument
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-8, -10, 16, 10), Color(0.24, 0.21, 0.3))
	draw_rect(Rect2(-8, -10, 3, 10), Color(0.3, 0.27, 0.37))
	draw_rect(Rect2(-11, -13, 22, 3), Color(0.36, 0.32, 0.44))
	draw_rect(Rect2(-10, 0, 20, 1), Color(0.16, 0.14, 0.2))
	var rune := Color(VIOLET, 0.6 + 0.3 * sin(_time * 3.0))
	draw_line(Vector2(-3, -7), Vector2(3, -3), rune, 1.0)
	draw_line(Vector2(0, -8), Vector2(0, -2), rune, 1.0)
	var c := Vector2(0, EGG_Y)
	if is_broken:
		# skorupki i złamana igła na postumencie
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -13), Vector2(-1, -13), Vector2(-3, -17), Vector2(-6, -16)]), SHELL)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -13), Vector2(7, -13), Vector2(6, -18), Vector2(3, -16)]), SHELL.darkened(0.15))
		draw_line(Vector2(-4, -14), Vector2(0, -15), Color(0.95, 0.8, 0.4), 1.0)
		draw_line(Vector2(1, -16), Vector2(4, -18), Color(0.95, 0.8, 0.4), 1.0)
		return
	# kapsuła (tło), jajo, rysy, igła prześwitująca przez skorupkę
	var glow := 0.16 + 0.06 * sin(_time * 2.5) + 0.35 * _pulse + 0.25 * _flash
	draw_circle(c, CAPSULE, Color(VIOLET, glow))
	var egg := PackedVector2Array()
	for i in 24:
		var ang := TAU * i / 24.0
		var r := Vector2(5.5, 7.5 if sin(ang) < 0.0 else 6.5)  # spiczasty od góry
		egg.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	var shell := SHELL.lerp(Color(1.6, 1.6, 1.6), _flash * 0.6)
	draw_colored_polygon(egg, shell)
	draw_colored_polygon(PackedVector2Array([c + Vector2(2, -6), c + Vector2(5.5, 0), c + Vector2(3, 5), c + Vector2(1, 0)]),
			shell.darkened(0.15))
	draw_line(c + Vector2(-2, -3), c + Vector2(2, 3), Color(0.95, 0.75, 0.35, 0.45), 1.0)  # igła
	var crack := Color(0.35, 0.25, 0.3)
	var f := health_fraction()
	if f < 0.7:
		draw_polyline(PackedVector2Array([c + Vector2(-5, -1), c + Vector2(-2, 1), c + Vector2(0, -1), c + Vector2(2, 2)]), crack, 1.0)
	if f < 0.35:
		draw_polyline(PackedVector2Array([c + Vector2(1, -7), c + Vector2(-1, -4), c + Vector2(2, -3), c + Vector2(0, 0)]), crack, 1.0)
	# brzeg kapsuły
	draw_arc(c, CAPSULE, 0.0, TAU, 28, Color(VIOLET.lightened(0.3), 0.55 + 0.4 * maxf(_pulse, _flash)), 1.0)
	draw_arc(c, CAPSULE - 2.0, PI * 1.1, PI * 1.45, 6, Color(1, 1, 1, 0.5), 1.0)  # odblask
	# pasek zdrowia jaja
	var bar := Rect2(-12, EGG_Y - CAPSULE - 6, 24, 3)
	draw_rect(bar, Color(0.08, 0.05, 0.12, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * f, bar.size.y)), VIOLET)


## Nić magii po posadzce od jaja do stóp Kościeja (pod postaciami): pulsuje, płyną po niej jasne iskry ku bossowi.
class _Thread:
	extends Node2D
	var egg: ProtoKosciejEgg

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		if egg.is_broken or egg.boss == null or not is_instance_valid(egg.boss) or not egg.boss.alive():
			return
		var to: Vector2 = (egg.boss.global_position - egg.global_position) / ProtoKosciejEgg.SIZE
		var a := 0.22 + 0.1 * sin(egg._time * 4.0) + 0.5 * egg._pulse
		draw_line(Vector2.ZERO, to, Color(ProtoKosciejEgg.VIOLET, a), 2.0)
		draw_line(Vector2.ZERO, to, Color(1, 0.9, 1, a * 0.6), 1.0)
		var length := to.length()
		if length < 1.0:
			return
		var step := 26.0
		var off := fmod(egg._time * 40.0, step)
		var d := off
		while d < length:
			draw_circle(to * (d / length), 1.5, Color(0.95, 0.8, 1.0, a + 0.2))
			d += step

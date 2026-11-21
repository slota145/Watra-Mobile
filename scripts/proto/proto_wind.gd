class_name ProtoWind
extends Node2D
## Wiatr Podniebnych wysp (Dungeons.SKY, ustalone z autorem 21.11.2026): podmuchy i wędrowne trąby powietrzne.
## - Podmuch: co CALM s (losowo z przedziału) wiatr wybiera kierunek (jeden z 8); przez WARN s wokół postaci migają
##   białe strzałki w tę stronę, potem przez BLOW s wiatr spycha postać (HERO_PUSH px/s - wolniej, niż biegnie, więc
##   da się iść pod wiatr), potwory (MONSTER_PUSH) i pociski potworów (ARROW_PUSH); przez ekran lecą smugi wiatru.
##   Szum podmuchu: `gust_*.ogg` z Watry.
## - Trąby: TORNADOES wędrownych trąb (ProtoTornado) rozsianych z dala od miejsca startu postaci.
## Węzeł leży w arenie nad postaciami (z_index), rysuje w jej współrzędnych (arena w punkcie 0,0).

const CALM := Vector2(9.0, 14.0)
const WARN := 1.6
const BLOW := 2.6
const HERO_PUSH := 42.0
const MONSTER_PUSH := 36.0
const ARROW_PUSH := 40.0
const TORNADOES := 2
## Trąby startują co najmniej tak daleko od postaci.
const TORNADO_CLEAR := 220.0
const STREAKS := 26
const STREAK_AREA := Vector2(420.0, 760.0)
const STREAK_SPEED := 420.0
const ARROWS := 3
const ARROW_RING := 40.0
const SOUNDS: Array[AudioStream] = [preload("res://assets/watra/sfx/gust_1.ogg"), preload("res://assets/watra/sfx/gust_3.ogg")]

var hero: ProtoHero
## Węzeł świata z potworami i pociskami (ProtoHorde.world).
var world: Node2D
var bounds := Rect2(-300, -300, 600, 600)
## Siła potworów lochu (obrażenia trąb).
var power := 1.0
## Obrażenia trąby na 1. poziomie siły.
var tornado_damage := 10
## Testy: bez podmuchów i trąb (wiatr nie zrywa się sam).
var passive := false

## "calm", "warn", "blow".
var state := "calm"
var direction := Vector2.RIGHT
var tornadoes: Array[ProtoTornado] = []
var _timer := 0.0
var _next := 0.0
var _streaks: Array[Vector3] = []  # x, y, długość
var _audio: AudioStreamPlayer


func _ready() -> void:
	z_index = 30
	_next = randf_range(CALM.x, CALM.y)
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -6.0
	add_child(_audio)


## Rozsiewa wędrowne trąby (wołane przez arenę po dodaniu postaci).
func spawn_tornadoes() -> void:
	if passive or world == null:
		return
	for i in TORNADOES:
		var t := ProtoTornado.new()
		t.hero = hero
		t.bounds = bounds
		t.damage = roundi(tornado_damage * power)
		var at := Vector2.ZERO
		for tries in 20:
			at = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
			if hero == null or at.distance_to(hero.position) > TORNADO_CLEAR:
				break
		t.position = at
		world.add_child(t)
		tornadoes.append(t)


func _process(delta: float) -> void:
	if hero == null or passive:
		return
	_timer += delta
	match state:
		"calm":
			if _timer >= _next:
				start_gust(Vector2.from_angle(randi() % 8 * TAU / 8.0))
		"warn":
			if _timer >= WARN:
				state = "blow"
				_timer = 0.0
				_audio.stream = SOUNDS.pick_random()
				_audio.pitch_scale = randf_range(0.85, 1.05)
				_audio.play()
		"blow":
			_blow(delta)
			if _timer >= BLOW:
				state = "calm"
				_timer = 0.0
				_next = randf_range(CALM.x, CALM.y)
				_streaks.clear()
	queue_redraw()


## Zapowiedź podmuchu w kierunku `dir` (też do testów).
func start_gust(dir: Vector2) -> void:
	direction = dir.normalized()
	state = "warn"
	_timer = 0.0
	_streaks.clear()
	for i in STREAKS:
		_streaks.append(Vector3(randf_range(-0.5, 0.5) * STREAK_AREA.x, randf_range(-0.5, 0.5) * STREAK_AREA.y, randf_range(10.0, 26.0)))


## Podmuch: spycha postać, potwory i pociski potworów.
func _blow(delta: float) -> void:
	var k := clampf(minf(_timer / 0.3, (BLOW - _timer) / 0.4), 0.0, 1.0)  # wiatr narasta i cichnie
	hero.drift(direction * HERO_PUSH * k * delta)
	if world:
		for c in world.get_children():
			if c is ProtoGoblin:
				var g := c as ProtoGoblin
				g.position = (g.position + direction * MONSTER_PUSH * k * delta).clamp(g.bounds.position, g.bounds.end)
			elif c is ProtoArrow:
				(c as Node2D).position += direction * ARROW_PUSH * k * delta
	for i in _streaks.size():
		var s := _streaks[i]
		var p := Vector2(s.x, s.y) + direction * STREAK_SPEED * delta
		if absf(p.x) > STREAK_AREA.x * 0.5 or absf(p.y) > STREAK_AREA.y * 0.5:
			p = Vector2(randf_range(-0.5, 0.5) * STREAK_AREA.x, randf_range(-0.5, 0.5) * STREAK_AREA.y)  # nowa smuga
		_streaks[i] = Vector3(p.x, p.y, s.z)


## Strzałki zapowiedzi wokół postaci i smugi wiatru w kadrze.
func _draw() -> void:
	if hero == null:
		return
	var center := hero.position
	if state == "warn":
		var blink := 0.45 + 0.55 * absf(sin(_timer * 9.0))
		var side := direction.orthogonal()
		for i in ARROWS:
			var base := center - direction * ARROW_RING + side * (i - 1) * 24.0
			var tip := base + direction * 30.0
			for pass_i in 2:  # najpierw ciemny obrys (czytelne na jasnej mgle), potem biała strzałka
				var col := Color(0.1, 0.12, 0.2, 0.7 * blink) if pass_i == 0 else Color(1.0, 1.0, 1.0, 0.95 * blink)
				var w := 4.5 if pass_i == 0 else 2.5
				draw_line(base, tip, col, w)
				draw_line(tip, tip - direction * 9.0 + side * 7.0, col, w)
				draw_line(tip, tip - direction * 9.0 - side * 7.0, col, w)
	elif state == "blow":
		var k := clampf(minf(_timer / 0.3, (BLOW - _timer) / 0.4), 0.0, 1.0)
		for s in _streaks:
			var p := center + Vector2(s.x, s.y)
			draw_line(p, p - direction * s.z * 1.5, Color(1.0, 1.0, 1.0, 0.65 * k), 1.5)


func _exit_tree() -> void:
	for t in tornadoes:
		if is_instance_valid(t):
			t.queue_free()

class_name ProtoDziadMroz
extends ProtoChief
## Dziad Mróz - boss Lodowych jaskiń (Dungeons.FROST, ustalone z autorem 25.11.2026; Marzanna zostaje na bossa
## szczytowego): pradawny duch zimy z lodową brodą i laską z kryształem. Reszta (wejście, pasek zdrowia, trafienia,
## śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem na ziemi (liczby - propozycje Claude):
## - Mroźne tchnienie: wachlarz BREATH_ARC przed nim (BREATH_RADIUS) - po BREATH_WARN s dmucha mrozem: rani lodem,
##   mocno spowalnia i dokłada dużo chłodu (ProtoFrost.chill_hero);
## - Deszcz sopli: RAIN_DROPS małych kół wokół postaci (pierwsze pod nią), sople spadają po kolei (efekt sopla Wodnika);
## - Lodowe kolce: pas do postaci (SPIKES_LENGTH x SPIKES_WIDTH), po SPIKES_WARN s wzdłuż niego po kolei wyrastają
##   lodowe kryształy (ice_spikes rapiera) - rani i schładza.
## Poniżej połowy zdrowia raz ryczy i zrywa się **zamieć** (`blizzard`): po ekranie sypie śnieg, postać dodatkowo
## marznie (BLIZZARD_COLD na sekundę) i pada więcej sopli. Grafika: model SpriteKiln assets/spritekiln/dziad_mroz/
## (idle, walk, roar, breath, rain, spikes, hit, death), do tego czasu powiększony goblin w kolorze lodu.

const MROZ_SCENE := "res://assets/spritekiln/dziad_mroz/dziad_mroz.tscn"
const MROZ_HP := 1250
const KEEP_DISTANCE := 70.0
const ATTACK_RANGE := 150.0
const BREATH_RADIUS := 120.0
const BREATH_ARC := deg_to_rad(70.0)
const BREATH_WARN := 1.1
const BREATH_DAMAGE := 24
const BREATH_SLOW := 0.5
const BREATH_COLD := 30.0
const RAIN_DROPS := 7
const RAIN_DROPS_STORM := 10
const RAIN_RADIUS := 15.0
const RAIN_SPREAD := 75.0
const RAIN_WARN := 1.0
const RAIN_STEP := 0.13
const RAIN_DAMAGE := 18
const RAIN_COLD := 12.0
const SPIKES_LENGTH := 210.0
const SPIKES_WIDTH := 26.0
const SPIKES_WARN := 0.9
const SPIKES_STEP := 0.05
const SPIKES_COUNT := 8
const SPIKES_DAMAGE := 26
const SPIKES_COLD := 20.0
const BLIZZARD_AT := 0.5
const BLIZZARD_COLD := 4.0
const STORM_ROAR := 1.2
const CHILL_TIME := 1.5
## Mroźne tchnienie: zionięcie Żmija przebarwione na lód (tools/frost_decor.py), długość płomienia w arkuszu (px).
const BREATH_FX := preload("res://assets/effects/frost_breath.png")
const BREATH_FX_FRAMES := 8
const BREATH_FX_ANCHOR := Vector2(4, 25)
const BREATH_FX_LENGTH := 100.0
const ICICLE_FX := preload("res://assets/effects/wodnik_icicle.png")
const ICICLE_FX_FRAMES := 18
const ICICLE_FX_FPS := 18.0
const ICICLE_FX_ANCHOR := Vector2(32, 93)
## Sopel spada ICICLE_LEAD s i uderza w 8. klatce - wtedy, gdy koło się wypełni.
const ICICLE_LEAD := 7.0 / ICICLE_FX_FPS
const SPIKES_FX := preload("res://assets/effects/ice_spikes.png")
const SPIKES_FX_FRAMES := 18
const SPIKES_FX_ANCHOR := Vector2(30, 34)
const SHATTER_FX := preload("res://assets/effects/frost_shatter.png")
const ATTACKS: Array[String] = ["breath", "rain", "spikes"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
## Czy trwa zamieć (druga faza).
var blizzard := false
var _last_attack := ""
var _drops: Array[ProtoTelegraph] = []
var _spikes_from := Vector2.ZERO
var _spikes_dir := Vector2.DOWN
var _snow: Node2D


func _init() -> void:
	scene_path = MROZ_SCENE
	base_hp = MROZ_HP
	fallback_tint = Color(0.7, 0.88, 1.0)
	keep_distance = KEEP_DISTANCE
	anim_hit_at = {&"breath": 0.35, &"rain": 0.4, &"spikes": 0.5}
	anim_fallback = {&"breath": &"attack", &"rain": &"attack", &"spikes": &"attack", &"roar": &"idle",
		&"slam": &"attack", &"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_update_drops()
	if state == "dead" or hero == null:
		return
	if blizzard and not hero.dead:
		ProtoFrost.chill_hero(hero, BLIZZARD_COLD * delta)
	match state:
		"breath":
			_sync_anim(&"breath", BREATH_WARN)
			if _timer >= BREATH_WARN:
				_breath_hit()
		"rain":
			_sync_anim(&"rain", RAIN_WARN)
			if _timer >= RAIN_WARN:
				_set_state("recover")
		"spikes":
			_sync_anim(&"spikes", SPIKES_WARN)
			if _timer >= SPIKES_WARN:
				_spikes_hit()
		"storm":
			if _timer >= STORM_ROAR:
				_set_state("recover")


func _choose_attack(distance: float) -> void:
	if passive:
		_cooldown = 0.4
		return
	if not blizzard and health_fraction() <= BLIZZARD_AT:
		start_blizzard()
		return
	if distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack)
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (breath, rain, spikes) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to := hero.global_position - global_position
	_face(to)
	_play(&"idle")
	match kind:
		"breath":
			_set_state("breath")
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.radius = BREATH_RADIUS
			_telegraph.arc = BREATH_ARC
			_telegraph.angle = to.angle()
			_telegraph.duration = BREATH_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = global_position
		"rain":
			_set_state("rain")
			for i in (RAIN_DROPS_STORM if blizzard else RAIN_DROPS):
				var at := hero.global_position
				if i > 0:
					at += Vector2.from_angle(randf() * TAU) * randf_range(RAIN_RADIUS * 1.6, RAIN_SPREAD) * Vector2(1, 0.7)
				var t := ProtoTelegraph.new()
				t.radius = RAIN_RADIUS
				t.duration = RAIN_WARN + RAIN_STEP * i
				get_parent().add_child(t)
				t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)
				_drops.append(t)
		"spikes":
			_set_state("spikes")
			_spikes_from = global_position
			_spikes_dir = to.normalized() if to.length() > 1.0 else Vector2.DOWN
			var end := (_spikes_from + _spikes_dir * SPIKES_LENGTH).clamp(bounds.position, bounds.end)
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.length = _spikes_from.distance_to(end)
			_telegraph.width = SPIKES_WIDTH
			_telegraph.angle = _spikes_dir.angle()
			_telegraph.duration = SPIKES_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = _spikes_from


## Druga faza: ryk i zamieć do końca walki (śnieg na ekranie, postać szybciej marznie, więcej sopli).
func start_blizzard() -> void:
	blizzard = true
	_set_state("storm")
	_play(&"roar", true)
	_sound(ROAR_SOUND, -2.0, 0.8)
	_shake(4.0, 0.5)
	_snow = _Snow.new()
	_snow.z_index = 30
	hero.add_child(_snow)
	hero.float_text(tr("Zamieć!"), -54.0, Color(0.8, 0.95, 1.0), 14, 1.4)


func _chill(amount: float, slow: float) -> void:
	hero.slow(slow, CHILL_TIME, Elements.COLORS[Elements.COLD])
	ProtoFrost.chill_hero(hero, amount)


## Mroźne tchnienie: rani w wachlarzu, chmura mrozu przed Dziadem.
func _breath_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(BREATH_DAMAGE * power), Elements.COLD)
		_chill(BREATH_COLD, BREATH_SLOW)
	var dir := Vector2.from_angle(_telegraph.angle) if _telegraph and is_instance_valid(_telegraph) else Vector2.DOWN
	_remove_telegraph()
	var fx := Fx.once(get_parent(), BREATH_FX, BREATH_FX_FRAMES, 14.0, (global_position + Vector2(0, -20.0)).round(),
			BREATH_FX_ANCHOR, 20, BREATH_RADIUS / BREATH_FX_LENGTH)
	fx.rotation = dir.angle()
	_sound(ROAR_SOUND, -12.0, 1.6)
	_set_state("recover")


## Lodowe kolce: kryształy wyrastają po kolei wzdłuż pasa, rani postać w pasie.
func _spikes_hit() -> void:
	var length := _telegraph.length if _telegraph and is_instance_valid(_telegraph) else SPIKES_LENGTH
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(SPIKES_DAMAGE * power), Elements.COLD)
		_chill(SPIKES_COLD, 0.3)
	_remove_telegraph()
	for i in SPIKES_COUNT:
		var spot := _spikes_from + _spikes_dir * length * (i + 1) / SPIKES_COUNT
		get_tree().create_timer(SPIKES_STEP * i, false).timeout.connect(func() -> void:
			if is_inside_tree():
				Fx.once(get_parent(), SPIKES_FX, SPIKES_FX_FRAMES, 18.0, spot.round(), SPIKES_FX_ANCHOR, 2, 0.8))
	_shake(3.0, 0.3)
	_sound(SLAM_SOUND, -4.0, randf_range(1.1, 1.2))
	_set_state("recover")


## Sopel spada tam, gdzie koło się wypełniło: rani i schładza, lód pęka.
func _update_drops() -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var t := _drops[i]
		if not is_instance_valid(t):
			_drops.remove_at(i)
			continue
		if not t.has_meta("icicle") and (1.0 - t.progress) * t.duration <= ICICLE_LEAD:
			t.set_meta("icicle", true)
			Fx.once(get_parent(), ICICLE_FX, ICICLE_FX_FRAMES, ICICLE_FX_FPS, t.global_position, ICICLE_FX_ANCHOR, 20, 0.55)
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hit_hero(hero, roundi(RAIN_DAMAGE * power), Elements.COLD)
			_chill(RAIN_COLD, 0.25)
		t.queue_free()
		_drops.remove_at(i)


## Ile sopli jeszcze spada (testy).
func rain_pending() -> int:
	return _drops.size()


func _die() -> void:
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	_drops.clear()
	_stop_snow()
	super()


func _stop_snow() -> void:
	if _snow and is_instance_valid(_snow):
		_snow.queue_free()
	_snow = null


func _exit_tree() -> void:
	_remove_telegraph()
	_stop_snow()
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()


## Zamieć: płatki śniegu lecące ukośnie wokół postaci (rysowane - bez cząsteczek, tanio dla telefonów).
class _Snow extends Node2D:
	const FLAKES := 70
	const HALF := Vector2(200, 340)
	var _flakes: Array[Vector3] = []  # x, y, prędkość

	func _ready() -> void:
		for i in FLAKES:
			_flakes.append(Vector3(randf_range(-HALF.x, HALF.x), randf_range(-HALF.y, HALF.y), randf_range(60.0, 130.0)))

	func _process(delta: float) -> void:
		for i in _flakes.size():
			var f := _flakes[i]
			f.x -= f.z * 0.6 * delta
			f.y += f.z * delta
			if f.y > HALF.y:
				f.y = -HALF.y
				f.x = randf_range(-HALF.x, HALF.x + 120.0)
			if f.x < -HALF.x:
				f.x = HALF.x
			_flakes[i] = f
		queue_redraw()

	func _draw() -> void:
		for f in _flakes:
			var big := f.z > 110.0
			draw_rect(Rect2(Vector2(f.x, f.y).round(), Vector2(2, 2) if big else Vector2.ONE), Color(0.92, 0.97, 1.0, 0.85 if big else 0.6))

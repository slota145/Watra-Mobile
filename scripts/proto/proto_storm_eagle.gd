class_name ProtoStormEagle
extends ProtoChief
## Gromoskrzydły, Pan Burz - boss Górskich równin (Dungeons.PLAINS; z Wietrznych Turni Watry, ataki wybrane przez
## autora 15.11.2026). Olbrzymi burzowy orzeł unosi się nad ziemią (grafika z Watry - assets/watra/bosses/storm_eagle.png,
## 12 klatek machania skrzydłami, odbijana w lewo / prawo, kołysze się w powietrzu). Reszta (wejście, pasek zdrowia,
## trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem na ziemi:
## - Burza: STORM_BOLTS kół pod postacią jedno po drugim (co STORM_STEP s, każde pod nią w chwili pojawienia się) -
##   w każde po STORM_WARN s wali piorun: Grom i porażenie; trzeba się ruszać;
## - Nurkowanie: czerwony pas od orła w stronę postaci (DIVE_LENGTH x DIVE_WIDTH), po DIVE_WARN s orzeł przelatuje nim
##   (DIVE_TIME s) i rani, jeśli postać stoi w pasie;
## - Podmuch: koło wokół orła (GUST_RADIUS), po GUST_WARN s uderzenie skrzydeł rani, odrzuca postać (ProtoHero.leap)
##   i rozsiewa dookoła FEATHERS naelektryzowanych piór (ProtoArrow, Grom, porażenie przy trafieniu).

const SHEET := preload("res://assets/watra/bosses/storm_eagle.png")
const SHEET_COLS := 4
const SHEET_ROWS := 3
const FLAP_FPS := 12.0
## Wysokość lotu (px nad cieniem) i kołysanie.
const HOVER := 34.0
const BOB := 3.0
const EAGLE_HP := 1000
const EAGLE_SPEED := 45.0
const KEEP_DISTANCE := 80.0
const ATTACK_RANGE := 150.0
const STORM_BOLTS := 5
const STORM_STEP := 0.4
const STORM_WARN := 0.85
const STORM_RADIUS := 18.0
const STORM_DAMAGE := 18
const DIVE_LENGTH := 240.0
const DIVE_WIDTH := 30.0
const DIVE_WARN := 1.0
const DIVE_TIME := 0.35
const DIVE_DAMAGE := 28
const GUST_RADIUS := 52.0
const GUST_WARN := 1.0
const GUST_DAMAGE := 16
const GUST_PUSH := 70.0
const FEATHERS := 10
const FEATHER_DAMAGE := 10
const FEATHER_SPEED := 90.0
const SHOCK_TIME := 2.0
const SPARK := Color(1.0, 0.95, 0.5)
const BOLT_FX := preload("res://assets/effects/katana_hit.png")
const BOLT_FX_FRAMES := 10
const BOLT_FX_ANCHOR := Vector2(28, 22)
const ATTACKS: Array[String] = ["storm", "dive", "gust"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var _last_attack := ""
var _storm_left := 0
var _storm_next := 0.0
var _drops: Array[ProtoTelegraph] = []
var _dive_from := Vector2.ZERO
var _dive_to := Vector2.ZERO
var _dive_hit := false
var _flap := 0.0


func _init() -> void:
	base_hp = EAGLE_HP
	keep_distance = KEEP_DISTANCE
	move_speed = EAGLE_SPEED
	grounded = false


## Arkusz orła z Watry zamiast modelu SpriteKiln.
func _make_sprite() -> Node2D:
	var s := _EagleSprite.new()
	s.texture = SHEET
	s.hframes = SHEET_COLS
	s.vframes = SHEET_ROWS
	s.offset = Vector2(0, -HOVER)
	return s


func _process(delta: float) -> void:
	super(delta)
	_flap += delta
	if _sprite:
		_sprite.frame = int(_flap * FLAP_FPS) % (SHEET_COLS * SHEET_ROWS)
		_sprite.offset.y = -HOVER + sin(_flap * 2.5) * BOB
	_update_storm(delta)
	_update_drops()
	if state == "dead" or hero == null:
		return
	match state:
		"dive_warn":
			if _timer >= DIVE_WARN:
				_set_state("dive")
				_dive_hit = false
		"dive":
			var k := clampf(_timer / DIVE_TIME, 0.0, 1.0)
			position = _dive_from.lerp(_dive_to, k)
			if not _dive_hit and _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead \
					and global_position.distance_to(hero.global_position) < 20.0:
				_dive_hit = true
				hero.take_damage(roundi(DIVE_DAMAGE * power), Elements.LIGHTNING)
				hero.shock(SHOCK_TIME)
			if k >= 1.0:
				_remove_telegraph()
				_set_state("recover")
		"gust":
			if _timer >= GUST_WARN:
				_gust()


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "gust" or distance < GUST_RADIUS * 1.6))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (storm, dive, gust) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	_face(hero.global_position - global_position)
	match kind:
		"storm":
			_storm_left = STORM_BOLTS
			_storm_next = 0.0
			_set_state("recover")
			_timer = -STORM_STEP * STORM_BOLTS  # stoi i woła burzę
		"dive":
			_set_state("dive_warn")
			_dive_from = global_position
			var dir := (hero.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.DOWN
			_dive_to = (_dive_from + dir * DIVE_LENGTH).clamp(bounds.position, bounds.end)
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.length = _dive_from.distance_to(_dive_to)
			_telegraph.width = DIVE_WIDTH
			_telegraph.angle = (_dive_to - _dive_from).angle()
			_telegraph.duration = DIVE_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = _dive_from
		"gust":
			_set_state("gust")
			_telegraph = _make_telegraph(global_position, GUST_RADIUS, GUST_WARN)


## Burza: co STORM_STEP s nowe koło pod postacią.
func _update_storm(delta: float) -> void:
	if _storm_left <= 0 or state == "dead" or hero == null:
		return
	_storm_next -= delta
	if _storm_next > 0.0:
		return
	_storm_next = STORM_STEP
	_storm_left -= 1
	var t := ProtoTelegraph.new()
	t.radius = STORM_RADIUS
	t.duration = STORM_WARN
	get_parent().add_child(t)
	t.global_position = hero.global_position
	_drops.append(t)


## Pioruny: gdzie koło się wypełniło, tam wali.
func _update_drops() -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var t := _drops[i]
		if not is_instance_valid(t):
			_drops.remove_at(i)
			continue
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hero.take_damage(roundi(STORM_DAMAGE * power), Elements.LIGHTNING)
			hero.shock(SHOCK_TIME)
		Fx.once(get_parent(), BOLT_FX, BOLT_FX_FRAMES, 18.0, t.global_position + Vector2(0, -8), BOLT_FX_ANCHOR, 20, 1.1)
		t.queue_free()
		_drops.remove_at(i)


## Ile piorunów burzy jeszcze czeka (testy).
func storm_pending() -> int:
	return _drops.size() + _storm_left


## Podmuch: rani i odrzuca w kole, pióra lecą dookoła.
func _gust() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hero.take_damage(roundi(GUST_DAMAGE * power), Elements.LIGHTNING)
		var away := (hero.global_position - global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.DOWN
		hero.leap(hero.global_position + away * GUST_PUSH, 0.25, 6.0)
	_remove_telegraph()
	var start := randf() * TAU
	for i in FEATHERS:
		var f := ProtoArrow.new()
		f.hero = hero
		f.element = Elements.LIGHTNING
		f.tint = SPARK
		f.speed = FEATHER_SPEED
		f.fly_range = 200.0
		f.damage = roundi(FEATHER_DAMAGE * power)
		f.direction = Vector2.from_angle(start + TAU * i / FEATHERS)
		f.position = position + f.direction * 14.0
		get_parent().add_child(f)
	_shake(3.0, 0.25)
	_sound(SLAM_SOUND, -4.0, randf_range(1.3, 1.45))
	_set_state("recover")


func _die() -> void:
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	_drops.clear()
	_storm_left = 0
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()


## Arkusz orła udający model SpriteKiln (bez nazwanych animacji; kierunek - odbicie w poziomie).
class _EagleSprite extends Sprite2D:
	signal anim_finished(anim: StringName)

	func anim_names() -> Array:
		return []

	func play_anim(_anim: StringName, _restart := false) -> void:
		pass

	func face(dir: Vector2) -> void:
		if absf(dir.x) > 0.5:
			flip_h = dir.x < 0.0  # arkusz patrzy w prawo

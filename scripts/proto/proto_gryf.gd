class_name ProtoGryf
extends ProtoChief
## Gryf - boss Podniebnych wysp (Dungeons.SKY, ustalone z autorem 21.11.2026; z Pól Zbożowych Watry - scripts/gryf.gd).
## Złoty półlew-półorzeł unosi się nad ziemią (grafika z Watry - assets/watra/bosses/gryf.png, 4x2 klatki: 0-3 machanie
## skrzydłami, 4 szybowanie, 5 skrzydła szeroko - zapowiedź, 6 pikowanie, 7 szpony; arkusz patrzy w prawo, odbijany).
## Reszta (wejście, pasek zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem, żywioł
## powietrze:
## - Pikowanie: czerwony pas przez postać (DIVE_LENGTH x DIVE_WIDTH), po DIVE_WARN s gryf przelatuje nim (DIVE_TIME s);
## - Podmuch: czerwony wachlarz w stronę postaci (GUST_RADIUS, GUST_ARC), po GUST_WARN s stożek wiatru (`bow_wind_cone`
##   z Watry) rani i odrzuca postać, a wachlarzem leci BLADES ostrzy wiatru (ProtoArrow `wind`);
## - Szpony: koło pod postacią (SLAM_RADIUS), po SLAM_WARN s gryf spada na nie łukiem (SLAM_TIME s) - rani, wstrząs,
##   złote szpony z pyłem (`gryf_slam` z Watry);
## - Trąby: zrywa TWISTERS trąb powietrznych (ProtoTornado w pościgu, poniżej połowy zdrowia TWISTERS_LOW), które przez
##   TWISTER_LIFE s suną za postacią - wciągają, ranią i wyrzucają.

const SHEET := preload("res://assets/watra/bosses/gryf.png")
const SHEET_COLS := 4
const SHEET_ROWS := 2
const FLAP_FPS := 10.0
const HOVER := 32.0
const BOB := 3.0
const GRYF_HP := 1050
const GRYF_SPEED := 48.0
const KEEP_DISTANCE := 85.0
const ATTACK_RANGE := 160.0
const DIVE_LENGTH := 240.0
const DIVE_WIDTH := 32.0
const DIVE_WARN := 0.95
const DIVE_TIME := 0.38
const DIVE_DAMAGE := 28
const GUST_RADIUS := 120.0
const GUST_ARC := 1.1
const GUST_WARN := 1.0
const GUST_DAMAGE := 18
const GUST_PUSH := 80.0
const BLADES := 5
const BLADE_SPREAD := 0.22
const BLADE_DAMAGE := 10
const BLADE_SPEED := 125.0
const SLAM_RADIUS_G := 40.0
const SLAM_WARN_G := 1.0
const SLAM_TIME := 0.5
const SLAM_DAMAGE_G := 32
const TWISTERS := 2
const TWISTERS_LOW := 3
const TWISTER_LIFE := 4.5
const TWISTER_DAMAGE := 14
const TWISTER_WARN := 0.7
const WIND_FX := preload("res://assets/watra/effects/bow_wind_cone.png")
const WIND_FX_FRAMES := 9
const WIND_FX_ANCHOR := Vector2(4, 53)
const WIND_FX_LENGTH := 104.0
const SLAM_FX := preload("res://assets/watra/effects/gryf_slam.png")
const SLAM_FX_FRAMES := 10
const SLAM_FX_ANCHOR := Vector2(36, 25)
const SLAM_FX_RADIUS := 36.0
const GUST_SOUND := preload("res://assets/watra/sfx/wing_gust.ogg")
const SCREECH_SOUND := preload("res://assets/watra/sfx/storm_eagle_screech.ogg")
const ATTACKS: Array[String] = ["dive", "gust", "talons", "twisters"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var twisters: Array[ProtoTornado] = []
var _last_attack := ""
var _dive_from := Vector2.ZERO
var _dive_to := Vector2.ZERO
var _dive_hit := false
var _slam_from := Vector2.ZERO
var _slam_to := Vector2.ZERO
var _gust_dir := Vector2.RIGHT
var _flap := 0.0


func _init() -> void:
	base_hp = GRYF_HP
	keep_distance = KEEP_DISTANCE
	move_speed = GRYF_SPEED
	grounded = false


## Arkusz gryfa z Watry zamiast modelu SpriteKiln (ten sam „udawany model” co orzeł).
func _make_sprite() -> Node2D:
	var s := ProtoStormEagle._EagleSprite.new()
	s.texture = SHEET
	s.hframes = SHEET_COLS
	s.vframes = SHEET_ROWS
	s.offset = Vector2(0, -HOVER)
	return s


func _enter() -> void:
	super()
	_sound(SCREECH_SOUND, -2.0, 0.8)


func _process(delta: float) -> void:
	super(delta)
	_flap += delta
	_animate()
	_clean_twisters()
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
			if not _dive_hit and hero and not hero.dead and global_position.distance_to(hero.global_position) < 20.0:
				_dive_hit = true
				hit_hero(hero, roundi(DIVE_DAMAGE * power), Elements.AIR)
			if k >= 1.0:
				_remove_telegraph()
				_set_state("recover")
		"gust":
			if _timer >= GUST_WARN:
				_gust()
		"talons_warn":
			if _timer >= SLAM_WARN_G:
				_slam_from = global_position
				_set_state("talons")
		"talons":
			var t := clampf(_timer / SLAM_TIME, 0.0, 1.0)
			position = _slam_from.lerp(_slam_to, t)
			if _sprite:
				_sprite.position.y = -sin(t * PI) * 40.0 + t * HOVER
			if t >= 1.0:
				_talons_hit()
		"twisters":
			if _timer >= TWISTER_WARN:
				_release_twisters()


## Klatka arkusza wg stanu i kołysanie w powietrzu.
func _animate() -> void:
	if _sprite == null:
		return
	if state != "talons" and state != "enter":
		_sprite.position.y = lerpf(_sprite.position.y, 0.0, 0.3)
	_sprite.offset.y = -HOVER + sin(_flap * 2.5) * BOB
	var flap := int(_flap * FLAP_FPS) % 4
	match state:
		"dive_warn", "gust", "talons_warn", "twisters":
			_sprite.frame = 5
		"dive":
			_sprite.frame = 6
		"talons":
			_sprite.frame = 7
		"dead":
			_sprite.frame = 4
		_:
			_sprite.frame = flap


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "gust" or distance < GUST_RADIUS * 0.9))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (dive, gust, talons, twisters) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to_hero := hero.global_position - global_position
	_face(to_hero)
	match kind:
		"dive":
			_set_state("dive_warn")
			_dive_from = global_position
			var dir := to_hero.normalized() if to_hero.length() > 1.0 else Vector2.DOWN
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
			_gust_dir = to_hero.normalized() if to_hero.length() > 1.0 else Vector2.DOWN
			_telegraph = _make_telegraph(global_position, GUST_RADIUS, GUST_WARN)
			_telegraph.arc = GUST_ARC
			_telegraph.angle = ProtoTelegraph.ground_angle(_gust_dir)
		"talons":
			_set_state("talons_warn")
			_slam_to = hero.global_position.clamp(bounds.position, bounds.end)
			_telegraph = _make_telegraph(_slam_to, SLAM_RADIUS_G, SLAM_WARN_G + SLAM_TIME)
		"twisters":
			_set_state("twisters")
			_sound(SCREECH_SOUND, -4.0, 1.1)


## Podmuch skrzydeł: stożek wiatru rani i odrzuca, wachlarz ostrzy wiatru.
func _gust() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(GUST_DAMAGE * power), Elements.AIR)
		hero.leap((hero.global_position + _gust_dir * GUST_PUSH).clamp(hero.bounds.position, hero.bounds.end), 0.25, 6.0)
	_remove_telegraph()
	var fx := Fx.once(get_parent(), WIND_FX, WIND_FX_FRAMES, 18.0, global_position, WIND_FX_ANCHOR, 20, GUST_RADIUS / WIND_FX_LENGTH)
	fx.rotation = _gust_dir.angle()
	for i in BLADES:
		var b := ProtoArrow.new()
		b.hero = hero
		b.wind = true
		b.tint = Color(1.0, 0.95, 0.8)
		b.speed = BLADE_SPEED
		b.fly_range = 260.0
		b.damage = roundi(BLADE_DAMAGE * power)
		b.direction = _gust_dir.rotated((i - (BLADES - 1) / 2.0) * BLADE_SPREAD)
		b.position = position + b.direction * 14.0
		get_parent().add_child(b)
	_sound(GUST_SOUND, -3.0, randf_range(0.9, 1.05))
	_set_state("recover")


## Lądowanie szponami: rani w kole, wstrząs, złote szpony.
func _talons_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(SLAM_DAMAGE_G * power), Elements.AIR)
	_remove_telegraph()
	Fx.once(get_parent(), SLAM_FX, SLAM_FX_FRAMES, 16.0, global_position, SLAM_FX_ANCHOR, 20, SLAM_RADIUS_G / SLAM_FX_RADIUS)
	_shake(5.0, 0.3)
	_sound(SLAM_SOUND, -2.0, randf_range(1.1, 1.25))
	_set_state("recover")


## Trąby powietrzne: suną za postacią (więcej, gdy gryf ma mniej niż połowę zdrowia).
func _release_twisters() -> void:
	var n := TWISTERS if hp > max_hp / 2.0 else TWISTERS_LOW
	for i in n:
		var t := ProtoTornado.new()
		t.hero = hero
		t.chase = true
		t.life = TWISTER_LIFE
		t.damage = roundi(TWISTER_DAMAGE * power)
		t.position = position + Vector2.from_angle(TAU * i / n + randf() * 0.5) * 40.0
		get_parent().add_child(t)
		twisters.append(t)
	_sound(GUST_SOUND, -2.0, 0.8)
	_set_state("recover")


func _clean_twisters() -> void:
	for i in range(twisters.size() - 1, -1, -1):
		if not is_instance_valid(twisters[i]):
			twisters.remove_at(i)


func _die() -> void:
	for t in twisters:
		if is_instance_valid(t):
			t.queue_free()
	twisters.clear()
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	for t in twisters:
		if is_instance_valid(t):
			t.queue_free()

class_name ProtoLeszy
extends ProtoChief
## Leszy, Pan Puszczy - boss Prastarego Boru (Dungeons.FOREST, ustalone z autorem 25.11.2026; z Prastarego Lasu Watry -
## scripts/leshy.gd): wysoki, chudy duch lasu z ciałem z kory, brodą z mchu, porożem i kosturem. Grafika z Watry
## (assets/watra/bosses/leshy.png, 4x2 klatki 52x70: 0-3 chód, 4 spoczynek, 5 wezwanie, 6 korzenie, 7 wir liści;
## arkusz patrzy w prawo, odbijany - „udawany model” ProtoStormEagle._EagleSprite). Reszta (wejście, pasek zdrowia,
## trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem, żywioł natura:
## - Korzenie: czerwony pas w stronę postaci (ROOTS_LENGTH x ROOTS_WIDTH), po ROOTS_WARN s z ziemi wzdłuż pasa wybuchają
##   korzenie (leshy_roots z Watry) - ranią i na chwilę trzymają (prawie pełne spowolnienie);
## - Przebudzenie: okrzyk - z ziemi wyrastają AWAKEN dzikie drzewce (`minion_kind` brute - ProtoWildTreant);
## - Wir liści: czerwony wachlarz przed Leszym (LEAVES_RADIUS, LEAVES_ARC), po LEAVES_WARN s wirujące liście
##   (leshy_leaves z Watry) tną wszystko w stożku.

const SHEET := preload("res://assets/watra/bosses/leshy.png")
const SHEET_COLS := 4
const SHEET_ROWS := 2
const WALK_FPS := 6.0
const FRAME_IDLE := 4
const FRAME_SUMMON := 5
const FRAME_ROOTS := 6
const FRAME_LEAVES := 7
const LESZY_HP := 1300
const LESZY_SPEED := 30.0
const KEEP_DISTANCE := 75.0
const ATTACK_RANGE := 170.0
const ROOTS_LENGTH := 230.0
const ROOTS_WIDTH := 30.0
const ROOTS_WARN := 1.0
const ROOTS_DAMAGE := 26
const ROOTS_HOLD := 1.2
const ROOTS_SLOW := 0.9
const ROOTS_SPOTS := 7
const ROOTS_STEP := 0.05
const AWAKEN := 2
const AWAKEN_TIME := 1.0
const AWAKEN_RING := 46.0
const AWAKEN_COOLDOWN := 12.0
const LEAVES_RADIUS := 130.0
const LEAVES_ARC := deg_to_rad(70.0)
const LEAVES_WARN := 1.0
const LEAVES_DAMAGE := 24
const ROOTS_FX := preload("res://assets/watra/effects/leshy_roots.png")
const LEAVES_FX := preload("res://assets/watra/effects/leshy_leaves.png")
const ATTACKS: Array[String] = ["roots", "leaves", "awaken"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var _last_attack := ""
var _walk_t := 0.0
var _awaken_cd := 4.0
var _roots_from := Vector2.ZERO
var _roots_dir := Vector2.DOWN


func _init() -> void:
	base_hp = LESZY_HP
	keep_distance = KEEP_DISTANCE
	move_speed = LESZY_SPEED
	minion_kind = "brute"


## Arkusz Leszego z Watry zamiast modelu SpriteKiln (ten sam „udawany model” co orzeł i gryf).
func _make_sprite() -> Node2D:
	var s := ProtoStormEagle._EagleSprite.new()
	s.texture = SHEET
	s.hframes = SHEET_COLS
	s.vframes = SHEET_ROWS
	s.offset = Vector2(0, -33)
	s.frame = FRAME_IDLE
	return s


func _process(delta: float) -> void:
	var before := position
	super(delta)
	_awaken_cd -= delta
	_animate(delta, position.distance_to(before) > 0.05)
	if state == "dead" or hero == null:
		return
	match state:
		"roots":
			if _timer >= ROOTS_WARN:
				_roots_hit()
		"leaves":
			if _timer >= LEAVES_WARN:
				_leaves_hit()
		"awaken":
			if _timer >= AWAKEN_TIME:
				_awaken()


## Klatki arkusza: chód, gdy idzie, poza tym spoczynek; w atakach - klatka ataku.
func _animate(delta: float, moving: bool) -> void:
	var s := _sprite as Sprite2D
	if s == null:
		return
	match state:
		"roots":
			s.frame = FRAME_ROOTS
		"leaves":
			s.frame = FRAME_LEAVES
		"awaken", "enter":
			s.frame = FRAME_SUMMON
		_:
			if moving:
				_walk_t += delta * WALK_FPS
				s.frame = int(_walk_t) % 4
			else:
				s.frame = FRAME_IDLE


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "awaken" or _awaken_cd <= 0.0))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (roots, leaves, awaken) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to := hero.global_position - global_position
	_face(to)
	match kind:
		"roots":
			_set_state("roots")
			_roots_from = global_position
			_roots_dir = to.normalized() if to.length() > 1.0 else Vector2.DOWN
			var end := (_roots_from + _roots_dir * ROOTS_LENGTH).clamp(bounds.position, bounds.end)
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.length = _roots_from.distance_to(end)
			_telegraph.width = ROOTS_WIDTH
			_telegraph.angle = _roots_dir.angle()
			_telegraph.duration = ROOTS_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = _roots_from
		"leaves":
			_set_state("leaves")
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.radius = LEAVES_RADIUS
			_telegraph.arc = LEAVES_ARC
			_telegraph.angle = to.angle()
			_telegraph.duration = LEAVES_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = global_position
		"awaken":
			_set_state("awaken")
			_awaken_cd = AWAKEN_COOLDOWN
			_sound(ROAR_SOUND, -3.0, 0.7)


## Korzenie wybuchają po kolei wzdłuż pasa: postać w pasie obrywa i korzenie ją trzymają.
func _roots_hit() -> void:
	var length := _telegraph.length if _telegraph and is_instance_valid(_telegraph) else ROOTS_LENGTH
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(ROOTS_DAMAGE * power), Elements.NATURE)
		hero.slow(ROOTS_SLOW, ROOTS_HOLD, Elements.COLORS[Elements.NATURE])
	_remove_telegraph()
	for i in ROOTS_SPOTS:
		var spot := _roots_from + _roots_dir * length * (i + 1) / ROOTS_SPOTS
		get_tree().create_timer(ROOTS_STEP * i, false).timeout.connect(func() -> void:
			if is_inside_tree():
				Fx.once(get_parent(), ROOTS_FX, 10, 16.0, spot.round(), Vector2(24, 39), 20, 1.0))
	_shake(3.0, 0.3)
	_sound(SLAM_SOUND, -4.0, randf_range(0.8, 0.9))
	_set_state("recover")


## Wir liści: rani w wachlarzu przed Leszym.
func _leaves_hit() -> void:
	var dir := Vector2.from_angle(_telegraph.angle) if _telegraph and is_instance_valid(_telegraph) else Vector2.DOWN
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(LEAVES_DAMAGE * power), Elements.NATURE)
	_remove_telegraph()
	var fx := Fx.once(get_parent(), LEAVES_FX, 10, 16.0, (global_position + Vector2(0, -20)).round(), Vector2(11, 32), 20,
			LEAVES_RADIUS / 90.0)
	fx.rotation = dir.angle()
	_set_state("recover")


## Przebudzenie: z ziemi wokół Leszego wyrastają dzikie drzewce (arena - ProtoHorde.spawn_at z `minion_kind`).
func _awaken() -> void:
	var points: Array = []
	var start := randf() * TAU
	for i in AWAKEN:
		var p := global_position + Vector2.from_angle(start + TAU * i / AWAKEN) * AWAKEN_RING * Vector2(1, 0.7)
		points.append(p)
		Fx.once(get_parent(), ROOTS_FX, 10, 16.0, p.round(), Vector2(24, 39), 20, 1.3)
	summon_minions.emit(points)
	_set_state("recover")

class_name ProtoDwarfKing
extends ProtoChief
## Król Karłów Kowal - boss Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026; liczby - Claude): opętany
## przez Hordę król karłów, kowal z wielkim młotem i kowadłem. Reszta (wejście, pasek zdrowia, trafienia, śmierć,
## skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem na ziemi, żywioł ziemia:
## - Uderzenie młotem (`hammer`, animacja `slam`): koło wokół Króla i WAVES pasów fali w stronę postaci (wachlarz co
##   WAVE_SPREAD), po HAMMER_WARN s młot wali w ziemię - wstrząs w kole, wzdłuż pasów wyskakują skalne kolce
##   (slam_spikes); rani raz (koło - HAMMER_DAMAGE, pas - WAVE_DAMAGE). Poniżej połowy zdrowia WAVES_RAGE pasów;
## - Deszcz odłamków (`shards`, animacja `shards` - uderzenie w kowadło): SHARDS kół wokół postaci (pierwsze pod nią),
##   po kolei spadają odłamki skały (głazy z tools/mine_art.py w mniejszej skali) - ranią w kole; poniżej połowy SHARDS_RAGE;
## - Przywołanie (`summon`, co najwyżej co SUMMON_EVERY s): z ziemi wyskakują skalne golemy (`minion_kind` brute -
##   ProtoStoneGolem), poniżej połowy zdrowia - więcej.
## Grafika: model SpriteKiln assets/spritekiln/dwarf_king/ (idle, walk, attack, slam - `hit` ok. 0,9 s, shards i summon
## - `release` ok. 0,6 s, hit, death), do czasu grafiki - powiększony goblin w zastępczym kolorze.

const BOSS_SCENE := "res://assets/spritekiln/dwarf_king/dwarf_king.tscn"
const BOSS_HP := 1400
const KING_SPEED := 26.0
const KEEP_DISTANCE := 55.0
const ATTACK_RANGE := 170.0
const HAMMER_RANGE := 120.0
const HAMMER_WARN := 1.2
const HAMMER_RADIUS := 48.0
const HAMMER_DAMAGE := 32
const WAVES := 3
const WAVES_RAGE := 5
const WAVE_SPREAD := deg_to_rad(32.0)
const WAVE_LENGTH := 200.0
const WAVE_WIDTH := 26.0
const WAVE_DAMAGE := 26
## Kolce fali wyskakują co WAVE_STEP px, kolejno co WAVE_DELAY s.
const WAVE_STEP := 30.0
const WAVE_DELAY := 0.035
const SHARDS := 6
const SHARDS_RAGE := 9
const SHARD_RADIUS := 18.0
const SHARD_SPREAD := 85.0
const SHARD_WARN := 1.1
const SHARD_STEP := 0.14
const SHARD_DAMAGE := 20
const SHARD_FALL := 0.3
const SHARD_SCALE := 0.6
const SUMMON_EVERY := 16.0
const SUMMON_COUNT := 2
const SUMMON_COUNT_RAGE := 3
const SUMMON_RING := 46.0
const SUMMON_TIME := 1.0
const RAGE_AT := 0.5
const TREMOR_FX := preload("res://assets/effects/earth_tremor.png")
const TREMOR_FRAMES := 9
const TREMOR_ANCHOR := Vector2(58, 24)
const SPIKES_FX := preload("res://assets/effects/slam_spikes.png")
const SPIKES_FRAMES := 18
const SPIKES_ANCHOR := Vector2(30, 34)
const ERUPT_FX := preload("res://assets/effects/ground_slam.png")
const ERUPT_FRAMES := 10
const ERUPT_ANCHOR := Vector2(26, 35)
const ATTACKS: Array[String] = ["hammer", "shards"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var _last_attack := ""
var _summon_ready := 6.0
var _summoned := false
var _waves: Array[ProtoTelegraph] = []
## Spadające odłamki: {"t": ProtoTelegraph, "rock": Sprite2D albo null}.
var _shards: Array = []
## Ile razy młot (koło lub fala) i odłamki trafiły postać (testy).
var hammer_hits := 0
var shard_hits := 0


func _init() -> void:
	scene_path = BOSS_SCENE
	base_hp = BOSS_HP
	fallback_tint = Color(0.85, 0.6, 0.4)
	keep_distance = KEEP_DISTANCE
	move_speed = KING_SPEED
	minion_kind = "brute"
	anim_hit_at = {&"slam": 0.9, &"shards": 0.6, &"summon": 0.6}
	anim_fallback = {&"slam": &"attack", &"shards": &"attack", &"summon": &"attack", &"roar": &"summon",
		&"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_update_shards()
	if state == "dead" or hero == null:
		return
	_summon_ready -= delta
	match state:
		"hammer":
			_sync_anim(&"slam", HAMMER_WARN)
			if _timer >= HAMMER_WARN:
				_hammer_hit()
		"shards":
			_sync_anim(&"shards", anim_hit_at[&"shards"])
			if _timer >= SHARD_WARN * 0.8:
				_set_state("recover")
		"summon":
			_sync_anim(&"summon", SUMMON_TIME * 0.6)
			if _timer >= SUMMON_TIME * 0.6 and not _summoned:
				_summon_golems()
			if _timer >= SUMMON_TIME:
				_set_state("recover")


func _choose_attack(distance: float) -> void:
	if passive:
		_cooldown = 0.4
		return
	if _summon_ready <= 0.0:
		start_attack("summon")
		return
	if distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack)
	if distance > HAMMER_RANGE:
		pool = ["shards"]
	start_attack(pool.pick_random())


func _rage() -> bool:
	return health_fraction() <= RAGE_AT


## Zaczyna atak `kind` (hammer, shards, summon) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to := hero.global_position - global_position
	_face(to)
	_play(&"idle")
	match kind:
		"hammer":
			_set_state("hammer")
			_telegraph = _make_telegraph(global_position, HAMMER_RADIUS, HAMMER_WARN)
			_clear_waves()
			var dir := to.normalized() if to.length() > 1.0 else Vector2.DOWN
			var n := WAVES_RAGE if _rage() else WAVES
			for i in n:
				var a := dir.angle() + (i - (n - 1) / 2.0) * WAVE_SPREAD
				var t := ProtoTelegraph.new()
				t.length = WAVE_LENGTH
				t.width = WAVE_WIDTH
				t.angle = a
				t.duration = HAMMER_WARN
				get_parent().add_child(t)
				t.global_position = global_position
				_waves.append(t)
		"shards":
			_set_state("shards")
			for i in (SHARDS_RAGE if _rage() else SHARDS):
				var at := hero.global_position
				if i > 0:
					at += Vector2.from_angle(randf() * TAU) * randf_range(SHARD_RADIUS * 1.6, SHARD_SPREAD) * Vector2(1, 0.7)
				var t := ProtoTelegraph.new()
				t.radius = SHARD_RADIUS
				t.duration = SHARD_WARN + SHARD_STEP * i
				get_parent().add_child(t)
				t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)
				_shards.append({"t": t, "rock": null})
		"summon":
			_set_state("summon")
			_summon_ready = SUMMON_EVERY
			_summoned = false
			_sound(ROAR_SOUND, -4.0, 0.7)


## Młot wali w ziemię: rani w kole albo na pasie fali (raz), wstrząs i kolce wzdłuż fal.
func _hammer_hit() -> void:
	if hero and not hero.dead:
		if _telegraph and is_instance_valid(_telegraph) and _telegraph.contains(hero.global_position):
			hammer_hits += 1
			hit_hero(hero, roundi(HAMMER_DAMAGE * power), Elements.EARTH)
		elif _waves.any(func(t: ProtoTelegraph) -> bool: return is_instance_valid(t) and t.contains(hero.global_position)):
			hammer_hits += 1
			hit_hero(hero, roundi(WAVE_DAMAGE * power), Elements.EARTH)
	_remove_telegraph()
	_sound(SLAM_SOUND, 2.0, randf_range(0.65, 0.75))
	_shake(5.0, 0.3)
	Fx.once(get_parent(), TREMOR_FX, TREMOR_FRAMES, 14.0, global_position.round(), TREMOR_ANCHOR, -1, HAMMER_RADIUS / 56.0 * 1.3)
	var tween := create_tween()
	var steps := int(WAVE_LENGTH / WAVE_STEP)
	for k in steps:
		var spots: Array[Vector2] = []
		for t in _waves:
			if is_instance_valid(t):
				spots.append(global_position + Vector2.from_angle(t.angle) * WAVE_STEP * (k + 1))
		tween.tween_callback(func() -> void:
			for p in spots:
				if get_parent():
					Fx.once(get_parent(), SPIKES_FX, SPIKES_FRAMES, 22.0, p.round(), SPIKES_ANCHOR, 2, 0.55))
		tween.tween_interval(WAVE_DELAY)
	_clear_waves()
	_set_state("recover")


## Z ziemi wokół Króla wyskakują skalne golemy (arena - ProtoHorde.spawn_at z `minion_kind`).
func _summon_golems() -> void:
	_summoned = true
	var points: Array = []
	var n := SUMMON_COUNT_RAGE if _rage() else SUMMON_COUNT
	var start := randf() * TAU
	for i in n:
		points.append((global_position + Vector2.from_angle(start + TAU * i / n) * SUMMON_RING * Vector2(1, 0.7))
				.clamp(bounds.position, bounds.end))
	for p in points:
		Fx.once(get_parent(), ERUPT_FX, ERUPT_FRAMES, 15.0, (p as Vector2).round(), ERUPT_ANCHOR, 2, 1.1)
	_shake(3.0, 0.2)
	summon_minions.emit(points)


## Odłamki spadają, gdy koło się wypełni (widać je w locie przez ostatnie SHARD_FALL s).
func _update_shards() -> void:
	for i in range(_shards.size() - 1, -1, -1):
		var s: Dictionary = _shards[i]
		var t: ProtoTelegraph = s.t
		if not is_instance_valid(t):
			_shards.remove_at(i)
			continue
		var left := (1.0 - t.progress) * t.duration
		if s.rock == null and left <= SHARD_FALL:
			s.rock = _make_shard(t.global_position)
		if s.rock and is_instance_valid(s.rock):
			var k := clampf(1.0 - left / SHARD_FALL, 0.0, 1.0)
			(s.rock as Sprite2D).position = t.global_position + Vector2(0, -130.0 * (1.0 - k * k))
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			shard_hits += 1
			hit_hero(hero, roundi(SHARD_DAMAGE * power), Elements.EARTH)
		Fx.once(get_parent(), ProtoRockfall.SHARDS_FX, ProtoRockfall.SHARDS_FRAMES, 16.0, t.global_position.round(),
				ProtoRockfall.SHARDS_ANCHOR, 2, 0.9)
		if s.rock and is_instance_valid(s.rock):
			s.rock.queue_free()
		t.queue_free()
		_shards.remove_at(i)


func _make_shard(at: Vector2) -> Sprite2D:
	var r := Sprite2D.new()
	r.texture = ProtoRockfall.ROCK_TEX
	r.hframes = ProtoRockfall.ROCK_FRAMES
	r.frame = randi() % ProtoRockfall.ROCK_FRAMES
	r.scale = Vector2.ONE * SHARD_SCALE
	r.offset = Vector2(0, -ProtoRockfall.ROCK_TEX.get_height() / 2.0)
	r.z_index = 6
	get_parent().add_child(r)
	r.position = at + Vector2(0, -130.0)
	return r


## Ile odłamków jeszcze spada (testy).
func shards_pending() -> int:
	return _shards.size()


func _clear_waves() -> void:
	for t in _waves:
		if is_instance_valid(t):
			t.queue_free()
	_waves.clear()


func _clear_shards() -> void:
	for s in _shards:
		if is_instance_valid(s.t):
			s.t.queue_free()
		if s.rock and is_instance_valid(s.rock):
			s.rock.queue_free()
	_shards.clear()


func _die() -> void:
	_clear_waves()
	_clear_shards()
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	_clear_waves()
	_clear_shards()

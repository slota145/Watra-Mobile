class_name ProtoHammer
extends ProtoWeapon
## Młot - broń ziemi (ustalone z autorem 21.11.2026; Elements.EARTH - ogłusza i odpycha). Jeden ciężki, dwuręczny młot
## bojowy lewituje obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie, krytyki,
## Rozłupanie Ziemi - przeniesione z miecza). Grafika assets/weapons/hammer.png (tools/hammer_art.py), ikony
## tools/hammer_icons.py. Efekty z kreatora PixelLab już w grze: boss_slam (pył uderzenia), slam_spikes (skalne kolce),
## earth_tremor (fala wstrząsu), legend_shockwave (fala wokół trafionych), cleaver_impact (trafienie rzutem).
## - „Uderzenie młotem” (`m_smash`, zwykły atak): młot wznosi się nad najbliższego wroga i spada obuchem - rani w kole
##   SMASH_RADIUS i odpycha; 5. poziom - co trzecie uderzenie ogłusza, 10. - fala wstrząsu dookoła; kamień unikalny
##   (Lawiny) - co SMASH_ROCKS_EVERY uderzenie 3 odłamki skały spadają na pobliskich wrogów (`_rocks`).
## - „Rzut młotem” (`m_throw`): młot leci, wirując, w najbliższego wroga, odbija się od trafionych (HT_BOUNCES,
##   5. poziom - więcej), każdego ogłusza, potem wraca; 10. - fala wstrząsu przy każdym trafieniu; kamień unikalny
##   (Powrotu) - wracając, rani wszystkich na drodze.
## - „Skok z uderzeniem” (`m_leap`): postać skacze (nietykalna w locie) w stronę gałki albo najbliższego wroga, młot
##   uderza przy lądowaniu - krater rani, ogłusza i odpycha; 5. - krater większy, 10. - fala kolców (szczeliny gwiazdą od krateru, `_spike_wave`);
##   kamień unikalny (Grzęzawiska) - krater zostaje na LEAP_PIT_TIME s, spowalnia i rani (`_pits`).
## - „Trzęsienie ziemi” (`m_quake`, trzymany - Skills.is_charged, `charge_held`): dopóki palec trzyma przycisk i starcza
##   many (koszt na sekundę), co QUAKE_EVERY s fala wokół postaci rani i odpycha; postać idzie wolniej
##   (ProtoHero.form_speed); 5. - fale częściej, 10. - co trzecia ogłusza; kamień unikalny (Uskoku) - każda fala
##   wypuszcza szczelinę z kolcami w najbliższego wroga.

const HAMMER_TEXTURE := preload("res://assets/weapons/hammer.png")
## Punkt chwytu w arkuszu (owijki przy głowicy trzonka), skala w grze (większy niż miecz - ciężka broń) i długość
## od chwytu do końca obucha w grze (px).
const H_GRIP := Vector2(10.0, 18.0)
const H_SCALE := 0.62
const HAMMER_LEN := 38.0
const DUST_FX := preload("res://assets/effects/boss_slam.png")
const DUST_FRAMES := 12
const DUST_ANCHOR := Vector2(37, 25)
const DUST_RADIUS := 34.0
const TREMOR_FX := preload("res://assets/effects/earth_tremor.png")
const TREMOR_FRAMES := 9
const TREMOR_ANCHOR := Vector2(58, 24)
const TREMOR_RADIUS := 56.0
const IMPACT_FX := preload("res://assets/effects/cleaver_impact.png")
const IMPACT_FRAMES := 9
const IMPACT_ANCHOR := Vector2(23, 17)
const EARTH_TINT := Color(1.0, 0.82, 0.6)
const SMASH_RISE := 0.2
const SMASH_FALL := 0.07
const SMASH_RECOVER := 0.22
const SMASH_COOLDOWN := 0.45
const SMASH_HEIGHT := 34.0
const SMASH_RADIUS := 24.0
const SMASH_PUSH := 70.0
const SMASH_STUN := 0.6
const SMASH_WAVE := 48.0
const SMASH_WAVE_POWER := 0.4
const SMASH_ROCKS_EVERY := 4
const SMASH_ROCKS := 3
const SMASH_ROCK_RANGE := 90.0
const SMASH_ROCK_POWER := 0.5
const HT_SPEED := 320.0
const HT_BACK_SPEED := 360.0
const HT_BOUNCES := 3
const HT_BOUNCES_PERK := 5
const HT_EXTRA := 2
const HT_BOUNCE_RANGE := 95.0
const HT_STUN := 0.4
const HT_TIME_MAX := 3.0
const HT_RETURN_POWER := 0.6
const HT_SHOCK := 30.0
const LEAP_TIME := 0.45
const LEAP_HOP := 30.0
const LEAP_RADIUS := 48.0
const LEAP_PERK_AREA := 1.3
const LEAP_STUN := 0.8
const LEAP_PUSH := 120.0
const LEAP_ECHO := 0.2
const LEAP_ECHO_RADIUS := 1.4
## 10. poziom skoku (prośba autora po teście 21.11.2026 - zamiast pierścienia kolców naraz): fala kolców - z krateru
## rozchodzi się LEAP_CRACKS szczelin jak gwiazda (jak szczelina Rozłupania Ziemi), wzdłuż każdej po kolei od środka
## wyskakują LEAP_CRACK_SPIKES kolce; każdy wróg obrywa od fali raz.
const LEAP_CRACKS := 6
const LEAP_CRACK_SPIKES := 4
const LEAP_CRACK_LENGTH := 85.0
const LEAP_CRACK_TIME := 0.35
const LEAP_SPIKE_POWER := 0.5
const LEAP_PIT_TIME := 4.0
const LEAP_PIT_TICK := 0.5
const LEAP_PIT_SLOW := 0.5
const LEAP_PIT_POWER := 0.2
const QUAKE_EVERY := 0.5
const QUAKE_EVERY_PERK := 0.4
const QUAKE_RADIUS := 60.0
const QUAKE_PUSH := 90.0
const QUAKE_STUN := 0.5
const QUAKE_SLOW_WALK := 0.6
const QUAKE_CRACK := 90.0
const QUAKE_CRACK_POWER := 0.4
const SPIKE_RADIUS := 16.0

## Ile uderzeń młotem padło (5. poziom - co trzecie ogłusza; kamień Lawiny - co czwarte odłamki).
var smash_count := 0
var _smash_at := Vector2.ZERO
## Rzut: obecny cel, trafieni, ile odbić zostało (i ile z nich to dodatkowe z Mnożenia), kto oberwał przy powrocie.
var _throw_target: ProtoTarget
var _throw_hits: Array = []
var _h_bounces := 0
var _extra_left := 0
var _back_hits: Array = []
var _spin_angle := 0.0
## Trzęsienie: ile fal (10. poziom - co trzecia ogłusza), do następnej fali, uzbierana mana.
var quake_waves := 0
var _quake_t := 0.0
var _quake_drain_acc := 0.0
## Kratery z kamienia Grzęzawiska ({"node", "at", "radius", "left", "tick"}).
var _pits: Array = []


func _init() -> void:
	basic = "m_smash"
	main_skill = "m_smash"
	element = Elements.EARTH
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = HAMMER_TEXTURE
		s.offset = -H_GRIP
		s.scale = Vector2.ONE * H_SCALE


func _world_fx() -> Array:
	return super._world_fx() + [_pits]


func _exit_tree() -> void:
	if hero and hero.form_speed != 1.0 and _state == "m_quake":
		hero.form_speed = 1.0
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"m_rise", "m_fall", "m_recover":
			_process_smash()
		"m_throw", "m_back":
			_process_throw_hammer(delta)
		"m_leap":
			_process_leap()
		"m_quake":
			_process_quake(delta)
	_process_pits(delta)


## Trafienie umiejętnością `skill` z siłą `power` (pył ziemi na celu).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)


## Wszyscy w kole `radius` wokół `at` (spłaszczonym jak cienie). Zwraca trafionych.
func _ring_hits(at: Vector2, radius: float, power: float, skill: String) -> Array:
	var hit: Array = []
	for t in _near(at, radius):
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, skill)
			hit.append(t)
	return hit


func _dust(at: Vector2, radius: float) -> void:
	Fx.once(get_parent(), DUST_FX, DUST_FRAMES, 16.0, at.round(), DUST_ANCHOR, -1, minf(radius / DUST_RADIUS, 2.5))


func _tremor(at: Vector2, radius: float) -> void:
	var fx := Fx.once(get_parent(), TREMOR_FX, TREMOR_FRAMES, 14.0, at.round(), TREMOR_ANCHOR, -1, minf(radius / TREMOR_RADIUS, 2.5))
	fx.modulate = Color(EARTH_TINT, 0.5)  # przygaszona - pełna zasłaniała potwory


func _shake(strength: float) -> void:
	var cam := hero.get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	for i in 3:
		tw.tween_property(cam, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


## Skalny kolec w `spot`: rani i krótko ogłusza wrogów obok.
func _spike(spot: Vector2, power: float, skill: String) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	Fx.once(get_parent(), SLAM_SPIKE_FX, SLAM_SPIKE_FRAMES, 16.0, spot.round(), SLAM_SPIKE_ANCHOR, 2, 0.8)
	for t in _ring_hits(spot, SPIKE_RADIUS * _area(skill), power, skill):
		t.stun(0.3)


# --- Uderzenie młotem (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		smash_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	var reach: float = Skills.DATA[basic].range * _area(basic)
	var best: ProtoTarget = null
	if second:  # Mnożenie: drugie uderzenie w innego wroga obok (bez niego - w to samo miejsce)
		for t in _near(_smash_at, reach):
			if t.global_position.distance_to(_smash_at) > SMASH_RADIUS:
				best = t
				break
	else:
		best = _nearest(reach)
	# _goal - w układzie rodzica (świat lochu), jak przy Rozłupaniu
	_goal = best.position if best else (position if second else hero.position + hero.facing.normalized() * 26.0)
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("m_rise")
	hero.play_gesture(_goal)


func _process_smash() -> void:
	match _state:
		"m_rise":
			var k := ease(clampf(_t / SMASH_RISE, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(_goal, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -SMASH_HEIGHT - HAMMER_LEN), k)
			_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
			if _t >= SMASH_RISE:
				_set_state("m_fall")
		"m_fall":
			var k := clampf(_t / SMASH_FALL, 0.0, 1.0)
			_sprite.position = Vector2(0, lerpf(-SMASH_HEIGHT - HAMMER_LEN, -HAMMER_LEN + 4.0, k * k))
			if _t >= SMASH_FALL:
				_smash_hit()
				_set_state("m_recover")
		"m_recover":
			if _t >= SMASH_RECOVER:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = SMASH_COOLDOWN


## Uderzenie obuchem: koło rani i odpycha; 5. - co trzecie ogłusza; 10. - fala wstrząsu; Lawina - odłamki.
func _smash_hit() -> void:
	var at := global_position
	_smash_at = at
	var radius := SMASH_RADIUS * _area(basic)
	var power := _swing_power * _power(basic)
	var stun := _perk(basic, 0) and not _second and smash_count % 3 == 0
	for t in _ring_hits(at, radius, power, basic):
		t.push_away(at, SMASH_PUSH)
		if stun:
			t.stun(SMASH_STUN)
	_dust(at, radius)
	if _perk(basic, 1) and not _second:
		var wave := SMASH_WAVE * _area(basic)
		for t in _near(at, wave):
			var d := t.global_position - at
			var flat := Vector2(d.x, d.y * 1.6).length()
			if flat > radius and flat <= wave:
				_hit(t, power * SMASH_WAVE_POWER, at, basic)
		_tremor(at, wave)
	if _unique(basic) and not _second and smash_count % SMASH_ROCKS_EVERY == 0:
		_rocks(at, power * SMASH_ROCK_POWER)
	Input.vibrate_handheld(18)
	_shake(1.5)


## Kamień Lawiny: odłamki skały spadają na losowych wrogów w pobliżu (bez wrogów - wokół miejsca uderzenia).
func _rocks(at: Vector2, power: float) -> void:
	var near := _near(at, SMASH_ROCK_RANGE)
	near.shuffle()
	for i in SMASH_ROCKS:
		var spot: Vector2 = near[i].global_position if i < near.size() else at + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 60.0)
		get_tree().create_timer(0.12 + 0.1 * i, false).timeout.connect(_spike.bind(spot, power, basic))


# --- Umiejętności ---

func cooldown_full(id: String) -> float:
	if id == "m_quake":
		return 0.0
	return super.cooldown_full(id)


func can_use(id: String) -> bool:
	if id == "m_quake":
		return Skills.has(id) and not hero.dead and hero.can_pay(_quake_tick_cost())
	return super.can_use(id)


func _start(id: String) -> void:
	if id == basic or not id in ["m_throw", "m_leap", "m_quake"]:
		super._start(id)
		return
	if not can_use(id):
		return
	if id != "m_quake":
		if not hero.spend_mana(mana_cost(id)):
			return
		_cd[id] = cooldown_full(id)
	_hit_done = false
	match id:
		"m_throw":
			_start_throw()
		"m_leap":
			_start_leap()
		"m_quake":
			quake_waves = 0
			_quake_t = 0.0
			_quake_drain_acc = 0.0
			hero.form_speed = QUAKE_SLOW_WALK
			_set_state("m_quake")
	skill_used.emit(id)


func _end_skill() -> void:
	if _state == "m_quake" and hero:
		hero.form_speed = 1.0
	_throw_target = null
	super._end_skill()


## Rozłupanie Ziemi młotem: obuch (głowica w dół) spada niżej niż miecz - młot jest dłuższy.
func _process_slam() -> void:
	if _state == "slam_fall":
		var k := clampf(_t / SLAM_FALL, 0.0, 1.0)
		_sprite.position = Vector2(0, lerpf(-SLAM_HEIGHT, -HAMMER_LEN + 4.0, k * k))
		if _t >= SLAM_FALL:
			_slam_hit()
			_set_state("slam_stuck")
		return
	super._process_slam()


# --- Rzut młotem ---

func _start_throw() -> void:
	var reach: float = Skills.DATA.m_throw.range * _area("m_throw")
	_throw_target = _nearest(reach)
	_throw_hits = []
	_back_hits = []
	_h_bounces = HT_BOUNCES_PERK if _perk("m_throw", 0) else HT_BOUNCES
	_extra_left = HT_EXTRA if gem_power("m_throw", "multi") > 0.0 else 0
	position = hero.position
	_sprite.position = Vector2(0, -ORBIT_HEIGHT)
	_dir = (_throw_target.global_position - hero.global_position).normalized() if _throw_target else hero.facing.normalized()
	if _dir == Vector2.ZERO:
		_dir = Vector2.RIGHT
	_goal = hero.global_position + _dir * reach
	hero.play_gesture(hero.global_position + _dir * 20.0)
	_set_state("m_throw")


func _process_throw_hammer(delta: float) -> void:
	_spin_angle += TAU * 3.0 * delta
	_sprite.rotation = _spin_angle
	_sprite.position = Vector2(0, -ORBIT_HEIGHT) - Vector2.from_angle(_spin_angle) * HAMMER_LEN * 0.6  # wiruje wokół obucha
	if _state == "m_throw":
		var to := (_throw_target.global_position if _throw_target and is_instance_valid(_throw_target) and _throw_target.alive() else _goal) - global_position
		var step := HT_SPEED * delta
		if to.length() <= step + 6.0:
			global_position += to
			if _throw_target and is_instance_valid(_throw_target) and _throw_target.alive():
				_throw_hit(_throw_target)
			else:
				_set_state("m_back")
		else:
			global_position += to.normalized() * step
		if _t >= HT_TIME_MAX:
			_set_state("m_back")
		return
	# powrót do postaci (kamień Powrotu - rani po drodze)
	var back := hero.global_position - global_position
	var step := HT_BACK_SPEED * delta
	if _unique("m_throw"):
		for t in _near(global_position, 14.0):
			if not _back_hits.has(t):
				_back_hits.append(t)
				_hit(t, _power("m_throw") * HT_RETURN_POWER, global_position, "m_throw")
	if back.length() <= step + 6.0 or _t >= HT_TIME_MAX:
		_end_skill()
		return
	global_position += back.normalized() * step


## Trafienie rzuconym młotem: rani, ogłusza, 10. - fala wstrząsu; potem odbicie w kolejnego albo powrót.
func _throw_hit(t: ProtoTarget) -> void:
	var extra := _h_bounces <= 0 and _extra_left > 0
	var power := _power("m_throw") * (gem_power("m_throw", "multi") / 100.0 if extra else 1.0)
	_hit(t, power, global_position, "m_throw")
	t.stun(HT_STUN)
	_throw_hits.append(t)
	var fx := Fx.once(get_parent(), IMPACT_FX, IMPACT_FRAMES, 16.0, t.center().round(), IMPACT_ANCHOR, 21)
	fx.modulate = EARTH_TINT
	if _perk("m_throw", 1):
		for o in _near(t.global_position, HT_SHOCK * _area("m_throw")):
			if o != t:
				_hit(o, power * SMASH_WAVE_POWER, t.global_position, "m_throw")
		_tremor(t.global_position, HT_SHOCK * _area("m_throw"))
	Input.vibrate_handheld(12)
	if extra:
		_extra_left -= 1
	else:
		_h_bounces -= 1
	if _h_bounces + _extra_left <= 0:
		_set_state("m_back")
		return
	var next: ProtoTarget = null
	var best_d := HT_BOUNCE_RANGE * _area("m_throw")
	for o in _near(t.global_position, best_d):
		var d := o.global_position.distance_to(t.global_position)
		if not _throw_hits.has(o) and d <= best_d:
			best_d = d
			next = o
	if next == null:
		_set_state("m_back")
		return
	_throw_target = next
	_t = 0.0


## Ile odbić zostało (testy).
func throw_bounces_left() -> int:
	return _h_bounces + _extra_left


# --- Skok z uderzeniem ---

func _start_leap() -> void:
	var reach: float = Skills.DATA.m_leap.range * _area("m_leap")
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	var dest: Vector2
	if stick.length() > 0.2:
		dest = hero.global_position + stick.normalized() * reach
	else:
		var best := _nearest(reach)
		if best:
			dest = best.global_position
		else:
			dest = hero.global_position + (hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT) * reach * 0.6
	hero.leap(dest, LEAP_TIME, LEAP_HOP)
	hero.protect(LEAP_TIME + 0.05)
	_set_state("m_leap")


func _process_leap() -> void:
	var k := clampf(_t / LEAP_TIME, 0.0, 1.0)
	position = hero.position + Vector2(0, -1.0)
	# młot uniesiony nad głową (obuch w górę), pod koniec obraca się obuchem w dół i spada z postacią
	var a := lerp_angle(-PI / 2.0, PI / 2.0, ease(clampf((k - 0.55) / 0.45, 0.0, 1.0), 2.0))
	_sprite.rotation = a
	_sprite.position = Vector2(0, -ORBIT_HEIGHT - 20.0) if k < 0.55 else Vector2(0, lerpf(-ORBIT_HEIGHT - HAMMER_LEN - 10.0, -HAMMER_LEN + 4.0, (k - 0.55) / 0.45))
	if _t >= LEAP_TIME and not hero.leaping():
		_leap_land(hero.global_position)
		_end_skill()


func _leap_radius() -> float:
	return LEAP_RADIUS * _area("m_leap") * (LEAP_PERK_AREA if _perk("m_leap", 0) else 1.0)


## Lądowanie: krater rani, ogłusza i odpycha; Mnożenie - drugi, szerszy wstrząs; 10. - pierścień kolców;
## Grzęzawisko - krater zostaje.
func _leap_land(at: Vector2, echo := false) -> void:
	var radius := _leap_radius() * (LEAP_ECHO_RADIUS if echo else 1.0)
	var power := _power("m_leap") * (gem_power("m_leap", "multi") / 100.0 if echo else 1.0)
	for t in _ring_hits(at, radius, power, "m_leap"):
		t.push_away(at, LEAP_PUSH)
		if not echo:
			t.stun(LEAP_STUN)
	_dust(at, radius)
	_tremor(at, radius)
	if echo:
		return
	if gem_power("m_leap", "multi") > 0.0:
		get_tree().create_timer(LEAP_ECHO, false).timeout.connect(_leap_land.bind(at, true))
	if _perk("m_leap", 1):
		_spike_wave(at, radius)
	if _unique("m_leap"):
		_spawn_pit(at, radius)
	Input.vibrate_handheld(45)
	_shake(3.0)


## Fala kolców z krateru (10. poziom skoku): szczeliny rosną od brzegu krateru na zewnątrz, kolce wyskakują po kolei.
## `turn` - obrót gwiazdy szczelin (domyślnie losowy; testy podają stały).
func _spike_wave(at: Vector2, radius: float, turn := -1.0) -> void:
	var hit := {}  # każdy wróg raz na całą falę
	var length := LEAP_CRACK_LENGTH * _area("m_leap")
	var power := _power("m_leap") * LEAP_SPIKE_POWER
	if turn < 0.0:
		turn = randf() * TAU
	for c in LEAP_CRACKS:
		var dir := Vector2.from_angle(turn + TAU * c / LEAP_CRACKS)
		var flat := Vector2(dir.x, dir.y * 0.62)  # jak cienie - spłaszczone w pionie
		var start := at + flat * radius * 0.7
		var side := flat.orthogonal().normalized()
		var crack := Line2D.new()
		crack.width = 2.0
		crack.default_color = Color(0.12, 0.08, 0.05, 0.85)
		crack.z_index = -1
		var points := PackedVector2Array()
		var steps := 6
		for i in steps + 1:
			points.append(start + flat * length * i / steps + side * (0.0 if i == 0 else randf_range(-4.0, 4.0)))
		crack.add_point(points[0])
		get_parent().add_child(crack)
		var grow := crack.create_tween()
		grow.tween_method(func(k: float) -> void:
			var n := clampi(ceili(k * steps), 1, steps)
			while crack.get_point_count() < n + 1:
				crack.add_point(points[crack.get_point_count()]), 0.0, 1.0, LEAP_CRACK_TIME)
		grow.tween_interval(0.8)
		grow.tween_property(crack, "modulate:a", 0.0, 0.4)
		grow.tween_callback(crack.queue_free)
		for i in LEAP_CRACK_SPIKES:
			var k := (i + 1.0) / LEAP_CRACK_SPIKES
			var spot := start + flat * length * k + side * randf_range(-3.0, 3.0)
			get_tree().create_timer(LEAP_CRACK_TIME * k, false).timeout.connect(_wave_spike.bind(spot, power, hit))


## Kolec fali: efekt kolca Rozłupania i trafienie wrogów obok, którzy jeszcze nie oberwali od tej fali.
func _wave_spike(spot: Vector2, power: float, hit: Dictionary) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	Fx.once(get_parent(), SLAM_SPIKE_FX, SLAM_SPIKE_FRAMES, 16.0, spot.round(), SLAM_SPIKE_ANCHOR, 2, 0.7)
	var r := SPIKE_RADIUS * _area("m_leap")
	for t in _near(spot, r):
		var d := t.global_position - spot
		if hit.has(t) or Vector2(d.x, d.y * 1.6).length() > r:
			continue
		hit[t] = true
		_hit(t, power, spot, "m_leap")
		t.stun(0.3)


## Kamień Grzęzawiska: krater z pękniętej ziemi (ciemne, spłaszczone koło z bursztynowym brzegiem).
func _spawn_pit(at: Vector2, radius: float) -> void:
	var node := _Pit.new()
	node.radius = radius
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = at
	_pits.append({"node": node, "at": at, "radius": radius, "left": LEAP_PIT_TIME, "tick": 0.0})


func _process_pits(delta: float) -> void:
	for p in _pits.duplicate():
		p.left -= delta
		p.tick -= delta
		var node: Node2D = p.node
		node.modulate.a = clampf(p.left / 0.5, 0.0, 1.0)
		if p.tick <= 0.0:
			p.tick = LEAP_PIT_TICK
			for t in _ring_hits(p.at, p.radius, _power("m_leap") * LEAP_PIT_POWER, "m_leap"):
				t.slow(LEAP_PIT_SLOW, LEAP_PIT_TICK + 0.2)
		if p.left <= 0.0:
			node.queue_free()
			_pits.erase(p)


## Ile kraterów leży na ziemi (testy).
func pits() -> int:
	return _pits.size()


# --- Trzęsienie ziemi (trzymane) ---

func _quake_every() -> float:
	return QUAKE_EVERY_PERK if _perk("m_quake", 0) else QUAKE_EVERY


## Mana jednej fali (koszt umiejętności jest na sekundę).
func _quake_tick_cost() -> int:
	return maxi(1, ceili(mana_cost("m_quake") * _quake_every()))


func _process_quake(delta: float) -> void:
	position = hero.position + Vector2(0, -1.0)
	_quake_t -= delta
	# młot obuchem w dół nad postacią; z każdą falą uderza o ziemię
	var bob := clampf(-_quake_t / _quake_every(), 0.0, 1.0)
	_sprite.rotation = PI / 2.0
	_sprite.position = Vector2(0, lerpf(-HAMMER_LEN + 2.0, -HAMMER_LEN - 18.0, ease(bob, 0.4)))
	if _quake_t <= 0.0:
		_quake_t = _quake_every()
		if not hero.spend_mana(_quake_tick_cost()):
			cast_failed.emit("m_quake", "mana")
			_end_skill()
			return
		_quake_wave()
	if not charge_held or hero.dead:
		_end_skill()


## Fala trzęsienia: rani i odpycha wokół postaci; Mnożenie - drugie uderzenie; 10. - co trzecia ogłusza;
## Uskok - szczelina z kolcami w najbliższego wroga.
func _quake_wave() -> void:
	quake_waves += 1
	var at := hero.global_position
	var radius := QUAKE_RADIUS * _area("m_quake")
	var power := _power("m_quake")
	var extra := gem_power("m_quake", "multi") / 100.0
	var stun := _perk("m_quake", 1) and quake_waves % 3 == 0
	for t in _ring_hits(at, radius, power, "m_quake"):
		if extra > 0.0 and t.alive():
			_hit(t, power * extra, at, "m_quake")
		t.push_away(at, QUAKE_PUSH)
		if stun:
			t.stun(QUAKE_STUN)
	_tremor(at, radius)
	if _unique("m_quake"):
		var best := _nearest(QUAKE_CRACK * _area("m_quake") + radius)
		var dir := (best.global_position - at).normalized() if best else Vector2.from_angle(randf() * TAU)
		for i in 4:
			var spot := at + dir * (radius * 0.4 + QUAKE_CRACK * _area("m_quake") * (i + 1) / 4.0)
			get_tree().create_timer(0.05 * (i + 1), false).timeout.connect(_spike.bind(spot, power * QUAKE_CRACK_POWER, "m_quake"))
	Input.vibrate_handheld(20)
	_shake(2.0)


## Krater Grzęzawiska: ciemne, spłaszczone koło pękniętej ziemi z bursztynowym brzegiem.
class _Pit extends Node2D:
	var radius := 40.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, radius, Color(0.16, 0.1, 0.06, 0.55))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.95, 0.6, 0.25, 0.7), 1.5)
		for i in 6:
			var a := TAU * i / 6.0 + 0.3
			draw_line(Vector2.from_angle(a) * radius * 0.2, Vector2.from_angle(a + 0.2) * radius * 0.85, Color(0.05, 0.03, 0.02, 0.7), 1.0)

class_name ProtoHydrosphere
extends ProtoWeapon
## Hydrosfera (ustalone z autorem 14.11.2026) - trzecia broń, żywioł woda (Elements.WATER), walka na dystans.
## Kula wody lewituje obok postaci (dziedziczy po ProtoWeapon: mana, odnowienia, kamienie, krytyki, kolejka umiejętności),
## przy zwykłym ciosie podlatuje odrobinę ku celowi i wypluwa pocisk. Każde trafienie PRZEMACZA (`_hit`): wróg wolniejszy
## o SOAK_SLOW na SOAK_TIME (ProtoTarget.slow; combo z Gromem i lodem - później).
## - „Wodny pocisk” (`h_bolt`, zwykły cios): bańka leci w najbliższego wroga do 140 px, rozprysk rani pobliskich
##   (5. poziom - większy i silniejszy rozprysk, 10. - co trzeci strzał to trzy bańki w wachlarzu);
## - „Fala” (`h_wave`): sierp wody toczy się ok. 110 px przed postacią, rani i odpycha (5. - o połowę dalej, 10. - druga fala);
## - „Wir” (`h_vortex`): wir w miejscu wroga przez 3 s wciąga wrogów do środka i co chwilę rani (5. - 4 s, 10. - na koniec
##   wybucha falą wody);
## - „Gejzery” (`h_geyser`): pod 5 najbliższymi wrogami po chwili tryska gejzer - rani i ogłusza 1 s (5. - 1,5 s, 10. - 8);
## - „Ulewa” (`h_rain`): przez 4 s co chwilę sopel spada na losowego wroga wokół postaci (5. - 6 s, 10. - dwa razy częściej).
## Grafika: kula assets/weapons/hydrosphere.png (24 px w skali 0,5; narysowana w narzędziu pikseli PixelLab), efekty z kreatora
## (assets/effects/hydro_*.png, pixellab_src/vfx/ids.json).

const ORB_TEXTURE := preload("res://assets/weapons/hydrosphere.png")
## Przemoczenie: spowolnienie i jego czas.
const SOAK_SLOW := 0.2
const SOAK_TIME := 3.0
## Wodny pocisk: zasięg, prędkość, promień trafienia, rozprysk (promień, siła; 5. poziom - mnożnik obu), wachlarz z 10.,
## czasy (podlot kuli, wystrzał, przerwa).
const BOLT_RANGE := 140.0
const BOLT_SPEED := 230.0
const BOLT_RADIUS := 9.0
const SPLASH_RADIUS := 20.0
const SPLASH_POWER := 0.5
const SPLASH_PERK := 1.5
const BOLT_FAN := deg_to_rad(18.0)
const ORB_WINDUP := 0.16
const ORB_SHOT := 0.12
const ORB_COOLDOWN := 0.5
## Fala: zasięg (5. poziom - x1,5), prędkość, promień trafienia, siła odepchnięcia, opóźnienie drugiej fali z 10.
const WAVE_DISTANCE := 110.0
const WAVE_SPEED := 160.0
const WAVE_RADIUS := 24.0
const WAVE_PUSH := 140.0
const WAVE_SECOND := 0.3
## Wir: czas (5. poziom - dłużej), promień, co ile rani, siła wciągania, wybuch z 10. (promień, siła).
const VORTEX_TIME := 3.0
const VORTEX_TIME_LONG := 4.0
const VORTEX_RADIUS := 42.0
const VORTEX_TICK := 0.4
const VORTEX_PULL := 70.0
const VORTEX_BLAST_RADIUS := 55.0
const VORTEX_BLAST_POWER := 2.0
## Gejzery: liczba (10. poziom - więcej), opóźnienie wybuchu, promień, ogłuszenie (5. poziom - dłużej).
const GEYSERS := 5
const GEYSERS_PERK := 8
const GEYSER_DELAY := 0.35
const GEYSER_RADIUS := 22.0
const GEYSER_STUN := 1.0
const GEYSER_STUN_LONG := 1.5
## Ulewa: czas (5. poziom - dłużej), co ile sopel (10. poziom - dwa razy częściej), zasięg szukania wrogów, wysokość
## i czas spadania, promień trafienia.
const RAIN_TIME := 4.0
const RAIN_TIME_LONG := 6.0
const RAIN_EVERY := 0.25
const RAIN_RANGE := 130.0
const RAIN_HEIGHT := 90.0
const RAIN_FALL := 0.3
const RAIN_RADIUS := 14.0
## Efekty (klatki, fps, zaczepienie).
const BOLT_FX := preload("res://assets/effects/hydro_bolt.png")
const BOLT_FX_ANCHOR := Vector2(22, 8)
const SPLASH_FX := preload("res://assets/effects/hydro_splash.png")
const SPLASH_FX_ANCHOR := Vector2(21, 18)
const TIDE_FX := preload("res://assets/effects/hydro_wave.png")
const TIDE_FX_ANCHOR := Vector2(17, 32)
const TIDE_FX_FRAMES := 12
const VORTEX_FX := preload("res://assets/effects/hydro_vortex.png")
const VORTEX_FX_ANCHOR := Vector2(48, 34)
const VORTEX_FX_FRAMES := 12
## Promień wiru w efekcie (spirale wody na ziemi, piana na brzegu) - skalowany do VORTEX_RADIUS.
const VORTEX_FX_RADIUS := 34.0
const GEYSER_FX := preload("res://assets/effects/hydro_geyser.png")
const GEYSER_FX_ANCHOR := Vector2(49, 39)
const DROP_FX := preload("res://assets/effects/hydro_drop.png")
const DROP_FX_ANCHOR := Vector2(29, 6)

## Pociski i fale w locie: {"fx", "dir", "left", "speed", "radius", "hits", "skill", "kind" ("bolt"/"wave"), "target"}.
var _shots: Array = []
## Wiry: {"node", "at", "left", "tick", "radius"}.
var _vortexes: Array = []
## Sople Ulewy: {"fx", "at", "t"}.
var _drops: Array = []
var _rain_left := 0.0
var _rain_acc := 0.0
var _shot_target: ProtoTarget


func _init() -> void:
	basic = "h_bolt"
	main_skill = "h_bolt"


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = ORB_TEXTURE
		s.offset = -Vector2(12, 12)  # kula 24 px w skali 0,5 jak miecz i glewia (SCALE)


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"orb_windup", "orb_shot":
			_process_orb()
	_process_shots(delta)
	_process_vortexes(delta)
	_process_rain(delta)
	_process_drops(delta)


## Kula nie obraca się - unosi się i lekko faluje obok postaci.
func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	_sprite.position = _sprite.position.lerp(Vector2(0, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0)), k)
	_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, k)


## Trafienie wodą: obrażenia jak każdej broni (`_deal`) i przemoczenie.
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)
	if t.alive():
		t.slow(SOAK_SLOW, SOAK_TIME)


func _splash_fx(at: Vector2, size := 1.0) -> void:
	Fx.once(get_parent(), SPLASH_FX, 10, 14.0, at.round(), SPLASH_FX_ANCHOR, 21, size)


# --- Zwykły cios: wodny pocisk ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_shot_target = _nearest(BOLT_RANGE * _area(basic))
	_aim = (_shot_target.center() - _orbit_center()).angle() if _shot_target else hero.facing.angle()
	_from_pos = position
	_from_sprite = _sprite.position
	_hit_done = false
	_set_state("orb_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Kula podlatuje ku celowi (przed postać), wypluwa pocisk i wraca na swoje miejsce.
func _process_orb() -> void:
	var front := hero.position + Vector2.from_angle(_aim) * 14.0
	match _state:
		"orb_windup":
			var k := ease(clampf(_t / ORB_WINDUP, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(front, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -ORBIT_HEIGHT - 6.0), k)
			if _t >= ORB_WINDUP:
				_fire_bolts()
				_set_state("orb_shot")
		"orb_shot":
			if _t >= ORB_SHOT:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: drugi pocisk
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = ORB_COOLDOWN


## Wystrzał: jedna bańka (10. poziom - co trzeci strzał trzy w wachlarzu).
func _fire_bolts() -> void:
	var angles := [_aim]
	if _perk(basic, 1) and _strike_count % 3 == 0:
		angles = [_aim - BOLT_FAN, _aim, _aim + BOLT_FAN]
	for a in angles:
		var fx := _shot_sprite(BOLT_FX, 8, BOLT_FX_ANCHOR, a)
		_shots.append({"fx": fx, "dir": Vector2.from_angle(a), "left": BOLT_RANGE * _area(basic) + 20.0,
				"speed": BOLT_SPEED, "radius": BOLT_RADIUS, "hits": [], "skill": basic, "kind": "bolt",
				"target": _shot_target if a == _aim else null, "power": _swing_power})


func _shot_sprite(texture: Texture2D, frames: int, anchor: Vector2, a: float) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = 20
	fx.rotation = a
	get_parent().add_child(fx)
	fx.global_position = _sprite.global_position if _sprite else _orbit_center()
	return fx


## Pociski i fale: lecą, pocisk lekko skręca ku celowi i pęka na pierwszym trafionym (rozprysk), fala przebija i odpycha.
func _process_shots(delta: float) -> void:
	for i in range(_shots.size() - 1, -1, -1):
		var s: Dictionary = _shots[i]
		var fx: Sprite2D = s.fx
		var tgt = s.get("target")
		if s.kind == "bolt" and tgt != null and is_instance_valid(tgt) and tgt.alive():
			var want: Vector2 = (tgt.center() - fx.global_position).normalized()
			s.dir = s.dir.slerp(want, minf(1.0, 8.0 * delta)).normalized()
			fx.rotation = s.dir.angle()
		var step: float = s.speed * delta
		fx.global_position += s.dir * step
		s.left -= step
		if s.kind == "bolt":
			fx.frame = int(_clock * 12.0 + i) % 8
		else:
			fx.frame = int(_clock * 12.0 + i) % TIDE_FX_FRAMES
			fx.modulate.a = clampf(s.left / 30.0, 0.0, 1.0)
		var reach: float = s.radius * _area(s.skill)
		var popped := false
		for t in _live_targets():
			if s.hits.has(t) or t.center().distance_to(fx.global_position) > reach:
				continue
			s.hits.append(t)
			if s.kind == "bolt":
				_hit(t, _power(basic) * s.power, fx.global_position - s.dir * 10.0, basic)
				_bolt_splash(fx.global_position, t)
				popped = true
				break
			_hit(t, _power(s.skill), fx.global_position - s.dir * 20.0, s.skill)
			t.push_away(fx.global_position - s.dir * 20.0, WAVE_PUSH)
		if popped or s.left <= 0.0:
			if s.kind == "bolt" and not popped:
				_splash_fx(fx.global_position, 0.6)
			fx.queue_free()
			_shots.remove_at(i)


## Rozprysk bańki: rani i przemacza pobliskich (bez trafionego), 5. poziom - większy i silniejszy.
func _bolt_splash(at: Vector2, hit: ProtoTarget) -> void:
	var k := SPLASH_PERK if _perk(basic, 0) else 1.0
	for t in _live_targets():
		if t != hit and t.center().distance_to(at) <= SPLASH_RADIUS * k * _area(basic):
			_hit(t, _power(basic) * SPLASH_POWER * k, at, basic)
	_splash_fx(at, 0.7 * k)
	Input.vibrate_handheld(10)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["h_wave", "h_vortex", "h_geyser", "h_rain"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	var best := _nearest(Skills.DATA[id].range)
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"h_wave":
			_spawn_tide()
			if _perk(id, 1):
				get_tree().create_timer(WAVE_SECOND, false).timeout.connect(_spawn_tide)
		"h_vortex":
			var at: Vector2 = best.global_position if best else hero.global_position + hero.facing.normalized() * 60.0
			_add_vortex(at)
		"h_geyser":
			_geysers()
		"h_rain":
			_rain_left = RAIN_TIME_LONG if _perk(id, 0) else RAIN_TIME
			_rain_acc = 0.0
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Fala: sierp wody toczy się od postaci w stronę celu (kierunek z chwili rzutu - druga fala celuje od nowa).
func _spawn_tide() -> void:
	if hero.dead:
		return
	var best := _nearest(Skills.DATA.h_wave.range)
	var a := (best.center() - _orbit_center()).angle() if best else _aim
	var fx := _shot_sprite(TIDE_FX, TIDE_FX_FRAMES, TIDE_FX_ANCHOR, a)
	fx.global_position = _orbit_center()
	fx.scale = Vector2.ONE * _area("h_wave")
	var dist := WAVE_DISTANCE * _area("h_wave") * (1.5 if _perk("h_wave", 0) else 1.0)
	_shots.append({"fx": fx, "dir": Vector2.from_angle(a), "left": dist, "speed": WAVE_SPEED, "radius": WAVE_RADIUS,
			"hits": [], "skill": "h_wave", "kind": "wave"})


## Wir w punkcie `at` (stopy wroga): zapętlony wir wody na ziemi (spirale wciągające do środka, piana na brzegu).
func _add_vortex(at: Vector2) -> void:
	var r := VORTEX_RADIUS * _area("h_vortex")
	var node := Sprite2D.new()
	node.texture = VORTEX_FX
	node.hframes = VORTEX_FX_FRAMES
	node.centered = false
	node.offset = -VORTEX_FX_ANCHOR
	node.scale = Vector2.ONE * r / VORTEX_FX_RADIUS
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = at.round()
	_vortexes.append({"node": node, "at": at, "radius": r, "tick": VORTEX_TICK,
			"left": VORTEX_TIME_LONG if _perk("h_vortex", 0) else VORTEX_TIME})


func _process_vortexes(delta: float) -> void:
	for i in range(_vortexes.size() - 1, -1, -1):
		var v: Dictionary = _vortexes[i]
		v.left -= delta
		v.tick -= delta
		var node: Sprite2D = v.node
		node.frame = int(_clock * 12.0) % VORTEX_FX_FRAMES
		node.modulate.a = clampf(v.left / 0.4, 0.0, 1.0)
		for t in _live_targets():
			var d: Vector2 = t.global_position - v.at
			if Vector2(d.x, d.y * 1.6).length() > v.radius:
				continue
			if d.length() > 4.0:  # wciąganie: odpychanie od punktu po drugiej stronie celu
				t.push_away(t.global_position + d.normalized() * 10.0, VORTEX_PULL)
			if v.tick <= 0.0:
				_hit(t, _power("h_vortex"), v.at, "h_vortex")
		if v.tick <= 0.0:
			v.tick += VORTEX_TICK
		if v.left <= 0.0:
			if _perk("h_vortex", 1):
				_water_blast(v.at, VORTEX_BLAST_RADIUS * _area("h_vortex"), _power("h_vortex") * VORTEX_BLAST_POWER)
			node.queue_free()
			_vortexes.remove_at(i)


## Wybuch wody (koniec wiru z 10. poziomem): rani, przemacza i odpycha w promieniu.
func _water_blast(at: Vector2, radius: float, power: float) -> void:
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, "h_vortex")
			t.push_away(at, WAVE_PUSH)
	Fx.once(get_parent(), GEYSER_FX, 12, 14.0, at.round(), GEYSER_FX_ANCHOR, 6, radius / 45.0)
	Input.vibrate_handheld(30)


## Gejzery pod najbliższymi wrogami: po GEYSER_DELAY tryskają - rani, przemacza i ogłusza w promieniu.
func _geysers() -> void:
	var near: Array = []
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d <= Skills.DATA.h_geyser.range * _area("h_geyser"):
			near.append([d, t])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var n := GEYSERS_PERK if _perk("h_geyser", 1) else GEYSERS
	var targets_hit: Array = []
	for pair in near.slice(0, n):
		targets_hit.append(pair[1])
	if targets_hit.is_empty():
		var at := hero.global_position + hero.facing.normalized() * 40.0
		_splash_fx(at, 0.4)
		get_tree().create_timer(GEYSER_DELAY, false).timeout.connect(_geyser_burst.bind(at, null))
	for t in targets_hit:
		_splash_fx(t.global_position, 0.4)  # zapowiedź: bulgocze ziemia
		get_tree().create_timer(GEYSER_DELAY, false).timeout.connect(_geyser_burst.bind(t.global_position, t))


## Wybuch gejzera - pod wrogiem `target` tam, gdzie akurat stoi (zdążył się ruszyć), albo w punkcie `at`.
func _geyser_burst(at: Vector2, target: ProtoTarget) -> void:
	if not is_inside_tree():
		return
	if target != null and is_instance_valid(target) and target.alive():
		at = target.global_position
	var radius := GEYSER_RADIUS * _area("h_geyser")
	var stun_time := GEYSER_STUN_LONG if _perk("h_geyser", 0) else GEYSER_STUN
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, _power("h_geyser"), at, "h_geyser")
			t.stun(stun_time)
	Fx.once(get_parent(), GEYSER_FX, 12, 14.0, at.round(), GEYSER_FX_ANCHOR, 6, 0.8)
	Input.vibrate_handheld(20)


## Ulewa: co RAIN_EVERY (10. poziom - dwa razy częściej) sopel spada na losowego wroga wokół postaci
## (bez wrogów - w losowe miejsce obok).
func _process_rain(delta: float) -> void:
	if _rain_left <= 0.0:
		return
	if hero.dead:
		_rain_left = 0.0
		return
	_rain_left -= delta
	_rain_acc += delta
	var every := RAIN_EVERY * (0.5 if _perk("h_rain", 1) else 1.0)
	while _rain_acc >= every:
		_rain_acc -= every
		var near: Array = []
		for t in _live_targets():
			if hero.global_position.distance_to(t.global_position) <= RAIN_RANGE * _area("h_rain"):
				near.append(t)
		var at: Vector2 = near.pick_random().global_position if not near.is_empty() \
				else hero.global_position + Vector2.from_angle(randf() * TAU) * randf_range(20.0, RAIN_RANGE * 0.6)
		var fx := _shot_sprite(DROP_FX, 8, DROP_FX_ANCHOR, PI / 2.0)  # sopel ostrzem w dół
		fx.global_position = at + Vector2(0, -RAIN_HEIGHT)
		_drops.append({"fx": fx, "at": at, "t": 0.0})


func _process_drops(delta: float) -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var d: Dictionary = _drops[i]
		d.t += delta
		var fx: Sprite2D = d.fx
		var k := clampf(d.t / RAIN_FALL, 0.0, 1.0)
		fx.global_position = (d.at as Vector2) + Vector2(0, -RAIN_HEIGHT * (1.0 - k * k))
		fx.frame = int(_clock * 12.0 + i) % 8
		if k >= 1.0:
			var radius := RAIN_RADIUS * _area("h_rain")
			for t in _live_targets():
				var off: Vector2 = t.global_position - d.at
				if Vector2(off.x, off.y * 1.6).length() <= radius:
					_hit(t, _power("h_rain"), d.at, "h_rain")
			_splash_fx(d.at, 0.6)
			fx.queue_free()
			_drops.remove_at(i)


func _end_skill() -> void:
	super._end_skill()
	_cooldown = maxf(_cooldown, ORB_COOLDOWN * 0.5)

class_name ProtoHydrosphere
extends ProtoWeapon
## Hydrosfera (ustalone z autorem 14.11.2026) - trzecia broń, żywioł woda (Elements.WATER), walka na dystans.
## Kula wody lewituje obok postaci (dziedziczy po ProtoWeapon: mana, odnowienia, kamienie, krytyki, kolejka umiejętności),
## przy zwykłym ciosie podlatuje odrobinę ku celowi i wypluwa pocisk. Każde trafienie PRZEMACZA (`_hit`): wróg wolniejszy
## o SOAK_SLOW na SOAK_TIME, kapią z niego krople (ProtoTarget.soak; combo z Gromem i lodem - Elements.soak_bonus).
## - „Wodny pocisk” (`h_bolt`, zwykły cios): bańka leci w najbliższego wroga do 140 px, rozprysk rani pobliskich
##   (5. poziom - większy i silniejszy rozprysk, 10. - co trzeci strzał to trzy bańki w wachlarzu);
## - „Fala” (`h_wave`): sierp wody toczy się ok. 110 px przed postacią, rani i odpycha (5. - o połowę dalej, 10. - druga fala);
## - „Wir” (`h_vortex`): wir w miejscu wroga przez 3 s wciąga wrogów do środka i co chwilę rani (5. - 4 s, 10. - na koniec
##   wybucha falą wody);
## - „Gejzery” (`h_geyser`): pod 5 najbliższymi wrogami po chwili tryska gejzer - rani i ogłusza 1 s (5. - 1,5 s, 10. - 8);
## - „Wodny Strażnik” (`h_guardian`, zamiast Ulewy - pomysł autora 14.11.2026): kula wody pojawia się z wybuchem przy
##   wrogu (albo przed postacią), zostaje GUARD_TIME i co GUARD_EVERY strzela pociskiem w najbliższego wroga (5. - dłużej,
##   10. - dwie kule).
## Kamienie unikalne (pomysły autora 14.11.2026, `_unique`): pocisk - zamiast lotu bańka krąży wokół postaci i przebija
## (`_orbits`); Fala - fale dookoła postaci; Wir - wędruje ku wrogom; Gejzery - każdy wypluwa 3 kule wody spadające dookoła
## (`_lobs`); Strażnik - powtarza Falę, Wir i Gejzery gracza ze swojego miejsca, za darmo, siłą ECHO_POWER.
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
## Wodny Strażnik: czas (5. poziom - dłużej), co ile strzela, zasięg, wybuch przy pojawieniu (promień, siła), unoszenie,
## odległość od celu przy pojawieniu, rozstaw dwóch kul z 10.
const GUARD_TIME := 6.0
const GUARD_TIME_LONG := 8.0
const GUARD_EVERY := 0.5
const GUARD_RANGE := 120.0
const GUARD_BLAST_RADIUS := 34.0
const GUARD_BLAST_POWER := 1.2
const GUARD_HOVER := 16.0
const GUARD_SPREAD := 26.0
## Kamienie unikalne: krążące bańki (promień, obroty na sekundę, czas, najwięcej naraz, co ile ten sam wróg), fale dookoła
## (liczba, siła), wędrujący wir (prędkość, dłużej o), kule z gejzerów (liczba, odległość, czas lotu, wysokość, promień,
## siła), echo Strażnika (siła).
const ORBIT_RADIUS := 40.0
const ORBIT_TURNS := 0.9
const ORBIT_TIME := 3.0
const ORBIT_MAX := 4
const ORBIT_REHIT := 0.5
const RING_WAVES := 6
const RING_POWER := 0.6
const VORTEX_WANDER := 32.0
const VORTEX_WANDER_BONUS := 1.0
const LOB_COUNT := 3
const LOB_DISTANCE := 40.0
const LOB_TIME := 0.5
const LOB_HEIGHT := 30.0
const LOB_RADIUS := 18.0
const LOB_POWER := 0.6
const ECHO_POWER := 0.5
## Efekty (klatki, fps, zaczepienie).
const BOLT_FX := preload("res://assets/effects/hydro_bolt.png")
const BOLT_FX_ANCHOR := Vector2(22, 8)
const SPLASH_FX := preload("res://assets/effects/hydro_splash.png")
const SPLASH_FX_ANCHOR := Vector2(21, 18)
## Rozbryzg w kierunku trafienia (narysowany w prawo - gra obraca go w stronę lotu pocisku, fali, od środka wybuchu).
const SPRAY_FX := preload("res://assets/effects/hydro_spray.png")
const SPRAY_FX_ANCHOR := Vector2(10, 13)
const TIDE_FX := preload("res://assets/effects/hydro_wave.png")
const TIDE_FX_ANCHOR := Vector2(17, 32)
const TIDE_FX_FRAMES := 12
const VORTEX_FX := preload("res://assets/effects/hydro_vortex.png")
const VORTEX_FX_ANCHOR := Vector2(48, 34)
const VORTEX_FX_FRAMES := 12
## Promień wiru w efekcie (spirale wody na ziemi, piana na brzegu) - skalowany do VORTEX_RADIUS.
const VORTEX_FX_RADIUS := 34.0
## Krążąca bańka z wygiętym ogonem (kamień unikalny pocisku): zaczepienie w środku orbity, bańka ORBIT_FX_RADIUS w prawo.
const ORBIT_FX := preload("res://assets/effects/hydro_orbit.png")
const ORBIT_FX_ANCHOR := Vector2(52, 52)
const ORBIT_FX_RADIUS := 40.0
const GEYSER_FX := preload("res://assets/effects/hydro_geyser.png")
const GEYSER_FX_ANCHOR := Vector2(49, 39)

## Pociski i fale w locie: {"fx", "dir", "left", "speed", "radius", "hits", "skill", "kind" ("bolt"/"wave"), "target",
## "power" (mnożnik siły), "splash" (rozprysk bańki gracza)}.
var _shots: Array = []
## Wiry: {"node", "at", "left", "tick", "radius", "mult", "wander"}.
var _vortexes: Array = []
## Wodni Strażnicy: {"node", "at", "left", "acc"}.
var _guardians: Array = []
## Bańki krążące wokół postaci (kamień unikalny pocisku): {"fx", "angle", "left", "hits" (wróg -> czas do kolejnego)}.
var _orbits: Array = []
## Kule wody z gejzerów (kamień unikalny): {"fx", "from", "to", "t", "mult"}.
var _lobs: Array = []
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
	_process_guardians(delta)
	_process_orbits(delta)
	_process_lobs(delta)


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
		t.soak(SOAK_SLOW, SOAK_TIME)


## Pionowe pluśnięcie (gejzery, kule z gejzerów, znikający Strażnik, pocisk, który nikogo nie trafił).
func _splash_fx(at: Vector2, size := 1.0) -> void:
	Fx.once(get_parent(), SPLASH_FX, 10, 14.0, at.round(), SPLASH_FX_ANCHOR, 21, size)


## Rozbryzg w kierunku `dir` (pocisk, rozprysk, fala, wybuch wiru): krople i strugi tryskają dalej, w stronę uderzenia.
func _spray_fx(at: Vector2, dir: Vector2, size := 1.0) -> void:
	var fx := Fx.once(get_parent(), SPRAY_FX, 9, 16.0, at.round(), SPRAY_FX_ANCHOR, 21, size)
	fx.rotation = dir.angle()


# --- Zwykły cios: wodny pocisk ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_shot_target = _farthest(BOLT_RANGE * _area(basic))  # bańka leci przez tłum do najdalszego (19.11.2026)
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


## Wystrzał: jedna bańka (10. poziom - co trzeci strzał trzy w wachlarzu); z kamieniem unikalnym bańki krążą wokół
## postaci (`_orbits`).
func _fire_bolts() -> void:
	var angles := [_aim]
	if _perk(basic, 1) and _strike_count % 3 == 0:
		angles = [_aim - BOLT_FAN, _aim, _aim + BOLT_FAN]
	for a in angles:
		if _unique(basic):
			_add_orbit(a)
			continue
		_spawn_bolt(_sprite.global_position, a, _shot_target if a == _aim else null, basic, _swing_power, true)


## Bańka w locie z punktu `from` pod kątem `a` (lekko naprowadzana na `target`), siła umiejętności `skill` razy `mult`;
## `splash` - rozprysk na sąsiadach (pocisk gracza).
func _spawn_bolt(from: Vector2, a: float, target: ProtoTarget, skill: String, mult := 1.0, splash := false) -> void:
	var fx := _shot_sprite(BOLT_FX, 8, BOLT_FX_ANCHOR, a)
	fx.global_position = from
	_shots.append({"fx": fx, "dir": Vector2.from_angle(a), "left": BOLT_RANGE * _area(skill) + 20.0,
			"speed": BOLT_SPEED, "radius": BOLT_RADIUS, "hits": [], "skill": skill, "kind": "bolt",
			"target": target, "power": mult, "splash": splash})


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
				_hit(t, _power(s.skill) * s.power, fx.global_position - s.dir * 10.0, s.skill)
				if s.splash:
					_bolt_splash(fx.global_position, t, s.dir)
				else:
					_spray_fx(fx.global_position, s.dir, 0.7)
				popped = true
				break
			_hit(t, _power(s.skill) * s.get("power", 1.0), fx.global_position - s.dir * 20.0, s.skill)
			t.push_away(fx.global_position - s.dir * 20.0, WAVE_PUSH)
			_spray_fx(t.center(), s.dir, 0.9)
		if popped or s.left <= 0.0:
			if s.kind == "bolt" and not popped:
				_splash_fx(fx.global_position, 0.6)
			fx.queue_free()
			_shots.remove_at(i)


## Rozprysk bańki: rani i przemacza pobliskich (bez trafionego), 5. poziom - większy i silniejszy; rozbryzg leci
## w kierunku lotu pocisku (`dir`).
func _bolt_splash(at: Vector2, hit: ProtoTarget, dir: Vector2) -> void:
	var k := SPLASH_PERK if _perk(basic, 0) else 1.0
	for t in _live_targets():
		if t != hit and t.center().distance_to(at) <= SPLASH_RADIUS * k * _area(basic):
			_hit(t, _power(basic) * SPLASH_POWER * k, at, basic)
			_spray_fx(t.center(), t.center() - at, 0.5)  # mały rozbryzg od trafionego na sąsiada
	_spray_fx(at, dir, 0.8 * k)
	Input.vibrate_handheld(10)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["h_wave", "h_vortex", "h_geyser", "h_guardian"]:
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
			_geysers(hero.global_position)
		"h_guardian":
			var at: Vector2 = best.global_position - Vector2.from_angle(_aim) * 10.0 if best \
					else hero.global_position + hero.facing.normalized() * 50.0
			if _perk(id, 1):  # 10. poziom: dwie kule po bokach
				var side := Vector2.from_angle(_aim).orthogonal() * GUARD_SPREAD
				_add_guardian(at + side)
				_add_guardian(at - side)
			else:
				_add_guardian(at)
	if id != "h_guardian" and _unique("h_guardian"):
		_echo(id)
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Fala: sierp wody toczy się od postaci (albo od `from` - echo Strażnika) w stronę najbliższego wroga (kierunek
## z chwili rzutu - druga fala celuje od nowa); z kamieniem unikalnym RING_WAVES fal dookoła (słabszych).
func _spawn_tide(from := Vector2.INF, mult := 1.0) -> void:
	if hero.dead:
		return
	var origin := _orbit_center() if from == Vector2.INF else from
	var best: ProtoTarget = null  # fala celuje w najdalszego wroga w zasięgu - płynie przez tłum (19.11.2026)
	var best_d := -1.0
	for t in _live_targets():
		var d := t.center().distance_to(origin)
		if d <= Skills.DATA.h_wave.range and d > best_d:
			best = t
			best_d = d
	var a := (best.center() - origin).angle() if best else _aim
	var angles := [a]
	if _unique("h_wave"):
		angles = []
		for i in RING_WAVES:
			angles.append(a + TAU * i / RING_WAVES)
		mult *= RING_POWER
	var dist := WAVE_DISTANCE * _area("h_wave") * (1.5 if _perk("h_wave", 0) else 1.0)
	for ang in angles:
		var fx := _shot_sprite(TIDE_FX, TIDE_FX_FRAMES, TIDE_FX_ANCHOR, ang)
		fx.global_position = origin
		fx.scale = Vector2.ONE * _area("h_wave")
		_shots.append({"fx": fx, "dir": Vector2.from_angle(ang), "left": dist, "speed": WAVE_SPEED, "radius": WAVE_RADIUS * _area("h_wave"),
				"hits": [], "skill": "h_wave", "kind": "wave", "power": mult})


## Wir w punkcie `at` (stopy wroga): zapętlony wir wody na ziemi (spirale wciągające do środka, piana na brzegu).
func _add_vortex(at: Vector2, mult := 1.0) -> void:
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
	var wander := _unique("h_vortex")
	_vortexes.append({"node": node, "at": at, "radius": r, "tick": VORTEX_TICK, "mult": mult, "wander": wander,
			"left": (VORTEX_TIME_LONG if _perk("h_vortex", 0) else VORTEX_TIME) + (VORTEX_WANDER_BONUS if wander else 0.0)})


func _process_vortexes(delta: float) -> void:
	for i in range(_vortexes.size() - 1, -1, -1):
		var v: Dictionary = _vortexes[i]
		v.left -= delta
		v.tick -= delta
		var node: Sprite2D = v.node
		if v.wander:  # kamień unikalny: wir płynie ku najbliższemu wrogowi
			var goal: ProtoTarget = null
			var gd := INF
			for t in _live_targets():
				var dd: float = t.global_position.distance_to(v.at)
				if dd < gd:
					goal = t
					gd = dd
			if goal and gd > 4.0:
				v.at = (v.at as Vector2).move_toward(goal.global_position, VORTEX_WANDER * delta)
				node.global_position = (v.at as Vector2).round()
		node.frame = int(_clock * 12.0) % VORTEX_FX_FRAMES
		node.modulate.a = clampf(v.left / 0.4, 0.0, 1.0)
		for t in _live_targets():
			var d: Vector2 = t.global_position - v.at
			if Vector2(d.x, d.y * 1.6).length() > v.radius:
				continue
			if d.length() > 4.0:  # wciąganie: odpychanie od punktu po drugiej stronie celu
				t.push_away(t.global_position + d.normalized() * 10.0, VORTEX_PULL)
			if v.tick <= 0.0:
				_hit(t, _power("h_vortex") * v.mult, v.at, "h_vortex")
		if v.tick <= 0.0:
			v.tick += VORTEX_TICK
		if v.left <= 0.0:
			if _perk("h_vortex", 1):
				_water_blast(v.at, VORTEX_BLAST_RADIUS * _area("h_vortex"), _power("h_vortex") * VORTEX_BLAST_POWER * v.mult)
			node.queue_free()
			_vortexes.remove_at(i)


## Wybuch wody (koniec wiru z 10. poziomem, pojawienie się Strażnika): rani, przemacza i odpycha w promieniu.
func _water_blast(at: Vector2, radius: float, power: float, skill := "h_vortex") -> void:
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, skill)
			t.push_away(at, WAVE_PUSH)
			_spray_fx(t.center(), t.global_position - at, 0.7)
	Fx.once(get_parent(), GEYSER_FX, 12, 14.0, at.round(), GEYSER_FX_ANCHOR, 6, radius / 45.0)
	Input.vibrate_handheld(30)


## Gejzery pod najbliższymi wrogami (od punktu `origin` - postać albo Strażnik): po GEYSER_DELAY tryskają - rani,
## przemacza i ogłusza w promieniu.
func _geysers(origin: Vector2, mult := 1.0) -> void:
	var near: Array = []
	for t in _live_targets():
		var d := origin.distance_to(t.global_position)
		if d <= Skills.DATA.h_geyser.range * _area("h_geyser"):
			near.append([d, t])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var n := GEYSERS_PERK if _perk("h_geyser", 1) else GEYSERS
	var targets_hit: Array = []
	for pair in near.slice(0, n):
		targets_hit.append(pair[1])
	if targets_hit.is_empty():
		var at := origin + hero.facing.normalized() * 40.0
		_splash_fx(at, 0.4)
		get_tree().create_timer(GEYSER_DELAY, false).timeout.connect(_geyser_burst.bind(at, null, mult))
	for t in targets_hit:
		_splash_fx(t.global_position, 0.4)  # zapowiedź: bulgocze ziemia
		get_tree().create_timer(GEYSER_DELAY, false).timeout.connect(_geyser_burst.bind(t.global_position, t, mult))


## Wybuch gejzera - pod wrogiem `target` tam, gdzie akurat stoi (zdążył się ruszyć), albo w punkcie `at`.
func _geyser_burst(at: Vector2, target: ProtoTarget, mult := 1.0) -> void:
	if not is_inside_tree():
		return
	if target != null and is_instance_valid(target) and target.alive():
		at = target.global_position
	var radius := GEYSER_RADIUS * _area("h_geyser")
	var stun_time := GEYSER_STUN_LONG if _perk("h_geyser", 0) else GEYSER_STUN
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, _power("h_geyser") * mult, at, "h_geyser")
			t.stun(stun_time)
	Fx.once(get_parent(), GEYSER_FX, 12, 14.0, at.round(), GEYSER_FX_ANCHOR, 6, 0.8)
	if _unique("h_geyser"):  # kamień unikalny: gejzer wypluwa kule wody, które spadają dookoła
		var start := randf() * TAU
		for i in LOB_COUNT:
			var to := at + Vector2.from_angle(start + TAU * i / LOB_COUNT) * LOB_DISTANCE * _area("h_geyser")
			_add_lob(at, to, mult)
	Input.vibrate_handheld(20)


# --- Wodny Strażnik ---

## Strażnik w punkcie `at` (na ziemi): pojawia się z wybuchem wody (rani i odpycha wokół), potem unosi się i strzela.
func _add_guardian(at: Vector2) -> void:
	var node := Sprite2D.new()
	node.texture = ORB_TEXTURE
	node.offset = Vector2(0, -GUARD_HOVER)
	node.z_index = 5
	get_parent().add_child(node)
	node.global_position = at.round()
	_water_blast(at, GUARD_BLAST_RADIUS * _area("h_guardian"), _power("h_guardian") * GUARD_BLAST_POWER, "h_guardian")
	_guardians.append({"node": node, "at": at, "acc": 0.0,
			"left": GUARD_TIME_LONG if _perk("h_guardian", 0) else GUARD_TIME})


func _process_guardians(delta: float) -> void:
	for i in range(_guardians.size() - 1, -1, -1):
		var g: Dictionary = _guardians[i]
		var node: Sprite2D = g.node
		g.left -= delta
		g.acc += delta
		node.offset = Vector2(0, -GUARD_HOVER - 2.0 * sin(_clock * 3.0 + i))
		node.modulate.a = clampf(g.left / 0.4, 0.0, 1.0)
		var from: Vector2 = node.global_position + node.offset
		if g.acc >= GUARD_EVERY:
			g.acc -= GUARD_EVERY
			var best: ProtoTarget = null
			var best_d := GUARD_RANGE * _area("h_guardian")
			for t in _live_targets():
				var d := t.center().distance_to(from)
				if d <= best_d:
					best = t
					best_d = d
			if best:
				_spawn_bolt(from, (best.center() - from).angle(), best, "h_guardian")
		if g.left <= 0.0 or hero.dead:
			_splash_fx(g.at, 0.7)
			node.queue_free()
			_guardians.remove_at(i)


## Kamień unikalny Strażnika: każdy Strażnik powtarza ze swojego miejsca umiejętność `id` gracza, za darmo, słabiej.
func _echo(id: String) -> void:
	for g in _guardians:
		var at: Vector2 = g.at
		match id:
			"h_wave":
				_spawn_tide(at + Vector2(0, -GUARD_HOVER), ECHO_POWER)
			"h_vortex":
				var best: ProtoTarget = null
				var best_d := Skills.DATA.h_vortex.range as float
				for t in _live_targets():
					var d := t.global_position.distance_to(at)
					if d <= best_d:
						best = t
						best_d = d
				_add_vortex(best.global_position if best else at, ECHO_POWER)
			"h_geyser":
				_geysers(at, ECHO_POWER)


# --- Kamienie unikalne: krążące bańki i kule z gejzerów ---

## Bańka krążąca wokół postaci zaczyna pod kątem `a`; najwięcej ORBIT_MAX naraz (najstarsza znika).
func _add_orbit(a: float) -> void:
	if _orbits.size() >= ORBIT_MAX:
		_orbits[0].holder.queue_free()
		_orbits.remove_at(0)
	var holder := Node2D.new()  # spłaszcza okrąg orbity jak na ziemi (rzut z góry)
	holder.scale = Vector2(1.0, 0.7)
	holder.z_index = 20
	get_parent().add_child(holder)
	holder.global_position = _orbit_center()
	var fx := Sprite2D.new()
	fx.texture = ORBIT_FX
	fx.hframes = 8
	fx.centered = false
	fx.offset = -ORBIT_FX_ANCHOR
	fx.rotation = a
	fx.scale = Vector2.ONE * ORBIT_RADIUS * _area(basic) / ORBIT_FX_RADIUS
	holder.add_child(fx)
	_orbits.append({"fx": fx, "holder": holder, "angle": a, "left": ORBIT_TIME, "hits": {}})


## Bańki krążą wokół postaci (rozłożone równo), przebijają wrogów - ten sam wróg najwyżej co ORBIT_REHIT.
func _process_orbits(delta: float) -> void:
	var r := ORBIT_RADIUS * _area(basic)
	for i in range(_orbits.size() - 1, -1, -1):
		var o: Dictionary = _orbits[i]
		var fx: Sprite2D = o.fx
		o.left -= delta
		o.angle += TAU * ORBIT_TURNS * delta
		var at := _orbit_center() + Vector2(cos(o.angle), sin(o.angle) * 0.7) * r
		o.holder.global_position = _orbit_center()
		fx.rotation = o.angle  # bańka na czele, ogon wygięty po łuku za nią
		fx.frame = int(_clock * 12.0 + i) % 8
		o.holder.modulate.a = clampf(o.left / 0.3, 0.0, 1.0)
		for t in o.hits.keys():
			o.hits[t] -= delta
		for t in _live_targets():
			if t.center().distance_to(at) <= BOLT_RADIUS * _area(basic) and o.hits.get(t, 0.0) <= 0.0:
				o.hits[t] = ORBIT_REHIT
				_hit(t, _power(basic) * _swing_power, at, basic)
				_spray_fx(t.center(), Vector2.from_angle(o.angle + PI / 2.0), 0.6)
		if o.left <= 0.0 or hero.dead:
			o.holder.queue_free()
			_orbits.remove_at(i)


## Kula wody z gejzera leci łukiem z `from` do `to`, a po upadku rani obszarem (LOB_POWER x siła gejzera x `mult`).
func _add_lob(from: Vector2, to: Vector2, mult: float) -> void:
	var fx := _shot_sprite(BOLT_FX, 8, BOLT_FX_ANCHOR, (to - from).angle())
	fx.global_position = from
	fx.scale = Vector2.ONE * 0.8
	_lobs.append({"fx": fx, "from": from, "to": to, "t": 0.0, "mult": mult})


func _process_lobs(delta: float) -> void:
	for i in range(_lobs.size() - 1, -1, -1):
		var l: Dictionary = _lobs[i]
		var fx: Sprite2D = l.fx
		l.t += delta
		var k := clampf(l.t / LOB_TIME, 0.0, 1.0)
		var ground: Vector2 = (l.from as Vector2).lerp(l.to, k)
		fx.global_position = ground + Vector2(0, -LOB_HEIGHT * 4.0 * k * (1.0 - k))
		fx.rotation = ((l.to as Vector2) - (l.from as Vector2)).angle() + (k - 0.5) * 1.6 * signf(cos(fx.rotation) + 0.001)
		fx.frame = int(_clock * 12.0 + i) % 8
		if k >= 1.0:
			var radius := LOB_RADIUS * _area("h_geyser")
			for t in _live_targets():
				var off: Vector2 = t.global_position - (l.to as Vector2)
				if Vector2(off.x, off.y * 1.6).length() <= radius:
					_hit(t, _power("h_geyser") * LOB_POWER * l.mult, l.to, "h_geyser")
			_splash_fx(l.to, 0.6)
			fx.queue_free()
			_lobs.remove_at(i)


func _end_skill() -> void:
	super._end_skill()
	_cooldown = maxf(_cooldown, ORB_COOLDOWN * 0.5)

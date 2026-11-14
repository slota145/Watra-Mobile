class_name ProtoKatana
extends ProtoWeapon
## Elektryczna katana (ustalone z autorem 15.11.2026) - czwarta broń, żywioł Grom (Elements.LIGHTNING), najszybsza
## broń wręcz. Lewituje obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, orbita cięcia, mana, odnowienia,
## kamienie, krytyki). Każde trafienie PORAŻA (`_hit`): wróg przez SHOCK_TIME dostaje od wszystkiego o
## Elements.SHOCK_BONUS więcej (ProtoWeapon._combo_mult), a ARC_POWER obrażeń przeskakuje piorunem na najbliższego
## sąsiada (`_chain_from`; z przemoczonego - combo z hydrosferą - na Elements.SOAK_CHAIN_EXTRA wrogów więcej i mocniej,
## a cała katana bije przemoczonych o Elements.SOAK_BONUS mocniej).
## - „Błyskawiczne cięcie” (`k_slash`, zwykły cios): szybkie cięcie po łuku (5. poziom - co 4. cięcie piorun
##   w najbliższego wroga, 10. - cięcie przeskakuje na dwóch wrogów obok);
## - „Iaido” (`k_iaido`): zryw postaci na wylot przez wroga, rani wszystkich na drodze (5. - dłuższy zryw,
##   10. - wyładowanie na końcu);
## - „Łańcuch piorunów” (`k_chain`): piorun z katany skacze po kolei po CHAIN_JUMPS wrogach (5. - więcej skoków,
##   10. - każdy skok zostawia iskrę na ziemi, która rani);
## - „Sąd Peruna” (`k_perun`): pioruny z nieba w najbliższych wrogów, ranią obszarem i ogłuszają (5. - 5 piorunów,
##   10. - druga seria po pół sekundy);
## - „Burza ostrzy” (`k_storm`): katana sama skacze od wroga do wroga przez STORM_TIME, postać chodzi swobodnie z boku
##   (5. - dłużej, 10. - z każdego skoku piorun rozgałęzia się na dwóch wrogów).
## Kamienie unikalne katany - później. Grafika: assets/weapons/katana.png (tools/katana_art.py), efekty z kreatora
## (assets/effects/katana_*.png, pixellab_src/vfx/ids.json): cięcie i smuga Iaido (przebarwione cięcie miecza i smuga
## Mgnienia), trafienie piorunem, piorun z nieba.

const KATANA_TEXTURE := preload("res://assets/weapons/katana.png")
## Punkt chwytu na obrazku (przy tsubie - ostrze ma od niego 26 px w grze, jak miecz).
const K_GRIP := Vector2(20.0, 8.0)
## Porażenie: czas, część obrażeń trafienia przeskakująca na sąsiada, ilu sąsiadów, zasięg przeskoku.
const SHOCK_TIME := 3.0
const ARC_POWER := 0.25
const ARC_TARGETS := 1
const ARC_RANGE := 60.0
## Błyskawiczne cięcie: czasy (zamach, cięcie, powrót, przerwa) - ok. 1,4 raza szybciej niż miecz; piorun z 5. poziomu
## (co który, zasięg, siła), przeskok z 10. (ilu, siła).
const K_WINDUP := 0.07
const K_SWING := 0.12
const K_RECOVER := 0.06
const K_COOLDOWN := 0.38
const SLASH_BOLT_EVERY := 4
const SLASH_BOLT_RANGE := 100.0
const SLASH_BOLT_POWER := 0.8
const SLASH_ARC_TARGETS := 2
const SLASH_ARC_POWER := 0.5
## Iaido: długość zrywu (5. poziom - dłuższy), o ile za wroga, połowa szerokości pasa, wyładowanie z 10. (promień, siła).
const IAIDO_DISTANCE := 70.0
const IAIDO_DISTANCE_LONG := 100.0
const IAIDO_OVERSHOOT := 18.0
const IAIDO_WIDTH := 12.0
const IAIDO_BLAST_RADIUS := 40.0
const IAIDO_BLAST_POWER := 0.8
## Łańcuch piorunów: liczba skoków (5. poziom - więcej), zasięg skoku, co ile kolejny skok, iskry z 10. (czas, co ile
## ranią, promień, siła).
const CHAIN_JUMPS := 5
const CHAIN_JUMPS_PERK := 7
const CHAIN_JUMP_RANGE := 80.0
const CHAIN_STEP := 0.07
const SPARK_TIME := 2.0
const SPARK_TICK := 0.5
const SPARK_RADIUS := 14.0
const SPARK_POWER := 0.25
## Sąd Peruna: liczba piorunów (5. poziom - więcej), odstęp między nimi, czas od pojawienia do uderzenia (klatki
## spadania pioruna), promień, ogłuszenie, druga seria z 10. (po ilu sekundach).
const PERUN_BOLTS := 3
const PERUN_BOLTS_PERK := 5
const PERUN_STAGGER := 0.08
const PERUN_DELAY := 0.2
const PERUN_RADIUS := 22.0
const PERUN_STUN := 0.6
const PERUN_ECHO := 0.5
## Burza ostrzy: czas (5. poziom - dłużej), co ile skok, zasięg szukania wrogów od postaci, promień cięcia, rozgałęzienie
## z 10. (ilu, siła).
const STORM_TIME := 3.0
const STORM_TIME_LONG := 4.0
const STORM_EVERY := 0.22
const STORM_RANGE := 120.0
const STORM_HIT := 18.0
const STORM_BRANCH_TARGETS := 2
const STORM_BRANCH_POWER := 0.4
## Efekty (klatki, fps, zaczepienie, wielkość).
const K_SLASH_FX := preload("res://assets/effects/katana_slash.png")
const K_HIT_FX := preload("res://assets/effects/katana_hit.png")
const K_HIT_FRAMES := 10
const K_HIT_FPS := 18.0
const K_HIT_ANCHOR := Vector2(28, 22)
const K_HIT_SIZE := 0.45
const K_TRAIL_FX := preload("res://assets/effects/katana_trail.png")
const K_TRAIL_ANCHOR := Vector2(8, 10)
const K_TRAIL_LENGTH := 64.0
const PERUN_FX := preload("res://assets/effects/katana_perun.png")
const PERUN_FX_FRAMES := 14
const PERUN_FX_FPS := 20.0
const PERUN_FX_ANCHOR := Vector2(49, 138)
const PERUN_FX_SIZE := 0.6

## Łańcuch piorunów w drodze: {"cur": cel, "from": punkt, "hits": [], "left": skoki, "t": do skoku, "power"}.
var _chains: Array = []
## Iskry na ziemi (10. poziom łańcucha): {"at", "left", "tick", "fx"}.
var _sparks: Array = []
## Pioruny Peruna czekające na uderzenie: {"at", "t", "mult"}.
var _strikes: Array = []
var _storm_left := 0.0
var _storm_acc := 0.0
var _storm_last: Object


func _init() -> void:
	basic = "k_slash"
	main_skill = "k_slash"
	element = Elements.LIGHTNING


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = KATANA_TEXTURE
		s.offset = -K_GRIP
	_slash.texture = K_SLASH_FX


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"k_windup", "k_swing", "k_recover":
			_process_slash()
		"storm":
			_process_storm(delta)
	_process_chains(delta)
	_process_sparks(delta)
	_process_strikes(delta)


## Błysk pioruna na celu.
func _zap_fx(at: Vector2, size := K_HIT_SIZE) -> void:
	Fx.once(get_parent(), K_HIT_FX, K_HIT_FRAMES, K_HIT_FPS, at.round(), K_HIT_ANCHOR, 21, size)


## Trafienie kataną: obrażenia jak każdej broni (`_deal` - krytyk, elity, kamienie, combo), porażenie i przeskok
## pioruna na `arcs` sąsiadów (`arc_power` obrażeń trafienia; 0 - bez przeskoku). Zwraca zadane obrażenia (przed krytykiem).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String, arcs := ARC_TARGETS, arc_power := ARC_POWER) -> int:
	var amount := _roll(power)
	_deal(t, amount, from, skill)
	if t.alive():
		t.shock(SHOCK_TIME)
	if arcs > 0 and arc_power > 0.0:
		for n in _chain_from(t, maxi(1, roundi(amount * arc_power)), arcs, ARC_RANGE):
			n.shock(SHOCK_TIME)
	return amount


# --- Zwykły cios: błyskawiczne cięcie ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) * _area(basic) / SLASH_FX_RADIUS
	var best := _nearest(Skills.DATA[basic].range * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("k_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _process_slash() -> void:
	match _state:
		"k_windup":
			var k := ease(clampf(_t / K_WINDUP, 0.0, 1.0), -2.0)
			var a := _angle_at(-0.1)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= K_WINDUP:
				_set_state("k_swing")
				_slash.visible = true
		"k_swing":
			var progress := clampf(_t / K_SWING, 0.0, 1.0)
			_place(_angle_at(ease(progress, 0.5)))
			_slash.frame = mini(int(progress * SLASH_FRAMES), SLASH_FRAMES - 1)
			if not _hit_done and progress >= 0.5:
				_hit_done = true
				_slash_hit()
			if _t >= K_SWING:
				_slash.visible = false
				_set_state("k_recover")
		"k_recover":
			_place(_angle_at(1.0))
			if _t >= K_RECOVER:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: drugie cięcie w drugą stronę
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = K_COOLDOWN


## Cięcie trafia wszystkich w łuku przed postacią; 5. poziom - co SLASH_BOLT_EVERY cięcie piorun w najbliższego wroga,
## 10. - przeskok na SLASH_ARC_TARGETS wrogów (zamiast jednego).
func _slash_hit() -> void:
	var power := _swing_power * _power(basic)
	var reach := (HILT_RADIUS + BLADE + 6.0) * _area(basic)
	var arcs := SLASH_ARC_TARGETS if _perk(basic, 1) else ARC_TARGETS
	var arc_power := SLASH_ARC_POWER if _perk(basic, 1) else ARC_POWER
	var any := false
	for t in _live_targets():
		var to := t.center() - _orbit_center()
		if to.length() <= reach and absf(angle_difference(_aim, to.angle())) <= ARC / 2.0:
			_hit(t, power, hero.global_position, basic, arcs, arc_power)
			_zap_fx(_orbit_center() + to.limit_length(HILT_RADIUS + BLADE * 0.8))
			any = true
	if _perk(basic, 0) and not _second and _strike_count % SLASH_BOLT_EVERY == 0:
		var near := _nearest(SLASH_BOLT_RANGE * _area(basic))
		if near:
			_bolt(_sprite.global_position, near.center())
			_hit(near, power * SLASH_BOLT_POWER, hero.global_position, basic, 0)
			_zap_fx(near.center(), 0.6)
	if any:
		Input.vibrate_handheld(12)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["k_iaido", "k_chain", "k_perun", "k_storm"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	_slash.visible = false
	var best := _nearest(Skills.DATA[id].range * _area(id))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"k_iaido":
			_iaido(best)
		"k_chain":
			if best:
				_chains.append({"cur": best, "from": _sprite.global_position, "hits": [], "left": _chain_jumps(),
						"t": 0.0, "power": _power(id)})
			else:
				_zap_fx(_orbit_center() + Vector2.from_angle(_aim) * 30.0, 0.6)
		"k_perun":
			_perun(best)
		"k_storm":
			_storm_left = STORM_TIME_LONG if _perk(id, 0) else STORM_TIME
			_storm_acc = STORM_EVERY
			_storm_last = null
			_set_state("storm")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Iaido: postać przemyka w stronę wroga (na wylot, co najmniej IAIDO_OVERSHOOT za nim), błękitna smuga od miejsca
## startu, cięcie trafia wszystkich w pasie wzdłuż drogi; 10. poziom - wyładowanie w miejscu lądowania.
func _iaido(best: ProtoTarget) -> void:
	var from := hero.global_position
	var dir := Vector2.from_angle(_aim)
	var distance := (IAIDO_DISTANCE_LONG if _perk("k_iaido", 0) else IAIDO_DISTANCE) * _area("k_iaido")
	if best:
		distance = maxf(distance, from.distance_to(best.global_position) + IAIDO_OVERSHOOT)
	var spot := hero.teleport(from + dir * distance)
	var travel := spot - from
	var body := Vector2(0, -ORBIT_HEIGHT)
	var trail := Fx.once(get_parent(), K_TRAIL_FX, 7, 16.0, from + body, K_TRAIL_ANCHOR)
	trail.rotation = travel.angle()
	trail.scale = Vector2.ONE * maxf(0.5, (travel.length() - 8.0) / K_TRAIL_LENGTH)
	var width := IAIDO_WIDTH * _area("k_iaido")
	for t in _live_targets():
		var c := t.center()
		if Geometry2D.get_closest_point_to_segment(c, from + body, spot + body).distance_to(c) \
				<= width + t.center_height * 0.5:
			_hit(t, _power("k_iaido"), from, "k_iaido")
			_zap_fx(c)
	if _perk("k_iaido", 1):
		_discharge(spot + body, IAIDO_BLAST_RADIUS * _area("k_iaido"), _power("k_iaido") * IAIDO_BLAST_POWER, "k_iaido")
	Input.vibrate_handheld(20)
	# katana tnie po łuku w stronę zrywu (bez drugiego trafienia - cięcie już zadane wzdłuż drogi)
	_aim = travel.angle() if travel != Vector2.ZERO else _aim
	_sign = -_sign
	_hit_done = true
	_second = true
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) / SLASH_FX_RADIUS
	_set_state("k_swing")
	_slash.visible = true


## Wyładowanie: rani i poraża wszystkich w promieniu `radius` od punktu `at` (bez przeskoków).
func _discharge(at: Vector2, radius: float, power: float, skill: String) -> void:
	for t in _live_targets():
		if t.center().distance_to(at) <= radius:
			_hit(t, power, at, skill, 0)
	_zap_fx(at, radius / 32.0)


func _chain_jumps() -> int:
	return CHAIN_JUMPS_PERK if _perk("k_chain", 0) else CHAIN_JUMPS


## Łańcuch piorunów: co CHAIN_STEP piorun skacze na kolejnego wroga (najbliższego nietrafionego w zasięgu skoku).
func _process_chains(delta: float) -> void:
	for c in _chains.duplicate():
		c.t -= delta
		if c.t > 0.0:
			continue
		if not is_instance_valid(c.cur) or not (c.cur as ProtoTarget).alive():
			_chains.erase(c)
			continue
		var cur: ProtoTarget = c.cur
		_bolt(c.from, cur.center())
		_hit(cur, c.power, c.from, "k_chain", 0)
		_zap_fx(cur.center())
		c.hits.append(cur)
		if _perk("k_chain", 1):
			_add_spark(cur.global_position)
		c.left -= 1
		c.from = cur.center()
		c.t = CHAIN_STEP
		var next: ProtoTarget = null
		var best_d := CHAIN_JUMP_RANGE * _area("k_chain")
		for t in _live_targets():
			var d := t.global_position.distance_to(cur.global_position)
			if not c.hits.has(t) and d <= best_d:
				next = t
				best_d = d
		c.cur = next
		if c.left <= 0 or next == null:
			_chains.erase(c)


## Iskra na ziemi (10. poziom łańcucha): migocze SPARK_TIME, co SPARK_TICK rani wrogów obok.
func _add_spark(at: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = K_HIT_FX
	fx.hframes = K_HIT_FRAMES
	fx.centered = false
	fx.offset = -K_HIT_ANCHOR
	fx.scale = Vector2.ONE * 0.3
	fx.z_index = 2
	get_parent().add_child(fx)
	fx.global_position = at.round()
	_sparks.append({"at": at, "left": SPARK_TIME, "tick": SPARK_TICK, "fx": fx})


func _process_sparks(delta: float) -> void:
	for s in _sparks.duplicate():
		s.left -= delta
		s.tick -= delta
		var fx: Sprite2D = s.fx
		fx.frame = 4 + int(_clock * K_HIT_FPS) % 4
		fx.modulate.a = clampf(s.left / 0.3, 0.0, 1.0)
		if s.tick <= 0.0:
			s.tick = SPARK_TICK
			for t in _live_targets():
				if t.global_position.distance_to(s.at) <= SPARK_RADIUS:
					_hit(t, _power("k_chain") * SPARK_POWER, s.at, "k_chain", 0)
		if s.left <= 0.0:
			fx.queue_free()
			_sparks.erase(s)


## Sąd Peruna: pioruny w najbliższych wrogów (bez wrogów - jeden przed postacią); 10. poziom - druga seria.
func _perun(best: ProtoTarget) -> void:
	var count := PERUN_BOLTS_PERK if _perk("k_perun", 0) else PERUN_BOLTS
	var near: Array = []
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d <= Skills.DATA.k_perun.range * _area("k_perun"):
			near.append([d, t])
	near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var spots: Array = []
	for pair in near.slice(0, count):
		spots.append((pair[1] as ProtoTarget).global_position)
	if spots.is_empty():
		spots.append(hero.global_position + Vector2.from_angle(_aim) * 40.0)
	for i in spots.size():
		_add_strike(spots[i], i * PERUN_STAGGER)
		if _perk("k_perun", 1):
			_add_strike(spots[i], i * PERUN_STAGGER + PERUN_ECHO)


## Piorun Peruna w punkcie `at` za `wait` s: najpierw pojawia się efekt, po PERUN_DELAY uderza.
func _add_strike(at: Vector2, wait: float) -> void:
	_strikes.append({"at": at, "t": wait, "shown": false})


func _process_strikes(delta: float) -> void:
	for s in _strikes.duplicate():
		s.t -= delta
		if not s.shown and s.t <= 0.0:
			s.shown = true
			Fx.once(get_parent(), PERUN_FX, PERUN_FX_FRAMES, PERUN_FX_FPS, (s.at as Vector2).round(), PERUN_FX_ANCHOR, 21,
					PERUN_FX_SIZE)
		if s.t <= -PERUN_DELAY:
			_strikes.erase(s)
			var radius := PERUN_RADIUS * _area("k_perun")
			for t in _live_targets():
				if t.global_position.distance_to(s.at) <= radius + t.center_height * 0.3:
					_hit(t, _power("k_perun"), s.at, "k_perun")
					t.stun(PERUN_STUN)
			Input.vibrate_handheld(25)


## Burza ostrzy: katana co STORM_EVERY przeskakuje (zygzak pioruna) do najbliższego wroga w zasięgu postaci i tnie go
## oraz wrogów tuż obok; bez wrogów wraca do postaci. Postać w tym czasie chodzi swobodnie.
func _process_storm(delta: float) -> void:
	_storm_left -= delta
	_storm_acc += delta
	if _storm_left <= 0.0:
		_end_skill()
		return
	var on_target: bool = is_instance_valid(_storm_last) and (_storm_last as ProtoTarget).alive()
	if not on_target:
		_follow(delta)  # bez wroga katana wraca do postaci
	if _storm_acc < STORM_EVERY:
		return
	_storm_acc = 0.0
	var range_px := STORM_RANGE * _area("k_storm")
	var here := _sprite.global_position
	var best: ProtoTarget = null
	var best_d := INF
	for t in _live_targets():
		if hero.global_position.distance_to(t.global_position) > range_px:
			continue
		var d := here.distance_to(t.center()) + (1000.0 if on_target and t == _storm_last else 0.0)
		if d < best_d:
			best = t
			best_d = d
	if best == null:
		_storm_last = null
		return
	_storm_last = best
	global_position = best.global_position + Vector2(0, 1)
	_sprite.position = Vector2(0, -best.center_height - 1.0)
	_sprite.rotation = randf() * TAU
	_bolt(here, _sprite.global_position)
	var fx := Fx.once(get_parent(), K_SLASH_FX, SLASH_FRAMES, 24.0, best.center().round(), Vector2(32, 32), 21, 0.6)
	fx.rotation = randf() * TAU
	var branch := _perk("k_storm", 1)
	for t in _live_targets():
		if t.center().distance_to(best.center()) <= STORM_HIT * _area("k_storm"):
			_hit(t, _power("k_storm"), here, "k_storm", STORM_BRANCH_TARGETS if branch and t == best else ARC_TARGETS,
					STORM_BRANCH_POWER if branch and t == best else ARC_POWER)
	_zap_fx(best.center())
	Input.vibrate_handheld(10)


func _end_skill() -> void:
	_storm_left = 0.0
	_storm_last = null
	super._end_skill()

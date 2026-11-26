class_name ProtoSpear
extends ProtoWeapon
## Słoneczna włócznia Dadźboga - pierwsza broń Prawii (ustalona z autorem 26.11.2026; Elements.PRAWIA), fizyczna, wręcz.
## Długa złota włócznia lewituje obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie,
## krytyki). Każde trafienie Prawią oślepia i piętnuje wroga, a kolejne trafienia w napiętnowanego leczą postać
## (ProtoWeapon._deal, ProtoTarget.brand). Grafika assets/weapons/spear.png (tools/spear_art.py), ikony
## tools/spear_icons.py, efekty z kreatora (pixellab_src/vfx/ids.json: spear_thrust, spear_hit, sun_ring, sun_spin, sky_beam).
## - „Promienne Pchnięcie” (`p_thrust`, zwykły atak): długie pchnięcie rani wszystkich na linii; 5. poziom - co trzecie
##   pchnięcie to promień dwa razy dalej, 10. - rozbłysk światła przy pierwszym trafionym; kamień unikalny (Trzech
##   Promieni) - dwa dodatkowe promienie w wachlarzu; Mnożenie - drugie pchnięcie w innego wroga.
## - „Rzut Dadźboga” (`p_throw`): włócznia leci (gałka, bez niej najbliższy wróg) THROW_DIST px, przebija wszystkich
##   i wraca do ręki, raniąc drugi raz; 5. - dalej, 10. - przy zawróceniu pierścień światła; kamień unikalny (Sieci
##   Swaroga) - wracając, ciągnie trafionych za sobą ku postaci; Mnożenie - 3 włócznie wachlarzem.
## - „Wschód Słońca” (`p_sunrise`): włócznia unosi się i wbija w ziemię - pierścień światła rani (i piętnuje)
##   wszystkich wokół; 5. - krąg większy, 10. - drugi rozbłysk; kamień unikalny (Południa) - włócznia-widmo zostaje
##   wbita jako słup światła i co chwilę rani wrogów obok; Mnożenie - drugi, szerszy rozbłysk.
## - „Kołowrót Słońca” (`p_wheel`, pomysł autora 26.11.2026 - ruch jak Taniec Marzanny, wybuch jak Cięcie Światowida):
##   kilka kroków naprzód z włócznią wirującą nad głową - dwa obroty (złote okręgi `sun_spin`), wir rani co WHEEL_TICK;
##   potem od cięć rozchodzi się pierścień światła, który rani i odpycha; 5. - pierścień dalej, 10. - trzy obroty;
##   kamień unikalny (Swarożyca) - z pierścienia wylatuje 8 promieni; Mnożenie - pierścień drugi raz.
## - „Zenit” (`p_zenith`, pomysł autora 26.11.2026 - deszcz włóczni): z nieba po kolei spada ZENITH_COUNT włóczni
##   w promieniach światła - na wrogów w pobliżu, a gdy ich brak, w losowe miejsca; przed upadkiem złoty krąg na ziemi;
##   5. - więcej włóczni, 10. - wbite włócznie świecą i ranią; kamień unikalny (Dadźboga) - na końcu ogromna włócznia
##   spada na najsilniejszego wroga; Mnożenie - 3 włócznie więcej.

const SPEAR_TEXTURE := preload("res://assets/weapons/spear.png")
## Punkt chwytu w obrazku (na drzewcu), skala w grze i długość od chwytu do szpica w grze (px).
const P_GRIP := Vector2(34.0, 10.0)
const P_SCALE := 0.5
const SPEAR_LEN := 28.0
const GOLD := Color(1.0, 0.86, 0.45)
const THRUST_FX := preload("res://assets/effects/spear_thrust.png")
const THRUST_FRAMES := 7
const THRUST_ANCHOR := Vector2(5, 7)
const THRUST_FX_LEN := 60.0
const P_HIT_FX := preload("res://assets/effects/spear_hit.png")
const P_HIT_FRAMES := 8
const P_HIT_ANCHOR := Vector2(20, 19)
const RING_FX := preload("res://assets/effects/sun_ring.png")
const RING_FRAMES := 8
const RING_FPS := 14.0
const RING_ANCHOR := Vector2(58, 25)
## Promień pierścienia na arkuszu w ostatnich klatkach (do skalowania pod promień trafienia).
const RING_FX_RADIUS := 55.0
const SPIN_FX := preload("res://assets/effects/sun_spin.png")
const SPIN_FRAMES := 11
const SPIN_FPS := 16.0
const SPIN_ANCHOR := Vector2(48, 23)
const SPIN_FX_RADIUS := 46.0
const BEAM_FX := preload("res://assets/effects/sky_beam.png")
const BEAM_FRAMES := 14
const BEAM_FPS := 14.0
const BEAM_ANCHOR := Vector2(36, 106)
## Promień rozbłysku u podstawy promienia na arkuszu.
const BEAM_FX_RADIUS := 33.0

## Promienne Pchnięcie: czasy, szerokość pasa trafienia, promień z 5. poziomu (co ile, mnożnik zasięgu), rozbłysk
## z 10. (promień, siła), kamień unikalny (kąt i siła bocznych promieni).
const THRUST_WIND := 0.1
const THRUST_OUT := 0.12
const THRUST_BACK := 0.12
const THRUST_COOLDOWN := 0.5
const THRUST_WIDTH := 10.0
const RAY_EVERY := 3
const RAY_LONG := 2.0
const FLARE_RADIUS := 24.0
const FLARE_POWER := 0.4
const RAYS_ANGLE := 0.4
const RAYS_POWER := 0.5
## Rzut Dadźboga: odległość (5. poziom - dalej), prędkość lotu i powrotu, szerokość trafienia, pierścień przy zawróceniu
## z 10. (promień, siła), siła ściągania z kamieniem unikalnym, kąt bocznych włóczni z Mnożeniem.
const THROW_DIST := 150.0
const THROW_LONG := 1.3
const THROW_OUT_SPEED := 380.0
const THROW_BACK_SPEED := 440.0
const THROW_WIDTH := 12.0
const TURN_RADIUS := 40.0
const TURN_POWER := 0.6
const THROW_PULL := 170.0
const THROW_FAN := 0.35
## Wschód Słońca: wzniesienie i upadek włóczni (s), wysokość, promień kręgu (5. - większy), drugi rozbłysk z 10.
## (po ilu s, siła), Mnożenie (po ilu s, mnożnik promienia), kamień Południa (czas słupa, co ile rani, promień, siła).
const RISE_TIME := 0.18
const FALL_TIME := 0.07
const RISE_HEIGHT := 40.0
const SUNRISE_RADIUS := 62.0
const SUNRISE_PERK_AREA := 1.3
const SUNRISE_SECOND := 0.5
const SUNRISE_SECOND_POWER := 0.6
const SUNRISE_ECHO := 0.35
const SUNRISE_ECHO_AREA := 1.3
const PILLAR_TIME := 4.0
const PILLAR_TICK := 0.5
const PILLAR_RADIUS := 0.7
const PILLAR_POWER := 0.2
## Kołowrót Słońca: obroty (10. - 3), czas obrotu, droga kroków na obrót, wir (promień, co ile rani, siła), pierścień
## (zasięg, 5. - dalej, siła, odepchnięcie, Mnożenie - po ilu s), kamień Swarożyca (promienie: ile, zasięg, siła).
const WHEEL_SPINS := 2
const WHEEL_SPINS_PERK := 3
const WHEEL_SPIN_TIME := 0.4
const WHEEL_STEP := 26.0
const WHEEL_RADIUS := 44.0
const WHEEL_TICK := 0.13
const WHEEL_SPIN_POWER := 0.35
const WHEEL_RING := 92.0
const WHEEL_PERK_AREA := 1.3
const WHEEL_RING_POWER := 1.6
const WHEEL_PUSH := 130.0
const WHEEL_ECHO := 0.3
const WHEEL_RAYS := 8
const WHEEL_RAY_REACH := 150.0
const WHEEL_RAY_POWER := 0.5
## Zenit: ile włóczni (5. - więcej, Mnożenie - +3), w jakim czasie spadają, ostrzeżenie (s), upadek (s), wysokość
## startu, promień trafienia, wbite włócznie z 10. (czas, co ile, promień, siła), kamień Dadźboga (siła, promień, skala).
const ZENITH_COUNT := 6
const ZENITH_COUNT_PERK := 8
const ZENITH_EXTRA := 3
const ZENITH_SPAN := 1.0
const ZENITH_WARN := 0.25
const ZENITH_FALL := 0.18
const ZENITH_HEIGHT := 150.0
const ZENITH_RADIUS := 26.0
const ZENITH_STUCK := 0.4
const ZENITH_GLOW := 2.0
const ZENITH_GLOW_TICK := 0.5
const ZENITH_GLOW_RADIUS := 22.0
const ZENITH_GLOW_POWER := 0.2
const ZENITH_BIG_POWER := 3.0
const ZENITH_BIG_RADIUS := 44.0
const ZENITH_BIG_SCALE := 2.0

## Pchnięcie: licznik (promień co trzecie), kierunek.
var thrust_count := 0
var _aim_dir := Vector2.RIGHT
var _ray := false
## Lecące włócznie Rzutu ({"node", "dir", "from", "dist", "back", "hits", "power", "turned", "pulled"}).
var _throws: Array = []
## Wschód Słońca: miejsce wbicia, zaplanowane rozbłyski ({"at", "t", "radius", "power"}), słupy Południa.
var _flashes: Array = []
var _pillars: Array = []
## Kołowrót: obroty do zrobienia, zrobione, odliczanie wiru, kierunek kroków.
var _spins := 0
var spins_done := 0
var _wheel_tick := 0.0
var _wheel_dir := Vector2.RIGHT
## Zenit: spadające włócznie ({"at", "t", "delay", "power", "radius", "big", "warn", "node", "hit", "glow", "tick"}).
var _drops: Array = []
## Ile włóczni Zenitu uderzyło (testy).
var drops_done := 0


func _init() -> void:
	basic = "p_thrust"
	main_skill = "p_thrust"
	element = Elements.PRAWIA
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = SPEAR_TEXTURE
		s.offset = -P_GRIP
		s.scale = Vector2.ONE * P_SCALE


func _world_fx() -> Array:
	return super._world_fx() + [_throws, _pillars, _drops]


func _exit_tree() -> void:
	if _sprite:
		_sprite.visible = true
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"p_wind", "p_out", "p_back":
			_process_attack()
		"p_rise", "p_fall":
			_process_sunrise()
		"p_wheel":
			_process_wheel(delta)
		"p_throw":  # włócznia w locie - bez pchnięć, dopóki nie wróci
			position = hero.position
			if _throws.is_empty() or hero.dead:
				_end_skill()
	_process_throws(delta)
	_process_flashes(delta)
	_process_pillars(delta)
	_process_drops(delta)


# --- Trafienia ---

## Trafienie umiejętnością `skill` z siłą `power` (złota gwiazdka na celu).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)
	if not Fx.crowded(P_HIT_FX):
		Fx.once(get_parent(), P_HIT_FX, P_HIT_FRAMES, 18.0, t.center().round(), P_HIT_ANCHOR, 21, 0.8)


## Wszyscy w kole `radius` wokół `at` (spłaszczonym jak cienie), poza `skip`. Zwraca trafionych.
func _ring_hits(at: Vector2, radius: float, power: float, skill: String, skip: Array = []) -> Array:
	var hit: Array = []
	for t in _near(at, radius):
		if skip.has(t):
			continue
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, skill)
			hit.append(t)
	return hit


## Wrogowie na odcinku `a`-`b` (środki celów bliżej niż `width`), pomijając `skip`.
func _line_targets(a: Vector2, b: Vector2, width: float, skip: Array = []) -> Array:
	var out: Array = []
	var mid := (a + b) * 0.5
	for t in _near(mid, a.distance_to(b) * 0.5 + width + CENTER_PAD):
		if skip.has(t):
			continue
		var p := Geometry2D.get_closest_point_to_segment(t.center(), a, b)
		if p.distance_to(t.center()) <= width:
			out.append(t)
	return out


## Złoty pierścień światła na ziemi o promieniu `radius` w `at`.
func _ring_fx(at: Vector2, radius: float, z := 2) -> void:
	if not Fx.crowded(RING_FX, 24):
		Fx.once(get_parent(), RING_FX, RING_FRAMES, RING_FPS, at.round(), RING_ANCHOR, z, radius / RING_FX_RADIUS)


## Smuga pchnięcia od `from` w kierunku `dir` na długość `length`.
func _thrust_fx(from: Vector2, dir: Vector2, length: float) -> void:
	var fx := Fx.once(get_parent(), THRUST_FX, THRUST_FRAMES, 28.0, from.round(), THRUST_ANCHOR, 21)
	fx.rotation = dir.angle()
	fx.scale = Vector2(length / THRUST_FX_LEN, 1.0)


## Włócznia wysunięta w kierunku `dir` o `out` px od środka orbity (grot do przodu).
func _point(dir: Vector2, out: float) -> void:
	position = hero.position + Vector2(0, -1.0 if dir.y < -0.2 else 1.0)
	_sprite.position = _orbit_center() - global_position + dir * out
	_sprite.rotation = dir.angle()


## Kierunek z gałki, bez niej do najbliższego wroga w zasięgu `reach`, bez niego - kierunek patrzenia.
func _aim_for(reach: float) -> Vector2:
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	if stick.length() > 0.2:
		return stick.normalized()
	var best := _nearest(reach)
	if best:
		return (best.center() - _orbit_center()).normalized()
	return hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT


# --- Promienne Pchnięcie (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		thrust_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_ray = not second and _perk(basic, 0) and thrust_count % RAY_EVERY == 0
	var reach: float = Skills.DATA[basic].range * _area(basic)
	var best: ProtoTarget = null
	if second:  # Mnożenie: drugie pchnięcie w innego wroga (bez niego - w to samo miejsce)
		var near := _near(hero.global_position, reach)
		near.shuffle()
		for t in near:
			if absf(angle_difference((t.center() - _orbit_center()).angle(), _aim_dir.angle())) > 0.3:
				best = t
				break
	else:
		best = _nearest(reach)
	if best:
		_aim_dir = (best.center() - _orbit_center()).normalized()
	elif not second:
		_aim_dir = hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("p_wind")
	hero.play_gesture(_orbit_center() + _aim_dir * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _thrust_reach() -> float:
	return Skills.DATA[basic].range * _area(basic) * (RAY_LONG if _ray else 1.0)


func _process_attack() -> void:
	match _state:
		"p_wind":
			var k := ease(clampf(_t / THRUST_WIND, 0.0, 1.0), -2.0)
			_point(_aim_dir, -4.0)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, _aim_dir.angle(), k)
			if _t >= THRUST_WIND:
				_set_state("p_out")
		"p_out":
			var k := clampf(_t / THRUST_OUT, 0.0, 1.0)
			_point(_aim_dir, lerpf(-4.0, 24.0, ease(k, 0.4)))
			if not _hit_done and k >= 0.5:
				_hit_done = true
				_thrust_hit()
			if _t >= THRUST_OUT:
				_set_state("p_back")
		"p_back":
			var k := clampf(_t / THRUST_BACK, 0.0, 1.0)
			_point(_aim_dir, lerpf(24.0, 6.0, k))
			if _t >= THRUST_BACK:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = THRUST_COOLDOWN


## Trafienie pchnięciem: wszyscy na linii; 10. - rozbłysk przy pierwszym trafionym; Trzech Promieni - boczne promienie.
func _thrust_hit() -> void:
	var from := _orbit_center()
	var reach := _thrust_reach()
	var power := _swing_power * _power(basic)
	var hit := _line_targets(from, from + _aim_dir * reach, THRUST_WIDTH * _area(basic))
	for t in hit:
		_hit(t, power, hero.global_position, basic)
	_thrust_fx(from, _aim_dir, reach)
	if _unique(basic) and not _second:
		for side in [-1.0, 1.0]:
			var dir := _aim_dir.rotated(RAYS_ANGLE * side)
			for t in _line_targets(from, from + dir * reach, THRUST_WIDTH * _area(basic)):
				_hit(t, power * RAYS_POWER, hero.global_position, basic)
			_thrust_fx(from, dir, reach)
	if not hit.is_empty() and _perk(basic, 1) and not _second:
		var first: ProtoTarget = hit[0]
		for t in hit:
			if t.global_position.distance_to(from) < first.global_position.distance_to(from):
				first = t
		var r := FLARE_RADIUS * _area(basic)
		_ring_hits(first.global_position, r, power * FLARE_POWER, basic, [first])
		_ring_fx(first.global_position, r, 3)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["p_throw", "p_sunrise", "p_wheel", "p_zenith"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	match id:
		"p_throw":
			_cast_throw()
		"p_sunrise":
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			_set_state("p_rise")
		"p_wheel":
			_spins = WHEEL_SPINS_PERK if _perk(id, 1) else WHEEL_SPINS
			spins_done = 0
			_wheel_tick = 0.0
			_wheel_dir = _aim_for(Skills.DATA[id].range * 2.0)
			_spin_step()
			_set_state("p_wheel")
		"p_zenith":
			_cast_zenith()
	hero.play_gesture(_orbit_center() + _aim_dir * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


func _end_skill() -> void:
	_sprite.visible = true
	super._end_skill()


# --- Rzut Dadźboga ---

func _throw_dist() -> float:
	return THROW_DIST * _area("p_throw") * (THROW_LONG if _perk("p_throw", 0) else 1.0)


## Wypuszcza włócznię (z Mnożeniem trzy wachlarzem); włócznia w dłoni znika, dopóki nie wróci.
func _cast_throw() -> void:
	var dir := _aim_for(_throw_dist())
	_aim_dir = dir
	var angles: Array = [0.0]
	if gem_power("p_throw", "multi") > 0.0:
		angles = [0.0, -THROW_FAN, THROW_FAN]
	for a in angles:
		var node := Sprite2D.new()
		node.texture = SPEAR_TEXTURE
		node.scale = Vector2.ONE * P_SCALE
		node.z_index = 6
		if a != 0.0:
			node.modulate = Color(1.0, 0.95, 0.75, 0.7)
		get_parent().add_child(node)
		var d: Vector2 = dir.rotated(a)
		node.global_position = _orbit_center()
		node.rotation = d.angle()
		var power := _power("p_throw") * (1.0 if a == 0.0 else gem_power("p_throw", "multi") / 100.0)
		_throws.append({"node": node, "dir": d, "from": _orbit_center(), "dist": 0.0, "back": false, "hits": [],
				"power": power, "turned": false, "main": a == 0.0})
	_sprite.visible = false
	_thrust_fx(_orbit_center(), dir, 40.0)
	_set_state("p_throw")


func _process_throws(delta: float) -> void:
	for th in _throws.duplicate():
		var node: Sprite2D = th.node
		if not is_instance_valid(node):
			_throws.erase(th)
			continue
		var a := node.global_position
		if not th.back:
			var step: float = THROW_OUT_SPEED * delta
			node.global_position += th.dir * step
			th.dist += step
			if th.dist >= _throw_dist():
				th.back = true
				th.hits = []
				if _perk("p_throw", 1) and th.main:  # 10. poziom: pierścień światła przy zawróceniu
					var r := TURN_RADIUS * _area("p_throw")
					_ring_hits(node.global_position, r, th.power * TURN_POWER, "p_throw")
					_ring_fx(node.global_position, r)
		else:
			var home := _orbit_center()
			var to := home - node.global_position
			var step: float = THROW_BACK_SPEED * delta
			if to.length() <= step + 4.0 or hero.dead:
				node.queue_free()
				_throws.erase(th)
				if th.main and _state == "p_throw":
					_end_skill()  # włócznia w dłoni - dalej walczysz
				continue
			node.global_position += to.normalized() * step
			node.rotation = (-to).angle()  # wraca drzewcem naprzód, grotem od postaci - jak przyciągana
		for t in _line_targets(a, node.global_position, THROW_WIDTH * _area("p_throw"), th.hits):
			th.hits.append(t)
			_hit(t, th.power, a, "p_throw")
			if th.back and _unique("p_throw"):  # Sieć Swaroga: wracająca włócznia ciągnie wrogów ku postaci
				t.push_away(hero.global_position, -THROW_PULL)


## Ile włóczni jest w locie (testy).
func throws_flying() -> int:
	return _throws.size()


# --- Wschód Słońca ---

func _sunrise_radius() -> float:
	return SUNRISE_RADIUS * _area("p_sunrise") * (SUNRISE_PERK_AREA if _perk("p_sunrise", 0) else 1.0)


## Włócznia unosi się grotem w dół nad postacią i spada - wbija się w ziemię u jej stóp.
func _process_sunrise() -> void:
	var down := Vector2.DOWN
	var ground := hero.global_position + Vector2(0, -2)
	match _state:
		"p_rise":
			var k := ease(clampf(_t / RISE_TIME, 0.0, 1.0), -2.0)
			position = hero.position + Vector2(0, 1)
			var top := ground + Vector2(0, -RISE_HEIGHT - SPEAR_LEN)
			_sprite.position = _from_sprite.lerp(top - global_position, k)
			_sprite.rotation = lerp_angle(_from_rot, down.angle(), k)
			if _t >= RISE_TIME:
				_set_state("p_fall")
		"p_fall":
			var k := clampf(_t / FALL_TIME, 0.0, 1.0)
			position = hero.position + Vector2(0, 1)
			var top := ground + Vector2(0, -RISE_HEIGHT - SPEAR_LEN)
			_sprite.position = (top - global_position).lerp(ground + Vector2(0, -SPEAR_LEN) - global_position, k)
			_sprite.rotation = down.angle()
			if _t >= FALL_TIME:
				_sunrise_burst()
				_end_skill()


## Pierścień światła wokół postaci; 10. poziom i Mnożenie - kolejne rozbłyski; Południe - słup światła.
func _sunrise_burst() -> void:
	var at := hero.global_position
	var r := _sunrise_radius()
	var power := _power("p_sunrise")
	_ring_hits(at, r, power, "p_sunrise")
	_ring_fx(at, r)
	Fx.once(get_parent(), BEAM_FX, BEAM_FRAMES, BEAM_FPS * 1.4, at.round(), BEAM_ANCHOR, 3, 0.45)
	if _perk("p_sunrise", 1):
		_flashes.append({"at": at, "t": SUNRISE_SECOND, "radius": r, "power": power * SUNRISE_SECOND_POWER})
	if gem_power("p_sunrise", "multi") > 0.0:
		_flashes.append({"at": at, "t": SUNRISE_ECHO, "radius": r * SUNRISE_ECHO_AREA,
				"power": power * gem_power("p_sunrise", "multi") / 100.0})
	if _unique("p_sunrise"):
		var ghost := Sprite2D.new()
		ghost.texture = SPEAR_TEXTURE
		ghost.centered = false
		ghost.offset = -P_GRIP
		ghost.scale = Vector2.ONE * P_SCALE
		ghost.rotation = PI / 2.0
		ghost.modulate = Color(1.3, 1.15, 0.8, 0.8)
		ghost.z_index = 1
		get_parent().add_child(ghost)
		ghost.global_position = at + Vector2(0, -SPEAR_LEN - 2.0)
		_pillars.append({"node": ghost, "at": at, "left": PILLAR_TIME, "tick": PILLAR_TICK, "radius": r * PILLAR_RADIUS,
				"power": power * PILLAR_POWER})
	Input.vibrate_handheld(25)


func _process_flashes(delta: float) -> void:
	for f in _flashes.duplicate():
		f.t -= delta
		if f.t <= 0.0:
			_flashes.erase(f)
			if hero and not hero.dead:
				_ring_hits(f.at, f.radius, f.power, "p_sunrise")
				_ring_fx(f.at, f.radius)


func _process_pillars(delta: float) -> void:
	for p in _pillars.duplicate():
		p.left -= delta
		p.tick -= delta
		var node: Sprite2D = p.node
		if p.tick <= 0.0 and p.left > 0.0:
			p.tick = PILLAR_TICK
			_ring_hits(p.at, p.radius, p.power, "p_sunrise")
			_ring_fx(p.at, p.radius, 1)
		if p.left <= 0.0:
			if is_instance_valid(node):
				node.create_tween().tween_property(node, "modulate:a", 0.0, 0.3).finished.connect(node.queue_free)
			_pillars.erase(p)


## Ile słupów Południa stoi (testy).
func pillars() -> int:
	return _pillars.size()


# --- Kołowrót Słońca ---

func _wheel_radius() -> float:
	return WHEEL_RADIUS * _area("p_wheel")


## Jeden obrót: krok naprzód (jak Taniec Marzanny) i złoty okrąg cięcia wokół postaci.
func _spin_step() -> void:
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	if stick.length() > 0.2:
		_wheel_dir = stick.normalized()
	hero.leap(hero.global_position + _wheel_dir * WHEEL_STEP * _area("p_wheel"), WHEEL_SPIN_TIME)
	if not Fx.crowded(SPIN_FX, 12):
		var fx := Fx.once(hero, SPIN_FX, SPIN_FRAMES, SPIN_FPS * 1.6, hero.global_position + Vector2(0, -10),
				SPIN_ANCHOR, 3, _wheel_radius() / SPIN_FX_RADIUS)
		fx.scale.x *= -1.0 if spins_done % 2 else 1.0  # kolejne okręgi kręcą się w drugą stronę


## Włócznia wiruje nad głową; co WHEEL_TICK rani wokół; po obrotach - pierścień światła.
func _process_wheel(delta: float) -> void:
	position = hero.position + Vector2(0, -1)
	_sprite.position = _orbit_center() - global_position + Vector2(0, -14)
	_sprite.rotation += delta * TAU / WHEEL_SPIN_TIME
	_wheel_tick -= delta
	var radius := _wheel_radius()
	if _wheel_tick <= 0.0:
		_wheel_tick = WHEEL_TICK
		_ring_hits(hero.global_position, radius, _power("p_wheel") * WHEEL_SPIN_POWER, "p_wheel")
	if _t >= WHEEL_SPIN_TIME:
		spins_done += 1
		if spins_done >= _spins:
			_wheel_burst()
			_end_skill()
		else:
			_t = 0.0
			_spin_step()


## Pierścień światła od cięć: rani i odpycha wszystkich w zasięgu; Swarożyc - promienie; Mnożenie - drugi raz.
func _wheel_burst(power_mult := 1.0) -> void:
	var at := hero.global_position
	var reach := WHEEL_RING * _area("p_wheel") * (WHEEL_PERK_AREA if _perk("p_wheel", 0) else 1.0)
	var power := _power("p_wheel") * WHEEL_RING_POWER * power_mult
	for t in _ring_hits(at, reach, power, "p_wheel"):
		t.push_away(at, WHEEL_PUSH)
	_ring_fx(at, reach)
	if _unique("p_wheel") and power_mult == 1.0:
		for i in WHEEL_RAYS:
			var dir := Vector2.from_angle(TAU * i / WHEEL_RAYS + 0.2)
			var from := at + Vector2(0, -ORBIT_HEIGHT)
			for t in _line_targets(from, from + dir * WHEEL_RAY_REACH * _area("p_wheel"), THRUST_WIDTH):
				_hit(t, _power("p_wheel") * WHEEL_RAY_POWER, at, "p_wheel")
			_thrust_fx(from, dir, WHEEL_RAY_REACH * _area("p_wheel"))
	if gem_power("p_wheel", "multi") > 0.0 and power_mult == 1.0:
		get_tree().create_timer(WHEEL_ECHO).timeout.connect(func() -> void:
			if is_inside_tree() and hero and not hero.dead:
				_wheel_burst(gem_power("p_wheel", "multi") / 100.0))
	Input.vibrate_handheld(30)


# --- Zenit ---

## Planuje deszcz włóczni: najpierw na wrogów w zasięgu, potem w losowe miejsca; Dadźbóg - ogromna na końcu.
func _cast_zenith() -> void:
	var reach: float = Skills.DATA["p_zenith"].range * _area("p_zenith")
	var count := ZENITH_COUNT_PERK if _perk("p_zenith", 0) else ZENITH_COUNT
	var extra := ZENITH_EXTRA if gem_power("p_zenith", "multi") > 0.0 else 0
	var foes := _near(hero.global_position, reach)
	foes.shuffle()
	var power := _power("p_zenith")
	var radius := ZENITH_RADIUS * _area("p_zenith")
	for i in count + extra:
		var at: Vector2
		if i < foes.size():
			at = foes[i].global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
		else:
			var a := randf() * TAU
			at = hero.global_position + Vector2.from_angle(a) * randf_range(20.0, reach) * Vector2(1.0, 0.7)
		var p := power * (gem_power("p_zenith", "multi") / 100.0 if i >= count else 1.0)
		_add_drop(at, ZENITH_SPAN * i / float(count + extra), p, radius, false)
	if _unique("p_zenith"):
		var best: ProtoTarget = null
		for t in foes:
			if best == null or (_tough(t) and not _tough(best)) or (_tough(t) == _tough(best) and _hp_of(t) > _hp_of(best)):
				best = t
		var spot := best.global_position if best else hero.global_position + _aim_for(reach) * 50.0
		_add_drop(spot, ZENITH_SPAN + 0.2, power * ZENITH_BIG_POWER, ZENITH_BIG_RADIUS * _area("p_zenith"), true)


## Zdrowie celu (kukła go nie ma - 0).
static func _hp_of(t: ProtoTarget) -> int:
	return int(t.get("hp")) if "hp" in t else 0


func _add_drop(at: Vector2, delay: float, power: float, radius: float, big: bool) -> void:
	_drops.append({"at": at, "t": -delay, "power": power, "radius": radius, "big": big, "warn": null, "node": null,
			"hit": false, "left": 0.0, "tick": ZENITH_GLOW_TICK})


## Każda włócznia: złoty krąg ostrzeżenia, upadek z nieba, uderzenie w promieniu światła, potem chwilę tkwi w ziemi.
func _process_drops(delta: float) -> void:
	for d in _drops.duplicate():
		d.t += delta
		if d.t < 0.0:
			continue
		var scale_k: float = ZENITH_BIG_SCALE if d.big else 1.0
		if d.warn == null:
			d.warn = _warn_ring(d.at, d.radius)
			var node := Sprite2D.new()
			node.texture = SPEAR_TEXTURE
			node.centered = false
			node.offset = Vector2(-86.0, -P_GRIP.y)  # szpic w punkcie węzła
			node.scale = Vector2.ONE * P_SCALE * scale_k
			node.rotation = PI / 2.0
			node.z_index = 6
			node.visible = false
			get_parent().add_child(node)
			d.node = node
		var node: Sprite2D = d.node
		var fall_start: float = ZENITH_WARN
		if not d.hit:
			if d.t >= fall_start and is_instance_valid(node):
				node.visible = true
				var k := clampf((d.t - fall_start) / ZENITH_FALL, 0.0, 1.0)
				node.global_position = d.at + Vector2(0, -ZENITH_HEIGHT * (1.0 - k * k))
			if d.t >= fall_start + ZENITH_FALL:
				d.hit = true
				drops_done += 1
				_ring_hits(d.at, d.radius, d.power, "p_zenith")
				if not Fx.crowded(BEAM_FX, 16):
					Fx.once(get_parent(), BEAM_FX, BEAM_FRAMES, BEAM_FPS * 1.3, d.at.round(), BEAM_ANCHOR, 3,
							d.radius / BEAM_FX_RADIUS)
				if is_instance_valid(d.warn):
					(d.warn as Node).queue_free()
				d.left = ZENITH_GLOW if _perk("p_zenith", 1) else ZENITH_STUCK
				if is_instance_valid(node):
					node.global_position = d.at + Vector2(0, 4)  # grot wbity w ziemię
					if _perk("p_zenith", 1):
						node.modulate = Color(1.4, 1.25, 0.8)
				Input.vibrate_handheld(40 if d.big else 10)
			continue
		d.left -= delta
		if _perk("p_zenith", 1) and not d.big:  # 10. poziom: wbita włócznia świeci i rani wrogów obok
			d.tick -= delta
			if d.tick <= 0.0 and d.left > 0.0:
				d.tick = ZENITH_GLOW_TICK
				_ring_hits(d.at, ZENITH_GLOW_RADIUS * _area("p_zenith"), _power("p_zenith") * ZENITH_GLOW_POWER, "p_zenith")
		if d.left <= 0.0:
			if is_instance_valid(node):
				node.create_tween().tween_property(node, "modulate:a", 0.0, 0.25).finished.connect(node.queue_free)
			_drops.erase(d)


## Złoty krąg ostrzeżenia na ziemi (spłaszczony okrąg) - gaśnie, gdy włócznia uderzy.
func _warn_ring(at: Vector2, radius: float) -> Line2D:
	var line := Line2D.new()
	line.width = 1.5
	line.default_color = Color(GOLD, 0.8)
	line.closed = true
	line.z_index = -1
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius / 1.6))
	line.points = pts
	get_parent().add_child(line)
	line.global_position = at
	return line


## Ile włóczni Zenitu jeszcze czeka albo tkwi w ziemi (testy).
func drops_left() -> int:
	return _drops.size()

class_name ProtoRapier
extends ProtoWeapon
## Lodowy rapier - pierwsza broń lodu (ustalone z autorem 25.11.2026; Elements.COLD). Cienka klinga z lodu lewituje
## obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie, krytyki). Każde trafienie
## lodem spowalnia i dokłada znak chłodu, a Elements.CHILL_STACKS znaków zamraża wroga (ProtoTarget.chill, wspólne
## w ProtoWeapon._deal). **Roztrzaskanie** (`_hit`): zamrożony wróg trafiony rapierem pęka - lód znika, a sąsiedzi
## w SHATTER_RADIUS obrywają SHATTER_POWER tego trafienia (bez łańcucha roztrzaskań).
## Poprawki po pierwszym teście autora (25.11.2026): zwykły atak w cyklu z cięciami, krąg riposty, wypad do wroga,
## kamień Gradu z lecącymi kolcami, Rój Sopli zamiast Lodowego Kwiatu.
## Grafika assets/weapons/rapier.png (tools/rapier_art.py), ikony tools/rapier_icons.py, efekty z kreatora
## (pixellab_src/vfx/ids.json: rapier_*, riposte_*, icicle, ice_cloud, frost_shatter).
## - „Pchnięcie Szronu” (`r_thrust`, zwykły atak) w cyklu CYCLE: pchnięcie (rani wszystkich na linii), krótkie cięcie
##   w prawo (wrogowie w łuku przed postacią), pchnięcie, cięcie w lewo; 5. poziom - pchnięcia o połowę dalej, 10. -
##   lodowy kolec przy pierwszym trafionym pchnięciem; kamień unikalny (Sopli) - drugie pchnięcie cyklu wystrzeliwuje
##   sopel (`_icicles`); Mnożenie - drugi taki sam ruch w innego wroga.
## - „Wypad” (`r_lunge`): w stronę gałki do pierwszego wroga na drodze, bez gałki do najdalszego w zasięgu (bez wrogów -
##   pełny wypad naprzód); postać (ProtoHero.leap, nietykalna) zatrzymuje się LUNGE_STOP przed wrogiem i przebija go
##   pchnięciem, po drodze rani wszystkich i zostawia ścieżkę szronu (`_paths`); 5. - ścieżka dłużej, 10. - wybuch mrozu
##   przy wrogu; kamień unikalny (Zamieci) - drugi wypad za darmo przez LUNGE_FREE_TIME s.
## - „Riposta Morozka” (`r_riposte`): szronowy krąg na ziemi na CIRCLE_TIME s (`_circle`); postać w kręgu ma
##   RIPOSTE_CHANCE szansy (ProtoHero.parry_chance), że cios wroga zostanie odbity (sygnał `parried`) - wtedy kontra
##   pchnięciem w najbliższego wroga; 5. - krąg dłużej, 10. - sopel z każdej riposty; kamień unikalny (Mroźnej Riposty) -
##   większa szansa, a skontrowany wróg od razu zamarza.
## - „Grad Pchnięć” (`r_flurry`, trzymany - Skills.is_charged, `charge_held`): dopóki palec trzyma przycisk i starcza
##   many (koszt na sekundę), co FLURRY_EVERY s pchnięcie w losowym kierunku stożka; postać idzie wolniej
##   (ProtoHero.form_speed); 5. - szybciej, 10. - co piąte lodowy kolec na końcu; kamień unikalny (Gradu) - co
##   FLURRY_SPIKE_GEM s lecący kolec w losowego wroga.
## - „Rój Sopli” (`r_swarm`): chmura lodowych kolców za plecami postaci na SWARM_TIME s (`_cloud`) - co SWARM_EVERY s
##   sopel w losowego wroga w zasięgu; 5. - chmura dłużej, 10. - po dwa sople; Mnożenie - dodatkowy sopel w innego
##   wroga; kamień unikalny (Szronowej Mgły) - trafiony sopel rozpryskuje się szronem na wrogów obok.

const RAPIER_TEXTURE := preload("res://assets/weapons/rapier.png")
## Punkt chwytu w obrazku (środek owijki), skala w grze i długość od chwytu do szpica w grze (px).
const R_GRIP := Vector2(9.0, 10.0)
const R_SCALE := 0.5
const RAPIER_LEN := 29.0
const THRUST_FX := preload("res://assets/effects/rapier_thrust.png")
const THRUST_FRAMES := 7
const THRUST_ANCHOR := Vector2(5, 8)
const THRUST_FX_LEN := 52.0
const CUT_FX := preload("res://assets/effects/katana_cut.png")
const CUT_FRAMES := 9
const CUT_ANCHOR := Vector2(39, 46)
const CUT_FX_RADIUS := 40.0
const HIT_ICE_FX := preload("res://assets/effects/rapier_hit.png")
const HIT_ICE_FRAMES := 12
const HIT_ICE_ANCHOR := Vector2(23, 17)
const SPIKES_FX := preload("res://assets/effects/ice_spikes.png")
const SPIKES_FRAMES := 18
const SPIKES_ANCHOR := Vector2(30, 34)
const TRAIL_FX := preload("res://assets/effects/rapier_trail.png")
const TRAIL_FRAMES := 7
const TRAIL_ANCHOR := Vector2(8, 10)
const TRAIL_LEN := 64.0
const SHATTER_FX := preload("res://assets/effects/frost_shatter.png")
const SHATTER_FRAMES := 10
const SHATTER_ANCHOR := Vector2(31, 29)
const SHATTER_FX_RADIUS := 26.0
const ICE := Color(0.7, 0.93, 1.0)

## Roztrzaskanie zamrożonego wroga: zasięg i część obrażeń trafienia dla sąsiadów.
const SHATTER_RADIUS := 34.0
const SHATTER_POWER := 0.6
## Zwykły atak: cykl ruchów, czasy (cofnięcie, wysunięcie, powrót, przerwa - szybciej niż miecz), szerokość linii
## pchnięcia, cięcie (zasięg względem pchnięcia, łuk), 5. poziom (pchnięcia dalej), 10. (siła kolca), kamień Sopli.
const CYCLE := ["thrust", "right", "thrust", "left"]
const THRUST_WIND := 0.08
const THRUST_OUT := 0.06
const THRUST_BACK := 0.12
const THRUST_COOLDOWN := 0.36
const THRUST_WIDTH := 9.0
const THRUST_LONG := 1.5
const THRUST_SPIKE_POWER := 0.4
const SLASH_REACH := 0.75
const SLASH_ARC := deg_to_rad(120.0)
const ICICLE_RANGE := 200.0
const ICICLE_SPEED := 330.0
const ICICLE_POWER := 0.6
const ICICLE_HIT := 10.0
## Wypad: czas, szerokość pasa trafienia, szukanie wroga w stronę gałki (szerokość pasa), zatrzymanie przed wrogiem,
## siła końcowego pchnięcia, ścieżka szronu (czas, 5. poziom, spowolnienie, co ile), wybuch z 10. poziomu, odbicie
## z kamienia Mnożenie (odsunięcie), kamień Zamieci (czas na darmowy wypad).
const LUNGE_TIME := 0.18
const LUNGE_WIDTH := 14.0
const LUNGE_SEEK := 28.0
const LUNGE_STOP := 16.0
const LUNGE_FINISH := 1.0
const LUNGE_PATH_TIME := 2.0
const LUNGE_PATH_TIME_LONG := 4.0
const LUNGE_PATH_SLOW := 0.4
const LUNGE_PATH_TICK := 0.25
const LUNGE_BURST := 40.0
const LUNGE_BURST_POWER := 0.6
const LUNGE_MIRROR := 16.0
const LUNGE_FREE_TIME := 1.5
## Riposta Morozka: krąg (czas, 5. poziom, promień, spłaszczenie), szansa (kamień - więcej), kontra (zasięg), sopel
## z 10. poziomu.
const CIRCLE_TIME := 6.0
const CIRCLE_TIME_LONG := 9.0
const CIRCLE_RADIUS := 40.0
const CIRCLE_FLAT := 0.55
const RIPOSTE_CHANCE := 0.35
const RIPOSTE_CHANCE_GEM := 0.25
const COUNTER_RANGE := 70.0
const RIPOSTE_ICICLE_POWER := 0.6
## Grad Pchnięć: co ile pchnięcie (5. poziom), połowa kąta stożka, co ile mana, chód, kolec z 10. poziomu, kamień Gradu
## (co ile kolec, zasięg szukania, siła względem pchnięcia rapiera).
const FLURRY_EVERY := 0.12
const FLURRY_EVERY_PERK := 0.09
const FLURRY_CONE := 0.45
const FLURRY_MANA_EVERY := 0.5
const FLURRY_WALK := 0.6
const FLURRY_SPIKE_EVERY := 5
const FLURRY_SPIKE_POWER := 0.6
const FLURRY_GHOST_TURN := 0.18
const FLURRY_SPIKE_GEM := 0.3
const FLURRY_GEM_RANGE := 160.0
const FLURRY_GEM_POWER := 0.5
## Rój Sopli: czas (5. poziom), co ile sopel, miejsce chmury za plecami, kamień Szronowej Mgły (zasięg i siła rozprysku).
const SWARM_TIME := 8.0
const SWARM_TIME_LONG := 11.0
const SWARM_EVERY := 0.45
const CLOUD_BEHIND := 14.0
const CLOUD_HEIGHT := 34.0
const SPLASH_RADIUS := 30.0
const SPLASH_POWER := 0.3
const SPIKE_RADIUS := 16.0

## Ile ataków padło (cykl CYCLE), ile roztrzaskań, ile ripost w kręgu, ile pchnięć gradu i sopli roju (testy).
var thrust_count := 0
var shatters := 0
var ripostes := 0
var flurry_thrusts := 0
var swarm_shots := 0
var _move := "thrust"
var _aim_dir := Vector2.RIGHT
var _shattering := false
var _lunge_from := Vector2.ZERO
var _lunge_target: ProtoTarget
var _lunge_hits: Array = []
var _lunge_mirror_hits: Array = []
var _lunge_free := 0.0
var _flurry_t := 0.0
var _flurry_mana_t := 0.0
var _flurry_gem_t := 0.0
var _swarm_t := 0.0
## Krąg riposty ({"node", "at", "radius", "left"}; pusty - brak) i chmura roju ({"node", "left"}).
var _circle := {}
var _cloud := {}
## Lecące sople ({"node", "dir", "left", "power", "hits", "skill"}) i ścieżki szronu ({"node", "a", "b", "left",
## "tick"}).
var _icicles: Array = []
var _paths: Array = []


func _init() -> void:
	basic = "r_thrust"
	main_skill = "r_thrust"
	element = Elements.COLD
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = RAPIER_TEXTURE
		s.offset = -R_GRIP
		s.scale = Vector2.ONE * R_SCALE
	_connect_parry()


func _world_fx() -> Array:
	return super._world_fx() + [_icicles, _paths, _circle, _cloud]


func _exit_tree() -> void:
	if hero:
		if hero.form_speed != 1.0 and _state == "r_flurry":
			hero.form_speed = 1.0
		hero.parry_chance = 0.0
	super._exit_tree()


func _connect_parry() -> void:
	if hero and not hero.parried.is_connected(_on_parried):
		hero.parried.connect(_on_parried)


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"r_wind", "r_out", "r_back":
			_process_attack()
		"r_lunge":
			_process_lunge()
		"r_flurry":
			_process_flurry(delta)
	if _lunge_free > 0.0:
		_lunge_free -= delta
		if _lunge_free <= 0.0:  # Zamieć: czas na darmowy wypad minął - zwykłe odnowienie
			_cd["r_lunge"] = maxf(cooldown_full("r_lunge") - LUNGE_FREE_TIME, 0.0)
	_process_circle(delta)
	_process_cloud(delta)
	_process_icicles(delta)
	_process_paths(delta)


# --- Trafienia, roztrzaskanie ---

## Trafienie umiejętnością `skill` z siłą `power`; zamrożony wróg pęka (roztrzaskanie).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	var frozen := t.is_frozen()
	var amount := _roll(power)
	_deal(t, amount, from, skill)
	if frozen and not _shattering:
		_shatter(t, amount, skill)


## Roztrzaskanie: lód pęka z odłamkami, sąsiedzi w SHATTER_RADIUS dostają SHATTER_POWER trafienia (lodem, ze
## znakami chłodu - ale bez kolejnego roztrzaskania).
func _shatter(t: ProtoTarget, amount: int, skill: String) -> void:
	t.thaw()
	shatters += 1
	var at := t.global_position
	var radius := SHATTER_RADIUS * _area(skill)
	Fx.once(get_parent(), SHATTER_FX, SHATTER_FRAMES, 18.0, at.round(), SHATTER_ANCHOR, 21, radius / SHATTER_FX_RADIUS * 0.6)
	_shattering = true
	for o in _near(at, radius):
		if o != t:
			var d := o.global_position - at
			if Vector2(d.x, d.y * 1.6).length() <= radius:
				_deal(o, maxi(1, roundi(amount * SHATTER_POWER)), at, skill)
	_shattering = false
	Input.vibrate_handheld(14)


## Wszyscy w kole `radius` wokół `at` (spłaszczonym jak cienie). Zwraca trafionych.
func _ring_hits(at: Vector2, radius: float, power: float, skill: String) -> Array:
	var hit: Array = []
	for t in _near(at, radius):
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


func _hit_fx(at: Vector2) -> void:
	Fx.once(get_parent(), HIT_ICE_FX, HIT_ICE_FRAMES, 20.0, at.round(), HIT_ICE_ANCHOR)


## Lodowy kolec w `spot`: rani wrogów obok i mocno schładza.
func _ice_spike(spot: Vector2, power: float, skill: String, size := 0.8) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	Fx.once(get_parent(), SPIKES_FX, SPIKES_FRAMES, 18.0, spot.round(), SPIKES_ANCHOR, 2, size)
	for t in _ring_hits(spot, SPIKE_RADIUS * _area(skill), power, skill):
		t.chill()


## Smuga pchnięcia od `from` w kierunku `dir` na długość `length`.
func _thrust_fx(from: Vector2, dir: Vector2, length: float) -> void:
	var fx := Fx.once(get_parent(), THRUST_FX, THRUST_FRAMES, 30.0, from.round(), THRUST_ANCHOR, 21)
	fx.rotation = dir.angle()
	fx.scale = Vector2(length / THRUST_FX_LEN, 0.9)


## Rapier wysunięty w kierunku `dir` o `out` px od środka orbity (szpic do przodu).
func _point(dir: Vector2, out: float) -> void:
	position = hero.position + Vector2(0, -1.0 if dir.y < -0.2 else 1.0)
	_sprite.position = _orbit_center() - global_position + dir * out
	_sprite.rotation = dir.angle()


# --- Pchnięcie Szronu (zwykły atak w cyklu) ---

## Ruch cyklu dla ataku nr `count` (od 1): "thrust", "right" albo "left".
static func cycle_move(count: int) -> String:
	return CYCLE[(count - 1) % CYCLE.size()]


func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		thrust_count += 1
		_move = cycle_move(thrust_count)
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	var reach: float = Skills.DATA[basic].range * _area(basic)
	var best: ProtoTarget = null
	if second:  # Mnożenie: drugi taki sam ruch w innego wroga (bez niego - w to samo miejsce)
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
	_set_state("r_wind")
	hero.play_gesture(_orbit_center() + _aim_dir * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _thrust_reach() -> float:
	return Skills.DATA[basic].range * _area(basic) * (THRUST_LONG if _perk(basic, 0) else 1.0)


## Kierunek ostrza w chwili `k` (0-1) ruchu: pchnięcie - prosto w cel, cięcie - po łuku SLASH_ARC (w prawo zgodnie
## z ruchem wskazówek zegara, w lewo - przeciwnie).
func _blade_dir(k: float) -> Vector2:
	if _move == "thrust":
		return _aim_dir
	var side := 1.0 if _move == "right" else -1.0
	return _aim_dir.rotated(lerpf(-SLASH_ARC / 2.0, SLASH_ARC / 2.0, k) * side)


func _process_attack() -> void:
	var slash := _move != "thrust"
	match _state:
		"r_wind":
			var k := ease(clampf(_t / THRUST_WIND, 0.0, 1.0), -2.0)
			var dir := _blade_dir(-0.05)
			_point(dir, 8.0 if slash else 2.0)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, dir.angle(), k)
			if _t >= THRUST_WIND:
				_set_state("r_out")
		"r_out":
			var k := clampf(_t / THRUST_OUT, 0.0, 1.0)
			if slash:
				_point(_blade_dir(ease(k, 0.5)), 10.0)
			else:
				_point(_aim_dir, lerpf(2.0, 22.0, k))
			if not _hit_done and k >= 0.5:
				_hit_done = true
				if slash:
					_slash_hit()
				else:
					_thrust_hit()
			if _t >= THRUST_OUT:
				_set_state("r_back")
		"r_back":
			var k := clampf(_t / THRUST_BACK, 0.0, 1.0)
			if slash:
				_point(_blade_dir(1.0), lerpf(10.0, 6.0, k))
			else:
				_point(_aim_dir, lerpf(22.0, 6.0, k))
			if _t >= THRUST_BACK:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = THRUST_COOLDOWN


## Trafienie pchnięciem: wszyscy na linii; 10. - kolec przy pierwszym trafionym; Sople - drugie pchnięcie cyklu.
func _thrust_hit() -> void:
	var from := _orbit_center()
	var reach := _thrust_reach()
	var power := _swing_power * _power(basic)
	var hit := _line_targets(from, from + _aim_dir * reach, THRUST_WIDTH * _area(basic))
	for t in hit:
		_hit(t, power, hero.global_position, basic)
		_hit_fx(t.center())
	_thrust_fx(from, _aim_dir, reach)
	if not hit.is_empty() and _perk(basic, 1) and not _second:
		var first: ProtoTarget = hit[0]
		for t in hit:
			if t.global_position.distance_to(from) < first.global_position.distance_to(from):
				first = t
		_ice_spike(first.global_position, power * THRUST_SPIKE_POWER, basic)
	if _unique(basic) and not _second and (thrust_count - 1) % CYCLE.size() == 2:
		_launch_icicle(from, _aim_dir, _power(basic) * ICICLE_POWER, basic)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


## Trafienie krótkim cięciem: wrogowie w łuku SLASH_ARC przed postacią, w zasięgu SLASH_REACH pchnięcia.
func _slash_hit() -> void:
	var c := _orbit_center()
	var reach: float = Skills.DATA[basic].range * SLASH_REACH * _area(basic)
	var power := _swing_power * _power(basic)
	var hit := false
	for t in _near_c(c, reach):
		var to := t.center() - c
		if to.length() <= reach and absf(angle_difference(_aim_dir.angle(), to.angle())) <= SLASH_ARC / 2.0:
			_hit(t, power, hero.global_position, basic)
			_hit_fx(t.center())
			hit = true
	var fx := Fx.once(get_parent(), CUT_FX, CUT_FRAMES, 36.0, c.round(), CUT_ANCHOR, 21, reach / CUT_FX_RADIUS)
	fx.rotation = _aim_dir.angle()
	fx.flip_v = _move == "left"
	fx.modulate = Color(0.85, 1.0, 1.1)
	if hit:
		Input.vibrate_handheld(10)


# --- Sople (kamień Sopli, Riposta, Grad, Rój) ---

func _launch_icicle(from: Vector2, dir: Vector2, power: float, skill: String, distance := ICICLE_RANGE) -> void:
	var node := _Icicle.new()
	node.rotation = dir.angle()
	node.z_index = 21
	get_parent().add_child(node)
	node.global_position = from
	_icicles.append({"node": node, "dir": dir, "left": distance, "power": power, "hits": [], "skill": skill})


## Sopel w losowego wroga w zasięgu `reach` od `from` (poza `skip`). Zwraca wroga, w którego leci (null - brak wrogów).
func _icicle_at_random(from: Vector2, reach: float, power: float, skill: String, skip: Array = []) -> ProtoTarget:
	var near: Array = []
	for t in _near(from, reach):
		if not skip.has(t):
			near.append(t)
	if near.is_empty():
		return null
	var t: ProtoTarget = near.pick_random()
	var to := t.center() - from
	_launch_icicle(from, to.normalized(), power, skill, to.length() + 40.0)
	return t


func _process_icicles(delta: float) -> void:
	for ic in _icicles.duplicate():
		var node: Node2D = ic.node
		var step := ICICLE_SPEED * delta
		var a := node.global_position
		node.global_position += ic.dir * step
		ic.left -= step
		for t in _line_targets(a, node.global_position, ICICLE_HIT, ic.hits):
			ic.hits.append(t)
			_hit(t, ic.power, a, ic.skill)
			_hit_fx(t.center())
			if ic.skill == "r_swarm" and _unique("r_swarm"):
				_frost_splash(t, ic.power)
		if ic.left <= 0.0:
			node.queue_free()
			_icicles.erase(ic)


## Kamień Szronowej Mgły: trafiony sopel rozpryskuje się - wrogowie obok dostają 2 znaki chłodu i część siły sopla.
func _frost_splash(t: ProtoTarget, power: float) -> void:
	for o in _near(t.global_position, SPLASH_RADIUS):
		if o != t:
			_hit(o, power * SPLASH_POWER, t.global_position, "r_swarm")
			o.chill(Elements.CHILL_SLOW, Elements.CHILL_TIME, 2)


## Ile sopli leci (testy).
func icicles() -> int:
	return _icicles.size()


# --- Umiejętności ---

func cooldown_full(id: String) -> float:
	if id == "r_flurry":
		return 0.0
	return super.cooldown_full(id)


func mana_cost(id: String) -> int:
	if id == "r_lunge" and _lunge_free > 0.0:
		return 0  # Zamieć: drugi wypad za darmo
	return super.mana_cost(id)


func can_use(id: String) -> bool:
	if id == "r_flurry":
		return Skills.has(id) and not hero.dead and hero.can_pay(_flurry_tick_cost())
	return super.can_use(id)


func _start(id: String) -> void:
	if id == basic or not id in ["r_lunge", "r_riposte", "r_flurry", "r_swarm"]:
		super._start(id)
		return
	if not can_use(id):
		return
	var free := id == "r_lunge" and _lunge_free > 0.0
	if id != "r_flurry":
		if not hero.spend_mana(mana_cost(id)):
			return
		_cd[id] = cooldown_full(id)
	_hit_done = false
	match id:
		"r_lunge":
			if free:
				_lunge_free = 0.0
			elif _unique(id):  # Zamieć: przez chwilę drugi wypad bez odnowienia i many
				_lunge_free = LUNGE_FREE_TIME
				_cd[id] = 0.0
			_start_lunge()
		"r_riposte":
			_place_circle()
		"r_flurry":
			flurry_thrusts = 0
			_flurry_t = 0.0
			_flurry_mana_t = 0.0
			_flurry_gem_t = FLURRY_SPIKE_GEM
			hero.form_speed = FLURRY_WALK
			_set_state("r_flurry")
		"r_swarm":
			_summon_cloud()
	skill_used.emit(id)


func _end_skill() -> void:
	if _state == "r_flurry" and hero:
		hero.form_speed = 1.0
	super._end_skill()


# --- Wypad ---

## Cel wypadu: w stronę gałki `dir` pierwszy wróg na drodze (w pasie LUNGE_SEEK), bez gałki najdalszy w zasięgu.
func _lunge_target_for(stick: Vector2, reach: float) -> ProtoTarget:
	if stick.length() <= 0.2:
		return _farthest(reach)
	var dir := stick.normalized()
	var best: ProtoTarget = null
	var best_d := reach
	for t in _near(hero.global_position, reach):
		var to := t.global_position - hero.global_position
		var along := to.dot(dir)
		if along > 0.0 and along <= best_d and absf(to.cross(dir)) <= LUNGE_SEEK:
			best = t
			best_d = along
	return best


func _start_lunge() -> void:
	var reach: float = Skills.DATA.r_lunge.range * _area("r_lunge")
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	_lunge_target = _lunge_target_for(stick, reach)
	var dir: Vector2
	var dest: Vector2
	if _lunge_target:
		var to := _lunge_target.global_position - hero.global_position
		dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
		dest = hero.global_position + dir * maxf(to.length() - LUNGE_STOP, 0.0)  # zatrzymanie przed wrogiem
	else:
		dir = stick.normalized() if stick.length() > 0.2 else (hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT)
		dest = hero.global_position + dir * reach
	_aim_dir = dir
	_lunge_from = hero.global_position
	_lunge_hits = [_lunge_target] if _lunge_target else []
	_lunge_mirror_hits = []
	hero.leap(dest, LUNGE_TIME, 0.0)
	hero.protect(LUNGE_TIME + 0.08)
	hero.play_gesture(hero.global_position + dir * 20.0)
	var length := maxf(_lunge_from.distance_to(dest), 20.0)
	var fx := Fx.once(get_parent(), TRAIL_FX, TRAIL_FRAMES, 30.0, (_lunge_from + Vector2(0, -ORBIT_HEIGHT)).round(), TRAIL_ANCHOR, 21)
	fx.rotation = dir.angle()
	fx.scale = Vector2(length / TRAIL_LEN, 1.0)
	_set_state("r_lunge")


func _process_lunge() -> void:
	_point(_aim_dir, 18.0)
	var power := _power("r_lunge")
	var a := _lunge_from + Vector2(0, -ORBIT_HEIGHT)
	var b := hero.global_position + Vector2(0, -ORBIT_HEIGHT) + _aim_dir * 18.0
	var width := LUNGE_WIDTH * _area("r_lunge")
	for t in _line_targets(a, b, width, _lunge_hits):
		_lunge_hits.append(t)
		_hit(t, power, hero.global_position, "r_lunge")
		_hit_fx(t.center())
	var mirror := gem_power("r_lunge", "multi") / 100.0
	if mirror > 0.0:  # Mnożenie: lodowe odbicie leci obok i też przebija
		var side := _aim_dir.orthogonal() * LUNGE_MIRROR
		for t in _line_targets(a + side, b + side, width, _lunge_mirror_hits):
			_lunge_mirror_hits.append(t)
			_hit(t, power * mirror, hero.global_position, "r_lunge")
	if _t >= LUNGE_TIME and not hero.leaping():
		_lunge_land()
		_end_skill()


## Koniec wypadu: pchnięcie w wroga, przed którym postać stanęła, ścieżka szronu; 10. poziom - wybuch mrozu przy wrogu.
func _lunge_land() -> void:
	var end := hero.global_position
	var focus := end + _aim_dir * LUNGE_STOP
	if _lunge_target and is_instance_valid(_lunge_target) and _lunge_target.alive():
		focus = _lunge_target.global_position
		_hit(_lunge_target, _power("r_lunge") * LUNGE_FINISH, end, "r_lunge")
		_hit_fx(_lunge_target.center())
		_thrust_fx(_orbit_center(), _aim_dir, _lunge_target.center().distance_to(_orbit_center()) + 10.0)
	var node := _FrostPath.new()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO
	node.a = _lunge_from
	node.b = end
	node.queue_redraw()
	var time := LUNGE_PATH_TIME_LONG if _perk("r_lunge", 0) else LUNGE_PATH_TIME
	_paths.append({"node": node, "a": _lunge_from, "b": end, "left": time, "tick": 0.0})
	if _perk("r_lunge", 1):
		var radius := LUNGE_BURST * _area("r_lunge")
		for t in _ring_hits(focus, radius, _power("r_lunge") * LUNGE_BURST_POWER, "r_lunge"):
			t.chill(Elements.CHILL_SLOW, Elements.CHILL_TIME, 2)
		Fx.once(get_parent(), SHATTER_FX, SHATTER_FRAMES, 18.0, focus.round(), SHATTER_ANCHOR, 21, radius / SHATTER_FX_RADIUS * 0.6)
	_lunge_target = null
	Input.vibrate_handheld(20)


func _process_paths(delta: float) -> void:
	for p in _paths.duplicate():
		p.left -= delta
		p.tick -= delta
		var node: Node2D = p.node
		node.modulate.a = clampf(p.left / 0.5, 0.0, 1.0)
		if p.tick <= 0.0:
			p.tick = LUNGE_PATH_TICK
			for t in _line_targets(p.a, p.b, LUNGE_WIDTH * _area("r_lunge")):
				t.slow(LUNGE_PATH_SLOW, LUNGE_PATH_TICK + 0.3)
		if p.left <= 0.0:
			node.queue_free()
			_paths.erase(p)


## Ile ścieżek szronu leży na ziemi (testy).
func frost_paths() -> int:
	return _paths.size()


# --- Riposta Morozka (krąg) ---

func _circle_radius() -> float:
	return CIRCLE_RADIUS * _area("r_riposte")


## Szansa na ripostę w kręgu (kamień Mroźnej Riposty - więcej).
func riposte_chance() -> float:
	return RIPOSTE_CHANCE + (RIPOSTE_CHANCE_GEM if _unique("r_riposte") else 0.0)


## Stawia szronowy krąg pod postacią (nowy zastępuje stary).
func _place_circle() -> void:
	_clear_circle()
	var node := _RiposteCircle.new()
	node.radius = _circle_radius()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = hero.global_position
	_circle = {"node": node, "at": hero.global_position, "radius": node.radius,
			"left": CIRCLE_TIME_LONG if _perk("r_riposte", 0) else CIRCLE_TIME}


func _clear_circle() -> void:
	if not _circle.is_empty() and is_instance_valid(_circle.node):
		_circle.node.queue_free()
	_circle = {}
	if hero:
		hero.parry_chance = 0.0


## Czy postać stoi w kręgu riposty.
func in_circle() -> bool:
	if _circle.is_empty() or hero == null:
		return false
	var at: Vector2 = _circle.at
	var d := hero.global_position - at
	return Vector2(d.x, d.y / CIRCLE_FLAT).length() <= float(_circle.radius)


func _process_circle(delta: float) -> void:
	if _circle.is_empty():
		return
	_circle.left -= delta
	var node: Node2D = _circle.node
	node.modulate.a = clampf(_circle.left / 0.5, 0.0, 1.0)
	hero.parry_chance = riposte_chance() if in_circle() and not hero.dead else 0.0
	if _circle.left <= 0.0:
		_clear_circle()


## Ile sekund zostało kręgowi (0 - brak; testy).
func circle_left() -> float:
	return 0.0 if _circle.is_empty() else float(_circle.left)


## Cios odbity w kręgu: kontra pchnięciem w najbliższego wroga (Mnożenie - dwa razy, kamień - zamraża), 10. - sopel.
func _on_parried() -> void:
	if not in_circle():
		return
	ripostes += 1
	var best := _nearest(COUNTER_RANGE * _area("r_riposte"))
	if best == null:
		return
	var dir := (best.center() - _orbit_center()).normalized()
	var power := _power("r_riposte")
	_hit(best, power, hero.global_position, "r_riposte")
	var extra := gem_power("r_riposte", "multi") / 100.0
	if extra > 0.0 and best.alive():
		_hit(best, power * extra, hero.global_position, "r_riposte")
	if _unique("r_riposte") and best.alive():
		best.freeze(Elements.CHILL_FREEZE)
	_thrust_fx(_orbit_center(), dir, best.center().distance_to(_orbit_center()) + 6.0)
	_hit_fx(best.center())
	if _perk("r_riposte", 1):
		_launch_icicle(_orbit_center(), dir, _power("r_riposte") * RIPOSTE_ICICLE_POWER, "r_riposte")


# --- Grad Pchnięć (trzymany) ---

func _flurry_every() -> float:
	return FLURRY_EVERY_PERK if _perk("r_flurry", 0) else FLURRY_EVERY


## Mana za FLURRY_MANA_EVERY s gradu (koszt umiejętności jest na sekundę).
func _flurry_tick_cost() -> int:
	return maxi(1, ceili(mana_cost("r_flurry") * FLURRY_MANA_EVERY))


func _process_flurry(delta: float) -> void:
	_flurry_mana_t -= delta
	if _flurry_mana_t <= 0.0:
		_flurry_mana_t = FLURRY_MANA_EVERY
		if not hero.spend_mana(_flurry_tick_cost()):
			cast_failed.emit("r_flurry", "mana")
			_end_skill()
			return
	var reach: float = Skills.DATA.r_flurry.range * _area("r_flurry")
	var best := _nearest(reach)
	if best:
		_aim_dir = (best.center() - _orbit_center()).normalized()
	elif hero.facing.length() > 0.1:
		_aim_dir = hero.facing.normalized()
	_flurry_t -= delta
	var k := clampf(1.0 - _flurry_t / _flurry_every(), 0.0, 1.0)
	_point(_aim_dir, lerpf(20.0, 4.0, k))
	if _flurry_t <= 0.0:
		_flurry_t = _flurry_every()
		_flurry_thrust(reach)
	if _unique("r_flurry"):  # Kamień Gradu: lecące kolce w losowych wrogów
		_flurry_gem_t -= delta
		if _flurry_gem_t <= 0.0:
			_flurry_gem_t = FLURRY_SPIKE_GEM
			_icicle_at_random(_orbit_center(), FLURRY_GEM_RANGE, _power(basic) * FLURRY_GEM_POWER, "r_flurry")
	if not charge_held or hero.dead:
		_end_skill()


## Jedno pchnięcie gradu w losowym kierunku stożka; Mnożenie - widmowe obok; 10. - kolec.
func _flurry_thrust(reach: float) -> void:
	flurry_thrusts += 1
	var from := _orbit_center()
	var dir := _aim_dir.rotated(randf_range(-FLURRY_CONE, FLURRY_CONE))
	var power := _power("r_flurry")
	var length := reach * randf_range(0.8, 1.0)
	var hit := _line_targets(from, from + dir * length, THRUST_WIDTH * _area("r_flurry"))
	for t in hit:
		_hit(t, power, hero.global_position, "r_flurry")
	_thrust_fx(from, dir, length)
	var extra := gem_power("r_flurry", "multi") / 100.0
	if extra > 0.0:
		var ghost := dir.rotated(FLURRY_GHOST_TURN * (1.0 if flurry_thrusts % 2 else -1.0))
		for t in _line_targets(from, from + ghost * length, THRUST_WIDTH * _area("r_flurry")):
			_hit(t, power * extra, hero.global_position, "r_flurry")
	if _perk("r_flurry", 1) and flurry_thrusts % FLURRY_SPIKE_EVERY == 0:
		_ice_spike(from + dir * length + Vector2(0, ORBIT_HEIGHT), _power("r_flurry") * FLURRY_SPIKE_POWER / Skills.DATA.r_flurry.power, "r_flurry")
	if not hit.is_empty():
		Input.vibrate_handheld(6)


# --- Rój Sopli ---

## Miejsce chmury: za plecami postaci, nad jej głową.
func _cloud_spot() -> Vector2:
	var back := -hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.LEFT
	return hero.global_position + back * CLOUD_BEHIND + Vector2(0, -CLOUD_HEIGHT)


func _summon_cloud() -> void:
	if not _cloud.is_empty() and is_instance_valid(_cloud.node):
		_cloud.node.queue_free()
	var node := _Cloud.new()
	node.z_index = 22
	get_parent().add_child(node)
	node.global_position = _cloud_spot()
	_cloud = {"node": node, "left": SWARM_TIME_LONG if _perk("r_swarm", 0) else SWARM_TIME}
	_swarm_t = 0.15


func _process_cloud(delta: float) -> void:
	if _cloud.is_empty():
		return
	_cloud.left -= delta
	var node: Node2D = _cloud.node
	node.global_position = node.global_position.lerp(_cloud_spot(), 1.0 - exp(-6.0 * delta))
	node.modulate.a = clampf(_cloud.left / 0.5, 0.0, 1.0)
	_swarm_t -= delta
	if _swarm_t <= 0.0 and not hero.dead:
		_swarm_t = SWARM_EVERY
		var reach: float = Skills.DATA.r_swarm.range * _area("r_swarm")
		var power := _power("r_swarm")
		var used: Array = []
		for i in (2 if _perk("r_swarm", 1) else 1):
			var t := _icicle_at_random(node.global_position, reach, power, "r_swarm", used)
			if t:
				used.append(t)
				swarm_shots += 1
		var extra := gem_power("r_swarm", "multi") / 100.0
		if extra > 0.0 and not used.is_empty():
			_icicle_at_random(node.global_position, reach, power * extra, "r_swarm", used)
	if _cloud.left <= 0.0:
		node.queue_free()
		_cloud = {}


## Ile sekund zostało chmurze (0 - brak; testy).
func cloud_left() -> float:
	return 0.0 if _cloud.is_empty() else float(_cloud.left)


## Sopel: wydłużony, bladobłękitny kryształ z białym rdzeniem (szpic w prawo).
class _Icicle extends Node2D:
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -2), Vector2(4, -2), Vector2(10, 0), Vector2(4, 2),
				Vector2(-9, 2)]), Color(0.55, 0.85, 1.0, 0.9))
		draw_line(Vector2(-8, -1), Vector2(7, 0), Color(0.95, 1.0, 1.0), 1.0)


## Ścieżka szronu wypadu: szeroki, bladobłękitny pas z białymi kryształkami.
class _FrostPath extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO

	func _draw() -> void:
		draw_line(a, b, Color(0.7, 0.92, 1.0, 0.35), 10.0)
		draw_line(a, b, Color(0.9, 0.98, 1.0, 0.45), 3.0)
		var n := maxi(2, int(a.distance_to(b) / 12.0))
		var side := (b - a).orthogonal().normalized()
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n) + side * (4.0 if i % 2 else -4.0)
			draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(0.95, 1.0, 1.0, 0.8))


## Krąg Riposty Morozka: spłaszczony szronowy krąg z wirującymi kryształkami.
class _RiposteCircle extends Node2D:
	var radius := 40.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, CIRCLE_FLAT))
		draw_circle(Vector2.ZERO, radius, Color(0.6, 0.85, 1.0, 0.1))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.8, 0.96, 1.0, 0.75), 1.5)
		draw_arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 40, Color(0.7, 0.9, 1.0, 0.35), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 8:
			var a := _t * 0.8 + TAU * i / 8.0
			var p := Vector2(cos(a), sin(a) * CIRCLE_FLAT) * radius
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(2, 0), p + Vector2(0, 3),
					p + Vector2(-2, 0)]), Color(0.92, 0.99, 1.0, 0.95))


## Chmura Roju Sopli: kłąb mroźnej mgły z wiszącymi soplami.
class _Cloud extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 5:
			var p := Vector2((i - 2) * 6.0, sin(_t * 2.0 + i) * 1.5)
			draw_circle(p, 6.0 - absf(i - 2.0), Color(0.75, 0.92, 1.0, 0.55))
		for i in 4:
			var x := (i - 1.5) * 7.0
			var y := 4.0 + sin(_t * 3.0 + i * 1.7) * 1.5
			draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, y), Vector2(x + 1.5, y), Vector2(x, y + 7.0)]),
					Color(0.85, 0.97, 1.0, 0.95))

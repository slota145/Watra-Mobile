class_name ProtoRapier
extends ProtoWeapon
## Lodowy rapier - pierwsza broń lodu (ustalone z autorem 25.11.2026; Elements.COLD). Cienka klinga z lodu lewituje
## obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie, krytyki). Każde trafienie
## lodem spowalnia i dokłada znak chłodu, a Elements.CHILL_STACKS znaków zamraża wroga (ProtoTarget.chill, wspólne
## w ProtoWeapon._deal). **Roztrzaskanie** (`_hit`): zamrożony wróg trafiony rapierem pęka - lód znika, a sąsiedzi
## w SHATTER_RADIUS obrywają SHATTER_POWER tego trafienia (bez łańcucha roztrzaskań).
## Grafika assets/weapons/rapier.png (tools/rapier_art.py), ikony tools/rapier_icons.py, efekty z kreatora przebarwione
## na lód (pixellab_src/vfx/ids.json: rapier_thrust, ice_spikes, rapier_hit, rapier_trail) i frost_shatter.
## - „Pchnięcie Szronu” (`r_thrust`, zwykły atak): szybkie, długie pchnięcie w najbliższego wroga - rani wszystkich na
##   linii; 5. poziom - co trzecie sięga dwa razy dalej, 10. - lodowy kolec w miejscu trafienia; kamień unikalny
##   (Sopli) - co THRUST_ICICLE_EVERY pchnięcie sopel leci daleko i przebija (`_icicles`).
## - „Wypad” (`r_lunge`): błyskawiczny wypad (ProtoHero.leap, nietykalny) w stronę gałki albo najbliższego wroga, przebija
##   wszystkich po drodze, zostawia ścieżkę szronu (`_paths` - spowalnia); 5. - ścieżka dłużej, 10. - wybuch mrozu na
##   końcu; kamień unikalny (Zamieci) - drugi wypad za darmo przez LUNGE_FREE_TIME s.
## - „Riposta Morozka” (`r_riposte`): zasłona (ProtoHero.parry_left odnawiane co klatkę) - każdy cios odbity i kontra
##   pchnięciem w najbliższego wroga; na koniec mróz wybucha dookoła i zamraża wszystkich; 5. - dłuższa zasłona,
##   10. - każde odbicie wystrzeliwuje sopel; kamień unikalny (Lodowego Pancerza) - po zasłonie mniej obrażeń
##   (ProtoHero.fortify).
## - „Grad Pchnięć” (`r_flurry`, trzymany - Skills.is_charged, `charge_held`): dopóki palec trzyma przycisk i starcza
##   many (koszt na sekundę), co FLURRY_EVERY s pchnięcie w losowym kierunku stożka; postać idzie wolniej
##   (ProtoHero.form_speed); 5. - szybciej, 10. - co piąte lodowy kolec na końcu; kamień unikalny (Gradu) - 2 znaki
##   chłodu.
## - „Lodowy Kwiat” (`r_bloom`): rapier wbija się w ziemię, pierścieniem wyrastają kryształy - ranią i mocno schładzają;
##   5. - większy, 10. - drugi, szerszy pierścień; kamień unikalny (Wiecznej Zmarzliny) - kryształy zostają (`_fields`).

const RAPIER_TEXTURE := preload("res://assets/weapons/rapier.png")
## Punkt chwytu w obrazku (środek owijki), skala w grze i długość od chwytu do szpica w grze (px).
const R_GRIP := Vector2(9.0, 10.0)
const R_SCALE := 0.5
const RAPIER_LEN := 29.0
const THRUST_FX := preload("res://assets/effects/rapier_thrust.png")
const THRUST_FRAMES := 7
const THRUST_ANCHOR := Vector2(5, 8)
const THRUST_FX_LEN := 52.0
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
const ICE_WHITE := Color(0.92, 0.99, 1.0)

## Roztrzaskanie zamrożonego wroga: zasięg i część obrażeń trafienia dla sąsiadów.
const SHATTER_RADIUS := 34.0
const SHATTER_POWER := 0.6
## Pchnięcie: czasy (cofnięcie, wysunięcie, powrót, przerwa - szybciej niż miecz), szerokość linii trafienia, 5. poziom
## (co które, ile razy dalej), 10. (siła kolca), kamień Sopli (co które, zasięg, prędkość, siła).
const THRUST_WIND := 0.08
const THRUST_OUT := 0.06
const THRUST_BACK := 0.12
const THRUST_COOLDOWN := 0.36
const THRUST_WIDTH := 9.0
const THRUST_LONG_EVERY := 3
const THRUST_LONG := 2.0
const THRUST_SPIKE_POWER := 0.4
const THRUST_ICICLE_EVERY := 4
const ICICLE_RANGE := 200.0
const ICICLE_SPEED := 330.0
const ICICLE_POWER := 0.6
const ICICLE_HIT := 10.0
## Wypad: czas, szerokość pasa trafienia, ścieżka szronu (czas, 5. poziom, spowolnienie, co ile), wybuch z 10. poziomu,
## odbicie z kamienia Mnożenie (odsunięcie), kamień Zamieci (czas na darmowy wypad).
const LUNGE_TIME := 0.18
const LUNGE_WIDTH := 14.0
const LUNGE_PATH_TIME := 2.0
const LUNGE_PATH_TIME_LONG := 4.0
const LUNGE_PATH_SLOW := 0.4
const LUNGE_PATH_TICK := 0.25
const LUNGE_BURST := 40.0
const LUNGE_BURST_POWER := 0.6
const LUNGE_MIRROR := 16.0
const LUNGE_FREE_TIME := 1.5
## Riposta Morozka: zasłona (s, 5. poziom), kontra (siła, zasięg), wybuch na koniec (zasięg), sopel z 10. poziomu,
## kamień Lodowego Pancerza (bazowo, za odbicie, sufit, czas).
const GUARD_TIME := 1.5
const GUARD_TIME_LONG := 2.5
const COUNTER_POWER := 0.5
const COUNTER_RANGE := 70.0
const NOVA_RADIUS := 60.0
const GUARD_ICICLE_POWER := 0.6
const ARMOR_BASE := 0.3
const ARMOR_STEP := 0.05
const ARMOR_MAX := 0.5
const ARMOR_TIME := 4.0
## Grad Pchnięć: co ile pchnięcie (5. poziom), połowa kąta stożka, co ile mana, chód, kolec z 10. poziomu.
const FLURRY_EVERY := 0.12
const FLURRY_EVERY_PERK := 0.09
const FLURRY_CONE := 0.45
const FLURRY_MANA_EVERY := 0.5
const FLURRY_WALK := 0.6
const FLURRY_SPIKE_EVERY := 5
const FLURRY_SPIKE_POWER := 0.6
const FLURRY_GHOST_TURN := 0.18
## Lodowy Kwiat: wbijanie (s), pierścień (zasięg, liczba kryształów, spłaszczenie, znaki chłodu), 5. poziom, drugi
## pierścień z 10. poziomu (opóźnienie, zasięg, siła), Mnożenie (opóźnienie), kamień Wiecznej Zmarzliny.
const BLOOM_DROP := 0.22
const BLOOM_RADIUS := 50.0
const BLOOM_CRYSTALS := 10
const BLOOM_FLAT := 0.62
const BLOOM_CHILL := 2
const BLOOM_PERK_AREA := 1.3
const BLOOM_RING2_DELAY := 0.4
const BLOOM_RING2 := 1.6
const BLOOM_RING2_POWER := 0.7
const BLOOM_ECHO_DELAY := 0.2
const FIELD_TIME := 3.0
const FIELD_TICK := 0.5
const FIELD_POWER := 0.25
const SPIKE_RADIUS := 16.0

## Ile pchnięć padło (5. poziom - co trzecie dalej; kamień Sopli - co czwarte sopel); ile roztrzaskań (testy).
var thrust_count := 0
var shatters := 0
## Ile ciosów odbiła ostatnia zasłona (testy, kamień Lodowego Pancerza).
var guard_blocks := 0
var flurry_thrusts := 0
var _aim_dir := Vector2.RIGHT
var _shattering := false
var _guard_ring: Node2D
var _lunge_from := Vector2.ZERO
var _lunge_hits: Array = []
var _lunge_mirror_hits: Array = []
var _lunge_free := 0.0
var _flurry_t := 0.0
var _flurry_mana_t := 0.0
## Lecące sople ({"node", "dir", "left", "power", "hits", "skill"}), ścieżki szronu ({"node", "a", "b", "left",
## "tick"}) i kryształy Wiecznej Zmarzliny ({"node", "at", "radius", "left", "tick"}).
var _icicles: Array = []
var _paths: Array = []
var _fields: Array = []


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
	return super._world_fx() + [_icicles, _paths, _fields, [_guard_ring]]


func _exit_tree() -> void:
	if hero and hero.form_speed != 1.0 and _state == "r_flurry":
		hero.form_speed = 1.0
	super._exit_tree()


func _connect_parry() -> void:
	if hero and not hero.parried.is_connected(_on_parried):
		hero.parried.connect(_on_parried)


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"r_wind", "r_out", "r_back":
			_process_thrust()
		"r_lunge":
			_process_lunge()
		"r_guard":
			_process_guard()
		"r_flurry":
			_process_flurry(delta)
		"r_bloom":
			_process_bloom()
	if _lunge_free > 0.0:
		_lunge_free -= delta
		if _lunge_free <= 0.0:  # Zamieć: czas na darmowy wypad minął - zwykłe odnowienie
			_cd["r_lunge"] = maxf(cooldown_full("r_lunge") - LUNGE_FREE_TIME, 0.0)
	_process_icicles(delta)
	_process_paths(delta)
	_process_fields(delta)


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


# --- Pchnięcie Szronu (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		thrust_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
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
	_set_state("r_wind")
	hero.play_gesture(_orbit_center() + _aim_dir * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _thrust_reach() -> float:
	var long := _perk(basic, 0) and not _second and thrust_count % THRUST_LONG_EVERY == 0
	return Skills.DATA[basic].range * _area(basic) * (THRUST_LONG if long else 1.0)


func _process_thrust() -> void:
	match _state:
		"r_wind":
			var k := ease(clampf(_t / THRUST_WIND, 0.0, 1.0), -2.0)
			_point(_aim_dir, 2.0)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, _aim_dir.angle(), k)
			if _t >= THRUST_WIND:
				_set_state("r_out")
		"r_out":
			var k := clampf(_t / THRUST_OUT, 0.0, 1.0)
			_point(_aim_dir, lerpf(2.0, 22.0, k))
			if not _hit_done and k >= 0.5:
				_hit_done = true
				_thrust_hit()
			if _t >= THRUST_OUT:
				_set_state("r_back")
		"r_back":
			var k := clampf(_t / THRUST_BACK, 0.0, 1.0)
			_point(_aim_dir, lerpf(22.0, 6.0, k))
			if _t >= THRUST_BACK:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = THRUST_COOLDOWN


## Trafienie pchnięciem: wszyscy na linii; 10. - kolec przy pierwszym trafionym; Sople - co czwarte sopel.
func _thrust_hit() -> void:
	var from := _orbit_center()
	var reach := _thrust_reach()
	var to := from + _aim_dir * reach
	var power := _swing_power * _power(basic)
	var hit := _line_targets(from, to, THRUST_WIDTH * _area(basic))
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
	if _unique(basic) and not _second and thrust_count % THRUST_ICICLE_EVERY == 0:
		_launch_icicle(from, _aim_dir, _power(basic) * ICICLE_POWER, basic)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


# --- Sople (kamień Sopli, 10. poziom Riposty) ---

func _launch_icicle(from: Vector2, dir: Vector2, power: float, skill: String) -> void:
	var node := _Icicle.new()
	node.rotation = dir.angle()
	node.z_index = 21
	get_parent().add_child(node)
	node.global_position = from
	_icicles.append({"node": node, "dir": dir, "left": ICICLE_RANGE, "power": power, "hits": [], "skill": skill})


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
		if ic.left <= 0.0:
			node.queue_free()
			_icicles.erase(ic)


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
	if id == basic or not id in ["r_lunge", "r_riposte", "r_flurry", "r_bloom"]:
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
			_connect_parry()
			guard_blocks = 0
			hero.parry_left = 0.2
			_show_guard(true)
			_set_state("r_guard")
		"r_flurry":
			flurry_thrusts = 0
			_flurry_t = 0.0
			_flurry_mana_t = 0.0
			hero.form_speed = FLURRY_WALK
			_set_state("r_flurry")
		"r_bloom":
			_from_sprite = _sprite.position
			_set_state("r_bloom")
			hero.play_gesture(hero.global_position + Vector2(0, 10))
	skill_used.emit(id)


func _end_skill() -> void:
	if _state == "r_flurry" and hero:
		hero.form_speed = 1.0
	if _state == "r_guard":
		if hero:
			hero.parry_left = 0.0
		_show_guard(false)
	super._end_skill()


# --- Wypad ---

func _start_lunge() -> void:
	var reach: float = Skills.DATA.r_lunge.range * _area("r_lunge")
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	var dir: Vector2
	if stick.length() > 0.2:
		dir = stick.normalized()
	else:
		var best := _nearest(reach)
		if best:
			dir = (best.global_position - hero.global_position).normalized()
		else:
			dir = hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	_aim_dir = dir
	_lunge_from = hero.global_position
	_lunge_hits = []
	_lunge_mirror_hits = []
	hero.leap(hero.global_position + dir * reach, LUNGE_TIME, 0.0)
	hero.protect(LUNGE_TIME + 0.08)
	hero.play_gesture(hero.global_position + dir * 20.0)
	var fx := Fx.once(get_parent(), TRAIL_FX, TRAIL_FRAMES, 30.0, (_lunge_from + Vector2(0, -ORBIT_HEIGHT)).round(), TRAIL_ANCHOR, 21)
	fx.rotation = dir.angle()
	fx.scale = Vector2(reach / TRAIL_LEN, 1.0)
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


## Koniec wypadu: ścieżka szronu od startu do końca; 10. poziom - wybuch mrozu.
func _lunge_land() -> void:
	var end := hero.global_position
	var node := _FrostPath.new()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO
	node.a = _lunge_from
	node.b = end
	node.queue_redraw()
	var time := LUNGE_PATH_TIME_LONG if _perk("r_lunge", 0) else LUNGE_PATH_TIME
	_paths.append({"node": node, "a": _lunge_from, "b": end, "left": time, "full": time, "tick": 0.0})
	if _perk("r_lunge", 1):
		var radius := LUNGE_BURST * _area("r_lunge")
		for t in _ring_hits(end, radius, _power("r_lunge") * LUNGE_BURST_POWER, "r_lunge"):
			t.chill(Elements.CHILL_SLOW, Elements.CHILL_TIME, 2)
		Fx.once(get_parent(), SHATTER_FX, SHATTER_FRAMES, 18.0, end.round(), SHATTER_ANCHOR, 21, radius / SHATTER_FX_RADIUS * 0.6)
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


# --- Riposta Morozka ---

func _guard_time() -> float:
	return GUARD_TIME_LONG if _perk("r_riposte", 0) else GUARD_TIME


func _show_guard(on: bool) -> void:
	if on and (_guard_ring == null or not is_instance_valid(_guard_ring)):
		_guard_ring = _GuardRing.new()
		_guard_ring.z_index = -1
		hero.add_child(_guard_ring)
	elif not on and _guard_ring and is_instance_valid(_guard_ring):
		_guard_ring.queue_free()
		_guard_ring = null


func _process_guard() -> void:
	# rapier pionowo przed postacią, lekko drży - zasłona
	position = hero.position + Vector2(0, 1)
	var side := 1.0 if hero.facing.x >= 0.0 else -1.0
	_sprite.position = _orbit_center() - global_position + Vector2(side * 9.0, -6.0)
	_sprite.rotation = -PI / 2.0 + 0.05 * sin(_clock * 35.0)
	hero.parry_left = 0.2  # każdy cios w zasłonie jest odbity
	if _t >= _guard_time() or hero.dead:
		_guard_nova()
		_end_skill()


## Cios odbity zasłoną: kontra pchnięciem w najbliższego wroga (Mnożenie - dwa razy), 10. poziom - sopel.
func _on_parried() -> void:
	if _state != "r_guard":
		return
	guard_blocks += 1
	var best := _nearest(COUNTER_RANGE * _area("r_riposte"))
	if best == null:
		return
	var dir := (best.center() - _orbit_center()).normalized()
	var power := _power("r_riposte") * COUNTER_POWER
	_hit(best, power, hero.global_position, "r_riposte")
	var extra := gem_power("r_riposte", "multi") / 100.0
	if extra > 0.0 and best.alive():
		_hit(best, power * extra, hero.global_position, "r_riposte")
	_thrust_fx(_orbit_center(), dir, best.center().distance_to(_orbit_center()) + 6.0)
	_hit_fx(best.center())
	if _perk("r_riposte", 1):
		_launch_icicle(_orbit_center(), dir, _power("r_riposte") * GUARD_ICICLE_POWER, "r_riposte")


## Koniec zasłony: mróz wybucha dookoła i zamraża wszystkich; Lodowy Pancerz - mniej obrażeń przez chwilę.
func _guard_nova() -> void:
	var at := hero.global_position
	var radius := NOVA_RADIUS * _area("r_riposte")
	for t in _ring_hits(at, radius, _power("r_riposte"), "r_riposte"):
		t.chill(Elements.CHILL_SLOW, Elements.CHILL_TIME, Elements.CHILL_STACKS)
	Fx.once(get_parent(), SHATTER_FX, SHATTER_FRAMES, 16.0, at.round(), SHATTER_ANCHOR, 21, radius / SHATTER_FX_RADIUS * 0.75)
	if _unique("r_riposte"):
		hero.fortify(minf(ARMOR_BASE + ARMOR_STEP * guard_blocks, ARMOR_MAX), ARMOR_TIME)
		hero.float_text(tr("Lodowy pancerz!"), -46.0, ICE, 11, 0.9)
	Input.vibrate_handheld(35)


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
	if not charge_held or hero.dead:
		_end_skill()


## Jedno pchnięcie gradu w losowym kierunku stożka; Mnożenie - widmowe obok; Grad - 2 znaki chłodu; 10. - kolec.
func _flurry_thrust(reach: float) -> void:
	flurry_thrusts += 1
	var from := _orbit_center()
	var dir := _aim_dir.rotated(randf_range(-FLURRY_CONE, FLURRY_CONE))
	var power := _power("r_flurry")
	var length := reach * randf_range(0.8, 1.0)
	var hit := _line_targets(from, from + dir * length, THRUST_WIDTH * _area("r_flurry"))
	for t in hit:
		_hit(t, power, hero.global_position, "r_flurry")
		if _unique("r_flurry"):
			t.chill()
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


# --- Lodowy Kwiat ---

func _bloom_radius() -> float:
	return BLOOM_RADIUS * _area("r_bloom") * (BLOOM_PERK_AREA if _perk("r_bloom", 0) else 1.0)


func _process_bloom() -> void:
	# rapier wznosi się szpicem w dół nad postacią i wbija w ziemię
	position = hero.position + Vector2(0, 1)
	var k := clampf(_t / BLOOM_DROP, 0.0, 1.0)
	_sprite.rotation = PI / 2.0
	_sprite.position = Vector2(0, lerpf(-RAPIER_LEN - 22.0, -RAPIER_LEN + 4.0, ease(k, 2.0)))
	if _t >= BLOOM_DROP:
		var at := hero.global_position
		_bloom_ring(at, _bloom_radius(), _power("r_bloom"), randf() * TAU)
		if gem_power("r_bloom", "multi") > 0.0:
			get_tree().create_timer(BLOOM_ECHO_DELAY, false).timeout.connect(_bloom_ring.bind(at, _bloom_radius() * 1.2,
					_power("r_bloom") * gem_power("r_bloom", "multi") / 100.0, PI / BLOOM_CRYSTALS))
		if _perk("r_bloom", 1):
			get_tree().create_timer(BLOOM_RING2_DELAY, false).timeout.connect(_bloom_ring.bind(at,
					_bloom_radius() * BLOOM_RING2, _power("r_bloom") * BLOOM_RING2_POWER, 0.3))
		if _unique("r_bloom"):
			_spawn_field(at, _bloom_radius())
		Input.vibrate_handheld(40)
		_end_skill()


## Pierścień kryształów o promieniu `radius` wokół `at`: rani wszystkich w środku i dokłada BLOOM_CHILL znaków chłodu
## (zamrożeni pękają w `_hit`). `turn` - obrót pierścienia.
func _bloom_ring(at: Vector2, radius: float, power: float, turn: float) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	for i in BLOOM_CRYSTALS:
		var a := turn + TAU * i / BLOOM_CRYSTALS
		var spot := at + Vector2(cos(a), sin(a) * BLOOM_FLAT) * radius
		Fx.once(get_parent(), SPIKES_FX, SPIKES_FRAMES, 18.0, spot.round(), SPIKES_ANCHOR, 2, 0.7)
	for t in _ring_hits(at, radius + SPIKE_RADIUS * 0.5, power, "r_bloom"):
		t.chill(Elements.CHILL_SLOW, Elements.CHILL_TIME, BLOOM_CHILL)


func _spawn_field(at: Vector2, radius: float) -> void:
	var node := _Crystals.new()
	node.radius = radius
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = at
	_fields.append({"node": node, "at": at, "radius": radius, "left": FIELD_TIME, "tick": FIELD_TICK})


func _process_fields(delta: float) -> void:
	for f in _fields.duplicate():
		f.left -= delta
		f.tick -= delta
		var node: Node2D = f.node
		node.modulate.a = clampf(f.left / 0.5, 0.0, 1.0)
		if f.tick <= 0.0:
			f.tick = FIELD_TICK
			for t in _ring_hits(f.at, f.radius + SPIKE_RADIUS * 0.5, _power("r_bloom") * FIELD_POWER, "r_bloom"):
				t.chill()
		if f.left <= 0.0:
			node.queue_free()
			_fields.erase(f)


## Ile pól kryształów stoi (testy).
func crystal_fields() -> int:
	return _fields.size()


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


## Zasłona Riposty Morozka: szronowy krąg wokół postaci z kryształkami.
class _GuardRing extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color(0.75, 0.95, 1.0, 0.8), 1.5)
		for i in 6:
			var a := _t * 1.5 + TAU * i / 6.0
			var p := Vector2.from_angle(a) * 18.0
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3), p + Vector2(2, 0), p + Vector2(0, 3),
					p + Vector2(-2, 0)]), Color(0.92, 0.99, 1.0, 0.95))


## Kryształy Wiecznej Zmarzliny: pierścień lodowych kryształów wbitych w ziemię.
class _Crystals extends Node2D:
	var radius := 50.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, BLOOM_FLAT))
		draw_circle(Vector2.ZERO, radius, Color(0.6, 0.85, 1.0, 0.12))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.85, 0.97, 1.0, 0.5), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in BLOOM_CRYSTALS:
			var a := TAU * i / BLOOM_CRYSTALS
			var p := Vector2(cos(a), sin(a) * BLOOM_FLAT) * radius
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(0, -10), p + Vector2(3, 0)]),
					Color(0.65, 0.9, 1.0, 0.85))
			draw_line(p + Vector2(0, -9), p + Vector2(-1, -1), Color(1, 1, 1, 0.9), 1.0)

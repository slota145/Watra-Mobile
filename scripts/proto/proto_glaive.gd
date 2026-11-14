class_name ProtoGlaive
extends ProtoWeapon
## Glewia ognia (ustalone z autorem 13.11.2026) - druga broń po mieczu, żywioł ogień (Elements.FIRE). Lewituje obok
## postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie, krytyki), ale bije inaczej:
## - zwykły cios „Pchnięcie glewii” (`g_thrust`): glewia cofa się i dźga daleko przed siebie, rani wszystkich na linii;
## - „Ognisty zamach” (`g_sweep`): szeroki półokrąg przed postacią, mocno podpala (5. poziom - odpycha, 10. - drugi
##   zamach w drugą stronę);
## - „Płonąca bruzda” (`g_trail`, pomysł autora 14.11.2026 zamiast doskoku): glewia wbija się w ziemię przed postacią
##   i ryje bruzdę do przodu - zostaje krótki pas ognia, a w wachlarzu wylatują 3 szybkie pionowe cięcia ognia
##   (5. poziom - bruzda płonie dłużej, 10. - 5 cięć);
## - „Słup ognia” (`g_pillar`): glewia wznosi się i spada na wroga, wybuch ognia wokół i płonący krąg na ziemi
##   (5. poziom - większy krąg, 10. - drugi wybuch po chwili);
## - „Taniec płomieni” (`g_dance`, pomysł autora): seria zamaszystych cięć dookoła postaci pod różnymi kątami (14.11.2026:
##   bez wiru) - każde cięcie wypuszcza sierp ognia, który powoli leci na zewnątrz i przebija wrogów
##   (5. poziom - dłużej, 10. - po dwa sierpy naraz w przeciwne strony).
## Kamienie unikalne (Gems.UNIQUE, ustalone z autorem 14.11.2026; `_unique`): pchnięcie - 3 pchnięcia w wąskim stożku;
## zamach - płonąca ziemia wzdłuż łuku; bruzda - cięcia wracają do postaci (ranią drugi raz); Słup ognia - glewia spada
## 3 razy w 3 różnych wrogów (słabsze wybuchy, mniejsze kręgi); Taniec płomieni - sierpy odbijają się między wrogami.
## Każde trafienie podpala (`_hit`): Skills.burn_of - ile obrażeń trafienia dopala się przez BURN_TIME (silniejsze
## podpalenie zastępuje słabsze - ProtoTarget.burn). Ogień na ziemi (`_zones`) co ZONE_TICK rani i podpala stojących
## w nim wrogów. Grafika glewii: assets/weapons/glaive.png (ostrze w prawo, rękojeść po lewej; narysowana w narzędziu
## pikseli PixelLab). Efekty ognia z kreatora efektów PixelLab (assets/effects/glaive_*.png, pixellab_src/vfx/ids.json):
## pchnięcie, zamach, wybuch, ogień na ziemi (pętla, wiele płomyków na strefę), lecące cięcie, trafienie ogniem.

const GLAIVE_TEXTURE := preload("res://assets/weapons/glaive.png")
## Punkt chwytu na obrazku (piksele obrazka) i długość glewii w grze (od chwytu do czubka).
const G_GRIP := Vector2(12.0, 10.0)
const G_LENGTH := 42.0
## Pchnięcie: zasięg czubka od środka postaci, połowa szerokości linii, czasy (zamach, dźgnięcie, powrót, przerwa).
const THRUST_REACH := 64.0
const THRUST_WIDTH := 12.0
const THRUST_WINDUP := 0.14
const THRUST_TIME := 0.12
const THRUST_RECOVER := 0.1
const THRUST_COOLDOWN := 0.55
## Ognisty zamach: kąt łuku, zasięg, czas, siła odepchnięcia z 5. poziomu.
const SWEEP_ARC := deg_to_rad(200.0)
const SWEEP_RADIUS := 58.0
const SWEEP_TIME := 0.26
const SWEEP_PUSH := 150.0
## Płonąca bruzda: gdzie glewia wbija się w ziemię i dokąd ryje (od środka postaci), czas wbicia i przeciągnięcia,
## połowa szerokości pasa ognia, jak długo płonie (5. poziom - dłużej), cięcia w wachlarzu (liczba, z 10. poziomu,
## rozstaw między sąsiednimi, prędkość, zasięg).
const FURROW_FROM := 12.0
const FURROW_TO := 40.0
const FURROW_PLUNGE := 0.1
const FURROW_DRAG := 0.22
const TRAIL_WIDTH := 12.0
const TRAIL_BURN := 3.0
const TRAIL_BURN_LONG := 5.0
const FURROW_CUTS := 3
const FURROW_CUTS_PERK := 5
const FURROW_SPREAD := deg_to_rad(20.0)
const FURROW_CUT_SPEED := 260.0
const FURROW_CUT_DISTANCE := 130.0
## Słup ognia: wzniesienie, spadek, tkwienie w ziemi, wysokość, promień wybuchu i płonącego kręgu, drugi wybuch.
const PILLAR_RISE := 0.25
const PILLAR_FALL := 0.09
const PILLAR_STUCK := 0.35
const PILLAR_HEIGHT := 64.0
const PILLAR_RADIUS := 50.0
const PILLAR_ZONE_RADIUS := 36.0
const PILLAR_ZONE_BIG := 1.5
const PILLAR_ZONE_TIME := 3.0
const PILLAR_ECHO := 0.5
## Taniec płomieni: czas (5. poziom - dłużej), co ile cięcie, łuk jednego cięcia, o ile (od-do) obraca się kolejne,
## prędkość i zasięg sierpów, promień trafienia.
const DANCE_TIME := 3.0
const DANCE_TIME_LONG := 4.0
const DANCE_EVERY := 0.3
const DANCE_SWING := deg_to_rad(140.0)
const DANCE_TURN := Vector2(deg_to_rad(100.0), deg_to_rad(200.0))
const CUT_SPEED := 70.0
const CUT_DISTANCE := 150.0
const CUT_RADIUS := 15.0
## Kamienie unikalne: rozstaw pchnięć w stożku, łuk płonącej ziemi zamachu (promień jako część zasięgu, połowa
## szerokości, czas), powrót cięć bruzdy (prędkość), Słup ognia (liczba upadków, zasięg szukania celów, siła i krąg
## kolejnych), odbicia sierpów tańca (najwięcej, zasięg szukania).
const THRUST_GEM_SPREAD := deg_to_rad(12.0)
const SWEEP_GEM_RADIUS := 0.7
const SWEEP_GEM_WIDTH := 12.0
const SWEEP_GEM_TIME := 3.0
const FURROW_RETURN_SPEED := 220.0
const PILLAR_GEM_FALLS := 3
const PILLAR_GEM_RANGE := 120.0
const PILLAR_GEM_POWER := 0.6
const PILLAR_GEM_ZONE := 0.6
const DANCE_GEM_BOUNCES := 3
const DANCE_GEM_RANGE := 90.0
## Ogień na ziemi: co ile rani i jaką częścią obrażeń umiejętności.
const ZONE_TICK := 0.5
const ZONE_POWER := 0.25
## Kolor ognia (wir Tańca płomieni).
const FIRE := Color(1.0, 0.55, 0.2)
## Efekty (klatki, fps, punkt zaczepienia, wielkość w pikselach efektu: długość smugi, promień łuku i wybuchu).
const THRUST_FX := preload("res://assets/effects/glaive_thrust.png")
const THRUST_FX_ANCHOR := Vector2(5, 8)
const THRUST_FX_LENGTH := 52.0
const SWEEP_FX := preload("res://assets/effects/glaive_sweep.png")
const SWEEP_FX_ANCHOR := Vector2(53, 67)
const SWEEP_FX_RADIUS := 56.0
const BLAST_FX := preload("res://assets/effects/glaive_blast.png")
const BLAST_FX_ANCHOR := Vector2(35, 35)
const BLAST_FX_RADIUS := 33.0
const GROUND_FX := preload("res://assets/effects/glaive_ground_fire.png")
const GROUND_FX_ANCHOR := Vector2(10, 15)
const GROUND_FX_FRAMES := 8
const GROUND_FX_SPACING := 9.0
## Odstęp płomyków w płonącym kręgu (rzadziej niż w pasie, żeby krąg nie zlewał się w plamę).
const RING_FX_SPACING := 14.0
const CUT_FX := preload("res://assets/effects/glaive_cut.png")
const CUT_FX_ANCHOR := Vector2(20, 20)
const CUT_FX_FRAMES := 14
## Klatki lecącego sierpa (bez rozbłysku na początku i gaśnięcia na końcu) - grają w pętli w locie.
const CUT_FX_LOOP := Vector2i(2, 12)
const DANCE_SLASH_FX := preload("res://assets/effects/glaive_dance_slash.png")
## Cięcie tańca: łuk nad punktem zaczepienia (wypukły do góry), promień ok. 27 px.
const DANCE_SLASH_ANCHOR := Vector2(30, 36)
const DANCE_SLASH_SIZE := 1.4
const FIRE_HIT_FX := preload("res://assets/effects/glaive_hit.png")
const FIRE_HIT_ANCHOR := Vector2(19, 19)

## Lecące cięcia Tańca płomieni: {"fx", "dir", "left", "hits"}.
var _cuts: Array = []
## Ogień na ziemi: {"node", "a", "b", "radius", "left", "tick", "skill"} (odcinek a-b z promieniem; koło - a == b).
var _zones: Array = []
var _dance_left := 0.0
var _dance_acc := 0.0
var _sweep_again := false
var _furrow_from := Vector2.ZERO
var _furrow_to := Vector2.ZERO
var _dance_sign := 1.0
## Słup ognia z kamieniem unikalnym: kolejne cele (węzły wrogów) i mnożnik siły bieżącego upadku.
var _pillar_queue: Array = []
var _pillar_mult := 1.0


func _init() -> void:
	basic = "g_thrust"
	main_skill = "g_thrust"


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = GLAIVE_TEXTURE
		s.offset = -G_GRIP


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"thrust_windup", "thrust", "thrust_recover":
			_process_thrust()
		"sweep":
			_process_sweep()
		"trail":
			_process_trail()
		"pillar_rise", "pillar_fall", "pillar_stuck":
			_process_pillar()
		"dance":
			_process_dance(delta)
	_process_cuts(delta)
	_process_zones(delta)


## Błysk trafienia ogniem na celu.
func _fire_hit(t: ProtoTarget) -> void:
	Fx.once(get_parent(), FIRE_HIT_FX, 12, 16.0, t.center().round(), FIRE_HIT_ANCHOR, 21, 0.75)


## Trafienie glewią: obrażenia jak każdej broni (`_deal` - krytyk, elity, kamienie) i podpalenie wg umiejętności.
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String, burn_mult := 1.0) -> void:
	var amount := _roll(power)
	_deal(t, amount, from, skill)
	var burn := Skills.burn_of(skill) * burn_mult
	if burn > 0.0 and t.alive():
		t.burn(amount * burn, BURN_TIME)


## Glewia na linii od środka postaci pod kątem `a`: chwyt `d` pikseli od środka.
func _place_line(a: float, d: float) -> void:
	position = hero.position + Vector2(0, -1.0 if sin(a) < -0.2 else 1.0)
	_sprite.position = _orbit_center() - global_position + Vector2.from_angle(a) * d
	_sprite.rotation = a


# --- Zwykły cios: pchnięcie ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	var best := _nearest(THRUST_REACH * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("thrust_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _process_thrust() -> void:
	var tip := THRUST_REACH * _area(basic) - G_LENGTH
	match _state:
		"thrust_windup":
			var k := ease(clampf(_t / THRUST_WINDUP, 0.0, 1.0), -2.0)
			_place_line(_aim, -4.0)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, _aim, k)
			if _t >= THRUST_WINDUP:
				_set_state("thrust")
		"thrust":
			var k := clampf(_t / THRUST_TIME, 0.0, 1.0)
			_place_line(_aim, lerpf(-4.0, tip, ease(k, 0.4)))
			if not _hit_done and k >= 0.6:
				_hit_done = true
				_thrust_hit()
			if _t >= THRUST_TIME:
				_set_state("thrust_recover")
		"thrust_recover":
			_place_line(_aim, lerpf(tip, 4.0, clampf(_t / THRUST_RECOVER, 0.0, 1.0)))
			if _t >= THRUST_RECOVER:
				var perk_second := _perk(basic, 1) and _strike_count % 3 == 0
				if not _second and (perk_second or gem_power(basic, "multi") > 0.0) and not hero.dead:
					_attack(true, perk_second)  # Mnożenie albo 10. poziom: drugie pchnięcie
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = THRUST_COOLDOWN


## Pchnięcie trafia wszystkich na linii od postaci do czubka (5. poziom - podpalenie x2).
func _thrust_hit() -> void:
	var reach := THRUST_REACH * _area(basic)
	var any := false
	var angles := [_aim, _aim - THRUST_GEM_SPREAD, _aim + THRUST_GEM_SPREAD] if _unique(basic) else [_aim]
	var hit: Array = []  # w stożku każdy wróg obrywa raz na pchnięcie
	for a in angles:
		var dir := Vector2.from_angle(a)
		for t in _live_targets():
			var to := t.center() - _orbit_center()
			var along := to.dot(dir)
			if not hit.has(t) and along >= 0.0 and along <= reach + 6.0 and absf(to.cross(dir)) <= THRUST_WIDTH:
				hit.append(t)
				_hit(t, _swing_power * _power(basic), hero.global_position, basic, 2.0 if _perk(basic, 0) else 1.0)
				_fire_hit(t)
				any = true
		var fx := Fx.once(get_parent(), THRUST_FX, 7, 16.0, (_orbit_center() + dir * 8.0).round(), THRUST_FX_ANCHOR, 6,
				(reach - 8.0) / THRUST_FX_LENGTH)
		fx.rotation = a
	if any:
		Input.vibrate_handheld(15)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["g_sweep", "g_trail", "g_pillar", "g_dance"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	var best := _nearest(Skills.DATA[id].range)
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"g_sweep":
			_sweep_again = _perk(id, 1)
			_sign = -_sign
			_sweep_fx()
			_set_state("sweep")
		"g_trail":
			var dir := Vector2.from_angle(_aim)
			_furrow_from = hero.global_position + dir * FURROW_FROM
			_furrow_to = hero.global_position + dir * FURROW_TO * _area(id)
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			_set_state("trail")
		"g_pillar":
			_goal = best.position if best else hero.position + hero.facing.normalized() * 30.0
			_pillar_queue = []
			_pillar_mult = 1.0
			if _unique(id):
				_pillar_mult = PILLAR_GEM_POWER
				var near: Array = []
				for t in _live_targets():
					var d := hero.global_position.distance_to(t.global_position)
					if t != best and d <= PILLAR_GEM_RANGE * _area(id):
						near.append([d, t])
				near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
				for pair in near.slice(0, PILLAR_GEM_FALLS - 1):
					_pillar_queue.append(pair[1])
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			_set_state("pillar_rise")
		"g_dance":
			_spin = _aim
			_dance_left = DANCE_TIME_LONG if _perk(id, 0) else DANCE_TIME
			_dance_acc = DANCE_EVERY
			_set_state("dance")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Ognisty zamach: glewia przechodzi łukiem SWEEP_ARC przed postacią; w połowie trafia wszystkich w łuku.
func _process_sweep() -> void:
	var k := clampf(_t / SWEEP_TIME, 0.0, 1.0)
	var a := _aim + lerpf(-SWEEP_ARC / 2.0, SWEEP_ARC / 2.0, ease(k, 0.5)) * _sign
	_place_line(a, 6.0)
	if not _hit_done and k >= 0.5:
		_hit_done = true
		var radius := SWEEP_RADIUS * _area("g_sweep")
		for t in _live_targets():
			var to := t.center() - _orbit_center()
			if to.length() <= radius and absf(angle_difference(_aim, to.angle())) <= SWEEP_ARC / 2.0:
				_hit(t, _power("g_sweep"), hero.global_position, "g_sweep")
				if _perk("g_sweep", 0):
					t.push_away(hero.global_position, SWEEP_PUSH)
				_fire_hit(t)
		Input.vibrate_handheld(20)
	if _t >= SWEEP_TIME:
		if _unique("g_sweep"):
			_add_arc_zone(_orbit_center() + Vector2(0, ORBIT_HEIGHT), _aim, SWEEP_RADIUS * _area("g_sweep") * SWEEP_GEM_RADIUS,
					SWEEP_ARC, SWEEP_GEM_WIDTH * _area("g_sweep"), SWEEP_GEM_TIME, "g_sweep")
		if _sweep_again and not hero.dead:
			_sweep_again = false
			_hit_done = false
			_sign = -_sign
			_sweep_fx()
			_set_state("sweep")
		else:
			_end_skill()


## Ognisty łuk zamachu z kreatora (rysowany zgodnie z ruchem wskazówek zegara - w drugą stronę odbity).
func _sweep_fx() -> void:
	var size := SWEEP_RADIUS * _area("g_sweep") / SWEEP_FX_RADIUS
	var fx := Fx.once(get_parent(), SWEEP_FX, 9, 16.0, _orbit_center().round(), SWEEP_FX_ANCHOR, 6, size)
	fx.scale = Vector2(size, size * _sign)
	fx.rotation = _aim


## Płonąca bruzda: glewia wbija się ostrzem w ziemię przed postacią, ryje do przodu (pas ognia za nią), a na końcu
## wypuszcza wachlarz szybkich cięć ognia. Postać stoi w miejscu.
func _process_trail() -> void:
	var dig := Vector2(0, -G_LENGTH + 8.0)  # chwyt nad ziemią, czubek w ziemi
	if _t < FURROW_PLUNGE:
		var k := ease(clampf(_t / FURROW_PLUNGE, 0.0, 1.0), -2.0)
		position = _from_pos.lerp(_furrow_from, k)
		_sprite.position = _from_sprite.lerp(dig, k)
		_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
		return
	var k := clampf((_t - FURROW_PLUNGE) / FURROW_DRAG, 0.0, 1.0)
	position = _furrow_from.lerp(_furrow_to, ease(k, 0.6))
	_sprite.position = dig
	_sprite.rotation = PI / 2.0 - 0.35 * signf(cos(_aim) + 0.001)  # przechylona do tyłu - ciągnięta
	if k >= 1.0:
		_add_zone(_furrow_from, _furrow_to, TRAIL_WIDTH * _area("g_trail"),
				TRAIL_BURN_LONG if _perk("g_trail", 0) else TRAIL_BURN, "g_trail")
		var n := FURROW_CUTS_PERK if _perk("g_trail", 1) else FURROW_CUTS
		for i in n:
			var a := _aim + (i - (n - 1) / 2.0) * FURROW_SPREAD
			_spawn_cut(a, "g_trail", _furrow_to, FURROW_CUT_SPEED, FURROW_CUT_DISTANCE)
		Fx.once(get_parent(), FIRE_HIT_FX, 12, 16.0, _furrow_to.round(), FIRE_HIT_ANCHOR, 6)
		Input.vibrate_handheld(30)
		_end_skill()


## Słup ognia: glewia wznosi się nad cel ostrzem w dół, spada, wybuch ognia i płonący krąg; chwilę tkwi w ziemi.
func _process_pillar() -> void:
	match _state:
		"pillar_rise":
			var k := ease(clampf(_t / (PILLAR_RISE * (0.6 if _pillar_mult < 1.0 else 1.0)), 0.0, 1.0), -2.0)
			position = _from_pos.lerp(_goal, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -PILLAR_HEIGHT), k)
			_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
			if k >= 1.0:
				_set_state("pillar_fall")
		"pillar_fall":
			var k := clampf(_t / PILLAR_FALL, 0.0, 1.0)
			_sprite.position = Vector2(0, lerpf(-PILLAR_HEIGHT, -G_LENGTH + 6.0, k * k))
			if _t >= PILLAR_FALL:
				_pillar_hit(global_position)
				if _perk("g_pillar", 1):
					get_tree().create_timer(PILLAR_ECHO, false).timeout.connect(
							_blast.bind(global_position, PILLAR_RADIUS * _area("g_pillar"), _power("g_pillar") * _pillar_mult,
							"g_pillar"))
				_set_state("pillar_stuck")
		"pillar_stuck":
			if _t >= PILLAR_STUCK * (0.4 if _unique("g_pillar") else 1.0):
				var next: ProtoTarget = null
				while not _pillar_queue.is_empty() and next == null:
					var t = _pillar_queue.pop_front()
					next = t if is_instance_valid(t) and t.alive() else null
				if next and not hero.dead:  # kamień unikalny: kolejny upadek w następnego wroga
					_goal = next.position
					_from_pos = position
					_from_sprite = _sprite.position
					_from_rot = _sprite.rotation
					_set_state("pillar_rise")
				else:
					_end_skill()


func _pillar_hit(at: Vector2) -> void:
	_blast(at, PILLAR_RADIUS * _area("g_pillar"), _power("g_pillar") * _pillar_mult, "g_pillar")
	var r := PILLAR_ZONE_RADIUS * _area("g_pillar") * (PILLAR_ZONE_BIG if _perk("g_pillar", 0) else 1.0) \
			* (PILLAR_GEM_ZONE if _unique("g_pillar") else 1.0)
	_add_zone(at, at, r, PILLAR_ZONE_TIME, "g_pillar")
	var cam := hero.get_viewport().get_camera_2d()
	if cam:
		var shake := cam.create_tween()
		for i in 4:
			shake.tween_property(cam, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.03)
		shake.tween_property(cam, "offset", Vector2.ZERO, 0.03)


## Wybuch ognia w punkcie `at`: rani i podpala wszystkich w promieniu (elipsa jak przy Rozłupaniu - rzut z góry).
func _blast(at: Vector2, radius: float, power: float, skill: String) -> void:
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, skill)
	Fx.once(get_parent(), BLAST_FX, 12, 14.0, at.round(), BLAST_FX_ANCHOR, 6, radius / BLAST_FX_RADIUS)
	Input.vibrate_handheld(35)


## Taniec płomieni: seria cięć dookoła postaci - co DANCE_EVERY glewia przeskakuje pod nowy kąt (obrót o DANCE_TURN
## w losową stronę) i tnie łukiem DANCE_SWING na przemian w obie strony; w połowie cięcia wylatuje sierp ognia.
func _process_dance(delta: float) -> void:
	_dance_left -= delta
	_dance_acc += delta
	if _dance_acc >= DANCE_EVERY:
		_dance_acc -= DANCE_EVERY
		_spin += randf_range(DANCE_TURN.x, DANCE_TURN.y) * (1.0 if randf() < 0.5 else -1.0)
		_dance_sign = -_dance_sign
		_hit_done = false
		var fx := Fx.once(get_parent(), DANCE_SLASH_FX, 12, 28.0, _orbit_center().round(), DANCE_SLASH_ANCHOR, 6)
		var size := DANCE_SLASH_SIZE * _area("g_dance")
		fx.scale = Vector2(size * _dance_sign, size)
		fx.rotation = _spin + PI / 2.0
		hero.play_gesture(_orbit_center() + Vector2.from_angle(_spin) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	var k := clampf(_dance_acc / (DANCE_EVERY * 0.7), 0.0, 1.0)
	_place_line(_spin + lerpf(-DANCE_SWING / 2.0, DANCE_SWING / 2.0, ease(k, 0.5)) * _dance_sign, 4.0)
	if not _hit_done and k >= 0.5:
		_hit_done = true
		_spawn_cut(_spin)
		if _perk("g_dance", 1):
			_spawn_cut(_spin + PI)
	if _dance_left <= 0.0:
		_end_skill()


## Sierp ognia leci od `from` (domyślnie środek postaci) pod kątem `a` z prędkością `speed` na `distance` pikseli
## i przebija wrogów; rani siłą umiejętności `skill` (Taniec płomieni - wolno, Płonąca bruzda - szybko).
func _spawn_cut(a: float, skill := "g_dance", from := Vector2.INF, speed := CUT_SPEED, distance := CUT_DISTANCE) -> void:
	var fx := Sprite2D.new()
	fx.texture = CUT_FX
	fx.hframes = CUT_FX_FRAMES
	fx.frame = CUT_FX_LOOP.x
	fx.centered = false
	fx.offset = -CUT_FX_ANCHOR
	fx.z_index = 20
	fx.rotation = a
	fx.scale = Vector2.ONE * _area(skill)
	get_parent().add_child(fx)
	fx.global_position = _orbit_center() if from == Vector2.INF else from + Vector2(0, -ORBIT_HEIGHT)
	_cuts.append({"fx": fx, "dir": Vector2.from_angle(a), "left": distance * _area(skill), "hits": [], "skill": skill,
			"speed": speed, "back": skill == "g_trail" and _unique(skill), "bounces": DANCE_GEM_BOUNCES
			if skill == "g_dance" and _unique(skill) else 0})


func _process_cuts(delta: float) -> void:
	for i in range(_cuts.size() - 1, -1, -1):
		var c: Dictionary = _cuts[i]
		var fx: Sprite2D = c.fx
		var step: float = c.speed * delta
		if c.get("returning", false):  # kamień unikalny bruzdy: wraca do postaci (goni ją)
			var to := _orbit_center() - fx.global_position
			c.dir = to.normalized() if to.length() > 0.1 else c.dir
			fx.rotation = c.dir.angle()
			c.left = to.length()
		fx.global_position += c.dir * step
		fx.frame = CUT_FX_LOOP.x + int(_clock * 16.0 + i) % (CUT_FX_LOOP.y - CUT_FX_LOOP.x)
		c.left -= step
		fx.modulate.a = 1.0 if c.get("returning", false) else clampf(c.left / 30.0, 0.0, 1.0)
		var reach := CUT_RADIUS * _area(c.skill)
		for t in _live_targets():
			if not c.hits.has(t) and t.center().distance_to(fx.global_position) <= reach:
				c.hits.append(t)
				_hit(t, _power(c.skill), fx.global_position - c.dir * 10.0, c.skill)
				_fire_hit(t)
				if c.bounces > 0:  # kamień unikalny tańca: odbicie w najbliższego nietrafionego wroga
					var next := _bounce_target(fx.global_position, c.hits)
					if next:
						c.bounces -= 1
						c.dir = (next.center() - fx.global_position).normalized()
						fx.rotation = c.dir.angle()
						c.left = maxf(c.left, fx.global_position.distance_to(next.center()) + 20.0)
		if c.left <= 0.0:
			if c.back:
				c.back = false
				c.returning = true
				c.hits = []
				c.speed = FURROW_RETURN_SPEED
				c.left = 1.0
				continue
			fx.queue_free()
			_cuts.remove_at(i)


## Najbliższy wróg w zasięgu DANCE_GEM_RANGE od `at`, którego sierp jeszcze nie trafił (null - brak).
func _bounce_target(at: Vector2, hits: Array) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := DANCE_GEM_RANGE * _area("g_dance")
	for t in _live_targets():
		var d := t.center().distance_to(at)
		if not hits.has(t) and d <= best_d:
			best = t
			best_d = d
	return best


# --- Ogień na ziemi ---

## Pas (a-b) albo koło (a == b) ognia na `time` sekund; co ZONE_TICK rani i podpala wrogów w środku. Na ziemi
## płomyki z kreatora (pętla) co GROUND_FX_SPACING wzdłuż pasa albo w kręgach koła.
func _add_zone(a: Vector2, b: Vector2, radius: float, time: float, skill: String) -> void:
	var node := Node2D.new()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO  # płomyki w układzie świata
	var spots: Array[Vector2] = []
	if a.distance_to(b) > 1.0:
		var n := maxi(1, int(a.distance_to(b) / GROUND_FX_SPACING))
		for i in n + 1:
			var side := (b - a).orthogonal().normalized() * radius * 0.5 * (1.0 if i % 2 == 0 else -1.0)
			spots.append(a.lerp(b, float(i) / n) + side * randf_range(0.2, 1.0))
	else:
		spots.append(a)
		var r := RING_FX_SPACING
		while r < radius + 1.0:
			var count := int(TAU * r / RING_FX_SPACING)
			for i in count:
				var ang := TAU * i / count + r
				spots.append(a + Vector2(cos(ang), sin(ang) / 1.6) * r)
			r += RING_FX_SPACING
	var flames: Array = []
	for p in spots:
		var f := Sprite2D.new()
		f.texture = GROUND_FX
		f.hframes = GROUND_FX_FRAMES
		f.centered = false
		f.offset = -GROUND_FX_ANCHOR
		f.position = p.round()
		f.frame = randi() % GROUND_FX_FRAMES
		node.add_child(f)
		flames.append(f)
	_zones.append({"node": node, "flames": flames, "a": a, "b": b, "radius": radius, "left": time, "tick": ZONE_TICK,
			"skill": skill})


## Płonąca ziemia wzdłuż łuku (kamień unikalny zamachu): środek `c`, kierunek `aim`, promień `r`, kąt `span`, połowa
## szerokości `width`. Strefa to płomyki w kołach co GROUND_FX_SPACING (wróg w którymkolwiek - w ogniu).
func _add_arc_zone(c: Vector2, aim: float, r: float, span: float, width: float, time: float, skill: String) -> void:
	var node := Node2D.new()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO
	var n := maxi(2, int(span * r / GROUND_FX_SPACING))
	var circles: Array = []
	var flames: Array = []
	for i in n + 1:
		var a := aim + lerpf(-span / 2.0, span / 2.0, float(i) / n)
		var p := c + Vector2(cos(a), sin(a) / 1.6) * r
		circles.append(p)
		var f := Sprite2D.new()
		f.texture = GROUND_FX
		f.hframes = GROUND_FX_FRAMES
		f.centered = false
		f.offset = -GROUND_FX_ANCHOR
		f.position = p.round()
		f.frame = randi() % GROUND_FX_FRAMES
		node.add_child(f)
		flames.append(f)
	_zones.append({"node": node, "flames": flames, "a": c, "b": c, "circles": circles, "radius": width, "left": time,
			"tick": ZONE_TICK, "skill": skill})


func _process_zones(delta: float) -> void:
	for i in range(_zones.size() - 1, -1, -1):
		var z: Dictionary = _zones[i]
		z.left -= delta
		z.tick -= delta
		if z.tick <= 0.0:
			z.tick += ZONE_TICK
			for t in _live_targets():
				if _in_zone(z, t.global_position):
					_hit(t, _power(z.skill) * ZONE_POWER, t.global_position, z.skill)
		if z.left <= 0.0:
			z.node.queue_free()
			_zones.remove_at(i)
			continue
		z.node.modulate.a = clampf(z.left / 0.5, 0.0, 1.0)
		for k in z.flames.size():
			z.flames[k].frame = (int(_clock * 12.0) + k * 3) % GROUND_FX_FRAMES


## Czy punkt `p` (stopy wroga) stoi w ogniu strefy `z` (odległość od odcinka, rzut z góry - spłaszczony pion).
static func _in_zone(z: Dictionary, p: Vector2) -> bool:
	if z.has("circles"):
		for c in z.circles:
			var dc: Vector2 = p - c
			if Vector2(dc.x, dc.y * 1.6).length() <= z.radius:
				return true
		return false
	var a: Vector2 = z.a
	var b: Vector2 = z.b
	var ab := b - a
	var k := 0.0 if ab.length_squared() < 0.01 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var d := p - a.lerp(b, k)
	return Vector2(d.x, d.y * 1.6).length() <= z.radius


func _end_skill() -> void:
	super._end_skill()
	_cooldown = maxf(_cooldown, THRUST_COOLDOWN * 0.5)

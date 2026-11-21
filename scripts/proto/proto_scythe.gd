class_name ProtoScythe
extends ProtoWeapon
## Mroczna kosa (ustalone z autorem 21.11.2026) - broń wręcz, żywioł Nawia (Elements.NAWIA): każde trafienie wysysa
## trochę życia i osłabia wroga (ProtoWeapon._deal, ProtoTarget.wither). Lewituje obok postaci jak miecz (dziedziczy
## po ProtoWeapon: podążanie, orbita, mana, odnowienia, kamienie, krytyki). Efekty czarno-białe z przewagą czerni
## (decyzja autora): czarne cięcia z białą krawędzią, gasną powoli (efekty z kreatora PixelLab: scythe_swing,
## scythe_hit, scythe_line, scythe_blast, scythe_wave; pixellab_src/vfx/ids.json). Grafika: assets/weapons/scythe.png
## (tools/scythe_art.py).
## - „Żniwo” (`s_reap`, zwykły atak): szeroki zamach łukiem REAP_ARC przed postacią; 5. poziom - co trzeci zamach to
##   pełny obrót, 10. - zamach zostawia na chwilę smugę Nawii, która rani (`_trails`); kamień unikalny (Żniwiarza) -
##   po REAP_CHARGE trafieniach fala Nawii dookoła (`_reap_wave`).
## - „Cięcie Światowida” (`s_square`): 4 cięcia jedno po drugim układają się w kwadrat dookoła postaci (cienkie
##   ciemne cięcia po łuku zostają - wygięte na zewnątrz i dłuższe niż bok, krzyżują się w rogach; prośba autora
##   21.11.2026), po chwili każdy bok wybucha na zewnątrz (rani i odpycha wrogów za bokiem); 5. - wybuch
##   o SQUARE_PERK_AREA szerszy, 10. - wybuch dwa razy; kamień unikalny (Czterech Stron) - 3 widmowe kosy więcej:
##   4 takie kwadraty 2x2 dookoła postaci, oddalone od siebie (`_squares`).
## - „Pokos” (`s_mow`, ładowany - Skills.is_charged): dopóki palec trzyma przycisk, na ziemi rośnie stożek ze ściętym
##   czubkiem (większy zasięg i obrażenia im dłużej), po puszczeniu kosa kosi cały stożek; 5. - ładuje się o 1/3
##   szybciej, 10. - pełne naładowanie ogłusza; kamień unikalny (Rzędów Nawii) - po cięciu w stożku wybucha Nawia
##   rzędami, każdy rząd od prawej do lewej względem postaci (`_mow_rows`).
## Taniec Marzanny i Postać Mary - w drugim kroku (ROADMAP).

const SCYTHE_TEXTURE := preload("res://assets/weapons/scythe.png")
## Punkt chwytu na obrazku (koniec drzewca po lewej).
const S_GRIP := Vector2(8.0, 34.0)
const NAWIA := Color(0.03, 0.02, 0.05)
const BONE := Color(0.93, 0.93, 0.97)
## Efekty z kreatora (wymiary i zaczepienia - pixellab_src/vfx/ids.json).
const SWING_FX := preload("res://assets/effects/scythe_swing.png")
const SWING_FRAMES := 14
const SWING_FPS := 16.0
const SWING_ANCHOR := Vector2(29, 37)
## Promień łuku zamachu na arkuszu i kąt jego środka (łuk biegnie zgodnie z zegarem od góry-lewej).
const SWING_RADIUS := 26.0
const SWING_MID := deg_to_rad(-20.0)
## Klatka szczytu zamachu (smuga z 10. poziomu zostaje na niej).
const SWING_PEAK := 6
const S_HIT_FX := preload("res://assets/effects/scythe_hit.png")
const S_HIT_FRAMES := 10
const S_HIT_FPS := 18.0
const S_HIT_ANCHOR := Vector2(41, 27)
const S_HIT_SIZE := 0.45
const LINE_FX := preload("res://assets/effects/scythe_line.png")
const LINE_FRAMES := 12
const LINE_FPS := 18.0
const LINE_ANCHOR := Vector2(54, 21)
## Długość cięcia na arkuszu i jego nachylenie (lekko wznosi się w prawo, jak cięcie katany).
const LINE_LENGTH := 102.0
const LINE_TILT := deg_to_rad(7.85)
const BLAST_FX := preload("res://assets/effects/scythe_blast.png")
const BLAST_FRAMES := 12
const BLAST_FPS := 16.0
const BLAST_ANCHOR := Vector2(43, 39)
## Promień wybuchu na arkuszu (do skalowania pod promień trafienia).
const BLAST_RADIUS := 30.0
const S_WAVE_FX := preload("res://assets/effects/scythe_wave.png")
const S_WAVE_FRAMES := 12
const S_WAVE_FPS := 16.0
const S_WAVE_ANCHOR := Vector2(58, 74)
const S_WAVE_RADIUS_FX := 55.0
## Fala jest w arkuszu bardzo biała - w grze przygaszona, żeby przeważała czerń (decyzja autora o kolorach).
const S_WAVE_TINT := Color(0.55, 0.55, 0.62, 0.95)

## Żniwo: czasy (zamach wolniejszy niż miecz - ciężka kosa, za to szerszy łuk), łuk, zasięg od środka postaci;
## smuga z 10. poziomu (czas, co ile rani, siła); kamień unikalny (ile trafień, promień i siła fali).
const REAP_WINDUP := 0.13
const REAP_SWING := 0.22
const REAP_RECOVER := 0.1
const REAP_COOLDOWN := 0.62
const REAP_ARC := deg_to_rad(200.0)
const REAP_REACH := 56.0
const TRAIL_TIME := 1.2
const TRAIL_TICK := 0.3
const TRAIL_POWER := 0.25
const REAP_CHARGE := 15
const WAVE_RADIUS := 80.0
const WAVE_POWER := 1.0
## Cięcie Światowida: połowa boku kwadratu, co ile kolejne cięcie, siła cięcia, przerwa przed wybuchem, zasięg wybuchu
## za bokiem (5. poziom - szerzej), siła i odepchnięcie, drugi wybuch z 10. (po ilu s, siła).
const SQUARE_HALF := 38.0
## Cięcie boku po łuku: o tyle (część boku) dłuższe z każdej strony - krzyżuje się z sąsiednim w rogu, wygięcie na
## zewnątrz, czas rysowania; kamień unikalny - środki kwadratów o tyle połówek boku od postaci (między nimi odstęp).
const SQUARE_ARC_EXT := 0.24
const SQUARE_ARC_SAG := 0.16
const SQUARE_ARC_DRAW := 0.07
const SQUARE_SPREAD := 1.5
const SQUARE_CUT_EVERY := 0.07
const SQUARE_CUT_POWER := 0.45
const SQUARE_CUT_WIDTH := 9.0
const SQUARE_BURST_DELAY := 0.45
const SQUARE_BURST_DEPTH := 36.0
const SQUARE_PERK_AREA := 1.3
const SQUARE_BURST_POWER := 1.3
const SQUARE_PUSH := 140.0
const SQUARE_SECOND := 0.35
const SQUARE_SECOND_POWER := 0.8
## Pokos: pełne ładowanie (5. poziom - krócej), samo puszczenie po tylu s trzymania naładowanej, stożek (ścięty czubek,
## zasięg i pół-kąt od-do), siła (od-do), ogłuszenie z 10.; kamień unikalny (rzędy, odstępy, promień i siła wybuchu).
const MOW_CHARGE := 1.4
const MOW_CHARGE_FAST := 0.93
const MOW_HOLD_MAX := 1.0
const MOW_INNER := 14.0
const MOW_REACH := Vector2(55.0, 120.0)
const MOW_HALF := Vector2(deg_to_rad(32.0), deg_to_rad(55.0))
const MOW_POWER := Vector2(0.9, 2.0)
const MOW_STUN := 1.0
const MOW_FLASH := 0.5
const MOW_ROWS := 3
const MOW_ROW_GAP := 0.14
const MOW_BLAST_GAP := 0.05
const MOW_BLAST_SPACING := 26.0
const MOW_BLAST_RADIUS := 20.0
const MOW_BLAST_POWER := 0.45

## Żniwo: licznik zamachów (co trzeci - obrót), czy ten zamach to obrót, trafienia do fali (kamień unikalny).
var reap_count := 0
var _full_spin := false
var reap_hits := 0
## Smugi Nawii ({"node", "aim", "radius", "arc", "left", "tick", "power"}).
var _trails: Array = []
## Kwadraty Światowida w toku ({"center", "half", "t", "cuts", "bursts", "lines": [Line2D], "ghost", "area", "power"}).
var _squares: Array = []
## Pokos: ładowanie (s), stożek na ziemi (wypełnienie i obrys), zaplanowane wybuchy rzędów ({"at", "t"}).
var _charge := 0.0
var _mow_poly: Polygon2D
var _mow_edge: Line2D
var _mow_blasts: Array = []
## Ile wybuchów rzędów było (do testów).
var mow_blasts_done := 0


func _init() -> void:
	basic = "s_reap"
	main_skill = "s_reap"
	element = Elements.NAWIA
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = SCYTHE_TEXTURE
		s.offset = -S_GRIP


func _world_fx() -> Array:
	return super._world_fx() + [_trails, _squares, [_mow_poly, _mow_edge]]


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"r_windup", "r_swing", "r_recover":
			_process_reap()
		"mow_charge":
			_process_mow_charge(delta)
		"square_spin":
			_place(_aim + TAU * clampf(_t / (SQUARE_CUT_EVERY * 4.0), 0.0, 1.0))
			if _t >= SQUARE_CUT_EVERY * 4.0 + 0.05:
				_end_skill()
	_process_trails(delta)
	_process_squares(delta)
	_process_mow_blasts(delta)


## Trafienie umiejętnością `skill` z siłą `power` (z rozbłyskiem Nawii na celu).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)
	if not Fx.crowded(S_HIT_FX):
		Fx.once(get_parent(), S_HIT_FX, S_HIT_FRAMES, S_HIT_FPS, t.center().round(), S_HIT_ANCHOR, 21, S_HIT_SIZE)


## Zamach z kreatora: środek łuku ku `aim`, `sign` - kierunek (odbicie), promień `radius`. Zwraca węzeł efektu.
func _swing_fx(at: Vector2, aim: float, sign_: float, radius: float) -> Sprite2D:
	var fx := Fx.once(get_parent(), SWING_FX, SWING_FRAMES, SWING_FPS, at.round(), SWING_ANCHOR, 5, radius / SWING_RADIUS)
	fx.rotation = aim - SWING_MID * sign_
	fx.scale.y *= sign_
	return fx


## Trafia wszystkich, których środek leży w łuku `arc` wokół kierunku `aim`, w odległości `inner`..`reach` od `at`.
func _arc_hits(at: Vector2, aim: float, reach: float, arc: float, power: float, skill: String, inner := 0.0) -> Array:
	var hit: Array = []
	for t in _near_c(at, reach):
		var to := t.center() - at
		var d := to.length()
		if d <= reach + t.center_height * 0.3 and d >= inner and (arc >= TAU or absf(angle_difference(aim, to.angle())) <= arc / 2.0):
			_hit(t, power, hero.global_position, skill)
			hit.append(t)
	return hit


# --- Żniwo (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		reap_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_full_spin = _perk(basic, 0) and not second and reap_count % 3 == 0
	var best := _nearest(Skills.DATA[basic].range * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("r_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Kąt kosy w chwili `k` zamachu (obrót z 5. poziomu - pełne koło).
func _reap_angle(k: float) -> float:
	var arc := TAU if _full_spin else REAP_ARC
	return _aim + lerpf(-arc / 2.0, arc / 2.0, k) * _sign


func _process_reap() -> void:
	match _state:
		"r_windup":
			var k := ease(clampf(_t / REAP_WINDUP, 0.0, 1.0), -2.0)
			var a := _reap_angle(-0.08)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= REAP_WINDUP:
				_set_state("r_swing")
				var radius := REAP_REACH * _area(basic)
				_swing_fx(_orbit_center(), _aim, _sign, radius)
				if _full_spin:
					_swing_fx(_orbit_center(), _aim + PI, _sign, radius)
		"r_swing":
			var progress := clampf(_t / (REAP_SWING * (1.5 if _full_spin else 1.0)), 0.0, 1.0)
			_place(_reap_angle(ease(progress, 0.5)))
			if not _hit_done and progress >= 0.45:
				_hit_done = true
				_reap_hit()
			if progress >= 1.0:
				_set_state("r_recover")
		"r_recover":
			_place(_reap_angle(1.0))
			if _t >= REAP_RECOVER:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: drugi zamach w drugą stronę
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = REAP_COOLDOWN


## Zamach Żniwa: wszyscy w łuku (obrót - dookoła); 10. poziom - smuga Nawii; kamień unikalny - licznik do fali.
func _reap_hit() -> void:
	var power := _swing_power * _power(basic)
	var reach := REAP_REACH * _area(basic)
	var arc := TAU if _full_spin else REAP_ARC
	var hit := _arc_hits(_orbit_center(), _aim, reach, arc, power, basic)
	if _perk(basic, 1) and not _second:
		_spawn_trail(_aim, reach, arc, power * TRAIL_POWER)
	if _unique(basic):
		reap_hits += hit.size()
		if reap_hits >= REAP_CHARGE:
			reap_hits -= REAP_CHARGE
			_reap_wave(power)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


## Smuga Nawii (10. poziom Żniwa): szczyt zamachu zostaje na TRAIL_TIME s i gaśnie, co TRAIL_TICK rani w łuku.
func _spawn_trail(aim: float, radius: float, arc: float, power: float) -> void:
	var node := Sprite2D.new()
	node.texture = SWING_FX
	node.hframes = SWING_FRAMES
	node.frame = SWING_PEAK
	node.centered = false
	node.offset = -SWING_ANCHOR
	node.scale = Vector2.ONE * radius / SWING_RADIUS
	node.rotation = aim - SWING_MID * _sign
	node.scale.y *= _sign
	node.modulate = Color(1, 1, 1, 0.65)
	node.z_index = 4
	get_parent().add_child(node)
	node.global_position = _orbit_center().round()
	_trails.append({"node": node, "aim": aim, "radius": radius, "arc": arc, "left": TRAIL_TIME, "tick": TRAIL_TICK,
			"power": power, "at": _orbit_center()})


func _process_trails(delta: float) -> void:
	for tr_ in _trails.duplicate():
		tr_.left -= delta
		tr_.tick -= delta
		var node: Sprite2D = tr_.node
		node.modulate.a = 0.65 * clampf(tr_.left / TRAIL_TIME, 0.0, 1.0)
		node.frame = SWING_PEAK + mini(int((TRAIL_TIME - tr_.left) / TRAIL_TIME * 4.0), 3)
		if tr_.tick <= 0.0:
			tr_.tick = TRAIL_TICK
			_arc_hits(tr_.at, tr_.aim, tr_.radius, tr_.arc, tr_.power, basic, tr_.radius * 0.4)
		if tr_.left <= 0.0:
			node.queue_free()
			_trails.erase(tr_)


## Kamień unikalny Żniwa: fala Nawii dookoła postaci (pierścień z kreatora, przygaszony).
func _reap_wave(power: float) -> void:
	var radius := WAVE_RADIUS * _area(basic)
	var fx := Fx.once(get_parent(), S_WAVE_FX, S_WAVE_FRAMES, S_WAVE_FPS, hero.global_position.round(), S_WAVE_ANCHOR, -1,
			radius / S_WAVE_RADIUS_FX)
	fx.modulate = S_WAVE_TINT
	for t in _near(hero.global_position, radius):
		if t.global_position.distance_to(hero.global_position) <= radius:
			_hit(t, power * WAVE_POWER, hero.global_position, basic)
	Input.vibrate_handheld(25)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["s_square", "s_mow"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	var best := _nearest(Skills.DATA[id].range * _area(id))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"s_square":
			_cast_square()
			_set_state("square_spin")
		"s_mow":
			_charge = 0.0
			_mow_poly = Polygon2D.new()
			_mow_poly.color = Color(NAWIA, 0.3)
			_mow_poly.z_index = -1
			get_parent().add_child(_mow_poly)
			_mow_edge = Line2D.new()
			_mow_edge.width = 1.0
			_mow_edge.default_color = Color(BONE, 0.45)
			_mow_edge.closed = true
			_mow_edge.z_index = -1
			get_parent().add_child(_mow_edge)
			_set_state("mow_charge")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


func _end_skill() -> void:
	for n in [_mow_poly, _mow_edge]:
		if n and is_instance_valid(n):
			n.queue_free()
	_mow_poly = null
	_mow_edge = null
	super._end_skill()


# --- Cięcie Światowida ---

## Kwadrat (albo cztery z kamieniem unikalnym) wokół postaci - cięcia i wybuchy biegną w `_process_squares`.
func _cast_square() -> void:
	var half := SQUARE_HALF * _area("s_square")
	var centers: Array = [hero.global_position]
	if _unique("s_square"):  # 4 kwadraty 2x2 dookoła postaci, z odstępami między nimi
		centers = []
		for off in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			centers.append(hero.global_position + off * half * SQUARE_SPREAD)
	for c in centers:
		var ghost: Sprite2D = null
		if centers.size() > 1:  # widmowa kosa wiruje nad każdym kwadratem
			ghost = Sprite2D.new()
			ghost.texture = SCYTHE_TEXTURE
			ghost.centered = false
			ghost.offset = -S_GRIP
			ghost.scale = Vector2.ONE * SCALE
			ghost.modulate = Color(0.85, 0.85, 0.95, 0.7)
			ghost.z_index = 6
			get_parent().add_child(ghost)
			ghost.global_position = c + Vector2(0, -ORBIT_HEIGHT)
		_squares.append({"center": c, "half": half, "t": 0.0, "cuts": 0, "bursts": 0, "lines": [], "draw": [], "ghost": ghost,
				"area": SQUARE_PERK_AREA if _perk("s_square", 0) else 1.0, "power": _power("s_square"),
				"twice": _perk("s_square", 1)})
	Input.vibrate_handheld(15)


## Boki kwadratu: [początek, koniec, kierunek na zewnątrz] (zgodnie z zegarem od lewego górnego rogu).
static func square_sides(center: Vector2, half: float) -> Array:
	var tl := center + Vector2(-half, -half)
	var tr_ := center + Vector2(half, -half)
	var br := center + Vector2(half, half)
	var bl := center + Vector2(-half, half)
	return [[tl, tr_, Vector2.UP], [tr_, br, Vector2.RIGHT], [br, bl, Vector2.DOWN], [bl, tl, Vector2.LEFT]]


func _process_squares(delta: float) -> void:
	for sq in _squares.duplicate():
		sq.t += delta
		var sides := square_sides(sq.center, sq.half)
		if sq.ghost:
			sq.ghost.rotation += delta * 18.0
		while sq.cuts < 4 and sq.t >= sq.cuts * SQUARE_CUT_EVERY:
			_square_cut(sq, sides[sq.cuts])
			sq.cuts += 1
		for d in sq.draw.duplicate():  # cięcie po łuku rysuje się od początku do końca
			d.t += delta
			var k := clampf(d.t / SQUARE_ARC_DRAW, 0.0, 1.0)
			var n := maxi(2, ceili(k * d.pts.size()))
			for l in d.lines:
				(l as Line2D).points = d.pts.slice(0, n)
			if k >= 1.0:
				sq.draw.erase(d)
		var burst_at: float = 4 * SQUARE_CUT_EVERY + SQUARE_BURST_DELAY
		var bursts: int = 2 if sq.twice else 1
		while sq.bursts < bursts and sq.t >= burst_at + sq.bursts * SQUARE_SECOND:
			var power: float = sq.power * SQUARE_BURST_POWER * (1.0 if sq.bursts == 0 else SQUARE_SECOND_POWER)
			for side in sides:
				_square_burst(sq, side, power)
			sq.bursts += 1
		if sq.bursts >= bursts:
			for l in sq.lines:
				var line: Line2D = l
				line.create_tween().tween_property(line, "modulate:a", 0.0, 0.3).finished.connect(line.queue_free)
			if sq.ghost:
				sq.ghost.queue_free()
			_squares.erase(sq)


## Łuk cięcia boku a-b: wygięty na zewnątrz (`out`), z każdej strony dłuższy o SQUARE_ARC_EXT boku - sąsiednie łuki
## krzyżują się w rogach kwadratu.
static func square_arc(a: Vector2, b: Vector2, out: Vector2, steps := 14) -> PackedVector2Array:
	var len := a.distance_to(b)
	var along := (b - a) / len
	var p0 := a - along * len * SQUARE_ARC_EXT
	var p2 := b + along * len * SQUARE_ARC_EXT
	var p1 := a.lerp(b, 0.5) + out * len * SQUARE_ARC_SAG * 2.0  # punkt kontrolny - szczyt łuku w połowie wygięcia
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return pts


## Jedno cięcie boku po łuku: czarny półksiężyc (zwężony na końcach) z białą krawędzią po zewnętrznej stronie i błysk;
## zostaje do wybuchu, rani stojących na nim.
func _square_cut(sq: Dictionary, side: Array) -> void:
	var out_dir: Vector2 = side[2]
	var pts := square_arc(side[0], side[1], out_dir)
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.15))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.15))
	var lines: Array = []
	for w in [[6.0, Color(NAWIA, 0.9), Vector2.ZERO], [1.5, Color(BONE, 0.9), out_dir * 2.0]]:
		var line := Line2D.new()
		line.width = w[0]
		line.width_curve = taper
		line.default_color = w[1]
		line.position = w[2]
		line.z_index = 3
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.points = pts.slice(0, 2)
		get_parent().add_child(line)
		sq.lines.append(line)
		lines.append(line)
	var flash := Line2D.new()  # biały błysk cięcia, gaśnie
	flash.width = 3.0
	flash.width_curve = taper
	flash.default_color = Color(BONE, 0.9)
	flash.points = pts
	flash.z_index = 4
	get_parent().add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.25).set_delay(SQUARE_ARC_DRAW).finished.connect(flash.queue_free)
	sq.draw.append({"lines": lines, "pts": pts, "t": 0.0})
	for t in _arc_targets(pts, SQUARE_CUT_WIDTH):
		_hit(t, sq.power * SQUARE_CUT_POWER, sq.center, "s_square")


## Wrogowie, których stopy stoją w pasie szerokości `width` wzdłuż łamanej `pts` (kwadrat leży na ziemi).
func _arc_targets(pts: PackedVector2Array, width: float) -> Array:
	var out: Array = []
	var mid := pts[pts.size() / 2]
	for t in _near(mid, pts[0].distance_to(pts[-1]) * 0.6 + width):
		var c := t.global_position
		for i in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(c, pts[i], pts[i + 1]).distance_to(c) <= width * 0.5 + 4.0:
				out.append(t)
				break
	return out


## Wybuch boku na zewnątrz: rani i odpycha wrogów za bokiem (do SQUARE_BURST_DEPTH od niego), czarne wybuchy wzdłuż boku.
func _square_burst(sq: Dictionary, side: Array, power: float) -> void:
	var a: Vector2 = side[0]
	var b: Vector2 = side[1]
	var out: Vector2 = side[2]
	var depth: float = SQUARE_BURST_DEPTH * _area("s_square") * sq.area
	var along := (b - a).normalized()
	var len := a.distance_to(b)
	var mid := a.lerp(b, 0.5)
	for t in _near(mid + out * depth * 0.5, len * 0.5 + depth):
		var rel := t.global_position - a
		var s := rel.dot(along)
		var d := rel.dot(out)
		if s >= -6.0 and s <= len + 6.0 and d >= -8.0 and d <= depth + 6.0:
			_hit(t, power, sq.center, "s_square")
			t.push_away(sq.center, SQUARE_PUSH)
	var fx := Fx.once(get_parent(), LINE_FX, LINE_FRAMES, LINE_FPS * 1.3, (mid + out * depth * 0.35).round(), LINE_ANCHOR, 6)
	fx.scale = Vector2(len / LINE_LENGTH, 2.6)
	fx.rotation = along.angle() + atan(tan(LINE_TILT) * fx.scale.y / fx.scale.x)  # pochylenie arkusza po rozciągnięciu
	if not Fx.crowded(BLAST_FX, 12):
		for k in [0.25, 0.75]:
			Fx.once(get_parent(), BLAST_FX, BLAST_FRAMES, BLAST_FPS, (a.lerp(b, k) + out * depth * 0.45).round(), BLAST_ANCHOR,
					7, depth * 0.5 / BLAST_RADIUS)
	Input.vibrate_handheld(20)


# --- Pokos ---

## Stożek ze ściętym czubkiem: punkty (łuk wewnętrzny i zewnętrzny) wokół `at` w kierunku `aim`.
static func cone_points(at: Vector2, aim: float, inner: float, reach: float, half: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		pts.append(at + Vector2.from_angle(aim - half + 2.0 * half * i / steps) * reach)
	for i in range(steps, -1, -1):
		pts.append(at + Vector2.from_angle(aim - half + 2.0 * half * i / steps) * inner)
	return pts


func _mow_shape(k: float) -> Vector3:
	return Vector3(MOW_INNER, lerpf(MOW_REACH.x, MOW_REACH.y, k) * _area("s_mow"), lerpf(MOW_HALF.x, MOW_HALF.y, k))


## Ładowanie Pokosu: dopóki palec trzyma przycisk; stożek na ziemi rośnie, kosa uniesiona za postacią drży coraz mocniej.
func _process_mow_charge(delta: float) -> void:
	var full := MOW_CHARGE_FAST if _perk("s_mow", 0) else MOW_CHARGE
	_charge += delta
	var k := clampf(_charge / full, 0.0, 1.0)
	var shape := _mow_shape(k)
	var near := _nearest(shape.y)
	if near:
		_aim = (near.global_position - hero.global_position).angle()
	elif hero.velocity.length() > 1.0:
		_aim = hero.facing.angle()
	var pts := cone_points(hero.global_position, _aim, shape.x, shape.y, shape.z)
	if _mow_poly:
		_mow_poly.polygon = pts
		_mow_poly.color = Color(NAWIA, 0.22 + 0.18 * k + (0.08 * sin(_clock * 20.0) if k >= 1.0 else 0.0))
		_mow_edge.points = pts
	var dir := Vector2.from_angle(_aim)
	position = hero.position + Vector2(0, -1)
	_sprite.position = _orbit_center() - global_position + Vector2(-dir.x * 8.0, -16.0) \
			+ Vector2(randf_range(-1, 1), randf_range(-1, 1)) * k
	_sprite.rotation = -PI / 2.0 - 0.5 * signf(dir.x)
	if not charge_held or _charge >= full + MOW_HOLD_MAX:
		_mow_cut(k)


## Cięcie Pokosu: wszyscy w stożku obrywają (siła od naładowania), zamach kosy przez cały stożek i ciemny błysk stożka;
## 10. poziom przy pełnym naładowaniu ogłusza; kamień unikalny - rzędy wybuchów Nawii.
func _mow_cut(k: float) -> void:
	var shape := _mow_shape(k)
	var at := hero.global_position
	var power := _power("s_mow") * lerpf(MOW_POWER.x, MOW_POWER.y, k)
	var hit: Array = []
	for t in _near(at, shape.y):
		var to := t.global_position - at
		var d := to.length()
		if d <= shape.y + 4.0 and d >= shape.x * 0.5 and absf(angle_difference(_aim, to.angle())) <= shape.z + 0.08:
			_hit(t, power, at, "s_mow")
			hit.append(t)
			if _perk("s_mow", 1) and k >= 1.0:
				t.stun(MOW_STUN)
	_swing_fx(_orbit_center(), _aim, _sign, shape.y * 0.8)
	var flash := Polygon2D.new()
	flash.polygon = cone_points(at, _aim, shape.x, shape.y, shape.z)
	flash.color = Color(NAWIA, 0.6)
	flash.z_index = -1
	var edge := Line2D.new()
	edge.points = flash.polygon
	edge.closed = true
	edge.width = 1.5
	edge.default_color = BONE
	flash.add_child(edge)
	get_parent().add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, MOW_FLASH).finished.connect(flash.queue_free)
	if _unique("s_mow"):
		_mow_rows(at, _aim, shape, power)
	Input.vibrate_handheld(35)
	_end_skill()


## Kamień unikalny Pokosu: wybuchy Nawii w MOW_ROWS rzędach (od bliższego), każdy rząd od prawej do lewej względem
## postaci (prawa ręka przy patrzeniu w `aim` - większy kąt na ekranie).
func _mow_rows(at: Vector2, aim: float, shape: Vector3, power: float) -> void:
	for r in MOW_ROWS:
		var radius := lerpf(shape.x + 16.0, shape.y - 10.0, float(r) / maxf(MOW_ROWS - 1, 1))
		var count := maxi(3, int(2.0 * shape.z * radius / MOW_BLAST_SPACING) + 1)
		for i in count:
			var a := aim + shape.z * 0.9 - 1.8 * shape.z * i / maxf(count - 1, 1)
			_mow_blasts.append({"at": at + Vector2.from_angle(a) * radius, "t": 0.15 + r * MOW_ROW_GAP + i * MOW_BLAST_GAP,
					"power": power * MOW_BLAST_POWER, "row": r})


func _process_mow_blasts(delta: float) -> void:
	for b in _mow_blasts.duplicate():
		b.t -= delta
		if b.t > 0.0:
			continue
		_mow_blasts.erase(b)
		mow_blasts_done += 1
		var radius := MOW_BLAST_RADIUS * _area("s_mow")
		if not Fx.crowded(BLAST_FX, 16):
			Fx.once(get_parent(), BLAST_FX, BLAST_FRAMES, BLAST_FPS, (b.at as Vector2).round(), BLAST_ANCHOR, 7,
					radius / BLAST_RADIUS)
		for t in _near(b.at, radius):
			if t.global_position.distance_to(b.at) <= radius + 4.0:
				_hit(t, b.power, b.at, "s_mow")

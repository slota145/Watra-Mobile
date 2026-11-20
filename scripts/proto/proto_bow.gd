class_name ProtoBow
extends ProtoWeapon
## Łuk (ustalone z autorem 20.11.2026) - broń na dystans, żywioł powietrze (Elements.AIR): każde trafienie strzałą lekko
## odpycha wroga (AIR_PUSH). Łuk lewituje obok postaci (dziedziczy po ProtoWeapon: mana, odnowienia, kamienie, krytyki,
## kolejka umiejętności), przy strzale obraca się ku celowi.
## - „Strzał” (`b_shot`, zwykły cios): strzała w najdalszego wroga w zasięgu (5. poziom - przebija pierwszego wroga,
##   10. - co trzeci strzał dwie strzały); kamień unikalny - Wielostrzał: SHOT_FAN_COUNT strzał w stożku;
## - „Poszukująca strzała” (`b_seeker`, jak Strzała tropiąca Watry - `_Seeker`): leci ze stałą prędkością i skręca łukiem
##   ku celowi, przebija na wylot i szuka kolejnego (innego niż ostatnio trafiony), znika po SEEK_HITS trafieniach
##   (5. - więcej, 10. - dwie strzały); kamień unikalny (Wiernego Tropiciela) - przywołanie: widmowa strzała krąży przy
##   postaci, co SUMMON_EVERY s wypuszcza Poszukującą strzałę, rezerwuje SUMMON_RESERVE many, drugie użycie ją odwołuje;
## - „Deszcz strzał” (`b_rain`): na najbliższego wroga przez RAIN_TIME s spadają strzały - co RAIN_TICK rani wszystkich
##   w kręgu (5. - większy krąg, 10. - dłużej); kamień unikalny - 3 deszcze: na najbliższego i dwóch innych, oddalonych;
## - „Potężny strzał” (`b_power`, ładowany - Skills.is_charged): dopóki palec trzyma przycisk, łuk się naciąga, a na
##   ziemi rośnie pas (dłuższy i szerszy z naładowaniem); po puszczeniu podmuch w pasie rani i odpycha wrogów do przodu,
##   a strzała leci daleko i przebija wszystkich (5. - szybciej się naciąga, 10. - podmuch ogłusza); kamień unikalny
##   (Wichury) - wzdłuż toru strzały wiatr bije na boki: rani i odpycha od toru;
## - „Balista” (`b_ballista`): stawiana przy wrogu na BALLISTA_TIME s; nieruchoma podstawa, obracająca się górna część
##   strzela bełtami w najbliższych wrogów (5. - dłużej, 10. - dwie balisty); kamień unikalny (Oblężnika) - balista
##   powtarza Poszukującą strzałę, Deszcz strzał i Potężny strzał gracza ze swojego miejsca, za darmo, siłą ECHO_POWER.
## Grafika: łuk assets/weapons/bow.png (z Watry), balista ze SpriteKiln (assets/spritekiln/ballista_base i
## ballista_turret; bez nich - obrazek z Watry), efekty z kreatora PixelLab (assets/effects/bow_*.png, arrow_rain,
## seeker_trail, power_*, side_gust - pixellab_src/vfx/ids.json), ikony z Watry (assets/skills/bow/).

const BOW_TEXTURE := preload("res://assets/weapons/bow.png")
const BOW_OFFSET := Vector2(-11, -31)
const BOW_SCALE := 0.45
## Powietrze: każde trafienie strzałą lekko odpycha.
const AIR_PUSH := 40.0
## Strzał: prędkość, promień trafienia, czasy (naciągnięcie, wystrzał, przerwa), wielostrzał (liczba, rozstaw, siła),
## dwie strzały z 10. poziomu (rozstaw).
const ARROW_SPEED := 300.0
const ARROW_RADIUS := 8.0
const BOW_WINDUP := 0.14
const BOW_SHOT := 0.1
const BOW_COOLDOWN := 0.55
const SHOT_FAN_COUNT := 5
const SHOT_FAN := deg_to_rad(12.0)
const SHOT_FAN_POWER := 0.7
const SHOT_PAIR := deg_to_rad(6.0)
## Poszukująca strzała (jak Strzała tropiąca Watry): prędkość, skręt (rad/s; bez trafienia coraz ciaśniej), zasięg szukania,
## czas przelotu przez trafionego, czas życia, trafienia (5. poziom - więcej), rozstaw dwóch strzał z 10.
const SEEK_SPEED := 230.0
const SEEK_TURN := 5.0
const SEEK_TURN_MAX := 16.0
const SEEK_SEARCH := 260.0
const SEEK_PASS := 0.35
const SEEK_LIFE := 6.0
const SEEK_HITS := 4
const SEEK_HITS_PERK := 6
const SEEK_PAIR := deg_to_rad(25.0)
## Przywołanie (kamień Wiernego Tropiciela): co ile strzał, rezerwacja many (część pełnej), promień i czas okrążenia.
const SUMMON_EVERY := 1.5
const SUMMON_RESERVE := 0.2
const SUMMON_RADIUS := 22.0
const SUMMON_PERIOD := 2.0
## Deszcz strzał: promień kręgu (5. poziom - x1,3), czas (10. - dłużej), co ile rani; trzy deszcze kamienia unikalnego -
## najmniejszy odstęp między nimi (w promieniach kręgu).
const RAIN_RADIUS := 40.0
const RAIN_PERK := 1.3
const RAIN_TIME := 1.0
const RAIN_TIME_LONG := 2.0
const RAIN_TICK := 0.2
const RAIN_SPREAD := 1.6
## Potężny strzał: czas pełnego naciągnięcia (5. - krócej), przytrzymanie ponad pełne, długość i szerokość pasa podmuchu
## (od-do z naładowaniem), siła strzały (od-do), siła podmuchu (część), odepchnięcie, ogłuszenie z 10., zasięg strzały,
## podmuch na boki z kamieniem unikalnym (co ile px toru, zasięg na bok, siła, odepchnięcie).
const POWER_CHARGE := 1.2
const POWER_CHARGE_FAST := 0.8
const POWER_HOLD_MAX := 1.5
const POWER_LENGTH := Vector2(80.0, 150.0)
const POWER_WIDTH := Vector2(20.0, 46.0)
const POWER_SHOT := Vector2(0.6, 1.0)
const POWER_GUST := 0.4
const POWER_PUSH := 170.0
const POWER_STUN := 0.8
const POWER_RANGE := 280.0
const SIDE_STEP := 36.0
const SIDE_REACH := 42.0
const SIDE_POWER := 0.5
const SIDE_PUSH := 130.0
## Balista: czas (5. poziom - dłużej), co ile strzela, zasięg, odległość od celu przy postawieniu, rozstaw dwóch z 10.,
## siła powtórzonych umiejętności (kamień unikalny), wysokość wylotu bełtu.
const BALLISTA_TIME := 8.0
const BALLISTA_TIME_LONG := 11.0
const BALLISTA_EVERY := 0.6
const BALLISTA_RANGE := 180.0
const BALLISTA_SPREAD := 28.0
const ECHO_POWER := 0.5
const BALLISTA_MUZZLE := 14.0
const BALLISTA_BASE_SCENE := "res://assets/spritekiln/ballista_base/ballista_base.tscn"
const BALLISTA_TURRET_SCENE := "res://assets/spritekiln/ballista_turret/ballista_turret.tscn"
const BALLISTA_FALLBACK := preload("res://assets/watra/ballista.png")
## Efekty z kreatora PixelLab (pixellab_src/vfx/ids.json): klatki, fps, zaczepienie.
const ARROW_FX := preload("res://assets/effects/bow_arrow.png")
const ARROW_FX_FRAMES := 8
const ARROW_FX_ANCHOR := Vector2(16, 6)
const HIT_FX_BOW := preload("res://assets/effects/bow_hit.png")
const HIT_FX_BOW_FRAMES := 8
const HIT_FX_BOW_ANCHOR := Vector2(16, 16)
const RAIN_FX := preload("res://assets/effects/arrow_rain.png")
const RAIN_FX_FRAMES := 12
const RAIN_FX_ANCHOR := Vector2(50, 60)
const RAIN_FX_RADIUS := 40.0
const TRAIL_FX := preload("res://assets/effects/seeker_trail.png")
const TRAIL_FX_FRAMES := 8
const TRAIL_FX_ANCHOR := Vector2(28, 6)
const CHARGE_FX := preload("res://assets/effects/power_charge.png")
const CHARGE_FX_FRAMES := 8
const CHARGE_FX_ANCHOR := Vector2(20, 20)
const GUST_FX := preload("res://assets/effects/power_gust.png")
const GUST_FX_FRAMES := 9
const GUST_FX_ANCHOR := Vector2(4, 20)
const GUST_FX_LENGTH := 120.0
const GUST_FX_THICK := 40.0
const SIDE_FX := preload("res://assets/effects/side_gust.png")
const SIDE_FX_FRAMES := 9
const SIDE_FX_ANCHOR := Vector2(30, 30)

## Strzały w locie: {"fx", "dir", "left", "speed", "hits", "skill", "power", "pierce" (ile jeszcze przebije; -1 - wszystkich),
## "target", "seek" (Poszukująca: "life", "hits_left", "last", "since", "turn"), "trail", "side" (podmuch na boki)}.
var _arrows: Array = []
## Deszcze strzał: {"at", "left", "tick", "radius", "power", "fx"}.
var _rains: Array = []
## Balisty: {"base", "turret", "at", "left", "acc", "dir"}.
var _ballistas: Array = []
## Przywołanie Poszukującej (kamień Wiernego Tropiciela): widmowa strzała (węzeł) i czas do kolejnej strzały.
var _summon: Node2D
var _summon_acc := 0.0
var _summon_angle := 0.0
var _charge := 0.0
var _charge_line: Line2D
var _charge_fx: Sprite2D
var _shot_target: ProtoTarget


func _world_fx() -> Array:
	return super._world_fx() + [_arrows, _rains, _ballistas, [_charge_line, _charge_fx]]


func _init() -> void:
	basic = "b_shot"
	main_skill = "b_shot"


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = BOW_TEXTURE
		s.centered = false
		s.offset = BOW_OFFSET
		s.scale = Vector2.ONE * BOW_SCALE


func _exit_tree() -> void:
	_dismiss_summon()
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"bow_windup", "bow_shot":
			_process_bow()
		"charge":
			_process_charge(delta)
	_process_arrows(delta)
	_process_rains(delta)
	_process_ballistas(delta)
	_process_summon(delta)


## Łuk nie wiruje - unosi się obok postaci, lekko faluje i patrzy tam, gdzie postać.
func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	_sprite.position = _sprite.position.lerp(Vector2(0, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0)), k)
	_sprite.rotation = lerp_angle(_sprite.rotation, hero.facing.angle() if hero else 0.0, k)


## Trafienie strzałą: obrażenia jak każdej broni (`_deal`) i lekki podmuch powietrza (odepchnięcie).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String, push := AIR_PUSH) -> void:
	_deal(t, _roll(power), from, skill)
	if t.alive() and push > 0.0:
		t.push_away(from, push)


func _hit_fx(at: Vector2, dir: Vector2, size := 1.0) -> void:
	var fx := Fx.once(get_parent(), HIT_FX_BOW, HIT_FX_BOW_FRAMES, 18.0, at.round(), HIT_FX_BOW_ANCHOR, 21, size)
	fx.rotation = dir.angle()


# --- Zwykły cios: strzał ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_shot_target = _farthest(Skills.DATA.b_shot.range * _area(basic))  # strzała przez tłum do najdalszego
	_aim = (_shot_target.center() - _orbit_center()).angle() if _shot_target else hero.facing.angle()
	_from_pos = position
	_from_sprite = _sprite.position
	_hit_done = false
	_set_state("bow_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Łuk podlatuje przed postać, obraca się ku celowi, wypuszcza strzałę i wraca.
func _process_bow() -> void:
	var front := hero.position + Vector2.from_angle(_aim) * 12.0
	match _state:
		"bow_windup":
			var k := ease(clampf(_t / BOW_WINDUP, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(front, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -ORBIT_HEIGHT - 4.0), k)
			_sprite.rotation = lerp_angle(_sprite.rotation, _aim, k)
			if _t >= BOW_WINDUP:
				_fire_shot()
				_set_state("bow_shot")
		"bow_shot":
			if _t >= BOW_SHOT:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: druga strzała
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = BOW_COOLDOWN


## Wystrzał: jedna strzała (10. poziom - co trzeci strzał dwie); z kamieniem unikalnym Wielostrzał - stożek strzał.
func _fire_shot() -> void:
	var from := _sprite.global_position
	var pierce := 1 if _perk(basic, 0) else 0
	if _unique(basic):
		for i in SHOT_FAN_COUNT:
			var a := _aim + SHOT_FAN * (i - (SHOT_FAN_COUNT - 1) / 2.0)
			_spawn_arrow(from, a, null, basic, _swing_power * SHOT_FAN_POWER, pierce)
		return
	if _perk(basic, 1) and _strike_count % 3 == 0:
		_spawn_arrow(from, _aim - SHOT_PAIR, _shot_target, basic, _swing_power, pierce)
		_spawn_arrow(from, _aim + SHOT_PAIR, null, basic, _swing_power, pierce)
	else:
		_spawn_arrow(from, _aim, _shot_target, basic, _swing_power, pierce)


## Strzała z punktu `from` pod kątem `a` (lekko naprowadzana na `target`); `pierce` - ilu wrogów przebije (-1 - wszystkich).
func _spawn_arrow(from: Vector2, a: float, target: ProtoTarget, skill: String, mult := 1.0, pierce := 0,
		reach := 0.0, side := false) -> Dictionary:
	var fx := _arrow_sprite(a)
	fx.global_position = from
	var arrow := {"fx": fx, "dir": Vector2.from_angle(a), "speed": ARROW_SPEED, "hits": [], "skill": skill,
			"power": mult, "pierce": pierce, "target": target, "side": side, "side_acc": 0.0,
			"left": reach if reach > 0.0 else Skills.DATA[skill].range * _area(skill) + 30.0}
	_arrows.append(arrow)
	return arrow


func _arrow_sprite(a: float) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = ARROW_FX
	fx.hframes = ARROW_FX_FRAMES
	fx.centered = false
	fx.offset = -ARROW_FX_ANCHOR
	fx.z_index = 20
	fx.rotation = a
	get_parent().add_child(fx)
	return fx


## Poszukująca strzała z punktu `from`, pierwszy kierunek `a`; `mult` - siła, `hits` - ile trafień.
func _spawn_seeker(from: Vector2, a: float, mult := 1.0) -> void:
	var fx := _arrow_sprite(a)
	fx.global_position = from
	fx.modulate = Color(1.2, 1.35, 1.25)
	var trail := Sprite2D.new()
	trail.texture = TRAIL_FX
	trail.hframes = TRAIL_FX_FRAMES
	trail.centered = false
	trail.offset = -TRAIL_FX_ANCHOR
	trail.z_index = -1
	trail.show_behind_parent = true
	fx.add_child(trail)
	var arrow := {"fx": fx, "dir": Vector2.from_angle(a), "speed": SEEK_SPEED, "hits": [], "skill": "b_seeker",
			"power": mult, "pierce": -1, "target": null, "side": false, "side_acc": 0.0, "left": INF,
			"seek": true, "life": SEEK_LIFE, "hits_left": SEEK_HITS_PERK if _perk("b_seeker", 0) else SEEK_HITS,
			"last": null, "since": SEEK_PASS, "turn": SEEK_TURN, "trail": trail}
	arrow.target = _seek_target(from, null)
	_arrows.append(arrow)


## Cel Poszukującej: najbliższy żywy wróg w zasięgu szukania, inny niż `skip` (gdy jest tylko on - on).
func _seek_target(from: Vector2, skip: ProtoTarget) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := SEEK_SEARCH
	for t in _live_targets():
		if t == skip:
			continue
		var d := t.center().distance_to(from)
		if d <= best_d:
			best = t
			best_d = d
	if best == null and skip != null and is_instance_valid(skip) and skip.alive():
		return skip
	return best


## Strzały w locie: zwykłe lecą prosto (lekko skręcają ku celowi), Poszukujące skręcają łukiem i szukają kolejnych celów.
func _process_arrows(delta: float) -> void:
	for i in range(_arrows.size() - 1, -1, -1):
		var s: Dictionary = _arrows[i]
		var fx: Sprite2D = s.fx
		if not is_instance_valid(fx):
			_arrows.remove_at(i)
			continue
		var tgt = s.get("target")
		var alive_tgt: bool = tgt != null and is_instance_valid(tgt) and tgt.alive()
		if s.has("seek"):
			s.life -= delta
			s.since += delta
			if not alive_tgt:
				s.target = _seek_target(fx.global_position, s.last)
				tgt = s.target
				alive_tgt = tgt != null
			if alive_tgt:
				var want: Vector2 = tgt.center() - fx.global_position
				var turn := minf(s.turn * delta, absf(s.dir.angle_to(want)))
				s.dir = s.dir.rotated(signf(s.dir.angle_to(want)) * turn).normalized()
				s.turn = minf(s.turn + delta * 4.0, SEEK_TURN_MAX)  # bez trafienia coraz ciaśniej - nie krąży w kółko
		elif alive_tgt:
			var want2: Vector2 = (tgt.center() - fx.global_position).normalized()
			s.dir = s.dir.slerp(want2, minf(1.0, 6.0 * delta)).normalized()
		fx.rotation = s.dir.angle()
		var step: float = s.speed * delta
		fx.global_position += s.dir * step
		s.left -= step
		fx.frame = int(_clock * 14.0 + i) % ARROW_FX_FRAMES
		if s.has("trail") and is_instance_valid(s.trail):
			s.trail.frame = int(_clock * 14.0 + i) % TRAIL_FX_FRAMES
		if s.side:
			s.side_acc += step
			if s.side_acc >= SIDE_STEP:
				s.side_acc -= SIDE_STEP
				_side_gust(fx.global_position, s.dir, s.power)
		var done := false
		for t in _live_targets():
			if t.center().distance_to(fx.global_position) > ARROW_RADIUS * _area(s.skill) + t.center_height * 0.3:
				continue
			if s.has("seek"):
				if t == s.last and s.since < SEEK_PASS:
					continue
				_hit(t, _power(s.skill) * s.power, fx.global_position - s.dir * 10.0, s.skill)
				_hit_fx(t.center(), s.dir, 0.8)
				s.last = t
				s.since = 0.0
				s.hits_left -= 1
				s.turn = SEEK_TURN
				s.target = _seek_target(fx.global_position, t)
				if s.hits_left <= 0:
					done = true
				break
			if s.hits.has(t):
				continue
			s.hits.append(t)
			_hit(t, _power(s.skill) * s.power, fx.global_position - s.dir * 10.0, s.skill)
			_hit_fx(t.center(), s.dir, 0.8)
			if s.pierce == 0:
				done = true
				break
			if s.pierce > 0:
				s.pierce -= 1
		if done or s.left <= 0.0 or (s.has("seek") and s.life <= 0.0):
			if s.has("seek") and not done:
				_hit_fx(fx.global_position, s.dir, 0.5)
			fx.queue_free()
			_arrows.remove_at(i)


# --- Umiejętności ---

## Poszukująca z kamieniem unikalnym to przywołanie: bez odnowienia, drugie użycie je odwołuje.
func cooldown_full(id: String) -> float:
	if id == "b_seeker" and _unique(id):
		return 0.0
	return super.cooldown_full(id)


func can_use(id: String) -> bool:
	if id == "b_seeker" and _unique(id) and _summon != null:
		return false  # przywołanie już krąży - auto atak strzela zwykłym strzałem
	return super.can_use(id)


func cast(id: String) -> bool:
	if id == "b_seeker" and _unique(id) and _summon != null and not hero.dead:
		_dismiss_summon()  # drugie stuknięcie odwołuje widmową strzałę
		return true
	return super.cast(id)


func _start(id: String) -> void:
	if id == basic or not id in ["b_seeker", "b_rain", "b_power", "b_ballista"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	var best := _nearest(Skills.DATA[id].range)
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"b_seeker":
			if _unique(id):
				_call_summon()
			else:
				_seekers(_sprite.global_position, 1.0)
		"b_rain":
			_rain_volley(best.global_position if best else hero.global_position + hero.facing.normalized() * 60.0, 1.0)
		"b_power":
			_charge = 0.0
			_charge_line = Line2D.new()
			_charge_line.default_color = Color(Elements.color_of(Elements.AIR), 0.25)
			_charge_line.z_index = -1
			_charge_line.add_point(Vector2.ZERO)
			_charge_line.add_point(Vector2.ZERO)
			get_parent().add_child(_charge_line)
			_charge_fx = Fx.loop(get_parent(), CHARGE_FX, CHARGE_FX_FRAMES, 14.0, Vector2.ZERO, CHARGE_FX_ANCHOR, 21)
			_set_state("charge")
			skill_used.emit(id)
			return  # powtórka balisty - dopiero przy wystrzale (_power_release)
		"b_ballista":
			var at: Vector2 = best.global_position - Vector2.from_angle(_aim) * 24.0 if best \
					else hero.global_position + hero.facing.normalized() * 50.0
			if _perk(id, 1):  # 10. poziom: dwie balisty po bokach
				var side := Vector2.from_angle(_aim).orthogonal() * BALLISTA_SPREAD
				_add_ballista(at + side)
				_add_ballista(at - side)
			else:
				_add_ballista(at)
	if id != "b_ballista":
		_ballista_echo(id)
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Poszukujące z punktu `from` (10. poziom - dwie, rozchylone); `mult` - siła (powtórka balisty słabiej).
func _seekers(from: Vector2, mult: float) -> void:
	if _perk("b_seeker", 1):
		_spawn_seeker(from, _aim - SEEK_PAIR, mult)
		_spawn_seeker(from, _aim + SEEK_PAIR, mult)
	else:
		_spawn_seeker(from, _aim, mult)


# --- Deszcz strzał ---

## Deszcz w punkcie `at`; z kamieniem unikalnym (Ulewy) jeszcze dwa - na innych wrogów, oddalonych od siebie.
func _rain_volley(at: Vector2, mult: float) -> void:
	_add_rain(at, mult)
	if not _unique("b_rain"):
		return
	var radius := _rain_radius()
	var spots: Array[Vector2] = [at]
	var others := _live_targets()
	others.sort_custom(func(x: ProtoTarget, y: ProtoTarget) -> bool:
		return x.global_position.distance_to(at) < y.global_position.distance_to(at))
	for t in others:
		if spots.size() >= 3:
			break
		var far_enough := true
		for s in spots:
			far_enough = far_enough and t.global_position.distance_to(s) >= radius * RAIN_SPREAD
		if far_enough and t.global_position.distance_to(hero.global_position) <= Skills.DATA.b_rain.range * 1.5:
			spots.append(t.global_position)
			_add_rain(t.global_position, mult)


func _rain_radius() -> float:
	return RAIN_RADIUS * (RAIN_PERK if _perk("b_rain", 0) else 1.0) * _area("b_rain")


func _add_rain(at: Vector2, mult: float) -> void:
	var radius := _rain_radius()
	var time := RAIN_TIME_LONG if _perk("b_rain", 1) else RAIN_TIME
	var fx := Fx.loop(get_parent(), RAIN_FX, RAIN_FX_FRAMES, RAIN_FX_FRAMES / RAIN_TIME, Vector2.ZERO, RAIN_FX_ANCHOR,
			6, radius / RAIN_FX_RADIUS)
	fx.global_position = at.round()
	_rains.append({"at": at, "left": time, "tick": 0.05, "radius": radius, "power": mult, "fx": fx})


func _process_rains(delta: float) -> void:
	for i in range(_rains.size() - 1, -1, -1):
		var r: Dictionary = _rains[i]
		r.left -= delta
		r.tick -= delta
		if r.tick <= 0.0:
			r.tick += RAIN_TICK
			for t in _live_targets():
				var off: Vector2 = t.global_position - r.at
				off.y *= 2.0  # krąg spłaszczony jak cień
				if off.length() <= r.radius:
					_hit(t, _power("b_rain") * r.power, r.at + Vector2(0, -40), "b_rain", 0.0)
		if r.left <= 0.0:
			if is_instance_valid(r.fx):
				var fade: Tween = r.fx.create_tween()
				fade.tween_property(r.fx, "modulate:a", 0.0, 0.2)
				fade.tween_callback(r.fx.queue_free)
			_rains.remove_at(i)


# --- Potężny strzał ---

func _power_full() -> float:
	return POWER_CHARGE_FAST if _perk("b_power", 0) else POWER_CHARGE


## Naciąganie, dopóki palec trzyma przycisk: łuk drży, na ziemi rośnie pas podmuchu ku najdalszemu wrogowi.
func _process_charge(delta: float) -> void:
	_charge += delta
	var k := clampf(_charge / _power_full(), 0.0, 1.0)
	var far := _farthest(POWER_LENGTH.y * _area("b_power"))
	if far:
		_aim = (far.global_position - hero.global_position).angle()
	elif hero.velocity.length() > 1.0:
		_aim = hero.facing.angle()
	var dir := Vector2.from_angle(_aim)
	var length := lerpf(POWER_LENGTH.x, POWER_LENGTH.y, k) * _area("b_power")
	if _charge_line:
		_charge_line.width = lerpf(POWER_WIDTH.x, POWER_WIDTH.y, k) * _area("b_power")
		_charge_line.set_point_position(0, _charge_line.to_local(hero.global_position))
		_charge_line.set_point_position(1, _charge_line.to_local(hero.global_position + dir * length))
		_charge_line.default_color = Color(Elements.color_of(Elements.AIR), 0.12 + 0.15 * k \
				+ (0.08 * sin(_clock * 20.0) if k >= 1.0 else 0.0))
	position = hero.position + dir * 10.0
	_sprite.position = Vector2(0, -ORBIT_HEIGHT - 4.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * k
	_sprite.rotation = _aim
	if _charge_fx:
		_charge_fx.global_position = _sprite.global_position.round()
		_charge_fx.scale = Vector2.ONE * (0.6 + 0.6 * k)
	if not charge_held or _charge >= _power_full() + POWER_HOLD_MAX:
		_power_release(hero.global_position, _aim, k, 1.0)
		_ballista_echo("b_power", k)
		_end_skill()


## Wystrzał Potężnego strzału z punktu `from` w kierunku `a` z naładowaniem `k`: podmuch w pasie (rani, odpycha do przodu,
## z 10. poziomem ogłusza) i strzała przebijająca wszystkich (z kamieniem Wichury - podmuchy na boki wzdłuż toru).
func _power_release(from: Vector2, a: float, k: float, mult: float) -> void:
	var dir := Vector2.from_angle(a)
	var length := lerpf(POWER_LENGTH.x, POWER_LENGTH.y, k) * _area("b_power")
	var width := lerpf(POWER_WIDTH.x, POWER_WIDTH.y, k) * _area("b_power")
	var start := from + Vector2(0, -ORBIT_HEIGHT * 0.5)
	var end := start + dir * length
	for t in _live_targets():
		var c := t.center()
		if Geometry2D.get_closest_point_to_segment(c, start, end).distance_to(c) <= width * 0.5 + t.center_height * 0.5:
			_hit(t, _power("b_power") * POWER_GUST * mult, start, "b_power", 0.0)
			if t.alive():
				t.push_away(t.global_position - dir * 20.0, POWER_PUSH * (0.6 + 0.4 * k))
				if _perk("b_power", 1):
					t.stun(POWER_STUN)
	var gust := Fx.once(get_parent(), GUST_FX, GUST_FX_FRAMES, 20.0, start.round(), GUST_FX_ANCHOR, 21)
	gust.rotation = a
	gust.scale = Vector2(length / GUST_FX_LENGTH, clampf(width / GUST_FX_THICK, 0.6, 1.4))
	_spawn_arrow(start, a, null, "b_power", lerpf(POWER_SHOT.x, POWER_SHOT.y, k) * mult, -1,
			POWER_RANGE * _area("b_power"), _unique("b_power"))
	Input.vibrate_handheld(30)


## Kamień Wichury: z punktu toru strzały wiatr bije na boki - rani i odpycha wrogów od toru.
func _side_gust(at: Vector2, dir: Vector2, mult: float) -> void:
	var fx := Fx.once(get_parent(), SIDE_FX, SIDE_FX_FRAMES, 20.0, at.round(), SIDE_FX_ANCHOR, 20, 0.9)
	fx.rotation = dir.angle()
	var normal := dir.orthogonal()
	for t in _live_targets():
		var off := t.center() - at
		if absf(off.dot(dir)) > SIDE_STEP * 0.6 or absf(off.dot(normal)) > SIDE_REACH * _area("b_power"):
			continue
		_hit(t, _power("b_power") * SIDE_POWER * mult, at, "b_power", 0.0)
		if t.alive():
			t.push_away(t.global_position - normal * signf(off.dot(normal) if off.dot(normal) != 0.0 else 1.0) * 10.0,
					SIDE_PUSH)


func _end_skill() -> void:
	if _charge_line:
		_charge_line.queue_free()
		_charge_line = null
	if _charge_fx:
		_charge_fx.queue_free()
		_charge_fx = null
	super._end_skill()


# --- Balista ---

## Balista: nieruchoma podstawa i obracająca się górna część (sceny SpriteKiln; bez nich - obrazek z Watry).
func _add_ballista(at: Vector2) -> void:
	var base: Node2D
	var turret: Node2D
	if ResourceLoader.exists(BALLISTA_BASE_SCENE) and ResourceLoader.exists(BALLISTA_TURRET_SCENE):
		base = (load(BALLISTA_BASE_SCENE) as PackedScene).instantiate()
		turret = (load(BALLISTA_TURRET_SCENE) as PackedScene).instantiate()
	else:
		base = Node2D.new()
		var img := Sprite2D.new()
		img.texture = BALLISTA_FALLBACK
		img.offset = Vector2(0, -18)
		img.scale = Vector2.ONE * 0.7
		turret = img
	get_parent().add_child(base)
	base.global_position = at.round()
	base.y_sort_enabled = false
	base.add_child(turret)
	turret.position = Vector2.ZERO
	var dir := Vector2.from_angle(_aim)
	_face_turret(turret, dir)
	base.modulate.a = 0.0
	var show := base.create_tween()
	show.tween_property(base, "modulate:a", 1.0, 0.2)
	_hit_fx(at, Vector2.UP, 1.2)
	_ballistas.append({"base": base, "turret": turret, "at": at, "acc": 0.0, "dir": dir,
			"left": BALLISTA_TIME_LONG if _perk("b_ballista", 0) else BALLISTA_TIME})


func _face_turret(turret: Node2D, dir: Vector2) -> void:
	if turret.has_method("face"):
		turret.call("face", dir)
	elif turret is Sprite2D:
		(turret as Sprite2D).flip_h = dir.x < 0.0


func _process_ballistas(delta: float) -> void:
	for i in range(_ballistas.size() - 1, -1, -1):
		var b: Dictionary = _ballistas[i]
		var base: Node2D = b.base
		if not is_instance_valid(base):
			_ballistas.remove_at(i)
			continue
		b.left -= delta
		b.acc += delta
		var muzzle: Vector2 = b.at + Vector2(0, -BALLISTA_MUZZLE)
		var best: ProtoTarget = null
		var best_d := BALLISTA_RANGE * _area("b_ballista")
		for t in _live_targets():
			var d := t.center().distance_to(muzzle)
			if d <= best_d:
				best = t
				best_d = d
		if best:
			b.dir = (best.center() - muzzle).normalized()
			_face_turret(b.turret, b.dir)
		if b.acc >= BALLISTA_EVERY:
			b.acc = 0.0
			if best:
				if b.turret.has_method("play_anim"):
					b.turret.call("play_anim", &"shoot", true)
				_spawn_arrow(muzzle + b.dir * 10.0, b.dir.angle(), best, "b_ballista", 1.0, 1,
						BALLISTA_RANGE * _area("b_ballista") + 30.0)
		if b.left <= 0.0 or hero.dead:
			var fade := base.create_tween()
			fade.tween_property(base, "modulate:a", 0.0, 0.3)
			fade.tween_callback(base.queue_free)
			_ballistas.remove_at(i)


## Kamień Oblężnika: każda balista powtarza ze swojego miejsca umiejętność `id` gracza, za darmo, siłą ECHO_POWER.
func _ballista_echo(id: String, k := 1.0) -> void:
	if not _unique("b_ballista"):
		return
	for b in _ballistas:
		var at: Vector2 = b.at
		var muzzle := at + Vector2(0, -BALLISTA_MUZZLE)
		var best: ProtoTarget = null
		var best_d := Skills.DATA[id].range as float
		for t in _live_targets():
			var d := t.global_position.distance_to(at)
			if d <= best_d:
				best = t
				best_d = d
		var a: float = (best.center() - muzzle).angle() if best else (b.dir as Vector2).angle()
		match id:
			"b_seeker":
				_spawn_seeker(muzzle, a, ECHO_POWER)
			"b_rain":
				_add_rain(best.global_position if best else at + b.dir * 60.0, ECHO_POWER)
			"b_power":
				_power_release(at, a, k, ECHO_POWER)
		if b.turret.has_method("play_anim"):
			b.turret.call("play_anim", &"shoot", true)


# --- Przywołanie: Wierny Tropiciel ---

## Widmowa strzała krąży przy postaci i co SUMMON_EVERY s wypuszcza Poszukującą; rezerwuje część many.
func _call_summon() -> void:
	if _summon != null:
		return
	_summon = _SummonArrow.new()
	_summon.z_index = 22
	get_parent().add_child(_summon)
	_summon_acc = 0.0
	hero.summon_reserved = roundi(hero.max_mana * SUMMON_RESERVE)
	hero.apply_reserve()


func _dismiss_summon() -> void:
	if _summon != null and is_instance_valid(_summon):
		_summon.queue_free()
	_summon = null
	if hero and hero.summon_reserved > 0:
		hero.summon_reserved = 0
		hero.apply_reserve()


func _process_summon(delta: float) -> void:
	if _summon == null:
		return
	if hero.dead:
		_dismiss_summon()
		return
	_summon_angle += TAU / SUMMON_PERIOD * delta
	var ground := Vector2(cos(_summon_angle), sin(_summon_angle) * 0.5) * SUMMON_RADIUS
	_summon.global_position = hero.global_position + ground + Vector2(0, -20)
	_summon.rotation = _summon_angle + PI / 2.0
	_summon_acc += delta
	if _summon_acc >= SUMMON_EVERY:
		var best := _nearest(Skills.DATA.b_seeker.range)
		if best:
			_summon_acc = 0.0
			_aim = (best.center() - _summon.global_position).angle()
			_seekers(_summon.global_position, 1.0)


## Widmowa strzała przywołania (rysowana w kodzie): jasny grot i drzewce w kolorze powietrza, migocze.
class _SummonArrow extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Elements.color_of(Elements.AIR)
		var a := 0.55 + 0.2 * sin(_t * 6.0)
		draw_circle(Vector2.ZERO, 7.0, Color(c, 0.12 * a))
		draw_line(Vector2(-8, 0), Vector2(6, 0), Color(c, a), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(5, -3), Vector2(5, 3)]), Color(1, 1, 1, a))
		draw_line(Vector2(-8, 0), Vector2(-11, -3), Color(c, a * 0.8), 1.0)
		draw_line(Vector2(-8, 0), Vector2(-11, 3), Color(c, a * 0.8), 1.0)

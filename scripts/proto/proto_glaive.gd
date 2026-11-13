class_name ProtoGlaive
extends ProtoWeapon
## Glewia ognia (ustalone z autorem 13.11.2026) - druga broń po mieczu, żywioł ogień (Elements.FIRE). Lewituje obok
## postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, mana, odnowienia, kamienie, krytyki), ale bije inaczej:
## - zwykły cios „Pchnięcie glewii” (`g_thrust`): glewia cofa się i dźga daleko przed siebie, rani wszystkich na linii;
## - „Ognisty zamach” (`g_sweep`): szeroki półokrąg przed postacią, mocno podpala (5. poziom - odpycha, 10. - drugi
##   zamach w drugą stronę);
## - „Płonący ślad” (`g_trail`): doskok z pchnięciem w stronę wroga, rani na drodze, za postacią pas ognia na ziemi
##   (5. poziom - płonie dłużej, 10. - wybuch na końcu doskoku);
## - „Słup ognia” (`g_pillar`): glewia wznosi się i spada na wroga, wybuch ognia wokół i płonący krąg na ziemi
##   (5. poziom - większy krąg, 10. - drugi wybuch po chwili);
## - „Taniec płomieni” (`g_dance`, pomysł autora): glewia wiruje wokół postaci i co chwilę wypuszcza zamaszyste cięcie,
##   które powoli leci na zewnątrz (kolejne obracają się dookoła - na wszystkie strony) i przebija wrogów
##   (5. poziom - dłużej, 10. - po dwa cięcia naraz w przeciwne strony).
## Każde trafienie podpala (`_hit`): Skills.burn_of - ile obrażeń trafienia dopala się przez BURN_TIME (silniejsze
## podpalenie zastępuje słabsze - ProtoTarget.burn). Ogień na ziemi (`_zones`) co ZONE_TICK rani i podpala stojących
## w nim wrogów. Grafika glewii: assets/weapons/glaive.png (ostrze w prawo, rękojeść po lewej).

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
## Płonący ślad: długość i czas doskoku, połowa szerokości pasa, jak długo płonie (5. poziom - dłużej), wybuch z 10.
const TRAIL_DASH := 90.0
const TRAIL_TIME := 0.2
const TRAIL_WIDTH := 14.0
const TRAIL_BURN := 3.0
const TRAIL_BURN_LONG := 5.0
const TRAIL_BLAST_RADIUS := 40.0
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
## Taniec płomieni: czas (5. poziom - dłużej), obroty na sekundę, co ile cięcie, prędkość i zasięg cięć, promień trafienia.
const DANCE_TIME := 3.0
const DANCE_TIME_LONG := 4.0
const DANCE_SPIN := 1.4
const DANCE_EVERY := 0.3
const CUT_SPEED := 70.0
const CUT_DISTANCE := 150.0
const CUT_RADIUS := 15.0
## Ogień na ziemi: co ile rani i jaką częścią obrażeń umiejętności.
const ZONE_TICK := 0.5
const ZONE_POWER := 0.25
## Kolor ognia (efekty zastępcze, zanim dojdą grafiki z kreatora efektów).
const FIRE := Color(1.0, 0.55, 0.2)

## Lecące cięcia Tańca płomieni: {"fx", "dir", "left", "hits"}.
var _cuts: Array = []
## Ogień na ziemi: {"node", "a", "b", "radius", "left", "tick", "skill"} (odcinek a-b z promieniem; koło - a == b).
var _zones: Array = []
var _dance_left := 0.0
var _dance_acc := 0.0
var _sweep_again := false
var _dash_from := Vector2.ZERO
var _dash_to := Vector2.ZERO


func _init() -> void:
	basic = "g_thrust"
	main_skill = "g_thrust"


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = GLAIVE_TEXTURE
		s.offset = -G_GRIP
	_slash.modulate = FIRE
	_whirl_fx.modulate = Color(FIRE, 0.85)


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
	var dir := Vector2.from_angle(_aim)
	var any := false
	for t in _live_targets():
		var to := t.center() - _orbit_center()
		var along := to.dot(dir)
		if along >= 0.0 and along <= reach + 6.0 and absf(to.cross(dir)) <= THRUST_WIDTH:
			_hit(t, _swing_power * _power(basic), hero.global_position, basic, 2.0 if _perk(basic, 0) else 1.0)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, t.center().round(), HIT_FX_ANCHOR)
			any = true
	_flame_line(_orbit_center() + dir * 10.0, _orbit_center() + dir * reach, 0.15)
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
			_set_state("sweep")
		"g_trail":
			_dash_from = hero.global_position
			_dash_to = hero.global_position + Vector2.from_angle(_aim) * TRAIL_DASH * _area(id)
			_hit_set = []
			_set_state("trail")
		"g_pillar":
			_goal = best.position if best else hero.position + hero.facing.normalized() * 30.0
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			_set_state("pillar_rise")
		"g_dance":
			_spin = _aim
			_dance_left = DANCE_TIME_LONG if _perk(id, 0) else DANCE_TIME
			_dance_acc = DANCE_EVERY
			_whirl_fx.visible = true
			_whirl_fx.scale = Vector2.ONE * (G_LENGTH + 10.0) / WHIRL_FX_RADIUS
			_set_state("dance")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Ognisty zamach: glewia przechodzi łukiem SWEEP_ARC przed postacią; w połowie trafia wszystkich w łuku.
func _process_sweep() -> void:
	var k := clampf(_t / SWEEP_TIME, 0.0, 1.0)
	var a := _aim + lerpf(-SWEEP_ARC / 2.0, SWEEP_ARC / 2.0, ease(k, 0.5)) * _sign
	_place_line(a, 6.0)
	_slash.visible = true
	_slash.position = _orbit_center() - global_position
	_slash.rotation = _aim
	_slash.flip_v = _sign < 0.0
	_slash.scale = Vector2.ONE * SWEEP_RADIUS * _area("g_sweep") / SLASH_FX_RADIUS
	_slash.frame = mini(int(k * SLASH_FRAMES), SLASH_FRAMES - 1)
	if not _hit_done and k >= 0.5:
		_hit_done = true
		var radius := SWEEP_RADIUS * _area("g_sweep")
		for t in _live_targets():
			var to := t.center() - _orbit_center()
			if to.length() <= radius and absf(angle_difference(_aim, to.angle())) <= SWEEP_ARC / 2.0:
				_hit(t, _power("g_sweep"), hero.global_position, "g_sweep")
				if _perk("g_sweep", 0):
					t.push_away(hero.global_position, SWEEP_PUSH)
		Input.vibrate_handheld(20)
	if _t >= SWEEP_TIME:
		_slash.visible = false
		if _sweep_again and not hero.dead:
			_sweep_again = false
			_hit_done = false
			_sign = -_sign
			_set_state("sweep")
		else:
			_end_skill()


## Płonący ślad: postać doskakuje z wysuniętą glewią, rani wszystkich na drodze (każdego raz), a za nią zostaje pas ognia.
func _process_trail() -> void:
	var k := clampf(_t / TRAIL_TIME, 0.0, 1.0)
	var spot := hero.teleport(_dash_from.lerp(_dash_to, ease(k, 0.6)))
	_place_line(_aim, 6.0)
	for t in _live_targets():
		if _hit_set.has(t):
			continue
		var to := t.global_position - spot
		if to.length() <= TRAIL_WIDTH + 10.0 or (t.center() - _orbit_center()).length() <= G_LENGTH:
			_hit_set.append(t)
			_hit(t, _power("g_trail"), _dash_from, "g_trail")
	if _t >= TRAIL_TIME:
		var end := hero.global_position
		_add_zone(_dash_from, end, TRAIL_WIDTH * _area("g_trail"),
				TRAIL_BURN_LONG if _perk("g_trail", 0) else TRAIL_BURN, "g_trail")
		if _perk("g_trail", 1):
			_blast(end, TRAIL_BLAST_RADIUS * _area("g_trail"), _power("g_trail"), "g_trail")
		_end_skill()


## Słup ognia: glewia wznosi się nad cel ostrzem w dół, spada, wybuch ognia i płonący krąg; chwilę tkwi w ziemi.
func _process_pillar() -> void:
	match _state:
		"pillar_rise":
			var k := ease(clampf(_t / PILLAR_RISE, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(_goal, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -PILLAR_HEIGHT), k)
			_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
			if _t >= PILLAR_RISE:
				_set_state("pillar_fall")
		"pillar_fall":
			var k := clampf(_t / PILLAR_FALL, 0.0, 1.0)
			_sprite.position = Vector2(0, lerpf(-PILLAR_HEIGHT, -G_LENGTH + 6.0, k * k))
			if _t >= PILLAR_FALL:
				_pillar_hit(global_position)
				if _perk("g_pillar", 1):
					get_tree().create_timer(PILLAR_ECHO, false).timeout.connect(
							_blast.bind(global_position, PILLAR_RADIUS * _area("g_pillar"), _power("g_pillar"), "g_pillar"))
				_set_state("pillar_stuck")
		"pillar_stuck":
			if _t >= PILLAR_STUCK:
				_end_skill()


func _pillar_hit(at: Vector2) -> void:
	_blast(at, PILLAR_RADIUS * _area("g_pillar"), _power("g_pillar"), "g_pillar")
	var r := PILLAR_ZONE_RADIUS * _area("g_pillar") * (PILLAR_ZONE_BIG if _perk("g_pillar", 0) else 1.0)
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
	_flame_burst(at, radius)
	Input.vibrate_handheld(35)


## Taniec płomieni: glewia krąży wokół postaci, co DANCE_EVERY wypuszcza cięcie w kierunku, w którym akurat wskazuje.
func _process_dance(delta: float) -> void:
	_spin += TAU * DANCE_SPIN * delta
	_place_line(_spin, 4.0)
	_whirl_fx.position = _orbit_center() - global_position
	_whirl_fx.frame = int(_clock * WHIRL_FX_FPS) % WHIRL_FX_FRAMES
	_dance_left -= delta
	_dance_acc += delta
	if _dance_acc >= DANCE_EVERY:
		_dance_acc -= DANCE_EVERY
		_spawn_cut(_spin)
		if _perk("g_dance", 1):
			_spawn_cut(_spin + PI)
	if _dance_left <= 0.0:
		_end_skill()


## Zamaszyste cięcie Tańca płomieni: sierp ognia leci powoli od postaci pod kątem `a`.
func _spawn_cut(a: float) -> void:
	var fx := Sprite2D.new()
	fx.texture = WAVE_FX
	fx.hframes = WAVE_FX_FRAMES
	fx.centered = false
	fx.offset = -WAVE_FX_ANCHOR
	fx.z_index = 20
	fx.rotation = a
	fx.modulate = FIRE
	fx.scale = Vector2.ONE * _area("g_dance")
	get_parent().add_child(fx)
	fx.global_position = _orbit_center()
	_cuts.append({"fx": fx, "dir": Vector2.from_angle(a), "left": CUT_DISTANCE * _area("g_dance"), "hits": []})


func _process_cuts(delta: float) -> void:
	for i in range(_cuts.size() - 1, -1, -1):
		var c: Dictionary = _cuts[i]
		var fx: Sprite2D = c.fx
		var step := CUT_SPEED * delta
		fx.global_position += c.dir * step
		fx.frame = int(_clock * 12.0) % WAVE_FX_FRAMES
		c.left -= step
		fx.modulate.a = clampf(c.left / 30.0, 0.0, 1.0)
		var reach := CUT_RADIUS * _area("g_dance")
		for t in _live_targets():
			if not c.hits.has(t) and t.center().distance_to(fx.global_position) <= reach:
				c.hits.append(t)
				_hit(t, _power("g_dance"), fx.global_position - c.dir * 10.0, "g_dance")
		if c.left <= 0.0:
			fx.queue_free()
			_cuts.remove_at(i)


# --- Ogień na ziemi ---

## Pas (a-b) albo koło (a == b) ognia na `time` sekund; co ZONE_TICK rani i podpala wrogów w środku.
func _add_zone(a: Vector2, b: Vector2, radius: float, time: float, skill: String) -> void:
	var node := _FireZone.new()
	node.a = a
	node.b = b
	node.radius = radius
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO  # a i b w układzie świata
	_zones.append({"node": node, "a": a, "b": b, "radius": radius, "left": time, "tick": ZONE_TICK, "skill": skill})


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
		else:
			z.node.fade = clampf(z.left / 0.5, 0.0, 1.0)


## Czy punkt `p` (stopy wroga) stoi w ogniu strefy `z` (odległość od odcinka, rzut z góry - spłaszczony pion).
static func _in_zone(z: Dictionary, p: Vector2) -> bool:
	var a: Vector2 = z.a
	var b: Vector2 = z.b
	var ab := b - a
	var k := 0.0 if ab.length_squared() < 0.01 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var d := p - a.lerp(b, k)
	return Vector2(d.x, d.y * 1.6).length() <= z.radius


func _end_skill() -> void:
	super._end_skill()
	_slash.modulate = FIRE
	_cooldown = maxf(_cooldown, THRUST_COOLDOWN * 0.5)


## Zastępczy błysk ognia wzdłuż pchnięcia (do podmiany na efekt z kreatora).
func _flame_line(a: Vector2, b: Vector2, time: float) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(FIRE, 0.8)
	line.add_point(a)
	line.add_point(b)
	line.z_index = 6
	get_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, time)
	tween.tween_callback(line.queue_free)


## Zastępczy wybuch ognia: pierścień rośnie i gaśnie (do podmiany na efekt z kreatora).
func _flame_burst(at: Vector2, radius: float) -> void:
	var node := _FireZone.new()
	node.a = at
	node.b = at
	node.radius = radius
	node.burst = true
	node.z_index = 6
	get_parent().add_child(node)
	node.global_position = Vector2.ZERO
	var tween := node.create_tween()
	tween.tween_property(node, "fade", 0.0, 0.35).from(1.0)
	tween.tween_callback(node.queue_free)


## Rysunek ognia na ziemi: migoczące plamy płomieni wzdłuż pasa albo w kole (zastępczo, w kodzie).
class _FireZone extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var radius := 10.0
	var fade := 1.0:
		set(v):
			fade = v
			queue_redraw()
	var burst := false
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var ab := b - a
		var n := maxi(1, int(ab.length() / 10.0)) if ab.length() > 1.0 else 1
		if burst:
			draw_circle(a, radius * (1.2 - 0.4 * fade), Color(1.0, 0.6, 0.2, 0.45 * fade))
			draw_arc(a, radius * (1.2 - 0.4 * fade), 0.0, TAU, 32, Color(1.0, 0.85, 0.4, fade), 2.0)
			return
		for i in n + 1:
			var p := a.lerp(b, float(i) / n) if n > 0 else a
			if ab.length() <= 1.0:
				for j in 7:
					var ang := TAU * j / 7.0 + _t
					var q := p + Vector2(cos(ang), sin(ang) / 1.6) * radius * 0.6
					_flame(q, radius * 0.45)
				_flame(p, radius * 0.6)
			else:
				_flame(p, radius * 0.9)

	func _flame(p: Vector2, r: float) -> void:
		var flick := 0.8 + 0.2 * sin(_t * 13.0 + p.x * 0.7 + p.y)
		draw_set_transform(p, 0.0, Vector2(1.0, 1.0 / 1.6))
		draw_circle(Vector2.ZERO, r * flick, Color(0.85, 0.25, 0.05, 0.35 * fade))
		draw_circle(Vector2.ZERO, r * 0.55 * flick, Color(1.0, 0.6, 0.15, 0.55 * fade))
		draw_set_transform(Vector2.ZERO)

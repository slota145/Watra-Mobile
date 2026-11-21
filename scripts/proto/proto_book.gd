class_name ProtoBook
extends ProtoWeapon
## Księga Arkanów (ankieta z autorem 21.11.2026) - broń magiczna, żywioł Arkana (Elements.ARCANE: trafienia wysysają
## manę). Księga lewituje obok postaci (dziedziczy po ProtoWeapon: mana, odnowienia, kamienie, krytyki, kolejka
## umiejętności); szybkość czarów - szybkość rzucania (HeroStats.weapon_speed_mult), premia obrażeń magicznych.
## - „Pociski Arkanów” (`a_missiles`, zwykły atak): MISSILES pocisków leci łukiem albo zakosami - pierwszy w najbliższego
##   wroga, reszta w losowych wrogów w zasięgu; ogon rysowany w grze wygina się po torze lotu (Line2D z ostatnich pozycji).
##   Pociski wylatują po kolei co MISSILE_STAGGER s (prośba autora 21.11.2026; kolejne rzuty mogą się zazębiać).
##   5. poziom - 4 pociski, 10. - co trzeci rzut 2 więcej; kamień unikalny - z trafionego SHARDS odłamków (z ogonem)
##   w dalszych wrogów (SHARD_MIN-SHARD_REACH px - widać, jak lecą).
## - „Krąg Mocy” (`a_circle`): krąg pod postacią rani wszystkich w CIRCLE_RADIUS (5. - większy, 10. - drugi błysk);
##   kamień unikalny - krąg zostaje TRAIL_CIRCLE_TIME s i rani co CIRCLE_TICK, a postać w nim ma czary o CIRCLE_BUFF
##   silniejsze i jeden pocisk więcej.
## - „Kule Arkanów” (`a_orbs`, przełącznik jak aura - Skills.is_toggle): ORBS kul krąży wokół postaci i rani dotkniętych;
##   rezerwuje ORB_RESERVE many; obrót - szybkość rzucania, promień i wielkość - obszar (5. - silniejsze, 10. - +2 kule;
##   aura Rój Strzyboga dokłada kule - `extra_projectiles`);
##   kamień unikalny - druga orbita dalej, w przeciwną stronę.
## - „Promień Arkanów” (`a_beam`, trzymany - Skills.is_charged): promień z dłoni postaci (błysk arcane_beam_cast) w najbliższego
##   wroga (rozbryzg arcane_beam_impact na końcu), co BEAM_TICK rani cel
##   i wrogów w BEAM_AREA wokół niego; mana co sekundę (5. - przeskok na drugiego wroga, 10. - większy obszar);
##   kamień unikalny - co EMANATE_EVERY s od postaci rozchodzi się fala magii (arcane_wave; rani wokół).
## - „Pieczęcie Wybuchu” (`a_seals`): pieczęcie pod SEALS wrogami oddalonymi od siebie, po SEAL_DELAY s wybuch
##   (5. - 6 pieczęci, 10. - ogłusza); kamień unikalny - pieczęcie łączy raniąca wiązka.
## Grafika: efekty z kreatora PixelLab (assets/effects/arcane_*.png - FX; bez nich kształty rysowane w kodzie),
## księga ze SpriteKiln (assets/spritekiln/book/arcane_book.png; bez niej - rysowana).

const BOOK_TEXTURE := "res://assets/spritekiln/book/arcane_book.png"
const BOOK_SCALE := 0.7
const ARCANE := Color(0.82, 0.6, 1.0)
const ARCANE_CORE := Color(1.0, 0.95, 1.0)
## Efekty z kreatora (pixellab_src/vfx/ids.json): nazwa -> [klatki, fps, zaczepienie]. Brak pliku - kształt z kodu.
const FX := {
	"arcane_missile": [6, 12.0, Vector2(8, 8)],
	"arcane_hit": [6, 14.0, Vector2(23, 21)],
	"arcane_circle": [12, 12.0, Vector2(55, 23)],
	"arcane_orb": [6, 12.0, Vector2(8, 8)],
	"arcane_beam": [6, 12.0, Vector2(0, 8)],
	"arcane_beam_hit": [6, 12.0, Vector2(16, 16)],
	"arcane_seal": [10, 12.0, Vector2(27, 15)],
	"arcane_blast": [9, 18.0, Vector2(36, 20)],
	"arcane_shard": [4, 16.0, Vector2(8, 8)],
	"arcane_beam_cast": [6, 12.0, Vector2(12, 12)],
	"arcane_beam_impact": [6, 12.0, Vector2(20, 20)],
	"arcane_wave": [9, 16.0, Vector2(60, 30)],
}
## Promień fali magii w arkuszu (połowa szerokości największej klatki - do skalowania).
const WAVE_FX_RADIUS := 60.0
## Promień, w jakim narysowane są efekty obszarowe (połowa szerokości kręgu - do skalowania).
const CIRCLE_FX_RADIUS := 55.0
const BLAST_FX_RADIUS := 36.0
const SEAL_FX_RADIUS := 27.0
## Krąg z kreatora jest pętlą - rozbłysk (CIRCLE_FLASH s) i przygaszenie w grze; trwały krąg pod potworami ciemniej.
const CIRCLE_FLASH := 0.5
const CIRCLE_TRAIL_ALPHA := 0.45

## Pociski: liczba, prędkość, skręt (rad/s), zakosy (siła i częstotliwość), promień trafienia, czas życia, ogon.
const MISSILES := 3
const MISSILES_PERK := 4
const MISSILES_EXTRA := 2
const MISSILE_SPEED := 190.0
const MISSILE_TURN := 7.0
const MISSILE_WOBBLE := 2.6
const MISSILE_WOBBLE_FREQ := 9.0
const MISSILE_SPREAD := deg_to_rad(55.0)
const MISSILE_RADIUS := 8.0
const MISSILE_LIFE := 2.4
const TAIL_POINTS := 12
const TAIL_WIDTH := 6.0
const MISSILE_STAGGER := 0.08
const CAST_TIME := 0.16
const CAST_COOLDOWN := 0.6
## Odłamki (kamień unikalny pocisków): ile, zasięg szukania, prędkość, siła względem pocisku.
const SHARDS := 3
const SHARD_MIN := 35.0
const SHARD_REACH := 120.0
const SHARD_SPEED := 200.0
const SHARD_POWER := 0.4
const SHARD_SIZE := 1.4
const SHARD_TAIL := 6
## Promień wychodzi z dłoni: tyle nad stopami i tyle przed postacią w stronę celu.
const HAND_HEIGHT := 13.0
const HAND_REACH := 7.0
## Krąg Mocy: promień, 5. poziom, drugi błysk z 10., trwały krąg z kamieniem unikalnym (czas, tyknięcia, siła tyknięcia,
## premia czarów w kręgu).
const CIRCLE_RADIUS := 55.0
const CIRCLE_PERK := 1.3
const CIRCLE_SECOND := 0.5
const TRAIL_CIRCLE_TIME := 8.0
const CIRCLE_TICK := 0.5
const CIRCLE_TICK_POWER := 0.35
const CIRCLE_BUFF := 1.3
## Kule: liczba, rezerwacja many, okres obrotu (s, przy szybkości rzucania 1), promień orbity, promień trafienia kuli,
## co ile ta sama kula może trafić tego samego wroga, 5. poziom (siła), druga orbita (odległość).
const ORBS := 3
const ORBS_EXTRA := 2
const ORB_RESERVE := 0.2
const ORB_PERIOD := 2.2
const ORB_RADIUS := 34.0
const ORB_HIT := 7.0
const ORB_REHIT := 0.45
const ORB_PERK := 1.3
const ORB_OUTER := 1.7
## Promień: co ile trafia, obszar wokół celu, przeskok (zasięg, siła), 10. poziom (obszar), emanacja (co ile, promień,
## siła).
const BEAM_TICK := 0.2
const BEAM_AREA := 26.0
const BEAM_CHAIN := 80.0
const BEAM_CHAIN_POWER := 0.7
const BEAM_AREA_PERK := 1.5
const EMANATE_EVERY := 0.5
const EMANATE_RADIUS := 60.0
const EMANATE_POWER := 0.4
## Pieczęcie: ile (5. poziom - więcej), najmniejszy odstęp, opóźnienie wybuchu, promień, ogłuszenie z 10., wiązki
## (szerokość, co ile ranią, siła).
const SEALS := 4
const SEALS_PERK := 6
const SEAL_GAP := 40.0
const SEAL_DELAY := 0.8
const SEAL_RADIUS := 34.0
const SEAL_STUN := 0.5
const LINK_WIDTH := 8.0
const LINK_TICK := 0.2
const LINK_POWER := 0.25

var _missiles: Array = []
## Pociski czekające na wylot (rzut po kolei): {"wait", "target", "angle", "power", "chaotic"}.
var _volley: Array = []
var _beam_cast_fx: Node2D
var _shards: Array = []
var _circles: Array = []
var _seals: Array = []
var _orbs: Array = []
var _orbs_on := false
var _orb_angle := 0.0
## Ostatnie trafienie wroga przez kule (wróg -> czas zegara) - jedna kula nie bije tego samego co klatkę.
var _orb_hits := {}
var _beam: Line2D
var _beam2: Line2D
var _beam_hit_fx: Node2D
var _beam_target: ProtoTarget
var _beam_tick := 0.0
var _beam_mana := 0.0
var _emanate := 0.0
var _cast_count := 0
var _fx_cache := {}


func _world_fx() -> Array:
	return super._world_fx() + [_missiles, _shards, _circles, _seals, _orbs, [_beam, _beam2, _beam_hit_fx, _beam_cast_fx]]


func _init() -> void:
	basic = "a_missiles"
	main_skill = "a_missiles"
	element = Elements.ARCANE


func _ready() -> void:
	super._ready()
	var tex: Texture2D = load(BOOK_TEXTURE) if ResourceLoader.exists(BOOK_TEXTURE) else _drawn_book()
	for s in [_sprite] + _ghosts:
		s.texture = tex
		s.centered = true
		s.offset = Vector2.ZERO
		s.scale = Vector2.ONE * (BOOK_SCALE if ResourceLoader.exists(BOOK_TEXTURE) else 1.0)


func _exit_tree() -> void:
	_orbs_off()
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"book_cast":
			_process_cast()
		"beam":
			_process_beam(delta)
	_process_volley(delta)
	_process_missiles(delta)
	_process_shards(delta)
	_process_circles(delta)
	_process_seals(delta)
	_process_orbs(delta)


## Księga unosi się obok postaci i lekko kołysze (otwarta, okładką do góry).
func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	_sprite.position = _sprite.position.lerp(Vector2(0, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0)), k)
	_sprite.rotation = lerp_angle(_sprite.rotation, 0.08 * sin(_clock * 1.7), k)


## Trafienie czarem (obrażenia jak każdej broni - `_deal`, z premią kręgu z kamieniem unikalnym).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power * _circle_buff()), from, skill)


# --- efekty: arkusz z kreatora albo kształt z kodu ---

func _fx_tex(name: String) -> Texture2D:
	if not _fx_cache.has(name):
		var path := "res://assets/effects/%s.png" % name
		_fx_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _fx_cache[name]


## Efekt raz w punkcie świata `at` (skala `size`); bez arkusza - rozbłysk rysowany w kodzie.
func _fx_once(name: String, at: Vector2, size := 1.0, z := 21) -> Node2D:
	var tex := _fx_tex(name)
	if tex != null:
		if Fx.crowded(tex):
			return null
		var d: Array = FX[name]
		return Fx.once(get_parent(), tex, d[0], d[1], at.round(), d[2], z, size)
	var flash := _Flash.new()
	flash.radius = 12.0 * size
	flash.z_index = z
	get_parent().add_child(flash)
	flash.global_position = at
	return flash


## Efekt zapętlony jako dziecko `parent` (kula, głowa pocisku, pieczęć); bez arkusza - kropla światła.
func _fx_loop(name: String, parent: Node, size := 1.0, z := 0) -> Node2D:
	var tex := _fx_tex(name)
	if tex != null:
		var d: Array = FX[name]
		return Fx.loop(parent, tex, d[0], d[1], Vector2.ZERO, d[2], z, size)
	var glow := _Glow.new()
	glow.radius = 5.0 * size
	glow.z_index = z
	parent.add_child(glow)
	return glow


## Księga narysowana w kodzie (gdy nie ma renderu ze SpriteKiln): fioletowa okładka, jasne kartki, świecące runy.
static func _drawn_book() -> Texture2D:
	var img := Image.create(20, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 20:
		for y in 14:
			var edge := x == 0 or x == 19 or y == 13
			if y >= 2:
				img.set_pixel(x, y, Color(0.32, 0.14, 0.5) if edge or y >= 11 else Color(0.95, 0.9, 0.8))
	for x in [4, 6, 8, 12, 14, 16]:
		img.set_pixel(x, 5, ARCANE)
		img.set_pixel(x, 7, ARCANE)
	for y in range(2, 12):
		img.set_pixel(10, y, Color(0.45, 0.25, 0.6))
	return ImageTexture.create_from_image(img)


# --- Pociski Arkanów (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	var best := _nearest(Skills.DATA.a_missiles.range * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_hit_done = false
	_set_state("book_cast")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _process_cast() -> void:
	_sprite.position = Vector2(0, -HOVER_HEIGHT - 3.0 * sin(clampf(_t / CAST_TIME, 0.0, 1.0) * PI))
	if not _hit_done and _t >= CAST_TIME * 0.5:
		_hit_done = true
		_fire_missiles()
	if _t >= CAST_TIME:
		if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
			_attack(true)  # Mnożenie: drugi rzut
		else:
			_second = false
			_swing_power = 1.0
			_set_state("follow")
			_cooldown = CAST_COOLDOWN


## Ile pocisków w tym rzucie (5. poziom, co trzeci rzut z 10., trwały krąg, aura Rój Strzyboga).
func missile_count() -> int:
	var n := MISSILES_PERK if _perk(basic, 0) else MISSILES
	if _perk(basic, 1) and _strike_count % 3 == 0:
		n += MISSILES_EXTRA
	if _circle_buff() > 1.0:
		n += 1
	return n + extra_projectiles


func _fire_missiles() -> void:
	var reach: float = Skills.DATA.a_missiles.range * _area(basic)
	var pool := _near(hero.global_position, reach).filter(func(t: ProtoTarget) -> bool:
		return t.global_position.distance_to(hero.global_position) <= reach)
	pool.shuffle()
	var first := _nearest(reach)
	var n := missile_count()
	var power := _power(basic) * _swing_power * projectile_mult
	for i in n:
		var target: ProtoTarget = first if i == 0 else (pool[i % pool.size()] if not pool.is_empty() else first)
		var side := 1.0 if i % 2 == 0 else -1.0
		var a := _aim + side * MISSILE_SPREAD * (0.4 + 0.6 * randf()) * (0.0 if i == 0 and n == 1 else 1.0)
		_volley.append({"wait": MISSILE_STAGGER * i, "target": target, "angle": a, "power": power, "chaotic": randf() < 0.5})
	_process_volley(0.0)  # pierwszy od razu
	_cast_count += 1


## Wylot pocisków po kolei (z szybkością rzucania); cel, który zdążył paść, zastępuje najbliższy.
func _process_volley(delta: float) -> void:
	if _volley.is_empty():
		return
	var keep: Array = []
	for v: Dictionary in _volley:
		v.wait -= delta * speed_mult * (1.0 + speed_bonus)
		if v.wait > 0.0:
			keep.append(v)
			continue
		var t: ProtoTarget = v.target
		if t == null or not is_instance_valid(t) or not t.alive():
			t = _nearest(Skills.DATA.a_missiles.range * _area(basic))
		_spawn_missile(_sprite.global_position, v.angle, t, v.power, v.chaotic)
	_volley = keep


## Pocisk: lot ze skrętem ku celowi (łukiem) albo z zakosami (`chaotic`); ogon - Line2D z ostatnich pozycji.
func _spawn_missile(from: Vector2, a: float, target: ProtoTarget, power: float, chaotic: bool) -> void:
	var tail := Line2D.new()
	tail.width = TAIL_WIDTH
	tail.z_index = 20
	tail.joint_mode = Line2D.LINE_JOINT_ROUND
	tail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(1, 1))
	tail.width_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.55, 0.25, 0.95, 0.0))
	grad.set_color(1, Color(ARCANE, 0.95))
	grad.add_point(0.75, Color(0.7, 0.4, 1.0, 0.7))
	tail.gradient = grad
	tail.top_level = true
	get_parent().add_child(tail)
	var head := Node2D.new()
	head.z_index = 21
	get_parent().add_child(head)
	head.global_position = from
	_fx_loop("arcane_missile", head)
	_missiles.append({"node": head, "tail": tail, "pos": from, "vel": Vector2.from_angle(a) * MISSILE_SPEED,
			"target": target, "power": power, "chaotic": chaotic, "life": MISSILE_LIFE, "phase": randf() * TAU,
			"trail": [from]})


func _process_missiles(delta: float) -> void:
	var keep: Array = []
	for m: Dictionary in _missiles:
		m.life -= delta
		var t: ProtoTarget = m.target
		if t == null or not is_instance_valid(t) or not t.alive():
			t = _nearest_to(m.pos, Skills.DATA.a_missiles.range)
			m.target = t
		var vel: Vector2 = m.vel
		if t != null:
			var want: float = (t.center() - m.pos).angle()
			var turn: float = MISSILE_TURN * delta * (1.0 + (MISSILE_LIFE - m.life))  # coraz ciaśniej - zawsze doleci
			vel = vel.rotated(clampf(angle_difference(vel.angle(), want), -turn, turn))
		if m.chaotic:
			vel = vel.rotated(sin(_clock * MISSILE_WOBBLE_FREQ + m.phase) * MISSILE_WOBBLE * delta)
		m.vel = vel
		m.pos += vel * delta
		m.node.global_position = (m.pos as Vector2).round()
		m.node.rotation = vel.angle()
		m.trail.append(m.pos)
		if m.trail.size() > TAIL_POINTS:
			m.trail.pop_front()
		(m.tail as Line2D).points = PackedVector2Array(m.trail)
		var hit := t != null and is_instance_valid(t) and (m.pos as Vector2).distance_to(t.center()) <= MISSILE_RADIUS + 4.0
		if hit:
			_hit(t, m.power, m.pos, basic)
			_fx_once("arcane_hit", m.pos, 0.8)
			if _unique(basic):
				_spawn_shards(t, m.power)
		if hit or m.life <= 0.0:
			m.node.queue_free()
			m.tail.queue_free()
		else:
			keep.append(m)
	_missiles = keep


func _nearest_to(at: Vector2, reach: float) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := reach
	for t in _near(at, reach):
		var d := at.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


## Kamień Rozprysku: z trafionego wroga SHARDS odłamków - najpierw w dalszych wrogów (SHARD_MIN-SHARD_REACH px, żeby
## było widać lot; prośba autora 21.11.2026), a gdy ich brak - w bliższych. Odłamek większy, z krótkim ogonem.
func _spawn_shards(from_t: ProtoTarget, power: float) -> void:
	var at := from_t.center()
	var near := _near_c(at, SHARD_REACH).filter(func(t: ProtoTarget) -> bool:
		return t != from_t and t.center().distance_to(at) <= SHARD_REACH)
	near.shuffle()
	near.sort_custom(func(a: ProtoTarget, b: ProtoTarget) -> bool:  # dalsi (od SHARD_MIN) przed bliższymi
		return (a.center().distance_to(at) >= SHARD_MIN) and not (b.center().distance_to(at) >= SHARD_MIN))
	for i in mini(SHARDS, near.size()):
		var node := Node2D.new()
		node.z_index = 21
		get_parent().add_child(node)
		node.global_position = at
		_fx_loop("arcane_shard", node, SHARD_SIZE)
		var tail := Line2D.new()
		tail.width = 4.0
		tail.z_index = 20
		tail.top_level = true
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0))
		curve.add_point(Vector2(1, 1))
		tail.width_curve = curve
		var grad := Gradient.new()
		grad.set_color(0, Color(0.55, 0.25, 0.95, 0.0))
		grad.set_color(1, Color(ARCANE_CORE, 0.9))
		tail.gradient = grad
		get_parent().add_child(tail)
		_shards.append({"node": node, "tail": tail, "trail": [at], "pos": at, "target": near[i],
				"power": power * SHARD_POWER})


func _process_shards(delta: float) -> void:
	var keep: Array = []
	for s: Dictionary in _shards:
		var t: ProtoTarget = s.target
		var to: Vector2 = t.center() - s.pos if t != null and is_instance_valid(t) and t.alive() else Vector2.ZERO
		if to == Vector2.ZERO or to.length() <= SHARD_SPEED * delta + 3.0:
			if to != Vector2.ZERO:
				_hit(t, s.power, s.pos, basic)
				_fx_once("arcane_hit", s.pos, 0.6)
			s.node.queue_free()
			s.tail.queue_free()
			continue
		s.pos += to.normalized() * SHARD_SPEED * delta
		s.node.global_position = (s.pos as Vector2).round()
		s.node.rotation = to.angle()
		s.trail.append(s.pos)
		if s.trail.size() > SHARD_TAIL:
			s.trail.pop_front()
		(s.tail as Line2D).points = PackedVector2Array(s.trail)
		keep.append(s)
	_shards = keep


# --- Umiejętności ---

func cooldown_full(id: String) -> float:
	if Skills.is_toggle(id):
		return 0.0
	return super.cooldown_full(id)


func can_use(id: String) -> bool:
	if Skills.is_toggle(id):
		return Skills.has(id) and not hero.dead
	if id == "a_beam":
		return Skills.has(id) and not hero.dead and hero.can_pay(_beam_tick_cost())
	return super.can_use(id)


func cast(id: String) -> bool:
	if id == "a_orbs" and not hero.dead:
		if _orbs_on:
			_orbs_off()
		else:
			_orbs_on_now()
		skill_used.emit(id)
		return true
	return super.cast(id)


func _start(id: String) -> void:
	if id == basic or not id in ["a_circle", "a_beam", "a_seals"]:
		super._start(id)
		return
	if id == "a_beam":
		if not can_use(id):
			return
		_beam_target = null
		_beam_tick = 0.0
		_beam_mana = 0.0
		_emanate = 0.0
		_set_state("beam")
		skill_used.emit(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	match id:
		"a_circle":
			_cast_circle(hero.global_position, false)
			if _perk(id, 1):
				var at := hero.global_position
				get_tree().create_timer(CIRCLE_SECOND, false).timeout.connect(func() -> void:
					if is_inside_tree() and not hero.dead:
						_cast_circle(at, true))
		"a_seals":
			_cast_seals()
	hero.play_gesture(_orbit_center() + Vector2(0, -10))
	skill_used.emit(id)


# --- Krąg Mocy ---

func _circle_radius() -> float:
	return CIRCLE_RADIUS * _area("a_circle") * (CIRCLE_PERK if _perk("a_circle", 0) else 1.0)


## Krąg pod postacią: rani wszystkich w promieniu; z kamieniem unikalnym zostaje na ziemi (`echo` - drugi błysk z 10.
## poziomu nie zostawia kolejnego kręgu).
func _cast_circle(at: Vector2, echo: bool) -> void:
	var r := _circle_radius()
	_ring_hit(at, r, _power("a_circle"), "a_circle")
	_circle_fx(at, r)
	Input.vibrate_handheld(20)
	if _unique("a_circle") and not echo:
		var ring: Node2D
		if _fx_tex("arcane_circle") != null:
			ring = Node2D.new()
			_fx_loop("arcane_circle", ring, r / CIRCLE_FX_RADIUS)
			ring.modulate.a = CIRCLE_TRAIL_ALPHA
		else:
			ring = _Ring.new()
			ring.radius = r
		ring.z_index = -1
		get_parent().add_child(ring)
		ring.global_position = at
		_circles.append({"node": ring, "at": at, "r": r, "life": TRAIL_CIRCLE_TIME, "tick": 0.0})


## Rozbłysk kręgu w punkcie `at` o promieniu `r`: pętla z kreatora, która gaśnie po CIRCLE_FLASH s.
func _circle_fx(at: Vector2, r: float) -> void:
	if _fx_tex("arcane_circle") == null:
		_fx_once("arcane_circle", at, r / 48.0, -1)
		return
	var node := Node2D.new()
	node.z_index = -1
	get_parent().add_child(node)
	node.global_position = at
	_fx_loop("arcane_circle", node, r / CIRCLE_FX_RADIUS)
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, CIRCLE_FLASH).from(0.9).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)


## Wszyscy wrogowie w spłaszczonym kręgu (elipsa 2:1 jak cień) dostają trafienie.
func _ring_hit(at: Vector2, r: float, power: float, skill: String) -> void:
	for t in _near(at, r):
		var d := t.global_position - at
		d.y *= 2.0
		if d.length() <= r:
			_later(t, _hit.bind(t, power, at, skill))


func _process_circles(delta: float) -> void:
	var keep: Array = []
	for c: Dictionary in _circles:
		c.life -= delta
		c.tick -= delta
		if c.tick <= 0.0:
			c.tick = CIRCLE_TICK
			_ring_hit(c.at, c.r, _power("a_circle") * CIRCLE_TICK_POWER, "a_circle")
		c.node.modulate.a = clampf(c.life, 0.0, 1.0) * (CIRCLE_TRAIL_ALPHA if not c.node is _Ring else 1.0)
		if c.life <= 0.0:
			c.node.queue_free()
		else:
			keep.append(c)
	_circles = keep


## Premia trwałego kręgu (kamień unikalny Kręgu Mocy): postać w kręgu - czary silniejsze (i pocisk więcej).
func _circle_buff() -> float:
	if hero == null:
		return 1.0
	for c: Dictionary in _circles:
		var d: Vector2 = hero.global_position - c.at
		d.y *= 2.0
		if d.length() <= c.r:
			return CIRCLE_BUFF
	return 1.0


# --- Kule Arkanów (przełącznik, rezerwuje manę) ---

func orbs_on() -> bool:
	return _orbs_on


## Kule na jednej orbicie: podstawa, 10. poziom i aura Rój Strzyboga (każdy jej pocisk to kula więcej).
func _orb_count() -> int:
	return ORBS + (ORBS_EXTRA if _perk("a_orbs", 1) else 0) + extra_projectiles


func _orbs_on_now() -> void:
	_orbs_on = true
	_orb_hits.clear()
	var rings := 2 if _unique("a_orbs") else 1
	for ring in rings:
		for i in _orb_count():
			var node := Node2D.new()
			node.z_index = 21
			get_parent().add_child(node)
			_fx_loop("arcane_orb", node, _orb_size())
			_orbs.append({"node": node, "ring": ring, "i": i})
	hero.summon_reserved = roundi(hero.max_mana * ORB_RESERVE)
	hero.apply_reserve()


func _orbs_off() -> void:
	for o: Dictionary in _orbs:
		if is_instance_valid(o.node):
			o.node.queue_free()
	_orbs.clear()
	_orbs_on = false
	if hero and hero.summon_reserved > 0:
		hero.summon_reserved = 0
		hero.apply_reserve()


func _orb_size() -> float:
	return clampf(_area("a_orbs"), 0.7, 2.0)


## Pozycja kuli `i` z orbity `ring` (0 - wewnętrzna, 1 - zewnętrzna, w przeciwną stronę) na ziemi wokół postaci.
func orb_position(ring: int, i: int) -> Vector2:
	var n := _orb_count()
	var a := _orb_angle * (1.0 if ring == 0 else -1.0) + TAU * i / n + (PI / n if ring == 1 else 0.0)
	var r := ORB_RADIUS * _area("a_orbs") * (ORB_OUTER if ring == 1 else 1.0)
	return hero.global_position + Vector2(cos(a), sin(a) * 0.5) * r + Vector2(0, -ORBIT_HEIGHT)


func _process_orbs(delta: float) -> void:
	if not _orbs_on:
		return
	if hero.dead:
		_orbs_off()
		return
	if _orbs.size() != _orb_count() * (2 if _unique("a_orbs") else 1):  # 10. poziom albo kamień - od nowa
		_orbs_off()
		_orbs_on_now()
	_orb_angle += TAU / ORB_PERIOD * speed_mult * (1.0 + speed_bonus) * delta
	var power := _power("a_orbs") * (ORB_PERK if _perk("a_orbs", 0) else 1.0)
	var reach := ORB_HIT * _orb_size()
	for o: Dictionary in _orbs:
		var at := orb_position(o.ring, o.i)
		o.node.global_position = at.round()
		for t in _near_c(at, reach):
			if t.center().distance_to(at) > reach + t.center_height * 0.4:
				continue
			var key := "%d:%d" % [t.get_instance_id(), o.ring * 100 + o.i]
			if _clock - float(_orb_hits.get(key, -10.0)) < ORB_REHIT:
				continue
			_orb_hits[key] = _clock
			_hit(t, power, at, "a_orbs")
			_fx_once("arcane_hit", t.center(), 0.5)
	if _orb_hits.size() > 400:
		_orb_hits.clear()


# --- Promień Arkanów (trzymany) ---

## Mana jednego tyknięcia promienia (koszt umiejętności jest na sekundę).
func _beam_tick_cost() -> int:
	return maxi(1, ceili(mana_cost("a_beam") * BEAM_TICK))


func _beam_area() -> float:
	return BEAM_AREA * _area("a_beam") * (BEAM_AREA_PERK if _perk("a_beam", 1) else 1.0)


func _process_beam(delta: float) -> void:
	_follow(delta)  # księga unosi się dalej obok, promień leci z dłoni
	var reach: float = Skills.DATA.a_beam.range * _area("a_beam")
	if _beam_target == null or not is_instance_valid(_beam_target) or not _beam_target.alive() \
			or _beam_target.global_position.distance_to(hero.global_position) > reach * 1.2:
		_beam_target = _nearest(reach)
	var from := _hand_point()
	if _beam_target != null:
		_aim = (_beam_target.center() - from).angle()
	_beam_tick -= delta
	if _beam_tick <= 0.0:
		_beam_tick = BEAM_TICK
		if not hero.spend_mana(_beam_tick_cost()):
			_end_skill()
			return
		if _beam_target != null:
			var at := _beam_target.center()
			for t in _near_c(at, _beam_area()):
				if t.center().distance_to(at) <= _beam_area():
					_later(t, _hit.bind(t, _power("a_beam"), at, "a_beam"))
			var second := _beam_second()
			if second != null:
				_later(second, _hit.bind(second, _power("a_beam") * BEAM_CHAIN_POWER, at, "a_beam"))
	if _unique("a_beam"):
		_emanate -= delta
		if _emanate <= 0.0:
			_emanate = EMANATE_EVERY
			var r := EMANATE_RADIUS * _area("a_beam")
			_ring_hit(hero.global_position, r, _power("a_beam") * EMANATE_POWER, "a_beam")
			if _fx_tex("arcane_wave") != null:
				_fx_once("arcane_wave", hero.global_position, r / WAVE_FX_RADIUS, -1)
			else:
				_circle_fx(hero.global_position, r)
	_draw_beam(from)
	if not charge_held or hero.dead:
		_end_skill()


## Dłonie postaci (wylot promienia): nad stopami, lekko przed nią w stronę celu (wcześniej - spod księgi nad głową).
func _hand_point() -> Vector2:
	var dir := Vector2.from_angle(_aim) if _beam_target != null else hero.facing.normalized()
	return hero.global_position + Vector2(0, -HAND_HEIGHT) + dir * HAND_REACH


## 5. poziom promienia: drugi wróg najbliżej celu (przeskok).
func _beam_second() -> ProtoTarget:
	if not _perk("a_beam", 0) or _beam_target == null:
		return null
	var best: ProtoTarget = null
	var best_d := BEAM_CHAIN
	for t in _near(_beam_target.global_position, BEAM_CHAIN):
		var d := t.global_position.distance_to(_beam_target.global_position)
		if t != _beam_target and d <= best_d:
			best = t
			best_d = d
	return best


func _beam_line() -> Line2D:
	var line := Line2D.new()
	line.width = 5.0
	line.z_index = 20
	line.top_level = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	get_parent().add_child(line)
	return line


func _draw_beam(from: Vector2) -> void:
	if _beam == null:
		_beam = _beam_line()
	if _beam_cast_fx == null:  # błysk magii w dłoniach przez cały czas rzucania
		_beam_cast_fx = Node2D.new()
		_beam_cast_fx.z_index = 22
		get_parent().add_child(_beam_cast_fx)
		_fx_loop("arcane_beam_cast", _beam_cast_fx, 1.0)
	_beam_cast_fx.global_position = from.round()
	if _beam_target == null:
		_beam.visible = false
		if _beam_hit_fx:
			_beam_hit_fx.visible = false
		return
	var to := _beam_target.center()
	_beam.visible = true
	_beam.points = PackedVector2Array([from, to])
	var tex := _fx_tex("arcane_beam")
	if tex != null:  # kafelki promienia z kreatora wzdłuż linii, klatka po klatce
		var d: Array = FX.arcane_beam
		var frame: int = int(_clock * float(d[1])) % int(d[0])
		var w: float = float(tex.get_width()) / float(d[0])
		if not _beam.texture is AtlasTexture:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			_beam.texture = atlas
			_beam.texture_mode = Line2D.LINE_TEXTURE_TILE
			_beam.default_color = Color.WHITE
		(_beam.texture as AtlasTexture).region = Rect2(w * frame, 0, w, tex.get_height())
		_beam.width = tex.get_height() * (0.9 + 0.15 * sin(_clock * 30.0))
	else:
		_beam.width = 4.0 + 2.0 * sin(_clock * 30.0)
		_beam.default_color = ARCANE.lerp(ARCANE_CORE, 0.5 + 0.5 * sin(_clock * 17.0))
	if _beam_hit_fx == null:
		_beam_hit_fx = Node2D.new()
		_beam_hit_fx.z_index = 21
		get_parent().add_child(_beam_hit_fx)
		if _fx_tex("arcane_beam_impact") != null:  # rozbryzg na końcu promienia (zakrywa ucięty koniec)
			_fx_loop("arcane_beam_impact", _beam_hit_fx, _beam_area() / BEAM_AREA)
		else:
			_fx_loop("arcane_beam_hit", _beam_hit_fx, _beam_area() / BEAM_AREA)
	_beam_hit_fx.visible = true
	_beam_hit_fx.global_position = to.round()
	var second := _beam_second()
	if second != null:
		if _beam2 == null:
			_beam2 = _beam_line()
		_beam2.visible = true
		_beam2.points = PackedVector2Array([to, second.center()])
		_beam2.width = 3.0
		_beam2.default_color = Color(ARCANE, 0.8)
	elif _beam2 != null:
		_beam2.visible = false


func _end_skill() -> void:
	for n in [_beam, _beam2, _beam_hit_fx, _beam_cast_fx]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_beam = null
	_beam2 = null
	_beam_hit_fx = null
	_beam_cast_fx = null
	_beam_target = null
	super._end_skill()


# --- Pieczęcie Wybuchu ---

func _cast_seals() -> void:
	var reach: float = Skills.DATA.a_seals.range * _area("a_seals")
	var count := SEALS_PERK if _perk("a_seals", 0) else SEALS
	var pool := _near(hero.global_position, reach).filter(func(t: ProtoTarget) -> bool:
		return t.global_position.distance_to(hero.global_position) <= reach)
	pool.sort_custom(func(a: ProtoTarget, b: ProtoTarget) -> bool:
		return a.global_position.distance_to(hero.global_position) < b.global_position.distance_to(hero.global_position))
	var spots: Array[Vector2] = []
	for t in pool:
		if spots.size() >= count:
			break
		if spots.all(func(p: Vector2) -> bool: return p.distance_to(t.global_position) >= SEAL_GAP * _area("a_seals")):
			spots.append(t.global_position)
	if spots.is_empty():
		spots.append(hero.global_position + hero.facing.normalized() * 50.0)
	var nodes: Array = []
	for at in spots:
		var node := Node2D.new()
		node.z_index = -1
		get_parent().add_child(node)
		node.global_position = at
		var seal_size := SEAL_RADIUS * _area("a_seals") / SEAL_FX_RADIUS
		var tex := _fx_tex("arcane_seal")
		if tex != null:  # narasta przez SEAL_DELAY i błyska tuż przed wybuchem
			var d: Array = FX.arcane_seal
			Fx.once(node, tex, d[0], d[0] / SEAL_DELAY, at, d[2], -1, seal_size)
		else:
			_fx_loop("arcane_seal", node, seal_size)
		nodes.append(node)
	var links: Line2D = null
	if _unique("a_seals") and spots.size() > 1:
		links = Line2D.new()
		links.width = 3.0
		links.default_color = Color(ARCANE, 0.75)
		links.z_index = 19
		links.top_level = true
		get_parent().add_child(links)
		var pts := PackedVector2Array()
		for at in spots:
			pts.append(at + Vector2(0, -6))
		links.points = pts
	_seals.append({"spots": spots, "nodes": nodes, "links": links, "left": SEAL_DELAY, "tick": 0.0})


func _process_seals(delta: float) -> void:
	var keep: Array = []
	for s: Dictionary in _seals:
		s.left -= delta
		if s.links != null:
			s.links.width = 2.0 + 1.5 * sin(_clock * 25.0)
			s.tick -= delta
			if s.tick <= 0.0:
				s.tick = LINK_TICK
				_link_hit(s.spots)
		if s.left > 0.0:
			keep.append(s)
			continue
		var r := SEAL_RADIUS * _area("a_seals")
		for at: Vector2 in s.spots:
			_ring_hit(at, r * 1.4, _power("a_seals"), "a_seals")  # wybuch - koło (krąg spłaszczony x2 w pionie)
			_fx_once("arcane_blast", at + Vector2(0, -8), r / BLAST_FX_RADIUS)
			if _perk("a_seals", 1):
				for t in _near(at, r * 1.4):
					t.stun(SEAL_STUN)
		for n in s.nodes:
			if is_instance_valid(n):
				n.queue_free()
		if s.links != null:
			s.links.queue_free()
		Input.vibrate_handheld(25)
	_seals = keep


## Kamień Splecionych Pieczęci: wrogowie dotykający wiązki między kolejnymi pieczęciami dostają trafienie.
func _link_hit(spots: Array[Vector2]) -> void:
	var hit := {}
	for i in spots.size() - 1:
		var a := spots[i] + Vector2(0, -6)
		var b := spots[i + 1] + Vector2(0, -6)
		var mid := (a + b) * 0.5
		for t in _near_c(mid, a.distance_to(b) * 0.5 + LINK_WIDTH):
			if hit.has(t):
				continue
			var c := t.center()
			if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) <= LINK_WIDTH + t.center_height * 0.3:
				hit[t] = true
				_later(t, _hit.bind(t, _power("a_seals") * LINK_POWER, c, "a_seals"))


## Rozbłysk rysowany w kodzie (bez arkusza z kreatora): fioletowo-białe koło, które rośnie i gaśnie.
class _Flash extends Node2D:
	var radius := 12.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= 0.3:
			queue_free()

	func _draw() -> void:
		var k := _t / 0.3
		draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * k), Color(0.82, 0.6, 1.0, 0.5 * (1.0 - k)))
		draw_circle(Vector2.ZERO, radius * 0.4 * (1.0 - k), Color(1, 0.95, 1, 0.9 * (1.0 - k)))


## Kropla światła (kula, głowa pocisku) bez arkusza.
class _Glow extends Node2D:
	var radius := 5.0
	var _t := randf() * 5.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius * 1.6, Color(0.82, 0.6, 1.0, 0.25 + 0.1 * sin(_t * 8.0)))
		draw_circle(Vector2.ZERO, radius, Color(0.85, 0.65, 1.0, 0.9))
		draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 0.97, 1, 1))


## Trwały krąg na ziemi (kamień unikalny Kręgu Mocy): spłaszczona, pulsująca obwódka.
class _Ring extends Node2D:
	var radius := 50.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, radius, Color(0.82, 0.6, 1.0, 0.08))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.85, 0.65, 1.0, 0.6 + 0.2 * sin(_t * 4.0)), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.8, _t, _t + TAU * 0.75, 48, Color(1, 0.95, 1, 0.35), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

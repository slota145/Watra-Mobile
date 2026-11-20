class_name ProtoAuras
extends Node2D
## Aury w walce - dziecko postaci (ProtoHero), wzór: ../Watra/scripts/auras.gd. Rysuje pod postacią delikatne,
## wolno obracające się kręgi włączonych aur (aura na wrogów - krąg w jej zasięgu, aura na postać - mały pierścień
## przy stopach, kolejne coraz szersze). Robi to, czego nie da się zapisać premią postaci: piorun Gniewu Peruna,
## mróz Szronu Marzanny i krążący Błędny Ognik (trafienia przez ProtoWeapon.aura_hit, cele - `weapon.live_targets`/`targets_near`).
## Premie (zdrowie, szybkość, odnowa, ogień) liczy Auras.apply. Lista włączonych aur: `on` (arena z Game.auras_on).
## Krok 2: kręgi na wrogów (Postrach, Mgła Nawii, Piętno Czarnoboga) znaczą wrogów w kręgu (ProtoTarget.aura_weak,
## aura_miss, pride - działają w ProtoTarget.hit_hero i ProtoWeapon), Zwiastuny Popiołu i Mrozu - wybuch zabitego wroga
## (`on_monster_died`, arena podpina ProtoHorde.monster_died): wybuch ognia glewii i pękający lód z kreatora efektów.

## Broń w ręku (jej cele i siła ciosu); arena podmienia przy zmianie broni.
var weapon: ProtoWeapon
## Zwiastun Mrozu: pękający lód z odłamkami (kreator efektów PixelLab, pixellab_src/vfx/ids.json "frost_shatter").
const FROST_SHATTER_FX := preload("res://assets/effects/frost_shatter.png")
const FROST_SHATTER_ANCHOR := Vector2(31, 29)
## Włączone aury i ich poziomy (Game.auras_on, Game.auras).
var on: Array = []
var levels := {}

var _hero: ProtoHero
var _spin := 0.0
var _perun_next := Auras.PERUN_INTERVAL
var _szron_next := Auras.SZRON_TICK
var _circle_next := 0.0
var _ognik_angle := 0.0
var _ognik_hits := {}  # cel -> czas do kolejnego trafienia
var _wisp: Node2D


func _ready() -> void:
	_hero = get_parent() as ProtoHero
	show_behind_parent = true
	z_index = -1
	_wisp = Node2D.new()
	_wisp.name = "Wisp"
	_wisp.draw.connect(_draw_wisp)
	_wisp.visible = false
	_hero.add_child.call_deferred(_wisp)


func _process(delta: float) -> void:
	_spin += delta * 0.6
	visible = not on.is_empty()
	if not visible:
		_wisp.visible = false
		return
	queue_redraw()
	if _hero.dead or weapon == null:
		return
	if on.has("perun"):
		_perun_next -= delta
		if _perun_next <= 0.0:
			_perun_next = Auras.PERUN_INTERVAL
			_perun_strike()
	else:
		_perun_next = Auras.PERUN_INTERVAL
	if on.has("szron"):
		_szron_next -= delta
		if _szron_next <= 0.0:
			_szron_next = Auras.SZRON_TICK
			_szron_tick()
	_wisp.visible = on.has("ognik")
	if _wisp.visible:
		_ognik_update(delta)
	_circle_next -= delta
	if _circle_next <= 0.0:
		_circle_next = Auras.CIRCLE_TICK
		_circle_tick()


## Kręgi na wrogów: Postrach (słabsze ciosy, spowolnienie), Mgła Nawii (chybienia) - znak na Auras.MARK_TIME s;
## Piętno Czarnoboga - premia rośnie w kręgu przez Auras.CZARNOBOG_BUILD s, poza nim szybko gaśnie.
func _circle_tick() -> void:
	var postrach := on.has("postrach")
	var mgla := on.has("mgla")
	var czarnobog := on.has("czarnobog")
	var now := Time.get_ticks_msec() / 1000.0
	var pride_max := _power("czarnobog")
	for t: ProtoTarget in weapon.live_targets():  # wszyscy - Piętno Czarnoboga gaśnie też poza kręgiem
		var off := t.global_position - _hero.global_position
		off.y *= 2.0  # krąg spłaszczony jak na rysunku
		var d := off.length()
		if postrach and d <= Auras.radius_of("postrach") or mgla and d <= Auras.radius_of("mgla"):
			t.aura_until = now + Auras.MARK_TIME
			t.aura_weak = _power("postrach") if postrach and d <= Auras.radius_of("postrach") else 0.0
			t.aura_miss = _power("mgla") if mgla and d <= Auras.radius_of("mgla") else 0.0
			if t.aura_weak > 0.0:
				t.slow(Auras.POSTRACH_SLOW, Auras.MARK_TIME)
		if czarnobog and d <= Auras.radius_of("czarnobog"):
			t.pride = minf(t.pride + pride_max * Auras.CIRCLE_TICK / Auras.CZARNOBOG_BUILD, pride_max)
		elif t.pride > 0.0:
			t.pride = maxf(t.pride - pride_max * Auras.CIRCLE_TICK * Auras.CZARNOBOG_FADE / Auras.CZARNOBOG_BUILD, 0.0)


## Pokonany potwór: Zwiastun Popiołu (wybuch ognia, podpalenie sąsiadów) i Zwiastun Mrozu (lodowe odłamki,
## mocniejsze ze spowolnionego albo zamrożonego). Odroczone - łańcuch wybuchów idzie klatka po klatce.
func on_monster_died(g: ProtoTarget) -> void:
	if weapon == null or _hero.dead or not (on.has("popiol") or on.has("mroz")) or not is_instance_valid(g):
		return
	var at := g.global_position
	var chilled := g.speed_factor() < 1.0
	_herald.call_deferred(at, chilled)


func _herald(at: Vector2, chilled: bool) -> void:
	if weapon == null or not is_instance_valid(weapon):
		return
	var fire := on.has("popiol")
	var ice := on.has("mroz")
	var world := _hero.get_parent()
	if fire:  # wybuch ognia (ten sam co wybuch glewii)
		Fx.once(world, ProtoGlaive.BLAST_FX, 12, 16.0, at.round(), ProtoGlaive.BLAST_FX_ANCHOR, 6,
				Auras.HERALD_RADIUS / ProtoGlaive.BLAST_FX_RADIUS)
	if ice:  # pękający lód (kreator efektów PixelLab, 20.11.2026)
		Fx.once(world, FROST_SHATTER_FX, 10, 16.0, at.round(), FROST_SHATTER_ANCHOR, 7, 1.4 if chilled else 1.1)
	for t: ProtoTarget in weapon.targets_near(at, Auras.HERALD_RADIUS):
		if not is_instance_valid(t) or not t.alive():
			continue
		var off := t.global_position - at
		off.y *= 2.0
		if off.length() > Auras.HERALD_RADIUS:
			continue
		if fire:
			weapon.aura_hit(t, _power("popiol"), Elements.FIRE, at)
			if t.alive():
				t.burn(weapon._roll(_power("popiol")) * weapon.elem_mult * Auras.SWAROG_BURN, ProtoWeapon.BURN_TIME, weapon.penetration)
		if ice and t.alive():
			weapon.aura_hit(t, _power("mroz") * (Auras.MROZ_CHILLED if chilled else 1.0), Elements.COLD, at)
			t.slow(Auras.MROZ_SLOW, 1.5)


func _power(id: String) -> float:
	return Auras.power(id, levels.get(id, 1))


func _draw() -> void:
	var small := 0
	for id in on:
		if not Auras.is_aura(id):
			continue
		var r := Auras.radius_of(id)
		if r <= 0.0:
			r = 13.0 + 4.0 * small
			small += 1
		_draw_ring(r, Auras.color_of(id), small % 2 == 0)


## Spłaszczony krąg (perspektywa z góry) z kreskami obracającymi się w kółko.
func _draw_ring(radius: float, color: Color, clockwise: bool) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	if radius > 30.0:
		draw_circle(Vector2.ZERO, radius, Color(color, 0.07))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.35), 1.0)
	var dashes := 6 if radius < 30.0 else 12
	var turn := _spin * (1.0 if clockwise else -1.0)
	for i in dashes:
		var a := turn + TAU * i / dashes
		draw_arc(Vector2.ZERO, radius, a, a + TAU / dashes * 0.35, 6, Color(color, 0.75), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Żywy cel najbliżej postaci w zasięgu (albo null).
func _nearest(range_px: float) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := range_px
	for t in weapon.targets_near(_hero.global_position, range_px):
		var d := t.global_position.distance_to(_hero.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


## Gniew Peruna: piorun z nieba w najbliższego wroga (zygzak gaśnie w ułamku sekundy), cel porażony.
func _perun_strike() -> void:
	var t := _nearest(Auras.PERUN_RANGE)
	if not t:
		return
	var to := t.center()
	var bolt := Line2D.new()
	bolt.width = 2.0
	bolt.default_color = Color(0.85, 0.93, 1.0)
	bolt.z_index = 20
	var top := to + Vector2(randf_range(-20, 20), -110)
	for i in 8:
		var p := top.lerp(to, i / 7.0)
		if i > 0 and i < 7:
			p.x += randf_range(-7, 7)
		bolt.add_point(p)
	var glow := bolt.duplicate() as Line2D
	glow.width = 6.0
	glow.default_color = Color(Elements.color_of(Elements.LIGHTNING), 0.4)
	glow.z_index = 19
	var world := _hero.get_parent()
	for line: Line2D in [glow, bolt]:
		world.add_child(line)
		var tween := line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.25).set_delay(0.08)
		tween.tween_callback(line.queue_free)
	weapon.aura_hit(t, _power("perun"), Elements.LIGHTNING, _hero.global_position)
	t.shock(Auras.PERUN_SHOCK)


## Szron Marzanny: wrogowie w kręgu zwalniają i dostają rany od mrozu.
func _szron_tick() -> void:
	var p := _power("szron")
	for t: ProtoTarget in weapon.targets_near(_hero.global_position, Auras.radius_of("szron")):
		if not is_instance_valid(t) or not t.alive():
			continue
		var off := t.global_position - _hero.global_position
		off.y *= 2.0  # krąg spłaszczony jak na rysunku
		if off.length() <= Auras.radius_of("szron"):
			t.slow(Auras.SZRON_SLOW, Auras.SZRON_TICK + 0.3)
			weapon.aura_hit(t, p, Elements.COLD, _hero.global_position)


## Błędny Ognik krąży wokół postaci i rani wrogów, przez których przelatuje.
func _ognik_update(delta: float) -> void:
	_ognik_angle += TAU / Auras.OGNIK_PERIOD * delta
	var ground := Vector2(cos(_ognik_angle), sin(_ognik_angle) * 0.5) * Auras.OGNIK_RADIUS
	_wisp.position = ground
	_wisp.z_index = 1 if ground.y > 0.0 else -1  # przed postacią albo za nią
	_wisp.queue_redraw()
	for t in _ognik_hits.keys():
		_ognik_hits[t] -= delta
		if _ognik_hits[t] <= 0.0 or not is_instance_valid(t):
			_ognik_hits.erase(t)
	var at := _hero.global_position + ground
	for t: ProtoTarget in weapon.targets_near(at, 14.0):
		if _ognik_hits.has(t) or not is_instance_valid(t) or not t.alive():
			continue
		if t.global_position.distance_to(at) < 14.0:
			_ognik_hits[t] = Auras.OGNIK_HIT_GAP
			weapon.aura_hit(t, _power("ognik"), Elements.FIRE, at)


func _draw_wisp() -> void:
	var lift := Vector2(0, -16 + sin(_ognik_angle * 3.0) * 2.0)
	var c := Auras.color_of("ognik")
	_wisp.draw_circle(Vector2(0, 0), 3.0, Color(0, 0, 0, 0.25))  # cień
	_wisp.draw_circle(lift, 6.0, Color(c, 0.25))
	_wisp.draw_circle(lift, 3.5, Color(c, 0.7))
	_wisp.draw_circle(lift, 1.8, Color(1, 1, 0.9))

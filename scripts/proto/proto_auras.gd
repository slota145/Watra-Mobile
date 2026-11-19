class_name ProtoAuras
extends Node2D
## Aury w prototypie walki - dziecko postaci (ProtoHero), wzór: ../Watra/scripts/auras.gd.
## Rysuje pod postacią delikatne, wolno obracające się kręgi włączonych aur (aura na wrogów - krąg w jej zasięgu,
## aura na postać - mały pierścień przy stopach, kolejne coraz szersze). Robi to, czego nie da się zapisać premią
## postaci: piorun Gniewu Peruna, rany Szronu Marzanny i krążący Błędny Ognik. Premie (zdrowie, szybkość, odnowa,
## ogień) liczy ProtoHero.aura_power.

## Cele aur (kukły - arena podaje listę miecza).
var targets: Array[ProtoDummy] = []

var _hero: ProtoHero
var _spin := 0.0
var _perun_next := AuraData.PERUN_INTERVAL
var _szron_next := AuraData.SZRON_TICK
var _ognik_angle := 0.0
var _ognik_hits := {}  # kukła -> czas do kolejnego trafienia
var _wisp: Node2D


func _ready() -> void:
	_hero = get_parent() as ProtoHero
	show_behind_parent = true
	_wisp = Node2D.new()
	_wisp.name = "Wisp"
	_wisp.draw.connect(_draw_wisp)
	_wisp.visible = false
	_hero.add_child.call_deferred(_wisp)


func _process(delta: float) -> void:
	_spin += delta * 0.6
	queue_redraw()
	var on := _hero.auras
	if on.has("perun"):
		_perun_next -= delta
		if _perun_next <= 0.0:
			_perun_next = AuraData.PERUN_INTERVAL
			_perun_strike()
	else:
		_perun_next = AuraData.PERUN_INTERVAL
	if on.has("szron"):
		_szron_next -= delta
		if _szron_next <= 0.0:
			_szron_next = AuraData.SZRON_TICK
			_szron_tick()
	_wisp.visible = on.has("ognik")
	if _wisp.visible:
		_ognik_update(delta)


func _draw() -> void:
	var small := 0
	for id in _hero.auras:
		if not AuraData.is_aura(id):
			continue
		var r := AuraData.radius_of(id)
		if r <= 0.0:
			r = 13.0 + 4.0 * small
			small += 1
		_draw_ring(r, AuraData.color_of(id), small % 2 == 0)


## Spłaszczony krąg (perspektywa z góry) z kreskami obracającymi się w kółko.
func _draw_ring(radius: float, color: Color, clockwise: bool) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	var fill := color
	fill.a = 0.07 if radius > 30.0 else 0.0
	if fill.a > 0.0:
		draw_circle(Vector2.ZERO, radius, fill)
	var line := color
	line.a = 0.35
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, line, 1.0)
	var dashes := 6 if radius < 30.0 else 12
	var turn := _spin * (1.0 if clockwise else -1.0)
	line.a = 0.75
	for i in dashes:
		var a := turn + TAU * i / dashes
		draw_arc(Vector2.ZERO, radius, a, a + TAU / dashes * 0.35, 6, line, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Najbliższa kukła w zasięgu (albo null).
func _nearest(range_px: float) -> ProtoDummy:
	var best: ProtoDummy = null
	var best_d := range_px
	for t in targets:
		var d := t.global_position.distance_to(_hero.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


## Gniew Peruna: piorun z nieba w najbliższą kukłę, zygzak gaśnie w ułamku sekundy.
func _perun_strike() -> void:
	var t := _nearest(AuraData.PERUN_RANGE)
	if not t:
		return
	var to := t.center()
	var bolt := Line2D.new()
	bolt.width = 2.0
	bolt.default_color = Color(1.0, 0.95, 0.6)
	bolt.z_index = 20
	var top := to + Vector2(randf_range(-20, 20), -110)
	for i in 8:
		var p := top.lerp(to, i / 7.0)
		if i > 0 and i < 7:
			p.x += randf_range(-7, 7)
		bolt.add_point(p)
	var glow := bolt.duplicate() as Line2D
	glow.width = 6.0
	glow.default_color = Color(1.0, 0.85, 0.3, 0.35)
	glow.z_index = 19
	var world := _hero.get_parent()
	for line: Line2D in [glow, bolt]:
		world.add_child(line)
		var tween := line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.25).set_delay(0.08)
		tween.tween_callback(line.queue_free)
	t.take_damage(roundi(ProtoWeapon.AVG_DAMAGE * _hero.aura_power("perun")), _hero.global_position,
			AuraData.color_of("perun"))


## Szron Marzanny: rany od mrozu kukłom w kręgu.
func _szron_tick() -> void:
	var dmg := maxi(1, roundi(ProtoWeapon.AVG_DAMAGE * _hero.aura_power("szron")))
	for t in targets:
		var off := t.global_position - _hero.global_position
		off.y *= 2.0  # krąg spłaszczony jak na rysunku
		if off.length() <= AuraData.radius_of("szron"):
			t.take_damage(dmg, _hero.global_position, AuraData.color_of("szron"))


## Błędny Ognik krąży wokół postaci i rani kukły, przez które przelatuje.
func _ognik_update(delta: float) -> void:
	_ognik_angle += TAU / AuraData.OGNIK_PERIOD * delta
	var ground := Vector2(cos(_ognik_angle), sin(_ognik_angle) * 0.5) * AuraData.OGNIK_RADIUS
	_wisp.position = ground
	_wisp.z_index = 1 if ground.y > 0.0 else -1  # przed postacią albo za nią
	_wisp.queue_redraw()
	for t: ProtoDummy in _ognik_hits.keys():
		_ognik_hits[t] -= delta
		if _ognik_hits[t] <= 0.0:
			_ognik_hits.erase(t)
	for t in targets:
		if _ognik_hits.has(t):
			continue
		if t.global_position.distance_to(_hero.global_position + ground) < 14.0:
			_ognik_hits[t] = AuraData.OGNIK_HIT_GAP
			t.take_damage(roundi(ProtoWeapon.AVG_DAMAGE * _hero.aura_power("ognik")), _wisp.global_position,
					AuraData.color_of("ognik"))


func _draw_wisp() -> void:
	var lift := Vector2(0, -16 + sin(_ognik_angle * 3.0) * 2.0)
	var c := AuraData.color_of("ognik")
	_wisp.draw_circle(Vector2(0, 0), 3.0, Color(0, 0, 0, 0.25))  # cień
	_wisp.draw_circle(lift, 6.0, Color(c, 0.25))
	_wisp.draw_circle(lift, 3.5, Color(c, 0.7))
	_wisp.draw_circle(lift, 1.8, Color(1, 1, 0.9))

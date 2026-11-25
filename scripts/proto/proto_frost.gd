class_name ProtoFrost
extends Node2D
## Wymarzanie i koksowniki - mechanika Lodowych jaskiń (Dungeons.FROST, decyzja autora 25.11.2026, liczby - Claude):
## postać powoli zbiera chłód (`ProtoHero.frost_cold`, 0-MAX_COLD: COLD_RATE na sekundę, lodowe ciosy potworów
## dokładają - `chill_hero`) i idzie coraz wolniej (do MAX_SLOW przy pełnym chłodzie, ProtoHero.slow); przy pełnym
## chłodzie zamarza - co FREEZE_TICK s traci FREEZE_DAMAGE zdrowia (lód). Płonące koksowniki (BRAZIERS, grafika
## z katakumb Watry) rozgrzewają: w ich kręgu (WARM_RADIUS) chłód spada o WARM_RATE na sekundę, a postać dostaje
## „Rozgrzanie” - +WARM_BONUS obrażeń broni (ProtoWeapon.warm_mult) na WARM_TIME s. Pasek chłodu pod stopami postaci
## (`_draw`), koksowniki z poświatą i kręgiem ciepła. Arena tworzy węzeł tylko w tym lochu (`arena.frost`).
## „Dopóki płonie ogień, Ostoja trwa”.

const BRAZIER := preload("res://assets/watra/decor/frost/brazier.png")
const MAX_COLD := 100.0
const COLD_RATE := 3.3
const MAX_SLOW := 0.4
const FREEZE_TICK := 1.0
const FREEZE_DAMAGE := 0.03
const BRAZIERS := 5
const BRAZIER_SPACING := 150.0
const BRAZIER_CLEAR := 90.0
const BRAZIER_RADIUS := 12.0
const WARM_RADIUS := 46.0
const WARM_RATE := 35.0
const WARM_BONUS := 0.2
const WARM_TIME := 8.0
const COLD_COLOR := Color(0.6, 0.85, 1.0)
const WARM_COLOR := Color(1.0, 0.6, 0.25)

## Węzeł mechaniki w trwającym lochu (null - inny loch): lodowe ciosy potworów dokładają chłodu przez `chill_hero`.
static var current: ProtoFrost

var hero: ProtoHero
var weapon: ProtoWeapon
## Koksowniki: miejsca w świecie (do testów i zrzutów).
var braziers: Array[Vector2] = []
## Ile sekund zostało rozgrzania.
var warm_left := 0.0
var _freeze_t := 0.0
var _glows: Array[Node2D] = []
var _t := 0.0


## Dokłada `amount` chłodu postaci, gdy trwa loch mrozu (lodowe ciosy, sople).
static func chill_hero(h: ProtoHero, amount: float) -> void:
	if current and is_instance_valid(current) and h and not h.dead:
		h.frost_cold = minf(h.frost_cold + amount, MAX_COLD)


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null
	if weapon and is_instance_valid(weapon):
		weapon.warm_mult = 1.0


## Stawia BRAZIERS koksowników w świecie `world` w prostokącie `area`, z dala od siebie i od startu postaci `clear`.
func place_braziers(world: Node2D, area: Rect2, clear: Vector2) -> void:
	var tries := 0
	while braziers.size() < BRAZIERS and tries < 400:
		tries += 1
		var p := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y)).round()
		if p.distance_to(clear) < BRAZIER_CLEAR or braziers.any(func(q: Vector2) -> bool: return q.distance_to(p) < BRAZIER_SPACING):
			continue
		if ProtoDecor.obstacles.any(func(o: Vector3) -> bool: return Vector2(o.x, o.y).distance_to(p) < o.z + 26.0):
			continue  # nie na ozdobie
		add_brazier(world, p)


## Jeden koksownik w `at` (świat): grafika, poświata i krąg ciepła pod spodem, przeszkoda jak ozdoby lochu.
func add_brazier(world: Node2D, at: Vector2) -> void:
	braziers.append(at)
	var glow := _Glow.new()
	glow.z_index = -4
	world.add_child(glow)
	glow.global_position = at
	_glows.append(glow)
	var s := Sprite2D.new()
	s.texture = BRAZIER
	s.centered = false
	s.offset = Vector2(-BRAZIER.get_width() / 2.0, -BRAZIER.get_height() + 3.0)
	world.add_child(s)
	s.global_position = at
	ProtoDecor.obstacles.append(Vector3(at.x, at.y, BRAZIER_RADIUS))
	if hero:
		hero.obstacles.append(Vector3(at.x, at.y, BRAZIER_RADIUS))


## Czy postać stoi w kręgu ciepła któregoś koksownika.
func near_brazier() -> bool:
	if hero == null:
		return false
	for b in braziers:
		var d := hero.global_position - b
		if Vector2(d.x, d.y / 0.6).length() <= WARM_RADIUS:
			return true
	return false


func _process(delta: float) -> void:
	_t += delta
	for g in _glows:
		g.modulate.a = 0.85 + 0.15 * sin(_t * 9.0 + g.get_instance_id() % 7)
	if hero == null or hero.dead:
		return
	position = hero.position
	var warm := near_brazier()
	if warm:
		hero.frost_cold = maxf(hero.frost_cold - WARM_RATE * delta, 0.0)
		if warm_left <= 0.0:
			hero.float_text(tr("Rozgrzanie!"), -46.0, WARM_COLOR, 12, 0.9)
		warm_left = WARM_TIME
	else:
		hero.frost_cold = minf(hero.frost_cold + COLD_RATE * delta, MAX_COLD)
		warm_left = maxf(warm_left - delta, 0.0)
	if weapon and is_instance_valid(weapon):
		weapon.warm_mult = 1.0 + WARM_BONUS if warm_left > 0.0 else 1.0
	var k := hero.frost_cold / MAX_COLD
	if k > 0.05:
		hero.slow(MAX_SLOW * k, 0.15, Color(1, 1, 1).lerp(COLD_COLOR, k))
	if hero.frost_cold >= MAX_COLD:
		_freeze_t -= delta
		if _freeze_t <= 0.0:
			_freeze_t = FREEZE_TICK
			hero.float_text(tr("Zamarzasz!"), -46.0, COLD_COLOR, 12, 0.8)
			hero.take_damage(maxi(1, roundi(hero.max_hp * FREEZE_DAMAGE)), Elements.COLD)
	else:
		_freeze_t = 0.0
	queue_redraw()


## Pasek chłodu pod stopami postaci (szron od lewej; przy rozgrzaniu pomarańczowa obwódka).
func _draw() -> void:
	if hero == null or hero.frost_cold < 1.0:
		return
	var w := 26.0
	var top := Vector2(-w / 2.0, 6.0)
	draw_rect(Rect2(top - Vector2.ONE, Vector2(w + 2.0, 5.0)), WARM_COLOR if warm_left > 0.0 else Color(0.05, 0.08, 0.15, 0.85))
	draw_rect(Rect2(top, Vector2(w, 3.0)), Color(0.1, 0.14, 0.24, 0.9))
	draw_rect(Rect2(top, Vector2(w * hero.frost_cold / MAX_COLD, 3.0)), COLD_COLOR if hero.frost_cold < MAX_COLD else Color(1, 1, 1))


## Poświata i krąg ciepła koksownika (rysowane - bez prawdziwych świateł, tanio dla telefonów).
class _Glow extends Node2D:
	func _draw() -> void:
		for i in 4:
			var r := 18.0 + i * 9.0
			draw_set_transform(Vector2(0, -14.0), 0.0, Vector2(1.0, 0.8))
			draw_circle(Vector2.ZERO, r, Color(1.0, 0.55, 0.2, 0.09 - i * 0.018))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, WARM_RADIUS, 0.0, TAU, 40, Color(1.0, 0.6, 0.25, 0.35), 1.0)

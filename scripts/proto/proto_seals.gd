class_name ProtoSeals
extends Node2D
## Magiczne pieczęcie - mechanika Wieży Kościeja (Dungeons.TOWER, decyzja autora 26.11.2026, liczby - Claude): co EVERY s
## (losowo w widełkach) wokół postaci zapalają się na posadzce pieczęcie - RED_COUNT czerwonych i BLUE_COUNT niebieska.
## Trzeba czytać kolory (i kształty - dla telefonu w słońcu i daltonistów różnią się też znakiem w środku):
## - **czerwona** (trójkąt z wykrzyknikiem, kolce na brzegu): wypełnia się przez RED_WARN s, coraz szybciej miga,
##   potem wybucha (arcane_blast) - postać w kole obrywa RED_DAMAGE Arkanami (odporność na żywioły zmniejsza);
## - **niebieska** (romb ze strzałką w górę, spokojnie świeci): trwa BLUE_LIFE s; wejście w nią daje Moc pieczęci -
##   BLUE_MANA many (ułamek pełnej) i szybszy ruch (BLUE_SPEED przez BLUE_TIME s), pieczęć gaśnie.
## Pierwsza czerwona często pada pod postać (RED_UNDER) - trzeba z niej zejść, niebieska nigdy nie leży na czerwonej.
## Rysowane w kodzie (elipsy, dodawane światło - tanio dla telefonów). Arena tworzy węzeł tylko w tym lochu
## (`arena.seals`).

const EVERY := Vector2(5.0, 7.5)
const RADIUS := 20.0
## Spłaszczenie koła w pionie (jak ProtoTelegraph).
const SQUASH := 0.6
const RED_COUNT := 3
const BLUE_COUNT := 1
const RED_WARN := 1.8
const RED_DAMAGE := 20
## Szansa, że pierwsza czerwona pieczęć zapali się pod postacią.
const RED_UNDER := 0.5
## Pieczęcie zapalają się w tej odległości od postaci (min-max).
const SPREAD := Vector2(40.0, 110.0)
const BLUE_LIFE := 6.0
const BLUE_MANA := 0.3
const BLUE_SPEED := 0.3
const BLUE_TIME := 4.0
const RED := Color(1.0, 0.22, 0.18)
const BLUE := Color(0.3, 0.65, 1.0)
const BLAST_FX := preload("res://assets/effects/arcane_blast.png")
const BOOST_FX := preload("res://assets/effects/arcane_hit.png")

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: mechanika sama nie rusza.
var passive := false
## Pieczęcie: {"pos", "kind" ("red"/"blue"), "t" - ile już trwa}.
var seals: Array[Dictionary] = []
## Ile czerwonych wybuchło, ile razy wybuch zranił postać, ile niebieskich postać zebrała (testy).
var blasts := 0
var hits := 0
var boosts := 0
## Ile sekund jeszcze trwa przyspieszenie z niebieskiej pieczęci.
var boost_left := 0.0
var _next := 3.0
var _time := 0.0
## Przyspieszenie: mnożnik ruchu postaci przed premią i po niej (żeby zdjąć premię, tylko jeśli nikt go nie zmienił).
var _base_mult := 1.0
var _boosted_mult := 1.0
var _light: _Layer


func _ready() -> void:
	z_index = -1  # na posadzce, pod postaciami
	_light = _Layer.new()
	_light.seals_node = self
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = add
	add_child(_light)


func _process(delta: float) -> void:
	_time += delta
	if boost_left > 0.0:
		boost_left -= delta
		if boost_left <= 0.0:
			_end_boost()
	if hero == null or hero.dead:
		seals.clear()
		_redraw()
		return
	for i in range(seals.size() - 1, -1, -1):
		var s := seals[i]
		s.t += delta
		if s.kind == "red":
			if s.t >= RED_WARN:
				_blast(s)
				seals.remove_at(i)
		elif s.t >= BLUE_LIFE:
			seals.remove_at(i)
		elif contains(s.pos, hero.global_position):
			_boost(s)
			seals.remove_at(i)
	if not passive:
		_next -= delta
		if _next <= 0.0:
			light_up()
	_redraw()


func _redraw() -> void:
	queue_redraw()
	if _light:
		_light.queue_redraw()


## Zapala nową grupę pieczęci wokół postaci (czerwone i niebieskie, nie nachodzą na siebie).
func light_up() -> void:
	_next = randf_range(EVERY.x, EVERY.y)
	var spots: Array[Vector2] = []
	for s in seals:
		spots.append(s.pos)
	for i in RED_COUNT + BLUE_COUNT:
		var red := i < RED_COUNT
		var at := hero.global_position
		var ok := red and i == 0 and randf() < RED_UNDER
		var tries := 0
		while not ok and tries < 30:
			tries += 1
			at = (hero.global_position + Vector2.from_angle(randf() * TAU) * randf_range(SPREAD.x, SPREAD.y) * Vector2(1, 0.75)
					).clamp(bounds.position, bounds.end)
			at = ProtoDecor.push_out(at, RADIUS * 0.6)  # nie pod regałem - do niebieskiej trzeba dojść
			ok =spots.all(func(q: Vector2) -> bool: return q.distance_to(at) > RADIUS * 2.4)
		if not ok:
			continue
		spots.append(at)
		add_seal(at, "red" if red else "blue")


## Pieczęć `kind` ("red"/"blue") w punkcie `at` (też do testów i zrzutów).
func add_seal(at: Vector2, kind: String) -> void:
	seals.append({"pos": at, "kind": kind, "t": 0.0})


## Czy punkt `p` (stopy) leży w pieczęci o środku `center`.
static func contains(center: Vector2, p: Vector2) -> bool:
	var d := p - center
	return Vector2(d.x, d.y / SQUASH).length() <= RADIUS


func count(kind: String) -> int:
	return seals.filter(func(s: Dictionary) -> bool: return s.kind == kind).size()


## Czerwona pieczęć wybucha: rani postać w kole.
func _blast(s: Dictionary) -> void:
	blasts += 1
	var fx := Fx.once(get_parent(), BLAST_FX, 9, 18.0, (s.pos as Vector2).round(), Vector2(36, 20), 2, RADIUS / 30.0)
	fx.modulate = Color(1.0, 0.55, 0.5)
	if contains(s.pos, hero.global_position):
		hits += 1
		hero.take_damage(maxi(1, roundi(RED_DAMAGE * power)), Elements.ARCANE)


## Niebieska pieczęć: mana i szybszy ruch.
func _boost(s: Dictionary) -> void:
	boosts += 1
	hero.add_mana(maxi(1, roundi(hero.mana_cap() * BLUE_MANA)))
	if boost_left <= 0.0:
		_base_mult = hero.move_mult
		_boosted_mult = _base_mult * (1.0 + BLUE_SPEED)
		hero.move_mult = _boosted_mult
	boost_left = BLUE_TIME
	hero._spawn_text(tr("Moc pieczęci!"), BLUE.lightened(0.35))
	var fx := Fx.once(get_parent(), BOOST_FX, 6, 14.0, (s.pos as Vector2) + Vector2(0, -6), Vector2(23, 21), 21, 1.0)
	fx.modulate = Color(0.6, 0.85, 1.0)


## Koniec przyspieszenia (jeśli przedmioty w tym czasie nie zmieniły mnożnika - wtedy zostaje nowy).
func _end_boost() -> void:
	if hero and is_equal_approx(hero.move_mult, _boosted_mult):
		hero.move_mult = _base_mult


func _exit_tree() -> void:
	if boost_left > 0.0:
		boost_left = 0.0
		_end_boost()


## Pieczęcie - ciemniejsza podstawa (zwykła warstwa): wypełnienie i znak w środku.
func _draw() -> void:
	for s in seals:
		var c: Vector2 = s.pos - global_position
		var red: bool = s.kind == "red"
		var col := RED if red else BLUE
		var k := clampf(s.t / RED_WARN, 0.0, 1.0) if red else 1.0
		var fade := clampf((BLUE_LIFE - s.t) / 1.0, 0.0, 1.0) if not red else 1.0
		var appear := clampf(s.t / 0.25, 0.0, 1.0)
		var a := appear * fade
		draw_set_transform(c, 0.0, Vector2(1.0, SQUASH))
		draw_circle(Vector2.ZERO, RADIUS, Color(col.darkened(0.5), 0.3 * a))
		if red:  # wypełnianie od środka - jak koło zapowiedzi bossa
			draw_circle(Vector2.ZERO, RADIUS * k, Color(col, 0.28 * a))
		draw_set_transform(Vector2.ZERO)
		_draw_sign(self, c, red, Color(col.lightened(0.35), 0.9 * a))


## Znak w środku pieczęci: czerwona - trójkąt z wykrzyknikiem, niebieska - romb ze strzałką w górę.
func _draw_sign(on: CanvasItem, c: Vector2, red: bool, col: Color) -> void:
	if red:
		var tri := PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, 4), c + Vector2(-7, 4), c + Vector2(0, -8)])
		on.draw_polyline(tri, col, 1.0)
		on.draw_line(c + Vector2(0, -4), c + Vector2(0, 0), col, 1.0)
		on.draw_rect(Rect2(c + Vector2(-0.5, 1.5), Vector2(1, 1)), col)
	else:
		var dia := PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 0), c + Vector2(0, 8), c + Vector2(-8, 0), c + Vector2(0, -8)])
		on.draw_polyline(dia, col, 1.0)
		on.draw_line(c + Vector2(0, 4), c + Vector2(0, -4), col, 1.0)
		on.draw_line(c + Vector2(-3, -1), c + Vector2(0, -4), col, 1.0)
		on.draw_line(c + Vector2(3, -1), c + Vector2(0, -4), col, 1.0)


## Pieczęcie - światło (warstwa dodawana): pierścień, obracające się znaki run, czerwona przed wybuchem miga.
func draw_light(on: CanvasItem) -> void:
	for s in seals:
		var c: Vector2 = s.pos - global_position
		var red: bool = s.kind == "red"
		var col := RED if red else BLUE
		var appear := clampf(s.t / 0.25, 0.0, 1.0)
		var a := appear
		if red:
			var k := clampf(s.t / RED_WARN, 0.0, 1.0)
			var blink := 0.5 + 0.5 * sin(s.t * TAU * lerpf(2.0, 9.0, k))  # coraz szybciej
			a *= 0.55 + 0.45 * blink
		else:
			a *= clampf((BLUE_LIFE - s.t) / 1.0, 0.0, 1.0) * (0.75 + 0.25 * sin(_time * 3.0))
		var pts := PackedVector2Array()
		for i in 33:
			var ang := TAU * i / 32.0
			pts.append(c + Vector2(cos(ang), sin(ang) * SQUASH) * RADIUS)
		on.draw_polyline(pts, Color(col, 0.9 * a), 1.5)
		var inner := PackedVector2Array()
		for i in 33:
			var ang := TAU * i / 32.0
			inner.append(c + Vector2(cos(ang), sin(ang) * SQUASH) * (RADIUS - 5.0))
		on.draw_polyline(inner, Color(col, 0.45 * a), 1.0)
		# znaki run (kreski) między pierścieniami, obracają się (czerwona w drugą stronę i szybciej)
		var spin := _time * (-1.6 if red else 0.6)
		for i in 8:
			var ang := spin + TAU * i / 8.0
			var dir := Vector2(cos(ang), sin(ang) * SQUASH)
			if red:  # kolce na zewnątrz
				on.draw_line(c + dir * (RADIUS - 4.0), c + dir * (RADIUS + 3.0), Color(col, 0.8 * a), 1.0)
			else:
				on.draw_line(c + dir * (RADIUS - 4.0), c + dir * (RADIUS - 1.0), Color(col, 0.8 * a), 1.0)
		_draw_sign(on, c, red, Color(col, 0.6 * a))


## Warstwa światła pieczęci - rysuje przez węzeł mechaniki.
class _Layer:
	extends Node2D
	var seals_node: ProtoSeals

	func _draw() -> void:
		seals_node.draw_light(self)

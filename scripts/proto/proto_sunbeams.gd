class_name ProtoSunbeams
extends Node2D
## Promienie słońca - mechanika Świątyni Słońca (Dungeons.TEMPLE, decyzja autora 26.11.2026, liczby - Claude): co EVERY s
## (losowo w widełkach) przez posadzkę przesuwa się pas palącego światła. Najpierw zapowiedź: na ziemi blado pulsuje pas
## (WARN s) w miejscu startu, obok postaci; potem pas rozbłyska i sunie w poprzek (SPEED px/s przez TRAVEL px) - postać
## w pasie co TICK s obrywa (Prawia, odporność na żywioły zmniejsza). **Cień kolumn chroni**: każda wysoka ozdoba
## (przeszkoda ProtoDecor z promieniem >= SHELTER_MIN - kolumny, posągi, misy) rzuca cień w stronę ruchu pasa
## (SHADOW_LEN px, szerokość jak ozdoba); postać w cieniu nie obrywa. Cienie widać na ziemi, gdy pas jest blisko.
## Rysowane w grze (wielokąty, dodawane światło - tanio dla telefonów). Arena tworzy węzeł tylko w tym lochu
## (`arena.sunbeams`).

const EVERY := Vector2(6.0, 9.0)
const WARN := 1.2
const SPEED := 70.0
const TRAVEL := 250.0
## Pas: szerokość, długość (w poprzek ekranu), start (o tyle od postaci przed nią w kierunku ruchu).
const WIDTH := 34.0
const LENGTH := 460.0
const START := 110.0
const TICK := 0.5
const DAMAGE := 9
## Cień: od jakiego promienia przeszkody, długość, cienie rysowane do takiej odległości od pasa.
const SHELTER_MIN := 7.0
const SHADOW_LEN := 38.0
const SHADOW_SHOW := 140.0
const LIGHT := Color(1.0, 0.86, 0.45)

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: promienie same nie ruszają.
var passive := false
## Ile razy promień poparzył postać i ile razy cień ją ochronił (testy).
var burns := 0
var shelters := 0
## Stan pasa: "" (brak), "warn", "sweep"; środek, kierunek ruchu (pas leży prostopadle), czas, przebyta droga.
var state := ""
var center := Vector2.ZERO
var dir := Vector2.RIGHT
var _t := 0.0
var _gone := 0.0
var _tick := 0.0
var _next := 4.0
## Warstwy rysunku: światło (dodawane) i cienie kolumn (zwykłe, ciemne - na wierzchu).
var _light: _Layer
var _shade: _Layer


func _ready() -> void:
	z_index = -1  # na posadzce, pod postaciami
	_light = _Layer.new()
	_light.owner_beams = self
	_light.lit = true
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = add
	add_child(_light)
	_shade = _Layer.new()
	_shade.owner_beams = self
	add_child(_shade)


func _process(delta: float) -> void:
	if hero == null or hero.dead:
		state = ""
		_redraw()
		return
	match state:
		"warn":
			_t += delta
			if _t >= WARN:
				state = "sweep"
				_t = 0.0
				_tick = 0.0
		"sweep":
			var step := SPEED * delta
			center += dir * step
			_gone += step
			_tick -= delta
			if _tick <= 0.0 and covers(hero.global_position):
				_tick = TICK
				if sheltered(hero.global_position):
					shelters += 1
				else:
					burns += 1
					hero.take_damage(maxi(1, roundi(DAMAGE * power)), Elements.PRAWIA)
			if _gone >= TRAVEL:
				state = ""
		_:
			if not passive:
				_next -= delta
				if _next <= 0.0:
					start()
	_redraw()


func _redraw() -> void:
	if _light:
		_light.queue_redraw()
		_shade.queue_redraw()


## Zapowiedź nowego pasa: losowy kierunek ruchu, start przed postacią (pas przejdzie przez nią).
func start(direction := Vector2.ZERO) -> void:
	_next = randf_range(EVERY.x, EVERY.y)
	dir = direction.normalized() if direction != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
	center = hero.global_position - dir * START
	_t = 0.0
	_gone = 0.0
	state = "warn"


## Czy punkt `p` (stopy) leży w pasie światła.
func covers(p: Vector2) -> bool:
	if state != "sweep":
		return false
	var rel := p - center
	return absf(rel.dot(dir)) <= WIDTH * 0.5 and absf(rel.dot(dir.orthogonal())) <= LENGTH * 0.5


## Czy punkt `p` leży w cieniu kolumny (cień pada w stronę ruchu pasa).
func sheltered(p: Vector2) -> bool:
	for o in ProtoDecor.obstacles:
		if o.z < SHELTER_MIN:
			continue
		var rel := p - Vector2(o.x, o.y)
		var along := rel.dot(dir)
		if along >= -o.z * 0.5 and along <= SHADOW_LEN + o.z and absf(rel.dot(dir.orthogonal())) <= o.z * 1.1:
			return true
	return false


## Pas światła (warstwa dodawana).
func draw_light(on: CanvasItem) -> void:
	if state == "":
		return
	var side := dir.orthogonal() * LENGTH * 0.5
	var half := dir * WIDTH * 0.5
	var c := center - global_position
	var pts := PackedVector2Array([c - half - side, c + half - side, c + half + side, c - half + side])
	if state == "warn":
		var pulse := 0.5 + 0.5 * sin(_t * TAU * 2.5)
		on.draw_colored_polygon(pts, Color(LIGHT, 0.08 + 0.1 * pulse))
		on.draw_line(pts[1], pts[2], Color(LIGHT, 0.5), 1.0)  # przednia krawędź - stąd ruszy
		return
	on.draw_colored_polygon(pts, Color(LIGHT, 0.32))
	var inner := PackedVector2Array([c - half * 0.4 - side, c + half * 0.4 - side, c + half * 0.4 + side,
			c - half * 0.4 + side])
	on.draw_colored_polygon(inner, Color(1.0, 0.97, 0.85, 0.3))
	on.draw_line(pts[0], pts[3], Color(LIGHT, 0.7), 1.0)
	on.draw_line(pts[1], pts[2], Color(LIGHT, 0.7), 1.0)


## Cienie kolumn (warstwa zwykła): w czasie zapowiedzi i ruchu pasa, dla kolumn blisko jego drogi - ciemne,
## spłaszczone pasy od podstawy w stronę ruchu światła; tam warto się schować.
func draw_shade(on: CanvasItem) -> void:
	if state == "":
		return
	var a := 0.28 if state == "sweep" else 0.18
	for o in ProtoDecor.obstacles:
		if o.z < SHELTER_MIN:
			continue
		var base := Vector2(o.x, o.y)
		var ahead := (base - center).dot(dir)
		if ahead < -SHADOW_SHOW * 0.3 or ahead > TRAVEL + SHADOW_SHOW * 0.3 - _gone:
			continue
		if absf((base - center).dot(dir.orthogonal())) > LENGTH * 0.5:
			continue
		var b := base - global_position
		var w := dir.orthogonal() * o.z * 1.1
		var tip := b + dir * (SHADOW_LEN + o.z)
		on.draw_colored_polygon(PackedVector2Array([b - w, tip - w * 0.8, tip + w * 0.8, b + w]), Color(0.08, 0.05, 0.02, a))


## Warstwa rysunku promieni (światło albo cienie) - rysuje przez węzeł mechaniki.
class _Layer:
	extends Node2D
	var owner_beams: ProtoSunbeams
	var lit := false

	func _draw() -> void:
		if lit:
			owner_beams.draw_light(self)
		else:
			owner_beams.draw_shade(self)

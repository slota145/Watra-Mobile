class_name ProtoRockfall
extends Node2D
## Osuwiska - mechanika Kopalni karłów (Dungeons.MINE, decyzja autora 26.11.2026, liczby - Claude): co EVERY s (losowo
## w widełkach) ze stropu sypie się ROCKS głazów. Najpierw zapowiedź: czerwone koło (ProtoTelegraph) z rosnącym cieniem
## i sypiącym się pyłem - pierwsze koło pod postacią, reszta obok niej; po WARN s głaz spada (widać go w locie przez
## ostatnie FALL s) i rani postać w kole (ziemia, odporność na żywioły zmniejsza). **Głaz zostaje** na STAY s jako
## przeszkoda (ProtoDecor.obstacles i ProtoHero.obstacles - postać, potwory i boss go obchodzą) i osłona: pociski
## (ProtoArrow - kamienie procarzy, strzały, promienie) rozbijają się na głazie. Potem kruszy się i znika. Naraz najwyżej
## MAX_ROCKS głazów (najstarszy kruszy się pierwszy). Głazy i odłamki Króla Karłów - grafika z tools/mine_art.py.
## Arena tworzy węzeł tylko w tym lochu (`arena.rockfall`).

const EVERY := Vector2(5.0, 7.0)
const ROCKS := 3
const WARN := 1.4
const FALL := 0.3
const RADIUS := 18.0
const DAMAGE := 18
## Pozostałe głazy spadają tyle od postaci (px, losowo w widełkach).
const SPREAD := Vector2(45.0, 110.0)
const STAY := 6.0
const CRUMBLE := 0.5
## Przeszkoda głazu (promień koła spłaszczonego jak u ozdób) i zasięg osłony przed pociskami.
const ROCK_R := 10.0
const SHIELD_R := 12.0
const MAX_ROCKS := 8
const ROCK_TEX := preload("res://assets/watra/decor/mine/fallen_rock.png")
const ROCK_FRAMES := 3
const DROP_HEIGHT := 150.0
const DUST_FX := preload("res://assets/effects/boss_slam.png")
const DUST_FRAMES := 12
const DUST_ANCHOR := Vector2(37, 25)
const SHARDS_FX := preload("res://assets/effects/cleaver_impact.png")
const SHARDS_FRAMES := 9
const SHARDS_ANCHOR := Vector2(23, 17)
const LAND_SOUND := preload("res://assets/watra/chief_slam.ogg")

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: mechanika sama nie rusza.
var passive := false
## Ile razy głaz trafił postać i ile pocisków rozbiło się na głazach (testy).
var hits := 0
var blocked := 0
var _next := 4.0
## Spadające głazy: {"t": ProtoTelegraph, "at": Vector2, "rock": Sprite2D albo null}.
var _falling: Array = []
## Leżące głazy: {"rock": Sprite2D, "at": Vector2, "left": float, "obstacle": Vector3}.
var _rocks: Array = []
var _shadow: _Layer
var _dust: _Layer
var _drawn := false


func _ready() -> void:
	y_sort_enabled = true  # głazy sortują się po Y razem ze światem (postać chowa się za głazem)
	_shadow = _Layer.new()
	_shadow.rockfall = self
	_shadow.z_index = -1
	add_child(_shadow)
	_dust = _Layer.new()
	_dust.rockfall = self
	_dust.top = true
	_dust.z_index = 5
	add_child(_dust)


func _process(delta: float) -> void:
	_update_falling()
	_update_rocks(delta)
	_block_missiles()
	_redraw()
	if hero == null or hero.dead or passive:
		return
	_next -= delta
	if _next <= 0.0:
		start()


## Nowa fala głazów: pierwszy pod postacią (albo w `first`), reszta wokół niej.
func start(first := Vector2.INF) -> void:
	_next = randf_range(EVERY.x, EVERY.y)
	var center := hero.global_position if hero else Vector2.ZERO
	drop(first if first != Vector2.INF else center)
	for i in ROCKS - 1:
		var at := center + Vector2.from_angle(randf() * TAU) * randf_range(SPREAD.x, SPREAD.y) * Vector2(1, 0.75)
		drop(at.clamp(bounds.position, bounds.end))


## Zapowiedź jednego głazu w punkcie `at` (też dla odłamków Króla Karłów w testach).
func drop(at: Vector2) -> void:
	var t := ProtoTelegraph.new()
	t.radius = RADIUS
	t.duration = WARN
	get_parent().add_child(t)
	t.global_position = at
	_falling.append({"t": t, "at": at, "rock": null})


func _update_falling() -> void:
	for i in range(_falling.size() - 1, -1, -1):
		var f: Dictionary = _falling[i]
		var t: ProtoTelegraph = f.t
		if not is_instance_valid(t):
			_falling.remove_at(i)
			continue
		var left := (1.0 - t.progress) * WARN
		if f.rock == null and left <= FALL:
			f.rock = _make_rock(f.at)
		if f.rock:
			var k := clampf(1.0 - left / FALL, 0.0, 1.0)
			(f.rock as Sprite2D).offset.y = _rock_offset(f.rock) - DROP_HEIGHT * (1.0 - k * k)
		if t.progress < 1.0:
			continue
		_land(f)
		t.queue_free()
		_falling.remove_at(i)


func _land(f: Dictionary) -> void:
	var at: Vector2 = f.at
	var t: ProtoTelegraph = f.t
	if hero and not hero.dead and t.contains(hero.global_position):
		hits += 1
		hero.take_damage(maxi(1, roundi(DAMAGE * power)), Elements.EARTH)
	var rock: Sprite2D = f.rock if f.rock else _make_rock(at)
	rock.offset.y = _rock_offset(rock)
	Fx.once(get_parent(), DUST_FX, DUST_FRAMES, 18.0, at.round(), DUST_ANCHOR, 2, 0.5).modulate = Color(0.85, 0.75, 0.6)
	_sound(at)
	if _rocks.size() >= MAX_ROCKS:
		_crumble(0)
	var o := Vector3(at.x, at.y, ROCK_R)
	ProtoDecor.obstacles.append(o)
	if hero:
		hero.obstacles.append(o)
	_rocks.append({"rock": rock, "at": at, "left": STAY, "obstacle": o})


func _update_rocks(delta: float) -> void:
	for i in range(_rocks.size() - 1, -1, -1):
		_rocks[i].left -= delta
		if _rocks[i].left <= 0.0:
			_crumble(i)


## Głaz kruszy się: przestaje być przeszkodą, sypie odłamkami i gaśnie.
func _crumble(i: int) -> void:
	var r: Dictionary = _rocks[i]
	_rocks.remove_at(i)
	ProtoDecor.obstacles.erase(r.obstacle)
	if hero:
		hero.obstacles.erase(r.obstacle)
	var rock: Sprite2D = r.rock
	if is_instance_valid(rock):
		Fx.once(get_parent(), SHARDS_FX, SHARDS_FRAMES, 16.0, (r.at as Vector2).round(), SHARDS_ANCHOR, 2, 0.8)
		var tween := rock.create_tween()
		tween.tween_property(rock, "modulate:a", 0.0, CRUMBLE)
		tween.parallel().tween_property(rock, "scale", Vector2(1.15, 0.6), CRUMBLE)
		tween.tween_callback(rock.queue_free)


## Pociski lecące przez głaz rozbijają się na nim (osłona przed procarzami).
func _block_missiles() -> void:
	if _rocks.is_empty() or get_parent() == null:
		return
	for c in get_parent().get_children():
		if not (c is ProtoArrow) or c._done:
			continue
		var p: Vector2 = c.global_position
		if shelters(p):
			blocked += 1
			c._finish(true)


## Czy punkt `p` (na ziemi) leży w osłonie któregoś głazu.
func shelters(p: Vector2) -> bool:
	for r in _rocks:
		var at: Vector2 = r.at
		if Vector2(p.x - at.x, (p.y - at.y) * 2.0).length() <= SHIELD_R * 1.4:
			return true
	return false


## Ile głazów leży (testy).
func rock_count() -> int:
	return _rocks.size()


## Ile głazów jeszcze spada (testy).
func pending() -> int:
	return _falling.size()


func _make_rock(at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ROCK_TEX
	s.hframes = ROCK_FRAMES
	s.frame = randi() % ROCK_FRAMES
	s.flip_h = randf() < 0.5
	s.centered = false
	s.offset = Vector2(-ROCK_TEX.get_width() / float(ROCK_FRAMES) / 2.0, _rock_offset(s)).round()
	add_child(s)
	s.global_position = at
	return s


## Podstawa głazu nieco poniżej punktu na ziemi (stoi na kole, a nie nad nim).
func _rock_offset(s: Sprite2D) -> float:
	return -s.texture.get_height() + 4.0


func _sound(at: Vector2) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = LAND_SOUND
	p.volume_db = -10.0
	p.pitch_scale = randf_range(1.15, 1.35)
	get_parent().add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


## Cień głazu rośnie na ziemi (warstwa pod postaciami), z góry sypie się pył (warstwa nad nimi).
func draw_layer(on: CanvasItem, top: bool) -> void:
	for f in _falling:
		var t: ProtoTelegraph = f.t
		if not is_instance_valid(t):
			continue
		var at: Vector2 = (f.at as Vector2) - on.global_position
		var k := t.progress
		if not top:
			on.draw_set_transform(at, 0.0, Vector2(1.0, 0.5))
			on.draw_circle(Vector2.ZERO, 3.0 + 9.0 * k, Color(0, 0, 0, 0.18 + 0.25 * k))
			on.draw_set_transform(Vector2.ZERO)
			continue
		for j in 6:
			var ph := fposmod(k * 3.0 + j * 0.17, 1.0)
			var x := at.x + (float((j * 37) % 11) - 5.0) * 2.2
			var y := at.y - 70.0 + ph * 66.0
			on.draw_rect(Rect2(x, y, 1.0, 2.0), Color(0.8, 0.7, 0.55, 0.75 * (1.0 - ph)))


func _redraw() -> void:
	if _falling.is_empty() and not _drawn:
		return
	_drawn = not _falling.is_empty()
	_shadow.queue_redraw()
	_dust.queue_redraw()


## Warstwa rysunku (cienie albo pył) - rysuje przez węzeł mechaniki.
class _Layer:
	extends Node2D
	var rockfall: ProtoRockfall
	var top := false

	func _draw() -> void:
		rockfall.draw_layer(self, top)


func _exit_tree() -> void:
	for f in _falling:
		if is_instance_valid(f.t):
			f.t.queue_free()
	for r in _rocks:
		ProtoDecor.obstacles.erase(r.obstacle)
	_falling.clear()
	_rocks.clear()

class_name ProtoStaff
extends ProtoWeapon
## Kostur Leszego - pierwsza broń natury, magiczna (pomysły autora 25.11.2026; Elements.NATURE - trafienia dokładają
## znaki trucizny, ProtoTarget.poison). Kostur lewituje obok postaci (dziedziczy po ProtoWeapon: mana, odnowienia,
## kamienie, krytyki; szybkość - szybkość rzucania, premia obrażeń magicznych). Mechanika **sadzonek** (`_saplings`,
## najwyżej MAX_SAPLINGS, każda żyje SAPLING_LIFE s, najstarsza więdnie): zostawiają je Żołądź Leszego i Uścisk Boru,
## a Pylenie Mchu i Strażnicy Boru z nich korzystają, ale ich nie zużywają.
## - „Biegnące Korzenie” (`l_roots`, zwykły atak): korzenie wyskakują pod najbliższym wrogiem i biegną pod ziemią do
##   kolejnych (najbliższy nietrafiony w ROOT_JUMP), ROOT_TARGETS wrogów po kolei; 5. - więcej, 10. - co trzeci rzut dwa
##   łańcuchy; kamień unikalny (Zasiewu) - zabity korzeniami wróg z szansą ROOT_SEED zostawia sadzonkę.
## - „Żołądź Leszego” (`l_acorn`): żołądź leci przez wrogów (każdego rani raz), na końcu wyrasta sadzonka; 5. - dalej,
##   10. - dwa w wachlarzu; kamień unikalny (Muchołówki) - mięsożerna roślina (kłapie na najbliższego wroga).
## - „Uścisk Boru” (`l_grasp`): cierniowe korzenie chwytają GRASP_TARGETS losowych wrogów wokół postaci (rani,
##   unieruchamia); wrogowie z GRASP_PULL zdrowia lub mniej (nie elity ani bossowie) po GRASP_PULL_DELAY s znikają pod
##   ziemią (dobicie - `execute`) i w ich miejscu wyrasta sadzonka - zawsze przynajmniej jeden (najsłabszy złapany);
##   5. - więcej wrogów, 10. - próg wyżej; kamień unikalny (Głogu) - cierniowa sadzonka strzelająca cierniami.
## - „Pylenie Mchu” (`l_spores`): trujące zarodniki wybuchają wokół postaci i wokół każdej sadzonki (rani i dokłada
##   SPORE_POISON znaki trucizny); 5. - większe, 10. - więcej znaków; kamień unikalny (Purchawki) - zatruty wróg po
##   śmierci wybucha zarodnikami (`_on_victim_died`).
## - „Strażnicy Boru” (`l_treants`): drzewiec przy postaci i przy każdej sadzonce (najwyżej MAX_TREANTS naraz),
##   chodzą za wrogami i biją gałęziami przez TREANT_LIFE s (`_Treant`); 5. - dłużej, 10. - ciosy ogłuszają; kamień
##   unikalny (Leszego) - co TREANT_ROOT_EVERY s oplatają korzeniami najbliższego wroga.
## Grafika: kostur assets/weapons/staff.png (tools/staff_art.py), ikony tools/staff_icons.py, sadzonki i drzewiec ze
## SpriteKiln (assets/spritekiln/{sapling,carnivore,thorn,treant}/), efekty z kreatora (assets/effects/root_burst,
## acorn, spores, poison_hit, thorn, entangle, pull_under, nature_cast) - bez nich kształty rysowane w kodzie.

const STAFF_TEXTURE := preload("res://assets/weapons/staff.png")
const S_GRIP := Vector2(10.0, 17.0)
const S_SCALE := 0.5
const STAFF_LEN := 34.0
const NATURE := Color(0.55, 0.95, 0.35)
const ROOT_COLOR := Color(0.42, 0.28, 0.16)
## Efekty z kreatora: nazwa -> [klatki, fps, zaczepienie, skala]. Brak pliku - kształt z kodu (`_fx`).
const FX := {
	"root_burst": [9, 18.0, Vector2(20, 44), 0.8],
	"acorn": [5, 12.0, Vector2(12, 6), 1.0],
	"spores": [11, 16.0, Vector2(40, 28), 1.0],
	"poison_hit": [8, 18.0, Vector2(16, 16), 0.8],
	"thorn": [4, 12.0, Vector2(10, 4), 1.0],
	"entangle": [7, 10.0, Vector2(18, 34), 0.8],
	"pull_under": [9, 14.0, Vector2(20, 34), 0.9],
	"nature_cast": [7, 16.0, Vector2(18, 18), 0.8],
}
const SPORES_FX_RADIUS := 38.0
const SCENES := {"sapling": "res://assets/spritekiln/sapling/sapling.tscn",
	"carnivore": "res://assets/spritekiln/carnivore/carnivore.tscn",
	"thorn": "res://assets/spritekiln/thorn/thorn.tscn", "treant": "res://assets/spritekiln/treant/treant.tscn"}

## Rzucanie: uniesienie kostura, chwila po czarze, przerwa przed kolejnym zwykłym atakiem.
const CAST_TIME := 0.2
const AFTER_TIME := 0.12
const ROOTS_COOLDOWN := 0.45
## Biegnące Korzenie: ilu wrogów (5. poziom), zasięg przeskoku, odstęp między wyskokami, co który rzut dwa łańcuchy,
## Mnożenie (ilu więcej), kamień Zasiewu (szansa).
const ROOT_TARGETS := 3
const ROOT_TARGETS_PERK := 5
const ROOT_JUMP := 70.0
const ROOT_STEP := 0.08
const ROOT_DOUBLE_EVERY := 3
const ROOT_EXTRA := 2
const ROOT_SEED := 0.35
## Żołądź: prędkość, szerokość trafienia, 5. poziom (dalej), wachlarz (10. poziom i Mnożenie).
const ACORN_SPEED := 230.0
const ACORN_HIT := 10.0
const ACORN_LONG := 1.5
const ACORN_FAN := 0.25
## Uścisk Boru: ilu wrogów (5. poziom, Mnożenie), unieruchomienie, próg wciągnięcia (10. poziom), opóźnienie.
const GRASP_TARGETS := 4
const GRASP_TARGETS_PERK := 6
const GRASP_EXTRA := 2
const GRASP_HOLD := 1.5
const GRASP_PULL := 0.5
const GRASP_PULL_PERK := 0.6
const GRASP_PULL_DELAY := 0.5
## Pylenie Mchu: obłok przy postaci i przy sadzonce, 5. poziom, dodatkowe znaki trucizny (10. poziom), drugi wybuch
## (Mnożenie), kamień Purchawki (obłok, siła).
const SPORE_RADIUS := 50.0
const SPORE_SAPLING_RADIUS := 40.0
const SPORE_PERK_AREA := 1.3
const SPORE_POISON := 2
const SPORE_POISON_PERK := 3
const SPORE_ECHO := 0.4
const PUFF_RADIUS := 34.0
const PUFF_POWER := 0.5
## Sadzonki: najwyżej, życie, mięsożerna (co ile, zasięg, siła względem żołędzia), cierniowa (co ile, zasięg, siła
## względem Uścisku, prędkość ciernia).
const MAX_SAPLINGS := 12
const SAPLING_LIFE := 25.0
const BITE_EVERY := 1.0
const BITE_RANGE := 34.0
const BITE_POWER := 0.6
const THORN_EVERY := 1.2
const THORN_RANGE := 120.0
const THORN_POWER := 0.5
const THORN_SPEED := 260.0
## Drzewce: najwyżej, czas (5. poziom), prędkość, zasięg szukania i ciosu, co ile cios, ogłuszenie (10. poziom),
## kamień Leszego (co ile oplata, zasięg, unieruchomienie, siła).
const MAX_TREANTS := 10
const TREANT_LIFE := 12.0
const TREANT_LIFE_LONG := 16.0
const TREANT_SPEED := 40.0
const TREANT_SEEK := 140.0
const TREANT_REACH := 18.0
const TREANT_EVERY := 1.0
const TREANT_STUN := 0.4
const TREANT_ROOT_EVERY := 3.0
const TREANT_ROOT_RANGE := 60.0
const TREANT_ROOT_HOLD := 1.5
const TREANT_ROOT_POWER := 0.5

## Ile rzutów korzeni, ile wciągniętych pod ziemię, ile drzewców przyzwanych (testy).
var roots_casts := 0
var pulled := 0
var _pending := ""
## Sadzonki ({"node", "at", "kind", "left", "tick"}), lecące żołędzie i ciernie ({"node", "dir", "left", "power",
## "hits", "skill", "seed", "speed"}), drzewce (węzły _Treant).
var _saplings: Array = []
var _shots: Array = []
var _treants: Array = []
static var _fx_cache := {}


func _init() -> void:
	basic = "l_roots"
	main_skill = "l_roots"
	element = Elements.NATURE
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = STAFF_TEXTURE
		s.offset = -S_GRIP
		s.scale = Vector2.ONE * S_SCALE


func _world_fx() -> Array:
	return super._world_fx() + [_saplings, _shots, _treants]


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"l_cast":
			_process_cast()
		"l_after":
			if _t >= AFTER_TIME:
				_set_state("follow")
				_cooldown = ROOTS_COOLDOWN if _pending == basic else maxf(_cooldown, COOLDOWN * 0.5)
	_process_saplings(delta)
	_process_shots(delta)
	for tn in _treants.duplicate():
		if not is_instance_valid(tn):
			_treants.erase(tn)


# --- Pomocnicy ---

## Efekt `name` z kreatora (FX) w `at` (świat); bez pliku - kształt z kodu. Zwraca węzeł (albo null).
func _fx(name: String, at: Vector2, size := 1.0, z := 20, loop_parent: Node = null) -> Node2D:
	var info: Array = FX[name]
	var path := "res://assets/effects/%s.png" % name
	if not _fx_cache.has(name):
		_fx_cache[name] = load(path) if ResourceLoader.exists(path) else null
	var tex: Texture2D = _fx_cache[name]
	if tex == null:
		var shape := _Shape.new()
		shape.kind = name
		shape.z_index = z
		(loop_parent if loop_parent else get_parent()).add_child(shape)
		shape.global_position = at
		shape.scale = Vector2.ONE * size
		if loop_parent == null:
			var tw := shape.create_tween()
			tw.tween_property(shape, "modulate:a", 0.0, 0.45)
			tw.tween_callback(shape.queue_free)
		return shape
	if loop_parent:
		var fx := Fx.loop(loop_parent, tex, info[0], info[1], Vector2.ZERO, info[2], z, info[3] * size)
		fx.global_position = at
		return fx
	return Fx.once(get_parent(), tex, info[0], info[1], at.round(), info[2], z, info[3] * size)


## Trafienie: zielony rozprysk trucizny.
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)
	_fx("poison_hit", t.center(), 0.8)


func _deal(t: ProtoTarget, amount: int, from: Vector2, skill: String) -> void:
	super._deal(t, amount, from, skill)
	if _unique("l_spores") and t is ProtoGoblin and not t.died.is_connected(_on_victim_died):
		t.died.connect(_on_victim_died)


## Wszyscy w kole `radius` wokół `at` (spłaszczonym jak cienie). Zwraca trafionych.
func _ring_hits(at: Vector2, radius: float, power: float, skill: String) -> Array:
	var hit: Array = []
	for t in _near(at, radius):
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_hit(t, power, at, skill)
			hit.append(t)
	return hit


## Kostur nad postacią, kamieniem w górę, delikatnie się kołysze (czar).
func _raise(k: float) -> void:
	position = hero.position + Vector2(0, 1)
	var side := 1.0 if hero.facing.x >= 0.0 else -1.0
	_sprite.position = _orbit_center() - global_position + Vector2(side * 10.0, -8.0 - 6.0 * k)
	_sprite.rotation = -PI / 2.0 + 0.15 * side * (1.0 - k)


# --- Rzucanie czarów ---

func _attack(_second := false, _full := false) -> void:
	_cast(basic)


## Unosi kostur i po CAST_TIME rzuca czar `id` (`_release`).
func _cast(id: String) -> void:
	_pending = id
	_from_sprite = _sprite.position
	_set_state("l_cast")
	var best := _nearest(Skills.DATA[id].range * _area(id))
	hero.play_gesture(best.global_position if best else hero.global_position + hero.facing * 20.0)


func _process_cast() -> void:
	var k := clampf(_t / CAST_TIME, 0.0, 1.0)
	_raise(k)
	if _t >= CAST_TIME:
		var tip := _sprite.global_position + Vector2.from_angle(_sprite.rotation) * STAFF_LEN * 0.9
		_fx("nature_cast", tip, 0.8, 21)
		_release(_pending)
		_set_state("l_after")


func _release(id: String) -> void:
	match id:
		"l_roots":
			_cast_roots()
		"l_acorn":
			_cast_acorn()
		"l_grasp":
			_cast_grasp()
		"l_spores":
			_cast_spores(_power("l_spores"))
			var extra := gem_power("l_spores", "multi") / 100.0
			if extra > 0.0:
				get_tree().create_timer(SPORE_ECHO, false).timeout.connect(_cast_spores.bind(_power("l_spores") * extra))
		"l_treants":
			_cast_treants()


func _start(id: String) -> void:
	if id == basic or not id in ["l_acorn", "l_grasp", "l_spores", "l_treants"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_cast(id)
	skill_used.emit(id)


# --- Biegnące Korzenie ---

func _cast_roots() -> void:
	roots_casts += 1
	var reach: float = Skills.DATA.l_roots.range * _area(basic)
	var first := _nearest(reach)
	if first == null:
		return
	var count := ROOT_TARGETS_PERK if _perk(basic, 0) else ROOT_TARGETS
	var extra := ROOT_EXTRA if gem_power(basic, "multi") > 0.0 else 0
	_root_chain(first, count, extra, hero.global_position)
	if _perk(basic, 1) and roots_casts % ROOT_DOUBLE_EVERY == 0:
		var second: ProtoTarget = null
		for t in _near(hero.global_position, reach):
			if t != first:
				second = t
				break
		if second:
			_root_chain(second, count, extra, hero.global_position)


## Łańcuch korzeni od `start`: `count` wrogów (plus `extra` słabszych z Mnożenia), każdy kolejny - najbliższy
## nietrafiony w ROOT_JUMP; wyskoki po kolei co ROOT_STEP s, między nimi biegnie korzeń pod ziemią.
func _root_chain(start: ProtoTarget, count: int, extra: int, from: Vector2) -> void:
	var chain: Array = [start]
	var seen := {start: true}
	while chain.size() < count + extra:
		var cur: ProtoTarget = chain[-1]
		var best: ProtoTarget = null
		var best_d := ROOT_JUMP * _area(basic)
		for t in _near(cur.global_position, best_d):
			var d := t.global_position.distance_to(cur.global_position)
			if not seen.has(t) and d <= best_d:
				best = t
				best_d = d
		if best == null:
			break
		seen[best] = true
		chain.append(best)
	var prev := from
	for i in chain.size():
		var t: ProtoTarget = chain[i]
		var power := _power(basic) * (gem_power(basic, "multi") / 100.0 if i >= count else 1.0)
		get_tree().create_timer(ROOT_STEP * i, false).timeout.connect(_root_strike.bind(t, prev, power))
		prev = t.global_position


func _root_strike(t: ProtoTarget, from: Vector2, power: float) -> void:
	if not is_inside_tree() or hero == null or not is_instance_valid(t) or not t.alive():
		return
	_root_line(from, t.global_position)
	_fx("root_burst", t.global_position, 1.0, 2)
	_hit(t, power, from, basic)
	if not t.alive() and _unique(basic) and randf() < ROOT_SEED:
		add_sapling(t.global_position, "sapling")


## Korzeń biegnący pod ziemią: brązowa, postrzępiona linia, która szybko gaśnie.
func _root_line(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = ROOT_COLOR
	line.z_index = -1
	var side := (b - a).orthogonal().normalized()
	for i in 7:
		line.add_point(a.lerp(b, i / 6.0) + side * (0.0 if i in [0, 6] else randf_range(-3.0, 3.0)))
	get_parent().add_child(line)
	var tw := line.create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(line, "modulate:a", 0.0, 0.3)
	tw.tween_callback(line.queue_free)


# --- Żołądź Leszego ---

func _cast_acorn() -> void:
	var reach: float = Skills.DATA.l_acorn.range * _area("l_acorn") * (ACORN_LONG if _perk("l_acorn", 0) else 1.0)
	var best := _nearest(reach)
	var from := _orbit_center()
	var dir: Vector2 = (best.center() - from).normalized() if best else hero.facing.normalized()  # lot na wysokości pasa
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var kind := "carnivore" if _unique("l_acorn") else "sapling"
	if _perk("l_acorn", 1):
		_launch(from, dir.rotated(-ACORN_FAN * 0.5), _power("l_acorn"), "l_acorn", reach, kind)
		_launch(from, dir.rotated(ACORN_FAN * 0.5), _power("l_acorn"), "l_acorn", reach, kind)
	else:
		_launch(from, dir, _power("l_acorn"), "l_acorn", reach, kind)
	var extra := gem_power("l_acorn", "multi") / 100.0
	if extra > 0.0:  # Mnożenie: boczne żołędzie, bez sadzonek
		_launch(from, dir.rotated(-ACORN_FAN * 1.6), _power("l_acorn") * extra, "l_acorn", reach, "")
		_launch(from, dir.rotated(ACORN_FAN * 1.6), _power("l_acorn") * extra, "l_acorn", reach, "")


## Pocisk (żołądź albo cierń) z `from` w kierunku `dir`; na końcu lotu - sadzonka rodzaju `seed` ("" - bez).
func _launch(from: Vector2, dir: Vector2, power: float, skill: String, distance: float, seed: String,
		fx := "acorn", speed := ACORN_SPEED) -> void:
	var node := _fx(fx, from, 1.0, 21, get_parent())
	node.rotation = dir.angle()
	_shots.append({"node": node, "dir": dir, "left": distance, "power": power, "hits": [], "skill": skill,
			"seed": seed, "speed": speed})


func _process_shots(delta: float) -> void:
	for sh in _shots.duplicate():
		var node: Node2D = sh.node
		if not is_instance_valid(node):
			_shots.erase(sh)
			continue
		var step: float = sh.speed * delta
		var a := node.global_position
		node.global_position += sh.dir * step
		sh.left -= step
		var mid := (a + node.global_position) * 0.5
		for t in _near(mid, step + ACORN_HIT + CENTER_PAD):
			if sh.hits.has(t):
				continue
			var p := Geometry2D.get_closest_point_to_segment(t.center(), a, node.global_position)
			if p.distance_to(t.center()) <= ACORN_HIT:
				sh.hits.append(t)
				_hit(t, sh.power, a, sh.skill)
				if sh.skill == "thorn":
					_shots.erase(sh)
					node.queue_free()
					break
		if sh.left <= 0.0 and is_instance_valid(node):
			if sh.seed != "":
				add_sapling(node.global_position + Vector2(0, ORBIT_HEIGHT), sh.seed)
			node.queue_free()
			_shots.erase(sh)


# --- Uścisk Boru ---

func _cast_grasp() -> void:
	var reach: float = Skills.DATA.l_grasp.range * _area("l_grasp")
	var count := (GRASP_TARGETS_PERK if _perk("l_grasp", 0) else GRASP_TARGETS) \
			+ (GRASP_EXTRA if gem_power("l_grasp", "multi") > 0.0 else 0)
	var pool: Array = []
	for t in _near(hero.global_position, reach):
		if t.global_position.distance_to(hero.global_position) <= reach:
			pool.append(t)
	pool.shuffle()
	var caught := pool.slice(0, count)
	if caught.is_empty():
		return
	var threshold := GRASP_PULL_PERK if _perk("l_grasp", 1) else GRASP_PULL
	var power := _power("l_grasp")
	var weakest: ProtoTarget = null
	for t in caught:
		_hit(t, power, hero.global_position, "l_grasp")
		if not t.alive():
			continue
		t.stun(GRASP_HOLD)
		_hold_fx(t, GRASP_HOLD)
		if not _tough(t) and (weakest == null or t.health_fraction() < weakest.health_fraction()):
			weakest = t
	var to_pull: Array = []
	for t in caught:
		if t.alive() and not _tough(t) and t.health_fraction() <= threshold:
			to_pull.append(t)
	if to_pull.is_empty() and weakest and weakest.alive():
		to_pull.append(weakest)  # zawsze przynajmniej jeden (nie elita ani boss)
	for t in to_pull:
		get_tree().create_timer(GRASP_PULL_DELAY, false).timeout.connect(_pull_under.bind(t))


## Oplątanie cierniowymi korzeniami na `time` s (efekt przy wrogu, idzie za nim).
func _hold_fx(t: ProtoTarget, time: float) -> void:
	var fx := _fx("entangle", t.global_position, 1.0, 1, t)
	fx.position = Vector2.ZERO
	get_tree().create_timer(time, false).timeout.connect(func() -> void:
		if is_instance_valid(fx):
			fx.queue_free())


## Wróg znika pod ziemią (dobicie), a w jego miejscu wyrasta sadzonka (kamień Głogu - cierniowa).
func _pull_under(t: ProtoTarget) -> void:
	if not is_inside_tree() or not is_instance_valid(t) or not t.alive():
		return
	var at := t.global_position
	execute(t, at)
	pulled += 1
	_fx("pull_under", at, 1.0, 2)
	add_sapling(at, "thorn" if _unique("l_grasp") else "sapling")
	Input.vibrate_handheld(20)


# --- Pylenie Mchu ---

func _cast_spores(power: float) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	var grow := SPORE_PERK_AREA if _perk("l_spores", 0) else 1.0
	_spore_burst(hero.global_position, SPORE_RADIUS * _area("l_spores") * grow, power)
	for s in _saplings:
		_spore_burst(s.at, SPORE_SAPLING_RADIUS * _area("l_spores") * grow, power)
	Input.vibrate_handheld(15)


## Obłok zarodników: rani w kole i dokłada dodatkowe znaki trucizny (jeden daje samo trafienie naturą).
func _spore_burst(at: Vector2, radius: float, power: float) -> void:
	_fx("spores", at, radius / SPORES_FX_RADIUS, 19)
	var stacks := SPORE_POISON_PERK if _perk("l_spores", 1) else SPORE_POISON
	for t in _near(at, radius):
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			var amount := _roll(power)
			_deal(t, amount, at, "l_spores")
			for i in stacks - 1:
				t.poison(amount * Elements.POISON_SHARE, Elements.POISON_TIME * duration_mult, penetration)


## Kamień Purchawki: zatruty wróg po śmierci wybucha zarodnikami.
func _on_victim_died(g: ProtoGoblin) -> void:
	if is_inside_tree() and _unique("l_spores") and g.is_poisoned():
		_spore_burst(g.global_position, PUFF_RADIUS * _area("l_spores"), _power("l_spores") * PUFF_POWER)


# --- Sadzonki ---

## Nowa sadzonka rodzaju `kind` (sapling, carnivore, thorn) w `at`; ponad MAX_SAPLINGS więdnie najstarsza.
func add_sapling(at: Vector2, kind: String) -> void:
	if not is_inside_tree():
		return
	while _saplings.size() >= MAX_SAPLINGS:
		_wither(_saplings.pop_front())
	var node := _plant_node(kind)
	get_parent().add_child(node)
	node.global_position = at.round()
	_play(node, &"spawn", &"idle")
	_saplings.append({"node": node, "at": at, "kind": kind, "left": SAPLING_LIFE * duration_mult, "tick": 0.5})


## Węzeł rośliny: model SpriteKiln albo kształt z kodu.
func _plant_node(kind: String) -> Node2D:
	var path: String = SCENES[kind]
	if ResourceLoader.exists(path):
		return (load(path) as PackedScene).instantiate()
	var shape := _Shape.new()
	shape.kind = kind
	return shape


## Animacja `anim` modelu SpriteKiln, potem `then` (kształt z kodu - nic).
static func _play(node: Node, anim: StringName, then := &"") -> void:
	if node.has_method("play_anim"):
		node.play_anim(anim)
		if then != &"" and node.has_signal("anim_finished"):
			node.anim_finished.connect(func(a: StringName) -> void:
				if a == anim and is_instance_valid(node):
					node.play_anim(then), CONNECT_ONE_SHOT)


func _wither(s: Dictionary) -> void:
	var node: Node2D = s.node
	if not is_instance_valid(node):
		return
	_play(node, &"death")
	var tw := node.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(node, "modulate:a", 0.0, 0.3)
	tw.tween_callback(node.queue_free)


func _process_saplings(delta: float) -> void:
	for s in _saplings.duplicate():
		s.left -= delta
		if s.left <= 0.0:
			_saplings.erase(s)
			_wither(s)
			continue
		if s.kind == "sapling" or hero == null or hero.dead:
			continue
		s.tick -= delta
		if s.tick > 0.0:
			continue
		if s.kind == "carnivore":
			s.tick = BITE_EVERY
			var best: ProtoTarget = null
			var best_d := BITE_RANGE * _area("l_acorn")
			for t in _near(s.at, best_d):
				var d: float = t.global_position.distance_to(s.at)
				if d <= best_d:
					best = t
					best_d = d
			if best:
				_face_node(s.node, best.global_position - (s.at as Vector2))
				_play(s.node, &"attack", &"idle")
				_hit(best, _power("l_acorn") * BITE_POWER, s.at, "l_acorn")
		else:
			s.tick = THORN_EVERY
			var near := _near(s.at, THORN_RANGE * _area("l_grasp"))
			if not near.is_empty():
				var t: ProtoTarget = near.pick_random()
				var at: Vector2 = s.at
				var dir: Vector2 = (t.center() - (at + Vector2(0, -10))).normalized()
				_face_node(s.node, dir)
				_play(s.node, &"attack", &"idle")
				_launch(s.at + Vector2(0, -10), dir, _power("l_grasp") * THORN_POWER, "thorn", THORN_RANGE * 1.3, "",
						"thorn", THORN_SPEED)


static func _face_node(node: Node, dir: Vector2) -> void:
	if node.has_method("face"):
		node.face(dir)


## Ile sadzonek rośnie (testy); ile danego rodzaju.
func saplings(kind := "") -> int:
	return _saplings.size() if kind == "" else _saplings.filter(func(s: Dictionary) -> bool: return s.kind == kind).size()


# --- Strażnicy Boru ---

func _cast_treants() -> void:
	var spots: Array = [hero.global_position + hero.facing.normalized() * 14.0]
	for s in _saplings:
		spots.append(s.at)
	var power := _power("l_treants")
	var extra := gem_power("l_treants", "multi") / 100.0
	for i in spots.size():
		_add_treant(spots[i], power)
	if extra > 0.0:
		_add_treant(hero.global_position - hero.facing.normalized() * 14.0, power * extra)


func _add_treant(at: Vector2, power: float) -> void:
	while _treants.size() >= MAX_TREANTS:
		var old: _Treant = _treants.pop_front()
		if is_instance_valid(old):
			old.leave()
	var t := _Treant.new()
	t.weapon = self
	t.power = power
	t.left = (TREANT_LIFE_LONG if _perk("l_treants", 0) else TREANT_LIFE) * duration_mult
	get_parent().add_child(t)
	t.global_position = at.round()
	_treants.append(t)


## Ile drzewców stoi (testy).
func treants() -> int:
	return _treants.filter(func(t) -> bool: return is_instance_valid(t) and not t.leaving).size()


## Drzewiec: chodzi za najbliższym wrogiem (przy postaci, gdy wrogów brak), co TREANT_EVERY s bije gałęzią; znika po
## `left` s. Model SpriteKiln (idle, walk, attack ze zdarzeniem `hit`, spawn, hit, death) albo kształt z kodu.
class _Treant extends Node2D:
	var weapon: ProtoStaff
	var power := 1.0
	var left := 12.0
	var leaving := false
	var _body: Node2D
	var _cooldown := 0.6
	var _root_t := 1.5
	var _target: ProtoTarget

	func _ready() -> void:
		_body = weapon._plant_node("treant")
		add_child(_body)
		ProtoStaff._play(_body, &"spawn", &"idle")
		if _body is _Shape:
			_body.scale = Vector2.ONE * 1.4

	func leave() -> void:
		if leaving:
			return
		leaving = true
		ProtoStaff._play(_body, &"death")
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)

	func _process(delta: float) -> void:
		if leaving or weapon == null or not is_instance_valid(weapon) or weapon.hero == null:
			return
		left -= delta
		if left <= 0.0 or weapon.hero.dead:
			leave()
			return
		_cooldown -= delta
		_root_t -= delta
		if _target == null or not is_instance_valid(_target) or not _target.alive() \
				or _target.global_position.distance_to(global_position) > ProtoStaff.TREANT_SEEK * 1.3:
			_target = _nearest()
		var goal: Vector2 = _target.global_position if _target else weapon.hero.global_position
		var to := goal - global_position
		var reach := ProtoStaff.TREANT_REACH if _target else 26.0
		if to.length() > reach:
			global_position += to.normalized() * ProtoStaff.TREANT_SPEED * delta
			global_position = ProtoDecor.push_out(global_position, 6.0)
			ProtoStaff._face_node(_body, to)
			_anim(&"walk")
		else:
			_anim(&"idle")
			if _target and _cooldown <= 0.0:
				_cooldown = ProtoStaff.TREANT_EVERY
				ProtoStaff._face_node(_body, to)
				ProtoStaff._play(_body, &"attack", &"idle")
				weapon._hit(_target, power, global_position, "l_treants")
				if weapon._perk("l_treants", 1) and _target.alive():
					_target.stun(ProtoStaff.TREANT_STUN)
		if weapon._unique("l_treants") and _root_t <= 0.0:
			_root_t = ProtoStaff.TREANT_ROOT_EVERY
			var near := weapon.targets_near(global_position, ProtoStaff.TREANT_ROOT_RANGE)
			if not near.is_empty():
				var t: ProtoTarget = near[0]
				t.stun(ProtoStaff.TREANT_ROOT_HOLD)
				weapon._hold_fx(t, ProtoStaff.TREANT_ROOT_HOLD)
				weapon._hit(t, power * ProtoStaff.TREANT_ROOT_POWER, global_position, "l_treants")

	func _anim(a: StringName) -> void:
		if _body.has_method("play_anim") and _body.get("animation") != a and _body.get("animation") != &"attack" \
				and _body.get("animation") != &"spawn":
			_body.play_anim(a)

	func _nearest() -> ProtoTarget:
		var best: ProtoTarget = null
		var best_d := ProtoStaff.TREANT_SEEK
		for t in weapon.targets_near(global_position, best_d):
			var d := t.global_position.distance_to(global_position)
			if d <= best_d:
				best = t
				best_d = d
		return best


## Kształty zastępcze (bez grafik): sadzonka, mięsożerna, cierniowa, drzewiec, korzenie, obłok zarodników, żołądź, cierń.
class _Shape extends Node2D:
	var kind := "sapling"

	func _draw() -> void:
		match kind:
			"sapling", "carnivore", "thorn":
				draw_line(Vector2.ZERO, Vector2(0, -10), Color(0.3, 0.55, 0.2), 2.0)
				draw_circle(Vector2(-3, -9), 3.0, Color(0.45, 0.8, 0.3))
				draw_circle(Vector2(3, -11), 3.0, Color(0.5, 0.85, 0.35))
				if kind == "carnivore":
					draw_circle(Vector2(0, -14), 4.0, Color(0.7, 0.2, 0.2))
				elif kind == "thorn":
					draw_line(Vector2(0, -10), Vector2(0, -16), Color(0.25, 0.35, 0.15), 2.0)
			"treant":
				draw_rect(Rect2(-6, -20, 12, 20), Color(0.42, 0.28, 0.16))
				draw_circle(Vector2(0, -22), 9.0, Color(0.3, 0.55, 0.22))
				draw_rect(Rect2(-3, -15, 2, 2), Color(0.7, 1.0, 0.55))
				draw_rect(Rect2(1, -15, 2, 2), Color(0.7, 1.0, 0.55))
			"spores":
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
				draw_circle(Vector2.ZERO, ProtoStaff.SPORES_FX_RADIUS, Color(0.55, 0.9, 0.3, 0.25))
			"root_burst", "pull_under", "entangle":
				for i in 4:
					var x := -6.0 + i * 4.0
					draw_line(Vector2(x, 0), Vector2(x + 1.0, -12.0 - (i % 2) * 4.0), Color(0.42, 0.28, 0.16), 2.0)
			"acorn":
				draw_circle(Vector2.ZERO, 3.0, Color(0.6, 0.4, 0.2))
			"thorn":
				draw_line(Vector2(-5, 0), Vector2(5, 0), Color(0.3, 0.4, 0.15), 2.0)
			_:
				draw_circle(Vector2.ZERO, 4.0, Color(0.55, 0.95, 0.35, 0.6))

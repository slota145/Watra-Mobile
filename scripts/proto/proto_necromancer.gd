class_name ProtoNecromancer
extends ProtoChief
## Nekromanta - boss Katakumb (Dungeons.CATACOMBS, ataki wybrane przez autora 15.11.2026). Reszta (wejście, pasek
## zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Trzyma się z dala od Wojciecha i na zmianę:
## - Kule Nawii: wachlarz BOLTS wolnych fioletowych kul (ProtoArrow z `bubble`, żywioł Nawii) - przejdź między nimi;
## - Kościany krąg: pierścień kół wokół postaci z luką (RING_GAP kół brakuje, od strony z dala od Nekromanty);
##   najpierw z pierścienia wyrastają kolce (RING_WARN s), potem środek (RING_CENTER_WARN s) - trzeba wybiec
##   z kręgu przez lukę, zanim wypełni się środek;
## - Wyssanie życia: gdy postać jest bliżej niż DRAIN_RANGE - koło zasięgu wokół Nekromanty i fioletowa wiązka;
##   przez DRAIN_TIME s co DRAIN_TICK s rani Nawią i leczy Nekromantę; wyjście poza koło przerywa wiązkę;
## - Przywołanie szkieletów: z ziemi wstaje SUMMON_COUNT szkieletów (co SUMMON_COOLDOWN s).
## Grafika: model SpriteKiln assets/spritekiln/necromancer/ (idle, walk, roar, bolts, ring, drain, summon, hit,
## death), do tego czasu powiększony goblin w kolorze Nawii.

const NECRO_SCENE := "res://assets/spritekiln/necromancer/necromancer.tscn"
const NECRO_HP := 900
const KEEP_DISTANCE := 85.0
const ATTACK_RANGE := 140.0
const BOLTS := 5
const BOLT_FAN := deg_to_rad(16.0)
const BOLT_WARN := 0.7
const BOLT_DAMAGE := 16
const BOLT_SPEED := 80.0
const BOLT_RANGE := 320.0
const RING_COUNT := 12
const RING_GAP := 2
const RING_RADIUS := 50.0
const RING_SPIKE := 13.0
const RING_WARN := 0.8
const RING_CENTER := 42.0
const RING_CENTER_WARN := 1.6
const RING_DAMAGE := 22
const DRAIN_RANGE := 95.0
const DRAIN_TIME := 2.0
## Co tyle sekund wiązka rani (dłużej niż ProtoHero.INVULNERABLE, więc każdy cios wchodzi).
const DRAIN_TICK := 0.4
const DRAIN_DAMAGE := 6
const DRAIN_HEAL := 12
const DRAIN_START := 0.4
const SUMMON_COUNT := 4
const SUMMON_RING := 50.0
const SUMMON_TIME := 1.0
const SUMMON_COOLDOWN := 12.0
const NAWIA_TINT := Color(0.75, 0.5, 1.0)
const ATTACKS: Array[String] = ["bolts", "ring", "drain"]

var _drops: Array[ProtoTelegraph] = []
var _beam: Line2D
var _drain_tick := 0.0
var _summon_cooldown := 6.0
var _summon_points: Array = []
var _last_attack := ""
var _bolt_dir := Vector2.DOWN
## Testy i zrzuty: sam nie wybiera ataków.
var passive := false


func _init() -> void:
	scene_path = NECRO_SCENE
	base_hp = NECRO_HP
	fallback_tint = Color(0.75, 0.55, 1.0)
	keep_distance = KEEP_DISTANCE
	anim_hit_at = {&"bolts": 0.3, &"ring": 0.35, &"summon": 0.35, &"drain": 0.26}
	anim_fallback = {&"bolts": &"attack", &"ring": &"attack", &"drain": &"attack", &"summon": &"attack",
		&"roar": &"idle", &"slam": &"attack", &"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_summon_cooldown -= delta
	_update_drops()
	if state == "dead" or hero == null:
		return
	match state:
		"bolts":
			_sync_anim(&"bolts", BOLT_WARN)
			if _timer >= BOLT_WARN:
				_fire_bolts()
		"ring":
			_sync_anim(&"ring", RING_WARN)
			if _timer >= RING_CENTER_WARN:
				_set_state("recover")
		"drain":
			_sync_anim(&"drain", DRAIN_START)
			_update_drain(delta)
		"summon":
			_sync_anim(&"summon", SUMMON_TIME)
			if _timer >= SUMMON_TIME:
				summon_minions.emit(_summon_points)
				_set_state("recover")


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	if _summon_cooldown <= 0.0:
		start_attack("summon")
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "drain" or distance < DRAIN_RANGE))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (bolts, ring, drain, summon) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	_face(hero.global_position - global_position)
	_play(&"idle")
	match kind:
		"bolts":
			_set_state("bolts")
			_bolt_dir = (hero.global_position - global_position).normalized()
		"ring":
			_start_ring()
		"drain":
			_set_state("drain")
			_drain_tick = DRAIN_START
			_telegraph = _make_telegraph(global_position, DRAIN_RANGE, DRAIN_START + DRAIN_TIME)
			_telegraph.modulate = NAWIA_TINT
		"summon":
			_start_summon()


## Kule Nawii: wachlarz wolnych kul w kierunku z chwili zamachu.
func _fire_bolts() -> void:
	for i in BOLTS:
		var b := ProtoArrow.new()
		b.hero = hero
		b.bubble = true
		b.element = Elements.NAWIA
		b.tint = NAWIA_TINT
		b.speed = BOLT_SPEED
		b.fly_range = BOLT_RANGE
		b.damage = roundi(BOLT_DAMAGE * power)
		b.direction = _bolt_dir.rotated(BOLT_FAN * (i - (BOLTS - 1) / 2.0))
		b.position = position + b.direction * 10.0
		get_parent().add_child(b)
	_sound(ROAR_SOUND, -10.0, randf_range(1.6, 1.8))
	_set_state("recover")


## Kościany krąg: pierścień kół z luką z dala od Nekromanty, potem środek.
func _start_ring() -> void:
	_set_state("ring")
	var center := hero.global_position
	var away := (center - global_position).angle()
	for i in RING_COUNT:
		var a := away + TAU * (i + 0.5) / RING_COUNT
		if absf(angle_difference(a, away)) < TAU * RING_GAP / RING_COUNT / 2.0:
			continue  # luka - droga ucieczki
		_add_drop(center + Vector2.from_angle(a) * RING_RADIUS * Vector2(1, ProtoTelegraph.SQUASH), RING_SPIKE, RING_WARN)
	_add_drop(center, RING_CENTER, RING_CENTER_WARN)


func _add_drop(at: Vector2, radius: float, warn: float) -> void:
	var t := ProtoTelegraph.new()
	t.radius = radius
	t.duration = warn
	get_parent().add_child(t)
	t.global_position = at
	_drops.append(t)


## Kolce wyrastają tam, gdzie koło się wypełniło.
func _update_drops() -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var t := _drops[i]
		if not is_instance_valid(t):
			_drops.remove_at(i)
			continue
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hero.take_damage(roundi(RING_DAMAGE * power))
		Fx.once(get_parent(), FX_SLAM, 12, 18.0, t.global_position, Vector2(37, 25), 20, t.radius / 34.0).modulate = Color(0.95, 0.9, 0.8)
		t.queue_free()
		_drops.remove_at(i)


## Czy kolce kręgu jeszcze czekają (testy).
func ring_pending() -> int:
	return _drops.size()


## Wiązka: co DRAIN_TICK s rani i leczy, póki postać jest w kole; po DRAIN_TIME albo wyjściu - koniec.
func _update_drain(delta: float) -> void:
	var inside := hero and not hero.dead and _telegraph and is_instance_valid(_telegraph) and _telegraph.contains(hero.global_position)
	if _timer < DRAIN_START:
		return
	if not inside or _timer >= DRAIN_START + DRAIN_TIME:
		_end_drain()
		return
	if _beam == null:
		_beam = Line2D.new()
		_beam.width = 3.0
		_beam.default_color = Color(NAWIA_TINT, 0.85)
		_beam.z_index = 20
		get_parent().add_child(_beam)
	_beam.points = PackedVector2Array([global_position + Vector2(0, -26), hero.global_position + Vector2(0, -12)])
	_beam.width = 2.5 + sin(_timer * 30.0)
	_drain_tick -= delta
	if _drain_tick <= 0.0:
		_drain_tick = DRAIN_TICK
		hero.take_damage(roundi(DRAIN_DAMAGE * power), Elements.NAWIA)
		hp = mini(hp + roundi(DRAIN_HEAL * power), max_hp)
		health_changed.emit(hp, max_hp)


## Czy wiązka właśnie wysysa (testy).
func draining() -> bool:
	return _beam != null


func _end_drain() -> void:
	if _beam and is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null
	_remove_telegraph()
	_set_state("recover")


func _start_summon() -> void:
	_last_attack = "summon"
	_set_state("summon")
	_summon_cooldown = SUMMON_COOLDOWN
	_summon_points = []
	var start := randf() * TAU
	for i in SUMMON_COUNT:
		var p := global_position + Vector2.from_angle(start + TAU * i / SUMMON_COUNT) * SUMMON_RING * Vector2(1, 0.7)
		p = p.clamp(bounds.position, bounds.end)
		_summon_points.append(p)
		Fx.once(get_parent(), FX_ROAR, 10, 14.0, p, Vector2(73, 42), -1, 0.35).modulate = NAWIA_TINT
	_sound(ROAR_SOUND, -6.0, randf_range(0.6, 0.7))


func _die() -> void:
	if _beam and is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	_drops.clear()
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	if _beam and is_instance_valid(_beam):
		_beam.queue_free()

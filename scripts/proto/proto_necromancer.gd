class_name ProtoNecromancer
extends ProtoChief
## Nekromanta - boss Katakumb (Dungeons.CATACOMBS, ataki wybrane przez autora 15.11.2026). Reszta (wejście, pasek
## zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Trzyma się z dala od Wojciecha i na zmianę:
## - Kule Nawii: wachlarz BOLTS wolnych fioletowych kul (ProtoArrow z `bubble`, żywioł Nawii) - przejdź między nimi;
## - Kościany krąg: pierścień kół wokół postaci z luką (RING_GAP kół brakuje, od strony z dala od Nekromanty);
##   najpierw z pierścienia wyrastają kolce (RING_WARN s), potem środek (RING_CENTER_WARN s) - trzeba wybiec
##   z kręgu przez lukę, zanim wypełni się środek;
## - Wyssanie życia: gdy postać jest w kole DRAIN_RANGE (`in_drain_range`) - koło zasięgu wokół Nekromanty i fioletowa wiązka;
##   przez DRAIN_TIME s co DRAIN_TICK s rani Nawią i leczy Nekromantę; wyjście poza koło przerywa wiązkę;
## - Przywołanie szkieletów: z ziemi wstaje SUMMON_COUNT szkieletów (co SUMMON_COOLDOWN s).
## Grafika: model SpriteKiln assets/spritekiln/necromancer/ (idle, walk, roar, bolts, ring, drain, summon, hit,
## death), do tego czasu powiększony goblin w kolorze Nawii. Efekty z kreatora PixelLab (16.11.2026): kule Nawii
## z dymiącym ogonem (`ProtoArrow.nawia`), kościane kolce (`bone_spikes`), drobinki płynące wiązką od postaci
## do Nekromanty (`nawia_drain` - kafelki wzdłuż kreski) i błysk leczenia (`nawia_heal`), krąg przywołania z czarnym
## płomieniem (`nawia_summon`) i dym Nawii za Nekromantą przez całą zapowiedź ataku (`nawia_aura`).

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
const RING_GAP := 3
const RING_RADIUS := 50.0
const RING_SPIKE := 13.0
const RING_WARN := 0.8
const RING_CENTER := 42.0
const RING_CENTER_WARN := 1.6
const RING_DAMAGE := 22
## Zasięg wiązki: promień koła wokół Nekromanty (spłaszczonego jak wszystkie koła na ziemi).
const DRAIN_RANGE := 110.0
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
const SPIKES_FX := preload("res://assets/effects/bone_spikes.png")
const SPIKES_FRAMES := 18
const SPIKES_ANCHOR := Vector2(51, 47)
## Promień koła, do którego pasują kolce w skali 1 (skala = promień koła / SPIKES_RADIUS).
const SPIKES_RADIUS := 24.0
const DRAIN_FX := preload("res://assets/effects/nawia_drain.png")
const DRAIN_FX_FRAMES := 12
const DRAIN_FX_SIZE := Vector2(48, 16)
const HEAL_FX := preload("res://assets/effects/nawia_heal.png")
const HEAL_ANCHOR := Vector2(11, 24)
const SUMMON_FX := preload("res://assets/effects/nawia_summon.png")
const SUMMON_FX_ANCHOR := Vector2(38, 64)
const AURA_FX := preload("res://assets/effects/nawia_aura.png")
const AURA_FRAMES := 16
const AURA_ANCHOR := Vector2(24, 45)
## Stany zapowiedzi ataku - wtedy za Nekromantą kłębi się dym Nawii.
const WARN_STATES: Array[String] = ["bolts", "ring", "drain", "summon"]
const ATTACKS: Array[String] = ["bolts", "ring", "drain"]

var _drops: Array[ProtoTelegraph] = []
var _beam: Line2D
## Drobinki płynące wiązką (kafelki DRAIN_FX wzdłuż kreski).
var _beam_fx: Node2D
var _aura: Sprite2D
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
	_update_aura()
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
	var near := in_drain_range(hero.global_position)
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "drain" or near))
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
		b.nawia = true
		b.element = Elements.NAWIA
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
		var a := away + TAU * (i + (0.5 if RING_GAP % 2 == 0 else 0.0)) / RING_COUNT  # luka symetryczna wokół `away`
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
		Fx.once(get_parent(), SPIKES_FX, SPIKES_FRAMES, 16.0, t.global_position, SPIKES_ANCHOR, 20, t.radius / SPIKES_RADIUS)
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
	var from := global_position + Vector2(0, -26)
	var to := hero.global_position + Vector2(0, -12)
	_beam.points = PackedVector2Array([from, to])
	_beam.width = 1.5 + 0.5 * sin(_timer * 30.0)
	_update_beam_fx(from, to)
	_drain_tick -= delta
	if _drain_tick <= 0.0:
		_drain_tick = DRAIN_TICK
		hero.take_damage(roundi(DRAIN_DAMAGE * power), Elements.NAWIA)
		hp = mini(hp + roundi(DRAIN_HEAL * power), max_hp)
		health_changed.emit(hp, max_hp)
		Fx.once(get_parent(), HEAL_FX, 10, 14.0, global_position + Vector2(randf_range(-7.0, 7.0), -18.0), HEAL_ANCHOR, 21)


## Drobinki wzdłuż wiązki: kafelki arkusza od Nekromanty do postaci (ostatni przycięty), płyną w stronę Nekromanty.
func _update_beam_fx(from: Vector2, to: Vector2) -> void:
	if _beam_fx == null:
		_beam_fx = Node2D.new()
		_beam_fx.z_index = 21
		get_parent().add_child(_beam_fx)
	_beam_fx.global_position = from
	_beam_fx.rotation = (to - from).angle()
	var length := from.distance_to(to)
	var count := ceili(length / DRAIN_FX_SIZE.x)
	var frame := int(_timer * 12.0) % DRAIN_FX_FRAMES
	while _beam_fx.get_child_count() < count:
		var tile := Sprite2D.new()
		tile.texture = DRAIN_FX
		tile.centered = false
		tile.region_enabled = true
		_beam_fx.add_child(tile)
	for i in _beam_fx.get_child_count():
		var tile := _beam_fx.get_child(i) as Sprite2D
		tile.visible = i < count
		var w := minf(DRAIN_FX_SIZE.x, length - i * DRAIN_FX_SIZE.x)
		tile.position = Vector2(i * DRAIN_FX_SIZE.x, -DRAIN_FX_SIZE.y / 2.0)
		tile.region_rect = Rect2(frame * DRAIN_FX_SIZE.x, 0, maxf(w, 1.0), DRAIN_FX_SIZE.y)


## Czy punkt leży w kole wyssania (koło spłaszczone jak ostrzeżenia na ziemi).
func in_drain_range(point: Vector2) -> bool:
	var d := point - global_position
	return Vector2(d.x, d.y / ProtoTelegraph.SQUASH).length() <= DRAIN_RANGE


## Czy wiązka właśnie wysysa (testy).
func draining() -> bool:
	return _beam != null


func _end_drain() -> void:
	_clear_beam()
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
		Fx.once(get_parent(), SUMMON_FX, 12, 12.0, p, SUMMON_FX_ANCHOR, 6, 0.6)
	_sound(ROAR_SOUND, -6.0, randf_range(0.6, 0.7))


## Dym Nawii: jest, póki Nekromanta zapowiada atak albo wysysa (WARN_STATES).
func _update_aura() -> void:
	var warn := state in WARN_STATES
	if warn and _aura == null:
		_aura = Fx.loop(self, AURA_FX, AURA_FRAMES, 12.0, Vector2.ZERO, AURA_ANCHOR, -1)
	elif not warn and _aura:
		_aura.queue_free()
		_aura = null


## Czy dym Nawii kłębi się za Nekromantą (testy).
func aura_active() -> bool:
	return _aura != null


func _clear_beam() -> void:
	if _beam and is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null
	if _beam_fx and is_instance_valid(_beam_fx):
		_beam_fx.queue_free()
	_beam_fx = null


func _die() -> void:
	_clear_beam()
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
	if _beam_fx and is_instance_valid(_beam_fx):
		_beam_fx.queue_free()

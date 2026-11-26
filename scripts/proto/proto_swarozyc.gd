class_name ProtoSwarozyc
extends ProtoChief
## Swarożyc-strażnik - boss Świątyni Słońca (Dungeons.TEMPLE, ustalone z autorem 26.11.2026; nawiązanie do pomysłu
## autora z aniołami): ogromny świetlisty wojownik, syn Swaroga, który oszalał od światła - złota zbroja, aureola
## słońca, długa włócznia. Reszta (wejście, pasek zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief).
## Ataki z ostrzeżeniem na ziemi (liczby - propozycje Claude):
## - Wypad włócznią (`lunge`): pas do postaci (LUNGE_LENGTH x LUNGE_WIDTH), po LUNGE_WARN s Swarożyc przelatuje wzdłuż
##   pasa z włócznią - w pasie rani Prawią i oślepia (ProtoHero.blind);
## - Promienie z nieba (`beams`): BEAMS kół wokół postaci (pierwsze pod nią), po kolei z nieba bije promień (sky_beam
##   włóczni) - rani w kole;
## - Przywołanie (`summon`, co najwyżej co SUMMON_EVERY s): aureola rozbłyska, obok wyrastają mniejsi Swarożyce
##   (ProtoSwarozycMinion - `minion_kind`), poniżej połowy zdrowia - więcej.
## Grafika: model SpriteKiln assets/spritekiln/swarozyc/ (idle, walk, attack, lunge, beams, summon, hit, death), do czasu
## grafiki - powiększony goblin w kolorze złota.

const SWAROZYC_SCENE := "res://assets/spritekiln/swarozyc/swarozyc.tscn"
const SWAROZYC_HP := 1350
const KEEP_DISTANCE := 60.0
const ATTACK_RANGE := 160.0
const LUNGE_LENGTH := 170.0
const LUNGE_WIDTH := 26.0
const LUNGE_WARN := 1.0
const LUNGE_DASH := 0.16
const LUNGE_DAMAGE := 30
const LUNGE_BLIND := 1.5
const BEAMS := 5
const BEAMS_RAGE := 7
const BEAM_RADIUS := 20.0
const BEAM_SPREAD := 80.0
const BEAM_WARN := 1.0
const BEAM_STEP := 0.16
const BEAM_DAMAGE := 22
const SUMMON_EVERY := 14.0
const SUMMON_COUNT := 2
const SUMMON_COUNT_RAGE := 3
const SUMMON_RING := 42.0
const SUMMON_TIME := 1.0
const RAGE_AT := 0.5
const BEAM_FX := preload("res://assets/effects/sky_beam.png")
const BEAM_FX_FRAMES := 14
const BEAM_FX_ANCHOR := Vector2(36, 106)
## Promień uderza w 3. klatce efektu - tyle przed wypełnieniem koła rusza efekt.
const BEAM_LEAD := 2.0 / 14.0
const RING_FX := preload("res://assets/effects/sun_ring.png")
const THRUST_FX := preload("res://assets/effects/spear_thrust.png")
const ATTACKS: Array[String] = ["lunge", "beams"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var _last_attack := ""
var _summon_ready := 6.0
var _beams: Array[ProtoTelegraph] = []
var _lunge_from := Vector2.ZERO
var _lunge_to := Vector2.ZERO
var _lunge_hit := false
## Czy w tym przywołaniu słudzy już wyrośli.
var _summoned := false
## Ile razy wypad i promienie trafiły postać (testy).
var lunge_hits := 0
var beam_hits := 0


func _init() -> void:
	scene_path = SWAROZYC_SCENE
	base_hp = SWAROZYC_HP
	fallback_tint = Color(1.0, 0.88, 0.5)
	keep_distance = KEEP_DISTANCE
	minion_kind = "swarozyc"
	anim_hit_at = {&"lunge": 0.95, &"beams": 0.6, &"summon": 0.6}
	anim_fallback = {&"lunge": &"attack", &"beams": &"attack", &"summon": &"attack", &"roar": &"summon",
		&"slam": &"attack", &"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_update_beams()
	if state == "dead" or hero == null:
		return
	_summon_ready -= delta
	match state:
		"lunge":
			_sync_anim(&"lunge", LUNGE_WARN)
			if _timer >= LUNGE_WARN:
				_remove_telegraph()
				_set_state("lunge_dash")
				_lunge_hit = false
				var fx := Fx.once(get_parent(), THRUST_FX, 7, 24.0, (_lunge_from + Vector2(0, -18)).round(), Vector2(5, 7), 21)
				fx.rotation = (_lunge_to - _lunge_from).angle()
				fx.scale = Vector2(_lunge_from.distance_to(_lunge_to) / 60.0, 1.6)
		"lunge_dash":
			var k := clampf(_timer / LUNGE_DASH, 0.0, 1.0)
			global_position = _lunge_from.lerp(_lunge_to, k)
			if not _lunge_hit and hero and not hero.dead and _on_lunge(hero.global_position):
				_lunge_hit = true
				lunge_hits += 1
				hit_hero(hero, roundi(LUNGE_DAMAGE * power), Elements.PRAWIA)
				hero.blind(LUNGE_BLIND)
			if k >= 1.0:
				_shake(3.0, 0.25)
				_set_state("recover")
		"beams":
			_sync_anim(&"beams", BEAM_WARN * 0.6)
			if _timer >= BEAM_WARN:
				_set_state("recover")
		"summon":
			_sync_anim(&"summon", SUMMON_TIME * 0.6)
			if _timer >= SUMMON_TIME * 0.6 and not _summoned:
				_summon_guards()
			if _timer >= SUMMON_TIME:
				_set_state("recover")


func _choose_attack(distance: float) -> void:
	if passive:
		_cooldown = 0.4
		return
	if _summon_ready <= 0.0:
		start_attack("summon")
		return
	if distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack)
	start_attack(pool.pick_random())


func _rage() -> bool:
	return health_fraction() <= RAGE_AT


## Zaczyna atak `kind` (lunge, beams, summon) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to := hero.global_position - global_position
	_face(to)
	_play(&"idle")
	match kind:
		"lunge":
			_set_state("lunge")
			_lunge_from = global_position
			var dir := to.normalized() if to.length() > 1.0 else Vector2.DOWN
			_lunge_to = (_lunge_from + dir * LUNGE_LENGTH).clamp(bounds.position, bounds.end)
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.length = _lunge_from.distance_to(_lunge_to)
			_telegraph.width = LUNGE_WIDTH
			_telegraph.angle = dir.angle()
			_telegraph.duration = LUNGE_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = _lunge_from
		"beams":
			_set_state("beams")
			for i in (BEAMS_RAGE if _rage() else BEAMS):
				var at := hero.global_position
				if i > 0:
					at += Vector2.from_angle(randf() * TAU) * randf_range(BEAM_RADIUS * 1.6, BEAM_SPREAD) * Vector2(1, 0.7)
				var t := ProtoTelegraph.new()
				t.radius = BEAM_RADIUS
				t.duration = BEAM_WARN + BEAM_STEP * i
				get_parent().add_child(t)
				t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)
				_beams.append(t)
		"summon":
			_set_state("summon")
			_summon_ready = SUMMON_EVERY
			_summoned = false
			_sound(ROAR_SOUND, -4.0, 1.3)


## Aureola rozbłyska i obok wyrastają mniejsi Swarożyce (arena - ProtoHorde.spawn_at z `minion_kind`).
func _summon_guards() -> void:
	_summoned = true
	var points: Array = []
	var n := SUMMON_COUNT_RAGE if _rage() else SUMMON_COUNT
	var start := randf() * TAU
	for i in n:
		points.append((global_position + Vector2.from_angle(start + TAU * i / n) * SUMMON_RING * Vector2(1, 0.7))
				.clamp(bounds.position, bounds.end))
	var fx := Fx.once(get_parent(), RING_FX, 8, 14.0, global_position.round(), Vector2(58, 25), 2, 1.0)
	fx.modulate.a = 0.8
	for p in points:
		Fx.once(get_parent(), BEAM_FX, BEAM_FX_FRAMES, 18.0, (p as Vector2).round(), BEAM_FX_ANCHOR, 3, 0.5)
	summon_minions.emit(points)


## Czy punkt `p` (stopy postaci) leży na pasie wypadu, który Swarożyc już przebiegł.
func _on_lunge(p: Vector2) -> bool:
	var q := Geometry2D.get_closest_point_to_segment(p, _lunge_from, global_position)
	return q.distance_to(p) <= LUNGE_WIDTH * 0.5 + 4.0


## Promień z nieba bije tam, gdzie koło się wypełniło.
func _update_beams() -> void:
	for i in range(_beams.size() - 1, -1, -1):
		var t := _beams[i]
		if not is_instance_valid(t):
			_beams.remove_at(i)
			continue
		if not t.has_meta("beam") and (1.0 - t.progress) * t.duration <= BEAM_LEAD:
			t.set_meta("beam", true)
			Fx.once(get_parent(), BEAM_FX, BEAM_FX_FRAMES, 14.0, t.global_position.round(), BEAM_FX_ANCHOR, 3,
					BEAM_RADIUS / 33.0)
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			beam_hits += 1
			hit_hero(hero, roundi(BEAM_DAMAGE * power), Elements.PRAWIA)
		t.queue_free()
		_beams.remove_at(i)


## Ile promieni jeszcze czeka (testy).
func beams_pending() -> int:
	return _beams.size()


func _die() -> void:
	for t in _beams:
		if is_instance_valid(t):
			t.queue_free()
	_beams.clear()
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	for t in _beams:
		if is_instance_valid(t):
			t.queue_free()

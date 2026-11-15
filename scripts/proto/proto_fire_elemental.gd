class_name ProtoFireElemental
extends ProtoChief
## Żywiołak ognia - boss Wulkanicznych równin (Dungeons.VOLCANO, ataki wybrane przez autora 15.11.2026). Reszta (wejście,
## pasek zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem na ziemi:
## - Fala ognia: czerwony pierścień wokół Żywiołaka (WAVE_INNER-WAVE_RADIUS, ProtoTelegraph.inner) - po WAVE_WARN s
##   wybucha ogniem; bezpiecznie tuż przy nim albo daleko;
## - Deszcz lawy: RAIN_DROPS małych kół wokół postaci (pierwsze pod nią), spadają po kolei, rania i zostawiają na
##   chwilę płonącą ziemię (ProtoFirePatch);
## - Ognisty taran: czerwony pas do postaci (CHARGE_LENGTH x CHARGE_WIDTH), po CHARGE_WARN s szarżuje nim (CHARGE_TIME s),
##   rani przy przelocie i zostawia za sobą ślad płonącej ziemi.
## Ogień podpala (ProtoHero.ignite). Grafika: model SpriteKiln assets/spritekiln/fire_elemental/ (idle, walk, roar,
## wave, rain, charge, hit, death), do tego czasu powiększony goblin w kolorze ognia.

const ELEMENTAL_SCENE := "res://assets/spritekiln/fire_elemental/fire_elemental.tscn"
const ELEMENTAL_HP := 1100
const KEEP_DISTANCE := 70.0
const ATTACK_RANGE := 140.0
const WAVE_INNER := 26.0
const WAVE_RADIUS := 100.0
const WAVE_WARN := 1.2
const WAVE_DAMAGE := 26
const RAIN_DROPS := 7
const RAIN_RADIUS := 15.0
const RAIN_SPREAD := 70.0
const RAIN_WARN := 1.0
const RAIN_STEP := 0.15
const RAIN_DAMAGE := 18
const RAIN_PATCH := 2.5
const CHARGE_LENGTH := 220.0
const CHARGE_WIDTH := 30.0
const CHARGE_WARN := 0.9
const CHARGE_TIME := 0.4
const CHARGE_DAMAGE := 28
const CHARGE_TRAIL := 3.0
const BURN := 4
const BURN_TIME := 3.0
const FIRE_FX := preload("res://assets/effects/glaive_blast.png")
const FIRE_FX_FRAMES := 12
const FIRE_FX_ANCHOR := Vector2(35, 35)
const ATTACKS: Array[String] = ["wave", "rain", "charge"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var _last_attack := ""
var _drops: Array[ProtoTelegraph] = []
var _charge_from := Vector2.ZERO
var _charge_to := Vector2.ZERO
var _charge_hit := false
var _trail_next := 0.0


func _init() -> void:
	scene_path = ELEMENTAL_SCENE
	base_hp = ELEMENTAL_HP
	fallback_tint = Color(1.0, 0.55, 0.25)
	keep_distance = KEEP_DISTANCE
	anim_hit_at = {&"wave": 0.33, &"rain": 0.34, &"charge": 0.3}
	anim_fallback = {&"wave": &"attack", &"rain": &"attack", &"charge": &"attack", &"roar": &"idle",
		&"slam": &"attack", &"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_update_drops()
	if state == "dead" or hero == null:
		return
	match state:
		"wave":
			_sync_anim(&"wave", WAVE_WARN)
			if _timer >= WAVE_WARN:
				_wave_hit()
		"rain":
			_sync_anim(&"rain", RAIN_WARN)
			if _timer >= RAIN_WARN:
				_set_state("recover")
		"charge_warn":
			_sync_anim(&"charge", CHARGE_WARN)
			if _timer >= CHARGE_WARN:
				_set_state("charge")
				_charge_hit = false
				_trail_next = 0.0
		"charge":
			var k := clampf(_timer / CHARGE_TIME, 0.0, 1.0)
			position = _charge_from.lerp(_charge_to, k)
			_trail_next -= delta
			if _trail_next <= 0.0:
				_trail_next = CHARGE_TIME / 6.0
				ProtoFirePatch.spawn(get_parent(), global_position, hero, 14.0, CHARGE_TRAIL, roundi(BURN * power))
			if not _charge_hit and hero and not hero.dead and global_position.distance_to(hero.global_position) < 20.0:
				_charge_hit = true
				hero.take_damage(roundi(CHARGE_DAMAGE * power), Elements.FIRE)
				hero.ignite(roundi(BURN * power), BURN_TIME)
			if k >= 1.0:
				_remove_telegraph()
				_set_state("recover")


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack)
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (wave, rain, charge) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	_face(hero.global_position - global_position)
	_play(&"idle")
	match kind:
		"wave":
			_set_state("wave")
			_telegraph = _make_telegraph(global_position, WAVE_RADIUS, WAVE_WARN)
			_telegraph.inner = WAVE_INNER
		"rain":
			_set_state("rain")
			for i in RAIN_DROPS:
				var at := hero.global_position
				if i > 0:
					at += Vector2.from_angle(randf() * TAU) * randf_range(RAIN_RADIUS * 1.6, RAIN_SPREAD) * Vector2(1, 0.7)
				var t := ProtoTelegraph.new()
				t.radius = RAIN_RADIUS
				t.duration = RAIN_WARN + RAIN_STEP * i
				get_parent().add_child(t)
				t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)
				_drops.append(t)
		"charge":
			_set_state("charge_warn")
			_charge_from = global_position
			var dir := (hero.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.DOWN
			_charge_to = (_charge_from + dir * CHARGE_LENGTH).clamp(bounds.position, bounds.end)
			_remove_telegraph()
			_telegraph = ProtoTelegraph.new()
			_telegraph.length = _charge_from.distance_to(_charge_to)
			_telegraph.width = CHARGE_WIDTH
			_telegraph.angle = (_charge_to - _charge_from).angle()
			_telegraph.duration = CHARGE_WARN
			get_parent().add_child(_telegraph)
			_telegraph.global_position = _charge_from


## Fala ognia: rani w pierścieniu, wybuch ognia wokół.
func _wave_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hero.take_damage(roundi(WAVE_DAMAGE * power), Elements.FIRE)
		hero.ignite(roundi(BURN * power), BURN_TIME)
	_remove_telegraph()
	for i in 10:
		var p := global_position + Vector2.from_angle(TAU * i / 10.0) * (WAVE_INNER + WAVE_RADIUS) / 2.0 * Vector2(1, 0.6)
		Fx.once(get_parent(), FIRE_FX, FIRE_FX_FRAMES, 18.0, p, FIRE_FX_ANCHOR, 20, 0.5)
	_shake(4.0, 0.3)
	_sound(SLAM_SOUND, -2.0, randf_range(0.9, 1.0))
	_set_state("recover")


## Lawa spada tam, gdzie koło się wypełniło: rani, zostawia płonącą ziemię.
func _update_drops() -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var t := _drops[i]
		if not is_instance_valid(t):
			_drops.remove_at(i)
			continue
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hero.take_damage(roundi(RAIN_DAMAGE * power), Elements.FIRE)
			hero.ignite(roundi(BURN * power), BURN_TIME)
		Fx.once(get_parent(), FIRE_FX, FIRE_FX_FRAMES, 18.0, t.global_position, FIRE_FX_ANCHOR, 20, 0.45)
		ProtoFirePatch.spawn(get_parent(), t.global_position, hero, RAIN_RADIUS, RAIN_PATCH, roundi(BURN * power))
		t.queue_free()
		_drops.remove_at(i)


## Ile kul lawy jeszcze spada (testy).
func rain_pending() -> int:
	return _drops.size()


func _die() -> void:
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

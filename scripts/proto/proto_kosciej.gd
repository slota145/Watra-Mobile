class_name ProtoKosciej
extends ProtoChief
## Kościej Nieśmiertelny - boss Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): wychudły czarnoksiężnik
## w koronie i czarnym płaszczu, którego śmierć ukryta jest w igle w jajku. Reszta (wejście, pasek zdrowia, trafienia,
## skrzynia) jak u Wodza (ProtoChief). Liczby - propozycje Claude.
## **Jajo** (ProtoKosciejEgg): przy wejściu Kościeja na postumencie po drugiej stronie postaci pojawia się jajo
## w świetlistej kapsule, połączone z nim nicią magii. Dopóki jajo jest całe, Kościej po spadku zdrowia do zera nie
## ginie (nie wysyła `died`), tylko się odradza (`revive`, REVIVE_TIME s nietykalny) z REVIVE_SHARE zdrowia. Po
## zniszczeniu jaja (cel dla broni, EGG_SHARE zdrowia bossa) chwieje się i można go pokonać.
## Ataki z ostrzeżeniem na ziemi:
## - Pieczęcie (`cast`): po zamachu (CAST_TIME) wokół postaci zapalają się czerwone koła z pieczęcią (pierwsze pod nią),
##   po kolei wybuchają Arkanami (SEALS, w gniewie - poniżej połowy zdrowia - SEALS_RAGE);
## - Pocisk (`bolt`): wachlarz BOLTS pocisków Arkanów (ProtoArrow `arcane`; w gniewie BOLTS_RAGE) w stronę postaci;
## - Teleport (`teleport`): znika w błysku, przy postaci pojawia się koło (TELE_WARN s) - tam wyłania się z wybuchem.
## Grafika: model SpriteKiln assets/spritekiln/kosciej/ (idle, walk, attack, cast, bolt, teleport, revive, hit, death),
## do czasu grafiki - powiększony goblin w zastępczym kolorze.

const BOSS_SCENE := "res://assets/spritekiln/kosciej/kosciej.tscn"
const BOSS_HP := 1450
const KEEP_DISTANCE := 70.0
const ATTACK_RANGE := 170.0
const RAGE_AT := 0.5
## Jajo: ułamek zdrowia bossa, odległość od postaci (po drugiej stronie niż boss).
const EGG_SHARE := 0.22
const EGG_DISTANCE := 100.0
## Odrodzenie: czas (nietykalny) i ułamek zdrowia po nim.
const REVIVE_TIME := 1.2
const REVIVE_SHARE := 0.4
## Po zniszczeniu jaja chwieje się tyle sekund (bez ataków).
const STAGGER := 1.2
const CAST_TIME := 0.6
const SEALS := 4
const SEALS_RAGE := 6
const SEAL_RADIUS := 22.0
const SEAL_SPREAD := 85.0
const SEAL_WARN := 1.0
const SEAL_STEP := 0.15
const SEAL_DAMAGE := 24
const BOLT_TIME := 0.5
const BOLTS := 3
const BOLTS_RAGE := 5
const BOLT_ANGLE := deg_to_rad(16.0)
const BOLT_SPEED := 140.0
const BOLT_RANGE := 300.0
const BOLT_DAMAGE := 18
const TELE_OUT := 0.4
const TELE_WARN := 0.9
const TELE_DISTANCE := 18.0
const TELE_RADIUS := 40.0
const TELE_DAMAGE := 26
const SEAL_FX := preload("res://assets/effects/arcane_seal.png")
const BLAST_FX := preload("res://assets/effects/arcane_blast.png")
const WAVE_FX := preload("res://assets/effects/arcane_wave.png")
const CIRCLE_FX := preload("res://assets/effects/arcane_circle.png")
const RED_TINT := Color(1.0, 0.5, 0.45)
const ATTACKS: Array[String] = ["cast", "bolt", "teleport"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
var egg: ProtoKosciejEgg
var egg_broken := false
## Ile razy się odrodził, ile razy pieczęcie, pociski i wyłonienie z teleportu trafiły postać (testy).
var revives := 0
var seal_hits := 0
var tele_hits := 0
var _last_attack := ""
var _seals: Array[ProtoTelegraph] = []
var _cast_done := false
var _tele_to := Vector2.ZERO


func _init() -> void:
	scene_path = BOSS_SCENE
	base_hp = BOSS_HP
	fallback_tint = Color(0.75, 0.55, 1.0)
	keep_distance = KEEP_DISTANCE
	anim_hit_at = {&"cast": 0.6, &"bolt": 0.5, &"teleport": 0.4}
	anim_fallback = {&"cast": &"attack", &"bolt": &"attack", &"teleport": &"idle", &"revive": &"idle",
		&"roar": &"cast", &"slam": &"attack", &"throw": &"attack"}


func _ready() -> void:
	super()
	_spawn_egg.call_deferred()


## Jajo na postumencie po drugiej stronie postaci niż Kościej (żeby trzeba było się od niego oderwać).
func _spawn_egg() -> void:
	if get_parent() == null or egg != null:
		return
	var from := hero.global_position if hero else global_position + Vector2(0, 80)
	var dir := from - global_position
	dir = dir.normalized() if dir.length() > 1.0 else Vector2.DOWN
	var at := from + dir.rotated(randf_range(-0.6, 0.6)) * EGG_DISTANCE
	at = ProtoDecor.push_out(at.clamp(bounds.position + Vector2(20, 30), bounds.end - Vector2(20, 10)), 12.0)
	place_egg(at)


## Stawia jajo w punkcie `at` (też do testów i zrzutów - przestawia istniejące).
func place_egg(at: Vector2) -> void:
	if egg == null:
		egg = ProtoKosciejEgg.new()
		egg.name = "KosciejEgg"
		egg.boss = self
		egg.max_hp = maxi(1, roundi(max_hp * EGG_SHARE))
		egg.resists = resists
		egg.broken.connect(_on_egg_broken)
		get_parent().add_child(egg)
	egg.global_position = at


func _process(delta: float) -> void:
	super(delta)
	_update_seals()
	if state == "dead" or hero == null:
		return
	match state:
		"cast":
			_sync_anim(&"cast", CAST_TIME)
			if not _cast_done and _timer >= CAST_TIME:
				_cast_seals()
			if _timer >= CAST_TIME + 0.3:
				_set_state("recover")
		"bolt":
			_sync_anim(&"bolt", BOLT_TIME)
			if _timer >= BOLT_TIME:
				_shoot_bolts()
				_set_state("recover")
		"teleport":
			_sync_anim(&"teleport", TELE_OUT)
			if _timer >= TELE_OUT:
				_vanish_to()
		"teleport_in":
			if _timer >= TELE_WARN:
				_emerge()
		"revive":
			if _timer >= REVIVE_TIME:
				_revived()
		"stagger":
			if _timer >= STAGGER:
				_set_state("walk")


func _choose_attack(distance: float) -> void:
	if passive:
		_cooldown = 0.4
		return
	if distance > ATTACK_RANGE:
		start_attack("teleport" if _last_attack != "teleport" else "bolt")
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack)
	start_attack(pool.pick_random())


func _rage() -> bool:
	return health_fraction() <= RAGE_AT


## Zaczyna atak `kind` (cast, bolt, teleport) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	_face(hero.global_position - global_position)
	_play(&"idle")
	match kind:
		"cast":
			_set_state("cast")
			_cast_done = false
			var fx := Fx.once(get_parent(), CIRCLE_FX, 12, 18.0, global_position.round(), Vector2(55, 23), -1, 0.6)
			fx.modulate = RED_TINT
		"bolt":
			_set_state("bolt")
		"teleport":
			_set_state("teleport")


## Pieczęcie wokół postaci: czerwone koła z wirującą pieczęcią, wybuchają po kolei.
func _cast_seals() -> void:
	_cast_done = true
	for i in (SEALS_RAGE if _rage() else SEALS):
		var at := hero.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(SEAL_RADIUS * 1.5, SEAL_SPREAD) * Vector2(1, 0.7)
		var t := ProtoTelegraph.new()
		t.radius = SEAL_RADIUS
		t.duration = SEAL_WARN + SEAL_STEP * i
		get_parent().add_child(t)
		t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)
		var seal := Fx.loop(t, SEAL_FX, 10, 12.0, Vector2.ZERO, Vector2(27, 15), 1, SEAL_RADIUS / 27.0)
		seal.scale.y /= ProtoTelegraph.SQUASH  # koło zapowiedzi jest spłaszczone - pieczęć już jest płaska
		seal.modulate = RED_TINT
		_seals.append(t)


## Pieczęć wybucha tam, gdzie koło się wypełniło.
func _update_seals() -> void:
	for i in range(_seals.size() - 1, -1, -1):
		var t := _seals[i]
		if not is_instance_valid(t):
			_seals.remove_at(i)
			continue
		if t.progress < 1.0:
			continue
		var fx := Fx.once(get_parent(), BLAST_FX, 9, 18.0, t.global_position.round(), Vector2(36, 20), 2, SEAL_RADIUS / 30.0)
		fx.modulate = RED_TINT
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			seal_hits += 1
			hit_hero(hero, roundi(SEAL_DAMAGE * power), Elements.ARCANE)
		t.queue_free()
		_seals.remove_at(i)


## Wachlarz pocisków Arkanów w stronę postaci.
func _shoot_bolts() -> void:
	var to := hero.global_position - global_position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.DOWN
	var n := BOLTS_RAGE if _rage() else BOLTS
	for i in n:
		var b := ProtoArrow.new()
		b.hero = hero
		b.arcane = true
		b.speed = BOLT_SPEED
		b.fly_range = BOLT_RANGE
		b.direction = dir.rotated((i - (n - 1) / 2.0) * BOLT_ANGLE)
		b.damage = roundi(BOLT_DAMAGE * power)
		b.scale = Vector2.ONE * 1.3
		b.position = position + b.direction * 10.0
		get_parent().add_child(b)


## Znika w błysku; przy postaci zapala się koło - tam się wyłoni.
func _vanish_to() -> void:
	var fx := Fx.once(get_parent(), BLAST_FX, 9, 18.0, global_position.round(), Vector2(36, 20), 2, 1.0)
	fx.modulate = Color(0.85, 0.7, 1.0)
	_tele_to = (hero.global_position + Vector2.from_angle(randf() * TAU) * TELE_DISTANCE * Vector2(1, 0.7)).clamp(
			bounds.position, bounds.end)
	_telegraph = _make_telegraph(_tele_to, TELE_RADIUS, TELE_WARN)
	remove_from_group(ProtoWeapon.TARGETS)  # niewidzialny - broń go nie widzi
	create_tween().tween_property(self, "modulate:a", 0.0, 0.12)
	_set_state("teleport_in")


## Wyłania się w kole z wybuchem magii.
func _emerge() -> void:
	global_position = _tele_to
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		tele_hits += 1
		hit_hero(hero, roundi(TELE_DAMAGE * power), Elements.ARCANE)
	_remove_telegraph()
	add_to_group(ProtoWeapon.TARGETS)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)
	Fx.once(get_parent(), WAVE_FX, 9, 18.0, global_position.round(), Vector2(64, 34), -1, TELE_RADIUS / 60.0)
	_shake(3.0, 0.2)
	_set_state("recover")


## Nietykalny w czasie odradzania i w czasie teleportu.
func take_damage(amount: int, from: Vector2) -> void:
	if state == "revive" or state == "teleport_in":
		return
	super(amount, from)


## Dopóki jajo jest całe, Kościej nie da się dobić (Egzekucja, Hak Kata).
func remaining_hp() -> int:
	return super() if egg_broken else 0


## Zdrowie spadło do zera: z całym jajem - odrodzenie (bez sygnału `died`), bez jaja - śmierć.
func _die() -> void:
	_cancel_attack()
	if not egg_broken:
		_revive()
		return
	if egg and is_instance_valid(egg):
		egg.queue_free()
	super()


## Odrodzenie: pada na chwilę, jajo oddaje mu życie (nić rozbłyska), wstaje z REVIVE_SHARE zdrowia.
func _revive() -> void:
	_set_state("revive")
	_play(&"revive", true)
	_sound(ROAR_SOUND, -3.0, 0.6)
	if egg and is_instance_valid(egg):
		egg.pulse()
	var fx := Fx.once(get_parent(), CIRCLE_FX, 12, 12.0, global_position.round(), Vector2(55, 23), -1, 0.8)
	fx.modulate = Color(0.8, 0.6, 1.0)
	var tween := create_tween()
	tween.tween_property(_sprite, "self_modulate", Color(0.35, 0.25, 0.5), 0.3)
	tween.tween_property(_sprite, "self_modulate", fallback_tint if not ResourceLoader.exists(scene_path) else Color.WHITE,
			REVIVE_TIME - 0.3)
	_announce(tr("Kościej się odradza! Zniszcz jajo!"))


func _revived() -> void:
	revives += 1
	hp = maxi(1, roundi(max_hp * REVIVE_SHARE))
	health_changed.emit(hp, max_hp)
	Fx.once(get_parent(), WAVE_FX, 9, 18.0, global_position.round(), Vector2(64, 34), -1, 0.5)
	_set_state("recover")


## Jajo rozbite: Kościej chwieje się i od teraz można go pokonać.
func _on_egg_broken() -> void:
	egg_broken = true
	_announce(tr("Igła złamana! Kościej jest śmiertelny!"))
	if state == "dead" or state == "revive":
		return
	if state == "teleport_in":
		_emerge()
	_cancel_attack()
	_set_state("stagger")
	_play(&"hit", true)
	_shake(4.0, 0.3)
	_sound(ROAR_SOUND, -2.0, 0.75)


## Przerywa trwający atak: koła i pieczęcie znikają (teleport - zostaje tam, gdzie był).
func _cancel_attack() -> void:
	_remove_telegraph()
	for t in _seals:
		if is_instance_valid(t):
			t.queue_free()
	_seals.clear()
	if not is_in_group(ProtoWeapon.TARGETS) and state != "dead":
		add_to_group(ProtoWeapon.TARGETS)
		modulate.a = 1.0


## Ile pieczęci jeszcze czeka na wybuch (testy).
func seals_pending() -> int:
	return _seals.size()


## Napis na środku ekranu (ProtoArena.announce), jeśli boss stoi na arenie.
func _announce(text: String) -> void:
	var n := get_parent()
	while n and not n.has_method("announce"):
		n = n.get_parent()
	if n:
		n.announce(text, Elements.color_of(Elements.ARCANE))


func _exit_tree() -> void:
	_remove_telegraph()
	for t in _seals:
		if is_instance_valid(t):
			t.queue_free()
	if egg and is_instance_valid(egg) and not egg.is_queued_for_deletion():
		egg.queue_free()

class_name ProtoChief
extends ProtoTarget
## Wódz Goblinów - boss lochu, przyzywany za pełny pasek żaru. Wchodzi z rykiem i trzęsieniem ekranu, idzie powoli
## do Wojciecha i na zmianę używa trzech ataków, każdego z czytelnym ostrzeżeniem (czerwone koło na ziemi):
## - cios w ziemię: koło wokół Wodza wypełnia się przez SLAM_WARN s, potem uderzenie - trzeba wyjść z koła;
## - rzut tasakiem: koło pod Wojciechem (miejsce z chwili rzutu), tasak leci łukiem i spada, kiedy koło się wypełni,
##   potem wraca do Wodza jak bumerang (po drodze też rani);
## - okrzyk wojenny: pomarańczowe fale wokół Wodza, po chwili wokół niego pojawiają się zwykłe gobliny.
## Nie przerywa ataków od trafień (boss), tylko błyska. Siła rośnie z poziomem lochu (`power`).
## Grafika: model SpriteKiln assets/spritekiln/goblin_chief/ (gdy jest), a do tego czasu powiększony goblin.

signal died(chief: ProtoChief)
signal health_changed(hp: int, max_hp: int)
## Okrzyk wojenny: arena dokłada goblinów w tych miejscach (przez ProtoHorde.spawn_at).
signal summon_minions(points: Array)

const SCENE_PATH := "res://assets/spritekiln/goblin_chief/goblin_chief.tscn"
const FALLBACK_PATH := "res://assets/spritekiln/goblin/goblin.tscn"
## Zastępczy goblin jest tyle razy większy (do czasu eksportu modelu Wodza).
const FALLBACK_SCALE := 1.6
const MAX_HP := 700
## Wojciech: 70, goblin: 42 - Wódz jest wolny, przed ciosami da się uciec.
const SPEED := 30.0
## Wejście: tyle sekund ryku, zanim zacznie walczyć.
const ENTER_TIME := 1.4
## Przerwa między atakami.
const ATTACK_GAP := 1.1
## Cios w ziemię: promień koła, czas ostrzeżenia, obrażenia, z jakiej odległości Wódz go używa.
const SLAM_RADIUS := 46.0
const SLAM_WARN := 1.1
const SLAM_DAMAGE := 25
const SLAM_RANGE := 34.0
## Rzut tasakiem: promień koła, czas od rzutu do upadku, obrażenia przy upadku i na powrocie (trafia raz).
const THROW_RADIUS := 20.0
const THROW_WARN := 1.0
const THROW_DAMAGE := 20
const RETURN_DAMAGE := 10
const RETURN_TIME := 0.6
const RETURN_HIT := 12.0
## Okrzyk: ile goblinów, w jakiej odległości, po jakim czasie, co ile sekund najwyżej.
const ROAR_MINIONS := 5
const ROAR_RING := 44.0
const ROAR_TIME := 0.9
const ROAR_COOLDOWN := 9.0
## Po ataku Wódz stoi jeszcze tyle sekund (okno na kontrę).
const RECOVER := 0.6
## W którym momencie animacji pada cios (s od startu) - animacja startuje tak, żeby cios zgrał się z końcem
## ostrzeżenia. Zastępczy goblin: `attack` z ciosem po 0,3 s.
const ANIM_HIT_AT := {&"slam": 0.3, &"throw": 0.3}
## Zastępcze animacje, dopóki model Wodza ich nie ma.
const ANIM_FALLBACK := {&"slam": &"attack", &"throw": &"attack", &"roar": &"idle"}
const ROAR_SOUND := preload("res://assets/watra/chief_roar.ogg")
const SLAM_SOUND := preload("res://assets/watra/chief_slam.ogg")
const LAND_SOUND := preload("res://assets/watra/cleaver_land.ogg")
const HIT_SOUNDS := ProtoGoblin.HIT_SOUNDS
const CORPSE_TIME := 1.0

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
var max_hp := MAX_HP
var hp := MAX_HP

## enter, walk, slam, throw, roar, recover, dead
var state := "enter"
var _timer := 0.0
var _cooldown := 0.0
var _roar_cooldown := 3.0
var _anim_started := false
var _telegraph: ProtoTelegraph
var _cleaver: Node2D
var _cleaver_from := Vector2.ZERO
var _cleaver_to := Vector2.ZERO
var _cleaver_hit := false
var _roar_fx: Node2D
var _sprite  # KilnSprite2D
var _audio: AudioStreamPlayer2D
var _anims: Array = []


func _ready() -> void:
	center_height = 22.0
	max_hp = roundi(MAX_HP * power)
	hp = max_hp
	add_to_group(ProtoWeapon.TARGETS)
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(1.5, 1.4)
	add_child(shadow)
	var own := ResourceLoader.exists(SCENE_PATH)
	_sprite = (load(SCENE_PATH if own else FALLBACK_PATH) as PackedScene).instantiate()
	if not own:
		_sprite.scale = Vector2.ONE * FALLBACK_SCALE
		_sprite.self_modulate = Color(1.0, 0.72, 0.62)  # czerwonawy, żeby odróżniał się od zwykłych goblinów
	add_child(_sprite)
	_anims = _sprite.anim_names()
	_sprite.anim_finished.connect(_on_anim_finished)
	_audio = AudioStreamPlayer2D.new()
	_audio.max_distance = 2000.0
	add_child(_audio)
	_enter()


func alive() -> bool:
	return state != "dead"


## Wejście: spada z góry, ryk, wstrząs ekranu.
func _enter() -> void:
	state = "enter"
	_timer = 0.0
	_play(&"roar", true)
	_sound(ROAR_SOUND, 0.0, 0.85)
	_sprite.position.y = -60.0
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position:y", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.chain().tween_callback(func() -> void: _shake(5.0, 0.4))
	_roar_waves()


func _process(delta: float) -> void:
	_timer += delta
	_cooldown -= delta
	_roar_cooldown -= delta
	_update_cleaver()
	if state == "dead" or hero == null:
		return
	var to_hero := hero.global_position - global_position
	match state:
		"enter":
			if _timer >= ENTER_TIME:
				_set_state("walk")
		"walk":
			if hero.dead:
				_play(&"idle")
				return
			_face(to_hero)
			if _cooldown <= 0.0:
				_choose_attack(to_hero.length())
			if state == "walk":
				if to_hero.length() > SLAM_RANGE * 0.6:
					position += to_hero.normalized() * SPEED * delta
					_play(&"walk")
				else:
					_play(&"idle")
		"slam":
			_sync_anim(&"slam", SLAM_WARN)
			if _timer >= SLAM_WARN:
				_slam_hit()
		"throw":
			_sync_anim(&"throw", THROW_WARN * 0.4)
			if _cleaver == null and _timer >= THROW_WARN * 0.4:
				_launch_cleaver()
		"roar":
			if _timer >= ROAR_TIME:
				_summon()
		"recover":
			if _timer >= RECOVER:
				_set_state("walk")
	position = position.clamp(bounds.position, bounds.end)


## Wybór ataku: z bliska cios w ziemię, z daleka rzut tasakiem, okrzyk co ROAR_COOLDOWN s (gdy jest miejsce).
func _choose_attack(distance: float) -> void:
	if _roar_cooldown <= 0.0 and distance > SLAM_RANGE:
		_start_roar()
	elif distance <= SLAM_RANGE:
		_start_slam()
	elif distance > 60.0 and randf() < 0.6:
		_start_throw()
	else:
		_cooldown = 0.4  # podchodzi jeszcze kawałek i decyduje od nowa


func _start_slam() -> void:
	_set_state("slam")
	_telegraph = _make_telegraph(global_position, SLAM_RADIUS, SLAM_WARN)
	_play(&"idle")


func _slam_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hero.take_damage(roundi(SLAM_DAMAGE * power))
	_remove_telegraph()
	_sound(SLAM_SOUND, 2.0, randf_range(0.75, 0.85))
	_shake(4.0, 0.25)
	_dust(global_position, SLAM_RADIUS)
	_set_state("recover")


func _start_throw() -> void:
	_set_state("throw")
	_cleaver_to = hero.global_position
	_telegraph = _make_telegraph(_cleaver_to, THROW_RADIUS, THROW_WARN)
	_face(_cleaver_to - global_position)
	_play(&"idle")


## Tasak wylatuje z dłoni Wodza i leci łukiem do środka koła (dolot równo z wypełnieniem koła).
func _launch_cleaver() -> void:
	_cleaver = ProtoCleaver.new()
	_cleaver_from = global_position + Vector2(0, -24)
	_cleaver.global_position = _cleaver_from
	_cleaver_hit = false
	get_parent().add_child(_cleaver)
	var flight := THROW_WARN * 0.6
	var tween := _cleaver.create_tween()
	tween.tween_method(func(k: float) -> void:
		var p := _cleaver_from.lerp(_cleaver_to, k)
		p.y -= sin(k * PI) * 30.0
		_cleaver.global_position = p, 0.0, 1.0, flight)
	tween.tween_callback(_cleaver_landed)
	tween.tween_interval(0.25)
	tween.tween_method(func(k: float) -> void:
		var back := global_position + Vector2(0, -24)
		_cleaver.global_position = _cleaver_to.lerp(back, k)
		_cleaver.returning = true, 0.0, 1.0, RETURN_TIME)
	tween.tween_callback(_cleaver_back)
	_set_state("recover")
	_timer = -flight  # stoi, aż tasak spadnie


func _cleaver_landed() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hero.take_damage(roundi(THROW_DAMAGE * power))
		_cleaver_hit = true  # trafiony przy upadku - na powrocie już nie
	_remove_telegraph()
	if _cleaver:
		_cleaver.landed = true
	_sound(LAND_SOUND, -2.0, randf_range(0.8, 0.95))
	_dust(_cleaver_to, THROW_RADIUS)


func _cleaver_back() -> void:
	if _cleaver:
		_cleaver.queue_free()
	_cleaver = null


## Powracający tasak rani Wojciecha, jeśli przeleci przez niego (raz).
func _update_cleaver() -> void:
	if _cleaver == null or not is_instance_valid(_cleaver) or not _cleaver.returning or _cleaver_hit:
		return
	if hero and not hero.dead and (hero.global_position + Vector2(0, -12)).distance_to(_cleaver.global_position) <= RETURN_HIT:
		_cleaver_hit = true
		hero.take_damage(roundi(RETURN_DAMAGE * power))


func _start_roar() -> void:
	_set_state("roar")
	_roar_cooldown = ROAR_COOLDOWN
	_play(&"roar", true)
	_sound(ROAR_SOUND, -3.0, randf_range(1.0, 1.1))
	_roar_waves()


func _summon() -> void:
	var points: Array = []
	var start := randf() * TAU
	for i in ROAR_MINIONS:
		points.append(global_position + Vector2.from_angle(start + TAU * i / ROAR_MINIONS) * ROAR_RING * Vector2(1, 0.7))
	summon_minions.emit(points)
	_set_state("recover")


func take_damage(amount: int, _from: Vector2) -> void:
	if not alive() or state == "enter":
		return
	hp = maxi(hp - amount, 0)
	spawn_number(amount)
	health_changed.emit(hp, max_hp)
	_audio_hit()
	var tween := create_tween()
	_sprite.modulate = Color(3, 3, 3)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()


func _die() -> void:
	state = "dead"
	remove_from_group(ProtoWeapon.TARGETS)
	_remove_telegraph()
	z_index = -1
	_sound(ROAR_SOUND, -2.0, 0.65)
	_shake(6.0, 0.5)
	died.emit(self)
	if &"death" in _anims:
		_play(&"death", true)
	else:
		_vanish()


func _vanish() -> void:
	var tween := create_tween()
	tween.tween_interval(CORPSE_TIME)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"death":
		_vanish()


func _set_state(s: String) -> void:
	state = s
	_timer = 0.0
	_anim_started = false
	if s == "walk":
		_cooldown = ATTACK_GAP


## Animację ciosu startuje tak, żeby cios (ANIM_HIT_AT) padł w chwili `hit_time` od początku ataku.
func _sync_anim(anim: StringName, hit_time: float) -> void:
	if _anim_started:
		return
	var hit_at: float = ANIM_HIT_AT.get(anim, 0.3)
	if _timer >= hit_time - hit_at:
		_anim_started = true
		_play(anim, true)


func _make_telegraph(at: Vector2, radius: float, duration: float) -> ProtoTelegraph:
	_remove_telegraph()
	var t := ProtoTelegraph.new()
	t.radius = radius
	t.duration = duration
	t.global_position = at
	get_parent().add_child(t)
	return t


func _remove_telegraph() -> void:
	if _telegraph and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


## Pomarańczowe fale rozchodzące się od Wodza (okrzyk i wejście) - zapowiedź goblinów.
func _roar_waves() -> void:
	for i in 3:
		var ring := ProtoRing.new()
		ring.color = Color(1.0, 0.6, 0.2, 0.8)
		ring.max_radius = ROAR_RING + 16.0
		ring.duration = 0.6
		ring.delay = i * 0.22
		ring.position = Vector2(0, -2)
		add_child(ring)


## Kurz po uderzeniu: jasne koło rozchodzące się po ziemi.
func _dust(at: Vector2, radius: float) -> void:
	var ring := ProtoRing.new()
	ring.color = Color(0.85, 0.75, 0.6, 0.9)
	ring.max_radius = radius + 6.0
	ring.duration = 0.35
	ring.global_position = at
	get_parent().add_child(ring)


func _shake(strength: float, duration: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var tween := cam.create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		var k := 1.0 - float(i) / steps
		tween.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.04)


func _audio_hit() -> void:
	_audio.stream = HIT_SOUNDS.pick_random()
	_audio.pitch_scale = randf_range(0.7, 0.85)
	_audio.volume_db = -8.0
	_audio.play()


func _sound(stream: AudioStream, db: float, pitch: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _face(dir: Vector2) -> void:
	if dir.length() > 0.5:
		_sprite.face(dir)


## Gra animację Wodza albo jej zastępstwo (zastępczy goblin nie ma `slam`, `throw`, `roar`).
func _play(anim: StringName, restart := false) -> void:
	if anim not in _anims:
		anim = ANIM_FALLBACK.get(anim, &"idle")
	if anim in _anims:
		_sprite.play_anim(anim, restart)

class_name ProtoGoblinBrute
extends ProtoGoblin
## Goblin osiłek Hordy (od 3. poziomu lochu, udział - DungeonLevels.brute_share): duży, wolny i wytrzymały.
## Podchodzi do Wojciecha i z bliska bierze zamach maczugą: przed sobą na ziemi rysuje czerwone koło
## (ProtoTelegraph), które wypełnia się przez `SLAM_WARN` s - wtedy maczuga uderza w ziemię i rani tylko w kole.
## Ciężki: trafienie mieczem nie przerywa zamachu (trzeba wyjść z koła), odrzut i odepchnięcie są słabe;
## ogłuszenie (Rozłupanie Ziemi) przerywa zamach i gasi koło. Reszta (ucieczka przed Wodzem, iskry, łup) z ProtoGoblin.
## Grafika: assets/spritekiln/goblin_brute/goblin_brute.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const BRUTE_SCENE := "res://assets/spritekiln/goblin_brute/goblin_brute.tscn"
const BRUTE_HP := 150
const BRUTE_SPEED := 28.0
const SLAM_DAMAGE := 22
const SLAM_COOLDOWN := 2.4
## Z tej odległości (stopy-stopy) zaczyna zamach; koło leży `SLAM_REACH` px przed nim i ma promień `SLAM_RADIUS`.
const SLAM_RANGE := 28.0
const SLAM_REACH := 14.0
const SLAM_RADIUS := 26.0
## Czas od początku zamachu do uderzenia (koło wypełnia się przez tyle sekund).
const SLAM_WARN := 1.0
## Uderzenie w animacji `attack` pada tyle sekund po jej początku (zdarzenie `hit`) - animacja rusza tak,
## żeby maczuga spadła razem z wypełnieniem koła; wcześniej osiłek stoi w miejscu.
const ANIM_HIT_AT := 0.82
## Po uderzeniu stoi jeszcze tyle sekund (powrót z maczugą).
const RECOVER := 0.45
## Ułamek zwykłego odrzutu i odepchnięcia (ciężki).
const HEAVY := 0.3
const SLAM_SOUND := preload("res://assets/watra/chief_slam.ogg")
const FX_SLAM := preload("res://assets/effects/boss_slam.png")

var _telegraph: ProtoTelegraph
var _anim_started := false


func _init() -> void:
	scene_path = BRUTE_SCENE
	max_hp = BRUTE_HP
	speed = BRUTE_SPEED
	damage = SLAM_DAMAGE
	attack_cooldown = SLAM_COOLDOWN
	strike_time = SLAM_WARN
	attack_time = SLAM_WARN + RECOVER
	shadow_scale = 1.3


func _ready() -> void:
	super()
	center_height = 20.0


func _process(delta: float) -> void:
	super(delta)
	if _state != "attack" or _stunned > 0.0:
		return
	if _scene and not _anim_started and _timer >= SLAM_WARN - ANIM_HIT_AT:
		_anim_started = true
		_play(&"attack", true)
	if not _struck and _timer >= SLAM_WARN:
		_strike()
	if _scene and _timer >= SLAM_WARN + RECOVER:
		_state = "walk"


func _walk_move(to_hero: Vector2) -> Vector2:
	if to_hero.length() <= SLAM_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
		return Vector2.ZERO
	if to_hero.length() > SLAM_RANGE * 0.7:
		_face(to_hero)
		return to_hero.normalized() * speed * speed_factor()
	return Vector2.ZERO


## Zamach: koło przed osiłkiem w stronę postaci; osiłek stoi (idle), animacja ciosu rusza tuż przed uderzeniem.
func _start_attack(to_hero: Vector2) -> void:
	_state = "attack"
	_timer = 0.0
	_struck = false
	_anim_started = false
	_cooldown = attack_cooldown
	var dir := to_hero.normalized() if to_hero.length() > 1.0 else Vector2.DOWN
	_face(dir)
	_play(&"idle")
	_remove_telegraph()
	_telegraph = ProtoTelegraph.new()
	_telegraph.radius = SLAM_RADIUS
	_telegraph.duration = SLAM_WARN
	_telegraph.position = position + dir * SLAM_REACH
	get_parent().add_child(_telegraph)


## Uderzenie maczugą: rani postać w kole, dudni i wzbija kurz.
func _strike() -> void:
	_struck = true
	if _telegraph and is_instance_valid(_telegraph):
		if hero and not hero.dead and _telegraph.contains(hero.global_position):
			hero.take_damage(roundi(damage * power))
		Fx.once(get_parent(), FX_SLAM, 12, 16.0, _telegraph.global_position, Vector2(37, 25), 20, SLAM_RADIUS / 34.0)
	_remove_telegraph()
	_audio.stream = SLAM_SOUND
	_audio.pitch_scale = randf_range(0.95, 1.1)
	_audio.play()


## Uderzenie w ziemię liczy zegar (`_process`), nie zdarzenie animacji.
func _on_anim_event(_anim: StringName, _event: StringName) -> void:
	pass


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"attack":
		return  # koniec zamachu liczy zegar (RECOVER)
	super(anim)


## Ciężki: w trakcie zamachu trafienie tylko rani (bez przerwania), poza nim - słabszy odrzut.
func take_damage(amount: int, from: Vector2) -> void:
	if not alive():
		return
	if _state != "attack":
		super(amount, from)
		_push *= HEAVY
		return
	hp -= amount
	spawn_number(amount)
	_audio.stream = HIT_SOUNDS.pick_random()
	_audio.pitch_scale = randf_range(0.8, 0.95)
	_audio.play()
	var tween := create_tween()
	_sprite.modulate = Color(3, 3, 3)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()


func push_away(from: Vector2, force: float) -> void:
	super(from, force * HEAVY)


func stun(time: float) -> void:
	_remove_telegraph()
	super(time)


func flee(squeak := true) -> void:
	_remove_telegraph()
	super(squeak)


func _die() -> void:
	_remove_telegraph()
	super()


func _exit_tree() -> void:
	_remove_telegraph()


func _remove_telegraph() -> void:
	if _telegraph and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null

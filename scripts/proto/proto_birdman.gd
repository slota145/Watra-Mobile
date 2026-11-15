class_name ProtoBirdman
extends ProtoGoblin
## Ptakoczłek wojownik - zwykły potwór Górskich równin (Dungeons.PLAINS, jak w Wietrznych Turniach Watry, ustalone
## z autorem 15.11.2026): z bliska pchnięcie oszczepem (jak cios goblina), a z dystansu LEAP_MIN-LEAP_MAX doskok:
## przez LEAP_WARN s na ziemi leży czerwony pas do miejsca, gdzie stała postać, potem ptakoczłek skacze nim
## z rozpędu (LEAP_TIME s) i rani, jeśli postać wciąż jest w pasie przy lądowaniu. Odnowienie doskoku LEAP_COOLDOWN.
## Cios fizyczny. Nie piszczy przy ucieczce. Grafika: assets/spritekiln/birdman/birdman.tscn (idle, walk, attack ze
## zdarzeniem `hit`, leap - doskok, hit, death).

const BIRDMAN_SCENE := "res://assets/spritekiln/birdman/birdman.tscn"
const BIRDMAN_HP := 44
const BIRDMAN_SPEED := 32.0
const BIRDMAN_DAMAGE := 11
const LEAP_MIN := 45.0
const LEAP_MAX := 110.0
const LEAP_WARN := 0.55
const LEAP_TIME := 0.3
const LEAP_WIDTH := 16.0
const LEAP_DAMAGE := 14
const LEAP_COOLDOWN := 4.0

var _leap_cooldown := 1.5
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_line: ProtoTelegraph


func _init() -> void:
	scene_path = BIRDMAN_SCENE
	max_hp = BIRDMAN_HP
	speed = BIRDMAN_SPEED
	damage = BIRDMAN_DAMAGE
	squeaks = false
	fallback_color = Color(0.55, 0.38, 0.25)


## Czy właśnie szykuje doskok albo leci (testy).
func leaping() -> bool:
	return _state == "leap_warn" or _state == "leap"


func _process(delta: float) -> void:
	_leap_cooldown -= delta
	if _state == "leap_warn":
		_timer += delta
		if _timer >= LEAP_WARN:
			_jump()
		return
	if _state == "leap":
		_timer += delta
		var k := clampf(_timer / LEAP_TIME, 0.0, 1.0)
		position = _leap_from.lerp(_leap_to, k)
		if k >= 1.0:
			_land()
		return
	super(delta)


func _walk_move(to_hero: Vector2) -> Vector2:
	var d := to_hero.length()
	if d >= LEAP_MIN and d <= LEAP_MAX and _leap_cooldown <= 0.0 and _stunned <= 0.0:
		_start_leap(to_hero)
		return Vector2.ZERO
	return super(to_hero)


## Zapowiedź doskoku: czerwony pas od ptakoczłeka do miejsca postaci; stoi i przysiada.
func _start_leap(to_hero: Vector2) -> void:
	_state = "leap_warn"
	_timer = 0.0
	_leap_cooldown = LEAP_COOLDOWN
	_leap_from = position
	_leap_to = (position + to_hero).clamp(bounds.position, bounds.end)
	_face(to_hero)
	_play(&"idle")
	_leap_line = ProtoTelegraph.new()
	_leap_line.length = _leap_from.distance_to(_leap_to)
	_leap_line.width = LEAP_WIDTH
	_leap_line.angle = (_leap_to - _leap_from).angle()
	_leap_line.duration = LEAP_WARN
	get_parent().add_child(_leap_line)
	_leap_line.global_position = global_position


func _jump() -> void:
	_state = "leap"
	_timer = 0.0
	_play(&"leap", true)


## Lądowanie: rani, jeśli postać wciąż stoi w pasie.
func _land() -> void:
	if _leap_line and is_instance_valid(_leap_line) and hero and not hero.dead and _leap_line.contains(hero.global_position):
		hero.take_damage(roundi(LEAP_DAMAGE * power * damage_mult), element)
	_remove_line()
	_state = "walk"
	_cooldown = maxf(_cooldown, 0.5)


func _remove_line() -> void:
	if _leap_line and is_instance_valid(_leap_line):
		_leap_line.queue_free()
	_leap_line = null


## Trafienie przerywa zapowiedź doskoku (nie sam skok).
func take_damage(amount: int, from: Vector2) -> void:
	if _state == "leap_warn":
		_remove_line()
		_state = "walk"
	if _state == "leap":
		amount = _absorb(amount)
		hp -= amount
		spawn_number(amount)
		if hp <= 0:
			_remove_line()
			_die()
		return
	super(amount, from)


func stun(time: float) -> void:
	if _state == "leap":
		return
	_remove_line()
	if _state == "leap_warn":
		_state = "walk"
	super(time)


func flee(squeak := true) -> void:
	_remove_line()
	super(squeak)


func _die() -> void:
	_remove_line()
	super()


func _exit_tree() -> void:
	_remove_line()


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"leap":
		return
	super(anim)

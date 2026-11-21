class_name ProtoLatawiec
extends ProtoGoblin
## Latawiec - zwykły potwór Podniebnych wysp (Dungeons.SKY, ustalone z autorem 21.11.2026): słowiański demon
## powietrza, szybki i słabszy od goblina. Zamiast stać i bić, przelatuje przez postać: z odległości SWOOP_MIN-SWOOP_MAX
## zawisa na SWOOP_WARN s (drży, rozjaśnia się - bez czerwonego pasa, inaczej niż doskok ptakoczłeka), potem leci prosto
## przez miejsce postaci z prędkością SWOOP_SPEED na odległość SWOOP_LENGTH i rani pazurami (powietrze), jeśli zahaczy
## o postać (raz na przelot). Z bliska zwykły cios jak goblin. Nie piszczy przy ucieczce.
## Grafika: assets/spritekiln/latawiec/latawiec.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const LATAWIEC_SCENE := "res://assets/spritekiln/latawiec/latawiec.tscn"
const LATAWIEC_HP := 30
const LATAWIEC_SPEED := 46.0
const LATAWIEC_DAMAGE := 9
const SWOOP_MIN := 40.0
const SWOOP_MAX := 95.0
const SWOOP_WARN := 0.4
const SWOOP_SPEED := 260.0
## Przelot kończy się tyle px za miejscem, gdzie stała postać.
const SWOOP_OVERSHOOT := 45.0
const SWOOP_HIT := 11.0
const SWOOP_DAMAGE := 11
const SWOOP_COOLDOWN := 3.0

var _swoop_cooldown := 1.0
var _swoop_dir := Vector2.DOWN
var _swoop_left := 0.0
var _swoop_hit := false


func _init() -> void:
	scene_path = LATAWIEC_SCENE
	max_hp = LATAWIEC_HP
	speed = LATAWIEC_SPEED
	damage = LATAWIEC_DAMAGE
	element = Elements.AIR
	squeaks = false
	fallback_color = Color(0.75, 0.9, 1.0)


## Czy właśnie zawisł przed przelotem albo przelatuje (testy).
func swooping() -> bool:
	return _state == "swoop_warn" or _state == "swoop"


func _process(delta: float) -> void:
	_swoop_cooldown -= delta
	if _state == "swoop_warn":
		_timer += delta
		modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.6, 1.8, 2.0), absf(sin(_timer * 30.0)) * 0.6)
		if _timer >= SWOOP_WARN:
			_state = "swoop"
			_timer = 0.0
			modulate = Color.WHITE
			_play(&"walk", true)
		return
	if _state == "swoop":
		var step := SWOOP_SPEED * delta
		position = (position + _swoop_dir * step).clamp(bounds.position, bounds.end)
		_swoop_left -= step
		if not _swoop_hit and hero and not hero.dead and global_position.distance_to(hero.global_position) < SWOOP_HIT:
			_swoop_hit = true
			hit_hero(hero, roundi(SWOOP_DAMAGE * power * damage_mult), element)
		if _swoop_left <= 0.0:
			_state = "walk"
			_cooldown = maxf(_cooldown, 0.4)
		return
	super(delta)


func _walk_move(to_hero: Vector2) -> Vector2:
	var d := to_hero.length()
	if d >= SWOOP_MIN and d <= SWOOP_MAX and _swoop_cooldown <= 0.0 and _stunned <= 0.0:
		_start_swoop(to_hero)
		return Vector2.ZERO
	return super(to_hero)


## Zawiśnięcie przed przelotem: kierunek ustala się teraz (da się zejść z drogi).
func _start_swoop(to_hero: Vector2) -> void:
	_state = "swoop_warn"
	_timer = 0.0
	_swoop_cooldown = SWOOP_COOLDOWN
	_swoop_dir = to_hero.normalized()
	_swoop_left = to_hero.length() + SWOOP_OVERSHOOT
	_swoop_hit = false
	_face(to_hero)
	_play(&"idle")


## Trafienie przerywa zawiśnięcie (nie sam przelot).
func take_damage(amount: int, from: Vector2) -> void:
	if _state == "swoop_warn":
		_state = "walk"
		modulate = Color.WHITE
	super(amount, from)


func stun(time: float) -> void:
	if _state == "swoop_warn" or _state == "swoop":
		_state = "walk"
		modulate = Color.WHITE
	super(time)

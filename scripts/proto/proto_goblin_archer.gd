class_name ProtoGoblinArcher
extends ProtoGoblin
## Goblin łucznik Hordy (od 2. poziomu lochu, udział - DungeonLevels.archer_share): trzyma się w odległości
## od Wojciecha (`KEEP_MIN`-`SHOOT_RANGE`), a gdy postać podejdzie za blisko, cofa się. Strzela wolną strzałą
## (ProtoArrow) w miejsce, gdzie postać stała w chwili zablokowania celu. Zapowiedź: od początku naciągania
## na ziemi pojawia się czerwona linia celu, która podąża za postacią, a na `AIM_LOCK` s przed strzałem staje
## i jaśnieje - wtedy trzeba zejść z linii. Trafienie mieczem w trakcie naciągania przerywa strzał.
## Słabszy i wolniejszy od goblina z tasakiem; reszta (ucieczka przed Wodzem, iskry, łup, ogłuszenie) z ProtoGoblin.
## Grafika: assets/spritekiln/goblin_archer/goblin_archer.tscn (idle, walk, attack ze zdarzeniem `release`, hit, death).

const ARCHER_SCENE := "res://assets/spritekiln/goblin_archer/goblin_archer.tscn"
const ARCHER_HP := 26
const ARCHER_SPEED := 38.0
const ARROW_DAMAGE := 8
const SHOOT_COOLDOWN := 2.2
## Strzela z odległości do `SHOOT_RANGE` (mieści się w kadrze telefonu), cofa się, gdy postać jest bliżej niż `KEEP_MIN`.
const SHOOT_RANGE := 130.0
const KEEP_MIN := 65.0
## Strzał pada tyle sekund po początku naciągania (zdarzenie `release` animacji; bez grafiki - z zegara).
const RELEASE_TIME := 0.63
## Na tyle sekund przed strzałem cel przestaje podążać za postacią.
const AIM_LOCK := 0.3
## Skąd wylatuje strzała, gdy grafika nie ma punktu `arrow` (nad stopami, trochę przed postacią).
const BOW_HEIGHT := 11.0

## Kierunek strzału (od stóp łucznika do stóp postaci).
var aim := Vector2.DOWN
var _aim_line: _AimLine


func _init() -> void:
	scene_path = ARCHER_SCENE
	max_hp = ARCHER_HP
	speed = ARCHER_SPEED
	damage = ARROW_DAMAGE
	attack_cooldown = SHOOT_COOLDOWN
	strike_time = RELEASE_TIME
	attack_time = RELEASE_TIME + 0.25


func _ready() -> void:
	super()
	_cooldown = randf_range(0.8, 1.6)  # pierwszy strzał nie od razu po wejściu w kadr
	_aim_line = _AimLine.new()
	_aim_line.archer = self
	add_child(_aim_line)


## Czy łucznik właśnie celuje (naciąga łuk) - dla linii celu i testów.
func aiming() -> bool:
	return _state == "attack" and not _struck


## Czy cel jest już zablokowany (linia stoi i jaśnieje).
func aim_locked() -> bool:
	return aiming() and _timer >= RELEASE_TIME - AIM_LOCK


func _process(delta: float) -> void:
	super(delta)
	if aiming() and not aim_locked() and hero:
		var to_hero := hero.global_position - global_position
		if to_hero.length() > 1.0:
			aim = to_hero.normalized()
			_face(aim)


## Dystans zamiast podchodzenia: za daleko - podchodzi, za blisko - cofa się, w sam raz - stoi i strzela.
func _walk_move(to_hero: Vector2) -> Vector2:
	var d := to_hero.length()
	_face(to_hero)
	if d <= SHOOT_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
		return Vector2.ZERO
	if d > SHOOT_RANGE * 0.85:
		return to_hero.normalized() * speed * speed_factor()
	if d < KEEP_MIN:
		return -to_hero.normalized() * speed * 0.8 * speed_factor()
	return Vector2.ZERO


func _start_attack(to_hero: Vector2) -> void:
	aim = to_hero.normalized() if to_hero.length() > 1.0 else aim
	super(to_hero)


## Strzał: strzała leci w zablokowanym kierunku (da się ją wyminąć).
func _strike() -> void:
	_struck = true
	if hero == null:
		return
	var arrow := ProtoArrow.new()
	arrow.hero = hero
	arrow.direction = aim
	arrow.damage = roundi(damage * power)
	arrow.position = position + aim * 6.0
	get_parent().add_child(arrow)


func _on_anim_event(anim: StringName, event: StringName) -> void:
	if anim == &"attack" and event == &"release" and _state == "attack" and not _struck:
		_strike()


## Czerwona linia celu na ziemi (pod postaciami): przerywana, od łucznika w kierunku strzału; podczas naciągania
## coraz wyraźniejsza, po zablokowaniu celu jaśniejsza i pełna.
class _AimLine extends Node2D:
	const LENGTH := 150.0
	const COLOR := Color(1.0, 0.2, 0.1)
	var archer: ProtoGoblinArcher

	func _ready() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		visible = archer.aiming()
		if visible:
			queue_redraw()

	func _draw() -> void:
		var locked := archer.aim_locked()
		var t := clampf(archer._timer / (RELEASE_TIME - AIM_LOCK), 0.0, 1.0)
		var a := 0.85 if locked else 0.2 + 0.35 * t
		var dash := 6.0
		var x := 8.0
		while x < LENGTH:
			var fade := 1.0 - x / LENGTH
			var seg := dash * (1.6 if locked else 1.0)
			draw_line(archer.aim * x, archer.aim * minf(x + seg, LENGTH), Color(COLOR, a * fade), 1.5 if locked else 1.0)
			x += dash * 2.0

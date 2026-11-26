class_name ProtoKretolak
extends ProtoGoblin
## Kretołak - zwykły potwór Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026; liczby - Claude): kreto-człek
## z pazurami do kopania. Szybki; **wyskakuje spod ziemi**: zaczyna zakopany - pod ziemią sunie do postaci szybciej
## (BURROW_SPEED), widać tylko kopczyk ziemi z ogonem grudek; nie da się go wtedy trafić (poza grupą celów broni).
## Pod postacią staje i ziemia się wybrzusza - czerwone koło (RISE_WARN s), potem wyskakuje z pyłem i rani w kole
## (ziemia). Dalej walczy jak goblin (cios pazurami - zdarzenie `hit`). Gdy postać odbiegnie dalej niż REBURROW_DIST,
## po chwili znów się zakopuje. Zakopany najwyżej BURROW_MAX s - potem wyskakuje, gdzie jest. Nie piszczy przy ucieczce.
## Grafika: assets/spritekiln/kretolak/kretolak.tscn (idle, walk, attack ze zdarzeniem `hit` ok. 0,4 s, hit, death);
## do czasu grafiki - zastępczy kolor.

const KRETOLAK_SCENE := "res://assets/spritekiln/kretolak/kretolak.tscn"
const KRETOLAK_HP := 32
const KRETOLAK_SPEED := 50.0
const KRETOLAK_DAMAGE := 12
const BURROW_SPEED := 78.0
## Wynurza się, gdy jest tak blisko stóp postaci; koło wynurzenia - promień i czas zapowiedzi; obrażenia wyskoku.
const RISE_NEAR := 8.0
const RISE_RADIUS := 16.0
const RISE_WARN := 0.5
const RISE_DAMAGE := 14
const BURROW_MAX := 7.0
const REBURROW_DIST := 130.0
const REBURROW_COOLDOWN := 7.0
const DUST_FX := preload("res://assets/effects/boss_slam.png")
## Świeżo wykopana ziemia - ciemniejsza od podłogi chodnika, z jasnym wierzchem i ciemnym obrysem.
const DIRT := Color(0.3, 0.2, 0.12)
const DIRT_LIGHT := Color(0.6, 0.47, 0.32)
const DIRT_EDGE := Color(0.15, 0.09, 0.05)

## Czy zaczyna zakopany (ProtoHorde wpuszcza kretołaki spod ziemi; testy mogą wyłączyć).
var start_burrowed := true
## "" - na powierzchni, "dig" - sunie pod ziemią, "rise" - wybrzusza się (koło), przed wyskokiem.
var burrow := ""
## Ile razy wyskok trafił postać (testy).
var rise_hits := 0
var _burrow_t := 0.0
var _reburrow_cd := REBURROW_COOLDOWN
var _rise: ProtoTelegraph
var _trail: Array[Vector2] = []
var _trail_t := 0.0
var _shadow: Sprite2D


func _init() -> void:
	scene_path = KRETOLAK_SCENE
	max_hp = KRETOLAK_HP
	speed = KRETOLAK_SPEED
	damage = KRETOLAK_DAMAGE
	element = Elements.EARTH
	squeaks = false
	fallback_color = Color(0.45, 0.35, 0.3)
	strike_time = 0.4


func _ready() -> void:
	super()
	for c in get_children():
		if c is Sprite2D and c.texture == ProtoHero._shadow_texture():
			_shadow = c
	if start_burrowed:
		dig()


## Zakopuje się: znika pod ziemią (kopczyk), przestaje być celem broni.
func dig() -> void:
	if not alive():
		return
	burrow = "dig"
	_burrow_t = 0.0
	_state = "walk"
	_trail.clear()
	remove_from_group(ProtoWeapon.TARGETS)
	_show_body(false)


## Wyskakuje: pył, ciało wyskakuje z ziemi, rani postać w kole wynurzenia (`hurt` i było koło), znów jest celem.
func emerge(hurt := true) -> void:
	if burrow == "":
		return
	if _rise and is_instance_valid(_rise):
		if hurt and hero and not hero.dead and _rise.contains(hero.global_position):
			rise_hits += 1
			hit_hero(hero, roundi(RISE_DAMAGE * power * damage_mult), element)
		_rise.queue_free()
	_rise = null
	burrow = ""
	_reburrow_cd = REBURROW_COOLDOWN
	_cooldown = maxf(_cooldown, 0.5)
	_trail.clear()
	add_to_group(ProtoWeapon.TARGETS)
	_show_body(true)
	if get_parent():
		Fx.once(get_parent(), DUST_FX, 12, 18.0, global_position.round(), Vector2(37, 25), 2, 0.4).modulate = Color(0.8, 0.65, 0.45)
	if _sprite:
		_sprite.scale = Vector2(1.0, 0.2)
		create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _show_body(on: bool) -> void:
	if _sprite:
		_sprite.visible = on
	if _shadow:
		_shadow.visible = on
	if elite:
		elite.visible = on


func _process(delta: float) -> void:
	if burrow == "":
		super(delta)
		_reburrow_cd -= delta
		if _state == "walk" and _reburrow_cd <= 0.0 and hero and not hero.dead and not _objective_alive() \
				and global_position.distance_to(hero.global_position) > REBURROW_DIST and _stunned <= 0.0:
			dig()
		return
	_timer += delta
	_cooldown -= delta
	_burrow_t += delta
	if _objective_alive():
		emerge(false)
		return
	match burrow:
		"dig":
			if hero and not hero.dead:
				var to := hero.global_position - global_position
				if to.length() <= RISE_NEAR or _burrow_t >= BURROW_MAX:
					_start_rise()
				else:
					position = ProtoDecor.push_out((position + to.normalized() * BURROW_SPEED * speed_factor() * delta)
							.clamp(bounds.position, bounds.end), 3.0)
			elif _burrow_t >= BURROW_MAX:
				_start_rise()
			_trail_t -= delta
			if _trail_t <= 0.0:
				_trail_t = 0.08
				_trail.push_front(global_position)
				if _trail.size() > 6:
					_trail.pop_back()
		"rise":
			if _burrow_t >= RISE_WARN:
				emerge()
	queue_redraw()


## Ziemia wybrzusza się pod postacią: czerwone koło, po RISE_WARN s wyskok.
func _start_rise() -> void:
	burrow = "rise"
	_burrow_t = 0.0
	if get_parent():
		_rise = ProtoTelegraph.new()
		_rise.radius = RISE_RADIUS
		_rise.duration = RISE_WARN
		get_parent().add_child(_rise)
		_rise.global_position = global_position


## Kopczyk ziemi nad zakopanym kretołakiem (drga przy wybrzuszeniu) i grudki zostające za nim.
func _draw() -> void:
	if burrow == "":
		return
	for i in _trail.size():
		var p := _trail[i] - global_position
		var a := 0.5 * (1.0 - float(i) / _trail.size())
		draw_rect(Rect2(p + Vector2(-2, -1), Vector2(2, 2)), Color(DIRT, a))
		draw_rect(Rect2(p + Vector2(1, 0), Vector2(2, 1)), Color(DIRT_LIGHT, a))
	var shake := Vector2(randf_range(-1, 1), 0) if burrow == "rise" else Vector2.ZERO
	var h := 7.0 + (4.0 * _burrow_t / RISE_WARN if burrow == "rise" else sin(_timer * 18.0))
	draw_set_transform(shake, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2(0, 2), 12.0, Color(0, 0, 0, 0.3))
	draw_set_transform(shake + Vector2(0, -h * 0.35), 0.0, Vector2(1.0, h / 10.0))
	draw_circle(Vector2.ZERO, 10.0, DIRT_EDGE)
	draw_circle(Vector2.ZERO, 9.0, DIRT)
	draw_circle(Vector2(-2.0, -3.0), 5.5, DIRT_LIGHT)
	draw_set_transform(Vector2.ZERO)
	# grudki odpryskujące na boki
	for i in 4:
		var ph := fposmod(_timer * 2.5 + i * 0.25, 1.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		var c := shake + Vector2(side * (6.0 + ph * 7.0), -h * 0.6 - sin(ph * PI) * 6.0)
		draw_rect(Rect2(c, Vector2(2, 2)), Color(DIRT_LIGHT if i < 2 else DIRT, 1.0 - ph))
	draw_rect(Rect2(shake + Vector2(-8, 0), Vector2(3, 2)), DIRT_EDGE)
	draw_rect(Rect2(shake + Vector2(6, 1), Vector2(2, 2)), DIRT)


func take_damage(amount: int, from: Vector2) -> void:
	if burrow != "":
		return  # pod ziemią nietykalny
	super(amount, from)


func burn_tick(amount: int) -> void:
	if burrow == "":
		super(amount)


func stun(time: float) -> void:
	if burrow == "":
		super(time)


func push_away(from: Vector2, force: float) -> void:
	if burrow == "":
		super(from, force)


func flee(squeak := true) -> void:
	if burrow != "":
		emerge(false)
	super(squeak)


func _die() -> void:
	if _rise and is_instance_valid(_rise):
		_rise.queue_free()
	super()


func _exit_tree() -> void:
	if _rise and is_instance_valid(_rise):
		_rise.queue_free()

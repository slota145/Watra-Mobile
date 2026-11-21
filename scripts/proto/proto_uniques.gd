class_name ProtoUniques
extends Node2D
## Unikaty w walce (Items.UNIQUES) - dziecko postaci. Arena podaje broń (`weapon`) i założone unikaty (`worn`: id ->
## siła działania, Items.totals "uniques"). Tu działają te, które potrzebują własnego węzła:
## - Ostatnia Warownia: co COUNT_EVERY s liczy wrogów blisko postaci (ProtoWeapon.bastion_count - obrażenia
##   w `_deal`, ProtoHero.bastion_res - odporność), słaby krąg pokazuje zasięg, gdy ktoś w nim stoi;
## - Ślady Swaroga: za idącą postacią płomienie (efekt glewii `glaive_ground_fire`) na Items.SWAROG_TIME s, co TRAIL_TICK s
##   ranią ogniem (ProtoWeapon.aura_hit) i podpalają wrogów, którzy w nich stoją;
## - Pierścień Strzyboga: `split` (z ProtoWeapon._deal przy trafieniu pociskiem) wypuszcza odłamki w pobliskich wrogów
##   (najwyżej raz na SPLIT_COOLDOWN s - Kule Arkanów i deszcz strzał trafiają bardzo często).
## Oko Licha i Zwierciadło Mokoszy działają w ProtoWeapon, Korona Czarnoboga - w ProtoHero i HeroStats.

const FLAME_FX := preload("res://assets/effects/glaive_ground_fire.png")
const FLAME_FRAMES := 8
const FLAME_ANCHOR := Vector2(10, 15)
const FLAME_FPS := 12.0
## Co ile pikseli drogi zostaje płomień śladu, jak daleko sięga i co ile sekund rani.
const TRAIL_STEP := 9.0
const TRAIL_RADIUS := 11.0
const TRAIL_TICK := 0.5
const TRAIL_FADE := 0.4
const COUNT_EVERY := 0.2
const SPLIT_COOLDOWN := 0.08
## Odłamki: zasięg szukania celów, prędkość, kolor smugi (wiatr Strzyboga).
const SHARD_RANGE := 90.0
const SHARD_SPEED := 300.0
const SHARD_COLOR := Color(0.75, 0.95, 1.0)
const BASTION_COLOR := Color(0.85, 0.7, 0.4)

var weapon: ProtoWeapon
var worn := {}:
	set(v):
		worn = v
		_apply()

var _hero: ProtoHero
var _count_t := 0.0
var _trail_tick := 0.0
var _last_drop := Vector2.INF
var _flames: Array = []  # [Sprite2D, ile zostało s]
var _split_ready := 0.0
var _clock := 0.0
var _bastion := 0


func _ready() -> void:
	_hero = get_parent() as ProtoHero
	z_index = -1
	_apply()


func _apply() -> void:
	if weapon:
		weapon.uniques = worn
		weapon.uniques_node = self
		if not worn.has("bastion"):
			weapon.bastion_count = 0
	if _hero:
		_hero.crown = worn.has("crown")
		if not worn.has("bastion"):
			_hero.bastion_res = 0.0
	if not worn.has("bastion"):
		_bastion = 0
		queue_redraw()
	if not worn.has("swarog"):
		_clear_flames()


func _process(delta: float) -> void:
	_clock += delta
	if _hero == null or weapon == null or _hero.dead:
		return
	if worn.has("bastion"):
		_count_t -= delta
		if _count_t <= 0.0:
			_count_t = COUNT_EVERY
			var n := mini(weapon._near(_hero.global_position, Items.BASTION_RADIUS).size(), Items.BASTION_MAX)
			weapon.bastion_count = n
			_hero.bastion_res = n * Items.BASTION_RES / 100.0
			if n != _bastion:
				_bastion = n
				queue_redraw()
	if worn.has("swarog"):
		_process_trail(delta)


## Ślad Swaroga: nowy płomień co TRAIL_STEP drogi, gaśnięcie starych, co TRAIL_TICK s ogień w stojących w nim wrogach.
func _process_trail(delta: float) -> void:
	var at := _hero.global_position
	if _last_drop == Vector2.INF or at.distance_to(_last_drop) >= TRAIL_STEP:
		_last_drop = at
		_drop_flame(at)
	for i in range(_flames.size() - 1, -1, -1):
		var f: Array = _flames[i]
		f[1] -= delta
		var s: Sprite2D = f[0]
		if f[1] <= 0.0:
			s.queue_free()
			_flames.remove_at(i)
			continue
		s.frame = int(_clock * FLAME_FPS + i) % FLAME_FRAMES
		s.modulate.a = clampf(f[1] / TRAIL_FADE, 0.0, 1.0)
	_trail_tick -= delta
	if _trail_tick > 0.0 or _flames.is_empty():
		return
	_trail_tick = TRAIL_TICK
	var power: float = worn.swarog / 100.0 * TRAIL_TICK
	var hit := {}
	for f in _flames:
		var p: Vector2 = (f[0] as Sprite2D).global_position
		for t in weapon._near(p, TRAIL_RADIUS):
			if hit.has(t) or not t.alive():
				continue
			hit[t] = true
			weapon.aura_hit(t, power, Elements.FIRE, p)
			if t.alive():
				t.burn(float(weapon._roll(power)), ProtoWeapon.BURN_TIME * weapon.duration_mult, weapon.penetration)


func _drop_flame(at: Vector2) -> void:
	var world := _hero.get_parent()
	if world == null:
		return
	var s := Sprite2D.new()
	s.texture = FLAME_FX
	s.hframes = FLAME_FRAMES
	s.centered = false
	s.offset = -FLAME_ANCHOR
	s.z_index = -1
	world.add_child(s)
	s.global_position = at + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
	_flames.append([s, Items.SWAROG_TIME])


func _clear_flames() -> void:
	for f in _flames:
		if is_instance_valid(f[0]):
			(f[0] as Sprite2D).queue_free()
	_flames.clear()
	_last_drop = Vector2.INF


func _exit_tree() -> void:
	_clear_flames()


## Pierścień Strzyboga: pocisk umiejętności `skill` trafił `t` - odłamki lecą w najbliższych innych wrogów.
func split(t: ProtoTarget, skill: String) -> void:
	if _clock < _split_ready or _hero == null:
		return
	_split_ready = _clock + SPLIT_COOLDOWN
	var near := weapon._near(t.global_position, SHARD_RANGE).filter(func(n: ProtoTarget) -> bool:
		return n != t and n.alive())
	near.sort_custom(func(a: ProtoTarget, b: ProtoTarget) -> bool:
		return a.global_position.distance_squared_to(t.global_position) < b.global_position.distance_squared_to(t.global_position))
	var shard_power := Items.strzybog_power(float(worn.get("strzybog", Items.STRZYBOG_BASE)))  # rośnie z poziomem unikatu
	var power := shard_power * weapon._power(skill) if Skills.DATA.has(skill) else shard_power
	var world := _hero.get_parent()
	for i in mini(Items.STRZYBOG_SHARDS, near.size()):
		var shard := _Shard.new()
		shard.weapon = weapon
		shard.target = near[i]
		shard.power = power
		world.add_child(shard)
		shard.global_position = t.global_position + Vector2(0, -6)


## Krąg Warowni: słaby, tym mocniejszy, im więcej wrogów blisko.
func _draw() -> void:
	if _bastion <= 0:
		return
	var a := 0.08 + 0.2 * float(_bastion) / Items.BASTION_MAX
	draw_arc(Vector2.ZERO, Items.BASTION_RADIUS, 0.0, TAU, 48, Color(BASTION_COLOR, a), 1.0)


## Odłamek Pierścienia Strzyboga: krótka jasna smuga lecąca do celu; rani przy dotarciu (bez krytyków i kamieni).
class _Shard extends Node2D:
	var weapon: ProtoWeapon
	var target: ProtoTarget
	var power := 0.5
	var _dir := Vector2.RIGHT
	var _life := 0.8

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0 or not is_instance_valid(target) or not is_instance_valid(weapon):
			queue_free()
			return
		var goal := target.global_position + Vector2(0, -6)
		var to := goal - global_position
		var step := ProtoUniques.SHARD_SPEED * delta
		if to.length() <= step:
			if target.alive():
				weapon.aura_hit(target, power, weapon.element, global_position)
			queue_free()
			return
		_dir = to.normalized()
		global_position += _dir * step
		queue_redraw()

	func _draw() -> void:
		draw_line(-_dir * 7.0, Vector2.ZERO, Color(ProtoUniques.SHARD_COLOR, 0.5), 2.0)
		draw_line(-_dir * 3.0, Vector2.ZERO, ProtoUniques.SHARD_COLOR, 1.5)

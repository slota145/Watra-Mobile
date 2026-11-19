class_name ProtoTalismans
extends Node2D
## Talizmany w walce (Talismans) - dziecko postaci. Arena podaje założone talizmany (`worn`: talizman -> poziom)
## i broń (`weapon`); broń woła `on_hit` przy każdym trafieniu (ProtoWeapon._deal), arena podpina pokonanych
## (`on_kill`, ProtoHorde.monster_died), rany postaci (`on_hurt`, ProtoHero.hurt) i użyte umiejętności (`on_skill`,
## ProtoWeapon.skill_used). Efekty ranią przez ProtoWeapon.aura_hit (bez krytyków i kamieni, więc nie odpalają
## talizmanów ponownie) i używają gotowych animacji gry (fala, grom Peruna, wir, kolce, wybuch, leczenie).

var weapon: ProtoWeapon
var worn := {}:
	set(v):
		worn = v
		_apply()

var _hero: ProtoHero
var _hit_ready := {}  # talizman -> czas gry, od którego znowu może zadziałać przy trafieniu
var _tremor_next := 0.0
var _bloodlust := 0
var _bloodlust_left := 0.0


func _ready() -> void:
	_hero = get_parent() as ProtoHero


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Ustawienia broni z założonych talizmanów: droższe umiejętności (Korona Peruna).
func _apply() -> void:
	if weapon == null:
		return
	weapon.mana_tax = Talismans.archmage_cost(worn["archmage"]) if worn.has("archmage") else 0.0
	if not worn.has("bloodlust"):
		_bloodlust = 0
		weapon.bonus_mult = 1.0


func _process(delta: float) -> void:
	if weapon == null or _hero.dead:
		return
	if _bloodlust > 0:
		_bloodlust_left -= delta
		if _bloodlust_left <= 0.0:
			_bloodlust = 0
			weapon.bonus_mult = 1.0
	if worn.has("tremor"):
		_tremor_next -= delta
		if _tremor_next <= 0.0:
			_tremor_next = Talismans.tremor_every(worn.tremor)
			_tremor()


func _roll(id: String) -> bool:
	return worn.has(id) and randf() < Talismans.chance(id, worn[id])


func _power(id: String) -> float:
	return Talismans.power(id, worn.get(id, 1))


## Żywi wrogowie w promieniu `radius` od `at` (krąg spłaszczony jak cień: w pionie połowa).
func _around(at: Vector2, radius: float) -> Array[ProtoTarget]:
	var found: Array[ProtoTarget] = []
	for t: ProtoTarget in weapon.targets:
		if not is_instance_valid(t) or not t.alive():
			continue
		var off := t.global_position - at
		off.y *= 2.0
		if off.length() <= radius:
			found.append(t)
	return found


## Trafienie bronią (ProtoWeapon._deal): efekty „przy trafieniu”, każdy najwyżej raz na Talismans.HIT_GAP s.
func on_hit(t: ProtoTarget) -> void:
	if weapon == null or worn.is_empty() or not is_instance_valid(t):
		return
	var now := _now()
	for id: String in worn:
		if Talismans.trigger_of(id) != "hit" or _hit_ready.get(id, 0.0) > now or not _roll(id):
			continue
		_hit_ready[id] = now + Talismans.HIT_GAP
		var at := t.global_position
		match id:
			"shockwave":
				Fx.once(_world(), ProtoWeapon.SHOCK_FX, 9, 18.0, at, ProtoWeapon.SHOCK_FX_ANCHOR, 6,
						Talismans.SHOCK_RADIUS / ProtoWeapon.SHOCK_FX_RADIUS)
				for e in _around(at, Talismans.SHOCK_RADIUS):
					weapon.aura_hit(e, _power(id), Elements.PHYSICAL, at)
					e.stun(Talismans.SHOCK_STUN)
			"thunder":
				_thunder(t)
			"whirlpool":
				_whirlpool(at)
			"roots":
				Fx.once(_world(), ProtoWeapon.SLAM_SPIKE_FX, ProtoWeapon.SLAM_SPIKE_FRAMES, 24.0, at,
						ProtoWeapon.SLAM_SPIKE_ANCHOR, 6, Talismans.ROOTS_RADIUS / ProtoWeapon.SLAM_SPIKE_RADIUS)
				for e in _around(at, Talismans.ROOTS_RADIUS):
					weapon.aura_hit(e, _power(id), Elements.NATURE, at)
					e.stun(Talismans.roots_time(worn[id]))


## Pierścień Gromu: grom Peruna w trafionego i przeskok na najbliższych wrogów.
func _thunder(first: ProtoTarget) -> void:
	var hit: Array[ProtoTarget] = [first]
	var current := first
	for i in Talismans.THUNDER_CHAIN:
		var best: ProtoTarget = null
		var best_d := Talismans.THUNDER_RANGE
		for e in _around(current.global_position, Talismans.THUNDER_RANGE * 2.0):
			var d := e.global_position.distance_to(current.global_position)
			if not e in hit and d <= best_d:
				best = e
				best_d = d
		if best == null:
			break
		hit.append(best)
		current = best
	for e in hit:
		Fx.once(_world(), ProtoKatana.PERUN_BOLT_FX, ProtoKatana.PERUN_BOLT_FRAMES, 20.0, e.global_position.round(),
				ProtoKatana.PERUN_BOLT_ANCHOR, 22, 0.7)
		weapon.aura_hit(e, _power("thunder"), Elements.LIGHTNING, e.global_position)
		e.shock(2.0)


## Pierścień Topieli: wir w miejscu trafienia - ciągnie wrogów do środka i rani kilka razy.
func _whirlpool(at: Vector2) -> void:
	Fx.once(_world(), ProtoHydrosphere.VORTEX_FX, ProtoHydrosphere.VORTEX_FX_FRAMES, 10.0, at,
			ProtoHydrosphere.VORTEX_FX_ANCHOR, 5, Talismans.WHIRL_RADIUS / ProtoHydrosphere.VORTEX_FX_RADIUS * 0.8)
	for i in Talismans.WHIRL_TICKS:
		if i > 0:
			await get_tree().create_timer(Talismans.WHIRL_TICK, false).timeout
		if weapon == null or not is_instance_valid(weapon):
			return
		for e in _around(at, Talismans.WHIRL_RADIUS):
			e.push_away(at, -Talismans.WHIRL_PULL)
			e.soak(0.2, 2.0)
			weapon.aura_hit(e, _power("whirlpool"), Elements.WATER, at)


## Pokonany potwór (ProtoHorde.monster_died): Szpon Biesa, Serce Goblina, Szczęka Pożeracza.
func on_kill(g: ProtoTarget) -> void:
	if weapon == null or worn.is_empty() or _hero.dead or not is_instance_valid(g):
		return
	var at := g.global_position
	if _roll("bloodlust"):
		_bloodlust = mini(_bloodlust + 1, Talismans.BLOODLUST_STACKS)
		_bloodlust_left = Talismans.BLOODLUST_TIME
		weapon.bonus_mult = 1.0 + _power("bloodlust") * _bloodlust
	if _roll("kaboom"):
		_kaboom.call_deferred(at)  # łańcuch wybuchów idzie klatka po klatce
	if _roll("devour"):
		_hero.heal(maxi(1, roundi(_hero.max_hp * _power("devour"))))
		Fx.once(_world(), ProtoNecromancer.HEAL_FX, 10, 14.0, _hero.global_position + Vector2(0, -18),
				ProtoNecromancer.HEAL_ANCHOR, 21)


func _kaboom(at: Vector2) -> void:
	if weapon == null or not is_instance_valid(weapon):
		return
	Fx.once(_world(), ProtoGlaive.BLAST_FX, 12, 14.0, at.round(), ProtoGlaive.BLAST_FX_ANCHOR, 6,
			Talismans.KABOOM_RADIUS / ProtoGlaive.BLAST_FX_RADIUS)
	for e in _around(at, Talismans.KABOOM_RADIUS):
		weapon.aura_hit(e, _power("kaboom"), Elements.FIRE, at)


## Rana postaci (ProtoHero.hurt): Żołądź Leszego - ciernie wokół postaci.
func on_hurt() -> void:
	if weapon == null or _hero.dead or not _roll("thorns") or _hit_ready.get("thorns", 0.0) > _now():
		return
	_hit_ready["thorns"] = _now() + Talismans.HIT_GAP
	var at := _hero.global_position
	Fx.once(_world(), ProtoWeapon.SLAM_SPIKE_FX, ProtoWeapon.SLAM_SPIKE_FRAMES, 24.0, at, ProtoWeapon.SLAM_SPIKE_ANCHOR,
			6, Talismans.THORNS_RADIUS / ProtoWeapon.SLAM_SPIKE_RADIUS)
	for e in _around(at, Talismans.THORNS_RADIUS):
		weapon.aura_hit(e, _power("thorns"), Elements.NATURE, at)


## Użyta umiejętność (ProtoWeapon.skill_used): Korona Peruna - piorun w najbliższego wroga, siła z pełnej many.
func on_skill(id: String) -> void:
	if weapon == null or not worn.has("archmage") or _hero.dead or weapon.mana_cost(id) <= 0:
		return
	var best: ProtoTarget = null
	var best_d := Talismans.ARCHMAGE_RANGE
	for e in _around(_hero.global_position, Talismans.ARCHMAGE_RANGE * 2.0):
		var d := e.global_position.distance_to(_hero.global_position)
		if d <= best_d:
			best = e
			best_d = d
	if best == null:
		return
	Fx.once(_world(), ProtoKatana.PERUN_BOLT_FX, ProtoKatana.PERUN_BOLT_FRAMES, 20.0, best.global_position.round(),
			ProtoKatana.PERUN_BOLT_ANCHOR, 22)
	weapon.aura_hit(best, Talismans.ARCHMAGE_HIT, Elements.LIGHTNING, _hero.global_position,
			roundi(_hero.max_mana * _power("archmage")))
	best.shock(2.0)


## Serce Głębin: ziemia drży wokół postaci.
func _tremor() -> void:
	var at := _hero.global_position
	Fx.once(_world(), ProtoWeapon.SLAM_FX, ProtoWeapon.SLAM_FX_FRAMES, ProtoWeapon.SLAM_FX_FPS, at,
			ProtoWeapon.SLAM_FX_ANCHOR, 6, Talismans.TREMOR_RADIUS / ProtoWeapon.SLAM_RADIUS)
	for e in _around(at, Talismans.TREMOR_RADIUS):
		weapon.aura_hit(e, _power("tremor"), Elements.EARTH, at)


func _world() -> Node:
	return _hero.get_parent()

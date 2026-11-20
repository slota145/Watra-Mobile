class_name ProtoTalismans
extends Node2D
## Talizmany w walce (Talismans) - dziecko postaci. Arena podaje założone talizmany (`worn`: talizman -> poziom)
## i broń (`weapon`); broń woła `on_hit` przy każdym trafieniu (ProtoWeapon._deal), arena podpina pokonanych
## (`on_kill`, ProtoHorde.monster_died), rany postaci (`on_hurt`, ProtoHero.hurt) i użyte umiejętności (`on_skill`,
## ProtoWeapon.skill_used). Efekty ranią przez ProtoWeapon.aura_hit (bez krytyków i kamieni, więc nie odpalają
## talizmanów ponownie) i używają gotowych animacji gry (fala, grom Peruna, wir, kolce, wybuch, leczenie).

var weapon: ProtoWeapon
## Efekty z kreatora efektów PixelLab (20.11.2026, pixellab_src/vfx/ids.json): korzenie, wieniec cierni, krwawe leczenie.
const ROOTS_FX := preload("res://assets/effects/roots_snare.png")
const ROOTS_ANCHOR := Vector2(29, 35)
const THORNS_FX := preload("res://assets/effects/thorn_burst.png")
const THORNS_ANCHOR := Vector2(41, 45)
const BLOOD_HEAL_FX := preload("res://assets/effects/blood_heal.png")
const BLOOD_HEAL_ANCHOR := Vector2(18, 42)
## Serce Głębin: świecące pęknięcia ziemi i fala (kreator efektów, 20.11.2026 - zamiast kolców uderzenia w ziemię).
const TREMOR_FX := preload("res://assets/effects/earth_tremor.png")
const TREMOR_ANCHOR := Vector2(58, 24)
## Promień fali w klatce efektu (do skalowania do Talismans.TREMOR_RADIUS).
const TREMOR_FX_RADIUS := 55.0
var worn := {}:
	set(v):
		worn = v
		_apply()

var _hero: ProtoHero
var _hit_ready := {}  # talizman -> czas gry, od którego znowu może zadziałać przy trafieniu
var _tremor_next := 0.0
var _bloodlust := 0
var _bloodlust_left := 0.0
## Talizmany z Path of Exile (20.11.2026): czas do końca premii Łuski Żmija, Poroża Jelenia i Świecy Wiedźmy,
## wydana mana (Świeca).
var _overload_left := 0.0
var _onslaught_left := 0.0
var _arcane_left := 0.0
var _mana_spent := 0


func _ready() -> void:
	_hero = get_parent() as ProtoHero
	_hero.mana_spent.connect(_on_mana_spent)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Ustawienia broni i postaci z założonych talizmanów: droższe umiejętności (Kryształ Peruna), ogień zamiast
## fizycznych (Krzesiwo Swaroga), z bliska więcej (Kieł Niedźwiedzia), zdrowie zamiast many (Krwawe Serce),
## mana bierze część ciosów (Nić Mokoszy).
func _apply() -> void:
	if weapon == null:
		return
	weapon.mana_tax = Talismans.archmage_cost(worn["archmage"]) if worn.has("archmage") else 0.0
	weapon.fire_convert = worn.has("avatar")
	weapon.fire_convert_bonus = _power("avatar") if worn.has("avatar") else 0.0
	weapon.point_blank = _power("point_blank") if worn.has("point_blank") else 0.0
	if _hero:
		_hero.blood_magic = _power("blood_magic") if worn.has("blood_magic") else 0.0
		_hero.mana_shield = _power("mom") if worn.has("mom") else 0.0
	if not worn.has("bloodlust"):
		_bloodlust = 0
	_update_buffs()


## Premie na chwilę i zależne od stanu (Czaszka Biesa, Świeca Wiedźmy, Szpon Upiora, Łuska Żmija, Poroże Jelenia):
## mnożnik obrażeń broni, premia żywiołów, szybkość ruchu i ataku, odnowa many.
func _update_buffs() -> void:
	if weapon == null:
		return
	var mult := 1.0 + _power("bloodlust") * _bloodlust if worn.has("bloodlust") else 1.0
	if _arcane_left > 0.0 and worn.has("arcane"):
		mult *= 1.0 + _power("arcane")
	if worn.has("pain") and _hero and _hero.hp < _hero.max_hp * Talismans.PAIN_BELOW:
		mult *= 1.0 + _power("pain")
	weapon.bonus_mult = mult
	weapon.elem_extra = _power("overload") if _overload_left > 0.0 and worn.has("overload") else 0.0
	var rush := _power("onslaught") if _onslaught_left > 0.0 and worn.has("onslaught") else 0.0
	weapon.speed_bonus = rush
	if _hero:
		_hero.move_bonus = rush
		_hero.mana_regen_bonus = Talismans.ARCANE_REGEN if _arcane_left > 0.0 and worn.has("arcane") else 0.0


func _process(delta: float) -> void:
	if weapon == null or _hero.dead:
		return
	if _bloodlust > 0:
		_bloodlust_left -= delta
		if _bloodlust_left <= 0.0:
			_bloodlust = 0
	_overload_left -= delta
	_onslaught_left -= delta
	_arcane_left -= delta
	_update_buffs()
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
	for t: ProtoTarget in weapon.targets_near(at, radius):  # siatka broni (dawniej samo `targets` - bez potworów)
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
					weapon.aura_hit(e, _power(id), Elements.EARTH, at)  # fala jak trzęsienie ziemi - żywioł ziemi
					e.stun(Talismans.SHOCK_STUN)
			"thunder":
				_thunder(t)
			"whirlpool":
				_whirlpool(at)
			"cull":
				if t.alive() and t.health_fraction() < _power(id) * (0.5 if ProtoWeapon._tough(t) else 1.0):
					weapon.execute(t, _hero.global_position)
					_hero.float_text(tr("Cios łaski!"), -46.0, Talismans.color_of(id), 11, 0.8)
			"roots":
				Fx.once(_world(), ROOTS_FX, 14, 16.0, at.round(), ROOTS_ANCHOR, 6, 1.2)
				for e in _around(at, Talismans.ROOTS_RADIUS):
					weapon.aura_hit(e, _power(id), Elements.NATURE, at)
					e.stun(Talismans.roots_time(worn[id]))


## Pióro Gromu: grom Peruna w trafionego i przeskok na najbliższych wrogów.
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


## Perła Topieli: wir w miejscu trafienia - ciągnie wrogów do środka i rani kilka razy.
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


## Pokonany potwór (ProtoHorde.monster_died): Czaszka Biesa, Serce Goblina, Ząb Pożeracza.
func on_kill(g: ProtoTarget) -> void:
	if weapon == null or worn.is_empty() or _hero.dead or not is_instance_valid(g):
		return
	var at := g.global_position
	if _roll("bloodlust"):
		_bloodlust = mini(_bloodlust + 1, Talismans.BLOODLUST_STACKS)
		_bloodlust_left = Talismans.BLOODLUST_TIME
		_update_buffs()
	if _roll("kaboom"):
		_kaboom.call_deferred(at)  # łańcuch wybuchów idzie klatka po klatce
	if _roll("onslaught"):
		_onslaught_left = Talismans.ONSLAUGHT_TIME
		_update_buffs()
	if worn.has("pyre") and g.is_burning():  # Lont Pożogi: ogień przechodzi na sąsiadów
		_pyre.call_deferred(at)
	if _roll("devour"):
		_hero.heal(maxi(1, roundi(_hero.max_hp * _power("devour"))))
		Fx.once(_world(), BLOOD_HEAL_FX, 12, 14.0, _hero.global_position.round(), BLOOD_HEAL_ANCHOR, 21)


func _pyre(at: Vector2) -> void:
	if weapon == null or not is_instance_valid(weapon):
		return
	Fx.once(_world(), ProtoGlaive.BLAST_FX, 12, 18.0, at.round(), ProtoGlaive.BLAST_FX_ANCHOR, 6, 0.8)
	for e in _around(at, Talismans.PYRE_RADIUS):
		e.burn(weapon._roll(_power("pyre")) * weapon.elem_total(), ProtoWeapon.BURN_TIME, weapon.penetration)


## Trafienie krytyczne (ProtoWeapon._deal): Łuska Żmija - premia żywiołów na chwilę.
func on_crit() -> void:
	if worn.has("overload"):
		if _overload_left <= 0.0:
			_hero.float_text(tr("Przeciążenie!"), -46.0, Talismans.color_of("overload"), 11, 0.8)
		_overload_left = Talismans.OVERLOAD_TIME
		_update_buffs()


## Wydana mana (ProtoHero.mana_spent): Świeca Wiedźmy - po ARCANE_MANA premia na chwilę.
func _on_mana_spent(amount: int) -> void:
	if not worn.has("arcane"):
		return
	_mana_spent += amount
	if _mana_spent >= Talismans.ARCANE_MANA:
		_mana_spent = 0
		_arcane_left = Talismans.ARCANE_TIME
		_hero.float_text(tr("Przypływ many!"), -46.0, Talismans.color_of("arcane"), 11, 0.8)
		_update_buffs()


func _kaboom(at: Vector2) -> void:
	if weapon == null or not is_instance_valid(weapon):
		return
	Fx.once(_world(), ProtoGlaive.BLAST_FX, 12, 14.0, at.round(), ProtoGlaive.BLAST_FX_ANCHOR, 6,
			Talismans.KABOOM_RADIUS / ProtoGlaive.BLAST_FX_RADIUS)
	for e in _around(at, Talismans.KABOOM_RADIUS):
		weapon.aura_hit(e, _power("kaboom"), Elements.FIRE, at)


## Rana postaci (ProtoHero.hurt): Kora Leszego - ciernie wokół postaci.
func on_hurt() -> void:
	if weapon == null or _hero.dead or not _roll("thorns") or _hit_ready.get("thorns", 0.0) > _now():
		return
	_hit_ready["thorns"] = _now() + Talismans.HIT_GAP
	var at := _hero.global_position
	Fx.once(_world(), THORNS_FX, 16, 20.0, at.round(), THORNS_ANCHOR, 6, 1.2)
	for e in _around(at, Talismans.THORNS_RADIUS):
		weapon.aura_hit(e, _power("thorns"), Elements.NATURE, at)


## Użyta umiejętność (ProtoWeapon.skill_used): Kryształ Peruna - piorun w najbliższego wroga, siła z pełnej many.
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
	Fx.once(_world(), TREMOR_FX, 9, 14.0, at.round(), TREMOR_ANCHOR, -1, Talismans.TREMOR_RADIUS / TREMOR_FX_RADIUS)
	for e in _around(at, Talismans.TREMOR_RADIUS):
		weapon.aura_hit(e, _power("tremor"), Elements.EARTH, at)


func _world() -> Node:
	return _hero.get_parent()

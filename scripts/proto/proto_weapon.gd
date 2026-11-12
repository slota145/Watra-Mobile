class_name ProtoWeapon
extends Node2D
## Lewitujący miecz z prototypu. Poza walką unosi się za ramieniem postaci (lekko się kołysze i dogania ją
## z opóźnieniem). Dopóki gracz trzyma przycisk ataku (`attack_held`), miecz co chwilę wskakuje na orbitę wokół postaci - rękojeścią do niej,
## ostrzem na zewnątrz - i tnie po łuku w stronę najbliższej kukły w zasięgu (bez kukły - przed siebie), a nad łukiem gra efekt cięcia ze zwykłego ataku Watry
## (assets/effects/sword_slash.png z kreatora efektów PixelLab). Kolejne cięcia na przemian z góry i z dołu.
## Auto atak (`auto_attack`, ustawienie w pauzie): cios sam rusza, gdy cel jest w zasięgu - tylko podstawowy atak.
## Obrażenia rosną z poziomem postaci i premiami przedmiotów (`damage_mult`), założona broń zmienia obrażenia cięcia
## (`damage`), a premia szybkości ataku przyspiesza cały cios (`speed_mult`).
## Węzeł stoi na ziemi (sortowanie po Y z postacią i kukłą), a obrazek miecza wisi wyżej (ujemne _sprite.position.y).
## Umiejętności (Skills, `cast` z małych przycisków albo `main_skill` pod dużym przyciskiem): Młynek (miecz wiruje
## wokół postaci), Rzut mieczem (leci, przebija, wraca), Rozłupanie Ziemi (spada z góry, ogłusza), Mgnienie
## (jak w Watrze: dopóki gracz trzyma przycisk - `flicker_held` - postać przeskakuje na wylot przez najbliższego
## wroga, tnąc wszystkich po drodze i wokół celu, potem przez kolejnego, za manę za każdy skok). Każda kosztuje manę (ProtoHero.spend_mana) i ma odnowienie (`cooldown_left`).
## Umiejętność pod dużym przyciskiem rusza przy trzymaniu albo z auto atakiem; bez many lub w czasie odnowienia
## miecz tnie zwykłym ciosem. Umiejętność stuknięta w trakcie innego ruchu miecza czeka w kolejce (`_queued`).

const TEXTURE := preload("res://assets/watra/iron_sword.png")
## Punkt chwytu na obrazku miecza (rękojeść) - wokół niego miecz się obraca.
const GRIP := Vector2(9.5, 10.0)
const SCALE := 0.5
## Długość ostrza po przeskalowaniu (od chwytu do czubka, (61 - 9.5) * 0.5).
const BLADE := 26.0
## Środek orbity: tyle pikseli nad stopami postaci.
const ORBIT_HEIGHT := 12.0
## Rękojeść krąży w tej odległości od środka postaci (miecz lewituje, nie jest w dłoni), czubek ostrza - o BLADE dalej.
const HILT_RADIUS := 14.0
## Szerokość łuku cięcia (jak żelazny miecz w Watrze: 160 stopni).
const ARC := deg_to_rad(160.0)
## Zasięg celowania: cięcie idzie w stronę kukły bliższej niż tyle (stopy-stopy).
const REACH := 48.0
const COOLDOWN := 0.55
const WINDUP := 0.12
## Czas cięcia (jak attack_duration w Watrze).
const SWING := 0.18
const RECOVER := 0.08
const HOVER_HEIGHT := 22.0
const DAMAGE := Vector2i(14, 20)
const SLASH_FX := preload("res://assets/effects/sword_slash.png")
const SLASH_FRAMES := 5
## Promień półksiężyca w klatce efektu (px) - efekt skalujemy tak, żeby łuk pokrywał się z czubkiem ostrza.
const SLASH_FX_RADIUS := 29.0
## Efekt trafienia z kreatora PixelLab (pixellab_src/vfx/ids.json: sword_hit).
const HIT_FX := preload("res://assets/effects/sword_hit.png")
const HIT_FX_FRAMES := 12
const HIT_FX_FPS := 20.0
const HIT_FX_ANCHOR := Vector2(23, 17)

## Młynek: czas, prędkość obrotu (obroty na sekundę), co ile sekund trafia i promień trafień od środka postaci.
const WHIRL_TIME := 3.0
const WHIRL_SPIN := 2.2
const WHIRL_TICK := 0.3
const WHIRL_RADIUS := HILT_RADIUS + BLADE + 8.0
const WHIRL_FX := preload("res://assets/effects/whirl.png")
const WHIRL_FX_FRAMES := 8
const WHIRL_FX_FPS := 20.0
## Promień wiru w klatce efektu (jak w Watrze) - efekt skalujemy do WHIRL_RADIUS.
const WHIRL_FX_RADIUS := 35.0
## Rzut mieczem: zasięg lotu, prędkość tam i z powrotem, odległość trafienia od ostrza.
const THROW_DISTANCE := 130.0
const THROW_SPEED := 300.0
const THROW_RETURN := 340.0
const THROW_HIT := 16.0
## Rozłupanie Ziemi: wzlot nad cel, spadek, wysokość wzlotu, promień fali i ogłuszenie.
const SLAM_RISE := 0.25
const SLAM_FALL := 0.09
const SLAM_STUCK := 0.3
const SLAM_HEIGHT := 64.0
const SLAM_RADIUS := 46.0
const SLAM_STUN := 1.2
const SLAM_FX := preload("res://assets/effects/ground_slam.png")
const SLAM_FX_FRAMES := 10
const SLAM_FX_FPS := 15.0
const SLAM_FX_ANCHOR := Vector2(26, 35)
## Mgnienie (liczby z Watry, zasięg mniejszy - węższy ekran telefonu): zasięg skoku, odstęp między skokami
## przy trzymaniu, jak daleko za celem ląduje postać, szerokość pasa cięcia wzdłuż drogi i promień cięcia wokół celu.
const FLICKER_RANGE := 150.0
const FLICKER_INTERVAL := 0.32
const FLICKER_OVERSHOOT := 18.0
const FLICKER_PATH_WIDTH := 12.0
const FLICKER_HIT_RADIUS := 30.0
## Efekty Mgnienia z Watry (kreator efektów PixelLab): smuga od miejsca startu (rysowana w prawo, długość w klatce
## FLICKER_TRAIL_LENGTH) i cięcie na celu ukośnie do drogi skoku.
const FLICKER_TRAIL := preload("res://assets/effects/flicker_trail.png")
const FLICKER_TRAIL_ANCHOR := Vector2(8, 10)
const FLICKER_TRAIL_LENGTH := 64.0
const FLICKER_SLASH := preload("res://assets/effects/flicker_hit.png")
const FLICKER_SLASH_ANCHOR := Vector2(43, 16)
const FLICKER_SLASH_TILT := 0.6
const FLICKER_FX_FPS := 16.0

## Umiejętności nie dało się użyć (`reason`: "mana" - brak many, "cooldown" - jeszcze się odnawia,
## "target" - Mgnienie bez wroga w zasięgu).
signal cast_failed(id: String, reason: String)
## Użyto umiejętności (zapłacono manę, ruszyło odnowienie).
signal skill_used(id: String)

## Grupa węzłów, które miecz sam znajduje jako cele (potwory Hordy).
const TARGETS := &"proto_targets"

var hero: ProtoHero
## Czy gracz trzyma przycisk ataku.
var attack_held := false
## Auto atak: tnie sam, gdy jakiś cel jest bliżej niż REACH.
var auto_attack := false
## Mnożnik obrażeń z poziomu postaci.
var damage_mult := 1.0
## Obrażenia jednego cięcia (od-do) przed mnożnikiem - zwykły miecz albo założona broń.
var damage := DAMAGE
## Mnożnik szybkości ataku (rozbieg, cięcie, powrót i odpoczynek trwają tyle razy krócej).
var speed_mult := 1.0
## Czy gracz trzyma przycisk Mgnienia (skoki co FLICKER_INTERVAL, dopóki starcza many).
var flicker_held := false
## Umiejętność pod dużym przyciskiem (Skills; zwykły cios - Skills.STRIKE).
var main_skill := Skills.STRIKE
## Cele do bicia (kukły, potwory). Arena dopisuje je przy starcie, potwory dopisują się same w grupie TARGETS.
var targets: Array[ProtoTarget] = []

var _state := "follow"
var _t := 0.0
var _cooldown := 0.3
var _aim := 0.0  # kąt w stronę celu
var _sign := -1.0  # kierunek cięcia: +1 zgodnie z ruchem wskazówek zegara, -1 przeciwnie
var _hit_done := false
var _from_pos := Vector2.ZERO
var _from_sprite := Vector2.ZERO
var _from_rot := 0.0
var _clock := 0.0
var _sprite: Sprite2D
var _slash: Sprite2D
## Odnowienia umiejętności: id -> ile sekund zostało.
var _cd := {}
## Umiejętność stuknięta w trakcie innego ruchu miecza (rusza, gdy miecz wróci).
var _queued := ""
## Młynek: kąt obrotu i czas do następnego trafienia.
var _spin := 0.0
var _tick := 0.0
var _whirl_fx: Sprite2D
## Rzut i Rozłupanie: punkt na ziemi (cel), kierunek lotu, cele trafione w tym przelocie.
var _goal := Vector2.ZERO
var _dir := Vector2.RIGHT
var _hit_set: Array = []
## Mgnienie: czas do następnego skoku, jeden skok po samym stuknięciu, poprzedni cel (skacze się przez innego).
var _flicker_timer := 0.0
var _flicker_once := false
var _last_target: ProtoTarget


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(0.7, 0.7)
	shadow.modulate.a = 0.6
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.centered = false
	_sprite.offset = -GRIP
	_sprite.scale = Vector2.ONE * SCALE
	add_child(_sprite)
	_slash = Sprite2D.new()
	_slash.texture = SLASH_FX
	_slash.hframes = SLASH_FRAMES
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) / SLASH_FX_RADIUS
	_slash.z_index = 5
	_slash.visible = false
	add_child(_slash)
	_whirl_fx = Sprite2D.new()
	_whirl_fx.texture = WHIRL_FX
	_whirl_fx.hframes = WHIRL_FX_FRAMES
	_whirl_fx.scale = Vector2.ONE * WHIRL_RADIUS / WHIRL_FX_RADIUS
	_whirl_fx.modulate.a = 0.85
	_whirl_fx.z_index = 4
	_whirl_fx.visible = false
	add_child(_whirl_fx)
	if hero:
		position = _follow_spot()


func _process(delta: float) -> void:
	_clock += delta
	_cooldown -= delta * speed_mult
	_t += delta * speed_mult
	for id in _cd:
		_cd[id] = maxf(_cd[id] - delta, 0.0)
	if hero.dead and _state != "follow":
		_end_skill()
	_process_flicker(delta)
	match _state:
		"follow":
			_follow(delta)
			if hero.dead:
				pass
			elif _queued != "":
				var q := _queued
				_queued = ""
				_start(q)
			elif _cooldown <= 0.0:
				var main_ok := main_skill != Skills.STRIKE and can_use(main_skill)
				var main_range: float = Skills.DATA[main_skill].range if Skills.has(main_skill) else REACH
				if main_ok and (attack_held or (auto_attack and _nearest(main_range) != null)):
					_start(main_skill)
				elif attack_held or (auto_attack and _nearest() != null):
					_attack()
		"whirl":
			_process_whirl(delta)
		"throw", "throw_back":
			_process_throw(delta)
		"slam_rise", "slam_fall", "slam_stuck":
			_process_slam()
		"windup":
			# miecz wskakuje na orbitę, na początek łuku (odrobinę dalej - zamach)
			var k := ease(clampf(_t / WINDUP, 0.0, 1.0), -2.0)
			var a := _angle_at(-0.1)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= WINDUP:
				_set_state("swing")
				_slash.visible = true
		"swing":
			var progress := clampf(_t / SWING, 0.0, 1.0)
			_place(_angle_at(ease(progress, 0.5)))  # jak w Watrze: szybki start, hamowanie pod koniec
			_slash.frame = mini(int(progress * SLASH_FRAMES), SLASH_FRAMES - 1)
			if not _hit_done and progress >= 0.5:
				_hit_done = true
				_hit_in_arc()
			if _t >= SWING:
				_slash.visible = false
				_set_state("recover")
		"recover":
			_place(_angle_at(1.0))
			if _t >= RECOVER:
				_set_state("follow")
				_cooldown = COOLDOWN


## Miejsce obok postaci, za jej ramieniem (od strony przeciwnej do kierunku patrzenia).
func _follow_spot() -> Vector2:
	var side := -1.0 if hero.facing.x >= 0.0 else 1.0
	return hero.position + Vector2(side * 12.0, 3.0)


func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	_sprite.position = _sprite.position.lerp(Vector2(0, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0)), k)
	# ostrze w górę, lekko pochylone w stronę patrzenia, z delikatnym kołysaniem
	var side := 1.0 if hero.facing.x >= 0.0 else -1.0
	var rest := -PI / 2.0 + 0.35 * side + 0.06 * sin(_clock * 2.1)
	_sprite.rotation = lerp_angle(_sprite.rotation, rest, k)


## Najbliższy cel bliżej niż `reach` (domyślnie zasięg ciosu; null - żadnego).
func _nearest(reach := REACH) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := reach
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


func _attack() -> void:
	var best := _nearest()
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign  # kolejne cięcia na przemian
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Kąt ostrza w chwili `k` cięcia (0 - początek łuku, 1 - koniec; poza 0..1 - przed i za łukiem).
func _angle_at(k: float) -> float:
	return _aim + lerpf(-ARC / 2.0, ARC / 2.0, k) * _sign


## Środek orbity w świecie (postać, na wysokości pasa).
func _orbit_center() -> Vector2:
	return hero.global_position + Vector2(0, -ORBIT_HEIGHT)


## Ustawia miecz na orbicie: ostrze pod kątem `a`, rękojeść do postaci. Węzeł stoi pod postacią,
## odrobinę za nią, gdy ostrze wskazuje w górę (wtedy miecz rysuje się za postacią). Efekt cięcia jedzie z postacią.
func _place(a: float) -> void:
	position = hero.position + Vector2(0, -1.0 if sin(a) < -0.2 else 1.0)
	var center := _orbit_center() - global_position
	_sprite.position = center + Vector2.from_angle(a) * HILT_RADIUS
	_sprite.rotation = a
	_slash.position = center
	_slash.rotation = _aim
	_slash.flip_v = _sign < 0.0


## Trafienie: wszystkie kukły w zasięgu ostrza i w łuku cięcia; na każdej błysk z iskrami.
func _hit_in_arc() -> void:
	var hit := false
	for t in _live_targets():
		var to := t.center() - _orbit_center()
		if to.length() <= HILT_RADIUS + BLADE + 6.0 and absf(angle_difference(_aim, to.angle())) <= ARC / 2.0:
			t.take_damage(_roll(), hero.global_position)
			# błysk tam, gdzie ostrze przecina kukłę (na linii od postaci, nie dalej niż czubek)
			var at := _orbit_center() + to.limit_length(HILT_RADIUS + BLADE * 0.8)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, at.round(), HIT_FX_ANCHOR)
			hit = true
	if hit:
		Input.vibrate_handheld(15)


## Cele, które da się jeszcze trafić: lista `targets` i potwory z grupy TARGETS.
func _live_targets() -> Array[ProtoTarget]:
	var all: Array = targets.duplicate()
	all.append_array(get_tree().get_nodes_in_group(TARGETS))
	var out: Array[ProtoTarget] = []
	for t in all:
		if is_instance_valid(t) and t is ProtoTarget and t.alive() and not out.has(t):
			out.append(t)
	return out


func _set_state(state: String) -> void:
	_state = state
	_t = 0.0


## Obrażenia jednego trafienia: zwykłe cięcie razy `power` (mnożnik umiejętności).
func _roll(power := 1.0) -> int:
	return maxi(1, roundi(randi_range(damage.x, damage.y) * damage_mult * power))


## Ile sekund odnowienia zostało umiejętności `id` (0 - gotowa).
func cooldown_left(id: String) -> float:
	return _cd.get(id, 0.0)


## Czy umiejętność da się teraz użyć (odnowiona i starcza many).
func can_use(id: String) -> bool:
	return Skills.has(id) and cooldown_left(id) <= 0.0 and hero.mana >= Skills.mana_of(id) and not hero.dead


## Użycie umiejętności z małego przycisku. W trakcie innego ruchu miecza czeka w kolejce. Zwraca false (i wysyła
## `cast_failed`), gdy się odnawia albo brakuje many.
func cast(id: String) -> bool:
	if not Skills.has(id) or hero.dead:
		return false
	if cooldown_left(id) > 0.0:
		cast_failed.emit(id, "cooldown")
		return false
	if hero.mana < Skills.mana_of(id):
		cast_failed.emit(id, "mana")
		return false
	if id == "blink":
		if _flicker_target() == null:
			cast_failed.emit(id, "target")
			return false
		_flicker_once = true  # stuknięcie bez trzymania - jeden skok
		_process_flicker(0.0)
		return true
	if _state == "follow" and (id != Skills.STRIKE or _cooldown <= 0.0):
		_start(id)
	else:
		_queued = id
	return true


## Rusza umiejętność: płaci manę, włącza odnowienie i ustawia ruch miecza.
func _start(id: String) -> void:
	if not can_use(id):
		return
	if id == Skills.STRIKE:
		_attack()
		return
	if not hero.spend_mana(Skills.mana_of(id)):
		return
	_cd[id] = Skills.cooldown_of(id)
	_hit_done = false
	_slash.visible = false
	match id:
		"whirl":
			_spin = (_sprite.global_position - _orbit_center()).angle()
			_tick = 0.0
			_whirl_fx.visible = true
			_set_state("whirl")
		"throw":
			var best := _nearest(Skills.DATA.throw.range)
			_dir = (best.global_position - hero.global_position).normalized() if best else hero.facing.normalized()
			if _dir == Vector2.ZERO:
				_dir = Vector2.RIGHT
			_goal = hero.position + _dir * THROW_DISTANCE
			position = hero.position
			_sprite.position = Vector2(0, -ORBIT_HEIGHT)
			_hit_set = []
			hero.play_gesture(hero.global_position + _dir * 20.0)
			_set_state("throw")
		"slam":
			var best := _nearest(Skills.DATA.slam.range)
			_goal = best.position if best else hero.position + hero.facing.normalized() * 30.0
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			hero.play_gesture(_goal)
			_set_state("slam_rise")
	skill_used.emit(id)


## Młynek: miecz krąży wokół postaci (rękojeścią do niej), co WHIRL_TICK rani wszystkich w promieniu.
func _process_whirl(delta: float) -> void:
	_spin += TAU * WHIRL_SPIN * delta
	_place(_spin)
	_whirl_fx.position = _orbit_center() - global_position
	_whirl_fx.frame = int(_clock * WHIRL_FX_FPS) % WHIRL_FX_FRAMES
	_tick -= delta
	if _tick <= 0.0:
		_tick = WHIRL_TICK
		var hit := false
		for t in _live_targets():
			if t.center().distance_to(_orbit_center()) <= WHIRL_RADIUS:
				t.take_damage(_roll(Skills.DATA.whirl.power), hero.global_position)
				hit = true
		if hit:
			Input.vibrate_handheld(8)
	if _t >= WHIRL_TIME * speed_mult:  # _t rośnie szybciej z premią szybkości ataku - czas Młynka nie
		_end_skill()


## Rzut mieczem: lot po prostej do THROW_DISTANCE i powrót do postaci; każdy cel trafiony raz w każdą stronę.
func _process_throw(delta: float) -> void:
	_sprite.rotation += TAU * 3.0 * delta
	var target := _goal if _state == "throw" else hero.position
	var speed := THROW_SPEED if _state == "throw" else THROW_RETURN
	position = position.move_toward(target, speed * delta)
	var tip := _sprite.global_position
	for t in _live_targets():
		if not _hit_set.has(t) and t.center().distance_to(tip) <= THROW_HIT + t.center_height * 0.5:
			_hit_set.append(t)
			t.take_damage(_roll(Skills.DATA.throw.power), global_position - _dir * 10.0)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, tip.round(), HIT_FX_ANCHOR)
			Input.vibrate_handheld(12)
	if position.distance_to(target) < 2.0:
		if _state == "throw":
			_hit_set = []
			_dir = -_dir
			_set_state("throw_back")
		else:
			_end_skill()


## Rozłupanie Ziemi: miecz wznosi się nad cel ostrzem w dół, spada, fala rani i ogłusza, chwilę tkwi w ziemi.
func _process_slam() -> void:
	match _state:
		"slam_rise":
			var k := ease(clampf(_t / SLAM_RISE, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(_goal, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -SLAM_HEIGHT), k)
			_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
			if _t >= SLAM_RISE:
				_set_state("slam_fall")
		"slam_fall":
			var k := clampf(_t / SLAM_FALL, 0.0, 1.0)
			_sprite.position = Vector2(0, lerpf(-SLAM_HEIGHT, -BLADE + 4.0, k * k))
			if _t >= SLAM_FALL:
				_slam_hit()
				_set_state("slam_stuck")
		"slam_stuck":
			if _t >= SLAM_STUCK:
				_end_skill()


func _slam_hit() -> void:
	for t in _live_targets():
		var d := t.global_position - global_position
		if Vector2(d.x, d.y * 1.6).length() <= SLAM_RADIUS:
			t.take_damage(_roll(Skills.DATA.slam.power), global_position)
			t.stun(SLAM_STUN)
	Fx.once(get_parent(), SLAM_FX, SLAM_FX_FRAMES, SLAM_FX_FPS, global_position, SLAM_FX_ANCHOR, 6, 1.3)
	Input.vibrate_handheld(40)
	var cam := hero.get_viewport().get_camera_2d()
	if cam:
		var shake := cam.create_tween()
		for i in 4:
			shake.tween_property(cam, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.03)
		shake.tween_property(cam, "offset", Vector2.ZERO, 0.03)


## Mgnienie przy trzymaniu przycisku (albo jeden skok po stuknięciu): skok co FLICKER_INTERVAL, dopóki starcza many
## i jest wróg w zasięgu. Nie w czasie Młynka, Rzutu i Rozłupania (miecz jest zajęty) - wtedy czeka.
func _process_flicker(delta: float) -> void:
	_flicker_timer -= delta
	if not (flicker_held or _flicker_once) or _flicker_timer > 0.0 or hero.dead:
		return
	if not _state in ["follow", "windup", "swing", "recover"]:
		return
	_flicker_once = false
	if hero.mana < Skills.mana_of("blink"):
		cast_failed.emit("blink", "mana")
		_flicker_timer = 0.3
		return
	var best := _flicker_target()
	if best == null:
		cast_failed.emit("blink", "target")
		_flicker_timer = 0.3
		return
	hero.spend_mana(Skills.mana_of("blink"))
	_flicker_jump(best)
	_flicker_timer = FLICKER_INTERVAL / speed_mult
	skill_used.emit("blink")


## Najbliższy wróg w zasięgu Mgnienia; poprzedni cel tylko wtedy, gdy nie ma innego (null - nikogo).
func _flicker_target() -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := INF
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d > FLICKER_RANGE:
			continue
		if t == _last_target:
			d += FLICKER_RANGE
		if d < best_d:
			best = t
			best_d = d
	return best


## Skok na wylot przez `best`: postać ląduje za nim (na przedłużeniu skoku), smuga od miejsca startu, cięcie na celu;
## rani wszystkich w pasie wzdłuż drogi i wokół celu. Miecz tnie po łuku w stronę skoku.
func _flicker_jump(best: ProtoTarget) -> void:
	var from := hero.global_position
	var through := (best.global_position - from).normalized()
	if through == Vector2.ZERO:
		through = hero.facing.normalized()
	var spot := hero.teleport(best.global_position + through * FLICKER_OVERSHOOT)
	_last_target = best
	var travel := spot - from
	var body := Vector2(0, -ORBIT_HEIGHT)
	var trail := Fx.once(get_parent(), FLICKER_TRAIL, 7, FLICKER_FX_FPS, from + body, FLICKER_TRAIL_ANCHOR)
	trail.rotation = travel.angle()
	trail.scale = Vector2.ONE * maxf(0.5, (travel.length() - 8.0) / FLICKER_TRAIL_LENGTH)
	var cut := Fx.once(get_parent(), FLICKER_SLASH, 8, FLICKER_FX_FPS, best.center(), FLICKER_SLASH_ANCHOR)
	cut.rotation = travel.angle() + FLICKER_SLASH_TILT * (1.0 if randf() < 0.5 else -1.0)
	for t in _live_targets():
		var c := t.center()
		var on_path := Geometry2D.get_closest_point_to_segment(c, from + body, spot + body).distance_to(c) \
				<= FLICKER_PATH_WIDTH + t.center_height * 0.5
		if on_path or c.distance_to(best.center()) <= FLICKER_HIT_RADIUS:
			t.take_damage(_roll(Skills.DATA.blink.power), spot)
	Input.vibrate_handheld(20)
	if _state != "follow":
		_slash.visible = false
	_aim = travel.angle()
	_sign = -_sign
	_hit_done = true  # cięcie już zadane wzdłuż drogi
	_set_state("swing")
	_slash.visible = true


## Koniec umiejętności: miecz wraca za ramię (zwykły ruch śledzenia), krótka przerwa przed kolejnym ciosem.
func _end_skill() -> void:
	_whirl_fx.visible = false
	_slash.visible = false
	_set_state("follow")
	_cooldown = maxf(_cooldown, COOLDOWN * 0.5)


## Tryb deweloperski i testy: zeruje odnowienia.
func reset_cooldowns() -> void:
	_cd.clear()

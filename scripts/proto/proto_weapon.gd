class_name ProtoWeapon
extends Node2D
## Lewitujący miecz z prototypu. Poza walką unosi się za ramieniem postaci (lekko się kołysze i dogania ją
## z opóźnieniem). Dopóki gracz trzyma przycisk ataku (`attack_held`), miecz co chwilę wskakuje na orbitę wokół postaci - rękojeścią do niej,
## ostrzem na zewnątrz - i tnie po łuku w stronę najbliższej kukły w zasięgu (bez kukły - przed siebie), a nad łukiem gra efekt cięcia ze zwykłego ataku Watry
## (assets/effects/sword_slash.png z kreatora efektów PixelLab). Kolejne cięcia na przemian z góry i z dołu.
## Węzeł stoi na ziemi (sortowanie po Y z postacią i kukłą), a obrazek miecza wisi wyżej (ujemne _sprite.position.y).

const TEXTURE := preload("res://assets/watra/iron_sword.png")
## Punkt chwytu na obrazku miecza (rękojeść) - wokół niego miecz się obraca.
const GRIP := Vector2(9.5, 10.0)
const SCALE := 0.5
## Długość ostrza po przeskalowaniu (od chwytu do czubka, (61 - 9.5) * 0.5).
const BLADE := 26.0
## Środek orbity: tyle pikseli nad stopami postaci.
const ORBIT_HEIGHT := 12.0
## Rękojeść krąży w tej odległości od środka postaci, czubek ostrza - o BLADE dalej.
const HILT_RADIUS := 8.0
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

var hero: ProtoHero
## Czy gracz trzyma przycisk ataku.
var attack_held := false
## Cele do bicia (kukły). Arena dopisuje je przy starcie.
var targets: Array[ProtoDummy] = []

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
	if hero:
		position = _follow_spot()


func _process(delta: float) -> void:
	_clock += delta
	_cooldown -= delta
	_t += delta
	match _state:
		"follow":
			_follow(delta)
			if _cooldown <= 0.0 and attack_held:
				_attack()
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


func _attack() -> void:
	var best: ProtoDummy = null
	var best_d := REACH
	for t in targets:
		var d := hero.global_position.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
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


## Trafienie: wszystkie kukły w zasięgu ostrza i w łuku cięcia.
func _hit_in_arc() -> void:
	var hit := false
	for t in targets:
		var to := t.center() - _orbit_center()
		if to.length() <= HILT_RADIUS + BLADE + 6.0 and absf(angle_difference(_aim, to.angle())) <= ARC / 2.0:
			t.take_damage(randi_range(DAMAGE.x, DAMAGE.y), hero.global_position)
			hit = true
	if hit:
		Input.vibrate_handheld(15)


func _set_state(state: String) -> void:
	_state = state
	_t = 0.0

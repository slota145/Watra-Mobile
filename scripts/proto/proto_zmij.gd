class_name ProtoZmij
extends ProtoChief
## Żmij Gorynycz - boss szczytowy (Pinnacles, ustalenia z autorem 22.11.2026). Trójgłowy ognisty smok z Watry
## (scripts/world_boss.gd, grafika assets/watra/bosses/zmij*.png z tools/zmij_art.py: 8 klatek machania skrzydłami,
## widok z przodu - bez obracania). Walka sam na sam na Pogorzelisku (arena.gd z Game.pinnacle_key). Reszta (pasek
## zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Ataki z ostrzeżeniem na ziemi, żywioł ogień:
## - Zionięcie: czerwony wachlarz w stronę postaci (BREATH_RANGE, BREATH_ARC), po BREATH_WARN s ogień - rani,
##   podpala i zostawia BREATH_PATCHES płonącej ziemi (ProtoFirePatch); od 2. fazy zaraz potem drugie zionięcie
##   w przeciwną stronę (BREATH_SECOND_WARN);
## - Trzy Głowy: kule ognia spadają w koła - pierwsze pod postacią, reszta obok (2 + faza kul), ranią i podpalają;
## - Uderzenie: koło pod postacią, smok podskakuje i ląduje w nim (JUMP_TIME s) - rani i trzęsie ekranem; w 3. fazie
##   wokół miejsca lądowania wyrasta krąg PILLARS ognistych słupów (zostawiają płonącą ziemię).
## Fazy (odcinanie głów): przy PHASES zdrowia gaśnie głowa (grafika ze zwęgloną głową, ognisty słup na niej, ryk,
## wstrząs, sygnał `phase_changed` - arena pokazuje napis) i przez RAGE_TIME s smok nie atakuje.

signal phase_changed(phase: int)

const SHEETS: Array[Texture2D] = [preload("res://assets/watra/bosses/zmij.png"),
		preload("res://assets/watra/bosses/zmij_2.png"), preload("res://assets/watra/bosses/zmij_1.png")]
const FRAMES := 8
const FLAP_FPS := 8.0
const FLAP_FPS_ATTACK := 13.0
## Skala arkusza (klatka 160 px) i przesunięcie, żeby łapy stały na pozycji węzła.
const SPRITE_SCALE := 0.8
const SPRITE_OFFSET := Vector2(0, -68)
## Gdzie są boczne głowy (względem stóp, już w skali) - tam wybucha słup ognia, gdy gasną.
const HEAD_SPOTS: Array[Vector2] = [Vector2(-28, -90), Vector2(25, -90)]
const MOUTH_HEIGHT := 70.0
const ZMIJ_HP := 2600
const ZMIJ_SPEED := 22.0
const KEEP_DISTANCE := 70.0
const ATTACK_RANGE := 230.0
const PHASES: Array[float] = [0.66, 0.33]
const RAGE_TIME := 1.6
const BREATH_RANGE := 130.0
const BREATH_ARC := 1.2
const BREATH_WARN := 1.0
const BREATH_SECOND_WARN := 0.7
const BREATH_DAMAGE := 30
const BREATH_PATCHES := 5
const BALL_RADIUS := 22.0
const BALL_WARN := 1.1
const BALL_DAMAGE := 24
const BALL_SPREAD := Vector2(32, 75)
const JUMP_RADIUS := 50.0
const JUMP_WARN := 0.8
const JUMP_TIME := 0.6
const JUMP_HEIGHT := 50.0
const JUMP_DAMAGE := 34
const PILLARS := 8
const PILLAR_RING := 70.0
const PATCH_RADIUS := 16.0
const PATCH_TIME := 3.5
const BURN := 5
const BURN_TIME := 3.0
## Efekty z Watry (kreator efektów PixelLab; liczby z pixellab_src/vfx/ids.json Watry).
const FX_BREATH := preload("res://assets/watra/effects/zmij_breath.png")
const FX_BREATH_FRAMES := 8
const FX_BREATH_ANCHOR := Vector2(4, 25)
const FX_BREATH_LENGTH := 100.0
const FX_BALL := preload("res://assets/watra/effects/zmij_fireball.png")
const FX_BALL_FRAMES := 14
const FX_BALL_FPS := 18.0
const FX_BALL_ANCHOR := Vector2(54, 115)
## Kula spada 4 klatki, zanim wybuchnie - animacja rusza tyle przed obrażeniami.
const FX_BALL_LEAD := 4.0 / FX_BALL_FPS
const FX_BALL_SIZE := 0.5
const FX_SLAM_Z := preload("res://assets/watra/effects/zmij_slam.png")
const FX_SLAM_FRAMES := 12
const FX_SLAM_ANCHOR := Vector2(118, 86)
const FX_SLAM_RADIUS := 95.0
const FX_PILLAR := preload("res://assets/watra/effects/zmij_pillar.png")
const FX_PILLAR_FRAMES := 11
const FX_PILLAR_ANCHOR := Vector2(87, 124)
const ATTACKS: Array[String] = ["breath", "balls", "jump"]

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false
## Faza walki 1-3 (ile głów zgasło + 1).
var phase := 1
var _last_attack := ""
var _flap := 0.0
var _aim := Vector2.DOWN
var _second := false
var _balls: Array[ProtoTelegraph] = []
var _jump_from := Vector2.ZERO
var _jump_to := Vector2.ZERO


func _init() -> void:
	base_hp = ZMIJ_HP
	keep_distance = KEEP_DISTANCE
	move_speed = ZMIJ_SPEED


func _ready() -> void:
	super()
	center_height = 48.0
	var shadow := get_child(0) as Sprite2D  # cień Wodza - smok jest dużo szerszy
	if shadow:
		shadow.scale = Vector2(4.2, 2.6)


## Arkusz Żmija z Watry zamiast modelu SpriteKiln (ten sam „udawany model” co orzeł).
func _make_sprite() -> Node2D:
	var s := ProtoStormEagle._EagleSprite.new()
	s.texture = SHEETS[0]
	s.hframes = FRAMES
	s.scale = Vector2.ONE * SPRITE_SCALE
	s.offset = SPRITE_OFFSET / SPRITE_SCALE
	return s


## Wejście: spada z góry w słupie ognia, niski ryk.
func _enter() -> void:
	super()
	_sound(ROAR_SOUND, 0.0, 0.55)
	Fx.once(get_parent(), FX_PILLAR, FX_PILLAR_FRAMES, 16.0, global_position, FX_PILLAR_ANCHOR, 20, 0.7)


func _face(_dir: Vector2) -> void:
	pass  # widok z przodu - smok się nie obraca


func _process(delta: float) -> void:
	super(delta)
	_animate(delta)
	_update_balls()
	if state == "dead" or hero == null:
		return
	match state:
		"breath":
			if _timer >= (BREATH_SECOND_WARN if _second else BREATH_WARN):
				_breath_hit()
		"balls":
			if _timer >= BALL_WARN + 0.1 and _balls.is_empty():
				_set_state("recover")
		"jump_warn":
			if _timer >= JUMP_WARN:
				_jump_from = global_position
				_set_state("jump")
				_sound(SLAM_SOUND, -8.0, 1.4)
		"jump":
			var k := clampf(_timer / JUMP_TIME, 0.0, 1.0)
			position = _jump_from.lerp(_jump_to, k)
			_sprite.position.y = -sin(k * PI) * JUMP_HEIGHT
			if k >= 1.0:
				_sprite.position.y = 0.0
				_land()
		"rage":
			if _timer >= RAGE_TIME:
				_set_state("walk")


## Machanie skrzydłami (szybciej w ataku), arkusz wg fazy.
func _animate(delta: float) -> void:
	if _sprite == null:
		return
	var busy := state in ["breath", "balls", "jump_warn", "jump", "rage"]
	_flap += delta * (FLAP_FPS_ATTACK if busy else FLAP_FPS)
	_sprite.frame = int(_flap) % FRAMES


func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	var pool := ATTACKS.filter(func(a: String) -> bool:
		return a != _last_attack and (a != "breath" or distance < BREATH_RANGE * 0.95))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (breath, balls, jump) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	var to_hero := hero.global_position - global_position
	_aim = to_hero.normalized() if to_hero.length() > 1.0 else Vector2.DOWN
	match kind:
		"breath":
			_second = false
			_set_state("breath")
			_breath_telegraph(BREATH_WARN)
			_sound(ROAR_SOUND, -6.0, 0.9)
		"balls":
			_set_state("balls")
			var n := 2 + phase
			for i in n:
				var at := hero.global_position
				if i > 0:
					var a := TAU * i / (n - 1) + randf_range(-0.4, 0.4)
					at += Vector2.from_angle(a) * randf_range(BALL_SPREAD.x, BALL_SPREAD.y) * Vector2(1, 0.7)
				var t := ProtoTelegraph.new()
				t.radius = BALL_RADIUS
				t.duration = BALL_WARN + 0.08 * i
				get_parent().add_child(t)
				t.global_position = at.clamp(bounds.position, bounds.end)
				_balls.append(t)
		"jump":
			_set_state("jump_warn")
			_jump_to = hero.global_position.clamp(bounds.position, bounds.end)
			_telegraph = _make_telegraph(_jump_to, JUMP_RADIUS, JUMP_WARN + JUMP_TIME)


func _breath_telegraph(warn: float) -> void:
	_telegraph = _make_telegraph(global_position, BREATH_RANGE, warn)
	_telegraph.arc = BREATH_ARC
	_telegraph.angle = ProtoTelegraph.ground_angle(_aim)


## Zionięcie: ogień w wachlarzu, płonąca ziemia; od 2. fazy zaraz drugie w przeciwną stronę.
func _breath_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(BREATH_DAMAGE * power), Elements.FIRE)
		hero.ignite(roundi(BURN * power), BURN_TIME)
	_remove_telegraph()
	var mouth := global_position + Vector2(0, -MOUTH_HEIGHT * 0.5)
	var fx := Fx.once(get_parent(), FX_BREATH, FX_BREATH_FRAMES, 14.0, mouth, FX_BREATH_ANCHOR, 20,
			BREATH_RANGE / FX_BREATH_LENGTH)
	fx.rotation = _aim.angle()
	for i in BREATH_PATCHES:
		var at := global_position + _aim.rotated(randf_range(-BREATH_ARC, BREATH_ARC) * 0.45) \
				* randf_range(BREATH_RANGE * 0.3, BREATH_RANGE * 0.9) * Vector2(1, ProtoTelegraph.SQUASH)
		ProtoFirePatch.spawn(get_parent(), at, hero, PATCH_RADIUS, PATCH_TIME, roundi(BURN * power))
	_sound(SLAM_SOUND, -4.0, 1.5)
	_shake(2.5, 0.2)
	if phase >= 2 and not _second:
		_second = true
		_aim = -_aim
		_set_state("breath")
		_breath_telegraph(BREATH_SECOND_WARN)
		return
	_second = false
	_set_state("recover")


## Kule ognia: efekt rusza FX_BALL_LEAD s przed uderzeniem, potem obrażenia i płonąca ziemia w kole.
func _update_balls() -> void:
	for i in range(_balls.size() - 1, -1, -1):
		var t := _balls[i]
		if not is_instance_valid(t):
			_balls.remove_at(i)
			continue
		if not t.has_meta("fx") and (1.0 - t.progress) * t.duration <= FX_BALL_LEAD:
			t.set_meta("fx", true)
			Fx.once(get_parent(), FX_BALL, FX_BALL_FRAMES, FX_BALL_FPS, t.global_position, FX_BALL_ANCHOR, 20, FX_BALL_SIZE)
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hit_hero(hero, roundi(BALL_DAMAGE * power), Elements.FIRE)
			hero.ignite(roundi(BURN * power), BURN_TIME)
		ProtoFirePatch.spawn(get_parent(), t.global_position, hero, PATCH_RADIUS, PATCH_TIME * 0.6, roundi(BURN * power))
		_sound(LAND_SOUND, -6.0, randf_range(0.6, 0.75))
		t.queue_free()
		_balls.remove_at(i)


## Lądowanie po skoku: rani w kole, wstrząs; w 3. fazie krąg ognistych słupów.
func _land() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hit_hero(hero, roundi(JUMP_DAMAGE * power))
	_remove_telegraph()
	Fx.once(get_parent(), FX_SLAM_Z, FX_SLAM_FRAMES, 16.0, global_position, FX_SLAM_ANCHOR, -1, JUMP_RADIUS / FX_SLAM_RADIUS * 1.2)
	_shake(6.0, 0.35)
	_sound(SLAM_SOUND, 0.0, randf_range(0.6, 0.7))
	if phase >= 3:
		for i in PILLARS:
			var at := global_position + Vector2.from_angle(TAU * i / PILLARS) * PILLAR_RING * Vector2(1, ProtoTelegraph.SQUASH)
			ProtoFirePatch.spawn(get_parent(), at, hero, PATCH_RADIUS, PATCH_TIME, roundi(BURN * power))
			Fx.once(get_parent(), FX_PILLAR, FX_PILLAR_FRAMES, 16.0, at, FX_PILLAR_ANCHOR, 20, 0.3)
	_set_state("recover")


func take_damage(amount: int, from: Vector2) -> void:
	super(amount, from)
	if alive() and phase <= PHASES.size() and health_fraction() < PHASES[phase - 1]:
		_lose_head()


## Głowa gaśnie: zwęglona na grafice, słup ognia na niej, ryk, wstrząs; chwila gniewu bez ataków.
func _lose_head() -> void:
	var head: Vector2 = HEAD_SPOTS[phase - 1]
	phase += 1
	_sprite.texture = SHEETS[mini(phase - 1, SHEETS.size() - 1)]
	_cancel_attack()
	_set_state("rage")
	Fx.once(get_parent(), FX_PILLAR, FX_PILLAR_FRAMES, 16.0, global_position + head + Vector2(0, 30), FX_PILLAR_ANCHOR, 20, 0.45)
	_sound(ROAR_SOUND, 2.0, 0.5)
	_shake(7.0, 0.6)
	phase_changed.emit(phase)


## Przerywa trwający atak (zmiana fazy): ostrzeżenia znikają, smok wraca na ziemię.
func _cancel_attack() -> void:
	_remove_telegraph()
	for t in _balls:
		if is_instance_valid(t):
			t.queue_free()
	_balls.clear()
	_second = false
	if _sprite:
		_sprite.position.y = 0.0


## Ile kul ognia jeszcze spada (testy).
func balls_pending() -> int:
	return _balls.size()


func _die() -> void:
	_cancel_attack()
	Fx.once(get_parent(), FX_PILLAR, FX_PILLAR_FRAMES, 16.0, global_position, FX_PILLAR_ANCHOR, 20, 0.8)
	super()


func _exit_tree() -> void:
	_cancel_attack()

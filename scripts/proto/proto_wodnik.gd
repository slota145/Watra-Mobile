class_name ProtoWodnik
extends ProtoChief
## Wodnik - boss Zatopionych podziemi (Dungeons.FLOODED, ataki wybrane przez autora 15.11.2026). Reszta (wejście,
## pasek zdrowia, trafienia, śmierć, skrzynia) jak u Wodza (ProtoChief). Trzyma się kawałek od Wojciecha
## i na zmianę używa czterech ataków, każdego z ostrzeżeniem na ziemi:
## - Fala: czerwony pas od Wodnika w stronę postaci (WAVE_LENGTH x WAVE_WIDTH), po WAVE_WARN s przez pas przelatuje
##   fala - rani wodą i przemacza (spowolnienie); trzeba zejść w bok;
## - Wir: koło pod postacią, po VORTEX_WARN s w tym miejscu kręci się wir przez VORTEX_TIME s - wciąga postać
##   do środka (VORTEX_PULL px/s w zasięgu VORTEX_REACH) i rani co VORTEX_TICK s w kole; trzeba odejść;
## - Lodowe krople: DROPS kół wokół postaci (jedno pod nią), wypełniają się po kolei, potem spadają sople -
##   lód rani i mocno spowalnia;
## - Wezwanie topielców: wbija trójząb, z gejzerów wychodzi SUMMON_COUNT topielców (co SUMMON_COOLDOWN s).
## Grafika: model SpriteKiln assets/spritekiln/wodnik/ (idle, walk, roar, wave, vortex, cast, summon, hit, death),
## do tego czasu powiększony goblin w kolorze wody. Efekty wody z hydrosfery (hydro_wave, hydro_vortex,
## hydro_splash, hydro_geyser), lód - rozprysk w kolorze lodu.

const WODNIK_SCENE := "res://assets/spritekiln/wodnik/wodnik.tscn"
const WODNIK_HP := 800
const KEEP_DISTANCE := 70.0
## Z jakiej odległości używa ataków (dalej - podchodzi).
const ATTACK_RANGE := 120.0
const WAVE_WARN := 1.1
const WAVE_LENGTH := 230.0
const WAVE_WIDTH := 30.0
const WAVE_DAMAGE := 24
const WAVE_FLIGHT := 0.45
const VORTEX_WARN := 0.9
const VORTEX_RADIUS := 36.0
const VORTEX_TIME := 2.5
const VORTEX_TICK := 0.5
const VORTEX_DAMAGE := 8
const VORTEX_PULL := 45.0
const VORTEX_REACH := 70.0
const DROPS := 5
const DROP_RADIUS := 16.0
const DROP_WARN := 1.0
const DROP_STEP := 0.18
const DROP_SPREAD := 55.0
const DROP_DAMAGE := 18
const SUMMON_COUNT := 4
const SUMMON_RING := 46.0
const SUMMON_TIME := 1.0
const SUMMON_COOLDOWN := 11.0
const SOAK_SLOW := 0.3
const SOAK_TIME := 2.0
const ICE_SLOW := 0.45
const ICE_TIME := 1.3
const ICE_TINT := Color(0.6, 0.9, 1.0)
const TIDE_FX := preload("res://assets/effects/hydro_wave.png")
const TIDE_FRAMES := 12
const TIDE_ANCHOR := Vector2(17, 32)
const VORTEX_FX := preload("res://assets/effects/hydro_vortex.png")
const VORTEX_FRAMES := 12
const VORTEX_ANCHOR := Vector2(48, 34)
const VORTEX_FX_RADIUS := 34.0
const GEYSER_FX := preload("res://assets/effects/hydro_geyser.png")
const GEYSER_ANCHOR := Vector2(49, 39)
const ATTACKS: Array[String] = ["wave", "vortex", "cast"]

## Kierunek fali (radiany) i jej ostrzeżenie.
var _wave_angle := 0.0
## Wir na ziemi: węzeł efektu (null - brak), środek, ile jeszcze sekund, do następnego ciosu.
var _vortex: Sprite2D
var _vortex_at := Vector2.ZERO
var _vortex_left := 0.0
var _vortex_tick := 0.0
var _vortex_telegraph: ProtoTelegraph
## Lodowe krople: ostrzeżenia, które jeszcze nie spadły.
var _drops: Array[ProtoTelegraph] = []
var _summon_cooldown := 5.0
var _summon_points: Array = []
var _last_attack := ""
## Testy i zrzuty: Wodnik sam nie wybiera ataków (tylko `start_attack`).
var passive := false


func _init() -> void:
	scene_path = WODNIK_SCENE
	base_hp = WODNIK_HP
	fallback_tint = Color(0.55, 0.8, 1.0)
	keep_distance = KEEP_DISTANCE
	anim_hit_at = {&"wave": 0.44, &"vortex": 0.55, &"cast": 0.43, &"summon": 0.45}
	anim_fallback = {&"wave": &"attack", &"vortex": &"attack", &"cast": &"attack", &"summon": &"attack",
		&"roar": &"idle", &"slam": &"attack", &"throw": &"attack"}


func _process(delta: float) -> void:
	super(delta)
	_summon_cooldown -= delta
	_update_vortex(delta)
	_update_drops()
	if state == "dead" or hero == null:
		return
	match state:
		"wave":
			_sync_anim(&"wave", WAVE_WARN)
			if _timer >= WAVE_WARN:
				_wave_hit()
		"vortex":
			_sync_anim(&"vortex", VORTEX_WARN)
			if _timer >= VORTEX_WARN:
				_start_vortex()
		"cast":
			_sync_anim(&"cast", DROP_WARN)
			if _timer >= DROP_WARN:
				_set_state("recover")
		"summon":
			_sync_anim(&"summon", SUMMON_TIME)
			if _timer >= SUMMON_TIME:
				summon_minions.emit(_summon_points)
				_set_state("recover")


## Wybór ataku: wezwanie topielców, gdy gotowe; inaczej fala, wir albo krople (nie dwa razy to samo).
func _choose_attack(distance: float) -> void:
	if passive or distance > ATTACK_RANGE:
		_cooldown = 0.4
		return
	if _summon_cooldown <= 0.0:
		_start_summon()
		return
	var pool := ATTACKS.filter(func(a: String) -> bool: return a != _last_attack and (a != "vortex" or _vortex == null))
	start_attack(pool.pick_random())


## Zaczyna atak `kind` (wave, vortex, cast, summon) - też do testów.
func start_attack(kind: String) -> void:
	_last_attack = kind
	match kind:
		"wave":
			_start_wave()
		"vortex":
			_start_vortex_warn()
		"cast":
			_start_cast()
		"summon":
			_start_summon()


func _start_wave() -> void:
	_set_state("wave")
	var dir := hero.global_position - global_position
	_wave_angle = dir.angle() if dir.length() > 1.0 else PI / 2.0
	_face(dir)
	_remove_telegraph()
	_telegraph = ProtoTelegraph.new()
	_telegraph.length = WAVE_LENGTH
	_telegraph.width = WAVE_WIDTH
	_telegraph.angle = _wave_angle
	_telegraph.duration = WAVE_WARN
	get_parent().add_child(_telegraph)
	_telegraph.global_position = global_position
	_play(&"idle")


## Fala: rani w pasie, przelatuje efektem od Wodnika do końca pasa.
func _wave_hit() -> void:
	if _telegraph and is_instance_valid(_telegraph) and hero and not hero.dead and _telegraph.contains(hero.global_position):
		hero.take_damage(roundi(WAVE_DAMAGE * power), Elements.WATER)
		hero.slow(SOAK_SLOW, SOAK_TIME, Elements.COLORS[Elements.WATER].lerp(Color.WHITE, 0.4))
	_remove_telegraph()
	var fx := Sprite2D.new()
	fx.texture = TIDE_FX
	fx.hframes = TIDE_FRAMES
	fx.centered = false
	fx.offset = -TIDE_ANCHOR
	fx.rotation = _wave_angle
	fx.z_index = 20
	get_parent().add_child(fx)
	var from := global_position
	var to := global_position + Vector2.from_angle(_wave_angle) * WAVE_LENGTH
	fx.global_position = from
	var tween := fx.create_tween()
	tween.tween_method(func(k: float) -> void:
		fx.global_position = from.lerp(to, k)
		fx.frame = mini(int(k * TIDE_FRAMES), TIDE_FRAMES - 1), 0.0, 1.0, WAVE_FLIGHT)
	tween.tween_property(fx, "modulate:a", 0.0, 0.15)
	tween.tween_callback(fx.queue_free)
	_sound(SLAM_SOUND, -4.0, randf_range(1.2, 1.35))
	_set_state("recover")


func _start_vortex_warn() -> void:
	_set_state("vortex")
	_vortex_at = hero.global_position
	_face(_vortex_at - global_position)
	_telegraph = _make_telegraph(_vortex_at, VORTEX_RADIUS, VORTEX_WARN)
	_play(&"idle")


## Wir: kręci się VORTEX_TIME s w miejscu ostrzeżenia (koło zostaje jako znak, gdzie rani).
func _start_vortex() -> void:
	_remove_telegraph()
	_clear_vortex()
	_vortex = Sprite2D.new()
	_vortex.texture = VORTEX_FX
	_vortex.hframes = VORTEX_FRAMES
	_vortex.centered = false
	_vortex.offset = -VORTEX_ANCHOR
	_vortex.scale = Vector2.ONE * VORTEX_RADIUS / VORTEX_FX_RADIUS
	_vortex.z_index = -1
	get_parent().add_child(_vortex)
	_vortex.global_position = _vortex_at
	_vortex_left = VORTEX_TIME
	_vortex_tick = 0.0
	_set_state("recover")


## Wir wciąga postać i rani ją w kole.
func _update_vortex(delta: float) -> void:
	if _vortex == null:
		return
	_vortex_left -= delta
	_vortex.frame = int((VORTEX_TIME - _vortex_left) * 12.0) % VORTEX_FRAMES
	if _vortex_left <= 0.0 or state == "dead":
		_clear_vortex()
		return
	if hero == null or hero.dead:
		return
	var to := _vortex_at - hero.global_position
	var flat := Vector2(to.x, to.y / ProtoTelegraph.SQUASH)
	if flat.length() < VORTEX_REACH and flat.length() > 2.0:
		hero.global_position += to.normalized() * VORTEX_PULL * delta
	_vortex_tick -= delta
	if flat.length() <= VORTEX_RADIUS and _vortex_tick <= 0.0:
		_vortex_tick = VORTEX_TICK
		hero.take_damage(roundi(VORTEX_DAMAGE * power), Elements.WATER)


## Czy wir właśnie się kręci (testy).
func vortex_active() -> bool:
	return _vortex != null


func _clear_vortex() -> void:
	if _vortex and is_instance_valid(_vortex):
		var fading := _vortex
		var tween := fading.create_tween()
		tween.tween_property(fading, "modulate:a", 0.0, 0.3)
		tween.tween_callback(fading.queue_free)
	_vortex = null


## Lodowe krople: koło pod postacią i kilka wokół, wypełniają się po kolei.
func _start_cast() -> void:
	_set_state("cast")
	_face(hero.global_position - global_position)
	_play(&"idle")
	for i in DROPS:
		var at := hero.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(DROP_RADIUS * 1.5, DROP_SPREAD) * Vector2(1, 0.7)
		var t := ProtoTelegraph.new()
		t.radius = DROP_RADIUS
		t.duration = DROP_WARN + DROP_STEP * i
		get_parent().add_child(t)
		t.global_position = at if i == 0 else at.clamp(bounds.position, bounds.end)  # pierwsza zawsze pod postacią
		_drops.append(t)


## Spada sopel tam, gdzie koło się wypełniło.
func _update_drops() -> void:
	for i in range(_drops.size() - 1, -1, -1):
		var t := _drops[i]
		if not is_instance_valid(t):
			_drops.remove_at(i)
			continue
		if t.progress < 1.0:
			continue
		if hero and not hero.dead and state != "dead" and t.contains(hero.global_position):
			hero.take_damage(roundi(DROP_DAMAGE * power), Elements.COLD)
			hero.slow(ICE_SLOW, ICE_TIME, ICE_TINT.lerp(Color.WHITE, 0.3))
		var fx := Fx.once(get_parent(), ProtoArrow.WATER_HIT, ProtoArrow.WATER_HIT_FRAMES, 14.0, t.global_position,
				ProtoArrow.WATER_HIT_ANCHOR, 20, 0.9)
		fx.modulate = ICE_TINT
		t.queue_free()
		_drops.remove_at(i)


## Wezwanie: gejzery w kręgu wokół Wodnika, po chwili wychodzą z nich topielce (arena - ProtoHorde.spawn_at).
func _start_summon() -> void:
	_last_attack = "summon"
	_set_state("summon")
	_summon_cooldown = SUMMON_COOLDOWN
	_summon_points = []
	var start := randf() * TAU
	for i in SUMMON_COUNT:
		var p := global_position + Vector2.from_angle(start + TAU * i / SUMMON_COUNT) * SUMMON_RING * Vector2(1, 0.7)
		p = p.clamp(bounds.position, bounds.end)
		_summon_points.append(p)
		Fx.once(get_parent(), GEYSER_FX, 12, 12.0, p, GEYSER_ANCHOR, 6, 0.55)
	_sound(ROAR_SOUND, -6.0, randf_range(1.25, 1.4))
	_play(&"idle")


func _die() -> void:
	_clear_vortex()
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	_drops.clear()
	super()


func _exit_tree() -> void:
	_remove_telegraph()
	for t in _drops:
		if is_instance_valid(t):
			t.queue_free()
	if _vortex and is_instance_valid(_vortex):
		_vortex.queue_free()

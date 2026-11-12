class_name ProtoGoblin
extends ProtoTarget
## Goblin Hordy w prototypie: idzie do Wojciecha (rozpychając się z innymi goblinami), w zasięgu robi zamach
## i w chwili ciosu (zdarzenie `hit` animacji) zadaje obrażenia, jeśli postać wciąż stoi blisko. Po trafieniu
## mieczem błyska, odskakuje i gra animację trafienia; po śmierci gra animację śmierci, gaśnie i znika.
## Siła rośnie z poziomem lochu (`power` - mnoży zdrowie i obrażenia). Gdy gracz przyzwie bossa, gobliny uciekają
## z piskiem poza ekran (`flee`) i znikają.
## Grafika: scena SpriteKiln assets/spritekiln/goblin/goblin.tscn (KilnSprite2D - animacje idle, walk, attack, hit, death).

signal died(goblin: ProtoGoblin)

const SCENE_PATH := "res://assets/spritekiln/goblin/goblin.tscn"
const MAX_HP := 40
## Prędkość (Wojciech: 70) - około 60%, więc da się uciec.
const SPEED := 42.0
## Odległość stopy-stopy, z której goblin zaczyna zamach i z której cios jeszcze trafia.
const ATTACK_RANGE := 15.0
const HIT_RANGE := 22.0
const DAMAGE := 10
const ATTACK_COOLDOWN := 1.0
## Goblin nie wchodzi na innych bliżej niż tyle (rozpychanie w tłumie).
const PERSONAL_SPACE := 11.0
const KNOCKBACK := 40.0
## Po śmierci ciało leży tyle sekund, potem gaśnie.
const CORPSE_TIME := 1.2
const HIT_SOUNDS := [preload("res://assets/watra/dummy_hit_1.ogg"), preload("res://assets/watra/dummy_hit_2.ogg"),
	preload("res://assets/watra/dummy_hit_3.ogg"), preload("res://assets/watra/dummy_hit_4.ogg")]

const SQUEAKS := [preload("res://assets/sounds/goblin_squeak_0.ogg"), preload("res://assets/sounds/goblin_squeak_1.ogg"),
	preload("res://assets/sounds/goblin_squeak_2.ogg")]
## Ucieczka przed bossem: prędkość i po ilu sekundach goblin gaśnie.
const FLEE_SPEED := 120.0
const FLEE_TIME := 1.4

static var _scene: PackedScene

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var hp := MAX_HP
## Mnożnik zdrowia i obrażeń (DungeonLevels.power poziomu lochu) - ustawiany przed dodaniem do sceny.
var power := 1.0

var _state := "walk"  # walk, attack, hurt, flee, dead
var _cooldown := 0.0
var _push := Vector2.ZERO  # odrzut po trafieniu (wygasa)
var _struck := false  # cios bieżącego zamachu już zadany
var _timer := 0.0
var _sprite  # KilnSprite2D (scena SpriteKiln) albo zastępczy Polygon2D
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	center_height = 12.0
	hp = roundi(MAX_HP * power)
	add_to_group(ProtoWeapon.TARGETS)
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(0.85, 0.85)
	add_child(shadow)
	if _scene == null and ResourceLoader.exists(SCENE_PATH):
		_scene = load(SCENE_PATH)
	if _scene:
		_sprite = _scene.instantiate()
		add_child(_sprite)
		_sprite.anim_event.connect(_on_anim_event)
		_sprite.anim_finished.connect(_on_anim_finished)
		_sprite.play_anim(&"walk")
	else:
		_sprite = Polygon2D.new()  # do czasu eksportu grafiki
		_sprite.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(5, -20), Vector2(-5, -20)])
		_sprite.color = Color(0.55, 0.65, 0.2)
		add_child(_sprite)
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = -12.0
	add_child(_audio)
	_cooldown = randf_range(0.2, 0.6)


func alive() -> bool:
	return _state != "dead" and _state != "flee"


func _process(delta: float) -> void:
	_cooldown -= delta
	_timer += delta
	_push = _push.move_toward(Vector2.ZERO, KNOCKBACK * 6.0 * delta)
	if _state == "dead":
		return
	if _state == "flee":
		var away := (global_position - hero.global_position).normalized() if hero else Vector2.DOWN
		if away == Vector2.ZERO:
			away = Vector2.from_angle(randf() * TAU)
		_face(away)
		position += away * FLEE_SPEED * delta  # bez granic areny - ucieka poza nią
		return
	var to_hero := hero.global_position - global_position if hero else Vector2.ZERO
	var move := _push
	match _state:
		"walk":
			if hero and not hero.dead:
				if to_hero.length() <= ATTACK_RANGE and _cooldown <= 0.0:
					_start_attack(to_hero)
				elif to_hero.length() > ATTACK_RANGE * 0.8:
					move += to_hero.normalized() * SPEED
					_face(to_hero)
			move += _separation() * SPEED
			if _state == "walk":  # zamach mógł się właśnie zacząć - wtedy gra animacja ataku
				_play(&"walk" if move.length() > 4.0 else &"idle")
		"attack":
			move += _separation() * SPEED * 0.5
			if not _scene:  # bez grafiki: cios po 0.3 s
				if not _struck and _timer > 0.3:
					_strike()
				if _timer > 0.6:
					_state = "walk"
		"hurt":
			if not _scene and _timer > 0.25:
				_state = "walk"
	position = (position + move * delta).clamp(bounds.position, bounds.end)


func take_damage(amount: int, from: Vector2) -> void:
	if not alive():
		return
	hp -= amount
	spawn_number(amount)
	_audio.stream = HIT_SOUNDS.pick_random()
	_audio.pitch_scale = randf_range(1.05, 1.25)
	_audio.play()
	_push = (global_position - from).normalized() * KNOCKBACK
	var tween := create_tween()
	_sprite.modulate = Color(3, 3, 3)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()
		return
	# trafienie przerywa zamach (cios nie padnie) - nagroda za szybkie cięcie
	_state = "hurt"
	_timer = 0.0
	_cooldown = maxf(_cooldown, 0.4)
	_play(&"hit", true)


func _start_attack(to_hero: Vector2) -> void:
	_state = "attack"
	_timer = 0.0
	_struck = false
	_cooldown = ATTACK_COOLDOWN
	_face(to_hero)
	_play(&"attack", true)


## Cios: trafia, jeśli Wojciech wciąż jest w zasięgu (da się odskoczyć w trakcie zamachu).
func _strike() -> void:
	_struck = true
	if hero and not hero.dead and global_position.distance_to(hero.global_position) <= HIT_RANGE:
		hero.take_damage(roundi(DAMAGE * power))


func _die() -> void:
	_state = "dead"
	remove_from_group(ProtoWeapon.TARGETS)
	z_index = -1  # ciało pod żywymi
	died.emit(self)
	if _scene:
		_play(&"death", true)
	else:
		_vanish()


## Ucieczka przed bossem: goblin piszczy (`squeak`), odwraca się od postaci, biegnie i gaśnie. Nie daje iskry.
func flee(squeak := true) -> void:
	if not alive():
		return
	_state = "flee"
	remove_from_group(ProtoWeapon.TARGETS)
	_play(&"walk", true)
	if _scene:
		_sprite.speed_scale = FLEE_SPEED / SPEED
	if squeak:
		_audio.stream = SQUEAKS.pick_random()
		_audio.pitch_scale = randf_range(0.9, 1.2)
		_audio.volume_db = -10.0
		_audio.play()
	var tween := create_tween()
	tween.tween_interval(FLEE_TIME * 0.6)
	tween.tween_property(self, "modulate:a", 0.0, FLEE_TIME * 0.4)
	tween.tween_callback(queue_free)


func _vanish() -> void:
	var tween := create_tween()
	tween.tween_interval(CORPSE_TIME)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


func _on_anim_event(anim: StringName, event: StringName) -> void:
	if anim == &"attack" and event == &"hit" and _state == "attack" and not _struck:
		_strike()


func _on_anim_finished(anim: StringName) -> void:
	match anim:
		&"attack":
			if _state == "attack":
				if not _struck:
					_strike()
				_state = "walk"
		&"hit":
			if _state == "hurt":
				_state = "walk"
		&"death":
			_vanish()


## Odpychanie od sąsiednich goblinów (żeby tłum się rozkładał, a nie stał w jednym punkcie).
func _separation() -> Vector2:
	var away := Vector2.ZERO
	for other in get_tree().get_nodes_in_group(ProtoWeapon.TARGETS):
		if other == self or not other is ProtoGoblin:
			continue
		var d: Vector2 = global_position - other.global_position
		var l := d.length()
		if l < PERSONAL_SPACE:
			away += (d / l if l > 0.01 else Vector2.from_angle(randf() * TAU)) * (1.0 - l / PERSONAL_SPACE)
	return away.limit_length(1.0)


func _face(dir: Vector2) -> void:
	if _scene and dir.length() > 0.5:
		_sprite.face(dir)


func _play(anim: StringName, restart := false) -> void:
	if _scene:
		_sprite.play_anim(anim, restart)

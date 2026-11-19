class_name ProtoGoblin
extends ProtoTarget
## Goblin Hordy w prototypie: idzie do Wojciecha (rozpychając się z innymi goblinami), w zasięgu robi zamach
## i w chwili ciosu (zdarzenie `hit` animacji) zadaje obrażenia, jeśli postać wciąż stoi blisko. Po trafieniu
## mieczem błyska, odskakuje i gra animację trafienia; po śmierci gra animację śmierci, gaśnie i znika.
## Siła rośnie z poziomem lochu (`power` - mnoży zdrowie i obrażenia). Gdy gracz przyzwie bossa, gobliny uciekają
## z piskiem poza ekran (`flee`) i znikają. Ogłuszony (`stun`, Rozłupanie Ziemi) stoi w miejscu i nie atakuje.
## Elita (ProtoElite.promote, dziecko `elite`): tarcza pochłania trafienia (`_absorb`), Dowódczy wzmacnia sąsiadów
## (`empower` - szybsi i silniejsi), po śmierci elita może wybuchnąć (ProtoElite.on_death).
## Grafika: scena SpriteKiln assets/spritekiln/goblin/goblin.tscn (KilnSprite2D - animacje idle, walk, attack, hit, death).
## Potwory innych lochów (Dungeons) dziedziczą po goblinie: `element` - żywioł ciosu (odporność bohatera),
## `_hit_hero` - co jeszcze robi trafienie (np. przemoczenie topielca), `squeaks` - czy piszczy przy ucieczce.

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

## Wczytane sceny grafik (wspólne dla wszystkich goblinów danego rodzaju; klucz - ścieżka).
static var _scenes := {}
## Siatka tłumu do odpychania: kratka PERSONAL_SPACE -> gobliny w niej; budowana raz na klatkę (`_crowd_grid`),
## żeby każdy goblin sprawdzał tylko sąsiadów z 9 kratek, a nie cały tłum (inaczej czas rośnie z kwadratem liczby potworów).
static var _grid := {}
static var _grid_frame := -1

var hero: ProtoHero
## Cel ataku zamiast postaci (Kryształ Watry - ProtoCrystal): potwór idzie do niego i go bije, chyba że postać
## jest bliżej niż OBJECTIVE_AGGRO - wtedy walczy z nią jak zwykle.
var objective: ProtoCrystal
const OBJECTIVE_AGGRO := 70.0
var bounds := Rect2(-300, -300, 600, 600)
var hp := MAX_HP
## Mnożnik zdrowia i obrażeń (DungeonLevels.power poziomu lochu) - ustawiany przed dodaniem do sceny.
var power := 1.0
## Liczby tego rodzaju goblina (podklasy, np. łucznik, ustawiają inne w `_init`).
var scene_path := SCENE_PATH
var max_hp := MAX_HP
## Dodatkowy mnożnik zdrowia z głębokości lochu (DungeonLevels.hp_mult - ustawia ProtoHorde).
var hp_mult := 1.0
var speed := SPEED
var damage := DAMAGE
var attack_cooldown := ATTACK_COOLDOWN
## Wielkość cienia pod stopami (osiłek ma większy).
var shadow_scale := 0.85
## Żywioł ciosu (Elements) i czy piszczy przy ucieczce przed bossem (gobliny tak).
var element := Elements.PHYSICAL
var squeaks := true
## Kolor zastępczego kształtu, dopóki nie ma grafiki.
var fallback_color := Color(0.55, 0.65, 0.2)
## Elita (cechy, tarcza, napis) albo null; mnożnik obrażeń (elita - Elites.DAMAGE).
var elite: ProtoElite
var damage_mult := 1.0
## Wzmocnienie od Dowódczej elity (sekundy do końca).
var _empowered := 0.0
## Bez grafiki (zastępczy kształt): po tylu sekundach zamachu pada cios i po tylu zamach się kończy.
var strike_time := 0.3
var attack_time := 0.6

var _state := "walk"  # walk, attack, hurt, flee, dead
var _cooldown := 0.0
var _push := Vector2.ZERO  # odrzut po trafieniu (wygasa)
var _struck := false  # cios bieżącego zamachu już zadany
var _timer := 0.0
## Ile jeszcze sekund goblin jest ogłuszony.
var _stunned := 0.0
var _scene: PackedScene
var _sprite  # KilnSprite2D (scena SpriteKiln) albo zastępczy Polygon2D
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	center_height = 12.0
	hp = roundi(max_hp * power * hp_mult)
	add_to_group(ProtoWeapon.TARGETS)
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(shadow_scale, shadow_scale)
	add_child(shadow)
	if not _scenes.has(scene_path):
		_scenes[scene_path] = load(scene_path) if ResourceLoader.exists(scene_path) else null
	_scene = _scenes[scene_path]
	if _scene:
		_sprite = _scene.instantiate()
		add_child(_sprite)
		_sprite.anim_event.connect(_on_anim_event)
		_sprite.anim_finished.connect(_on_anim_finished)
		_sprite.play_anim(&"walk")
	else:
		_sprite = Polygon2D.new()  # do czasu eksportu grafiki
		_sprite.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(5, -20), Vector2(-5, -20)])
		_sprite.color = fallback_color
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
	if _empowered > 0.0:
		_empowered -= delta
		if _empowered <= 0.0 and _sprite:
			_sprite.self_modulate = Color.WHITE
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
	if _stunned > 0.0:
		_stunned -= delta
		position = (position + _push * delta).clamp(bounds.position, bounds.end)
		return
	var to_hero := hero.global_position - global_position if hero else Vector2.ZERO
	var move := _push
	match _state:
		"walk":
			if _objective_alive() and (hero == null or hero.dead or to_hero.length() > OBJECTIVE_AGGRO):
				move += _objective_move()
			elif hero and not hero.dead:
				move += _walk_move(to_hero)
			move += _separation() * speed
			if _state == "walk":  # zamach mógł się właśnie zacząć - wtedy gra animacja ataku
				_play(&"walk" if move.length() > 4.0 else &"idle")
		"attack":
			move += _separation() * speed * 0.5
			if not _scene:  # bez grafiki: cios po 0.3 s
				if not _struck and _timer > strike_time:
					_strike()
				if _timer > attack_time:
					_state = "walk"
		"hurt":
			if not _scene and _timer > 0.25:
				_state = "walk"
	position = ProtoDecor.push_out((position + move * delta).clamp(bounds.position, bounds.end), 3.0)  # obchodzi ozdoby


func _objective_alive() -> bool:
	return is_instance_valid(objective) and objective.under_attack()


## Marsz do celu ataku (Kryształ) i bicie go z bliska co `attack_cooldown` (bez animacji ciosu - podklasy mają różne
## ataki na postać; cel błyska przy trafieniu).
func _objective_move() -> Vector2:
	var to := objective.global_position - global_position
	if to.length() > objective.RADIUS + 6.0:
		_face(to)
		return to.normalized() * speed * speed_factor()
	if _cooldown <= 0.0:
		_cooldown = attack_cooldown
		objective.take_hit(hit_damage())
	return Vector2.ZERO


## Ruch w stanie marszu (postać żyje): podejście i zamach z bliska. Łucznik nadpisuje (dystans i strzał).
func _walk_move(to_hero: Vector2) -> Vector2:
	if to_hero.length() <= ATTACK_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
	elif to_hero.length() > ATTACK_RANGE * 0.8:
		_face(to_hero)
		return to_hero.normalized() * speed * speed_factor()
	return Vector2.ZERO


## Obrażenia ciosu tego goblina (siła poziomu, elita, wzmocnienie Dowódczego).
func hit_damage() -> int:
	var mult := damage_mult * (Elites.EMPOWER_DAMAGE if _empowered > 0.0 else 1.0)
	return roundi(damage * power * mult)


## Wzmocnienie od Dowódczej elity na `time` s: szybszy i silniejszy, lekko złoty.
func empower(time: float) -> void:
	if not alive():
		return
	_empowered = maxf(_empowered, time)
	if _sprite:
		_sprite.self_modulate = Elites.EMPOWER_TINT


func speed_factor() -> float:
	return super() * (Elites.EMPOWER_SPEED if _empowered > 0.0 else 1.0)


## Tarcza elity pochłania obrażenia; zwraca, ile przechodzi dalej (0 - całe trafienie na tarczy).
func _absorb(amount: int) -> int:
	return elite.absorb(amount) if elite else amount


func take_damage(amount: int, from: Vector2) -> void:
	if not alive():
		return
	amount = _absorb(amount)
	if amount <= 0:
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


## Podpalenie (kamień Żar): obrażenia bez odrzutu i przerwania zamachu, pomarańczowa liczba.
func burn_tick(amount: int) -> void:
	if not alive():
		return
	amount = _absorb(amount)
	if amount <= 0:
		return
	hp -= amount
	spawn_number(amount, Color(1.0, 0.6, 0.25))
	if hp <= 0:
		_die()


## Odepchnięcie (wybuch Młynka): mocniejszy odrzut niż zwykłe trafienie.
func push_away(from: Vector2, force: float) -> void:
	if alive():
		_push = (global_position - from).normalized() * force


## Ogłuszenie: przerywa zamach, goblin stoi i chwieje się (szarzeje) przez `time` sekund.
func stun(time: float) -> void:
	if not alive():
		return
	_stunned = maxf(_stunned, time)
	_state = "walk"
	_cooldown = maxf(_cooldown, 0.3)
	_play(&"idle")
	_sprite.modulate = Color(0.75, 0.75, 0.95)
	var tween := create_tween()
	tween.tween_interval(time)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _start_attack(to_hero: Vector2) -> void:
	_state = "attack"
	_timer = 0.0
	_struck = false
	_cooldown = attack_cooldown
	_face(to_hero)
	_play(&"attack", true)


## Cios: trafia, jeśli Wojciech wciąż jest w zasięgu (da się odskoczyć w trakcie zamachu).
func _strike() -> void:
	_struck = true
	if hero and not hero.dead and global_position.distance_to(hero.global_position) <= HIT_RANGE:
		hit_hero(hero, hit_damage(), element)
		_hit_hero()


## Co jeszcze robi trafienie postaci (podklasy: przemoczenie, zamrożenie); goblin - nic.
func _hit_hero() -> void:
	pass


func _die() -> void:
	_state = "dead"
	remove_from_group(ProtoWeapon.TARGETS)
	z_index = -1  # ciało pod żywymi
	if elite:
		elite.on_death()
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
		_sprite.speed_scale = FLEE_SPEED / speed
	if squeak and squeaks:
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
	var grid := _crowd_grid(get_tree())
	var cell := Vector2i((global_position / PERSONAL_SPACE).floor())
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var near: Array = grid.get(cell + Vector2i(dx, dy), [])
			for other: ProtoGoblin in near:
				if other == self:
					continue
				var d: Vector2 = global_position - other.global_position
				var l := d.length()
				if l < PERSONAL_SPACE:
					away += (d / l if l > 0.01 else Vector2.from_angle(randf() * TAU)) * (1.0 - l / PERSONAL_SPACE)
	return away.limit_length(1.0)


## Siatka tłumu z tej klatki (przy pierwszym wywołaniu w klatce układa wszystkie gobliny w kratki).
static func _crowd_grid(tree: SceneTree) -> Dictionary:
	var frame := Engine.get_process_frames()
	if frame != _grid_frame:
		_grid_frame = frame
		_grid = {}
		for n in tree.get_nodes_in_group(ProtoWeapon.TARGETS):
			if n is ProtoGoblin:
				var key := Vector2i((n.global_position / PERSONAL_SPACE).floor())
				if _grid.has(key):
					_grid[key].append(n)
				else:
					_grid[key] = [n]
	return _grid


func _face(dir: Vector2) -> void:
	if _scene and dir.length() > 0.5:
		_sprite.face(dir)


func _play(anim: StringName, restart := false) -> void:
	if _scene:
		_sprite.play_anim(anim, restart)

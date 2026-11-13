class_name ProtoHero
extends Node2D
## Postać w prototypie: Wojciech z Watry (arkusz assets/watra/wojciech.png) chodzi gałką.
## Arkusz: 8 kolumn = klatki, wiersze = animacja * 5 + kierunek (s, se, e, ne, n; zachód to odbicie).
## Bez broni w dłoni - broń lewituje obok (ProtoWeapon). Animacja "slash" z pustą dłonią służy za gest ataku.
## Zdrowie: potwory Hordy zadają obrażenia (`take_damage`), przy zerze postać pada (`died`). `obstacles` - okręgi
## (x, y, promień), przez które postać nie przechodzi (np. krąg kamieni Watry).
## Tryb deweloperski (`immortal`): zdrowie schodzi normalnie, ale zamiast śmierci wraca do pełna, a `deaths` liczy,
## ile razy postać by zginęła (sygnał `death_avoided`).
## Poziom postaci (`set_level`, HeroLevels) ustala największe zdrowie; awans (`level_up`) leczy do pełna
## ze złotym błyskiem, napisem „Poziom N!” i dźwiękiem. Przedmioty (`gear` - Items.totals) dokładają zdrowie, manę,
## szybkość ruchu, regenerację zdrowia i ochronę (mniej obrażeń od potworów).
## Mana odnawia się sama (HeroLevels.MANA_REGEN i premia przedmiotów `mana_regen`), a wydają ją umiejętności miecza (`spend_mana`). Skok Mgnienia
## (`teleport`) przenosi postać od razu, zostawia gasnący cień w miejscu startu i daje chwilę nietykalności.

signal health_changed(hp: int, max_hp: int)
signal mana_changed(mana: int, max_mana: int)
signal died
## Cios potwora chybił dzięki unikowi.
signal dodged
## Nieśmiertelność uratowała postać od śmierci (`count` - ile razy w tym lochu).
signal death_avoided(count: int)

const ANIMS := ["idle", "walk", "slash"]
const FPS := {"idle": 6.0, "walk": 14.0, "slash": 18.0}
const DIRS := 5
const FRAMES := 8
const SPEED := 70.0
## Zdrowie na 1. poziomie (wyżej - HeroLevels.max_hp).
const MAX_HP := HeroLevels.HP_BASE
const LEVEL_UP_SOUND := preload("res://assets/watra/level_up.ogg")
## Po trafieniu postać przez chwilę nie dostaje kolejnych obrażeń (kilka goblinów naraz nie zabija w mgnieniu oka).
const INVULNERABLE := 0.35

## Skąd postać bierze kierunek ruchu (gałka).
var joystick: Joystick
## Granica areny (postać nie wychodzi poza nią).
var bounds := Rect2(-300, -300, 600, 600)
## Czy przy ataku postać robi gest ręką.
var gesture := true
## Kierunek patrzenia (do gestu i do miejsca, w którym unosi się broń).
var facing := Vector2.DOWN
var velocity := Vector2.ZERO
var max_hp := MAX_HP
## Mana (zużywają ją umiejętności miecza).
var max_mana := HeroLevels.MANA_BASE
var mana := HeroLevels.MANA_BASE
var hp := MAX_HP
var dead := false
## Tryb deweloperski: zamiast śmierci zdrowie wraca do pełna.
var immortal := false
## Ile razy postać zginęłaby bez nieśmiertelności.
var deaths := 0
## Przeszkody: Vector3(x, y, promień); w pionie spłaszczone o połowę (widok z góry 3/4).
var obstacles: Array[Vector3] = []
## Z przedmiotów: mnożnik szybkości ruchu, zdrowie na sekundę, część obrażeń, której postać nie dostaje (0-0,5).
var move_mult := 1.0
var regen := 0.0
var protection := 0.0
## Szansa na unik (0-1, premia przedmiotów): cios potwora nie zadaje obrażeń, nad głową napis „Unik!”.
var dodge := 0.0
var _regen_acc := 0.0
var _mana_acc := 0.0
## Ostatnio podane cechy z przedmiotów (awans liczy z nimi nowe zdrowie).
var gear := {}

var _anim := "idle"
var _time := 0.0
var _sprite: Sprite2D
var _invulnerable := 0.0


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = _shadow_texture()
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/watra/wojciech.png")
	_sprite.hframes = FRAMES
	_sprite.vframes = _sprite.texture.get_height() / 54
	_sprite.offset = Vector2(0, -19)  # stopy postaci w punkcie węzła (sortowanie po Y)
	add_child(_sprite)


func _process(delta: float) -> void:
	_invulnerable -= delta
	if dead:
		velocity = Vector2.ZERO
		return
	if regen > 0.0 and hp < max_hp:
		_regen_acc += regen * delta
		if _regen_acc >= 1.0:
			var heal := int(_regen_acc)
			_regen_acc -= heal
			hp = mini(hp + heal, max_hp)
			health_changed.emit(hp, max_hp)
	if mana < max_mana:
		_mana_acc += (HeroLevels.MANA_REGEN + gear.get("mana_regen", 0.0)) * delta
		if _mana_acc >= 1.0:
			var add := int(_mana_acc)
			_mana_acc -= add
			mana = mini(mana + add, max_mana)
			mana_changed.emit(mana, max_mana)
	else:
		_mana_acc = 0.0
	var input := joystick.vector if joystick else Vector2.ZERO
	velocity = input * SPEED * move_mult
	position = _push_out((position + velocity * delta).clamp(bounds.position, bounds.end))
	if input.length() > 0.05:
		facing = input.normalized()
	if _anim == "slash":
		# gest gra do końca; jeśli postać ruszyła, wraca do chodzenia, żeby nie sunąć po ziemi
		if input.length() > 0.05 or _time * FPS.slash >= FRAMES:
			_play("walk" if input.length() > 0.05 else "idle")
	else:
		_play("walk" if input.length() > 0.05 else "idle")
	_time += delta
	_update_frame()


## Trafienie przez potwora: czerwony błysk, liczba nad głową, krótka nietykalność; przy zerze - śmierć.
func take_damage(amount: int) -> void:
	if dead or _invulnerable > 0.0:
		return
	_invulnerable = INVULNERABLE
	if dodge > 0.0 and randf() < dodge:
		_spawn_text(tr("Unik!"), Color(0.75, 0.9, 1.0))
		dodged.emit()
		return
	amount = maxi(1, roundi(amount * (1.0 - protection)))
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	_spawn_text("-%d" % amount, Color(1.0, 0.4, 0.35))
	Input.vibrate_handheld(30)
	var tween := _sprite.create_tween()
	_sprite.modulate = Color(2.2, 0.5, 0.45)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.25)
	if hp == 0 and immortal:
		deaths += 1
		hp = max_hp
		health_changed.emit(hp, max_hp)
		_sprite.modulate = Color(2.4, 2.0, 0.9)  # złoty błysk zamiast śmierci
		death_avoided.emit(deaths)
		return
	if hp == 0:
		dead = true
		# padnięcie: postać przechyla się i ciemnieje (Wojciech z Watry nie ma animacji śmierci)
		_play("idle")
		var fall := _sprite.create_tween()
		fall.tween_property(_sprite, "rotation", PI / 2.0 * (-1.0 if _sprite.flip_h else 1.0), 0.35).set_ease(Tween.EASE_IN)
		fall.parallel().tween_property(_sprite, "position:y", 8.0, 0.35)
		fall.tween_property(_sprite, "modulate", Color(0.45, 0.4, 0.4), 0.4)
		died.emit()


## Leczenie (kamień Krwiopijca) - bez liczby nad głową, żeby nie zasłaniać walki.
func heal(amount: int) -> void:
	if dead or amount <= 0 or hp >= max_hp:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


## Mana za trafienie (kamień Oszczędność w zwykłym ciosie).
func add_mana(amount: int) -> void:
	if dead or amount <= 0 or mana >= max_mana:
		return
	mana = mini(mana + amount, max_mana)
	mana_changed.emit(mana, max_mana)


## Wydaje manę na umiejętność. Zwraca false (i nic nie zabiera), gdy jej brakuje.
func spend_mana(amount: int) -> bool:
	if amount > mana:
		return false
	mana -= amount
	mana_changed.emit(mana, max_mana)
	return true


## Skok Mgnienia do punktu `to` (świat; w granicach areny, poza przeszkodami): gasnący niebieskawy cień w miejscu
## startu, postać patrzy w stronę skoku, 0,15 s nietykalności. Zwraca punkt, w którym wylądowała (świat).
func teleport(to: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	var local := parent.to_local(to) if parent else to
	local = _push_out(local.clamp(bounds.position, bounds.end))
	if parent:
		var ghost := Sprite2D.new()
		ghost.texture = _sprite.texture
		ghost.hframes = _sprite.hframes
		ghost.vframes = _sprite.vframes
		ghost.frame = _sprite.frame
		ghost.flip_h = _sprite.flip_h
		ghost.offset = _sprite.offset
		ghost.position = position
		ghost.modulate = Color(0.6, 0.75, 1.0, 0.6)
		parent.add_child(ghost)
		var fade := ghost.create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, 0.25)
		fade.tween_callback(ghost.queue_free)
	var dir := local - position
	if dir.length() > 0.5:
		facing = dir.normalized()
	position = local
	_invulnerable = maxf(_invulnerable, 0.15)
	_update_frame()
	return parent.to_global(local) if parent else local


## Ustawia zdrowie i manę według poziomu postaci i przedmiotów (`gear` - Items.totals; pełne).
func set_level(level: int, items_gear := {}) -> void:
	apply_gear(level, items_gear)
	hp = max_hp
	health_changed.emit(hp, max_hp)
	mana = max_mana
	mana_changed.emit(mana, max_mana)


## Przelicza cechy z poziomu i przedmiotów bez leczenia (zmiana ekwipunku w trakcie wyprawy): przyrost
## największego zdrowia i many dolicza się do obecnych, spadek tylko je przycina.
func apply_gear(level: int, items_gear: Dictionary) -> void:
	gear = items_gear
	var new_hp := HeroLevels.max_hp(level) + roundi(gear.get("hp", 0.0))
	var new_mana := HeroLevels.max_mana(level) + roundi(gear.get("mana", 0.0))
	hp = clampi(hp + maxi(new_hp - max_hp, 0), 0 if dead else 1, new_hp)
	mana = clampi(mana + maxi(new_mana - max_mana, 0), 0, new_mana)
	max_hp = new_hp
	max_mana = new_mana
	move_mult = 1.0 + gear.get("move_pct", 0.0) / 100.0
	regen = gear.get("regen", 0.0)
	protection = gear.get("protection_pct", 0.0) / 100.0
	dodge = gear.get("dodge_pct", 0.0) / 100.0
	health_changed.emit(hp, max_hp)
	mana_changed.emit(mana, max_mana)


## Awans: nowe zdrowie (pełne), złoty błysk, słup światła, napis „Poziom N!” nad głową i dźwięk. Gra się nie zatrzymuje.
func level_up(level: int) -> void:
	if dead:
		return
	set_level(level, gear)
	_sprite.modulate = Color(2.4, 2.0, 0.9)
	var tween := _sprite.create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.6)
	var glow := _LevelGlow.new()
	glow.z_index = 15
	add_child(glow)
	var num := Label.new()
	num.text = tr("Poziom %d!") % level
	num.add_theme_font_size_override("font_size", 16)
	num.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	num.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	num.add_theme_constant_override("outline_size", 5)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(100, 20)
	num.position = Vector2(-50, -62)
	num.z_index = 21
	add_child(num)
	var up := num.create_tween()
	up.tween_property(num, "position:y", num.position.y - 22, 1.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	up.parallel().tween_property(num, "modulate:a", 0.0, 0.5).set_delay(1.0)
	up.tween_callback(num.queue_free)
	var sound := AudioStreamPlayer.new()
	sound.stream = LEVEL_UP_SOUND
	sound.volume_db = -4.0
	add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)
	Input.vibrate_handheld(60)


## Słup złotego światła przy awansie: rośnie od stóp w górę i gaśnie (rysowany w kodzie, bez tekstur).
class _LevelGlow extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / 0.25, 0.0, 1.0)
		var fade := 1.0 - clampf((_t - 0.4) / 0.6, 0.0, 1.0)
		var h := 70.0 * k
		for i in 4:  # kilka nakładających się pasów - miękki brzeg
			var w := 18.0 - i * 4.0
			draw_rect(Rect2(-w / 2.0, -h, w, h), Color(1.0, 0.82, 0.35, 0.12 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))  # krąg na ziemi spłaszczony jak w widoku 3/4
		draw_arc(Vector2.ZERO, 6.0 + 20.0 * k, 0.0, TAU, 24, Color(1.0, 0.85, 0.4, 0.7 * fade), 2.0)


## Wypycha punkt z przeszkód (okręgi spłaszczone w pionie).
func _push_out(p: Vector2) -> Vector2:
	for o in obstacles:
		var d := Vector2(p.x - o.x, (p.y - o.y) * 2.0)
		if d.length() < o.z:
			d = (d if d.length() > 0.01 else Vector2.DOWN).normalized() * o.z
			p = Vector2(o.x + d.x, o.y + d.y / 2.0)
	return p


## Napis nad głową, który unosi się i znika (liczba obrażeń, „Unik!”).
func _spawn_text(text: String, color: Color) -> void:
	var num := Label.new()
	num.text = text
	num.add_theme_font_size_override("font_size", 12)
	num.add_theme_color_override("font_color", color)
	num.add_theme_color_override("font_outline_color", Color(0.15, 0.04, 0.04))
	num.add_theme_constant_override("outline_size", 4)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(60, 16)
	num.position = Vector2(-30, -60)
	num.z_index = 20
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", num.position.y - 16, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(num.queue_free)


## Gest ręką w stronę celu - wywołuje broń, gdy zaczyna zamach. Tylko w miejscu (w marszu postać tylko idzie).
func play_gesture(toward: Vector2) -> void:
	if not gesture or dead or velocity.length() > 5.0:
		return
	facing = (toward - global_position).normalized()
	_anim = "slash"
	_time = 0.0


func _play(anim: String) -> void:
	if anim != _anim:
		_anim = anim
		_time = 0.0


func _update_frame() -> void:
	# kąt 0 = wschód, rośnie zgodnie z ruchem wskazówek (oś Y w dół); kierunki co 45 stopni
	var octant := wrapi(roundi(facing.angle() / (PI / 4.0)), 0, 8)  # 0 e, 1 se, 2 s, 3 sw, 4 w, 5 nw, 6 n, 7 ne
	var dir: int = [2, 1, 0, 1, 2, 3, 4, 3][octant]
	_sprite.flip_h = octant in [3, 4, 5]
	var frame := int(_time * FPS[_anim]) % FRAMES
	_sprite.frame = (ANIMS.find(_anim) * DIRS + dir) * FRAMES + frame  # idle, walk, slash to 3 pierwsze animacje arkusza


static func _shadow_texture() -> Texture2D:
	var img := Image.create(14, 5, false, Image.FORMAT_RGBA8)
	for y in 5:
		for x in 14:
			var d := Vector2((x - 6.5) / 7.0, (y - 2.0) / 2.5).length()
			if d < 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.35))
	return ImageTexture.create_from_image(img)

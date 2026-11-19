class_name ProtoHero
extends Node2D
## Postać w prototypie: Wojciech z Watry (arkusz assets/watra/wojciech.png) chodzi gałką.
## Arkusz: 8 kolumn = klatki, wiersze = animacja * 5 + kierunek (s, se, e, ne, n; zachód to odbicie).
## Bez broni w dłoni - broń lewituje obok (ProtoWeapon). Animacja "slash" z pustą dłonią służy za gest ataku.
## Zdrowie i mana (pasek u góry - Vitals). Włączone aury (auras - ta sama tablica co Game.auras) rezerwują część
## maksymalnej many i dają premie (AuraData); aury działające na wrogów obsługuje ProtoAuras.

const ANIMS := ["idle", "walk", "slash"]
const FPS := {"idle": 6.0, "walk": 14.0, "slash": 18.0}
const DIRS := 5
const FRAMES := 8
const SPEED := 70.0
const BASE_HEALTH := 100.0
const BASE_MANA := 100.0
## Odnowa many bez aur: ułamek pełnej many na sekundę.
const MANA_REGEN := 0.02

## Skąd postać bierze kierunek ruchu (gałka).
var joystick: Joystick
## Granica areny (postać nie wychodzi poza nią).
var bounds := Rect2(-300, -300, 600, 600)
## Czy przy ataku postać robi gest ręką.
var gesture := true
## Kierunek patrzenia (do gestu i do miejsca, w którym unosi się broń).
var facing := Vector2.DOWN
var velocity := Vector2.ZERO
## Włączone aury (arena podaje tablicę Game.auras).
var auras: Array[String] = []
## Redukcja rezerwacji aur (Game.aura_reduction).
var aura_reduction := 0.0
var health := BASE_HEALTH
var mana := BASE_MANA

var _anim := "idle"
var _time := 0.0
var _sprite: Sprite2D


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
	var input := joystick.vector if joystick else Vector2.ZERO
	velocity = input * SPEED * (1.0 + aura_power("strzybog"))
	mana = minf(mana + full_mana() * (MANA_REGEN + aura_power("mana")) * delta, max_mana())
	health = minf(health + max_health() * aura_power("zywia") * delta, max_health())
	position = (position + velocity * delta).clamp(bounds.position, bounds.end)
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


## Siła włączonej aury (0, gdy wyłączona). Poziom aur na razie 1 (kamienie aur z łupu dojdą z lochami).
func aura_power(id: String) -> float:
	return AuraData.power(id) if auras.has(id) else 0.0


func max_health() -> float:
	return BASE_HEALTH * (1.0 + aura_power("krzepa"))


## Pełna mana, razem z zarezerwowaną przez aury.
func full_mana() -> float:
	return BASE_MANA


## Ułamek many zarezerwowany przez aury.
func reserved() -> float:
	return AuraData.reserved_total(auras, aura_reduction)


## Mana do wydania na umiejętności (pełna bez zarezerwowanej).
func max_mana() -> float:
	return full_mana() * (1.0 - reserved())


## Po włączeniu albo wyłączeniu aury: zdrowie zachowuje proporcję, mana nie wychodzi ponad wolną.
func auras_changed(old_max_health: float) -> void:
	health = clampf(health * max_health() / maxf(old_max_health, 1.0), 1.0, max_health())
	mana = minf(mana, max_mana())


## Gest ręką w stronę celu - wywołuje broń, gdy zaczyna zamach. Tylko w miejscu (w marszu postać tylko idzie).
func play_gesture(toward: Vector2) -> void:
	if not gesture or velocity.length() > 5.0:
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

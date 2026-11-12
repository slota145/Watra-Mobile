class_name ProtoLoot
extends Node2D
## Przedmiot na ziemi w lochu (z goblina albo ze skrzyni Wodza). Wyskakuje łukiem, leży z poświatą w kolorze rzadkości
## (rzadki - dodatkowo słup światła, żeby było go widać z daleka), a gdy postać podejdzie bliżej niż `magnet`, leci do niej
## i trafia do torby (`Game.add_item`, sygnał `picked`). Przy pełnej torbie odskakuje, pokazuje „Torba pełna!”
## i czeka, aż postać odejdzie i wróci (można zrobić miejsce w oknie „Postać” w pauzie). Łup ze skrzyni Wodza
## (`sell_if_full`) przy pełnej torbie sprzedaje się od razu za złoto, żeby nie przepadł po oknie zwycięstwa.
## Z włączoną auto sprzedażą (`Game.auto_sell_common`) zwykły przedmiot od razu zamienia się w złoto.
## Arena pokazuje powiadomienie o każdym podniesionym i sprzedanym przedmiocie (sygnały `picked`, `sold`).

signal picked(item: Dictionary)
## Przedmiot sprzedany od razu: auto sprzedaż zwykłych albo pełna torba (`bag_full`, łup ze skrzyni).
signal sold(item: Dictionary, price: int, bag_full: bool)

const MAGNET := 36.0
const PICKUP := 6.0
## Ikony z Watry mają 64 px - na ziemi zmniejszone.
const ICON_SCALE := 0.45
const SOUND := preload("res://assets/watra/handleSmallLeather.ogg")
const SOUND_RARE := preload("res://assets/watra/glass_002.ogg")
const DROP_SOUND := preload("res://assets/watra/dropLeather.ogg")

var hero: ProtoHero
var item: Dictionary = {}
var magnet := MAGNET
var spread := 12.0
## Przez tyle sekund po wypadnięciu przedmiot leży (wysyp ze skrzyni).
var delay := 0.0
## Przy pełnej torbie sprzedaj od razu (łup ze skrzyni).
var sell_if_full := false

var _sprite: Sprite2D
var _glow: Sprite2D
var _time := randf() * 10.0
var _pulled := false
var _speed := 0.0
var _taken := false
## Po nieudanym podniesieniu (pełna torba) czeka, aż postać się oddali.
var _blocked := false
var _game: Node


func _ready() -> void:
	_game = get_node("/root/Game")
	var color := Items.color_of(item)
	_glow = Sprite2D.new()
	_glow.texture = ProtoWatra._glow_texture()
	_glow.scale = Vector2.ONE * (0.3 if item.rarity == "common" else 0.45)
	_glow.modulate = Color(color, 0.35 if item.rarity == "common" else 0.6)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	add_child(_glow)
	if item.rarity == "rare":
		add_child(_Beam.new())
	_sprite = Sprite2D.new()
	_sprite.texture = Items.icon_of(item)
	_sprite.scale = Vector2.ONE * ICON_SCALE
	add_child(_sprite)
	var land := position + Vector2(randf_range(-spread, spread), randf_range(-spread * 0.3, spread * 0.5))
	_sprite.position.y = -14.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", land, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "position:y", -7.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	_play(DROP_SOUND, -10.0)


func _process(delta: float) -> void:
	_time += delta
	delay -= delta
	_glow.modulate.a = (0.3 if item.rarity == "common" else 0.5) + 0.12 * sin(_time * 5.0)
	if _taken or hero == null or hero.dead:
		return
	var target := hero.global_position + Vector2(0, -6)
	var to := target - global_position
	if _blocked:
		if to.length() > magnet * 1.6:
			_blocked = false
		return
	if not _pulled and delay <= 0.0 and to.length() <= magnet:
		_pulled = true
		_speed = 40.0
	if _pulled:
		_speed += 400.0 * delta
		global_position += to.normalized() * minf(_speed * delta, to.length())
		if to.length() <= PICKUP:
			_take()
	else:
		_sprite.position.y = -7.0 - 1.5 * (0.5 + 0.5 * sin(_time * 3.0))


func _take() -> void:
	var price := 0
	var bag_full := false
	if item.rarity == "common" and _game.auto_sell_common:
		price = _game.sell_loot(item)
	elif not _game.add_item(item):
		if not sell_if_full:
			_full()
			return
		bag_full = true
		price = _game.sell_loot(item)
	if price > 0:
		_float_text(tr("+%d złota") % price, Color(1, 0.85, 0.4))
	_taken = true
	if price > 0:
		sold.emit(item, price, bag_full)
	else:
		picked.emit(item)
	_play(SOUND_RARE if item.rarity == "rare" else SOUND, -6.0)
	for c in get_children():
		if c is CanvasItem:
			c.visible = false
	get_tree().create_timer(1.0).timeout.connect(queue_free)


## Pełna torba: przedmiot odskakuje od postaci i pokazuje napis.
func _full() -> void:
	_pulled = false
	_blocked = true
	var away := (global_position - hero.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	create_tween().tween_property(self, "position", position + away * 22.0, 0.25).set_ease(Tween.EASE_OUT)
	_float_text(tr("Torba pełna!"), Color(1, 0.55, 0.4))


## Napis nad przedmiotem, który unosi się i gaśnie.
func _float_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.03))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140, 16)
	label.position = position + Vector2(-70, -36)
	label.z_index = 20
	get_parent().add_child(label)  # obok przedmiotu - napis zostaje, gdy przedmiot znika
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 14.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.8)
	tween.tween_callback(label.queue_free)


func _play(stream: AudioStream, volume: float) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	audio.pitch_scale = randf_range(0.95, 1.1)
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


## Słup złotego światła nad rzadkim przedmiotem (rysowany w kodzie).
class _Beam extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.5 + 0.2 * sin(_t * 4.0)
		for i in 3:
			var w := 8.0 - i * 2.5
			draw_rect(Rect2(-w / 2.0, -60.0, w, 56.0), Color(1.0, 0.85, 0.35, 0.22 * a))

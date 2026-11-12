class_name ProtoCleaver
extends Node2D
## Tasak rzucony przez Wodza Goblinów: w locie wiruje, po upadku chwilę tkwi w ziemi, w drodze powrotnej
## znów wiruje. Lot prowadzi ProtoChief (pozycja), tu tylko wygląd: rysowany w kodzie (pixel-art z prostokątów),
## zardzewiałe żelazo i drewniany trzonek jak tasak goblina.

const IRON := Color(0.54, 0.51, 0.5)
const IRON_DARK := Color(0.24, 0.22, 0.22)
const EDGE := Color(0.82, 0.8, 0.76)
const RUST := Color(0.48, 0.23, 0.09)
const WOOD := Color(0.36, 0.22, 0.13)
const SPIN := 14.0

## Wbity w ziemię (nie wiruje).
var landed := false
## Wraca do Wodza.
var returning := false

var _shadow: Sprite2D
var _art: Node2D


func _ready() -> void:
	z_index = 2
	_art = Node2D.new()
	_art.draw.connect(_draw_art)
	add_child(_art)


func _process(delta: float) -> void:
	if landed and not returning:
		_art.rotation = 2.3
	else:
		_art.rotation += SPIN * delta


func _draw_art() -> void:
	# trzonek
	_art.draw_rect(Rect2(-9, -1.5, 8, 3), WOOD)
	# głownia: szeroki prostokąt z ostrzem na dole i plamą rdzy
	_art.draw_rect(Rect2(-2, -5, 12, 10), IRON_DARK)
	_art.draw_rect(Rect2(-1, -4, 10, 8), IRON)
	_art.draw_rect(Rect2(-1, 3, 10, 1), EDGE)
	_art.draw_rect(Rect2(5, -3, 3, 2), RUST)

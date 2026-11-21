class_name ProtoWichrowiec
extends ProtoGoblinBrute
## Wichrowiec - silny potwór Podniebnych wysp (Dungeons.SKY, ustalone z autorem 21.11.2026): kamienny żywiołak na
## leju trąby powietrznej. Jak goblin osiłek (wolny, wytrzymały, czerwone koło przed nim, trafienie nie przerywa
## zamachu), ale w czasie zamachu nad kołem kręci się wir (`whirl`) i wciąga postać z odległości PULL_RADIUS ku
## środkowi koła z prędkością PULL_SPEED px/s (wolniej niż postać biegnie - da się uciec, ale trzeba). Cios powietrzem.
## Nie piszczy przy ucieczce. Grafika: assets/spritekiln/wichrowiec/wichrowiec.tscn (idle, walk, attack ze zdarzeniem
## `hit`, hit, death).

const WICHROWIEC_SCENE := "res://assets/spritekiln/wichrowiec/wichrowiec.tscn"
const WICHROWIEC_HP := 170
const WICHROWIEC_SPEED := 25.0
const WICHROWIEC_DAMAGE := 22
const PULL_RADIUS := 80.0
const PULL_SPEED := 34.0
const WHIRL_FX := preload("res://assets/effects/whirl.png")
const WHIRL_FRAMES := 8
const WHIRL_ANCHOR := Vector2(48, 40)
## Wir nad kołem: skala arkusza (promień wiru w klatce ~44 px).
const WHIRL_SIZE := SLAM_RADIUS / 44.0

var _whirl: Sprite2D


func _init() -> void:
	super()
	scene_path = WICHROWIEC_SCENE
	max_hp = WICHROWIEC_HP
	speed = WICHROWIEC_SPEED
	damage = WICHROWIEC_DAMAGE
	element = Elements.AIR
	squeaks = false
	fallback_color = Color(0.7, 0.75, 0.82)
	anim_hit_at = 0.7  # ręce spadają w animacji `attack` po ok. 0,7 s (zdarzenie `hit`)


## Czy właśnie wciąga postać (testy).
func pulling() -> bool:
	return _state == "attack" and not _struck and _telegraph != null and is_instance_valid(_telegraph)


func _process(delta: float) -> void:
	super(delta)
	if pulling() and _stunned <= 0.0 and hero and not hero.dead:
		var center := _telegraph.global_position
		var to := center - hero.global_position
		if to.length() < PULL_RADIUS and to.length() > 2.0:
			hero.drift(to.normalized() * minf(PULL_SPEED * delta, to.length()))
	if not pulling():
		_remove_whirl()


func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_remove_whirl()
	if _telegraph:
		_whirl = Fx.loop(get_parent(), WHIRL_FX, WHIRL_FRAMES, 20.0, _telegraph.position, WHIRL_ANCHOR, -1, WHIRL_SIZE)
		_whirl.modulate = Color(1.0, 1.0, 1.0, 0.7)


func _remove_whirl() -> void:
	if _whirl and is_instance_valid(_whirl):
		_whirl.queue_free()
	_whirl = null


func _die() -> void:
	_remove_whirl()
	super()


func _exit_tree() -> void:
	_remove_whirl()
	super()

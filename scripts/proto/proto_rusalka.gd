class_name ProtoRusalka
extends ProtoGoblinBrute
## Topielica - silny potwór Zatopionych podziemi (Dungeons.FLOODED, ustalone z autorem 15.11.2026): jak goblin osiłek
## (koło ostrzeżenia, trafienie nie przerywa zamachu), ale koło leży wokół niej samej - unosi ręce i zamraża ziemię
## dookoła. Cios to lód (odporność na żywioły go zmniejsza), trafiona postać jest mocno spowolniona (FREEZE_SLOW
## na FREEZE_TIME s). Nie piszczy przy ucieczce. Grafika: assets/spritekiln/rusalka/rusalka.tscn (idle, walk,
## attack ze zdarzeniem `hit`, hit, death).

const RUSALKA_SCENE := "res://assets/spritekiln/rusalka/rusalka.tscn"
const RUSALKA_HP := 130
const RUSALKA_SPEED := 30.0
const FREEZE_DAMAGE := 20
## Koło wokół niej: promień i z jakiej odległości zaczyna (postać musi z niego wyjść).
const RING_RADIUS := 34.0
const RING_RANGE := 30.0
const FREEZE_SLOW := 0.5
const FREEZE_TIME := 1.5
const ICE_TINT := Color(0.6, 0.9, 1.0)
## Ręce opadają w animacji `attack` po tylu sekundach (zdarzenie `hit`).
const RUSALKA_HIT_AT := 0.68


func _init() -> void:
	super()
	scene_path = RUSALKA_SCENE
	max_hp = RUSALKA_HP
	speed = RUSALKA_SPEED
	damage = FREEZE_DAMAGE
	element = Elements.COLD
	squeaks = false
	fallback_color = Color(0.85, 0.92, 1.0)
	anim_hit_at = RUSALKA_HIT_AT


func _walk_move(to_hero: Vector2) -> Vector2:
	if to_hero.length() <= RING_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
		return Vector2.ZERO
	if to_hero.length() > RING_RANGE * 0.6:
		_face(to_hero)
		return to_hero.normalized() * speed * speed_factor()
	return Vector2.ZERO


## Zamach: koło wokół topielicy (nie przed nią).
func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_telegraph.radius = RING_RADIUS
	_telegraph.position = position


## Lodowy wybuch: zamiast kurzu - rozprysk wody w kolorze lodu.
func _strike() -> void:
	_struck = true
	if _telegraph and is_instance_valid(_telegraph):
		if hero and not hero.dead and _telegraph.contains(hero.global_position):
			hero.take_damage(hit_damage(), element)
			_hit_hero()
		var fx := Fx.once(get_parent(), ProtoArrow.WATER_HIT, ProtoArrow.WATER_HIT_FRAMES, 14.0, _telegraph.global_position,
				ProtoArrow.WATER_HIT_ANCHOR, 20, RING_RADIUS / 18.0)
		fx.modulate = ICE_TINT
	_remove_telegraph()
	_audio.stream = SLAM_SOUND
	_audio.pitch_scale = randf_range(1.3, 1.45)
	_audio.play()


func _hit_hero() -> void:
	hero.slow(FREEZE_SLOW, FREEZE_TIME, ICE_TINT.lerp(Color.WHITE, 0.3))

class_name ProtoSkeletonKnight
extends ProtoGoblinBrute
## Rycerz-szkielet - silny potwór Katakumb (Dungeons.CATACOMBS, ustalone z autorem 15.11.2026): jak goblin osiłek
## (wolny, wytrzymały, trafienie nie przerywa zamachu, ostrzeżenie na ziemi), ale tnie szerokim zamachem miecza:
## ostrzeżenie to wachlarz SWEEP_ARC przed nim (ProtoTelegraph.arc) o promieniu SWEEP_RADIUS - trzeba odejść
## albo zajść go z boku / od tyłu. Cios fizyczny. Nie piszczy przy ucieczce. Grafika:
## assets/spritekiln/skeleton_knight/skeleton_knight.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death).

const KNIGHT_SCENE := "res://assets/spritekiln/skeleton_knight/skeleton_knight.tscn"
const KNIGHT_HP := 170
const KNIGHT_SPEED := 26.0
const SWEEP_DAMAGE := 24
const SWEEP_RADIUS := 44.0
const SWEEP_ARC := deg_to_rad(120.0)
## Zaczyna zamach z tej odległości.
const SWEEP_RANGE := 34.0
## Miecz przechodzi przez środek wachlarza tyle sekund po początku animacji `attack` (zdarzenie `hit`).
const KNIGHT_HIT_AT := 0.7


func _init() -> void:
	super()
	scene_path = KNIGHT_SCENE
	max_hp = KNIGHT_HP
	speed = KNIGHT_SPEED
	damage = SWEEP_DAMAGE
	squeaks = false
	fallback_color = Color(0.45, 0.42, 0.45)
	anim_hit_at = KNIGHT_HIT_AT


func _walk_move(to_hero: Vector2) -> Vector2:
	if to_hero.length() <= SWEEP_RANGE and _cooldown <= 0.0:
		_start_attack(to_hero)
		return Vector2.ZERO
	if to_hero.length() > SWEEP_RANGE * 0.7:
		_face(to_hero)
		return to_hero.normalized() * speed * speed_factor()
	return Vector2.ZERO


## Zamach: wachlarz od rycerza w stronę postaci.
func _start_attack(to_hero: Vector2) -> void:
	super(to_hero)
	_telegraph.radius = SWEEP_RADIUS
	_telegraph.arc = SWEEP_ARC
	_telegraph.angle = ProtoTelegraph.ground_angle(to_hero if to_hero.length() > 1.0 else Vector2.DOWN)
	_telegraph.position = position


## Cięcie: rani w wachlarzu, efekt cięcia miecza wzdłuż łuku.
func _strike() -> void:
	_struck = true
	if _telegraph and is_instance_valid(_telegraph):
		if hero and not hero.dead and _telegraph.contains(hero.global_position):
			hero.take_damage(hit_damage(), element)
			_hit_hero()
		var tex := ProtoWeapon.SLASH_FX
		var anchor := Vector2(tex.get_width() / float(ProtoWeapon.SLASH_FRAMES), tex.get_height()) / 2.0
		var fx := Fx.once(get_parent(), tex, ProtoWeapon.SLASH_FRAMES, 18.0, global_position + Vector2(0, -10), anchor, 20,
				SWEEP_RADIUS / ProtoWeapon.SLASH_FX_RADIUS)
		fx.rotation = _telegraph.angle
	_remove_telegraph()
	_audio.stream = SLAM_SOUND
	_audio.pitch_scale = randf_range(1.5, 1.7)
	_audio.play()

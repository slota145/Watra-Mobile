class_name ProtoSkeleton
extends ProtoGoblin
## Szkielet - zwykły potwór Katakumb (Dungeons.CATACOMBS, ustalone z autorem 15.11.2026): jak goblin z tasakiem
## idzie do Wojciecha i tnie z bliska (fizycznie), ale po pierwszej śmierci rozpada się w kupkę kości (stan "pile")
## i po PILE_TIME s składa się z powrotem z połową zdrowia (animacja `rise`). Kupkę niszczy każde trafienie
## (cięcie, obszar, podpalenie) - wtedy szkielet ginie na dobre. Drugi raz już nie wstaje. Iskra żaru, łup
## i licznik pokonanych (sygnał `died`) dopiero przy ostatecznym zniszczeniu. Nie piszczy przy ucieczce.
## Grafika: assets/spritekiln/skeleton/skeleton.tscn (idle, walk, attack ze zdarzeniem `hit`, hit, death - kończy
## się kupką kości, rise - kupka składa się w szkielet).

const SKELETON_SCENE := "res://assets/spritekiln/skeleton/skeleton.tscn"
const SKELETON_HP := 34
const SKELETON_SPEED := 34.0
const SKELETON_DAMAGE := 10
## Tyle sekund leży kupka kości, zanim szkielet wstanie; tyle trwa wstawanie (bez grafiki - zegar).
const PILE_TIME := 3.0
const RISE_TIME := 0.8
## Ułamek zdrowia po wstaniu.
const REVIVE_HP := 0.5

## Czy szkielet już raz wstał (drugi raz nie wstanie).
var revived := false


func _init() -> void:
	scene_path = SKELETON_SCENE
	max_hp = SKELETON_HP
	speed = SKELETON_SPEED
	damage = SKELETON_DAMAGE
	squeaks = false
	fallback_color = Color(0.9, 0.88, 0.8)


## Czy leży jako kupka kości (albo właśnie wstaje).
func is_pile() -> bool:
	return _state == "pile" or _state == "rise"


func _process(delta: float) -> void:
	if not is_pile():
		super(delta)
		return
	_timer += delta
	if _state == "pile" and _timer >= PILE_TIME:
		_rise()
	elif _state == "rise" and _timer >= RISE_TIME:
		_state = "walk"
		_cooldown = 0.4
		add_to_group(ProtoWeapon.TARGETS)


## Pierwsza śmierć: kupka kości zamiast śmierci (bez sygnału i iskry).
func _die() -> void:
	if revived or is_pile():
		_final_death()
		return
	_state = "pile"
	_timer = 0.0
	_push = Vector2.ZERO
	z_index = -1
	if _scene:
		_play(&"death", true)
	else:
		_sprite.scale = Vector2(1.3, 0.3)


## Wstawanie z kupki: połowa zdrowia, animacja `rise`; w trakcie nie da się go trafić.
func _rise() -> void:
	revived = true
	_state = "rise"
	_timer = 0.0
	hp = maxi(1, roundi(max_hp * power * hp_mult * REVIVE_HP))
	remove_from_group(ProtoWeapon.TARGETS)
	z_index = 0
	if _scene:
		_play(&"rise", true)
	else:
		_sprite.scale = Vector2.ONE


func _final_death() -> void:
	_state = "walk"  # super()._die ustawi "dead"
	z_index = -1
	super._die()


## Kupkę kości niszczy każde trafienie.
func take_damage(amount: int, from: Vector2) -> void:
	if _state == "pile":
		spawn_number(amount)
		_final_death()
		return
	if _state == "rise":
		return
	super(amount, from)


func burn_tick(amount: int) -> void:
	if _state == "pile":
		_final_death()
		return
	if _state == "rise":
		return
	super(amount)


func stun(time: float) -> void:
	if not is_pile():
		super(time)


func push_away(from: Vector2, force: float) -> void:
	if not is_pile():
		super(from, force)


## Kupka kości przy ucieczce przed bossem po prostu gaśnie.
func flee(squeak := true) -> void:
	if is_pile():
		_state = "flee"
		remove_from_group(ProtoWeapon.TARGETS)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
		return
	super(squeak)


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"death" and is_pile():
		return  # kupka leży (ostatnia klatka śmierci)
	if anim == &"rise":
		return  # koniec wstawania liczy zegar
	super(anim)

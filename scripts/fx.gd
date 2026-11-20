class_name Fx
## Pomocnik efektów z kreatora PixelLab (arkusze z tools/vfx_art.py w assets/effects/: jeden rząd klatek).
## Wzorowane na SkillEffects.sheet_once z Watry.


## Ile efektów `once` z danym arkuszem trwa teraz (identyfikator tekstury -> liczba) - `crowded`.
static var _live := {}


## Czy efektów `once` z arkuszem `texture` jest już co najmniej `cap` naraz. Drobne efekty trafień (rozbryzgi,
## iskry, płomyki) przy tłumie 150-250 potworów szły w setki naraz (560 rozbryzgów hydrosfery) - wtedy się je
## pomija, i tak ich nie widać w kłębowisku (tools/combat_bench.gd, 20.11.2026).
static func crowded(texture: Texture2D, cap := HIT_CAP) -> bool:
	return _live.get(texture.get_instance_id(), 0) >= cap


## Domyślny limit drobnych efektów trafień jednego rodzaju naraz (`crowded`).
const HIT_CAP := 40


## Odtwarza arkusz raz w punkcie `at` (współrzędne świata) i usuwa efekt. `anchor` - punkt zaczepienia w klatce
## (z pixellab_src/vfx/ids.json), `size` - skala efektu. Zwraca węzeł efektu (np. do obrócenia).
static func once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		z := 20, size := 1.0) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = z
	fx.scale = Vector2.ONE * size
	parent.add_child(fx)
	fx.global_position = at
	var key := texture.get_instance_id()
	_live[key] = _live.get(key, 0) + 1
	fx.tree_exiting.connect(func() -> void: _live[key] = _live.get(key, 1) - 1)
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)
	return fx


## Zapętlony arkusz (aura, smuga) jako dziecko `parent` w jego współrzędnych `at`; trwa, aż ktoś go usunie.
static func loop(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		z := 0, size := 1.0) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = z
	fx.scale = Vector2.ONE * size
	fx.position = at
	parent.add_child(fx)
	var tween := fx.create_tween().set_loops()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	return fx

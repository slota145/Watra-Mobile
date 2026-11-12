class_name Fx
## Pomocnik efektów z kreatora PixelLab (arkusze z tools/vfx_art.py w assets/effects/: jeden rząd klatek).
## Wzorowane na SkillEffects.sheet_once z Watry.


## Odtwarza arkusz raz w punkcie `at` (współrzędne świata) i usuwa efekt. `anchor` - punkt zaczepienia w klatce
## (z pixellab_src/vfx/ids.json). Zwraca węzeł efektu (np. do obrócenia).
static func once(parent: Node, texture: Texture2D, frames: int, fps: float, at: Vector2, anchor: Vector2,
		z := 20) -> Sprite2D:
	var fx := Sprite2D.new()
	fx.texture = texture
	fx.hframes = frames
	fx.centered = false
	fx.offset = -anchor
	fx.z_index = z
	parent.add_child(fx)
	fx.global_position = at
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, (frames - 1) / fps).from(0)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(fx.queue_free)
	return fx

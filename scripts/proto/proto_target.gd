class_name ProtoTarget
extends Node2D
## Wspólna podstawa wszystkiego, co lewitujący miecz może ciąć (kukła, potwory Hordy).
## Miecz celuje w `center()`, tnie przez `take_damage()` i pomija cele, dla których `alive()` zwraca false.

## Wysokość środka celu nad ziemią (tam celuje broń i wyskakują liczby).
var center_height := 18.0


## Punkt, w który celuje broń.
func center() -> Vector2:
	return global_position + Vector2(0, -center_height)


## Czy cel można jeszcze trafić (martwy potwór - nie).
func alive() -> bool:
	return true


## Trafienie bronią; `from` - skąd przyszedł cios (postać).
func take_damage(_amount: int, _from: Vector2) -> void:
	pass


## Ogłuszenie na `time` sekund (Rozłupanie Ziemi). Domyślnie nic - bossy i kukły się nie zatrzymują.
func stun(_time: float) -> void:
	pass


## Liczba obrażeń wyskakująca nad celem.
func spawn_number(amount: int, color := Color(1.0, 0.95, 0.8)) -> void:
	var num := Label.new()
	num.text = str(amount)
	num.add_theme_font_size_override("font_size", 12)
	num.add_theme_color_override("font_color", color)
	num.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.05))
	num.add_theme_constant_override("outline_size", 4)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(40, 16)
	num.position = Vector2(-20 + randf_range(-8, 8), -center_height - 26)
	num.z_index = 20
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", num.position.y - 18, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(num.queue_free)

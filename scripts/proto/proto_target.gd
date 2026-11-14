class_name ProtoTarget
extends Node2D
## Wspólna podstawa wszystkiego, co lewitujący miecz może ciąć (kukła, potwory Hordy).
## Miecz celuje w `center()`, tnie przez `take_damage()` i pomija cele, dla których `alive()` zwraca false.
## Kamienie umiejętności (Gems): podpalenie (`burn` - obrażenia co BURN_TICK przez `burn_tick`, pomarańczowe liczby)
## i spowolnienie (`slow` - potwory mnożą prędkość przez `speed_factor()`); znaczki rysuje węzeł _Status pod celem.
## Podpalony cel płonie (14.11.2026): zapętlone płomienie z kreatora efektów (assets/effects/burning.png) za nim,
## skalowane do jego wysokości (`center_height`), gasną pod koniec podpalenia.

## Kolor i wielkość liczby trafienia krytycznego.
const CRIT_COLOR := Color(1.0, 0.82, 0.25)
const CRIT_SIZE := 15

## Wysokość środka celu nad ziemią (tam celuje broń i wyskakują liczby).
var center_height := 18.0
## Następna liczba obrażeń to trafienie krytyczne (ustawia miecz tuż przed take_damage; liczba złota, większa, z „!”).
var crit_next := false


## Punkt, w który celuje broń.
func center() -> Vector2:
	return global_position + Vector2(0, -center_height)


## Czy cel można jeszcze trafić (martwy potwór - nie).
func alive() -> bool:
	return true


## Trafienie bronią; `from` - skąd przyszedł cios (postać).
func take_damage(_amount: int, _from: Vector2) -> void:
	pass


## Odepchnięcie od punktu `from` z siłą `force` (wybuch Młynka na 10. poziomie). Domyślnie nic - bossy i kukły stoją.
func push_away(_from: Vector2, _force: float) -> void:
	pass


## Ogłuszenie na `time` sekund (Rozłupanie Ziemi). Domyślnie nic - bossy i kukły się nie zatrzymują.
func stun(_time: float) -> void:
	pass


## Podpalenie: razem `total` obrażeń rozłożonych na `time` sekund (nowe podpalenie zastępuje słabsze).
func burn(total: float, time: float) -> void:
	if not alive() or total <= 0.0 or time <= 0.0:
		return
	var st := _status()
	var dps := total / time
	if dps >= st.burn_dps or st.burn_left <= 0.0:
		st.burn_dps = dps
	st.burn_left = maxf(st.burn_left, time)


## Spowolnienie o `amount` (0-1, np. 0.25 - o 25%) na `time` sekund (silniejsze wygrywa).
func slow(amount: float, time: float) -> void:
	if not alive() or amount <= 0.0:
		return
	var st := _status()
	if amount >= st.slow or st.slow_left <= 0.0:
		st.slow = amount
	st.slow_left = maxf(st.slow_left, time)


## Mnożnik prędkości potwora (spowolnienie Szronem; 1.0 - bez).
func speed_factor() -> float:
	var st := get_node_or_null(^"_Status") as _Status
	return 1.0 - st.slow if st and st.slow_left > 0.0 else 1.0


## Obrażenia od podpalenia. Domyślnie zwykłe trafienie; potwory nadpisują (bez odrzutu i przerwania ataku).
func burn_tick(amount: int) -> void:
	take_damage(amount, global_position)


func _status() -> _Status:
	var st := get_node_or_null(^"_Status") as _Status
	if st and st.is_queued_for_deletion():
		st.name = "_StatusOld"
		st = null
	if st == null:
		st = _Status.new()
		st.name = "_Status"
		st.target = self
		add_child(st)
	return st


## Liczba obrażeń wyskakująca nad celem.
func spawn_number(amount: int, color := Color(1.0, 0.95, 0.8)) -> void:
	var crit := crit_next
	crit_next = false
	var num := Label.new()
	num.text = str(amount) + ("!" if crit else "")
	if crit:
		color = CRIT_COLOR
	num.add_theme_font_size_override("font_size", CRIT_SIZE if crit else 12)
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


## Podpalenie i spowolnienie celu: odlicza czas, zadaje obrażenia podpalenia, pokazuje płomienie (za celem)
## i szronowy krąg u stóp. Znika, gdy oba efekty wygasną.
class _Status extends Node2D:
	const BURN_TICK := 0.5
	const FLAMES := preload("res://assets/effects/burning.png")
	const FLAMES_FRAMES := 8
	const FLAMES_FPS := 12.0
	const FLAMES_ANCHOR := Vector2(16, 28)
	## Wysokość celu, do której narysowano płomienie (goblin), skala płomieni za celem (wystają zza niego)
	## i przed nim (oba świecące - mieszanie addytywne, cel dalej widać).
	const FLAMES_HEIGHT := 18.0
	const BACK_SCALE := 1.6
	const FRONT_SCALE := 0.8
	const FRONT_ALPHA := 0.75
	var target: ProtoTarget
	var burn_dps := 0.0
	var burn_left := 0.0
	var slow := 0.0
	var slow_left := 0.0
	var _acc := 0.0
	var _tick := BURN_TICK
	var _t := 0.0
	var _flames: Sprite2D
	var _front: Sprite2D

	func _ready() -> void:
		z_index = 1
		var k := maxf(target.center_height / FLAMES_HEIGHT, 0.6)
		_flames = _flame_sprite(k * BACK_SCALE, -2)  # za celem (węzeł stanu ma +1 względem celu)
		_front = _flame_sprite(k * FRONT_SCALE, 0)
		_front.self_modulate.a = FRONT_ALPHA
		var glow := CanvasItemMaterial.new()  # świecący ogień: ciemny kontur efektu znika, cel prześwituje
		glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_flames.material = glow
		_front.material = glow

	func _flame_sprite(size: float, z: int) -> Sprite2D:
		var s := Sprite2D.new()
		s.texture = FLAMES
		s.hframes = FLAMES_FRAMES
		s.centered = false
		s.offset = -FLAMES_ANCHOR
		s.scale = Vector2.ONE * size
		s.z_index = z
		s.visible = false
		add_child(s)
		return s

	func _process(delta: float) -> void:
		_t += delta
		slow_left -= delta
		if burn_left > 0.0:
			burn_left -= delta
			_acc += burn_dps * delta
			_tick -= delta
			if _tick <= 0.0 or burn_left <= 0.0:
				_tick = BURN_TICK
				var dmg := int(_acc)
				if dmg > 0 and target.alive():
					_acc -= dmg
					target.burn_tick(dmg)
		if not target.alive() or (burn_left <= 0.0 and slow_left <= 0.0):
			queue_free()
			return
		var on := burn_left > 0.0
		for f in [_flames, _front]:
			f.visible = on
			if on:
				var first := get_instance_id() % FLAMES_FRAMES + (3 if f == _front else 0)
				f.frame = int(_t * FLAMES_FPS + first) % FLAMES_FRAMES
				f.modulate.a = clampf(burn_left / 0.4, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		if slow_left > 0.0:
			var a := clampf(slow_left * 2.0, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, Color(0.6, 0.9, 1.0, 0.75 * a), 1.5)
			draw_set_transform(Vector2.ZERO)


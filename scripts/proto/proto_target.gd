class_name ProtoTarget
extends Node2D
## Wspólna podstawa wszystkiego, co lewitujący miecz może ciąć (kukła, potwory Hordy).
## Miecz celuje w `center()`, tnie przez `take_damage()` i pomija cele, dla których `alive()` zwraca false.
## Kamienie umiejętności (Gems): podpalenie (`burn` - obrażenia co BURN_TICK przez `burn_tick`, pomarańczowe liczby)
## i spowolnienie (`slow` - potwory mnożą prędkość przez `speed_factor()`); znaczki rysuje węzeł _Status pod celem.
## Podpalony cel płonie (14.11.2026): zapętlone płomienie z kreatora efektów (assets/effects/burning.png) za nim,
## skalowane do jego wysokości (`center_height`), gasną pod koniec podpalenia. Przemoczony (`soak`, 15.11.2026) - kapią
## z niego krople z kreatora (assets/effects/soak_drips.png); porażony (`shock`) - wokół przeskakują iskry.

## Kolor i wielkość liczby trafienia krytycznego.
const CRIT_COLOR := Color(1.0, 0.82, 0.25)
const CRIT_SIZE := 15
## Wydajność w tłumie (pomiar `tools/combat_bench.gd`, 20.11.2026): najwyżej tyle liczb obrażeń naraz (krytyczne
## zawsze), a dźwięk trafienia najwyżej co HIT_SOUND_GAP ms dla wszystkich wrogów razem - każde uruchomienie dźwięku
## kosztowało ok. 0,7 ms, a przy pełnej walce trafień jest kilkanaście na klatkę.
const MAX_NUMBERS := 60
const HIT_SOUND_GAP := 45
static var _numbers := 0
static var _next_hit_sound := 0

## Wysokość środka celu nad ziemią (tam celuje broń i wyskakują liczby).
var center_height := 18.0
## Po zamrożeniu (freeze) tyle sekund odporności na kolejne.
const FREEZE_IMMUNE := 2.0

## Następna liczba obrażeń to trafienie krytyczne (ustawia miecz tuż przed take_damage; liczba złota, większa, z „!”).
var crit_next := false
var _st: _Status = null  # węzeł stanu (_status, _st_live)
## Odporności na żywioły (Dungeons.RESISTS lochu; żywioł -> ułamek, ujemny - wrażliwość).
var resists := {}
## Kolor następnej liczby obrażeń (żywioł kamienia: piorun, szron; przezroczysty - zwykły biały).
var color_next := Color(0, 0, 0, 0)
## Aury postaci (Auras, ProtoAuras): Postrach (`aura_weak` - o tyle mniej obrażeń), Mgła Nawii (`aura_miss` - szansa
## na chybienie) - działają do `aura_until` (czas gry w s; krąg odnawia znak co Auras.CIRCLE_TICK); Piętno Czarnoboga
## (`pride` - o tyle więcej obrażeń od postaci, rośnie w kręgu).
var aura_weak := 0.0
var aura_miss := 0.0
var aura_until := 0.0
var pride := 0.0
## Aura Złość Licha (ustawia arena): podpalenia mocniejsze (`burn_power`) i dłuższe (`burn_length`) - wspólne dla celów.
static var burn_power := 1.0
static var burn_length := 1.0
var _freeze_ready := -INF


## Odporność na żywioł (przycięta do granic Elements); `pen` - przebicie odporności postaci (ułamek): zmniejsza
## odporność najwyżej do zera, wrażliwości nie pogłębia.
func resist(element: String, pen := 0.0) -> float:
	var r := clampf(float(resists.get(element, 0.0)), Elements.MIN_RESISTANCE, Elements.MAX_RESISTANCE)
	return maxf(r - pen, minf(r, 0.0))


## Cios tego celu w postać - przez aury postaci: w kręgu Mgły Nawii czasem chybia (napis nad postacią), w kręgu
## Postrachu zadaje mniej. Potwory wołają to zamiast `hero.take_damage`.
func hit_hero(hero: ProtoHero, amount: int, element := Elements.PHYSICAL) -> void:
	if aura_until > Time.get_ticks_msec() / 1000.0:
		if aura_miss > 0.0 and randf() < aura_miss:
			hero.enemy_missed()
			return
		amount = maxi(1, roundi(amount * (1.0 - aura_weak)))
	if is_withered():  # osłabiony Nawią (mroczna kosa)
		amount = maxi(1, roundi(amount * (1.0 - Elements.NAWIA_WEAK)))
	hero.take_damage(amount, element)


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
func burn(total: float, time: float, pen := 0.0) -> void:
	if not alive() or total <= 0.0 or time <= 0.0:
		return
	total *= 1.0 - resist(Elements.FIRE, pen)  # podpalenie to ogień
	total *= burn_power * burn_length  # Złość Licha: dłużej przy tych samych obrażeniach na sekundę, i mocniej
	time *= burn_length
	var st := _status()
	var dps := total / time
	if dps >= st.burn_dps or st.burn_left <= 0.0:
		st.burn_dps = dps
	st.burn_left = maxf(st.burn_left, time)


## Trucizna natury (Elements.POISON_*): dokłada znak (najwyżej Elements.POISON_STACKS), każdy zadaje `per_stack`
## obrażeń na sekundę (najsilniejszy znak wyznacza siłę wszystkich), czas odnawia się do `time`. Zielone liczby.
func poison(per_stack: float, time := Elements.POISON_TIME, pen := 0.0) -> void:
	if not alive() or per_stack <= 0.0 or time <= 0.0:
		return
	var st := _status()
	if st.poison_left <= 0.0:
		st.poison_stacks = 0
		st.poison_dps = 0.0
	st.poison_stacks = mini(st.poison_stacks + 1, Elements.POISON_STACKS)
	st.poison_dps = maxf(st.poison_dps, per_stack * (1.0 - resist(Elements.NATURE, pen)))
	st.poison_left = maxf(st.poison_left, time)


## Ile znaków trucizny ma wróg (0 - nie jest zatruty).
func poison_stacks() -> int:
	var st := _st_live()
	return st.poison_stacks if st and st.poison_left > 0.0 else 0


## Czy wróg jest zatruty (kamień Pylenia Mchu - zatruci wybuchają po śmierci).
func is_poisoned() -> bool:
	return poison_stacks() > 0


## Spowolnienie o `amount` (0-1, np. 0.25 - o 25%) na `time` sekund (silniejsze wygrywa).
func slow(amount: float, time: float) -> void:
	if not alive() or amount <= 0.0:
		return
	var st := _status()
	if amount >= st.slow or st.slow_left <= 0.0:
		st.slow = amount
	st.slow_left = maxf(st.slow_left, time)


## Przemoczenie (hydrosfera): spowolnienie o `amount` na `time` s i znak - kapiące krople (combo z Gromem i lodem -
## Elements.soak_bonus).
func soak(amount: float, time: float) -> void:
	if not alive() or time <= 0.0:
		return
	slow(amount, time)
	var st := _status()
	st.soak_left = maxf(st.soak_left, time)


## Czy wróg jest przemoczony.
func is_soaked() -> bool:
	var st := _st_live()
	return st != null and st.soak_left > 0.0


## Porażenie (elektryczna katana): przez `time` s wróg dostaje od wszystkiego o Elements.SHOCK_BONUS więcej
## (ProtoWeapon._deal), wokół niego przeskakują iskry.
func shock(time: float) -> void:
	if not alive() or time <= 0.0:
		return
	var st := _status()
	st.shock_left = maxf(st.shock_left, time)


## Osłabienie Nawią (mroczna kosa): przez `time` s wróg zadaje o Elements.NAWIA_WEAK mniej obrażeń (`hit_hero`),
## nad głową kłębi się ciemna mgiełka z białymi drobinkami.
func wither(time: float) -> void:
	if not alive() or time <= 0.0:
		return
	var st := _status()
	st.wither_left = maxf(st.wither_left, time)


## Czy wróg jest osłabiony Nawią.
func is_withered() -> bool:
	var st := _st_live()
	return st != null and st.wither_left > 0.0


## Zamrożenie (combo lodu z przemoczeniem - Elements.SOAK_FREEZE, chłód lodowego rapiera - `chill`): ogłusza na
## `time` s i okrywa wroga lodem, potem przez FREEZE_IMMUNE s nie da się zamrozić znowu (żeby lód nie trzymał wroga
## w miejscu bez końca). Zwraca, czy zamroziło.
func freeze(time: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if not alive() or now < _freeze_ready:
		return false
	_freeze_ready = now + time + FREEZE_IMMUNE
	stun(time)
	var st := _status()
	st.frozen_left = maxf(st.frozen_left, time)
	st.chill = 0
	return true


## Chłód lodu (Elements.CHILL_*): spowalnia o `amount` na `time` s i dokłada `stacks` znaków chłodu; po
## Elements.CHILL_STACKS znakach wróg zamarza na `freeze_time` s. Znaki znikają, gdy spowolnienie minie. Zwraca, czy
## zamroziło.
func chill(amount := Elements.CHILL_SLOW, time := Elements.CHILL_TIME, stacks := 1, freeze_time := Elements.CHILL_FREEZE) -> bool:
	if not alive():
		return false
	slow(amount, time)
	var st := _status()
	if st.frozen_left > 0.0:
		return false
	st.chill += stacks
	if st.chill >= Elements.CHILL_STACKS:
		st.chill = 0
		return freeze(freeze_time)
	return false


## Ile znaków chłodu ma wróg (testy, okno pomocy).
func chill_stacks() -> int:
	var st := _st_live()
	return st.chill if st and st.slow_left > 0.0 else 0


## Czy wróg jest zamrożony (roztrzaskanie lodowego rapiera).
func is_frozen() -> bool:
	var st := _st_live()
	return st != null and st.frozen_left > 0.0


## Kończy zamrożenie (roztrzaskanie - lód pęka; ogłuszenie potwora mija samo).
func thaw() -> void:
	var st := _st_live()
	if st:
		st.frozen_left = 0.0


## Czy wróg płonie (podpalenie trwa) - kamień Spalenie, talizman Lont Pożogi.
func is_burning() -> bool:
	var st := _st_live()
	return st != null and st.burn_left > 0.0


## Ile zdrowia zostało (0-1) - kamień Egzekucja i talizman Hak Kata. Kukła i inne cele bez zdrowia - zawsze pełne.
func health_fraction() -> float:
	return 1.0


## Ile obrażeń trzeba, żeby wróg padł (z tarczą elity) - dobijanie (Egzekucja, Hak Kata). 0 - nie da się dobić.
func remaining_hp() -> int:
	return 0


## Czy wróg jest porażony.
func is_shocked() -> bool:
	var st := _st_live()
	return st != null and st.shock_left > 0.0


## Mnożnik prędkości potwora (spowolnienie Szronem; 1.0 - bez).
func speed_factor() -> float:
	var st := _st_live()
	return 1.0 - st.slow if st and st.slow_left > 0.0 else 1.0


## Obrażenia od podpalenia. Domyślnie zwykłe trafienie; potwory nadpisują (bez odrzutu i przerwania ataku).
func burn_tick(amount: int) -> void:
	take_damage(amount, global_position)


func _status() -> _Status:
	var st := _st_live()
	if st == null:
		var old := get_node_or_null(^"_Status")
		if old:
			old.name = "_StatusOld"  # znikający - nowy dostaje swoją nazwę
		st = _Status.new()
		st.name = "_Status"
		st.target = self
		add_child(st)
		_st = st
	return st


## Węzeł stanu, jeśli trwa (zapamiętany w polu - pytają o niego trafienia i ruch potwora co klatkę, a szukanie
## węzła po nazwie było wyraźnie droższe; tools/combat_bench.gd).
func _st_live() -> _Status:
	if _st != null and is_instance_valid(_st) and not _st.is_queued_for_deletion():
		return _st
	return null


## Liczba obrażeń wyskakująca nad celem.
func spawn_number(amount: int, color := Color(1.0, 0.95, 0.8)) -> void:
	var crit := crit_next
	crit_next = false
	if color_next.a > 0.0:
		color = color_next
		color_next = Color(0, 0, 0, 0)
	if _numbers >= (MAX_NUMBERS + MAX_NUMBERS / 2 if crit else MAX_NUMBERS):  # krytyczne mają trochę zapasu
		return
	_numbers += 1
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
	num.tree_exiting.connect(func() -> void: _numbers -= 1)


## Czy wolno teraz zagrać dźwięk trafienia (wspólny limit wszystkich wrogów - HIT_SOUND_GAP).
static func hit_sound_ok() -> bool:
	var now := Time.get_ticks_msec()
	if now < _next_hit_sound:
		return false
	_next_hit_sound = now + HIT_SOUND_GAP
	return true


## Podpalenie, spowolnienie, przemoczenie i porażenie celu: odlicza czas, zadaje obrażenia podpalenia, pokazuje
## płomienie (za celem), kapiące krople, iskry i szronowy krąg u stóp. Znika, gdy wszystkie efekty wygasną.
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
	## Krople przemoczenia: arkusz, klatki, fps, zaczepienie (środek celu), skala przy goblinie.
	const DRIPS := preload("res://assets/effects/soak_drips.png")
	const DRIPS_FRAMES := 12
	const DRIPS_FPS := 12.0
	const DRIPS_ANCHOR := Vector2(17, 10)
	const DRIPS_SCALE := 0.6
	## Iskry porażenia: kolor, co ile nowy zygzak.
	const SPARK := Color(1.0, 0.95, 0.55)  # kolor Gromu (Elements.COLORS) - odróżnia się od niebieskich kropli
	const SPARK_EVERY := 0.12
	var target: ProtoTarget
	var burn_dps := 0.0
	var burn_left := 0.0
	var slow := 0.0
	var slow_left := 0.0
	var soak_left := 0.0
	var shock_left := 0.0
	var wither_left := 0.0
	## Lód: znaki chłodu (zerują się z końcem spowolnienia) i czas zamrożenia.
	var chill := 0
	var frozen_left := 0.0
	## Natura: znaki trucizny, obrażenia na sekundę jednego znaku, czas, zebrane ułamki obrażeń.
	var poison_stacks := 0
	var poison_dps := 0.0
	var poison_left := 0.0
	var _poison_acc := 0.0
	var _poison_tick := BURN_TICK
	var _acc := 0.0
	var _tick := BURN_TICK
	var _t := 0.0
	var _flames: Sprite2D
	var _front: Sprite2D
	var _drips: Sprite2D
	var _spark_t := 0.0
	var _spark_seed := 0

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
		_drips = Sprite2D.new()
		_drips.texture = DRIPS
		_drips.hframes = DRIPS_FRAMES
		_drips.centered = false
		_drips.offset = -DRIPS_ANCHOR
		_drips.position = Vector2(0, -target.center_height)
		_drips.scale = Vector2.ONE * DRIPS_SCALE * clampf(target.center_height / FLAMES_HEIGHT, 0.8, 1.6)
		_drips.z_index = 1
		_drips.visible = false
		add_child(_drips)

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
		soak_left -= delta
		shock_left -= delta
		wither_left -= delta
		frozen_left -= delta
		if slow_left <= 0.0:
			chill = 0
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
		if poison_left > 0.0:
			poison_left -= delta
			_poison_acc += poison_dps * poison_stacks * delta
			_poison_tick -= delta
			if _poison_tick <= 0.0 or poison_left <= 0.0:
				_poison_tick = BURN_TICK
				var pdmg := int(_poison_acc)
				if pdmg > 0 and target.alive():
					_poison_acc -= pdmg
					target.color_next = Elements.color_of(Elements.NATURE)
					target.burn_tick(pdmg)
			if poison_left <= 0.0:
				poison_stacks = 0
		if not target.alive() or (burn_left <= 0.0 and poison_left <= 0.0 and slow_left <= 0.0 and soak_left <= 0.0 and shock_left <= 0.0
				and wither_left <= 0.0 and frozen_left <= 0.0):
			queue_free()
			return
		var on := burn_left > 0.0
		for f in [_flames, _front]:
			f.visible = on
			if on:
				var first := get_instance_id() % FLAMES_FRAMES + (3 if f == _front else 0)
				f.frame = int(_t * FLAMES_FPS + first) % FLAMES_FRAMES
				f.modulate.a = clampf(burn_left / 0.4, 0.0, 1.0)
		_drips.visible = soak_left > 0.0
		if _drips.visible:
			_drips.frame = int(_t * DRIPS_FPS + get_instance_id() % DRIPS_FRAMES) % DRIPS_FRAMES
			_drips.modulate.a = clampf(soak_left / 0.4, 0.0, 1.0)
		if shock_left > 0.0 or wither_left > 0.0:
			_spark_t -= delta
			if _spark_t <= 0.0:
				_spark_t = SPARK_EVERY
				_spark_seed += 1
		queue_redraw()

	func _draw() -> void:
		if wither_left > 0.0:
			# Nawia: ciemna mgiełka nad głową (kilka czarnych kłębków) z białymi drobinkami, przesuwa się co SPARK_EVERY
			var a := clampf(wither_left / 0.4, 0.0, 1.0)
			var rng := RandomNumberGenerator.new()
			rng.seed = get_instance_id() + _spark_seed
			var top := -target.center_height * 2.0 - 3.0
			for i in 4:
				var p := Vector2(rng.randf_range(-7.0, 7.0), top + rng.randf_range(-3.0, 3.0))
				draw_circle(p, rng.randf_range(2.0, 3.5), Color(0.03, 0.02, 0.05, 0.75 * a))
			for i in 2:
				var p := Vector2(rng.randf_range(-7.0, 7.0), top + rng.randf_range(-4.0, 2.0))
				draw_rect(Rect2(p.round(), Vector2.ONE), Color(0.95, 0.95, 1.0, 0.9 * a))
		if shock_left > 0.0:
			# dwa małe zygzaki iskier przy celu, co SPARK_EVERY w innym miejscu
			var rng := RandomNumberGenerator.new()
			rng.seed = get_instance_id() + _spark_seed
			var h := target.center_height
			for i in 2:
				var p := Vector2(rng.randf_range(-8.0, 8.0), -h + rng.randf_range(-h * 0.6, h * 0.5))
				var pts := PackedVector2Array([p])
				for j in 3:
					p += Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-4.0, 4.0))
					pts.append(p)
				draw_polyline(pts, SPARK, 1.0)
		if poison_left > 0.0 and poison_stacks > 0:
			# trucizna: zielone bąbelki unoszą się nad głową - im więcej znaków, tym więcej bąbelków
			var a := clampf(poison_left * 2.0, 0.0, 1.0)
			var top := -target.center_height * 2.0 - 2.0
			for i in mini(poison_stacks, 5):
				var k := fmod(_t * 0.8 + i * 0.37, 1.0)
				var p := Vector2(sin(i * 2.3 + _t * 2.0) * 5.0, top - k * 8.0)
				draw_circle(p, 1.2 + (i % 2) * 0.6, Color(0.55, 0.95, 0.35, 0.85 * a * (1.0 - k * 0.6)))
		if frozen_left > 0.0:
			# zamrożony: bladobłękitna, półprzezroczysta bryła lodu na celu z białymi refleksami i kryształkami
			var a := clampf(frozen_left / 0.25, 0.0, 1.0)
			var h := target.center_height
			var w := maxf(h * 0.75, 8.0)
			var block := PackedVector2Array([Vector2(-w, 1), Vector2(-w - 1, -h * 1.2), Vector2(-w * 0.4, -h * 2.0 - 2.0),
					Vector2(w * 0.5, -h * 2.0), Vector2(w + 1, -h * 1.1), Vector2(w, 1)])
			draw_colored_polygon(block, Color(0.65, 0.9, 1.0, 0.38 * a))
			block.append(block[0])
			draw_polyline(block, Color(0.88, 0.98, 1.0, 0.85 * a), 1.0)
			draw_line(Vector2(-w * 0.55, -h * 1.6), Vector2(-w * 0.15, -h * 0.5), Color(1, 1, 1, 0.7 * a), 1.0)
			draw_line(Vector2(w * 0.35, -h * 1.75), Vector2(w * 0.55, -h * 1.2), Color(1, 1, 1, 0.55 * a), 1.0)
		elif chill > 0 and slow_left > 0.0:
			# znaki chłodu: tyle kryształków nad głową, ile zebrał (do zamrożenia - Elements.CHILL_STACKS)
			var a := clampf(slow_left * 2.0, 0.0, 1.0)
			var top := -target.center_height * 2.0 - 4.0
			for i in chill:
				var c := Vector2((i - (chill - 1) / 2.0) * 4.0, top)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(1.5, 0), c + Vector2(0, 2),
						c + Vector2(-1.5, 0)]), Color(0.75, 0.95, 1.0, 0.95 * a))
		if slow_left > 0.0 and soak_left <= 0.0:  # przemoczenie pokazują krople, szronowy krąg - samo spowolnienie
			var a := clampf(slow_left * 2.0, 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, Color(0.6, 0.9, 1.0, 0.75 * a), 1.5)
			draw_set_transform(Vector2.ZERO)


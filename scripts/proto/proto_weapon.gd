class_name ProtoWeapon
extends Node2D
## Lewitujący miecz z prototypu. Poza walką unosi się za ramieniem postaci (lekko się kołysze i dogania ją
## z opóźnieniem). Dopóki gracz trzyma przycisk ataku (`attack_held`), miecz co chwilę wskakuje na orbitę wokół postaci - rękojeścią do niej,
## ostrzem na zewnątrz - i tnie po łuku w stronę najbliższej kukły w zasięgu (bez kukły - przed siebie), a nad łukiem gra efekt cięcia ze zwykłego ataku Watry
## (assets/effects/sword_slash.png z kreatora efektów PixelLab). Kolejne cięcia na przemian z góry i z dołu.
## Auto atak (`auto_attack`, ustawienie w pauzie): cios sam rusza, gdy cel jest w zasięgu - tylko podstawowy atak.
## Obrażenia rosną z poziomem postaci i premiami przedmiotów (`damage_mult`), założona broń zmienia obrażenia cięcia
## (`damage`), a premia szybkości ataku przyspiesza cały cios (`speed_mult`).
## Węzeł stoi na ziemi (sortowanie po Y z postacią i kukłą), a obrazek miecza wisi wyżej (ujemne _sprite.position.y).
## Umiejętności (Skills, `cast` z małych przycisków albo `main_skill` pod dużym przyciskiem): Młynek (miecz wiruje
## wokół postaci), Rzut mieczem (leci, przebija, wraca), Rozłupanie Ziemi (spada z góry, ogłusza), Mgnienie
## (jak w Watrze: dopóki gracz trzyma przycisk - `flicker_held` - postać przeskakuje na wylot przez najbliższego
## wroga, tnąc wszystkich po drodze i wokół celu, potem przez kolejnego, za manę za każdy skok). Każda kosztuje manę (ProtoHero.spend_mana) i ma odnowienie (`cooldown_left`).
## Umiejętność pod dużym przyciskiem rusza przy trzymaniu albo z auto atakiem; bez many lub w czasie odnowienia
## miecz tnie zwykłym ciosem. Umiejętność stuknięta w trakcie innego ruchu miecza czeka w kolejce (`_queued`).
## Kamienie umiejętności (Gems, `skill_gems` z Game): każde trafienie idzie przez `_deal` - Żar podpala, Szron spowalnia,
## Krwiopijca leczy, Piorun przeskakuje na 2 wrogów (raz na klatkę, `_chained`), Oszczędność w zwykłym ciosie oddaje manę;
## Szerokość powiększa zasięg (`_area`), Pośpiech skraca odnowienie (`cooldown_full`, zwykły cios - szybszy),
## Oszczędność zmniejsza koszt (`mana_cost`), Mnożenie dodaje ostrza: drugie cięcie, widmowy miecz w Młynku
## i Rzucie (`_ghosts`), druga fala Rozłupania, dodatkowe cięcie przy skoku Mgnienia.
## Poziomy umiejętności (Skills, `skill_levels` z Game): więcej obrażeń (`_power`), mniej many i krótsze odnowienie,
## większy obszar (`_area`), a na 5. i 10. poziomie nowe działanie (`_perk`): zwykły cios - co trzeci tnie dwa razy,
## cięcie sąsiada; Młynek - dłużej, wybuch na koniec; Rzut - odbicie w kolejnego wroga, drugi miecz; Rozłupanie -
## dłuższe ogłuszenie, druga fala po chwili; Mgnienie - podwójny zwrot many za zabicie, wir co Skills.BLINK_SPIN_EVERY skoków.
## Mgnienie (13.11.2026, jak Flicker Strike z PoE): bez odnowienia, skacze, dopóki starcza many; każdy wróg zabity
## skokiem zwraca Skills.BLINK_MANA_ON_KILL many.
## Kamienie unikalne (Gems.UNIQUE, `_unique`): zwykły cios - fala cięcia leci do przodu i przebija (`_waves`);
## Młynek - bez odnowienia, wiruje do wyłączenia albo końca many (mana co sekundę), z 10. poziomem wybuch co czas
## odnowienia; Rzut - odbija się od trafionego wroga w kolejnego (do THROW_GEM_BOUNCES razy, widmowe miecze za nim);
## Rozłupanie - każdy trafiony wywołuje falę uderzeniową wokół siebie (bez kolejnych fal); Mgnienie - skoki
## za pół many.

const TEXTURE := preload("res://assets/watra/iron_sword.png")
## Punkt chwytu na obrazku miecza (rękojeść) - wokół niego miecz się obraca.
const GRIP := Vector2(9.5, 10.0)
const SCALE := 0.5
## Długość ostrza po przeskalowaniu (od chwytu do czubka, (61 - 9.5) * 0.5).
const BLADE := 26.0
## Środek orbity: tyle pikseli nad stopami postaci.
const ORBIT_HEIGHT := 12.0
## Rękojeść krąży w tej odległości od środka postaci (miecz lewituje, nie jest w dłoni), czubek ostrza - o BLADE dalej.
const HILT_RADIUS := 14.0
## Szerokość łuku cięcia (jak żelazny miecz w Watrze: 160 stopni).
const ARC := deg_to_rad(160.0)
## Zasięg celowania: cięcie idzie w stronę kukły bliższej niż tyle (stopy-stopy).
const REACH := 48.0
const COOLDOWN := 0.55
const WINDUP := 0.12
## Czas cięcia (jak attack_duration w Watrze).
const SWING := 0.18
const RECOVER := 0.08
const HOVER_HEIGHT := 22.0
const DAMAGE := Vector2i(14, 20)
const SLASH_FX := preload("res://assets/effects/sword_slash.png")
const SLASH_FRAMES := 5
## Promień półksiężyca w klatce efektu (px) - efekt skalujemy tak, żeby łuk pokrywał się z czubkiem ostrza.
const SLASH_FX_RADIUS := 29.0
## Efekt trafienia z kreatora PixelLab (pixellab_src/vfx/ids.json: sword_hit).
const HIT_FX := preload("res://assets/effects/sword_hit.png")
const HIT_FX_FRAMES := 12
const HIT_FX_FPS := 20.0
const HIT_FX_ANCHOR := Vector2(23, 17)

## Młynek: czas, prędkość obrotu (obroty na sekundę), co ile sekund trafia i promień trafień od środka postaci.
const WHIRL_TIME := 3.0
const WHIRL_SPIN := 2.2
const WHIRL_TICK := 0.3
const WHIRL_RADIUS := HILT_RADIUS + BLADE + 8.0
const WHIRL_FX := preload("res://assets/effects/whirl.png")
const WHIRL_FX_FRAMES := 8
const WHIRL_FX_FPS := 20.0
## Promień wiru w klatce efektu (jak w Watrze) - efekt skalujemy do WHIRL_RADIUS.
const WHIRL_FX_RADIUS := 35.0
## Rzut mieczem: zasięg lotu, prędkość tam i z powrotem, odległość trafienia od ostrza.
const THROW_DISTANCE := 130.0
const THROW_SPEED := 300.0
const THROW_RETURN := 340.0
const THROW_HIT := 16.0
## Rozłupanie Ziemi: wzlot nad cel, spadek, wysokość wzlotu, promień fali i ogłuszenie.
const SLAM_RISE := 0.25
const SLAM_FALL := 0.09
const SLAM_STUCK := 0.3
const SLAM_HEIGHT := 64.0
const SLAM_RADIUS := 46.0
const SLAM_STUN := 1.2
const SLAM_FX := preload("res://assets/effects/ground_slam.png")
const SLAM_FX_FRAMES := 10
const SLAM_FX_FPS := 15.0
const SLAM_FX_ANCHOR := Vector2(26, 35)
## Mgnienie (liczby z Watry, zasięg mniejszy - węższy ekran telefonu): zasięg skoku, odstęp między skokami
## przy trzymaniu, jak daleko za celem ląduje postać, szerokość pasa cięcia wzdłuż drogi i promień cięcia wokół celu.
const FLICKER_RANGE := 150.0
const FLICKER_INTERVAL := 0.32
const FLICKER_OVERSHOOT := 18.0
const FLICKER_PATH_WIDTH := 12.0
const FLICKER_HIT_RADIUS := 30.0
## Efekty Mgnienia z Watry (kreator efektów PixelLab): smuga od miejsca startu (rysowana w prawo, długość w klatce
## FLICKER_TRAIL_LENGTH) i cięcie na celu ukośnie do drogi skoku.
const FLICKER_TRAIL := preload("res://assets/effects/flicker_trail.png")
const FLICKER_TRAIL_ANCHOR := Vector2(8, 10)
const FLICKER_TRAIL_LENGTH := 64.0
const FLICKER_SLASH := preload("res://assets/effects/flicker_hit.png")
const FLICKER_SLASH_ANCHOR := Vector2(43, 16)
const FLICKER_SLASH_TILT := 0.6
const FLICKER_FX_FPS := 16.0

## Umiejętności nie dało się użyć (`reason`: "mana" - brak many, "cooldown" - jeszcze się odnawia,
## "target" - Mgnienie bez wroga w zasięgu).
signal cast_failed(id: String, reason: String)
## Użyto umiejętności (zapłacono manę, ruszyło odnowienie).
signal skill_used(id: String)

## Kamienie umiejętności: czas podpalenia i spowolnienia, zasięg pioruna i jego wyładowania, rozrzut widmowych
## mieczy Rzutu, opóźnienie drugiej fali Rozłupania, zasięg dodatkowego cięcia Mgnienia.
const BURN_TIME := 3.0
const SLOW_TIME := 2.0
const CHAIN_RANGE := 70.0
const CHAIN_TARGETS := 2
const THROW_SPREAD := 0.35
const SLAM_ECHO := 0.22
const SLAM_ECHO_RADIUS := 1.4
const FLICKER_EXTRA_RANGE := 60.0
## Nowe działania poziomów umiejętności: zasięg cięcia sąsiada, czas dłuższego Młynka, siła odepchnięcia wybuchu,
## zasięg odbicia Rzutu, dłuższe ogłuszenie, opóźnienie drugiej fali Rozłupania, siła wiru
## z Mgnienia.
const STRIKE_CLEAVE_RANGE := 40.0
const WHIRL_TIME_LONG := 4.0
const WHIRL_BLAST_PUSH := 160.0
const THROW_BOUNCE_RANGE := 90.0
const SLAM_STUN_LONG := 2.0
const SLAM_AFTERSHOCK := 0.5
const FLICKER_SPIN_POWER := 0.8
## Kamienie unikalne: fala cięcia (zasięg, prędkość, promień trafienia, siła), odbicia Rzutu, fale z trafionych
## Rozłupaniem (promień, siła, najwięcej naraz), mana Młynka na sekundę (ułamek kosztu).
const STRIKE_WAVE_DISTANCE := 140.0
const STRIKE_WAVE_SPEED := 260.0
const STRIKE_WAVE_RADIUS := 16.0
const STRIKE_WAVE_POWER := 0.6
const WAVE_FX := preload("res://assets/watra/effects/legend_wind_crescent.png")
const WAVE_FX_FRAMES := 4
const WAVE_FX_ANCHOR := Vector2(30, 22)
const THROW_GEM_BOUNCES := 3
const SLAM_SHOCK_RADIUS := 34.0
const SLAM_SHOCK_POWER := 0.5
const SLAM_SHOCK_MAX := 10
const SHOCK_FX := preload("res://assets/watra/effects/legend_shockwave.png")
const SHOCK_FX_ANCHOR := Vector2(52, 40)
const SHOCK_FX_RADIUS := 44.0
const WHIRL_DRAIN := 1.0 / 3.0

## Grupa węzłów, które miecz sam znajduje jako cele (potwory Hordy).
const TARGETS := &"proto_targets"
## Stany zwykłego ciosu (szybkość ataku i Pośpiech go przyspieszają); glewia i hydrosfera dokładają swoje.
const STRIKE_STATES := ["follow", "windup", "swing", "recover", "thrust_windup", "thrust", "thrust_recover",
		"orb_windup", "orb_shot"]

var hero: ProtoHero
## Czy gracz trzyma przycisk ataku.
var attack_held := false
## Auto atak: tnie sam, gdy jakiś cel jest bliżej niż REACH.
var auto_attack := false
## Mnożnik obrażeń z poziomu postaci.
var damage_mult := 1.0
## Obrażenia jednego cięcia (od-do) przed mnożnikiem - zwykły miecz albo założona broń.
var damage := DAMAGE
## Mnożnik szybkości ataku (rozbieg, cięcie, powrót i odpoczynek trwają tyle razy krócej).
var speed_mult := 1.0
## Premie przedmiotów (ustawia arena z HeroStats): szansa na krytyk (0-1) i mnożnik krytyka, mnożnik obrażeń
## przeciw elitom i bossom, skrócenie odnowienia umiejętności (0-1).
var crit_chance := HeroStats.CRIT_CHANCE / 100.0
var crit_mult := HeroStats.CRIT_DAMAGE / 100.0
var elite_mult := 1.0
var cooldown_cut := 0.0
## Premia przedmiotów: o tyle procent większy obszar cięć i umiejętności (dodaje się do kamienia Szerokość).
var area_bonus := 0.0
## Czy gracz trzyma przycisk Mgnienia (skoki co FLICKER_INTERVAL, dopóki starcza many).
var flicker_held := false
## Zwykły cios tej broni (miecz - Skills.STRIKE; glewia - ProtoGlaive ustawia swój).
var basic := Skills.STRIKE
## Umiejętność pod dużym przyciskiem (Skills; zwykły cios - `basic`).
var main_skill := Skills.STRIKE
## Kamienie w gniazdach umiejętności (Game.skill_gems: umiejętność -> lista identyfikatorów Gems).
var skill_gems := {}
## Poziomy umiejętności (Game.skill_levels: umiejętność -> poziom; brak - 1.).
var skill_levels := {}
## Cele do bicia (kukły, potwory). Arena dopisuje je przy starcie, potwory dopisują się same w grupie TARGETS.
var targets: Array[ProtoTarget] = []

var _state := "follow"
var _t := 0.0
var _cooldown := 0.3
var _aim := 0.0  # kąt w stronę celu
var _sign := -1.0  # kierunek cięcia: +1 zgodnie z ruchem wskazówek zegara, -1 przeciwnie
var _hit_done := false
var _from_pos := Vector2.ZERO
var _from_sprite := Vector2.ZERO
var _from_rot := 0.0
var _clock := 0.0
var _sprite: Sprite2D
var _slash: Sprite2D
## Odnowienia umiejętności: id -> ile sekund zostało.
var _cd := {}
## Umiejętność stuknięta w trakcie innego ruchu miecza (rusza, gdy miecz wróci).
var _queued := ""
## Młynek: kąt obrotu i czas do następnego trafienia.
var _spin := 0.0
var _tick := 0.0
var _whirl_fx: Sprite2D
## Rzut i Rozłupanie: punkt na ziemi (cel), kierunek lotu, cele trafione w tym przelocie.
var _goal := Vector2.ZERO
var _dir := Vector2.RIGHT
var _hit_set: Array = []
## Mgnienie: czas do następnego skoku, jeden skok po samym stuknięciu, poprzedni cel (skacze się przez innego).
var _flicker_timer := 0.0
var _flicker_once := false
var _last_target: ProtoTarget
## Kamienie: siła bieżącego cięcia (drugie cięcie Mnożenia - słabsze), czy to już drugie cięcie, czy piorun przeskoczył
## w tej klatce, ułamek leczenia, widmowe miecze (Młynek, Rzut) i ich trafienia, początek lotu Rzutu.
var _swing_power := 1.0
var _second := false
var _chained := false
var _leech_acc := 0.0
var _ghosts: Array[Sprite2D] = []
var _ghost_hits: Array = [[], []]
var _throw_origin := Vector2.ZERO
## Poziomy: licznik zwykłych ciosów (co trzeci podwójny), czy drugie cięcie jest z poziomu (pełna siła), czy Rzut
## już się odbił, czas ostatniego skoku Mgnienia i czy po serii ma być wir.
var _strike_count := 0
var _perk_second := false
var _bounced := false
var _last_jump := -INF
## Mgnienie: wszystkie skoki (wir co Skills.BLINK_SPIN_EVERY). Młynek: czy ruszył spod dużego przycisku, ułamek many do zapłacenia, czas do
## wybuchu (10. poziom z kamieniem unikalnym). Rzut: odbicia z kamienia. Fale cięcia w locie.
var _blink_jumps := 0
## Ile razy zawirował wir z 10. poziomu Mgnienia (do testów).
var _blink_spins := 0
var _whirl_main := false
var _whirl_drain_acc := 0.0
var _whirl_blast_t := 0.0
var _bounces_left := 0
var _waves: Array = []


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = ProtoHero._shadow_texture()
	shadow.scale = Vector2(0.7, 0.7)
	shadow.modulate.a = 0.6
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.centered = false
	_sprite.offset = -GRIP
	_sprite.scale = Vector2.ONE * SCALE
	add_child(_sprite)
	_slash = Sprite2D.new()
	_slash.texture = SLASH_FX
	_slash.hframes = SLASH_FRAMES
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) / SLASH_FX_RADIUS
	_slash.z_index = 5
	_slash.visible = false
	add_child(_slash)
	_whirl_fx = Sprite2D.new()
	_whirl_fx.texture = WHIRL_FX
	_whirl_fx.hframes = WHIRL_FX_FRAMES
	_whirl_fx.scale = Vector2.ONE * WHIRL_RADIUS / WHIRL_FX_RADIUS
	_whirl_fx.modulate.a = 0.85
	_whirl_fx.z_index = 4
	_whirl_fx.visible = false
	add_child(_whirl_fx)
	for i in 2:
		var ghost := Sprite2D.new()
		ghost.texture = TEXTURE
		ghost.centered = false
		ghost.offset = -GRIP
		ghost.scale = Vector2.ONE * SCALE
		ghost.modulate = Color(0.7, 0.9, 1.0, 0.55)
		ghost.top_level = true
		ghost.z_index = 4
		ghost.visible = false
		add_child(ghost)
		_ghosts.append(ghost)
	if hero:
		position = _follow_spot()


func _process(delta: float) -> void:
	_clock += delta
	_chained = false
	var sp := _strike_speed() if _state in STRIKE_STATES else speed_mult
	_cooldown -= delta * sp
	_t += delta * sp
	for id in _cd:
		_cd[id] = maxf(_cd[id] - delta, 0.0)
	if hero.dead and _state != "follow":
		_end_skill()
	_process_waves(delta)
	_process_flicker(delta)
	match _state:
		"follow":
			_follow(delta)
			if hero.dead:
				pass
			elif _queued != "":
				var q := _queued
				_queued = ""
				_start(q)
			elif _cooldown <= 0.0:
				var main_ok := main_skill != basic and can_use(main_skill)
				var main_range: float = Skills.DATA[main_skill].range if Skills.has(main_skill) else REACH
				if main_ok and (attack_held or (auto_attack and _nearest(main_range) != null)):
					_start(main_skill)
					_whirl_main = true
				elif attack_held or (auto_attack and _nearest(Skills.DATA[basic].range) != null):
					_attack()
		"whirl":
			_process_whirl(delta)
		"throw", "throw_back":
			_process_throw(delta)
		"slam_rise", "slam_fall", "slam_stuck":
			_process_slam()
		"windup":
			# miecz wskakuje na orbitę, na początek łuku (odrobinę dalej - zamach)
			var k := ease(clampf(_t / WINDUP, 0.0, 1.0), -2.0)
			var a := _angle_at(-0.1)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= WINDUP:
				_set_state("swing")
				_slash.visible = true
		"swing":
			var progress := clampf(_t / SWING, 0.0, 1.0)
			_place(_angle_at(ease(progress, 0.5)))  # jak w Watrze: szybki start, hamowanie pod koniec
			_slash.frame = mini(int(progress * SLASH_FRAMES), SLASH_FRAMES - 1)
			if not _hit_done and progress >= 0.5:
				_hit_done = true
				_hit_in_arc()
			if _t >= SWING:
				_slash.visible = false
				_set_state("recover")
		"recover":
			_place(_angle_at(1.0))
			if _t >= RECOVER:
				var perk_second := _perk(Skills.STRIKE, 0) and _strike_count % 3 == 0
				if not _second and (perk_second or gem_power(Skills.STRIKE, "multi") > 0.0) and not hero.dead:
					_attack(true, perk_second)  # Mnożenie albo 5. poziom: drugie cięcie w drugą stronę
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = COOLDOWN


## Miejsce obok postaci, za jej ramieniem (od strony przeciwnej do kierunku patrzenia).
func _follow_spot() -> Vector2:
	var side := -1.0 if hero.facing.x >= 0.0 else 1.0
	return hero.position + Vector2(side * 12.0, 3.0)


func _follow(delta: float) -> void:
	var k := 1.0 - exp(-9.0 * delta)
	position = position.lerp(_follow_spot(), k)
	_sprite.position = _sprite.position.lerp(Vector2(0, -HOVER_HEIGHT - 2.0 * sin(_clock * 3.0)), k)
	# ostrze w górę, lekko pochylone w stronę patrzenia, z delikatnym kołysaniem
	var side := 1.0 if hero.facing.x >= 0.0 else -1.0
	var rest := -PI / 2.0 + 0.35 * side + 0.06 * sin(_clock * 2.1)
	_sprite.rotation = lerp_angle(_sprite.rotation, rest, k)


## Najbliższy cel bliżej niż `reach` (domyślnie zasięg ciosu; null - żadnego).
func _nearest(reach := REACH) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := reach
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


## Zwykły cios; `second` - drugie cięcie z kamienia Mnożenie (słabsze, bez odpoczynku przed nim), `full` - drugie
## cięcie z 5. poziomu (pełna siła).
func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(Skills.STRIKE, "multi") / 100.0) if second else 1.0
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) * _area(Skills.STRIKE) / SLASH_FX_RADIUS
	var best := _nearest()
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign  # kolejne cięcia na przemian
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Kąt ostrza w chwili `k` cięcia (0 - początek łuku, 1 - koniec; poza 0..1 - przed i za łukiem).
func _angle_at(k: float) -> float:
	return _aim + lerpf(-ARC / 2.0, ARC / 2.0, k) * _sign


## Środek orbity w świecie (postać, na wysokości pasa).
func _orbit_center() -> Vector2:
	return hero.global_position + Vector2(0, -ORBIT_HEIGHT)


## Ustawia miecz na orbicie: ostrze pod kątem `a`, rękojeść do postaci. Węzeł stoi pod postacią,
## odrobinę za nią, gdy ostrze wskazuje w górę (wtedy miecz rysuje się za postacią). Efekt cięcia jedzie z postacią.
func _place(a: float) -> void:
	position = hero.position + Vector2(0, -1.0 if sin(a) < -0.2 else 1.0)
	var center := _orbit_center() - global_position
	_sprite.position = center + Vector2.from_angle(a) * HILT_RADIUS
	_sprite.rotation = a
	_slash.position = center
	_slash.rotation = _aim
	_slash.flip_v = _sign < 0.0


## Trafienie: wszystkie kukły w zasięgu ostrza i w łuku cięcia; na każdej błysk z iskrami.
## 10. poziom zwykłego ciosu: tnie też najbliższego wroga poza łukiem (w zasięgu STRIKE_CLEAVE_RANGE od ostrza).
func _hit_in_arc() -> void:
	var hit: Array = []
	var power := _swing_power * _power(Skills.STRIKE)
	var reach := (HILT_RADIUS + BLADE + 6.0) * _area(Skills.STRIKE)
	for t in _live_targets():
		var to := t.center() - _orbit_center()
		if to.length() <= reach and absf(angle_difference(_aim, to.angle())) <= ARC / 2.0:
			_deal(t, _roll(power), hero.global_position, Skills.STRIKE)
			# błysk tam, gdzie ostrze przecina kukłę (na linii od postaci, nie dalej niż czubek)
			var at := _orbit_center() + to.limit_length(HILT_RADIUS + BLADE * 0.8)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, at.round(), HIT_FX_ANCHOR)
			hit.append(t)
	if _unique(Skills.STRIKE):
		_spawn_wave(power * STRIKE_WAVE_POWER)
	if not hit.is_empty() and _perk(Skills.STRIKE, 1):
		var near: ProtoTarget = null
		var near_d := reach + STRIKE_CLEAVE_RANGE
		for t in _live_targets():
			var d := t.center().distance_to(_orbit_center())
			if not hit.has(t) and d <= near_d:
				near = t
				near_d = d
		if near:
			_deal(near, _roll(power), hero.global_position, Skills.STRIKE)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, near.center().round(), HIT_FX_ANCHOR)
	if not hit.is_empty():
		Input.vibrate_handheld(15)


## Cele, które da się jeszcze trafić: lista `targets` i potwory z grupy TARGETS.
func _live_targets() -> Array[ProtoTarget]:
	var all: Array = targets.duplicate()
	all.append_array(get_tree().get_nodes_in_group(TARGETS))
	var out: Array[ProtoTarget] = []
	for t in all:
		if is_instance_valid(t) and t is ProtoTarget and t.alive() and not out.has(t):
			out.append(t)
	return out


func _set_state(state: String) -> void:
	_state = state
	_t = 0.0


## Obrażenia jednego trafienia: zwykłe cięcie razy `power` (mnożnik umiejętności).
func _roll(power := 1.0) -> int:
	return maxi(1, roundi(randi_range(damage.x, damage.y) * damage_mult * power))


## Siła kamienia rodzaju `kind` w umiejętności `skill` (Gems.SUPPORT `values`; 0 - brak kamienia).
func gem_power(skill: String, kind: String) -> float:
	return Gems.skill_power(skill_gems.get(skill, []), kind)


## Poziom umiejętności (Game.skill_levels).
func level_of(skill: String) -> int:
	return skill_levels.get(skill, 1)


## Czy umiejętność ma nowe działanie nr `i` (0 - z 5. poziomu, 1 - z 10.).
func _perk(skill: String, i: int) -> bool:
	return Skills.perks_at(level_of(skill)) > i


## Czy w umiejętności siedzi jej kamień unikalny.
func _unique(skill: String) -> bool:
	return Gems.has_unique(skill_gems.get(skill, []), skill)


## Siła trafienia umiejętności: mnożnik z danych razy premia z poziomu.
func _power(skill: String) -> float:
	return Skills.DATA[skill].power * Skills.level_damage(level_of(skill))


## Mnożnik zasięgu umiejętności (kamień Szerokość, premia przedmiotów i poziom).
func _area(skill: String) -> float:
	return (1.0 + (gem_power(skill, "area") + area_bonus) / 100.0) * Skills.level_area(level_of(skill))


## Szybkość zwykłego ciosu: premia szybkości ataku, kamień Pośpiech i poziomy zwykłego ciosu (mniejszy „koszt” -
## szybszy cios).
func _strike_speed() -> float:
	return speed_mult * (1.0 + gem_power(basic, "haste") / 100.0) \
			* (2.0 - Skills.level_cost(level_of(basic)))


## Koszt many umiejętności z kamieniem Oszczędność i poziomem (Mgnienie z kamieniem unikalnym - o połowę mniej).
func mana_cost(id: String) -> int:
	var cost := Skills.mana_of(id) * (1.0 - gem_power(id, "thrift") / 100.0) * Skills.level_cost(level_of(id))
	if id == "blink" and _unique(id):
		cost *= 0.5
	return roundi(cost)


## Koszt skoku Mgnienia.
func _blink_cost() -> int:
	return mana_cost("blink")


## Pełne odnowienie umiejętności z kamieniem Pośpiech i poziomem.
## Młynek z kamieniem unikalnym - bez odnowienia (Mgnienie nie ma go wcale).
func cooldown_full(id: String) -> float:
	if id == "whirl" and _unique(id):
		return 0.0
	return _cooldown_base(id)


## Odnowienie bez kamienia unikalnego (Młynek z nim - co tyle wybuch z 10. poziomu).
func _cooldown_base(id: String) -> float:
	return Skills.cooldown_of(id) * (1.0 - gem_power(id, "haste") / 100.0) * Skills.level_cost(level_of(id)) \
			* (1.0 - cooldown_cut)


## Trafienie umiejętnością `skill` - premia przeciw elitom i bossom, trafienie krytyczne (złota liczba), obrażenia
## i działanie jej kamieni (podpalenie, spowolnienie, leczenie, mana,
## piorun).
func _deal(t: ProtoTarget, amount: int, from: Vector2, skill: String) -> void:
	if t is ProtoChief or (t is ProtoGoblin and t.elite != null):
		amount = roundi(amount * elite_mult)
	if randf() < crit_chance:
		amount = roundi(amount * crit_mult)
		t.crit_next = true
	t.take_damage(amount, from)
	t.crit_next = false
	var sockets: Array = skill_gems.get(skill, [])
	if sockets.is_empty():
		return
	var p := Gems.skill_power(sockets, "ember")
	if p > 0.0:
		t.burn(amount * p / 100.0, BURN_TIME)
	p = Gems.skill_power(sockets, "rime")
	if p > 0.0:
		t.slow(p / 100.0, SLOW_TIME)
	p = Gems.skill_power(sockets, "leech")
	if p > 0.0:
		_leech_acc += amount * p / 100.0
		var heal := int(_leech_acc)
		if heal > 0:
			_leech_acc -= heal
			hero.heal(heal)
	if skill == basic:
		var grade := Gems.skill_grade(sockets, "thrift")
		if grade >= 0:
			hero.add_mana(Gems.THRIFT_STRIKE[grade])
	p = Gems.skill_power(sockets, "discharge")
	if p > 0.0 and not _chained:
		_chained = true
		_chain_from(t, maxi(1, roundi(amount * p / 100.0)))


## Piorun (kamień): z celu `src` przeskakuje na CHAIN_TARGETS najbliższych wrogów w zasięgu - zygzak światła.
func _chain_from(src: ProtoTarget, amount: int) -> void:
	var near: Array = []
	for t in _live_targets():
		var d := t.global_position.distance_to(src.global_position)
		if t != src and d <= CHAIN_RANGE:
			near.append([d, t])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var from := src.center()
	for pair in near.slice(0, CHAIN_TARGETS):
		var t: ProtoTarget = pair[1]
		_bolt(from, t.center())
		t.take_damage(amount, src.global_position)


## Zygzak pioruna między dwoma punktami (świat), gaśnie w 0,2 s.
func _bolt(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.width = 1.5
	line.default_color = Color(1.0, 0.97, 0.6)
	line.z_index = 21
	var steps := 5
	var side := (b - a).orthogonal().normalized()
	for i in steps + 1:
		var k := float(i) / steps
		var jitter := 0.0 if i == 0 or i == steps else randf_range(-4.0, 4.0)
		line.add_point(a.lerp(b, k) + side * jitter)
	get_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)


## Ile sekund odnowienia zostało umiejętności `id` (0 - gotowa).
func cooldown_left(id: String) -> float:
	return _cd.get(id, 0.0)


## Czy umiejętność da się teraz użyć (odnowiona i starcza many).
func can_use(id: String) -> bool:
	var cost := _blink_cost() if id == "blink" else mana_cost(id)
	return Skills.has(id) and cooldown_left(id) <= 0.0 and hero.mana >= cost and not hero.dead


## Użycie umiejętności z małego przycisku. W trakcie innego ruchu miecza czeka w kolejce. Zwraca false (i wysyła
## `cast_failed`), gdy się odnawia albo brakuje many.
func cast(id: String) -> bool:
	if not Skills.has(id) or hero.dead:
		return false
	if id == "whirl" and _state == "whirl" and _unique("whirl"):
		_end_skill()  # kamień unikalny: drugie stuknięcie wyłącza Młynek
		return true
	if cooldown_left(id) > 0.0:
		cast_failed.emit(id, "cooldown")
		return false
	if hero.mana < (_blink_cost() if id == "blink" else mana_cost(id)):
		cast_failed.emit(id, "mana")
		return false
	if id == "blink":
		if _flicker_target() == null:
			cast_failed.emit(id, "target")
			return false
		_flicker_once = true  # stuknięcie bez trzymania - jeden skok
		_process_flicker(0.0)
		return true
	if _state == "follow" and (id != basic or _cooldown <= 0.0):
		_start(id)
	else:
		_queued = id
	return true


## Rusza umiejętność: płaci manę, włącza odnowienie i ustawia ruch miecza.
func _start(id: String) -> void:
	if not can_use(id):
		return
	if id == basic:
		_attack()
		return
	if not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	_slash.visible = false
	match id:
		"whirl":
			_spin = (_sprite.global_position - _orbit_center()).angle()
			_tick = 0.0
			_whirl_main = false
			_whirl_drain_acc = 0.0
			_whirl_blast_t = 0.0
			_whirl_fx.visible = true
			_whirl_fx.scale = Vector2.ONE * WHIRL_RADIUS * _area("whirl") / WHIRL_FX_RADIUS
			_ghosts[0].visible = gem_power("whirl", "multi") > 0.0
			_set_state("whirl")
		"throw":
			var best := _nearest(Skills.DATA.throw.range)
			_dir = (best.global_position - hero.global_position).normalized() if best else hero.facing.normalized()
			if _dir == Vector2.ZERO:
				_dir = Vector2.RIGHT
			_goal = hero.position + _dir * THROW_DISTANCE
			position = hero.position
			_sprite.position = Vector2(0, -ORBIT_HEIGHT)
			_hit_set = []
			_ghost_hits = [[], []]
			_bounced = false
			_bounces_left = THROW_GEM_BOUNCES if _unique("throw") else 0
			_throw_origin = hero.global_position + Vector2(0, -ORBIT_HEIGHT)
			for i in _ghosts.size():  # 10. poziom: pierwszy widmowy miecz zawsze (drugi miecz), drugi - z kamieniem
				_ghosts[i].visible = gem_power("throw", "multi") > 0.0 or (i == 0 and _perk("throw", 1))
			hero.play_gesture(hero.global_position + _dir * 20.0)
			_set_state("throw")
		"slam":
			var best := _nearest(Skills.DATA.slam.range)
			_goal = best.position if best else hero.position + hero.facing.normalized() * 30.0
			_from_pos = position
			_from_sprite = _sprite.position
			_from_rot = _sprite.rotation
			hero.play_gesture(_goal)
			_set_state("slam_rise")
	skill_used.emit(id)


## Młynek: miecz krąży wokół postaci (rękojeścią do niej), co WHIRL_TICK rani wszystkich w promieniu.
func _process_whirl(delta: float) -> void:
	_spin += TAU * WHIRL_SPIN * delta
	_place(_spin)
	if _ghosts[0].visible:
		_ghosts[0].global_position = _orbit_center() + Vector2.from_angle(_spin + PI) * HILT_RADIUS
		_ghosts[0].rotation = _spin + PI
	_whirl_fx.position = _orbit_center() - global_position
	_whirl_fx.frame = int(_clock * WHIRL_FX_FPS) % WHIRL_FX_FRAMES
	_tick -= delta
	if _tick <= 0.0:
		_tick = WHIRL_TICK
		var hit := false
		var extra := gem_power("whirl", "multi") / 100.0
		for t in _live_targets():
			if t.center().distance_to(_orbit_center()) <= WHIRL_RADIUS * _area("whirl"):
				_deal(t, _roll(_power("whirl")), hero.global_position, "whirl")
				if extra > 0.0 and t.alive():
					_deal(t, _roll(_power("whirl") * extra), hero.global_position, "whirl")
				hit = true
		if hit:
			Input.vibrate_handheld(8)
	if _unique("whirl"):
		_process_endless_whirl(delta)
		return
	var whirl_time := WHIRL_TIME_LONG if _perk("whirl", 0) else WHIRL_TIME
	if _t >= whirl_time * speed_mult:  # _t rośnie szybciej z premią szybkości ataku - czas Młynka nie
		if _perk("whirl", 1):
			_whirl_blast()
		_end_skill()


## Młynek z kamieniem unikalnym: płaci manę co sekundę (ułamek WHIRL_DRAIN kosztu), wybuch z 10. poziomu co czas
## odnowienia; kończy się bez many, a spod dużego przycisku - gdy gracz puści „Atak” (auto atak - gdy brak wrogów).
func _process_endless_whirl(delta: float) -> void:
	_whirl_drain_acc += mana_cost("whirl") * WHIRL_DRAIN * delta
	var pay := int(_whirl_drain_acc)
	if pay > 0:
		_whirl_drain_acc -= pay
		if not hero.spend_mana(pay):
			cast_failed.emit("whirl", "mana")
			_end_skill()
			return
	if _perk("whirl", 1):
		_whirl_blast_t += delta
		if _whirl_blast_t >= maxf(_cooldown_base("whirl"), 1.0):
			_whirl_blast_t = 0.0
			_whirl_blast()
	if _whirl_main and not attack_held and not (auto_attack and _nearest(Skills.DATA.whirl.range) != null):
		_end_skill()


## 10. poziom Młynka: na koniec wybuch - trafia wszystkich w promieniu wiru i odpycha ich od postaci.
func _whirl_blast() -> void:
	var radius := WHIRL_RADIUS * _area("whirl") * 1.2
	for t in _live_targets():
		if t.center().distance_to(_orbit_center()) <= radius:
			_deal(t, _roll(_power("whirl")), hero.global_position, "whirl")
			t.push_away(hero.global_position, WHIRL_BLAST_PUSH)
	Fx.once(get_parent(), SLAM_FX, SLAM_FX_FRAMES, SLAM_FX_FPS, hero.global_position, SLAM_FX_ANCHOR, 6,
			1.3 * radius / SLAM_RADIUS)
	Input.vibrate_handheld(30)


## Rzut mieczem: lot po prostej do THROW_DISTANCE i powrót do postaci; każdy cel trafiony raz w każdą stronę.
func _process_throw(delta: float) -> void:
	_sprite.rotation += TAU * 3.0 * delta
	var target := _goal if _state == "throw" else hero.position
	var speed := THROW_SPEED if _state == "throw" else THROW_RETURN
	position = position.move_toward(target, speed * delta)
	var tip := _sprite.global_position
	var reach := THROW_HIT * _area("throw")
	for t in _live_targets():
		if not _hit_set.has(t) and t.center().distance_to(tip) <= reach + t.center_height * 0.5:
			_hit_set.append(t)
			_deal(t, _roll(_power("throw")), global_position - _dir * 10.0, "throw")
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, tip.round(), HIT_FX_ANCHOR)
			Input.vibrate_handheld(12)
			if _state == "throw" and _bounces_left > 0 and _ricochet(t):
				break
	if _ghosts[0].visible:
		# Mnożenie: dwa widmowe miecze lecą wachlarzem obok głównego (słabsze)
		var anchor := _throw_origin if _state == "throw" else hero.global_position + Vector2(0, -ORBIT_HEIGHT)
		var gem := gem_power("throw", "multi") / 100.0
		for i in 2:
			var g := _ghosts[i]
			if not g.visible:
				continue
			# 10. poziom: pierwszy widmowy miecz to pełny drugi miecz
			var power: float = _power("throw") * (1.0 if i == 0 and _perk("throw", 1) else gem)
			g.global_position = anchor + (tip - anchor).rotated(THROW_SPREAD * (1.0 if i == 0 else -1.0))
			g.rotation = _sprite.rotation
			for t in _live_targets():
				if not _ghost_hits[i].has(t) and t.center().distance_to(g.global_position) <= reach + t.center_height * 0.5:
					_ghost_hits[i].append(t)
					_deal(t, _roll(power), g.global_position, "throw")
	if position.distance_to(target) < 2.0:
		if _state == "throw" and not _bounced and _perk("throw", 0):
			# 5. poziom: odbicie w najbliższego wroga, którego lot nie trafił - potem dopiero powrót
			_bounced = true
			var near: ProtoTarget = null
			var near_d := THROW_BOUNCE_RANGE
			for t in _live_targets():
				var d := t.global_position.distance_to(global_position)
				if not _hit_set.has(t) and d <= near_d:
					near = t
					near_d = d
			if near:
				_goal = near.position
				_dir = (near.global_position - global_position).normalized()
				return
		if _state == "throw":
			_hit_set = []
			_ghost_hits = [[], []]
			_dir = -_dir
			_set_state("throw_back")
		else:
			_end_skill()


## Kamień unikalny Rzutu: od trafionego `from` miecz skręca w najbliższego nietrafionego wroga w zasięgu
## THROW_BOUNCE_RANGE (widmowe miecze rozchodzą się od miejsca odbicia). Zwraca false, gdy nie ma w kogo.
func _ricochet(from: ProtoTarget) -> bool:
	var near: ProtoTarget = null
	var near_d := THROW_BOUNCE_RANGE
	for t in _live_targets():
		var d := t.global_position.distance_to(from.global_position)
		if t != from and not _hit_set.has(t) and d <= near_d:
			near = t
			near_d = d
	if near == null:
		return false
	_bounces_left -= 1
	_goal = near.position
	_dir = (near.global_position - global_position).normalized()
	_throw_origin = _sprite.global_position
	_ghost_hits = [[], []]
	return true


## Rozłupanie Ziemi: miecz wznosi się nad cel ostrzem w dół, spada, fala rani i ogłusza, chwilę tkwi w ziemi.
func _process_slam() -> void:
	match _state:
		"slam_rise":
			var k := ease(clampf(_t / SLAM_RISE, 0.0, 1.0), -2.0)
			position = _from_pos.lerp(_goal, k)
			_sprite.position = _from_sprite.lerp(Vector2(0, -SLAM_HEIGHT), k)
			_sprite.rotation = lerp_angle(_from_rot, PI / 2.0, k)
			if _t >= SLAM_RISE:
				_set_state("slam_fall")
		"slam_fall":
			var k := clampf(_t / SLAM_FALL, 0.0, 1.0)
			_sprite.position = Vector2(0, lerpf(-SLAM_HEIGHT, -BLADE + 4.0, k * k))
			if _t >= SLAM_FALL:
				_slam_hit()
				_set_state("slam_stuck")
		"slam_stuck":
			if _t >= SLAM_STUCK:
				_end_skill()


## Fala Rozłupania w punkcie `at`; `echo` - druga fala z kamienia Mnożenie (szersza, słabsza, bez ogłuszenia),
## `aftershock` - druga fala z 10. poziomu (pełna siła, bez ogłuszenia i bez kolejnych fal).
func _slam_hit(at := global_position, echo := false, aftershock := false) -> void:
	var radius := SLAM_RADIUS * _area("slam") * (SLAM_ECHO_RADIUS if echo else 1.0)
	var power: float = _power("slam") * (gem_power("slam", "multi") / 100.0 if echo else 1.0)
	var stun_time := SLAM_STUN_LONG if _perk("slam", 0) else SLAM_STUN
	var shocks: Array = []
	for t in _live_targets():
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_deal(t, _roll(power), at, "slam")
			if not echo and not aftershock:
				t.stun(stun_time)
			if shocks.size() < SLAM_SHOCK_MAX:
				shocks.append(t)
	if _unique("slam") and not shocks.is_empty():
		get_tree().create_timer(0.12, false).timeout.connect(_slam_shocks.bind(shocks))
	Fx.once(get_parent(), SLAM_FX, SLAM_FX_FRAMES, SLAM_FX_FPS, at, SLAM_FX_ANCHOR, 6,
			1.3 * radius / SLAM_RADIUS)
	if not echo and not aftershock and gem_power("slam", "multi") > 0.0:
		get_tree().create_timer(SLAM_ECHO, false).timeout.connect(_slam_hit.bind(at, true))
	if not echo and not aftershock and _perk("slam", 1):
		get_tree().create_timer(SLAM_AFTERSHOCK, false).timeout.connect(_slam_hit.bind(at, false, true))
	Input.vibrate_handheld(25 if echo else 40)
	var cam := hero.get_viewport().get_camera_2d()
	if cam:
		var shake := cam.create_tween()
		for i in 4:
			shake.tween_property(cam, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.03)
		shake.tween_property(cam, "offset", Vector2.ZERO, 0.03)


## Kamień unikalny Rozłupania: wokół każdego trafionego (`sources`) fala uderzeniowa rani pobliskich (bez źródła
## i bez kolejnych fal).
func _slam_shocks(sources: Array) -> void:
	var radius := SLAM_SHOCK_RADIUS * _area("slam")
	var power := _power("slam") * SLAM_SHOCK_POWER
	for src in sources:
		if not is_instance_valid(src):
			continue
		var at: Vector2 = src.global_position
		for t in _live_targets():
			var d := t.global_position - at
			if t != src and Vector2(d.x, d.y * 1.6).length() <= radius:
				_deal(t, _roll(power), at, "slam")
		Fx.once(get_parent(), SHOCK_FX, 9, 18.0, at, SHOCK_FX_ANCHOR, 6, maxf(radius / SHOCK_FX_RADIUS, 0.6))
	Input.vibrate_handheld(15)


## Kamień unikalny zwykłego ciosu: fala cięcia z postaci w stronę cięcia, siła `power` (wielokrotność cięcia).
func _spawn_wave(power: float) -> void:
	var fx := Sprite2D.new()
	fx.texture = WAVE_FX
	fx.hframes = WAVE_FX_FRAMES
	fx.centered = false
	fx.offset = -WAVE_FX_ANCHOR
	fx.z_index = 20
	fx.rotation = _aim
	fx.scale = Vector2.ONE * _area(Skills.STRIKE)
	get_parent().add_child(fx)
	fx.global_position = _orbit_center()
	_waves.append({"fx": fx, "dir": Vector2.from_angle(_aim), "left": STRIKE_WAVE_DISTANCE * _area(Skills.STRIKE),
			"power": power, "hits": []})


## Fale cięcia w locie: przesuwają się, ranią każdego raz, znikają po STRIKE_WAVE_DISTANCE.
func _process_waves(delta: float) -> void:
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		var fx: Sprite2D = w.fx
		if not is_instance_valid(fx):
			_waves.remove_at(i)
			continue
		var step := STRIKE_WAVE_SPEED * delta
		fx.global_position += w.dir * step
		w.left -= step
		fx.frame = int(_clock * 16.0) % WAVE_FX_FRAMES
		fx.modulate.a = clampf(w.left / 30.0, 0.0, 1.0)
		var reach := STRIKE_WAVE_RADIUS * _area(Skills.STRIKE)
		for t in _live_targets():
			if not w.hits.has(t) and t.center().distance_to(fx.global_position) <= reach + t.center_height * 0.5:
				w.hits.append(t)
				_deal(t, _roll(w.power), fx.global_position - w.dir * 10.0, Skills.STRIKE)
		if w.left <= 0.0:
			fx.queue_free()
			_waves.remove_at(i)


## Mgnienie przy trzymaniu przycisku (albo jeden skok po stuknięciu): skok co FLICKER_INTERVAL, dopóki starcza many
## i jest wróg w zasięgu. Nie w czasie Młynka, Rzutu i Rozłupania (miecz jest zajęty) - wtedy czeka.
func _process_flicker(delta: float) -> void:
	_flicker_timer -= delta
	if not (flicker_held or _flicker_once) or _flicker_timer > 0.0 or hero.dead:
		return
	if cooldown_left("blink") > 0.0:
		_flicker_once = false
		return
	if not _state in ["follow", "windup", "swing", "recover"]:
		return
	_flicker_once = false
	var cost := _blink_cost()
	if hero.mana < cost:
		cast_failed.emit("blink", "mana")
		_flicker_timer = 0.3
		return
	var best := _flicker_target()
	if best == null:
		cast_failed.emit("blink", "target")
		_flicker_timer = 0.3
		return
	if cost > 0:
		hero.spend_mana(cost)
	_flicker_jump(best)
	_last_jump = _clock
	_blink_jumps += 1
	if _perk("blink", 1) and _blink_jumps % Skills.BLINK_SPIN_EVERY == 0:
		_flicker_spin()
	_flicker_timer = FLICKER_INTERVAL / (speed_mult * (1.0 + gem_power("blink", "haste") / 100.0))
	skill_used.emit("blink")


## Najbliższy wróg w zasięgu Mgnienia; poprzedni cel tylko wtedy, gdy nie ma innego (null - nikogo).
func _flicker_target() -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := INF
	for t in _live_targets():
		var d := hero.global_position.distance_to(t.global_position)
		if d > FLICKER_RANGE:
			continue
		if t == _last_target:
			d += FLICKER_RANGE
		if d < best_d:
			best = t
			best_d = d
	return best


## Skok na wylot przez `best`: postać ląduje za nim (na przedłużeniu skoku), smuga od miejsca startu, cięcie na celu;
## rani wszystkich w pasie wzdłuż drogi i wokół celu. Miecz tnie po łuku w stronę skoku.
func _flicker_jump(best: ProtoTarget) -> void:
	var from := hero.global_position
	var through := (best.global_position - from).normalized()
	if through == Vector2.ZERO:
		through = hero.facing.normalized()
	var spot := hero.teleport(best.global_position + through * FLICKER_OVERSHOOT)
	_last_target = best
	var travel := spot - from
	var body := Vector2(0, -ORBIT_HEIGHT)
	var trail := Fx.once(get_parent(), FLICKER_TRAIL, 7, FLICKER_FX_FPS, from + body, FLICKER_TRAIL_ANCHOR)
	trail.rotation = travel.angle()
	trail.scale = Vector2.ONE * maxf(0.5, (travel.length() - 8.0) / FLICKER_TRAIL_LENGTH)
	var cut := Fx.once(get_parent(), FLICKER_SLASH, 8, FLICKER_FX_FPS, best.center(), FLICKER_SLASH_ANCHOR)
	cut.rotation = travel.angle() + FLICKER_SLASH_TILT * (1.0 if randf() < 0.5 else -1.0)
	var area := _area("blink")
	var hit: Array = []
	for t in _live_targets():
		var c := t.center()
		var on_path := Geometry2D.get_closest_point_to_segment(c, from + body, spot + body).distance_to(c) \
				<= FLICKER_PATH_WIDTH * area + t.center_height * 0.5
		if on_path or c.distance_to(best.center()) <= FLICKER_HIT_RADIUS * area:
			hit.append(t)
			_deal(t, _roll(_power("blink")), spot, "blink")
			_blink_kill(t)
	var extra := gem_power("blink", "multi") / 100.0
	if extra > 0.0:
		# Mnożenie: dodatkowe cięcie najbliższego wroga, którego skok nie trafił
		var near: ProtoTarget = null
		var near_d := FLICKER_EXTRA_RANGE
		for t in _live_targets():
			var d := t.global_position.distance_to(spot)
			if not hit.has(t) and d <= near_d:
				near = t
				near_d = d
		if near:
			var cut2 := Fx.once(get_parent(), FLICKER_SLASH, 8, FLICKER_FX_FPS, near.center(), FLICKER_SLASH_ANCHOR)
			cut2.rotation = randf() * TAU
			_deal(near, _roll(_power("blink") * extra), spot, "blink")
			_blink_kill(near)
	Input.vibrate_handheld(20)
	if _state != "follow":
		_slash.visible = false
	_aim = travel.angle()
	_sign = -_sign
	_hit_done = true  # cięcie już zadane wzdłuż drogi
	_second = true  # bez drugiego cięcia zwykłego ciosu po skoku
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) / SLASH_FX_RADIUS
	_set_state("swing")
	_slash.visible = true


## Wróg zabity Mgnieniem zwraca manę (5. poziom - dwa razy więcej). Kukły nie giną, więc nic nie dają.
func _blink_kill(t: ProtoTarget) -> void:
	if not t.alive():
		hero.add_mana(Skills.BLINK_MANA_ON_KILL * (2 if _perk("blink", 0) else 1))


## 10. poziom Mgnienia: co Skills.BLINK_SPIN_EVERY skoków krótki wir - trafia wszystkich wokół postaci.
func _flicker_spin() -> void:
	_blink_spins += 1
	var radius := WHIRL_RADIUS * _area("blink")
	for t in _live_targets():
		if t.center().distance_to(_orbit_center()) <= radius:
			_deal(t, _roll(_power("blink") * FLICKER_SPIN_POWER), hero.global_position, "blink")
			_blink_kill(t)
	var fx := Fx.once(get_parent(), WHIRL_FX, WHIRL_FX_FRAMES, WHIRL_FX_FPS, _orbit_center(),
			Vector2(WHIRL_FX.get_width() / WHIRL_FX_FRAMES / 2.0, WHIRL_FX.get_height() / 2.0), 6,
			radius / WHIRL_FX_RADIUS)
	fx.modulate = Color(1, 1, 1, 0.9)
	Input.vibrate_handheld(20)


## Koniec umiejętności: miecz wraca za ramię (zwykły ruch śledzenia), krótka przerwa przed kolejnym ciosem.
func _end_skill() -> void:
	_whirl_fx.visible = false
	for g in _ghosts:
		g.visible = false
	_slash.visible = false
	_set_state("follow")
	_cooldown = maxf(_cooldown, COOLDOWN * 0.5)


## Tryb deweloperski i testy: zeruje odnowienia.
func reset_cooldowns() -> void:
	_cd.clear()
	_blink_jumps = 0

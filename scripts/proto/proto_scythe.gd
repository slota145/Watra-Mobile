class_name ProtoScythe
extends ProtoWeapon
## Mroczna kosa (ustalone z autorem 21.11.2026) - broń wręcz, żywioł Nawia (Elements.NAWIA): każde trafienie wysysa
## trochę życia i osłabia wroga (ProtoWeapon._deal, ProtoTarget.wither). Lewituje obok postaci jak miecz (dziedziczy
## po ProtoWeapon: podążanie, orbita, mana, odnowienia, kamienie, krytyki). Efekty czarno-białe z przewagą czerni
## (decyzja autora; od drugiej wersji efektów z fioletem i przezroczystą otoczką mrocznego dymu, robione w rozmiarze
## z gry - prośba autora 21.11.2026): efekty z kreatora PixelLab scythe_swing, scythe_hit, scythe_blast, scythe_wave,
## square_burst, mow_swing, scythe_diag, dance_cut, dance_loop, mara_curse (pixellab_src/vfx/ids.json). Grafika: assets/weapons/scythe.png
## (tools/scythe_art.py).
## - „Żniwo” (`s_reap`, zwykły atak): szeroki zamach łukiem REAP_ARC przed postacią; 5. poziom - co trzeci zamach to
##   pełny obrót, 10. - zamach zostawia na chwilę smugę Nawii, która rani (`_trails`); kamień unikalny (Żniwiarza) -
##   po REAP_CHARGE trafieniach fala Nawii dookoła (`_reap_wave`).
## - „Cięcie Światowida” (`s_square`): 4 cięcia jedno po drugim układają się w kwadrat dookoła postaci (cienkie
##   ciemne cięcia po łuku zostają - wygięte na zewnątrz i dłuższe niż bok, krzyżują się w rogach; prośba autora
##   21.11.2026), po chwili każdy bok wybucha na zewnątrz (rani i odpycha wrogów za bokiem); 5. - wybuch
##   o SQUARE_PERK_AREA szerszy, 10. - wybuch dwa razy; kamień unikalny (Czterech Stron) - 3 widmowe kosy więcej:
##   4 takie kwadraty po czterech stronach postaci, oddalone od siebie
##   i obrócone o 45° - rogiem do postaci (prośba autora 21.11.2026; `_squares`).
## - „Pokos” (`s_mow`, ładowany - Skills.is_charged): dopóki palec trzyma przycisk, na ziemi rośnie stożek ze ściętym
##   czubkiem (większy zasięg i obrażenia im dłużej), po puszczeniu kosa kosi cały stożek; 5. - ładuje się o 1/3
##   szybciej, 10. - pełne naładowanie ogłusza; kamień unikalny (Rzędów Nawii) - po cięciu w stożku wybucha Nawia
##   rzędami, każdy rząd od prawej do lewej względem postaci (`_mow_rows`).
## - „Taniec Marzanny” (`s_dance`, pomysł autora jak Violation z BDO): kilka kroków naprzód (kierunek z gałki, bez niej
##   ku najbliższemu wrogowi) z kosą wirującą nad głową - co DANCE_TICK rani wrogów wokół; w trakcie i chwilę po
##   (DANCE_WINDOW) przycisk jest gotowy (`cooldown_left` 0) - kolejne stuknięcie płynnie przedłuża taniec za pół many:
##   drugi raz szybciej, kierunek z gałki; po ostatnich krokach cięcie po skosie, które odpycha (gaśnie powoli);
##   5. - wir o DANCE_PERK_AREA większy, 10. - końcowe cięcie zostawia raniącą smugę; kamień unikalny (Wirującego
##   Ostrza) - przy końcowym cięciu wylatuje wirujące ostrze: przez BLADE_TIME s leci od wroga do wroga, na końcu
##   wybucha (`_blades`).
## - „Postać Mary” (`s_mara`, pomysł autora - jak śmierciożercy z Harry'ego Pottera): postać zmienia się w chmurę mgły
##   (MARA_TIME s, nietykalna, szybsza - ProtoHero.form_speed, sterowana gałką) z długim czarnym ogonem z białym brzegiem,
##   wyginającym się po torze, i cząsteczkami (`_MaraCloud`); każdy wróg, przez którego przeleci, dostaje klątwę
##   (czaszki nad głową - mara_curse); po końcu formy (albo drugim stuknięciu) pod każdym przeklętym wybucha Nawia;
##   5. - forma trwa dłużej, 10. - wybuch rani też wrogów obok; kamień unikalny (Bliźniaczych Mar) - dwie dodatkowe
##   chmury same latają i przeklinają wrogów.

const SCYTHE_TEXTURE := preload("res://assets/weapons/scythe.png")
## Punkt chwytu na obrazku (koniec drzewca po lewej).
const S_GRIP := Vector2(8.0, 34.0)
const NAWIA := Color(0.03, 0.02, 0.05)
const BONE := Color(0.93, 0.93, 0.97)
## Efekty z kreatora (wymiary i zaczepienia - pixellab_src/vfx/ids.json).
const SWING_FX := preload("res://assets/effects/scythe_swing.png")
const SWING_FRAMES := 12
const SWING_FPS := 16.0
const SWING_ANCHOR := Vector2(68, 68)
## Efekty kosy (druga wersja, prośba autora 21.11.2026): robione w kreatorze od razu w rozmiarze z gry (bez powiększania
## pikseli), czarno-fioletowe, z przezroczystą otoczką mrocznego dymu - gra ich nie przygasza ani nie robi przezroczystymi.
## Zamach: promień łuku na arkuszu i kąt jego środka (łuk 200° zgodnie z zegarem od góry, środek w prawo).
const SWING_RADIUS := 50.0
const SWING_MID := 0.0
## Klatka szczytu zamachu (smuga z 10. poziomu zostaje na niej).
const SWING_PEAK := 4
const S_HIT_FX := preload("res://assets/effects/scythe_hit.png")
const S_HIT_FRAMES := 9
const S_HIT_FPS := 18.0
const S_HIT_ANCHOR := Vector2(20, 20)
const S_HIT_SIZE := 1.0
const BLAST_FX := preload("res://assets/effects/scythe_blast.png")
const BLAST_FRAMES := 12
const BLAST_FPS := 16.0
const BLAST_ANCHOR := Vector2(32, 36)
## Promień wybuchu na arkuszu (do skalowania pod promień trafienia).
const BLAST_RADIUS := 24.0
const S_WAVE_FX := preload("res://assets/effects/scythe_wave.png")
const S_WAVE_FRAMES := 12
const S_WAVE_FPS := 16.0
const S_WAVE_ANCHOR := Vector2(88, 46)
const S_WAVE_RADIUS_FX := 78.0
## Wybuch cięcia Światowida: cięcie długości SQUARE_BURST_LENGTH w poziomie rozbłyska i odrywa się falą w górę arkusza
## (w grze obrócone - fala leci na zewnątrz kwadratu), odłamki i dym.
const SQUARE_BURST_FX := preload("res://assets/effects/square_burst.png")
const SQUARE_BURST_FRAMES := 12
const SQUARE_BURST_FPS := 16.0
const SQUARE_BURST_ANCHOR := Vector2(56, 62)
const SQUARE_BURST_LENGTH := 76.0
## Zamach Pokosu: łuk 110° (promień na arkuszu), środek w prawo.
const MOW_FX := preload("res://assets/effects/mow_swing.png")
const MOW_FRAMES := 12
const MOW_FPS := 16.0
const MOW_ANCHOR := Vector2(-41, 80)
const MOW_FX_RADIUS := 92.0
## Linie cięć Światowida rysowane w grze (łuki krzyżujące się w rogach): czarno-fioletowy środek, jasnofioletowa
## krawędź, ciemnofioletowa mgiełka dookoła.
const ARC_DARK := Color(0.05, 0.02, 0.09)
const ARC_EDGE := Color(0.82, 0.72, 1.0)
const ARC_SMOKE := Color(0.13, 0.06, 0.22, 0.45)

## Żniwo: czasy (zamach wolniejszy niż miecz - ciężka kosa, za to szerszy łuk), łuk, zasięg od środka postaci;
## smuga z 10. poziomu (czas, co ile rani, siła); kamień unikalny (ile trafień, promień i siła fali).
const REAP_WINDUP := 0.13
const REAP_SWING := 0.22
const REAP_RECOVER := 0.1
const REAP_COOLDOWN := 0.62
const REAP_ARC := deg_to_rad(200.0)
const REAP_REACH := 56.0
const TRAIL_TIME := 1.2
const TRAIL_TICK := 0.3
const TRAIL_POWER := 0.25
const REAP_CHARGE := 15
const WAVE_RADIUS := 80.0
const WAVE_POWER := 1.0
## Cięcie Światowida: połowa boku kwadratu, co ile kolejne cięcie, siła cięcia, przerwa przed wybuchem, zasięg wybuchu
## za bokiem (5. poziom - szerzej), siła i odepchnięcie, drugi wybuch z 10. (po ilu s, siła).
const SQUARE_HALF := 38.0
## Cięcie boku po łuku: o tyle (część boku) dłuższe z każdej strony - krzyżuje się z sąsiednim w rogu, wygięcie na
## zewnątrz, czas rysowania; kamień unikalny - środki kwadratów o tyle połówek boku od postaci (rogiem do postaci,
## między nimi odstęp).
const SQUARE_ARC_EXT := 0.24
const SQUARE_ARC_SAG := 0.16
const SQUARE_ARC_DRAW := 0.07
const SQUARE_SPREAD := 2.6
const SQUARE_CUT_EVERY := 0.07
const SQUARE_CUT_POWER := 0.45
const SQUARE_CUT_WIDTH := 9.0
const SQUARE_BURST_DELAY := 0.45
const SQUARE_BURST_DEPTH := 36.0
const SQUARE_PERK_AREA := 1.3
const SQUARE_BURST_POWER := 1.3
const SQUARE_PUSH := 140.0
const SQUARE_SECOND := 0.35
const SQUARE_SECOND_POWER := 0.8
## Pokos: pełne ładowanie (5. poziom - krócej), samo puszczenie po tylu s trzymania naładowanej, stożek (ścięty czubek,
## zasięg i pół-kąt od-do), siła (od-do), ogłuszenie z 10.; kamień unikalny (rzędy, odstępy, promień i siła wybuchu).
const MOW_CHARGE := 1.4
const MOW_CHARGE_FAST := 0.93
const MOW_HOLD_MAX := 1.0
const MOW_INNER := 14.0
const MOW_REACH := Vector2(55.0, 120.0)
const MOW_HALF := Vector2(deg_to_rad(32.0), deg_to_rad(55.0))
const MOW_POWER := Vector2(0.9, 2.0)
const MOW_STUN := 1.0
const MOW_FLASH := 0.5
const MOW_ROWS := 3
const MOW_ROW_GAP := 0.14
const MOW_BLAST_GAP := 0.05
const MOW_BLAST_SPACING := 26.0
const MOW_BLAST_RADIUS := 20.0
const MOW_BLAST_POWER := 0.45
## Taniec Marzanny: droga i czas kroków (drugi raz szybciej), okno na przedłużenie, wir (promień, co ile rani, siła,
## 5. poziom - większy), końcowe cięcie (zasięg, łuk, siła, odepchnięcie), smuga z 10. (czas, siła).
const DANCE_DIST := 70.0
const DANCE_TIME := 0.6
const DANCE_TIME_FAST := 0.45
const DANCE_WINDOW := 0.35
const DANCE_RADIUS := 48.0
const DANCE_TICK := 0.12
const DANCE_SPIN_POWER := 0.35
const DANCE_PERK_AREA := 1.3
const DANCE_SLASH_REACH := 60.0
const DANCE_SLASH_ARC := deg_to_rad(140.0)
const DANCE_SLASH_POWER := 1.3
const DANCE_PUSH := 160.0
const DIAG_FX := preload("res://assets/effects/scythe_diag.png")
const DIAG_FRAMES := 14
const DIAG_FPS := 16.0
const DIAG_ANCHOR := Vector2(-8, 30)
## Promień półksiężyca na arkuszu (środek okręgu poza klatką, środek łuku w prawo).
const DIAG_RADIUS := 44.0
## Okręgi cięć Tańca (jak Violation z BDO - zrzuty autora 21.11.2026), składane w grze z półksiężyców cięć (prośba
## autora: „skleić efekt z efektów jak ten”): co DANCE_RING_EVERY s wokół postaci pojawia się DANCE_CUTS cięć
## (scythe_diag, smuklejszy dance_cut albo kółko na 3/4 okręgu dance_loop) na jednym z trzech stałych okręgów
## (DANCE_RINGS: wysokość, spłaszczenie w perspektywie, przechył), kolejne przesunięte o DANCE_CUT_STEP - zawsze układają
## się w okręgi wokół postaci; te z przodu rysują się przed postacią, te z tyłu za nią. Zostają w miejscu i gasną - za
## idącą postacią zostaje ślad.
const DANCE_CUT_FX := preload("res://assets/effects/dance_cut.png")
const DANCE_CUT_FRAMES := 12
const DANCE_CUT_FPS := 16.0
const DANCE_CUT_ANCHOR := Vector2(65, 65)
const DANCE_CUT_RADIUS := 50.0
## Cięcie na 3/4 okręgu (prośba autora - „żeby zataczały kółka”), ten sam rozmiar i zaczepienie co dance_cut; tyle
## z półksiężyców Tańca to takie kółka.
const DANCE_LOOP_FX := preload("res://assets/effects/dance_loop.png")
const DANCE_LOOP_SHARE := 0.5
const DANCE_RING_EVERY := 0.1
const DANCE_CUTS := 2
## Stałe okręgi wokół postaci (prośba autora - cięcia mają zawsze układać się w okręgi): [wysokość nad stopami,
## spłaszczenie, przechył, mnożnik promienia, kierunek cięć]; kolejne cięcia trafiają na kolejne okręgi, a kąt
## przesuwa się o DANCE_CUT_STEP - wir krąży dookoła.
const DANCE_RINGS := [[10.0, 0.36, 0.08, 1.06, 1.0], [19.0, 0.4, -0.08, 1.0, -1.0], [28.0, 0.34, 0.0, 0.92, 1.0]]
const DANCE_CUT_STEP := 2.4
## Cięcia Tańca rosną z obszarem umiejętności do tylu razy (są cienkie - powiększone nie wyglądają kanciasto;
## ogólny limit `_fx_scale` zatrzymywał je na 1,25 i obszar „nie działał” - uwaga autora 21.11.2026).
const DANCE_CUT_MAX_SCALE := 2.0
## Kamień Wirującego Ostrza: czas lotu, prędkość, siła trafienia, zasięg szukania kolejnego wroga, wybuch.
const BLADE_TIME := 3.0
const BLADE_SPEED := 230.0
const BLADE_POWER := 0.6
const BLADE_SEEK := 160.0
const BLADE_BLAST_RADIUS := 40.0
const BLADE_BLAST_POWER := 1.0
## Postać Mary: czas (5. poziom - dłużej), szybkość, zasięg dotknięcia, wybuch klątwy (promień, siła, 10. - obok),
## kamień unikalny (dodatkowe chmury, ich szybkość).
const MARA_TIME := 2.5
const MARA_TIME_LONG := 3.5
const MARA_SPEED := 2.4
const MARA_TOUCH := 18.0
const MARA_BLAST_RADIUS := 22.0
const MARA_SPLASH_RADIUS := 40.0
const MARA_SPLASH_POWER := 0.5
const MARA_TWINS := 2
const MARA_TWIN_SPEED := 190.0
const CURSE_FX := preload("res://assets/effects/mara_curse.png")
const CURSE_FRAMES := 16
const CURSE_FPS := 10.0
const CURSE_ANCHOR := Vector2(24, 37)

## Żniwo: licznik zamachów (co trzeci - obrót), czy ten zamach to obrót, trafienia do fali (kamień unikalny).
var reap_count := 0
var _full_spin := false
var reap_hits := 0
## Smugi Nawii ({"node", "aim", "radius", "arc", "left", "tick", "power"}).
var _trails: Array = []
## Kwadraty Światowida w toku ({"center", "half", "t", "cuts", "bursts", "lines": [Line2D], "ghost", "area", "power"}).
var _squares: Array = []
## Pokos: ładowanie (s), stożek na ziemi (wypełnienie i obrys), zaplanowane wybuchy rzędów ({"at", "t"}).
var _charge := 0.0
var _mow_poly: Polygon2D
var _mow_edge: Line2D
var _mow_blasts: Array = []
## Ile wybuchów rzędów było (do testów).
var mow_blasts_done := 0
## Taniec Marzanny: które użycie (1 albo 2), czas kroków, ile trwają, kierunek, odliczanie wiru, czekanie na
## przedłużenie, przedłużenie zamówione w trakcie kroków.
var dance_uses := 0
var _dance_t := 0.0
var _dance_time := 0.0
var _dance_dir := Vector2.RIGHT
var _dance_tick := 0.0
## Odliczanie do kolejnego okręgu cięć w trakcie tańca.
var _ring_t := 0.0
## Który okrąg Tańca dostaje następne cięcie i pod jakim kątem.
var _ring_i := 0
var _ring_angle := 0.0
var _dance_queued := false
## Wirujące ostrza ({"node", "target", "left", "power", "last"}).
var _blades: Array = []
## Postać Mary: ile jeszcze trwa, chmury (postać + bliźniacze: {"node", "twin", "target"}), przeklęci (cel -> znak).
var mara_left := 0.0
## Czy trwa forma chmury (osobno od czasu - po jego upływie forma musi się jeszcze zakończyć: postać wraca, chmura znika).
var mara_on := false
var _clouds: Array = []
var cursed := {}
var _mara_power := 0.0


func _init() -> void:
	basic = "s_reap"
	main_skill = "s_reap"
	element = Elements.NAWIA
	flicker_cut = false


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = SCYTHE_TEXTURE
		s.offset = -S_GRIP


func _world_fx() -> Array:
	return super._world_fx() + [_trails, _squares, [_mow_poly, _mow_edge], _blades, _clouds]


func _exit_tree() -> void:
	if mara_on:
		_mara_restore()
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"r_windup", "r_swing", "r_recover":
			_process_reap()
		"mow_charge":
			_process_mow_charge(delta)
		"square_spin":
			_place(_aim + TAU * clampf(_t / (SQUARE_CUT_EVERY * 4.0), 0.0, 1.0))
			if _t >= SQUARE_CUT_EVERY * 4.0 + 0.05:
				_end_skill()
		"dance", "dance_wait":
			_process_dance(delta)
		"mara":
			_process_mara(delta)
	_process_trails(delta)
	_process_squares(delta)
	_process_mow_blasts(delta)
	_process_blades(delta)


## Trafienie umiejętnością `skill` z siłą `power` (z rozbłyskiem Nawii na celu).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String) -> void:
	_deal(t, _roll(power), from, skill)
	if not Fx.crowded(S_HIT_FX):
		Fx.once(get_parent(), S_HIT_FX, S_HIT_FRAMES, S_HIT_FPS, t.center().round(), S_HIT_ANCHOR, 21, S_HIT_SIZE)


## Zamach z kreatora: środek łuku ku `aim`, `sign` - kierunek (odbicie), promień `radius`. Zwraca węzeł efektu.
func _swing_fx(at: Vector2, aim: float, sign_: float, radius: float) -> Sprite2D:
	var fx := Fx.once(get_parent(), SWING_FX, SWING_FRAMES, SWING_FPS, at.round(), SWING_ANCHOR, 5, _fx_scale(radius / SWING_RADIUS))
	fx.rotation = aim - SWING_MID * sign_
	fx.scale.y *= sign_
	return fx


## Skala efektu: bez powiększania ponad 1,25 (powiększone piksele wyglądały kanciasto - uwaga autora 21.11.2026).
static func _fx_scale(k: float) -> float:
	return minf(k, 1.25)


## Trafia wszystkich, których środek leży w łuku `arc` wokół kierunku `aim`, w odległości `inner`..`reach` od `at`.
func _arc_hits(at: Vector2, aim: float, reach: float, arc: float, power: float, skill: String, inner := 0.0) -> Array:
	var hit: Array = []
	for t in _near_c(at, reach):
		var to := t.center() - at
		var d := to.length()
		if d <= reach + t.center_height * 0.3 and d >= inner and (arc >= TAU or absf(angle_difference(aim, to.angle())) <= arc / 2.0):
			_hit(t, power, hero.global_position, skill)
			hit.append(t)
	return hit


# --- Żniwo (zwykły atak) ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
		reap_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	_full_spin = _perk(basic, 0) and not second and reap_count % 3 == 0
	var best := _nearest(Skills.DATA[basic].range * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("r_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


## Kąt kosy w chwili `k` zamachu (obrót z 5. poziomu - pełne koło).
func _reap_angle(k: float) -> float:
	var arc := TAU if _full_spin else REAP_ARC
	return _aim + lerpf(-arc / 2.0, arc / 2.0, k) * _sign


func _process_reap() -> void:
	match _state:
		"r_windup":
			var k := ease(clampf(_t / REAP_WINDUP, 0.0, 1.0), -2.0)
			var a := _reap_angle(-0.08)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= REAP_WINDUP:
				_set_state("r_swing")
				var radius := REAP_REACH * _area(basic)
				_swing_fx(_orbit_center(), _aim, _sign, radius)
				if _full_spin:
					_swing_fx(_orbit_center(), _aim + PI, _sign, radius)
		"r_swing":
			var progress := clampf(_t / (REAP_SWING * (1.5 if _full_spin else 1.0)), 0.0, 1.0)
			_place(_reap_angle(ease(progress, 0.5)))
			if not _hit_done and progress >= 0.45:
				_hit_done = true
				_reap_hit()
			if progress >= 1.0:
				_set_state("r_recover")
		"r_recover":
			_place(_reap_angle(1.0))
			if _t >= REAP_RECOVER:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: drugi zamach w drugą stronę
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = REAP_COOLDOWN


## Zamach Żniwa: wszyscy w łuku (obrót - dookoła); 10. poziom - smuga Nawii; kamień unikalny - licznik do fali.
func _reap_hit() -> void:
	var power := _swing_power * _power(basic)
	var reach := REAP_REACH * _area(basic)
	var arc := TAU if _full_spin else REAP_ARC
	var hit := _arc_hits(_orbit_center(), _aim, reach, arc, power, basic)
	if _perk(basic, 1) and not _second:
		_spawn_trail(_aim, reach, arc, power * TRAIL_POWER)
	if _unique(basic):
		reap_hits += hit.size()
		if reap_hits >= REAP_CHARGE:
			reap_hits -= REAP_CHARGE
			_reap_wave(power)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


## Smuga Nawii (10. poziom Żniwa): szczyt zamachu zostaje na TRAIL_TIME s i gaśnie, co TRAIL_TICK rani w łuku.
func _spawn_trail(aim: float, radius: float, arc: float, power: float, skill := "s_reap") -> void:
	var node := Sprite2D.new()
	node.texture = SWING_FX
	node.hframes = SWING_FRAMES
	node.frame = SWING_PEAK
	node.centered = false
	node.offset = -SWING_ANCHOR
	node.scale = Vector2.ONE * _fx_scale(radius / SWING_RADIUS)
	node.rotation = aim - SWING_MID * _sign
	node.scale.y *= _sign
	node.z_index = 4
	get_parent().add_child(node)
	node.global_position = _orbit_center().round()
	_trails.append({"node": node, "aim": aim, "radius": radius, "arc": arc, "left": TRAIL_TIME, "tick": TRAIL_TICK,
			"power": power, "at": _orbit_center(), "skill": skill})


func _process_trails(delta: float) -> void:
	for tr_ in _trails.duplicate():
		tr_.left -= delta
		tr_.tick -= delta
		var node: Sprite2D = tr_.node
		node.frame = SWING_PEAK + mini(int((TRAIL_TIME - tr_.left) / TRAIL_TIME * (SWING_FRAMES - SWING_PEAK)), SWING_FRAMES - SWING_PEAK - 1)
		if tr_.tick <= 0.0:
			tr_.tick = TRAIL_TICK
			_arc_hits(tr_.at, tr_.aim, tr_.radius, tr_.arc, tr_.power, tr_.skill, tr_.radius * 0.4)
		if tr_.left <= 0.0:
			node.queue_free()
			_trails.erase(tr_)


## Kamień unikalny Żniwa: fala Nawii dookoła postaci (pierścień z kreatora, przygaszony).
func _reap_wave(power: float) -> void:
	var radius := WAVE_RADIUS * _area(basic)
	var fx := Fx.once(get_parent(), S_WAVE_FX, S_WAVE_FRAMES, S_WAVE_FPS, hero.global_position.round(), S_WAVE_ANCHOR, -1,
			_fx_scale(radius / S_WAVE_RADIUS_FX))
	for t in _near(hero.global_position, radius):
		if t.global_position.distance_to(hero.global_position) <= radius:
			_hit(t, power * WAVE_POWER, hero.global_position, basic)
	Input.vibrate_handheld(25)


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["s_square", "s_mow", "s_dance", "s_mara"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	var best := _nearest(Skills.DATA[id].range * _area(id))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"s_square":
			_cast_square()
			_set_state("square_spin")
		"s_mow":
			_charge = 0.0
			_mow_poly = Polygon2D.new()
			_mow_poly.color = Color(NAWIA, 0.3)
			_mow_poly.z_index = -1
			get_parent().add_child(_mow_poly)
			_mow_edge = Line2D.new()
			_mow_edge.width = 1.0
			_mow_edge.default_color = Color(BONE, 0.45)
			_mow_edge.closed = true
			_mow_edge.z_index = -1
			get_parent().add_child(_mow_edge)
			_set_state("mow_charge")
		"s_dance":
			dance_uses = 1
			_dance_queued = false
			_dance_steps(DANCE_TIME)
		"s_mara":
			_start_mara()
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


func _end_skill() -> void:
	dance_uses = 0
	_dance_queued = false
	_sprite.visible = true
	if mara_on:
		_mara_finish()
	for n in [_mow_poly, _mow_edge]:
		if n and is_instance_valid(n):
			n.queue_free()
	_mow_poly = null
	_mow_edge = null
	super._end_skill()


# --- Cięcie Światowida ---

## Kwadrat (albo cztery z kamieniem unikalnym) wokół postaci - cięcia i wybuchy biegną w `_process_squares`.
func _cast_square() -> void:
	var half := SQUARE_HALF * _area("s_square")
	var centers: Array = [hero.global_position]
	var rot := 0.0
	if _unique("s_square"):  # 4 kwadraty po czterech stronach, obrócone rogiem do postaci, z odstępami
		centers = []
		rot = PI / 4.0
		for i in 4:
			centers.append(hero.global_position + Vector2.from_angle(-PI / 2.0 + i * PI / 2.0) * half * SQUARE_SPREAD)
	for c in centers:
		var ghost: Sprite2D = null
		if centers.size() > 1:  # widmowa kosa wiruje nad każdym kwadratem
			ghost = Sprite2D.new()
			ghost.texture = SCYTHE_TEXTURE
			ghost.centered = false
			ghost.offset = -S_GRIP
			ghost.scale = Vector2.ONE * SCALE
			ghost.modulate = Color(0.85, 0.85, 0.95, 0.7)
			ghost.z_index = 6
			get_parent().add_child(ghost)
			ghost.global_position = c + Vector2(0, -ORBIT_HEIGHT)
		_squares.append({"center": c, "half": half, "t": 0.0, "cuts": 0, "bursts": 0, "lines": [], "draw": [], "ghost": ghost, "rot": rot,
				"area": SQUARE_PERK_AREA if _perk("s_square", 0) else 1.0, "power": _power("s_square"),
				"twice": _perk("s_square", 1)})
	Input.vibrate_handheld(15)


## Boki kwadratu obróconego o `rot`: [początek, koniec, kierunek na zewnątrz] (zgodnie z zegarem od lewego górnego rogu).
static func square_sides(center: Vector2, half: float, rot := 0.0) -> Array:
	var tl := center + Vector2(-half, -half).rotated(rot)
	var tr_ := center + Vector2(half, -half).rotated(rot)
	var br := center + Vector2(half, half).rotated(rot)
	var bl := center + Vector2(-half, half).rotated(rot)
	return [[tl, tr_, Vector2.UP.rotated(rot)], [tr_, br, Vector2.RIGHT.rotated(rot)], [br, bl, Vector2.DOWN.rotated(rot)],
			[bl, tl, Vector2.LEFT.rotated(rot)]]


func _process_squares(delta: float) -> void:
	for sq in _squares.duplicate():
		sq.t += delta
		var sides := square_sides(sq.center, sq.half, sq.rot)
		if sq.ghost:
			sq.ghost.rotation += delta * 18.0
		while sq.cuts < 4 and sq.t >= sq.cuts * SQUARE_CUT_EVERY:
			_square_cut(sq, sides[sq.cuts])
			sq.cuts += 1
		for d in sq.draw.duplicate():  # cięcie po łuku rysuje się od początku do końca
			d.t += delta
			var k := clampf(d.t / SQUARE_ARC_DRAW, 0.0, 1.0)
			var n := maxi(2, ceili(k * d.pts.size()))
			for l in d.lines:
				(l as Line2D).points = d.pts.slice(0, n)
			if k >= 1.0:
				sq.draw.erase(d)
		var burst_at: float = 4 * SQUARE_CUT_EVERY + SQUARE_BURST_DELAY
		var bursts: int = 2 if sq.twice else 1
		while sq.bursts < bursts and sq.t >= burst_at + sq.bursts * SQUARE_SECOND:
			var power: float = sq.power * SQUARE_BURST_POWER * (1.0 if sq.bursts == 0 else SQUARE_SECOND_POWER)
			for side in sides:
				_square_burst(sq, side, power)
			sq.bursts += 1
		if sq.bursts >= bursts:
			for l in sq.lines:
				var line: Line2D = l
				line.create_tween().tween_property(line, "modulate:a", 0.0, 0.3).finished.connect(line.queue_free)
			if sq.ghost:
				sq.ghost.queue_free()
			_squares.erase(sq)


## Łuk cięcia boku a-b: wygięty na zewnątrz (`out`), z każdej strony dłuższy o SQUARE_ARC_EXT boku - sąsiednie łuki
## krzyżują się w rogach kwadratu.
static func square_arc(a: Vector2, b: Vector2, out: Vector2, steps := 14) -> PackedVector2Array:
	var len := a.distance_to(b)
	var along := (b - a) / len
	var p0 := a - along * len * SQUARE_ARC_EXT
	var p2 := b + along * len * SQUARE_ARC_EXT
	var p1 := a.lerp(b, 0.5) + out * len * SQUARE_ARC_SAG * 2.0  # punkt kontrolny - szczyt łuku w połowie wygięcia
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return pts


## Jedno cięcie boku po łuku: czarny półksiężyc (zwężony na końcach) z białą krawędzią po zewnętrznej stronie i błysk;
## zostaje do wybuchu, rani stojących na nim.
func _square_cut(sq: Dictionary, side: Array) -> void:
	var out_dir: Vector2 = side[2]
	var pts := square_arc(side[0], side[1], out_dir)
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.15))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.15))
	var lines: Array = []
	for w in [[11.0, ARC_SMOKE, Vector2.ZERO], [5.0, ARC_DARK, Vector2.ZERO], [1.5, ARC_EDGE, out_dir * 2.0]]:
		var line := Line2D.new()
		line.width = w[0]
		line.width_curve = taper
		line.default_color = w[1]
		line.position = w[2]
		line.z_index = 3
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.points = pts.slice(0, 2)
		get_parent().add_child(line)
		sq.lines.append(line)
		lines.append(line)
	var flash := Line2D.new()  # biały błysk cięcia, gaśnie
	flash.width = 3.0
	flash.width_curve = taper
	flash.default_color = ARC_EDGE
	flash.points = pts
	flash.z_index = 4
	get_parent().add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.25).set_delay(SQUARE_ARC_DRAW).finished.connect(flash.queue_free)
	sq.draw.append({"lines": lines, "pts": pts, "t": 0.0})
	for t in _arc_targets(pts, SQUARE_CUT_WIDTH):
		_hit(t, sq.power * SQUARE_CUT_POWER, sq.center, "s_square")


## Wrogowie, których stopy stoją w pasie szerokości `width` wzdłuż łamanej `pts` (kwadrat leży na ziemi).
func _arc_targets(pts: PackedVector2Array, width: float) -> Array:
	var out: Array = []
	var mid := pts[pts.size() / 2]
	for t in _near(mid, pts[0].distance_to(pts[-1]) * 0.6 + width):
		var c := t.global_position
		for i in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(c, pts[i], pts[i + 1]).distance_to(c) <= width * 0.5 + 4.0:
				out.append(t)
				break
	return out


## Wybuch boku na zewnątrz: rani i odpycha wrogów za bokiem (do SQUARE_BURST_DEPTH od niego), czarne wybuchy wzdłuż boku.
func _square_burst(sq: Dictionary, side: Array, power: float) -> void:
	var a: Vector2 = side[0]
	var b: Vector2 = side[1]
	var out: Vector2 = side[2]
	var depth: float = SQUARE_BURST_DEPTH * _area("s_square") * sq.area
	var along := (b - a).normalized()
	var len := a.distance_to(b)
	var mid := a.lerp(b, 0.5)
	for t in _near(mid + out * depth * 0.5, len * 0.5 + depth):
		var rel := t.global_position - a
		var s := rel.dot(along)
		var d := rel.dot(out)
		if s >= -6.0 and s <= len + 6.0 and d >= -8.0 and d <= depth + 6.0:
			_hit(t, power, sq.center, "s_square")
			t.push_away(sq.center, SQUARE_PUSH)
	if not Fx.crowded(SQUARE_BURST_FX, 24):  # cięcie wybucha falą na zewnątrz (w arkuszu - w górę)
		var fx := Fx.once(get_parent(), SQUARE_BURST_FX, SQUARE_BURST_FRAMES, SQUARE_BURST_FPS, mid.round(),
				SQUARE_BURST_ANCHOR, 6)
		fx.rotation = out.angle() + PI / 2.0
		fx.scale = Vector2(len / SQUARE_BURST_LENGTH, _fx_scale(depth / SQUARE_BURST_DEPTH))
	Input.vibrate_handheld(20)


# --- Pokos ---

## Stożek ze ściętym czubkiem: punkty (łuk wewnętrzny i zewnętrzny) wokół `at` w kierunku `aim`.
static func cone_points(at: Vector2, aim: float, inner: float, reach: float, half: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		pts.append(at + Vector2.from_angle(aim - half + 2.0 * half * i / steps) * reach)
	for i in range(steps, -1, -1):
		pts.append(at + Vector2.from_angle(aim - half + 2.0 * half * i / steps) * inner)
	return pts


func _mow_shape(k: float) -> Vector3:
	return Vector3(MOW_INNER, lerpf(MOW_REACH.x, MOW_REACH.y, k) * _area("s_mow"), lerpf(MOW_HALF.x, MOW_HALF.y, k))


## Ładowanie Pokosu: dopóki palec trzyma przycisk; stożek na ziemi rośnie, kosa uniesiona za postacią drży coraz mocniej.
func _process_mow_charge(delta: float) -> void:
	var full := MOW_CHARGE_FAST if _perk("s_mow", 0) else MOW_CHARGE
	_charge += delta
	var k := clampf(_charge / full, 0.0, 1.0)
	var shape := _mow_shape(k)
	var near := _nearest(shape.y)
	if near:
		_aim = (near.global_position - hero.global_position).angle()
	elif hero.velocity.length() > 1.0:
		_aim = hero.facing.angle()
	var pts := cone_points(hero.global_position, _aim, shape.x, shape.y, shape.z)
	if _mow_poly:
		_mow_poly.polygon = pts
		_mow_poly.color = Color(NAWIA, 0.22 + 0.18 * k + (0.08 * sin(_clock * 20.0) if k >= 1.0 else 0.0))
		_mow_edge.points = pts
	var dir := Vector2.from_angle(_aim)
	position = hero.position + Vector2(0, -1)
	_sprite.position = _orbit_center() - global_position + Vector2(-dir.x * 8.0, -16.0) \
			+ Vector2(randf_range(-1, 1), randf_range(-1, 1)) * k
	_sprite.rotation = -PI / 2.0 - 0.5 * signf(dir.x)
	if not charge_held or _charge >= full + MOW_HOLD_MAX:
		_mow_cut(k)


## Cięcie Pokosu: wszyscy w stożku obrywają (siła od naładowania), zamach kosy przez cały stożek i ciemny błysk stożka;
## 10. poziom przy pełnym naładowaniu ogłusza; kamień unikalny - rzędy wybuchów Nawii.
func _mow_cut(k: float) -> void:
	var shape := _mow_shape(k)
	var at := hero.global_position
	var power := _power("s_mow") * lerpf(MOW_POWER.x, MOW_POWER.y, k)
	var hit: Array = []
	for t in _near(at, shape.y):
		var to := t.global_position - at
		var d := to.length()
		if d <= shape.y + 4.0 and d >= shape.x * 0.5 and absf(angle_difference(_aim, to.angle())) <= shape.z + 0.08:
			_hit(t, power, at, "s_mow")
			hit.append(t)
			if _perk("s_mow", 1) and k >= 1.0:
				t.stun(MOW_STUN)
	var mow := Fx.once(get_parent(), MOW_FX, MOW_FRAMES, MOW_FPS, hero.global_position.round(), MOW_ANCHOR, 5,
			_fx_scale(shape.y * 0.92 / MOW_FX_RADIUS))
	mow.rotation = _aim
	mow.scale.y = -mow.scale.y  # zamach od drugiej strony (prośba autora 21.11.2026)
	var flash := Polygon2D.new()
	flash.polygon = cone_points(at, _aim, shape.x, shape.y, shape.z)
	flash.color = Color(NAWIA, 0.6)
	flash.z_index = -1
	var edge := Line2D.new()
	edge.points = flash.polygon
	edge.closed = true
	edge.width = 1.5
	edge.default_color = BONE
	flash.add_child(edge)
	get_parent().add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, MOW_FLASH).finished.connect(flash.queue_free)
	if _unique("s_mow"):
		_mow_rows(at, _aim, shape, power)
	Input.vibrate_handheld(35)
	_end_skill()


## Kamień unikalny Pokosu: wybuchy Nawii w MOW_ROWS rzędach (od bliższego), każdy rząd od prawej do lewej względem
## postaci (prawa ręka przy patrzeniu w `aim` - większy kąt na ekranie).
func _mow_rows(at: Vector2, aim: float, shape: Vector3, power: float) -> void:
	for r in MOW_ROWS:
		var radius := lerpf(shape.x + 16.0, shape.y - 10.0, float(r) / maxf(MOW_ROWS - 1, 1))
		var count := maxi(3, int(2.0 * shape.z * radius / MOW_BLAST_SPACING) + 1)
		for i in count:
			var a := aim + shape.z * 0.9 - 1.8 * shape.z * i / maxf(count - 1, 1)
			_mow_blasts.append({"at": at + Vector2.from_angle(a) * radius, "t": 0.15 + r * MOW_ROW_GAP + i * MOW_BLAST_GAP,
					"power": power * MOW_BLAST_POWER, "row": r})


func _process_mow_blasts(delta: float) -> void:
	for b in _mow_blasts.duplicate():
		b.t -= delta
		if b.t > 0.0:
			continue
		_mow_blasts.erase(b)
		mow_blasts_done += 1
		var radius := MOW_BLAST_RADIUS * _area("s_mow")
		if not Fx.crowded(BLAST_FX, 16):
			Fx.once(get_parent(), BLAST_FX, BLAST_FRAMES, BLAST_FPS, (b.at as Vector2).round(), BLAST_ANCHOR, 7,
					radius / BLAST_RADIUS)
		for t in _near(b.at, radius):
			if t.global_position.distance_to(b.at) <= radius + 4.0:
				_hit(t, b.power, b.at, "s_mow")


# --- Taniec Marzanny ---

## Przycisk Tańca jest gotowy w trakcie kroków i chwilę po nich (przedłużenie), Postaci Mary - w trakcie formy (koniec).
func cooldown_left(id: String) -> float:
	if id == "s_dance" and _dance_can_extend():
		return 0.0
	if id == "s_mara" and mara_on:
		return 0.0
	return super.cooldown_left(id)


## Stuknięcie w trakcie Tańca przedłuża go (za pół many), w trakcie Postaci Mary - kończy formę.
func cast(id: String) -> bool:
	if id == "s_dance" and _dance_can_extend():
		var cost := roundi(mana_cost(id) * 0.5)
		if not hero.spend_mana(cost):
			cast_failed.emit(id, "mana")
			return false
		if _state == "dance":
			_dance_queued = true  # płynnie: drugie kroki zaraz po pierwszych
		else:
			dance_uses = 2
			_dance_steps(DANCE_TIME_FAST)
		return true
	if id == "s_mara" and mara_on:
		_end_skill()
		return true
	return super.cast(id)


func _dance_can_extend() -> bool:
	return _state in ["dance", "dance_wait"] and dance_uses == 1 and not _dance_queued


## Kierunek kroków: gałka, bez niej najbliższy wróg, bez niego kierunek patrzenia.
func _dance_direction() -> Vector2:
	var stick: Vector2 = hero.joystick.vector if hero.joystick else Vector2.ZERO
	if stick.length() > 0.2:
		return stick.normalized()
	var best := _nearest(Skills.DATA["s_dance"].range * 2.0)
	if best:
		return (best.global_position - hero.global_position).normalized()
	return hero.facing.normalized() if hero.facing.length() > 0.1 else Vector2.RIGHT


func _dance_steps(time: float) -> void:
	_dance_dir = _dance_direction()
	_dance_t = 0.0
	_dance_time = time
	_dance_tick = 0.0
	hero.leap(hero.global_position + _dance_dir * DANCE_DIST * _area("s_dance"), time)
	_set_state("dance")


func _dance_radius() -> float:
	return DANCE_RADIUS * _area("s_dance") * (DANCE_PERK_AREA if _perk("s_dance", 0) else 1.0)


## Kroki z kosą wirującą nad głową: wir rani co DANCE_TICK; po krokach czekanie na przedłużenie albo końcowe cięcie.
func _process_dance(delta: float) -> void:
	_dance_t += delta
	position = hero.position + Vector2(0, -1)
	_sprite.position = _orbit_center() - global_position + Vector2(0, -16)
	_sprite.rotation += delta * (26.0 if dance_uses == 2 else 20.0)
	_dance_tick -= delta
	var radius := _dance_radius()
	if _dance_tick <= 0.0:
		_dance_tick = DANCE_TICK
		for t in _near(hero.global_position, radius):
			if t.global_position.distance_to(hero.global_position) <= radius + 4.0:
				_hit(t, _power("s_dance") * DANCE_SPIN_POWER, hero.global_position, "s_dance")
	_ring_t -= delta
	if _ring_t <= 0.0 and not Fx.crowded(DANCE_CUT_FX, 30):  # półksiężyce cięć wokół postaci - ślad za nią
		_ring_t = DANCE_RING_EVERY
		for i in DANCE_CUTS:
			_dance_cut(radius)
	if _state == "dance" and _dance_t >= _dance_time:
		if _dance_queued:
			_dance_queued = false
			dance_uses = 2
			_dance_steps(DANCE_TIME_FAST)
		elif dance_uses >= 2:
			_dance_slash()
		else:
			_set_state("dance_wait")
	elif _state == "dance_wait" and _t >= DANCE_WINDOW:
		_dance_slash()


## Jeden półksiężyc cięcia Tańca: węzeł spłaszczony i lekko przechylony (perspektywa okręgu wokół postaci), w nim efekt
## obrócony pod losowym kątem; z przodu (dolna połowa okręgu) przed postacią, z tyłu za nią. Znika razem z efektem.
func _dance_cut(radius: float) -> void:
	var ring: Array = DANCE_RINGS[_ring_i % DANCE_RINGS.size()]
	_ring_i += 1
	_ring_angle = fmod(_ring_angle + DANCE_CUT_STEP, TAU)
	var a := _ring_angle
	var holder := Node2D.new()
	holder.scale = Vector2(1.0, ring[1])
	holder.rotation = ring[2]
	holder.z_index = 2 if sin(a) > 0.0 else -1
	get_parent().add_child(holder)
	holder.global_position = (hero.global_position + Vector2(0, -ring[0])).round()
	var roll := randf()
	var r: float = radius * ring[3]
	var fx: Sprite2D
	if roll < DANCE_LOOP_SHARE or roll < DANCE_LOOP_SHARE + 0.3:  # kółko na 3/4 okręgu albo smukły półksiężyc
		fx = Fx.once(holder, DANCE_LOOP_FX if roll < DANCE_LOOP_SHARE else DANCE_CUT_FX, DANCE_CUT_FRAMES, DANCE_CUT_FPS,
				holder.global_position, DANCE_CUT_ANCHOR, 0, minf(r / DANCE_CUT_RADIUS, DANCE_CUT_MAX_SCALE))
	else:
		fx = Fx.once(holder, DIAG_FX, DIAG_FRAMES, DIAG_FPS, holder.global_position, DIAG_ANCHOR, 0,
				minf(r / DIAG_RADIUS, DANCE_CUT_MAX_SCALE))
	fx.rotation = a
	fx.scale.y *= ring[4]  # każdy okrąg kręci się w swoją stronę
	fx.tree_exited.connect(holder.queue_free)


## Końcowe cięcie po skosie: rani w łuku przed postacią i odpycha; 10. poziom - smuga; kamień unikalny - wirujące ostrze.
func _dance_slash() -> void:
	var reach := DANCE_SLASH_REACH * _area("s_dance")
	var aim := _dance_dir.angle()
	var power := _power("s_dance") * DANCE_SLASH_POWER
	for t in _arc_hits(_orbit_center(), aim, reach, DANCE_SLASH_ARC, power, "s_dance"):
		t.push_away(hero.global_position, DANCE_PUSH)
	var fx := Fx.once(get_parent(), DIAG_FX, DIAG_FRAMES, DIAG_FPS, _orbit_center().round(),
			DIAG_ANCHOR, 6, _fx_scale(reach / DIAG_RADIUS))
	fx.rotation = aim + 0.35  # półksiężyc przed postacią, lekko po skosie
	if _perk("s_dance", 1):
		_spawn_trail(aim, reach, DANCE_SLASH_ARC, power * TRAIL_POWER, "s_dance")
	if _unique("s_dance"):
		_spawn_blade(power * BLADE_POWER)
	Input.vibrate_handheld(30)
	_end_skill()


# --- Kamień Wirującego Ostrza ---

func _spawn_blade(power: float) -> void:
	var node := Node2D.new()
	node.z_index = 6
	var spr := Sprite2D.new()
	spr.texture = SCYTHE_TEXTURE
	spr.region_enabled = true
	spr.region_rect = Rect2(30, 0, 70, 40)  # samo ostrze z kawałkiem drzewca
	spr.scale = Vector2.ONE * 0.4
	node.add_child(spr)
	var tail := Line2D.new()
	tail.width = 3.0
	tail.top_level = true
	tail.z_index = 5
	var g := Gradient.new()
	g.set_color(0, Color(NAWIA, 0.0))
	g.set_color(1, Color(NAWIA, 0.8))
	tail.gradient = g
	node.add_child(tail)
	get_parent().add_child(node)
	node.global_position = _orbit_center()
	_blades.append({"node": node, "target": _nearest(BLADE_SEEK), "left": BLADE_TIME, "power": power, "last": null,
			"tail": tail})


func _process_blades(delta: float) -> void:
	for b in _blades.duplicate():
		var node: Node2D = b.node
		b.left -= delta
		node.get_child(0).rotation += delta * 24.0
		var tail: Line2D = b.tail
		tail.add_point(node.global_position)
		while tail.get_point_count() > 10:
			tail.remove_point(0)
		var target: ProtoTarget = b.target
		if target == null or not is_instance_valid(target) or not target.alive():
			b.target = _blade_next(node.global_position, b.last)
			target = b.target
		if target:
			var to := target.center() - node.global_position
			node.global_position += to.limit_length(BLADE_SPEED * delta)
			if to.length() <= 10.0:
				_hit(target, b.power, node.global_position, "s_dance")
				b.last = target
				b.target = _blade_next(node.global_position, target)
		if b.left <= 0.0:
			var radius := BLADE_BLAST_RADIUS * _area("s_dance")
			Fx.once(get_parent(), BLAST_FX, BLAST_FRAMES, BLAST_FPS, node.global_position.round(), BLAST_ANCHOR, 7,
					radius / BLAST_RADIUS)
			for t in _near(node.global_position, radius):
				if t.global_position.distance_to(node.global_position) <= radius + 4.0:
					_hit(t, b.power / BLADE_POWER * BLADE_BLAST_POWER, node.global_position, "s_dance")
			node.queue_free()
			_blades.erase(b)


## Następny cel ostrza: najbliższy żywy wróg w BLADE_SEEK, inny niż ostatnio trafiony (gdy się da).
func _blade_next(at: Vector2, last: Variant) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := BLADE_SEEK
	for t in _near(at, BLADE_SEEK):
		if t == last or not t.alive():
			continue
		var d := t.global_position.distance_to(at)
		if d < best_d:
			best = t
			best_d = d
	return best


# --- Postać Mary ---

func _start_mara() -> void:
	mara_on = true
	mara_left = MARA_TIME_LONG if _perk("s_mara", 0) else MARA_TIME
	_mara_power = _power("s_mara")
	cursed.clear()
	hero.protect(mara_left + 0.2)
	hero.form_speed = MARA_SPEED
	hero._sprite.modulate.a = 0.0
	_sprite.visible = false
	_clouds.append(_make_cloud(false))
	if _unique("s_mara"):
		for i in MARA_TWINS:
			_clouds.append(_make_cloud(true))
	_set_state("mara")


func _make_cloud(twin: bool) -> Dictionary:
	var cloud := _MaraCloud.new()
	cloud.twin = twin
	get_parent().add_child(cloud)
	cloud.global_position = hero.global_position + (Vector2.from_angle(randf() * TAU) * 6.0 if twin else Vector2.ZERO)
	return {"node": cloud, "twin": twin, "target": null}


func _process_mara(delta: float) -> void:
	mara_left -= delta
	position = hero.position
	for c in _clouds:
		var cloud: _MaraCloud = c.node
		if not c.twin:
			cloud.global_position = hero.global_position
		else:
			var target: ProtoTarget = c.target
			if target == null or not is_instance_valid(target) or not target.alive() or cursed.has(target):
				c.target = _mara_seek(cloud.global_position)
				target = c.target
			if target:
				var to := target.global_position - cloud.global_position
				cloud.global_position += to.limit_length(MARA_TWIN_SPEED * delta)
			else:  # nikogo do przeklęcia - krąży przy postaci
				cloud.global_position = cloud.global_position.lerp(hero.global_position, 1.0 - exp(-3.0 * delta))
		for t in _near(cloud.global_position, MARA_TOUCH + 8.0):
			if not cursed.has(t) and t.alive() and t.global_position.distance_to(cloud.global_position) <= MARA_TOUCH:
				_curse(t)
	if mara_left <= 0.0 or hero.dead:
		_end_skill()


## Najbliższy nieprzeklęty wróg (bliźniacze chmury).
func _mara_seek(at: Vector2) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := INF
	for t in live_targets():
		if cursed.has(t) or not t.alive():
			continue
		var d := t.global_position.distance_to(at)
		if d < best_d:
			best = t
			best_d = d
	return best


## Klątwa: czaszki krążą nad głową wroga do końca formy.
func _curse(t: ProtoTarget) -> void:
	var mark := Fx.loop(t, CURSE_FX, CURSE_FRAMES, CURSE_FPS, Vector2(0, -t.center_height * 2.0 - 4.0), CURSE_ANCHOR, 8, 0.5)
	cursed[t] = mark
	_hit(t, _mara_power * 0.2, hero.global_position, "s_mara")


## Koniec formy: postać wraca, pod każdym przeklętym wybucha Nawia (10. poziom - rani też wrogów obok).
func _mara_finish() -> void:
	_mara_restore()
	var radius := MARA_BLAST_RADIUS * _area("s_mara")
	for t in cursed:
		var mark = cursed[t]
		if mark != null and is_instance_valid(mark):
			(mark as Node).queue_free()
		if not is_instance_valid(t) or not t.alive():
			continue
		var at: Vector2 = t.global_position
		Fx.once(get_parent(), BLAST_FX, BLAST_FRAMES, BLAST_FPS, at.round(), BLAST_ANCHOR, 7, radius / BLAST_RADIUS)
		_hit(t, _mara_power, at, "s_mara")
		if _perk("s_mara", 1):
			for n in _near(at, MARA_SPLASH_RADIUS * _area("s_mara")):
				if n != t and not cursed.has(n) and n.global_position.distance_to(at) <= MARA_SPLASH_RADIUS * _area("s_mara"):
					_hit(n, _mara_power * MARA_SPLASH_POWER, at, "s_mara")
	cursed.clear()
	Input.vibrate_handheld(40)


## Postać wraca z formy chmury (też przy zmianie broni).
func _mara_restore() -> void:
	mara_left = 0.0
	mara_on = false
	hero.form_speed = 1.0
	hero._sprite.modulate.a = 1.0
	hero._invulnerable = minf(hero._invulnerable, 0.15)
	for c in _clouds:
		var cloud: _MaraCloud = c.node
		if is_instance_valid(cloud):
			cloud.fade_out()
	_clouds.clear()


## Chmura mgły Mary: kłębiące się czarne kule z białymi drobinkami, długi czarny ogon z białym brzegiem po torze
## (Line2D z zapamiętanych pozycji, zwęża się ku końcowi) i cząsteczki (czarne kłęby, białe iskry). Bliźniacza
## chmura (kamień unikalny) - trochę mniejsza.
class _MaraCloud extends Node2D:
	const TAIL_POINTS := 44
	const TAIL_STEP := 3.0
	## Wielkość chmury (kłęby) i szerokość ogona przy chmurze.
	const SIZE := 1.6
	const TAIL_WIDTH := 16.0
	var twin := false
	var _t := 0.0
	var _tail: Line2D
	var _rim: Line2D
	var _smoke: CPUParticles2D
	var _sparks: CPUParticles2D
	var _fading := false

	func _ready() -> void:
		z_index = 5
		var taper := Curve.new()
		taper.add_point(Vector2(0.0, 0.05))
		taper.add_point(Vector2(1.0, 1.0))
		_rim = _line((TAIL_WIDTH + 3.0) * _k(), Color(0.78, 0.66, 1.0), taper)  # jasnofioletowy brzeg
		_tail = _line(TAIL_WIDTH * _k(), Color(0.05, 0.02, 0.09), taper)
		_smoke = _particles(18, Color(0.1, 0.05, 0.17, 0.8), 3.0, 0.7)  # mroczny dym (cząsteczki gasną same)
		_sparks = _particles(8, Color(0.88, 0.8, 1.0), 1.0, 0.5)

	func _k() -> float:
		return 0.75 if twin else 1.0

	func _line(width: float, color: Color, taper: Curve) -> Line2D:
		var l := Line2D.new()
		l.width = width
		l.width_curve = taper
		l.default_color = color
		l.top_level = true
		l.z_index = 4
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(l)
		return l

	func _particles(amount: int, color: Color, size: float, life: float) -> CPUParticles2D:
		var p := CPUParticles2D.new()
		p.amount = amount
		p.lifetime = life
		p.local_coords = false
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 7.0 * _k() * SIZE
		p.direction = Vector2.UP
		p.spread = 180.0
		p.gravity = Vector2(0, -12)
		p.initial_velocity_min = 4.0
		p.initial_velocity_max = 14.0
		p.scale_amount_min = size
		p.scale_amount_max = size * 1.6
		var g := Gradient.new()
		g.set_color(0, color)
		g.set_color(1, Color(color, 0.0))
		p.color_ramp = g
		p.position = Vector2(0, -10)
		add_child(p)
		return p

	func _process(delta: float) -> void:
		_t += delta
		var head := global_position + Vector2(0, -10)
		var moved := false
		if _tail.get_point_count() == 0 or _tail.get_point_position(_tail.get_point_count() - 1).distance_to(head) >= TAIL_STEP:
			moved = true
			for l in [_tail, _rim]:
				l.add_point(head)
		while _tail.get_point_count() > TAIL_POINTS or (_fading and _tail.get_point_count() > 0):
			for l in [_tail, _rim]:
				l.remove_point(0)
			if _fading:
				break
		if not _fading and not moved and _tail.get_point_count() > 2 and fmod(_t, 0.05) < delta:  # w miejscu ogon się kurczy
			for l in [_tail, _rim]:
				l.remove_point(0)
		queue_redraw()
		if _fading and _tail.get_point_count() == 0:
			queue_free()

	func _draw() -> void:
		if _fading:
			return
		var k := _k() * SIZE
		for i in 5:  # kłęby mgły: kule kręcą się wokół środka
			var a := _t * 5.0 + i * TAU / 5.0
			var p := Vector2(cos(a) * 5.0, sin(a) * 3.0 - 10.0) * k
			draw_circle(p, (5.0 + 1.5 * sin(_t * 9.0 + i)) * k, Color(0.07, 0.03, 0.12) if i % 2 else Color(0.03, 0.015, 0.05))
		draw_circle(Vector2(0, -10) * k, 6.0 * k, Color(0.02, 0.01, 0.03))
		for i in 3:  # białe oczy-iskry w środku
			var a := _t * 7.0 + i * 2.1
			draw_rect(Rect2((Vector2(cos(a) * 4.0, sin(a) * 2.5 - 10.0) * k).round(), Vector2.ONE), Color(0.88, 0.8, 1.0))

	## Chmura znika: ogon zwija się od końca, cząsteczki gasną.
	func fade_out() -> void:
		_fading = true
		_smoke.emitting = false
		_sparks.emitting = false
		queue_redraw()

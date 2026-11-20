class_name ProtoKatana
extends ProtoWeapon
## Elektryczna katana (ustalone z autorem 15.11.2026) - czwarta broń, żywioł Grom (Elements.LIGHTNING), najszybsza
## broń wręcz, szermierka wzmocniona piorunem (przebudowa z pomysłów autora: same cięcia zamiast czarów). Lewituje
## obok postaci jak miecz (dziedziczy po ProtoWeapon: podążanie, orbita cięcia, mana, odnowienia, kamienie, krytyki,
## skoki Mgnienia). Każde trafienie PORAŻA (`_deal`): wróg przez SHOCK_TIME dostaje od wszystkiego o
## Elements.SHOCK_BONUS więcej (ProtoWeapon._combo_mult), a ARC_POWER obrażeń przeskakuje błękitnym piorunem na
## kolejnych wrogów - zawsze najdalszego w zasięgu, bez powtórek, gdy się da (`_chain_from`; z przemoczonego - combo z hydrosferą - na Elements.SOAK_CHAIN_EXTRA wrogów
## więcej i mocniej, a cała katana bije przemoczonych o Elements.SOAK_BONUS mocniej).
## - „Błyskawiczne cięcie” (`k_slash`, zwykły cios): szybkie cienkie cięcie po łuku, przez które przelatuje piorun
##   (`_ArcBolt`); 5. poziom - co 4. cięcie piorun w najdalszego wroga w zasięgu, 10. - przeskok na dwóch wrogów obok;
## - „Taniec ostrza” (`k_dance`): postać idzie naprzód (ProtoHero.leap) i tnie DANCE_CUTS razy cienkimi prostymi
##   liniami, które po chwili naraz wybuchają grubymi cięciami (19.11.2026), na końcu błękitny
##   piorun przeskakuje po kolei między wszystkimi trafionymi (5. - 6 cięć, 10. - piorun skacze też na 3 wrogów obok);
## - „Riposta” (`k_riposte`): katana w gardzie przez RIPOSTE_WAIT - następny cios nie rani (ProtoHero.parry_left,
##   sygnał `parried`), a postać odpowiada: cięcie dookoła, wyskok ku napastnikowi (najbliższemu wrogowi) i cienkie,
##   idealnie równe cięcie po okręgu (`_Ring`), cały czas nietykalna (5. - garda 5 s, 10. - z okręgu przeskakują pioruny);
## - „Sąd Peruna” (`k_perun`, ładowany - Skills.is_charged): dopóki palec trzyma przycisk, katana się ładuje, po
##   puszczeniu tnie w linii prostej ku najdalszemu wrogowi w zasięgu - dłużej i szerzej im dłuższe ładowanie (do PERUN_CHARGE),
##   a po chwili wzdłuż linii biją gromy z nieba (`_perun_storm`)
##   (5. - szybsze ładowanie, 10. - piorun na końcu cięcia);
## - „Błysk Peruna” (`k_flash`): Mgnienie miecza (ProtoWeapon - `blink_skill`) z błękitnymi piorunami wzdłuż skoku;
##   trafieni są porażeni jak przy każdym cięciu (5. - więcej many za zabicie, 10. - co 5. skok wiązka piorunów).
## Kamienie unikalne katany - później. Grafika: assets/weapons/katana.png (tools/katana_art.py), efekty z kreatora
## (assets/effects/katana_*.png, pixellab_src/vfx/ids.json): cienkie cięcie, cięcie dookoła, długie cięcie, trafienie
## piorunem, smuga skoku (przebarwiona smuga Mgnienia); pioruny i okrąg Riposty rysowane w grze.

const KATANA_TEXTURE := preload("res://assets/weapons/katana.png")
## Punkt chwytu na obrazku (przy tsubie - ostrze ma od niego 26 px w grze, jak miecz).
const K_GRIP := Vector2(20.0, 8.0)
## Kolor piorunów katany (błękit) i jaśniejszy rdzeń.
const BOLT := Color(0.55, 0.85, 1.0)
const BOLT_CORE := Color(0.92, 0.98, 1.0)
## Porażenie: czas, część obrażeń trafienia przeskakująca na sąsiada, ilu sąsiadów, zasięg przeskoku.
const SHOCK_TIME := 3.0
const ARC_POWER := 0.25
const ARC_TARGETS := 1
const ARC_RANGE := 60.0
## Błyskawiczne cięcie: czasy (zamach, cięcie, powrót, przerwa) - ok. 1,4 raza szybciej niż miecz; piorun z 5. poziomu
## (co który, zasięg, siła), przeskok z 10. (ilu, siła).
const K_WINDUP := 0.07
const K_SWING := 0.12
const K_RECOVER := 0.06
const K_COOLDOWN := 0.38
const SLASH_BOLT_EVERY := 4
const SLASH_BOLT_RANGE := 100.0
const SLASH_BOLT_POWER := 0.8
const SLASH_ARC_TARGETS := 2
const SLASH_ARC_POWER := 0.5
## Taniec ostrza: liczba cięć (5. poziom - więcej), co ile cięcie, droga naprzód, promień i łuk cięcia, siła pioruna
## między trafionymi, przeskok z 10. (ilu).
const DANCE_CUTS := 4
const DANCE_CUTS_PERK := 6
const DANCE_EVERY := 0.14
const DANCE_DISTANCE := 80.0
## Taniec ostrza (przebudowa 19.11.2026, pomysł autora): każde cięcie to cienka, prosta, świecąca linia długości
## DANCE_LINE (na przemian skośnie o DANCE_SLANT względem marszu - krzyżują się jak „X”), rani lekko (DANCE_THIN siły);
## po ostatnim cięciu chwila ciszy (DANCE_BURST_DELAY) i wszystkie linie naraz wybuchają grubym cięciem z kreatora
## efektów (katana_dance_burst; DANCE_BURST siły, szerzej o DANCE_BURST_WIDTH), potem piorun między trafionymi.
const DANCE_LINE := 70.0
const DANCE_SLANT := deg_to_rad(28.0)
const DANCE_WIDTH := 9.0
const DANCE_THIN := 0.3
const DANCE_BURST := 0.9
const DANCE_BURST_WIDTH := 1.8
const DANCE_BURST_DELAY := 0.3
## Pogrubienie obrazka wybuchu (mniej niż pas trafienia - mocniej rozciągnięte piksele wyglądały jak klocki).
const DANCE_BURST_THICK := 1.3
const DANCE_BURST_FX := preload("res://assets/effects/katana_dance_burst.png")
const DANCE_BURST_FRAMES := 9
const DANCE_BURST_ANCHOR := Vector2(62, 21)
## Długość cięcia w arkuszu efektu i jego pochylenie (w arkuszu lekko wznosi się w prawo).
const DANCE_BURST_LENGTH := 110.0
const DANCE_BURST_TILT := 0.13
const DANCE_BOLT_POWER := 0.5
const DANCE_EXTRA := 3
## Riposta: czas gardy (5. poziom - dłużej), nietykalność kontry, cięcie dookoła (promień), wyskok (odległość, czas,
## wysokość podskoku, opóźnienie), precyzyjny okrąg (promień, spłaszczenie jak efekt cięcia dookoła, czas rysowania
## i gaśnięcia, siła).
const RIPOSTE_WAIT := 3.0
const RIPOSTE_WAIT_LONG := 5.0
const RIPOSTE_SAFE := 0.7
const RIPOSTE_RADIUS := 44.0
const RIPOSTE_LEAP := 48.0
const RIPOSTE_LEAP_TIME := 0.16
const RIPOSTE_HOP := 8.0
const RIPOSTE_LEAP_DELAY := 0.14
const RING_RADIUS := 50.0
const RING_SQUASH := 0.46
const RING_DRAW := 0.1
const RING_FADE := 0.3
const RING_POWER := 1.3
## Sąd Peruna: pełne ładowanie (5. poziom - krócej), samo puszczenie po tylu sekundach trzymania naładowanej,
## długość i szerokość cięcia (od-do), siła (mnożnik od-do), piorun z 10. (promień, siła).
const PERUN_CHARGE := 1.5
const PERUN_CHARGE_FAST := 1.0
const PERUN_HOLD_MAX := 1.0
const PERUN_LENGTH := Vector2(60.0, 200.0)
const PERUN_WIDTH := Vector2(10.0, 28.0)
const PERUN_POWER := Vector2(0.8, 1.5)
const PERUN_BLAST_RADIUS := 36.0
const PERUN_BLAST_POWER := 0.8
## Kulminacja Sądu Peruna (19.11.2026, prośba autora o „szlif efektowności”): chwilę po cięciu wzdłuż całej linii,
## od postaci do końca, uderzają z nieba gromy (efekt `perun_bolt` z kreatora PixelLab) - PERUN_STORM gromów (od-do wg
## naładowania), co PERUN_STORM_GAP s, każdy rani w promieniu PERUN_STORM_RADIUS (x obszar) PERUN_STORM_POWER siły
## i poraża; z ostatnim lekki błysk ekranu i drżenie.
const PERUN_STORM := Vector2(3.0, 6.0)
const PERUN_STORM_DELAY := 0.1
const PERUN_STORM_GAP := 0.06
const PERUN_STORM_RADIUS := 22.0
const PERUN_STORM_POWER := 0.35
const PERUN_BOLT_FX := preload("res://assets/effects/perun_bolt.png")
const PERUN_BOLT_FRAMES := 14
const PERUN_BOLT_ANCHOR := Vector2(42, 118)
## Grom w arkuszu uderza w 5. klatce (20 kl./s).
const PERUN_BOLT_IMPACT := 0.2
## Błysk Peruna: siła wyładowania co 5. skok (10. poziom) i jego promień.
## 10. poziom Błysku: co 5. skok wiązka piorunów - z postaci w najdalszego wroga w FLASH_CHAIN_RANGE, potem
## FLASH_CHAIN_JUMPS przeskoków (zasada `_chain_from`), każdy FLASH_SPIN_POWER siły (19.11.2026 - zamiast wybuchu,
## który zasłaniał postać).
const FLASH_SPIN_POWER := 0.8
const FLASH_CHAIN_RANGE := 110.0
const FLASH_CHAIN_JUMPS := 4
## Kamienie unikalne (pomysły autora 15.11.2026):
## Gromowe Ostrze (cięcie) - łuk pioruna leci do przodu z każdego cięcia: prędkość, zasięg, promień trafienia, siła;
const SPARK_SPEED := 240.0
const SPARK_DISTANCE := 130.0
const SPARK_RADIUS := 16.0
const SPARK_POWER := 0.5
## Wir Ostrza (Taniec) - cięcia w miejscu dookoła postaci: liczba cięć, obrót między nimi;
const SPIN_CUTS := 6
const SPIN_TURN := TAU / 6.0
## Łańcuch Kontr (Riposta) - każdy trafiony kontrą wróg sam tnie dookoła siebie: opóźnienie, promień, siła,
## najwięcej takich kontr na jedną Ripostę (każdy wróg najwyżej raz);
const ECHO_DELAY := 0.12
const ECHO_RADIUS := 30.0
const ECHO_POWER := 0.5
const ECHO_MAX := 12
## Wędrowne Gromy (Sąd Peruna) - z cięcia wyskakują pioruny pełzające po ziemi, każdy do innego wroga: liczba (od-do
## wg naładowania), prędkość, zasięg szukania celów od końca cięcia, najdłuższy czas życia, siła.
const CRAWL_COUNT := Vector2i(2, 6)
const CRAWL_SPEED := 150.0
const CRAWL_RANGE := 220.0
const CRAWL_LIFE := 2.5
const CRAWL_POWER := 0.6
## Efekty (klatki, fps, zaczepienie, wielkość).
const CUT_FX := preload("res://assets/effects/katana_cut.png")
const CUT_FRAMES := 9
const CUT_FPS := 40.0
const CUT_ANCHOR := Vector2(39, 46)
## Kąt środka łuku cięcia na arkuszu (łuk biegnie zgodnie z zegarem od -140 do +48 stopni) i jego promień.
const CUT_MID := deg_to_rad(-46.0)
const CUT_RADIUS := 39.0
const K_HIT_FX := preload("res://assets/effects/katana_hit.png")
const K_HIT_FRAMES := 10
const K_HIT_FPS := 18.0
const K_HIT_ANCHOR := Vector2(28, 22)
const K_HIT_SIZE := 0.45
const K_TRAIL_FX := preload("res://assets/effects/katana_trail.png")
const RIPOSTE_FX := preload("res://assets/effects/katana_riposte.png")
const RIPOSTE_FX_FRAMES := 11
const RIPOSTE_FX_ANCHOR := Vector2(48, 23)
## Promień cięcia dookoła na arkuszu (połowa szerokości).
const RIPOSTE_FX_RADIUS := 46.0
const LINE_FX := preload("res://assets/effects/katana_line.png")
const LINE_FX_FRAMES := 9
## Środek długiego cięcia na arkuszu, jego długość i grubość oraz nachylenie (cięcie lekko wznosi się w prawo).
const LINE_FX_CENTER := Vector2(60, 20)
const LINE_FX_LENGTH := 102.0
const LINE_FX_THICK := 10.0
const LINE_FX_TILT := deg_to_rad(7.85)

## Przeskoki pioruna: ilu sąsiadów i jaka część obrażeń (ustawiane na czas jednego trafienia; 0 - bez przeskoku).
var _arcs := ARC_TARGETS
var _arc_power := ARC_POWER
## Upływ czasu bieżącego cięcia (klatki arkusza grają z własnym fps; ujemny - brak cięcia).
var _cut_t := -1.0
## Taniec ostrza: ile cięć zostało, czas do następnego, kierunek, trafieni.
var _dance_left := 0
var _dance_t := 0.0
var _dance_dir := Vector2.RIGHT
var _dance_hits: Array = []
## Cienkie linie tego Tańca: {a, b (świat), node (Line2D)} - czekają na wybuch.
var _dance_lines: Array = []
## Riposta: czas do wyskoku i do okręgu po kontrze (ujemny - brak).
var _leap_wait := -1.0
var _ring_wait := -1.0
## Sąd Peruna: ładowanie (s) i znacznik linii na ziemi.
var _charge := 0.0
var _charge_line: Line2D
## Kamienie unikalne: lecące łuki pioruna ({"node", "dir", "left", "hits"}), kontry z trafionych ({"at", "t", "src"})
## i wrogowie, którzy już odpalili swoją kontrę w tej Ripoście, pioruny pełzające po ziemi ({"node", "target", "left"}).
var _sparks_fly: Array = []
var _echoes: Array = []
var _echoed: Array = []
var _crawlers: Array = []


func _init() -> void:
	basic = "k_slash"
	main_skill = "k_slash"
	element = Elements.LIGHTNING
	blink_skill = "k_flash"
	flicker_trail = K_TRAIL_FX
	flicker_cut = false
	bolt_color = BOLT


func _ready() -> void:
	super._ready()
	for s in [_sprite] + _ghosts:
		s.texture = KATANA_TEXTURE
		s.offset = -K_GRIP
	_slash.texture = CUT_FX
	_slash.hframes = CUT_FRAMES
	_slash.centered = false
	_slash.offset = -CUT_ANCHOR
	_connect_parry()


## Zmiana broni w trakcie: lecące łuki, pełzające pioruny, linie tańca i ładowania znikają razem z kataną.
func _world_fx() -> Array:
	return super._world_fx() + [_sparks_fly, _crawlers, _dance_lines, [_charge_line]]


func _exit_tree() -> void:
	super._exit_tree()
	_echoes.clear()


func _connect_parry() -> void:
	if hero and not hero.parried.is_connected(_on_parried):
		hero.parried.connect(_on_parried)


func _process(delta: float) -> void:
	super._process(delta)
	match _state:
		"k_windup", "k_swing", "k_recover":
			_process_slash()
		"dance":
			_process_dance(delta)
		"guard":
			_process_guard()
		"riposte":
			_process_riposte(delta)
		"charge":
			_process_charge(delta)
	_process_cut(delta)
	_process_sparks_fly(delta)
	_process_echoes(delta)
	_process_crawlers(delta)


## Błysk pioruna na celu.
func _zap_fx(at: Vector2, size := K_HIT_SIZE) -> void:
	if Fx.crowded(K_HIT_FX):
		return
	Fx.once(get_parent(), K_HIT_FX, K_HIT_FRAMES, K_HIT_FPS, at.round(), K_HIT_ANCHOR, 21, size)


## Każde trafienie kataną (też skoki Błysku Peruna): obrażenia jak każdej broni, porażenie i przeskok pioruna
## na `_arcs` sąsiadów (część `_arc_power` obrażeń).
func _deal(t: ProtoTarget, amount: int, from: Vector2, skill: String) -> void:
	super._deal(t, amount, from, skill)
	if t.alive():
		t.shock(SHOCK_TIME)
	if _arcs > 0 and _arc_power > 0.0:
		for n in _chain_from(t, maxi(1, roundi(amount * _arc_power)), _arcs, ARC_RANGE):
			n.shock(SHOCK_TIME)


## Trafienie umiejętnością z wybraną liczbą przeskoków (`arcs`, `arc_power`).
func _hit(t: ProtoTarget, power: float, from: Vector2, skill: String, arcs := ARC_TARGETS, arc_power := ARC_POWER) -> void:
	_arcs = arcs
	_arc_power = arc_power
	_deal(t, _roll(power), from, skill)
	_arcs = ARC_TARGETS
	_arc_power = ARC_POWER


# --- Cienkie cięcie (zwykły cios, Taniec ostrza, cięcie po skoku) ---

## Ustawia katanę na orbicie jak miecz; efekt cięcia: środek łuku w stronę `_aim`, odbity w drugą stronę cięcia
## (ujemna skala - odbicie wokół punktu zaczepienia).
func _place(a: float) -> void:
	super._place(a)
	_slash.flip_v = false
	_slash.rotation = _aim - CUT_MID * _sign
	var k := absf(_slash.scale.x)
	_slash.scale = Vector2(k, k * _sign)


## Rusza efekt cienkiego cięcia i piorun przelatujący przez nie (`_ArcBolt`).
func _start_cut(area := 1.0) -> void:
	_slash.scale = Vector2.ONE * (HILT_RADIUS + BLADE) * area / CUT_RADIUS
	_slash.rotation = _aim - CUT_MID * _sign
	_slash.scale.y *= _sign
	_slash.flip_v = false
	_slash.position = _orbit_center() - global_position
	_slash.frame = 0
	_slash.visible = true
	_cut_t = 0.0
	var bolt := _ArcBolt.new()
	bolt.from = _aim - ARC / 2.0 * _sign
	bolt.sweep = ARC * _sign
	bolt.radius = (HILT_RADIUS + BLADE - 3.0) * area
	bolt.top_level = true  # nie jedzie z kataną (po skoku dolatuje ona do postaci i ciągnęłaby piorun przed nią)
	add_child(bolt)
	bolt.global_position = _orbit_center()


## Klatki cięcia lecą własnym tempem (CUT_FPS), także po zakończeniu ruchu katany.
func _process_cut(delta: float) -> void:
	if _cut_t < 0.0:
		return
	_cut_t += delta
	var f := int(_cut_t * CUT_FPS)
	if f >= CUT_FRAMES:
		_cut_t = -1.0
		_slash.visible = false
		return
	_slash.visible = true
	_slash.frame = f
	_slash.position = _orbit_center() - global_position


# --- Zwykły cios: błyskawiczne cięcie ---

func _attack(second := false, full := false) -> void:
	_second = second
	if not second:
		_strike_count += 1
	_swing_power = (1.0 if full else gem_power(basic, "multi") / 100.0) if second else 1.0
	var best := _nearest(Skills.DATA[basic].range * _area(basic))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	_sign = -_sign
	_from_pos = position
	_from_sprite = _sprite.position
	_from_rot = _sprite.rotation
	_hit_done = false
	_set_state("k_windup")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))


func _process_slash() -> void:
	match _state:
		"k_windup":
			var k := ease(clampf(_t / K_WINDUP, 0.0, 1.0), -2.0)
			var a := _angle_at(-0.1)
			_place(a)
			position = _from_pos.lerp(position, k)
			_sprite.position = _from_sprite.lerp(_sprite.position, k)
			_sprite.rotation = lerp_angle(_from_rot, a, k)
			if _t >= K_WINDUP:
				_set_state("k_swing")
				_start_cut(_area(basic))
		"k_swing":
			var progress := clampf(_t / K_SWING, 0.0, 1.0)
			_place(_angle_at(ease(progress, 0.5)))
			if not _hit_done and progress >= 0.5:
				_hit_done = true
				_slash_hit()
			if _t >= K_SWING:
				_set_state("k_recover")
		"k_recover":
			_place(_angle_at(1.0))
			if _t >= K_RECOVER:
				if not _second and gem_power(basic, "multi") > 0.0 and not hero.dead:
					_attack(true)  # Mnożenie: drugie cięcie w drugą stronę
				else:
					_second = false
					_swing_power = 1.0
					_set_state("follow")
					_cooldown = K_COOLDOWN


## Cięcie trafia wszystkich w łuku przed postacią; 5. poziom - co SLASH_BOLT_EVERY cięcie piorun w najdalszego wroga w zasięgu,
## 10. - przeskok na SLASH_ARC_TARGETS wrogów (zamiast jednego).
func _slash_hit() -> void:
	var power := _swing_power * _power(basic)
	var arcs := SLASH_ARC_TARGETS if _perk(basic, 1) else ARC_TARGETS
	var arc_power := SLASH_ARC_POWER if _perk(basic, 1) else ARC_POWER
	var hit := _arc_hits(_aim, (HILT_RADIUS + BLADE + 6.0) * _area(basic), ARC, power, basic, arcs, arc_power)
	if _perk(basic, 0) and not _second and _strike_count % SLASH_BOLT_EVERY == 0:
		var near := _farthest(SLASH_BOLT_RANGE * _area(basic))  # najdalszy - widoczna wiązka (19.11.2026)
		if near:
			_bolt(_sprite.global_position, near.center())
			_hit(near, power * SLASH_BOLT_POWER, hero.global_position, basic, 0)
			_zap_fx(near.center(), 0.6)
	if _unique(basic):
		_spawn_spark(_aim, power * SPARK_POWER)
	if not hit.is_empty():
		Input.vibrate_handheld(12)


## Kamień Gromowego Ostrza: łuk pioruna (`_SparkArc`) leci od postaci w kierunku `a` i przebija wrogów.
func _spawn_spark(a: float, power: float) -> void:
	var node := _SparkArc.new()
	node.rotation = a
	node.scale = Vector2.ONE * _area(basic)  # obszar umiejętności: szerszy łuk (19.11.2026)
	get_parent().add_child(node)
	node.global_position = _orbit_center() + Vector2.from_angle(a) * (HILT_RADIUS + BLADE * 0.5)
	_sparks_fly.append({"node": node, "dir": Vector2.from_angle(a), "left": SPARK_DISTANCE * _area(basic),
			"hits": [], "power": power})


func _process_sparks_fly(delta: float) -> void:
	for f in _sparks_fly.duplicate():
		var node: Node2D = f.node
		var step: float = SPARK_SPEED * delta
		node.global_position += f.dir * step
		f.left -= step
		var spark_r := SPARK_RADIUS * _area(basic)
		for t in _near_c(node.global_position, spark_r + 10.0):  # siatka - każda iskra co klatkę
			if not f.hits.has(t) and t.center().distance_to(node.global_position) <= spark_r + t.center_height * 0.4:
				f.hits.append(t)
				_hit(t, f.power, node.global_position, basic, 0)
				_zap_fx(t.center(), 0.35)
		if f.left <= 0.0:
			node.queue_free()
			_sparks_fly.erase(f)


## Trafia wszystkich w łuku `arc` wokół kierunku `aim` do `reach` od środka postaci; zwraca trafionych.
func _arc_hits(aim: float, reach: float, arc: float, power: float, skill: String, arcs := ARC_TARGETS,
		arc_power := ARC_POWER) -> Array:
	var hit: Array = []
	for t in _near_c(_orbit_center(), reach):
		var to := t.center() - _orbit_center()
		if to.length() <= reach and absf(angle_difference(aim, to.angle())) <= arc / 2.0:
			_hit(t, power, hero.global_position, skill, arcs, arc_power)
			_zap_fx(_orbit_center() + to.limit_length(reach - 6.0))
			hit.append(t)
	return hit


# --- Umiejętności ---

func _start(id: String) -> void:
	if id == basic or not id in ["k_dance", "k_riposte", "k_perun"]:
		super._start(id)
		return
	if not can_use(id) or not hero.spend_mana(mana_cost(id)):
		return
	_cd[id] = cooldown_full(id)
	_hit_done = false
	var best := _nearest(Skills.DATA[id].range * _area(id))
	_aim = (best.center() - _orbit_center()).angle() if best else hero.facing.angle()
	match id:
		"k_dance":
			_dance_left = DANCE_CUTS_PERK if _perk(id, 0) else DANCE_CUTS
			_dance_t = 0.0
			_dance_dir = Vector2.from_angle(_aim)
			_dance_hits = []
			_dance_lines = []
			if _unique(id):
				_dance_left = maxi(_dance_left, SPIN_CUTS)  # Kamień Wiru Ostrza: w miejscu, cięcia dookoła
			else:
				hero.leap(hero.global_position + _dance_dir * DANCE_DISTANCE * _area(id), DANCE_EVERY * _dance_left)
			_set_state("dance")
		"k_riposte":
			_connect_parry()
			hero.parry_left = RIPOSTE_WAIT_LONG if _perk(id, 0) else RIPOSTE_WAIT
			_set_state("guard")
		"k_perun":
			_charge = 0.0
			_charge_line = Line2D.new()
			_charge_line.default_color = Color(BOLT, 0.35)
			_charge_line.z_index = -1
			_charge_line.add_point(Vector2.ZERO)
			_charge_line.add_point(Vector2.ZERO)
			get_parent().add_child(_charge_line)
			_set_state("charge")
	hero.play_gesture(_orbit_center() + Vector2.from_angle(_aim) * 20.0 + Vector2(0, ORBIT_HEIGHT))
	skill_used.emit(id)


## Taniec ostrza: co DANCE_EVERY cienka prosta linia cięcia (katana przemyka wzdłuż niej), po ostatniej - chwila ciszy
## i wybuch wszystkich linii naraz (`_dance_burst`), potem piorun między trafionymi.
func _process_dance(delta: float) -> void:
	if _dance_lines.is_empty():
		_place(_angle_at(clampf(_t / DANCE_EVERY, 0.0, 1.0)))
	else:  # katana przemyka wzdłuż ostatniej linii
		var ln: Dictionary = _dance_lines[-1]
		var k := clampf(_t / (DANCE_EVERY * 0.7), 0.0, 1.0)
		position = hero.position
		_sprite.position = (ln.a as Vector2).lerp(ln.b, k) - global_position
		_sprite.rotation = ((ln.b as Vector2) - (ln.a as Vector2)).angle()
	_dance_t -= delta
	if _dance_t > 0.0:
		return
	if _dance_left <= 0:
		var lines := _dance_lines.duplicate()
		_dance_lines = []
		_end_skill()
		get_tree().create_timer(DANCE_BURST_DELAY, false).timeout.connect(_dance_burst.bind(lines))
		return
	_dance_left -= 1
	_dance_t = DANCE_EVERY
	_set_state("dance")
	_sign = -_sign
	_aim = _dance_dir.angle()  # cięcia zawsze w kierunku marszu
	if _unique("k_dance"):
		_dance_dir = _dance_dir.rotated(SPIN_TURN)  # Kamień Wiru Ostrza: kolejne cięcie obrócone dalej dookoła
	_dance_line()
	Input.vibrate_handheld(10)


## Jedna cienka linia Tańca: prosta, skośnie do marszu (na przemian), lekko przed postacią; rani lekko wszystkich
## na niej i zostaje na ziemi do wybuchu.
func _dance_line() -> void:
	var area := _area("k_dance")
	var length := DANCE_LINE * area
	var dir := Vector2.from_angle(_aim + DANCE_SLANT * _sign)
	var c := _orbit_center() + Vector2.from_angle(_aim) * length * 0.15
	var a := c - dir * length * 0.5
	var b := c + dir * length * 0.5
	var glow := Line2D.new()
	glow.width = 3.0
	glow.default_color = Color(BOLT, 0.55)
	glow.z_index = 21
	glow.points = PackedVector2Array([a, b])
	var core := Line2D.new()
	core.width = 1.0
	core.default_color = BOLT_CORE
	core.points = glow.points
	glow.add_child(core)
	get_parent().add_child(glow)
	_dance_lines.append({"a": a, "b": b, "node": glow})
	for t in _line_targets(a, b, DANCE_WIDTH * area):
		_hit(t, _power("k_dance") * DANCE_THIN, hero.global_position, "k_dance", 0)
		if not _dance_hits.has(t):
			_dance_hits.append(t)


## Wrogowie przy odcinku a-b (świat) w odległości `width` (plus połowa ich wysokości).
func _line_targets(a: Vector2, b: Vector2, width: float) -> Array:
	var out: Array = []
	for t in _live_targets():
		var c := t.center()
		if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) <= width + t.center_height * 0.4:
			out.append(t)
	return out


## Wybuch Tańca: wszystkie cienkie linie naraz zamieniają się w grube cięcia (efekt z kreatora), ranią mocno wszystkich
## na nich; potem piorun między trafionymi (`_dance_finish`).
func _dance_burst(lines: Array) -> void:
	for ln in lines:
		var node: Node = ln.node
		if is_instance_valid(node):
			node.queue_free()
	if hero == null or hero.dead:
		return
	var area := _area("k_dance")
	for ln in lines:
		var a: Vector2 = ln.a
		var b: Vector2 = ln.b
		var fx := Fx.once(get_parent(), DANCE_BURST_FX, DANCE_BURST_FRAMES, 16.0, (a + b) / 2.0, DANCE_BURST_ANCHOR, 22)
		fx.rotation = (b - a).angle() + DANCE_BURST_TILT
		fx.scale = Vector2(a.distance_to(b) / DANCE_BURST_LENGTH * 1.15, DANCE_BURST_THICK)
		for t in _line_targets(a, b, DANCE_WIDTH * DANCE_BURST_WIDTH * area):
			_hit(t, _power("k_dance") * DANCE_BURST, hero.global_position, "k_dance", 0)
			if not _dance_hits.has(t):
				_dance_hits.append(t)
	Input.vibrate_handheld(40)
	var cam := hero.get_viewport().get_camera_2d()
	if cam:
		var shake := cam.create_tween()
		for i in 3:
			shake.tween_property(cam, "offset", Vector2(randf_range(-2, 2), randf_range(-2, 2)), 0.03)
		shake.tween_property(cam, "offset", Vector2.ZERO, 0.03)
	_dance_finish()


## Koniec Tańca: błękitny piorun skacze po kolei między trafionymi (zawsze do najdalszego - 19.11.2026), rani każdego;
## 10. poziom - z ostatniego przeskakuje jeszcze na DANCE_EXTRA wrogów obok.
func _dance_finish() -> void:
	var left: Array = _dance_hits.filter(func(t: Variant) -> bool: return is_instance_valid(t) and t.alive())
	if left.is_empty():
		return
	var from := _sprite.global_position
	var last: ProtoTarget = null
	while not left.is_empty():
		var next: ProtoTarget = left[0]
		for t in left:
			if t.center().distance_to(from) > next.center().distance_to(from):
				next = t
		left.erase(next)
		_bolt(from, next.center())
		_hit(next, _power("k_dance") * DANCE_BOLT_POWER, from, "k_dance", 0)
		_zap_fx(next.center())
		from = next.center()
		last = next
	if _perk("k_dance", 1) and last:
		for n in _chain_from(last, maxi(1, _roll(_power("k_dance") * DANCE_BOLT_POWER)), DANCE_EXTRA, ARC_RANGE * 1.5):
			n.shock(SHOCK_TIME)
	Input.vibrate_handheld(20)


## Garda: katana poziomo przed postacią, lekko drży; gdy minie czas gardy bez ciosu - wraca.
func _process_guard() -> void:
	var a := hero.facing.angle()
	position = hero.position + Vector2(0, 1)
	_sprite.position = _orbit_center() - global_position + Vector2.from_angle(a) * 6.0 + Vector2(0, -4)
	_sprite.rotation = a + PI / 2.0 + 0.04 * sin(_clock * 40.0)
	if hero.parry_left <= 0.0:
		_end_skill()


## Cios zablokowany gardą: nietykalność, cięcie dookoła, po chwili wyskok ku najbliższemu wrogowi.
func _on_parried() -> void:
	if _state != "guard":
		return
	hero.protect(RIPOSTE_SAFE)
	var c := _orbit_center()
	var radius := RIPOSTE_RADIUS * _area("k_riposte")
	var fx := Fx.once(get_parent(), RIPOSTE_FX, RIPOSTE_FX_FRAMES, 32.0, (c + Vector2(0, ORBIT_HEIGHT * 0.5)).round(),
			RIPOSTE_FX_ANCHOR, 21, radius / RIPOSTE_FX_RADIUS)
	fx.modulate.a = 0.95
	_echoed = []
	for t in _live_targets():
		var to := t.global_position - hero.global_position
		if Vector2(to.x, to.y / RING_SQUASH).length() <= radius + 6.0 or t.center().distance_to(c) <= radius * 0.6:
			_hit(t, _power("k_riposte"), c, "k_riposte")
			_zap_fx(t.center())
			_echo_from(t)
	_spin = hero.facing.angle()
	_leap_wait = RIPOSTE_LEAP_DELAY
	_ring_wait = -1.0
	_set_state("riposte")
	Input.vibrate_handheld(30)


## Kontra: katana wiruje wokół postaci; wyskok ku najbliższemu wrogowi, po wylądowaniu cienkie cięcie po okręgu.
func _process_riposte(delta: float) -> void:
	_spin += TAU * 3.0 * delta
	_place(_spin)
	if _leap_wait >= 0.0:
		_leap_wait -= delta
		if _leap_wait < 0.0:
			var near := _nearest(RIPOSTE_LEAP * 3.0)
			var dir := (near.global_position - hero.global_position).normalized() if near else hero.facing.normalized()
			var dist := minf(RIPOSTE_LEAP, near.global_position.distance_to(hero.global_position)) if near else RIPOSTE_LEAP
			hero.leap(hero.global_position + dir * dist, RIPOSTE_LEAP_TIME, RIPOSTE_HOP)
			hero.protect(RIPOSTE_SAFE)
			_ring_wait = RIPOSTE_LEAP_TIME
		return
	if _ring_wait >= 0.0:
		_ring_wait -= delta
		if _ring_wait < 0.0:
			_precise_ring()
			_end_skill()


## Cienkie, idealnie równe cięcie po okręgu wokół postaci (`_Ring` rysuje je w RING_DRAW s) - rani wszystkich w okręgu;
## 10. poziom - z każdego trafionego przeskakują pioruny na dwóch wrogów obok.
func _precise_ring() -> void:
	var radius := RING_RADIUS * _area("k_riposte")
	var ring := _Ring.new()
	ring.radius = radius
	ring.start = hero.facing.angle()
	get_parent().add_child(ring)
	ring.global_position = hero.global_position + Vector2(0, -ORBIT_HEIGHT * 0.5)
	var arcs := 2 if _perk("k_riposte", 1) else ARC_TARGETS
	for t in _live_targets():
		var to := t.global_position - hero.global_position
		if Vector2(to.x, to.y / RING_SQUASH).length() <= radius + 6.0:
			_hit(t, _power("k_riposte") * RING_POWER, hero.global_position, "k_riposte", arcs, ARC_POWER * 2.0)
			_zap_fx(t.center())
			_echo_from(t)
	Input.vibrate_handheld(25)


## Kamień Łańcucha Kontr: wróg trafiony kontrą (też kontrą innego wroga) po chwili tnie dookoła siebie - każdy wróg
## najwyżej raz na Ripostę i najwyżej ECHO_MAX kontr, żeby łańcuch nie ciągnął się bez końca.
func _echo_from(t: ProtoTarget) -> void:
	if not _unique("k_riposte") or _echoed.has(t) or _echoed.size() >= ECHO_MAX:
		return
	_echoed.append(t)
	_echoes.append({"src": t, "at": t.global_position, "t": ECHO_DELAY})


func _process_echoes(delta: float) -> void:
	for e in _echoes.duplicate():
		e.t -= delta
		if e.t > 0.0:
			continue
		_echoes.erase(e)
		var at: Vector2 = e.at
		if is_instance_valid(e.src):
			at = (e.src as Node2D).global_position
		var radius := ECHO_RADIUS * _area("k_riposte")
		var fx := Fx.once(get_parent(), RIPOSTE_FX, RIPOSTE_FX_FRAMES, 32.0, (at + Vector2(0, -6)).round(),
				RIPOSTE_FX_ANCHOR, 21, radius / RIPOSTE_FX_RADIUS)
		fx.modulate.a = 0.85
		for t in _near(at, radius + 6.0):  # spłaszczony krąg mieści się w zwykłym
			if t == e.src:
				continue
			var to := t.global_position - at
			if Vector2(to.x, to.y / RING_SQUASH).length() <= radius + 6.0:
				_hit(t, _power("k_riposte") * ECHO_POWER, at, "k_riposte", 0)
				_zap_fx(t.center(), 0.35)
				_echo_from(t)
		Input.vibrate_handheld(8)


## Sąd Peruna: ładowanie, dopóki palec trzyma przycisk (najwyżej do pełna + PERUN_HOLD_MAX); katana uniesiona drży
## coraz mocniej, na ziemi rośnie błękitna linia - długość i szerokość cięcia ku najbliższemu wrogowi.
func _process_charge(delta: float) -> void:
	var full := PERUN_CHARGE_FAST if _perk("k_perun", 0) else PERUN_CHARGE
	_charge += delta
	var k := clampf(_charge / full, 0.0, 1.0)
	var near := _farthest(PERUN_LENGTH.y * _area("k_perun"))  # cięcie w linii przez tłum (19.11.2026)
	if near:
		_aim = (near.global_position - hero.global_position).angle()
	elif hero.velocity.length() > 1.0:
		_aim = hero.facing.angle()
	var dir := Vector2.from_angle(_aim)
	var length := lerpf(PERUN_LENGTH.x, PERUN_LENGTH.y, k) * _area("k_perun")
	_charge_line.width = lerpf(PERUN_WIDTH.x, PERUN_WIDTH.y, k) * _area("k_perun")
	_charge_line.set_point_position(0, _charge_line.to_local(hero.global_position))
	_charge_line.set_point_position(1, _charge_line.to_local(hero.global_position + dir * length))
	_charge_line.default_color = Color(BOLT, 0.15 + 0.15 * k + (0.1 * sin(_clock * 20.0) if k >= 1.0 else 0.0))
	position = hero.position + Vector2(0, -1)
	_sprite.position = _orbit_center() - global_position + Vector2(-dir.x * 6.0, -14.0) \
			+ Vector2(randf_range(-1, 1), randf_range(-1, 1)) * k
	_sprite.rotation = -PI / 2.0 + 0.3 * signf(dir.x)
	if k >= 1.0 and fmod(_clock, 0.12) < delta:
		_bolt(_sprite.global_position + Vector2(0, -6), _sprite.global_position + Vector2(randf_range(-10, 10), -20))
	if not charge_held or _charge >= full + PERUN_HOLD_MAX:
		_perun_cut(k)


## Cięcie Sądu Peruna: wszyscy w pasie od postaci na długość (od-do wg naładowania `k`) obrywają; efekt długiego
## cięcia rozciągnięty do długości i szerokości pasa, katana ląduje na końcu cięcia.
func _perun_cut(k: float) -> void:
	var dir := Vector2.from_angle(_aim)
	var length := lerpf(PERUN_LENGTH.x, PERUN_LENGTH.y, k) * _area("k_perun")
	var width := lerpf(PERUN_WIDTH.x, PERUN_WIDTH.y, k) * _area("k_perun")
	var a := hero.global_position + Vector2(0, -ORBIT_HEIGHT * 0.5)
	var b := a + dir * length
	for t in _live_targets():
		var c := t.center()
		if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) <= width * 0.5 + t.center_height * 0.5:
			_hit(t, _power("k_perun") * lerpf(PERUN_POWER.x, PERUN_POWER.y, k), a, "k_perun")
			_zap_fx(c)
	var fx := Fx.once(get_parent(), LINE_FX, LINE_FX_FRAMES, 24.0, a.lerp(b, 0.5).round(), LINE_FX_CENTER, 21)
	fx.rotation = _aim + LINE_FX_TILT
	fx.scale = Vector2(length / LINE_FX_LENGTH, clampf(width / (LINE_FX_THICK * 1.8), 0.8, 1.5))  # grubsze - kanciaste
	if _perk("k_perun", 1):
		_bolt(b + Vector2(0, -40), b)
		for t in _near_c(b, PERUN_BLAST_RADIUS * _area("k_perun")):
			if t.center().distance_to(b) <= PERUN_BLAST_RADIUS * _area("k_perun"):
				_hit(t, _power("k_perun") * PERUN_BLAST_POWER, b, "k_perun", 0)
		_zap_fx(b, 0.9)
	_bolt(a, b)
	if _unique("k_perun"):
		_spawn_crawlers(a, b, k)
	_perun_storm(a, b, k)
	Input.vibrate_handheld(35)
	_end_skill()
	# katana ląduje na końcu cięcia i stamtąd wraca za ramię
	global_position = b + Vector2(0, ORBIT_HEIGHT * 0.5)
	_sprite.position = Vector2(0, -ORBIT_HEIGHT)
	_sprite.rotation = _aim


## Kulminacja Sądu Peruna: gromy z nieba po kolei wzdłuż linii cięcia od `a` do `b` (więcej przy pełnym ładowaniu).
func _perun_storm(a: Vector2, b: Vector2, k: float) -> void:
	var count := roundi(lerpf(PERUN_STORM.x, PERUN_STORM.y, k))
	var ground := Vector2(0, ORBIT_HEIGHT * 0.5)  # linia cięcia biegnie na wysokości katany - gromy biją w ziemię pod nią
	var side := (b - a).orthogonal().normalized()
	for i in count:
		var at := a.lerp(b, (i + 0.5) / count) + ground + side * randf_range(-5.0, 5.0)
		var delay := PERUN_STORM_DELAY + PERUN_STORM_GAP * i
		get_tree().create_timer(delay, false).timeout.connect(_perun_bolt_fx.bind(at))
		get_tree().create_timer(delay + PERUN_BOLT_IMPACT, false).timeout.connect(_perun_bolt_hit.bind(at, i == count - 1))


func _perun_bolt_fx(at: Vector2) -> void:
	if is_inside_tree():
		Fx.once(get_parent(), PERUN_BOLT_FX, PERUN_BOLT_FRAMES, 20.0, at.round(), PERUN_BOLT_ANCHOR, 22)


## Uderzenie gromu: rani i poraża wokół `at`; ostatni - błysk ekranu i drżenie kamery.
func _perun_bolt_hit(at: Vector2, last: bool) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	for t in _near(at, PERUN_STORM_RADIUS * _area("k_perun") + 10.0):
		if t.global_position.distance_to(at) <= PERUN_STORM_RADIUS * _area("k_perun") + t.center_height * 0.4:
			_hit(t, _power("k_perun") * PERUN_STORM_POWER, at, "k_perun", 0)
			t.shock(SHOCK_TIME)
	Input.vibrate_handheld(30 if last else 12)
	var cam := hero.get_viewport().get_camera_2d()
	if cam:
		var shake := cam.create_tween()
		var power := 3.0 if last else 1.5
		shake.tween_property(cam, "offset", Vector2(randf_range(-power, power), randf_range(-power, power)), 0.03)
		shake.tween_property(cam, "offset", Vector2.ZERO, 0.04)
	if last:
		_screen_flash()


## Krótki, łagodny błysk całego ekranu (biało-błękitny, 0,15 s).
func _screen_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var rect := ColorRect.new()
	rect.color = Color(0.85, 0.95, 1.0, 0.22)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.15)
	tween.tween_callback(layer.queue_free)


## Kamień Wędrownych Gromów: z cięcia (od a do b) wyskakują pioruny pełzające po ziemi, każdy do innego wroga
## w pobliżu końca cięcia - najpierw do tych, których cięcie nie trafiło; im dłuższe ładowanie (`k`), tym więcej.
func _spawn_crawlers(a: Vector2, b: Vector2, k: float) -> void:
	var count := roundi(lerpf(CRAWL_COUNT.x, CRAWL_COUNT.y, k))
	var width := lerpf(PERUN_WIDTH.x, PERUN_WIDTH.y, k) * _area("k_perun")
	var near: Array = []
	for t in _near(b, CRAWL_RANGE * _area("k_perun")):
		var d := t.global_position.distance_to(b)
		if d > CRAWL_RANGE * _area("k_perun"):
			continue
		var c := t.center()
		var in_cut := Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) <= width * 0.5 + t.center_height * 0.5
		near.append([d + (1000.0 if in_cut else 0.0), t])
	near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for i in count:
		var start := a.lerp(b, (i + 1.0) / (count + 1.0)) + Vector2(0, ORBIT_HEIGHT * 0.5)
		var node := _Crawler.new()
		get_parent().add_child(node)
		node.global_position = start
		var target: Variant = near[i][1] if i < near.size() else null
		_crawlers.append({"node": node, "target": target, "left": CRAWL_LIFE,
				"dir": Vector2.from_angle(_aim + randf_range(-1.2, 1.2))})


## Pioruny pełzające po ziemi: suną do swojego wroga (gdy zginie - do najbliższego, za którym nikt nie idzie),
## rażą go i gasną; bez celu pełzną przed siebie i gasną po CRAWL_LIFE.
func _process_crawlers(delta: float) -> void:
	for c in _crawlers.duplicate():
		var node: Node2D = c.node
		c.left -= delta
		if not is_instance_valid(c.target) or not (c.target as ProtoTarget).alive():
			c.target = _free_crawl_target(node.global_position)
		if c.target != null:
			var to: Vector2 = (c.target as ProtoTarget).global_position - node.global_position
			c.dir = to.normalized() if to.length() > 0.5 else c.dir
			if to.length() <= 8.0:
				_hit(c.target, _power("k_perun") * CRAWL_POWER, node.global_position, "k_perun")
				_zap_fx((c.target as ProtoTarget).center(), 0.55)
				c.left = 0.0
		node.global_position += c.dir * CRAWL_SPEED * delta
		if c.left <= 0.0:
			node.queue_free()
			_crawlers.erase(c)


func _free_crawl_target(from: Vector2) -> ProtoTarget:
	var taken: Array = []
	for c in _crawlers:
		taken.append(c.target)
	var best: ProtoTarget = null
	var best_d := CRAWL_RANGE * _area("k_perun")
	for t in _near(from, best_d):
		var d := t.global_position.distance_to(from)
		if d < best_d and not taken.has(t):
			best = t
			best_d = d
	return best


# --- Błysk Peruna (Mgnienie katany) ---

## Skok jak Mgnienie miecza, a wzdłuż drogi skoku dwa błękitne pioruny; po skoku jedno cienkie cięcie katany
## zwrócone za siebie - w przebitego wroga (tuż za plecami), a nie w pustkę przed postacią.
func _flicker_jump(best: ProtoTarget) -> void:
	var from := hero.global_position + Vector2(0, -ORBIT_HEIGHT)
	super._flicker_jump(best)
	var to := hero.global_position + Vector2(0, -ORBIT_HEIGHT)
	_bolt(from, to)
	_bolt(from, to)
	if is_instance_valid(best):
		_aim = (best.center() - _orbit_center()).angle()
	_set_state("k_swing")
	_hit_done = true
	_start_cut()


## 10. poziom Błysku: co 5. skok wiązka piorunów - z postaci w najdalszego wroga w zasięgu, potem przeskoki po
## kolejnych (najdalszych, nietrafionych). Zabicia zwracają manę jak skok.
func _flicker_spin() -> void:
	_blink_spins += 1
	var range_px := FLASH_CHAIN_RANGE * _area(blink_skill)
	var first: ProtoTarget = null
	var best_d := -1.0
	for t in _near_c(_orbit_center(), range_px):
		var d := t.center().distance_to(_orbit_center())
		if d <= range_px and d > best_d:
			first = t
			best_d = d
	if first == null:
		return
	var amount := _roll(_power(blink_skill) * FLASH_SPIN_POWER)
	_bolt(_sprite.global_position, first.center())
	_deal(first, amount, hero.global_position, blink_skill)
	_zap_fx(first.center(), 0.5)
	_blink_kill(first)
	for t in _chain_from(first, amount, FLASH_CHAIN_JUMPS, ARC_RANGE * 1.5 * _area(blink_skill)):
		t.shock(SHOCK_TIME)
		_blink_kill(t)


func _end_skill() -> void:
	_dance_left = 0
	_leap_wait = -1.0
	_ring_wait = -1.0
	if hero:
		hero.parry_left = 0.0
	if _charge_line:
		_charge_line.queue_free()
		_charge_line = null
	var cutting := _cut_t >= 0.0
	super._end_skill()
	_slash.visible = cutting  # cięcie dogrywa się do końca


## Piorun przelatujący przez cięcie: krótki odcinek zygzaka biegnie po łuku cięcia (od `from` o `sweep` radianów,
## promień `radius`) w TRAVEL s i gaśnie. Zygzak losuje się co klatkę - trzaska.
class _ArcBolt extends Node2D:
	const TRAVEL := 0.12
	const FADE := 0.08
	const TAIL := 0.45
	var from := 0.0
	var sweep := PI
	var radius := 36.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		if _t >= TRAVEL + FADE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var head := clampf(_t / TRAVEL, 0.0, 1.0)
		var tail := clampf(head - TAIL, 0.0, 1.0)
		var alpha := 1.0 - clampf((_t - TRAVEL) / FADE, 0.0, 1.0)
		var pts := PackedVector2Array()
		var steps := 8
		for i in steps + 1:
			var k := lerpf(tail, head, float(i) / steps)
			var jitter := 0.0 if i == 0 or i == steps else randf_range(-3.0, 3.0)
			pts.append(Vector2.from_angle(from + sweep * k) * (radius + jitter))
		draw_polyline(pts, Color(ProtoKatana.BOLT, 0.9 * alpha), 3.0)
		draw_polyline(pts, Color(ProtoKatana.BOLT_CORE, alpha), 1.0)


## Łuk pioruna z Kamienia Gromowego Ostrza: trzaskający półksiężyc zwrócony w stronę lotu (oś X węzła).
class _SparkArc extends Node2D:
	func _ready() -> void:
		z_index = 21

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 9:
			var a := lerpf(-1.1, 1.1, i / 8.0)
			pts.append(Vector2.from_angle(a) * (18.0 + (0.0 if i in [0, 8] else randf_range(-3.0, 3.0))) - Vector2(12, 0))
		draw_polyline(pts, Color(ProtoKatana.BOLT, 0.5), 5.0)
		draw_polyline(pts, Color(ProtoKatana.BOLT, 0.95), 3.0)
		draw_polyline(pts, ProtoKatana.BOLT_CORE, 1.0)


## Piorun pełzający po ziemi (Kamień Wędrownych Gromów): trzaskające zygzaki nad świecącą plamą i gasnący ślad
## po ziemi za nim (ostatnie pozycje, w świecie).
class _Crawler extends Node2D:
	const TRAIL := 8
	var _trail: Array[Vector2] = []

	func _ready() -> void:
		z_index = 2

	func _process(_delta: float) -> void:
		_trail.push_front(global_position)
		if _trail.size() > TRAIL:
			_trail.pop_back()
		queue_redraw()

	func _draw() -> void:
		for i in range(1, _trail.size()):
			var a := to_local(_trail[i - 1])
			var b := to_local(_trail[i]) + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			draw_line(a, b, Color(ProtoKatana.BOLT, 0.8 * (1.0 - float(i) / TRAIL)), 2.0)
		draw_circle(Vector2.ZERO, 4.0, Color(ProtoKatana.BOLT, 0.45))
		draw_circle(Vector2.ZERO, 2.0, ProtoKatana.BOLT_CORE)
		for n in 2:
			var p := Vector2.ZERO
			var pts := PackedVector2Array([p])
			for i in 3:
				p += Vector2(randf_range(-5.0, 5.0), randf_range(-8.0, -3.0))
				pts.append(p)
			draw_polyline(pts, Color(ProtoKatana.BOLT, 0.9), 2.0)
			draw_polyline(pts, ProtoKatana.BOLT_CORE, 1.0)


## Precyzyjne cięcie Riposty: cienka linia biegnie po idealnym (spłaszczonym jak ziemia) okręgu w RING_DRAW s,
## potem gaśnie w RING_FADE s.
class _Ring extends Node2D:
	var radius := 50.0
	var start := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 21

	func _process(delta: float) -> void:
		_t += delta
		if _t >= ProtoKatana.RING_DRAW + ProtoKatana.RING_FADE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / ProtoKatana.RING_DRAW, 0.0, 1.0)
		var fade := 1.0 - clampf((_t - ProtoKatana.RING_DRAW) / ProtoKatana.RING_FADE, 0.0, 1.0)
		var pts := PackedVector2Array()
		var steps := 48
		for i in steps + 1:
			var a := start + TAU * k * float(i) / steps
			pts.append(Vector2(cos(a) * radius, sin(a) * radius * ProtoKatana.RING_SQUASH))
		draw_polyline(pts, Color(ProtoKatana.BOLT, 0.8 * fade), 2.0)
		draw_polyline(pts, Color(ProtoKatana.BOLT_CORE, fade), 1.0)

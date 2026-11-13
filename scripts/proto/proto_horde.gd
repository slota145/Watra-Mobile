class_name ProtoHorde
extends Node
## Ciągły strumień Hordy w lochu prototypu: gobliny pojawiają się tuż poza ekranem i idą do Wojciecha.
## Z czasem przychodzą coraz częściej i coraz więcej naraz (`interval`, `max_alive`), aż do sufitu po ~3 minutach.
## Liczy pokonane potwory i czas przetrwania (`kills`, `time`). Z każdego potwora wypada iskra żaru (co `BIG_EVERY`
## potwór - duża), zebrany żar liczy `embers` - do bazy trafia tylko po pokonaniu bossa, ucieczka i śmierć go gaszą.
## Przyzwanie bossa (`call_boss`) zatrzymuje strumień, a gobliny uciekają z piskiem. Siła goblinów rośnie z poziomem
## lochu (`power`). Od 2. poziomu część goblinów to łucznicy (DungeonLevels.archer_share, najwyżej `MAX_ARCHERS`
## naraz), od 3. - osiłki (DungeonLevels.brute_share, najwyżej `MAX_BRUTES`; z osiłka wypada `BRUTE_EMBERS` żaru). Rzadko goblin upuszcza przedmiot z poziomu lochu (`level`, Items.roll_goblin).
## Od 2. poziomu co jakiś czas przychodzi elita (Elites, ProtoElite: cechy, większa, z napisem) - pokonana daje
## pewny przedmiot, iskrę za Elites.EMBERS żaru i sygnał `elite_killed` (arena dolicza doświadczenie).
## Ulepszenia lochów (DungeonUpgrades, ustawia arena): `density` - gęstszy strumień, `loot_mult` - mnożnik szans łupu,
## `reach` - o tyle pikseli dalej iskry i łup lecą do postaci.

signal kills_changed(kills: int)
signal embers_changed(embers: int)
## Goblin upuścił przedmiot (arena liczy podniesione do podsumowania).
signal loot_spawned(loot: ProtoLoot)
## Pokonano elitę (arena dolicza doświadczenie ponad zwykłego goblina).
signal elite_killed(goblin: ProtoGoblin)

## Odstęp między potworami na starcie i po pełnym rozkręceniu (s).
const INTERVAL_START := 1.3
const INTERVAL_END := 0.3
## Najwięcej potworów naraz na starcie i po pełnym rozkręceniu.
const ALIVE_START := 8
const ALIVE_END := 45
## Po tylu sekundach strumień osiąga pełne tempo.
const RAMP_TIME := 180.0
## Pierwszy potwór po tylu sekundach (chwila na rozejrzenie się).
const FIRST_DELAY := 1.5
## Co tyle pokonanych potworów wypada duża iskra (ProtoEmber.BIG żaru) zamiast małej.
const BIG_EVERY := 20
## Przy ucieczce przed bossem piszczy najwyżej tylu goblinów (żeby tłum nie zagłuszył ryku).
const SQUEAKERS := 6
## Najwięcej łuczników naraz (żeby strzały dało się wymijać, a nie były deszczem).
const MAX_ARCHERS := 6
## Najwięcej osiłków naraz i ile żaru daje iskra z osiłka.
const MAX_BRUTES := 3
const BRUTE_EMBERS := 3

var hero: ProtoHero
## Gdzie dodawać potwory (świat z sortowaniem po Y).
var world: Node2D
var bounds := Rect2(-300, -300, 600, 600)
var kills := 0
## Żar zebrany w tym lochu.
var embers := 0
var time := 0.0
## Strumień goblinów działa (przyzwanie bossa go wyłącza).
var running := true
## Czas biegnie (zatrzymuje się po zwycięstwie).
var clock := true
## Mnożnik zdrowia i obrażeń goblinów (DungeonLevels.power poziomu lochu).
var power := 1.0
## Poziom lochu (siła przedmiotów z goblinów).
var level := 1
## Ulepszenia lochów: mnożnik liczby potworów (częściej i więcej naraz), mnożnik szans łupu, dodatkowy zasięg zbierania.
var density := 1.0
var loot_mult := 1.0
var reach := 0.0

var _next := FIRST_DELAY
## Za ile sekund następna elita (ustawia _ready; ujemne - poziom bez elit).
var _elite_next := -1.0
var _alive := 0


func _ready() -> void:
	if Elites.max_traits(level) > 0:
		_elite_next = randf_range(Elites.FIRST.x, Elites.FIRST.y)


func _process(delta: float) -> void:
	if hero == null or hero.dead:
		return
	if clock:
		time += delta
	if not running:
		return
	if _elite_next > 0.0:
		_elite_next -= delta
		if _elite_next <= 0.0:
			_elite_next = randf_range(Elites.EVERY.x, Elites.EVERY.y)
			spawn_elite()
	_next -= delta
	if _next <= 0.0:
		_next = interval()
		if _alive < max_alive():
			spawn()


## Obecny odstęp między potworami.
func interval() -> float:
	return lerpf(INTERVAL_START, INTERVAL_END, _ramp()) / density


func max_alive() -> int:
	return roundi(lerpf(ALIVE_START, ALIVE_END, _ramp()) * density)


func _ramp() -> float:
	return clampf(time / RAMP_TIME, 0.0, 1.0)


## Elita: goblin losowego rodzaju (jak w strumieniu) z cechami z poziomu lochu, tuż poza ekranem.
func spawn_elite() -> ProtoGoblin:
	return spawn_at(spawn_point(), _roll_kind(), Elites.roll_traits(maxi(level, Elites.FROM_LEVEL)))


func spawn() -> ProtoGoblin:
	return spawn_at(spawn_point(), _roll_kind())


## Rodzaj goblina ze strumienia: osiłek, łucznik albo zwykły (udziały z poziomu, limity naraz).
func _roll_kind() -> String:
	var roll := randf()
	var brute := DungeonLevels.brute_share(level)
	var kind := "goblin"
	if roll < brute:
		if count(ProtoGoblinBrute) < MAX_BRUTES:
			kind = "brute"
	elif roll < brute + DungeonLevels.archer_share(level) and archers() < MAX_ARCHERS:
		kind = "archer"
	return kind


## Goblin w danym miejscu (strumień albo okrzyk Wodza; `kind`: goblin, archer - łucznik, brute - osiłek).
## Liczy się do pokonanych i daje iskrę. `elite_traits` - cechy elity (puste - zwykły goblin).
func spawn_at(pos: Vector2, kind := "goblin", elite_traits: Array[String] = []) -> ProtoGoblin:
	var g: ProtoGoblin
	match kind:
		"archer":
			g = ProtoGoblinArcher.new()
		"brute":
			g = ProtoGoblinBrute.new()
		_:
			g = ProtoGoblin.new()
	g.hero = hero
	g.bounds = bounds
	g.power = power
	g.position = pos.clamp(bounds.position, bounds.end)
	g.died.connect(_on_died)
	if not elite_traits.is_empty():
		ProtoElite.promote(g, elite_traits)
	_alive += 1
	world.add_child(g)
	return g


## Ilu łuczników żyje teraz w lochu.
func archers() -> int:
	return count(ProtoGoblinArcher)


## Ile żywych goblinów danego rodzaju (klasy) jest teraz w lochu.
func count(type: Variant) -> int:
	var n := 0
	for c in world.get_children():
		if is_instance_of(c, type) and c.alive():
			n += 1
	return n


## Punkt tuż poza widocznym kadrem (w losowym kierunku od postaci), w granicach areny.
## Gdy postać stoi przy brzegu areny i w danym kierunku nie ma miejsca, losuje inny kierunek.
func spawn_point() -> Vector2:
	var view := hero.get_viewport_rect().size
	var half := view / 2.0 + Vector2(16, 24)
	var p := Vector2.ZERO
	for i in 12:
		var dir := Vector2.from_angle(randf() * TAU)
		# promień do krawędzi kadru w tym kierunku
		var t := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		p = hero.global_position + dir * t
		if bounds.has_point(p):
			return p
	return p.clamp(bounds.position, bounds.end)


## Przyzwanie bossa: strumień staje, żywe gobliny uciekają z piskiem (bez iskier).
func call_boss() -> void:
	running = false
	scatter()


## Wszystkie żywe gobliny uciekają (przy przyzwaniu bossa i po jego śmierci).
func scatter() -> void:
	var squeaks := 0
	for n in world.get_children():
		if n is ProtoGoblin and n.alive():
			n.flee(squeaks < SQUEAKERS)
			squeaks += 1
			_alive -= 1


func _on_died(g: ProtoGoblin) -> void:
	_alive -= 1
	kills += 1
	kills_changed.emit(kills)
	var ember := ProtoEmber.new()
	ember.hero = hero
	ember.value = ProtoEmber.BIG if kills % BIG_EVERY == 0 else (BRUTE_EMBERS if g is ProtoGoblinBrute else 1)
	if g.elite:
		ember.value = Elites.EMBERS
	ember.position = g.position
	ember.magnet = ProtoEmber.MAGNET + reach
	ember.collected.connect(_on_ember)
	world.add_child.call_deferred(ember)
	var item := Items.roll(level, "", "", Items.CHEST_WEIGHTS) if g.elite else Items.roll_goblin(level, loot_mult)
	if not item.is_empty():
		drop_item(item, g.position)
	var gem := Gems.roll_goblin(level, loot_mult)
	if gem != "":
		drop_item({"gem": gem}, g.position)
	if g.elite:
		elite_killed.emit(g)


## Przedmiot na ziemi w danym miejscu.
func drop_item(item: Dictionary, at: Vector2) -> ProtoLoot:
	var loot := ProtoLoot.new()
	loot.hero = hero
	loot.item = item
	loot.magnet = ProtoLoot.MAGNET + reach
	loot.position = at
	loot_spawned.emit(loot)
	world.add_child.call_deferred(loot)
	return loot


func _on_ember(value: int) -> void:
	embers += value
	embers_changed.emit(embers)

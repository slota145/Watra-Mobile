class_name ProtoHorde
extends Node
## Ciągły strumień Hordy w lochu prototypu: gobliny pojawiają się tuż poza ekranem i idą do Wojciecha.
## Przychodzą grupkami z różnych stron kadru (`spawn_group`), z czasem częściej, większymi grupkami i więcej naraz
## (`interval`, `max_alive`), aż do pełnego tempa po RAMP_TIME (1,5 minuty).
## Liczy pokonane potwory i czas przetrwania (`kills`, `time`). Z części potworów wypada iskra żaru (`EMBER_CHANCE`,
## co `BIG_EVERY` potwór - duża; warta więcej w głębi), zebrany żar liczy `embers` - do bazy trafia tylko po pokonaniu bossa, ucieczka i śmierć go gaszą.
## Przyzwanie bossa (`call_boss`) zatrzymuje strumień, a gobliny uciekają z piskiem. Siła goblinów rośnie z poziomem
## lochu (`power`). Od 2. poziomu część goblinów to łucznicy (DungeonLevels.archer_share, najwyżej `MAX_ARCHERS`
## naraz), od 3. - osiłki (DungeonLevels.brute_share, najwyżej `MAX_BRUTES`; z osiłka wypada `BRUTE_EMBERS` żaru). Rzadko goblin upuszcza przedmiot z poziomu lochu (`level`, Items.roll_goblin).
## Od 2. poziomu co jakiś czas przychodzi elita (Elites, ProtoElite: cechy, większa, z napisem) - pokonana daje
## pewny przedmiot, iskrę za Elites.EMBERS żaru i sygnał `elite_killed` (arena dolicza doświadczenie).
## Ulepszenia lochów (DungeonUpgrades, ustawia arena): `density` - gęstszy strumień, `loot_mult` - mnożnik szans łupu,
## `reach` - o tyle pikseli dalej iskry i łup lecą do postaci. Premie przedmiotów (ustawia arena): `pickup_mult` - mnożnik
## zasięgu przyciągania, `ember_mult` - mnożnik żaru z iskier (ułamki zbierają się w `_ember_rest`).
## Rodzaj lochu (`climate`, Dungeons) wybiera potwory na trzech rolach strumienia (`make_monster`): w Leżu goblinów
## goblin / łucznik / osiłek, w Zatopionych podziemiach topielec / żabołak / topielica, w Katakumbach szkielet /
## szkielet łucznik / rycerz-szkielet, na Górskich równinach ptakoczłek wojownik / miotacz / szaman burzy, na Wulkanicznych równinach salamandra /
## ognik / żużlowy golem.

signal kills_changed(kills: int)
signal embers_changed(embers: int)
## Goblin upuścił przedmiot (arena liczy podniesione do podsumowania).
signal loot_spawned(loot: ProtoLoot)
## Pokonano elitę (arena dolicza doświadczenie ponad zwykłego goblina).
signal elite_killed(goblin: ProtoGoblin)
## Każdy pokonany potwór (cele na mapie lochu - Krąg Żertwy liczy daninę).
signal monster_died(goblin: ProtoGoblin)

## Odstęp między grupkami potworów na starcie i po pełnym rozkręceniu (s).
const INTERVAL_START := 1.6
const INTERVAL_END := 0.6
## Wielkość grupki (losowo od-do) na starcie i po pełnym rozkręceniu; grupka wychodzi z jednej strony kadru.
const GROUP_START := Vector2i(4, 6)
const GROUP_END := Vector2i(5, 8)
## Jak szeroko rozsypana jest grupka wzdłuż krawędzi kadru (w obie strony) i w głąb poza kadr (px).
const GROUP_SPREAD := 22.0
## Najwięcej potworów naraz na starcie i po pełnym rozkręceniu.
const ALIVE_START := 35
const ALIVE_END := 85
## Twardy limit potworów naraz (gęstość z ulepszeń i tłum głębokich lochów) - żeby słabszy telefon nie zwolnił
## (pomiar `tools/crowd_bench.gd`: odpychanie w siatce, czas rośnie równo z liczbą potworów).
const ALIVE_CAP := 150
## Po tylu sekundach strumień osiąga pełne tempo.
const RAMP_TIME := 90.0
## Pierwszy potwór po tylu sekundach (chwila na rozejrzenie się).
const FIRST_DELAY := 1.5
## Co tyle pokonanych potworów wypada duża iskra (ProtoEmber.BIG żaru) zamiast małej.
const BIG_EVERY := 40
## Szansa, że zwykły potwór upuści małą iskrę (tłum jest gęsty - decyzja autora 16.11.2026: mniej żaru z potwora;
## duża iskra co BIG_EVERY i z elit zawsze; osiłki jak zwykłe, ale iskra warta BRUTE_EMBERS). Wartość iskry rośnie
## z głębią (DungeonLevels.ember_value).
const EMBER_CHANCE := 0.2
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
## Rodzaj lochu (Dungeons) - jakie potwory idą w strumieniu.
var climate := Dungeons.GOBLINS
## Ulepszenia lochów: mnożnik liczby potworów (częściej i więcej naraz), mnożnik szans łupu, dodatkowy zasięg zbierania.
var density := 1.0
var loot_mult := 1.0
var reach := 0.0
var pickup_mult := 1.0
var ember_mult := 1.0
## Modyfikatory lochu (DungeonMods, ustawia arena): prędkość i obrażenia potworów, żar z iskier, elity częściej,
## przedmioty z wagami skrzyni bossa.
var mod_speed := 1.0
var mod_damage := 1.0
var mod_embers := 1.0
var elite_rate := 1.0
var rare_loot := false
var _ember_rest := 0.0
var _heal_acc := 0.0

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
			_elite_next = randf_range(Elites.EVERY.x, Elites.EVERY.y) / elite_rate
			spawn_elite()
	_next -= delta
	if _next <= 0.0:
		_next = interval()
		spawn_group()


## Obecny odstęp między potworami.
func interval() -> float:
	return lerpf(INTERVAL_START, INTERVAL_END, _ramp()) / density


func max_alive() -> int:
	return mini(roundi(lerpf(ALIVE_START, ALIVE_END, _ramp()) * density), ALIVE_CAP)


func _ramp() -> float:
	return clampf(time / RAMP_TIME, 0.0, 1.0)


## Elita: goblin losowego rodzaju (jak w strumieniu) z cechami z poziomu lochu, tuż poza ekranem.
func spawn_elite() -> ProtoGoblin:
	return spawn_at(spawn_point(), _roll_kind(), Elites.roll_traits(maxi(level, Elites.FROM_LEVEL)))


func spawn() -> ProtoGoblin:
	return spawn_at(spawn_point(), _roll_kind())


## Grupka potworów z jednej strony kadru (wielkość z GROUP_START/GROUP_END, nie ponad limit naraz). Zwraca ile wyszło.
func spawn_group() -> int:
	var size := lerpf(GROUP_START.x, GROUP_END.x, _ramp())
	var top := lerpf(GROUP_START.y, GROUP_END.y, _ramp())
	var count := mini(randi_range(roundi(size), roundi(top)), max_alive() - _alive)
	if count <= 0:
		return 0
	var center := spawn_point()
	var out := (center - hero.global_position).normalized()  # rozsyp wzdłuż krawędzi i na zewnątrz, nigdy w kadr
	for i in count:
		spawn_at(center + out * randf_range(0.0, GROUP_SPREAD) + out.orthogonal() * randf_range(-GROUP_SPREAD, GROUP_SPREAD),
				_roll_kind())
	return count


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
	var g := make_monster(climate, kind)
	g.hero = hero
	g.bounds = bounds
	g.power = power
	g.position = pos.clamp(bounds.position, bounds.end)
	g.died.connect(_on_died)
	if not elite_traits.is_empty():
		ProtoElite.promote(g, elite_traits)
	g.hp_mult = DungeonLevels.hp_mult(level)
	g.resists = Dungeons.resists(climate, level)
	g.speed *= mod_speed
	g.damage_mult *= mod_damage * DungeonLevels.MONSTER_DAMAGE
	_alive += 1
	world.add_child(g)
	return g


## Paczka `count` potworów (rodzaje jak w strumieniu) rozsypana wokół `at` - cele na mapie lochu (Krąg Żertwy,
## Kryształ Watry). Nie ponad ALIVE_CAP naraz. `objective` - cel ataku zamiast postaci (Kryształ). Zwraca potwory.
func spawn_pack(at: Vector2, count: int, objective: ProtoCrystal = null) -> Array[ProtoGoblin]:
	var out: Array[ProtoGoblin] = []
	for i in count:
		if _alive >= ALIVE_CAP:
			break
		var g := spawn_at(at + Vector2.from_angle(randf() * TAU) * randf_range(0.0, GROUP_SPREAD), _roll_kind())
		g.objective = objective
		out.append(g)
	return out


## Potwór lochu `climate` w roli `kind` (goblin - zwykły, archer - strzelający, brute - silny).
static func make_monster(climate_id: String, kind: String) -> ProtoGoblin:
	if climate_id == Dungeons.VOLCANO:
		match kind:
			"archer":
				return ProtoFireWisp.new()
			"brute":
				return ProtoSlagGolem.new()
			_:
				return ProtoSalamander.new()
	if climate_id == Dungeons.PLAINS:
		match kind:
			"archer":
				return ProtoBirdmanThrower.new()
			"brute":
				return ProtoBirdmanShaman.new()
			_:
				return ProtoBirdman.new()
	if climate_id == Dungeons.CATACOMBS:
		match kind:
			"archer":
				return ProtoSkeletonArcher.new()
			"brute":
				return ProtoSkeletonKnight.new()
			_:
				return ProtoSkeleton.new()
	if climate_id == Dungeons.FLOODED:
		match kind:
			"archer":
				return ProtoFrogman.new()
			"brute":
				return ProtoRusalka.new()
			_:
				return ProtoDrowner.new()
	match kind:
		"archer":
			return ProtoGoblinArcher.new()
		"brute":
			return ProtoGoblinBrute.new()
	return ProtoGoblin.new()


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
	_heal_acc += Items.life_on_kill(hero.gear)  # premia przedmiotów: zdrowie za zabicie (ułamki się zbierają)
	var heal := floori(_heal_acc)
	if heal > 0:
		_heal_acc -= heal
		if not hero.dead:
			hero.heal(heal)
	kills += 1
	kills_changed.emit(kills)
	monster_died.emit(g)
	var value := ProtoEmber.BIG if kills % BIG_EVERY == 0 else (BRUTE_EMBERS if g is ProtoGoblinBrute else 1)
	if g.elite:
		value = Elites.EMBERS
	if value == ProtoEmber.BIG or g.elite or randf() < EMBER_CHANCE:
		var ember := ProtoEmber.new()
		ember.hero = hero
		ember.value = value
		ember.position = g.position
		ember.magnet = (ProtoEmber.MAGNET + reach) * pickup_mult
		ember.collected.connect(_on_ember)
		world.add_child.call_deferred(ember)
	var item := Items.roll(level, "", "", Items.CHEST_WEIGHTS) if g.elite \
			else Items.roll_goblin(level, loot_mult, Items.CHEST_WEIGHTS if rare_loot else Items.GOBLIN_WEIGHTS)
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
	loot.magnet = (ProtoLoot.MAGNET + reach) * pickup_mult
	loot.position = at
	loot_spawned.emit(loot)
	world.add_child.call_deferred(loot)
	return loot


## Zebrana iskra z potwora: żar z głębi lochu (DungeonLevels.ember_value) i premii przedmiotów (`ember_mult`).
func _on_ember(value: int) -> void:
	_gain(value * DungeonLevels.ember_value(level) * mod_embers)


## Zebrana iskra ze skrzyni bossa: bez mnożnika głębi (DungeonLevels.chest_embers już rośnie z poziomem).
func on_chest_ember(value: int) -> void:
	_gain(value)


func _gain(value: float) -> void:
	var total := value * ember_mult + _ember_rest
	var whole := floori(total)
	_ember_rest = total - whole
	add_embers(whole)


## Żar do paska wyprawy bez premii (skrót deweloperski).
func add_embers(value: int) -> void:
	embers += value
	embers_changed.emit(embers)

extends Node2D
## Prototyp walki: polana z trawy, Wojciech z lewitującym mieczem i kukły treningowe z Watry.
## Chodzenie: przeciągnij palcem w dowolnym miejscu ekranu (pływająca gałka). Atak: trzymaj przycisk miecza
## w dolnym rogu (wokół niego 4 puste miejsca na umiejętności). „Menu” otwiera okno pauzy: przyciski po lewej
## stronie, gest ręką postaci przy ataku, wyjście do menu głównego.
## Wszystko budowane w kodzie, żeby prototyp łatwo było zmieniać i wyrzucić.
## Dwa tryby: baza (prototype.tscn - kukły i Watra; dotknięcie Watry przenosi do lochu) i loch z Hordą
## (horde.tscn, `horde = true` - ciągły strumień goblinów, pasek zdrowia, licznik pokonanych, po śmierci okno wyniku).
## Żar: iskry z goblinów liczy ProtoHorde i zapełniają pasek żaru (_summon_cost()). Pełny pasek pokazuje
## przycisk „Przyzwij Wodza”: przyzwanie zjada żar z paska, gobliny uciekają, wchodzi Wódz Goblinów (ProtoChief) z własnym
## paskiem zdrowia. Po jego śmierci spada skrzynia z żarem (ProtoChest), a po jej otwarciu cały żar z wyprawy trafia do
## Watry (`Game.bank_embers`), poziom lochu zostaje przebity (`Game.beat_level`) i pokazuje się okno zwycięstwa.
## Ucieczka (okno pauzy) i śmierć gaszą żar z wyprawy. W bazie Watra pokazuje zgromadzony żar, a jej dotknięcie
## otwiera wybór poziomu lochu (LevelPicker). Obok stoi skrzynia (ProtoStash) - przechowalnia przedmiotów z zakładkami
## kupowanymi za złoto (okno StashWindow).
## Rozwój postaci (HeroLevels, stan w Game): gobliny i Wódz dają doświadczenie (śmierć go nie zabiera), cienki pasek
## doświadczenia (złoty) z poziomem postaci u góry (w lochu pod paskami zdrowia i many, liczby na paskach, w bazie obok „Menu”), awans leczy i pokazuje
## efekt na postaci, odblokowuje miejsca na umiejętności. Okno wyniku podsumowuje zdobyte doświadczenie.
## Przedmioty (Items, stan w Game): rzadko z goblinów, kilka ze skrzyni Wodza; cechy założonych (`gear`) idą do postaci
## i miecza od razu, także po zmianie ekwipunku w pauzie (sygnał Game.inventory_changed). Każdy podniesiony
## (albo od razu sprzedany) przedmiot pokazuje krótkie powiadomienie pod paskami u góry (`loot_feed`).
## Umiejętności (Skills, stan w Game): po drugiej stronie Watry stoi kamień run (ProtoStash z grafiką kamienia) -
## otwiera okno umiejętności z kupowaniem (SkillsWindow). Przyciski walki pokazują umiejętności z miejsc
## (Game.skill_slots): duży przycisk - `weapon.main_skill`, małe - stuknięcie używa umiejętności (`weapon.cast`),
## a na przyciskach widać odnowienie i brak many (`_update_skill_buttons`).
## Baza i waluty (ustalone 12.11.2026): kowal (postać z Watry przy kowadle, okno SmithWindow - runy zmieniają premie, Runes)
## i kupiec (wędrowny kupiec przy straganie, okno ShopWindow - towar odnawia się po każdym zwycięstwie nad Wodzem),
## drzewko lochów (DungeonTreeWindow z wyboru poziomu przy Watrze; działanie w lochu - `_apply_upgrades`, `_tick_wander`)
## i pasek skrótów (BaseBar) otwierający okna budynków bez podchodzenia.
## Górny rząd (decyzja autora 13.11.2026): „Menu”, ikonki „Postać” (okno HeroStats) i „Umiejętności” (SkillsWindow;
## kupno tylko w bazie) - w bazie i w lochu; oba okna zatrzymują grę.
## Cele na mapie lochu (DungeonGoals, 16.11.2026): przy progach paska żaru (25/50/75%) na polanie pojawia się cel -
## skrzynia (ProtoChest z `hold_time`), kapliczka (ProtoShrine - dar bóstwa na 60 s doliczany do cech
## z przedmiotów w `_gear`), Skarbnik (ProtoSkarbnik - ruda za trafienia, `Game.add_ore`, runy za złapanie), Krąg Żertwy (ProtoZertwa -
## paczki potworów, danina z zabitych w kręgu, wybór nagrody ZertwaOffer) albo Kryształ Watry (ProtoCrystal - fale
## potworów bijących kryształ, kamienie i odpryski); napis na środku ekranu (`announce`), strzałki przy krawędzi (GoalArrows), nazwa daru
## z pozostałym czasem pod paskami (`gift_label`). Niezrobiony cel zostaje po przyzwaniu Wodza.
## Drabinka odblokowań (Unlocks): znaczek „Nowość!” nad Watrą (`Game.unlocks_seen`), okno UnlocksWindow z wyboru
## poziomu, w oknie zwycięstwa linie „Odblokowano: …”.
## Modyfikatory lochów (DungeonMods, włączane przy wyborze poziomu od 20.): `mods`, działanie w `_apply_upgrades`
## i ProtoHorde (prędkość, obrażenia, żar, elity, rzadki łup), nazwy pod paskami (`mods_label`).
## Boss szczytowy (Pinnacles, 22.11.2026): klucz do Gniazda Żmija (rzadko ze skrzyni bossa od Pinnacles.KEY_FROM) -
## wybór przy Watrze ustawia `Game.pinnacle_key`, a scena lochu staje się Pogorzeliskiem (`pinnacle`: mniejsza arena
## PINNACLE_ARENA z podłogą i wystrojem Wulkanicznych równin, bez Hordy i żaru do zbierania). Od razu wchodzi Żmij
## (ProtoZmij), po nim skrzynia Żmija (Pinnacles.chest_items), a zwycięstwo zużywa klucz (bez przebicia poziomu lochu).

const ARENA := Rect2(-360, -560, 720, 1120)
## Pogorzelisko - arena bossa szczytowego (Żmij Gorynycz, Pinnacles): mniejsza, ok. 1,5 ekranu.
const PINNACLE_ARENA := Rect2(-220, -340, 440, 680)
## Pogorzelisko: tu staje postać, a tu ląduje Żmij.
const PINNACLE_HERO := Vector2(0, 140)
const PINNACLE_BOSS := Vector2(0, -30)
## Pogorzelisko: kamera patrzy tyle pikseli nad postać - wielki smok mieści się nad nią pod paskami u góry.
const PINNACLE_CAMERA := 110.0
const DUMMIES := [Vector2(-100, 170), Vector2(100, 180), Vector2(0, 290)]
const WATRA_POS := Vector2(0, -115)
const STASH_POS := Vector2(-125, -135)
const RUNE_POS := Vector2(125, -135)
## Kowal (z kowadłem po prawej) i kupiec (ze straganem po lewej) po bokach, niżej niż Watra.
const SMITH_POS := Vector2(-120, 40)
const SHOP_POS := Vector2(130, 40)
## Targ (rynek - Market) między kupcem a kukłami; stragan po lewej od handlarza.
const MARKET_POS := Vector2(50, 105)
const MARKET_STALL_OFFSET := Vector2(-30, -2)
const ANVIL_OFFSET := Vector2(24, 4)
const STALL_OFFSET := Vector2(-32, -2)
const BASE_SCENE := "res://scenes/prototype.tscn"
const HORDE_SCENE := "res://scenes/horde.tscn"
## Po śmierci postaci okno wyniku pojawia się po tylu sekundach (widać, jak pada).
const RESULT_DELAY := 1.2
## Wódz pojawia się w takiej odległości od postaci (nad nią - widać go od razu).
const CHIEF_OFFSET := Vector2(0, -110)
## Skrzynia spada po tylu sekundach od śmierci Wodza.
const CHEST_DELAY := 1.4
## Okno zwycięstwa po tylu sekundach od otwarcia skrzyni (iskry zdążą dolecieć).
const VICTORY_DELAY := 2.2
## Ziemia pod wszystkim - także pod ciałami i czerwonymi kołami ostrzeżeń (z_index -1).
const GROUND_Z := -10
## Ciemne tło poza polaną (szersze niż pół najwyższego ekranu - kamera nie ma granic) i miękki cień przy brzegu.
const EDGE_PAD := 700.0
const EDGE_SHADE := 28.0
const EDGE_COLOR := Color(0.11, 0.16, 0.1)
const EMBER_FILL := Color(1.0, 0.55, 0.12)
const EMBER_FULL := Color(1.0, 0.8, 0.3)

## Loch z Hordą zamiast bazy.
@export var horde := false

var hero: ProtoHero
var weapon: ProtoWeapon
var joystick: Joystick
var menu_button: Button
var actions: ActionCluster
var pause_menu: PauseMenu
var watra: ProtoWatra
var horde_spawner: ProtoHorde
var health_bar: ProgressBar
var kills_label: Label
var time_label: Label
var embers_label: Label
var level_label: Label
## Poziom postaci i pasek doświadczenia.
var hero_level_label: Label
var xp_bar: ProgressBar
## Pasek many między zdrowiem a doświadczeniem (na razie pełny - manę zużyją umiejętności).
var mana_bar: ProgressBar
## Liczby na paskach („obecne / największe”).
var health_text: Label
var mana_text: Label
## Część paska many zarezerwowana przez aury (ciemna, z prawej) i ikonki włączonych aur na niej.
var mana_reserved: ColorRect
## Tarcza aury Opieka Mokoszy: jasny pas na dole paska zdrowia.
var shield_bar: ColorRect
var aura_icons: HBoxContainer
## Kręgi i działanie aur pod postacią (Auras).
var auras_node: ProtoAuras
## Efekty założonych talizmanów (Talismans).
var talismans_node: ProtoTalismans
## Unikaty w walce (ProtoUniques) - dziecko postaci.
var uniques_node: ProtoUniques
var xp_text: Label
## Doświadczenie zdobyte w tej wyprawie i poziom postaci na jej starcie (do podsumowania).
var run_xp := 0
var _start_hero_level := 1
## Przedmioty i runy podniesione w tej wyprawie oraz ruda (przedmioty rozbite od razu - filtr łupu, pełna torba
## przy skrzyni - i Skarbnik).
var run_items := 0
var run_runes := 0
var run_ore := 0
## Przedmioty rozbite przez filtr łupu w tej wyprawie i ruda z nich (podsumowanie - RunResult.add_filter_line).
var run_filtered := 0
var run_filtered_ore := 0
## Powiadomienia o łupie (pod paskami u góry, znikają same) i ich największa liczba naraz.
var loot_feed: VBoxContainer
## Powiadomienia o łupie: najwyżej tyle naraz, tyle sekund; małe i przy lewej krawędzi, żeby nie zasłaniały postaci
## (uwaga autora 21.11.2026).
const FEED_MAX := 3
const FEED_TIME := 2.2
## Liczby na pasku żaru („zebrane / potrzebne do przyzwania”).
var ember_text: Label
## Suma cech założonych przedmiotów (Items.totals).
var gear := {}
## Licznik zgonów w trybie deweloperskim (widoczny, gdy nieśmiertelność jest włączona).
var deaths_label: Label
## Tryb deweloperski: klatki na sekundę i potwory naraz (Game.dev_fps).
var fps_label: Label
var ember_bar: ProgressBar
var summon_button: Button
var boss_box: VBoxContainer
var boss_bar: ProgressBar
var result: RunResult
var picker: LevelPicker
## Skrzynia w bazie i jej okno.
var stash: ProtoStash
var stash_window: StashWindow
## Baza: kamień run i okno umiejętności z kupowaniem.
var rune_stone: ProtoStash
var skills_window: SkillsWindow
## Baza: kowal, kupiec, ich okna, okno ulepszeń lochów i pasek skrótów.
var smith: ProtoStash
var merchant: ProtoStash
var smith_window: SmithWindow
var shop_window: ShopWindow
var market: ProtoStash
var market_window: MarketWindow
var tree_window: DungeonTreeWindow
## Drabinka odblokowań (Unlocks) z wyboru poziomu.
var unlocks_window: UnlocksWindow
var mods_window: ModsWindow
var base_bar: BaseBar
## Ikonki w górnym rzędzie i okno „Postać”.
var stats_icon: Button
var skills_icon: Button
var stats_window: HeroStats
## Poziom lochu tej wyprawy (Game.dungeon_level) i jego rodzaj (Dungeons - od RANDOM_FROM losowany przy wejściu).
var level := 1
var climate := Dungeons.GOBLINS
## Walka z bossem szczytowym (Żmij - Pinnacles) zamiast zwykłego lochu; `area` - prostokąt polany (ARENA albo PINNACLE_ARENA).
var pinnacle := false
var area := ARENA
## Wystrój lochu (ozdoby i poświaty, ProtoDecor).
var decor: ProtoDecor
var chief: ProtoChief
## Wiatr Podniebnych wysp: podmuchy i wędrowne trąby (ProtoWind; null w innych lochach).
var wind: ProtoWind
## Wymarzanie i koksowniki Lodowych jaskiń (null - inny loch).
var frost: ProtoFrost
## Żywa puszcza Prastarego Boru - korzenie chwytające postać (null - inny loch).
var grove: ProtoGrove
## Promienie słońca Świątyni Słońca - pasy palącego światła (null - inny loch).
var sunbeams: ProtoSunbeams
var chest: ProtoChest
## Etap wyprawy: horde (zbieranie żaru), boss (walka z Wodzem), loot (skrzynia), won (po zwycięstwie).
var phase := "horde"
## Cele na mapie lochu (DungeonGoals): pojawione cele, wylosowane rodzaje (bez powtórek), strzałki i napis.
var goals: Array[Node2D] = []
var goal_kinds: Array[String] = []
var goal_arrows: GoalArrows
var banner: Label
## Dar kapliczki (klucz DungeonGoals.GIFTS, "" - brak) i ile sekund jeszcze trwa.
var gift := ""
var gift_left := 0.0
var gift_label: Label
## Włączone modyfikatory lochu w tej wyprawie (DungeonMods) i ich nazwy pod paskami.
var mods: Array[String] = []
var mods_label: Label
## Wybór nagrody za Krąg Żertwy (zatrzymuje grę).
var zertwa_offer: ZertwaOffer
var _fill_style: StyleBoxFlat
var _time := 0.0


func _ready() -> void:
	add_to_group(ProtoLoot.ANNOUNCE)
	if horde and Game.pinnacle_key > 0:
		pinnacle = true
		level = Game.pinnacle_key
		climate = Dungeons.VOLCANO
		area = PINNACLE_ARENA
	elif horde:
		level = Game.dungeon_level
		climate = Dungeons.for_level(level)
		mods = DungeonMods.active(level, Game.dungeon_mods)
	else:
		Game.pinnacle_key = 0  # baza: walka ze Żmijem skończona albo przerwana
	_make_ground()
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	if horde:
		decor = ProtoDecor.new()
		decor.name = "Decor"
		add_child(decor)
		decor.scatter(world, climate, area.grow(-24), PINNACLE_HERO if pinnacle else Vector2(0, 40))
	_make_hud()
	hero = ProtoHero.new()
	hero.name = "Hero"
	hero.position = PINNACLE_HERO if pinnacle else Vector2(0, 40)
	hero.joystick = joystick
	hero.bounds = area.grow(-16)
	hero.gesture = Game.gesture
	hero.immortal = Game.dev_immortal
	world.add_child(hero)
	if decor:
		hero.obstacles.append_array(ProtoDecor.obstacles)  # postać obchodzi ozdoby lochu
	_start_hero_level = Game.hero_level
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	# bez granic kamery: postać zawsze na środku ekranu, także przy brzegu polany (prośba autora 13.11.2026 -
	# przy brzegu postać chowała się pod kciukiem); za brzegiem widać ciemny pas (`_make_ground`)
	if pinnacle:
		camera.position.y = -PINNACLE_CAMERA
	hero.add_child(camera)

	weapon = Weapons.make(Game.weapon)
	weapon.name = "Weapon"
	weapon.hero = hero
	weapon.auto_attack = Game.auto_attack
	auras_node = ProtoAuras.new()
	auras_node.name = "Auras"
	auras_node.weapon = weapon
	hero.add_child(auras_node)
	talismans_node = ProtoTalismans.new()
	talismans_node.name = "Talismans"
	hero.add_child(talismans_node)
	uniques_node = ProtoUniques.new()
	uniques_node.name = "Uniques"
	hero.add_child(uniques_node)
	hero.hurt.connect(func(_amount: int) -> void: talismans_node.on_hurt())
	_link_talismans()
	gear = _gear()
	# paski zdrowia i many (w lochu i w bazie - prośba autora 25.11.2026)
	hero.health_changed.connect(func(hp: int, max_hp: int) -> void:
		health_bar.max_value = max_hp
		health_bar.value = hp
		health_text.text = "%d / %d" % [hp, max_hp])
	hero.mana_changed.connect(func(mana: int, max_mana: int) -> void:
		mana_bar.max_value = max_mana
		mana_bar.value = mana
		mana_text.text = "%d / %d" % [mana, hero.mana_cap()]
		_show_reserved())
	hero.shield_changed.connect(func(shield: int, _shield_max: int) -> void:
		shield_bar.visible = shield > 0
		shield_bar.anchor_right = float(shield) / maxf(hero.max_hp, 1.0)
		shield_bar.offset_right = 0.0)
	if horde:
		horde_spawner = ProtoHorde.new()
		horde_spawner.name = "Horde"
		horde_spawner.hero = hero
		horde_spawner.world = world
		horde_spawner.bounds = area.grow(-8)
		horde_spawner.power = DungeonLevels.power(level)
		horde_spawner.level = level
		horde_spawner.climate = climate
		horde_spawner.mod_speed = DungeonMods.mult(mods, "speed")
		horde_spawner.mod_damage = DungeonMods.mult(mods, "damage")
		horde_spawner.mod_embers = DungeonMods.mult(mods, "embers")
		horde_spawner.elite_rate = DungeonMods.mult(mods, "elite_rate")
		horde_spawner.rare_loot = DungeonMods.has_flag(mods, "rare_loot")
		_apply_upgrades()
		horde_spawner.loot_spawned.connect(_track_loot)
		horde_spawner.kills_changed.connect(func(k: int) -> void:
			kills_label.text = tr("Pokonane: %d") % k
			_gain_xp(HeroLevels.goblin_xp(level)))
		horde_spawner.embers_changed.connect(_on_embers)
		horde_spawner.elite_killed.connect(func(_g: ProtoGoblin) -> void:
			_gain_xp(roundi(HeroLevels.goblin_xp(level) * (Elites.XP * DungeonMods.mult(mods, "elite_xp") - 1))))
		add_child(horde_spawner)
		if pinnacle:
			_start_pinnacle.call_deferred()
		if climate == Dungeons.SKY:
			wind = ProtoWind.new()
			wind.name = "Wind"
			wind.hero = hero
			wind.world = world
			wind.bounds = area.grow(-40)
			wind.power = horde_spawner.power * DungeonLevels.MONSTER_DAMAGE * horde_spawner.mod_damage
			add_child(wind)
			wind.spawn_tornadoes()
		if climate == Dungeons.TEMPLE and not pinnacle:
			sunbeams = ProtoSunbeams.new()
			sunbeams.name = "Sunbeams"
			sunbeams.hero = hero
			sunbeams.bounds = area.grow(-20)
			sunbeams.power = horde_spawner.power * DungeonLevels.MONSTER_DAMAGE * horde_spawner.mod_damage
			world.add_child(sunbeams)
		if climate == Dungeons.FOREST and not pinnacle:
			grove = ProtoGrove.new()
			grove.name = "Grove"
			grove.hero = hero
			grove.bounds = area.grow(-20)
			grove.power = horde_spawner.power * DungeonLevels.MONSTER_DAMAGE * horde_spawner.mod_damage
			world.add_child(grove)
		if climate == Dungeons.FROST and not pinnacle:
			frost = ProtoFrost.new()
			frost.name = "Frost"
			frost.hero = hero
			frost.weapon = weapon
			world.add_child(frost)
			frost.place_braziers(world, area.grow(-50), hero.position)
		horde_spawner.monster_died.connect(func(g: ProtoGoblin) -> void:
			auras_node.on_monster_died(g)
			talismans_node.on_kill(g))
		hero.set_level(Game.hero_level, gear)
		hero.died.connect(_on_hero_died)
		hero.death_avoided.connect(func(n: int) -> void: deaths_label.text = tr("Zgony: %d") % n)
	else:
		for p in DUMMIES:
			var dummy := ProtoDummy.new()
			dummy.position = p
			world.add_child(dummy)
			weapon.targets.append(dummy)
		watra = ProtoWatra.new()
		watra.name = "Watra"
		watra.position = WATRA_POS
		watra.embers = Game.embers
		watra.brought = Game.embers_brought
		Game.embers_brought = 0
		watra.entered.connect(open_picker)
		watra.ready.connect(func() -> void: watra.set_news(Unlocks.has_new(Game.unlocks_seen, Game.best_level)))
		world.add_child(watra)
		hero.obstacles.append(Vector3(WATRA_POS.x, WATRA_POS.y, ProtoWatra.RADIUS))
		stash = ProtoStash.new()
		stash.name = "Stash"
		stash.position = STASH_POS
		stash.hero = hero
		stash.opened.connect(open_stash)
		world.add_child(stash)
		hero.obstacles.append(Vector3(STASH_POS.x, STASH_POS.y, ProtoStash.RADIUS))
		rune_stone = ProtoStash.new()
		rune_stone.name = "RuneStone"
		rune_stone.texture = preload("res://assets/watra/rune_stone.png")
		rune_stone.title = "Umiejętności"
		rune_stone.sprite_scale = 0.9
		rune_stone.position = RUNE_POS
		rune_stone.hero = hero
		rune_stone.opened.connect(open_skills)
		world.add_child(rune_stone)
		hero.obstacles.append(Vector3(RUNE_POS.x, RUNE_POS.y, ProtoStash.RADIUS))
		smith = _npc(world, "Smith", "Kowal", preload("res://assets/watra/base/smith.png"), SMITH_POS,
				preload("res://assets/watra/base/anvil.png"), ANVIL_OFFSET)
		smith.opened.connect(open_smith)
		merchant = _npc(world, "Merchant", "Kupiec", preload("res://assets/watra/base/traveling_merchant.png"),
				SHOP_POS, preload("res://assets/watra/base/stall_goods.png"), STALL_OFFSET)
		merchant.opened.connect(open_shop)
		market = _npc(world, "Market", "Targ", preload("res://assets/watra/base/market_trader.png"), MARKET_POS,
				preload("res://assets/watra/base/market_stall.png"), MARKET_STALL_OFFSET)
		market.opened.connect(open_market)
		Game.market_catch_up()  # rynek żyje też, gdy telefon leżał (Market.OFFLINE_MAX)
		Game.embers_changed.connect(func() -> void: watra.set_embers(Game.embers))
	world.add_child(weapon)
	if not horde:
		hero.set_level(Game.hero_level, gear)
	_apply_weapon()
	actions.set_hero_level(Game.hero_level)
	_on_xp(Game.hero_level, Game.hero_xp, Game.xp_needed())
	Game.xp_changed.connect(_on_xp)
	Game.leveled_up.connect(_on_level_up)
	Game.skill_unlocked.connect(func(id: String) -> void: hero.skill_unlocked(Skills.name_of(id)))
	Game.inventory_changed.connect(_on_inventory)
	_apply_auras()
	Game.auras_changed.connect(_apply_auras)
	Game.talismans_changed.connect(_link_talismans)
	actions.attack.pressed.connect(func() -> void: weapon.attack_held = true)
	actions.attack.released.connect(func() -> void: weapon.attack_held = false)
	for i in actions.skills.size():
		actions.skills[i].pressed.connect(_on_skill_pressed.bind(i + 1))
		actions.skills[i].released.connect(_on_skill_released)
	_apply_skills()
	Game.skills_changed.connect(_apply_skills)
	Game.weapon_changed.connect(_swap_weapon)


## Postać z Watry w bazie (arkusz 4x4 klatek, animowany pierwszy rząd) z rekwizytem obok; otwiera okno jak skrzynia.
func _npc(world: Node2D, node_name: String, title: String, sheet: Texture2D, at: Vector2, prop: Texture2D,
		prop_offset: Vector2) -> ProtoStash:
	var npc := ProtoStash.new()
	npc.name = node_name
	npc.texture = sheet
	npc.frames = 4
	npc.rows = 4
	npc.sprite_scale = 1.0
	npc.title = title
	npc.prop = prop
	npc.prop_offset = prop_offset
	npc.position = at
	npc.hero = hero
	world.add_child(npc)
	hero.obstacles.append(Vector3(at.x, at.y, ProtoStash.RADIUS))
	hero.obstacles.append(Vector3(at.x + prop_offset.x, at.y + prop_offset.y, ProtoStash.RADIUS))
	return npc


## Drzewko lochów (Game.tree_value, DungeonTree) do strumienia Hordy: gęstość (razy tłum poziomu lochu), szansa łupu
## i kamieni, zasięg zbierania, elity. Doświadczenie i mistrzostwo dolicza `_gain_xp`, żar - `_apply_weapon`, złoto -
## Game.add_ore, koszt przyzwania - `_summon_cost`, nagrody celów i Wędrowne cele - przy celach.
func _apply_upgrades() -> void:
	horde_spawner.density = (1.0 + Game.tree_value("horde") / 100.0) * DungeonLevels.crowd(Game.dungeon_level) \
			* DungeonMods.mult(mods, "density")
	horde_spawner.loot_mult = (1.0 + Game.tree_value("loot") / 100.0) * _gift_value("loot", 1.0) * DungeonMods.mult(mods, "loot")
	horde_spawner.rune_mult = Game.treasury_mult()  # drzewko lochów: Skarbiec
	horde_spawner.gem_mult = 1.0 + Game.tree_value("gems") / 100.0
	horde_spawner.reach = Game.tree_value("reach")
	horde_spawner.elite_rate = DungeonMods.mult(mods, "elite_rate") * (1.0 + Game.tree_value("elites") / 100.0)


## Żar potrzebny na przyzwanie Wodza (drzewko: Szybkie przyzwanie).
func _summon_cost() -> int:
	return maxi(1, roundi(DungeonLevels.summon_cost(level) * (1.0 - Game.tree_value("summon") / 100.0)))


## Mnożnik nagród z celów na mapie lochu (drzewko: Szczodre cele).
func _goal_reward() -> float:
	return 1.0 + Game.tree_value("rewards") / 100.0


## Trawa z Watry powtarzana na całej polanie, z ciemniejszym brzegiem.
func _make_ground() -> void:
	var edge := ColorRect.new()
	edge.color = EDGE_COLOR
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.position = area.position - Vector2(EDGE_PAD, EDGE_PAD)
	edge.size = area.size + Vector2(EDGE_PAD, EDGE_PAD) * 2.0
	edge.z_index = GROUND_Z
	add_child(edge)
	var grass := Sprite2D.new()
	grass.texture = load(Dungeons.get_data(climate).ground) if horde else preload("res://assets/watra/grass.png")
	grass.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grass.region_enabled = true
	grass.region_rect = Rect2(Vector2.ZERO, area.size)
	grass.centered = false
	grass.position = area.position
	grass.z_index = GROUND_Z
	if horde:
		grass.modulate = Dungeons.get_data(climate).tint  # loch: chłodniej i ciemniej (Horda)
	add_child(grass)
	# miękki cień wzdłuż brzegu polany: trawa ciemnieje w stronę ciemnego tła (cztery paski z gradientem)
	for side in 4:
		var shade := TextureRect.new()
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(EDGE_COLOR, 0.95), Color(EDGE_COLOR, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill_from = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1)][side]
		t.fill_to = [Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(0, 0)][side]
		shade.texture = t
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.z_index = GROUND_Z
		match side:
			0:  # lewy
				shade.position = area.position
				shade.size = Vector2(EDGE_SHADE, area.size.y)
			1:  # prawy
				shade.position = Vector2(area.end.x - EDGE_SHADE, area.position.y)
				shade.size = Vector2(EDGE_SHADE, area.size.y)
			2:  # górny
				shade.position = area.position
				shade.size = Vector2(area.size.x, EDGE_SHADE)
			3:  # dolny
				shade.position = Vector2(area.position.x, area.end.y - EDGE_SHADE)
				shade.size = Vector2(area.size.x, EDGE_SHADE)
		add_child(shade)


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	layer.add_to_group(TouchUi.GROUP)  # stuknięcie w przycisk nie otwiera Watry ani skrzyni pod nim
	add_child(layer)
	joystick = Joystick.new()  # pierwsze dziecko: pod przyciskami
	layer.add_child(joystick)
	var safe := SafeArea.new()
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(safe)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	menu_button = Button.new()
	menu_button.text = tr("Menu")
	menu_button.custom_minimum_size = Vector2(72, 44)
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # równo z ikonkami obok
	menu_button.pressed.connect(_open_menu)
	top.add_child(menu_button)
	stats_icon = _top_icon(top, preload("res://assets/watra/base/character.png"))
	stats_icon.pressed.connect(open_stats)
	skills_icon = _top_icon(top, preload("res://assets/watra/base/skills.png"))
	skills_icon.pressed.connect(open_skills)
	if not horde:  # baza: poziom postaci i doświadczenie obok „Menu”
		var xp_box := VBoxContainer.new()
		xp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		xp_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		xp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(xp_box)
		_make_vitals(xp_box)
		_make_xp_row(xp_box)
	if horde:
		_make_horde_bar(top)
		_make_boss_bar(column)
		_make_summon_button(column)
		loot_feed = VBoxContainer.new()
		loot_feed.add_theme_constant_override("separation", 2)
		loot_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(loot_feed)
		goal_arrows = GoalArrows.new()  # pod oknami (dodane później), nad światem
		goal_arrows.avoid_top = top
		safe.add_child(goal_arrows)
		banner = Label.new()
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		banner.custom_minimum_size = Vector2(300, 0)
		banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
		banner.position.y -= 120.0
		banner.add_theme_font_size_override("font_size", 15)
		banner.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02))
		banner.add_theme_constant_override("outline_size", 5)
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.visible = false
		layer.add_child(banner)
	else:
		var hint := Label.new()
		hint.text = tr("Przeciągnij palcem, żeby iść. Trzymaj przycisk ataku, żeby atakować.")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 0.8))
		hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		hint.add_theme_constant_override("outline_size", 3)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(hint)
		if Game.gold_converted != Vector2i.ZERO:  # stary zapis: złoto zamienione na runy i rudę (raz)
			hint.text = tr("Złota już nie ma - zamieniono je na %d run i %d rudy żelaza (kowal, kupiec).") \
					% [Game.gold_converted.x, Game.gold_converted.y]
			hint.add_theme_font_size_override("font_size", 13)
			hint.add_theme_color_override("font_color", Color(1, 0.82, 0.4))
			Game.gold_converted = Vector2i.ZERO
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(fill)
	# dolny róg (prawy albo lewy - ustawienie): atak i miejsca na umiejętności
	actions = ActionCluster.new()
	actions.left_handed = Game.left_handed
	column.add_child(actions)
	joystick.blocked = [top, actions]
	if not horde:
		base_bar = BaseBar.new()
		base_bar.left_handed = Game.left_handed
		base_bar.chosen.connect(_on_bar)
		safe.add_child(base_bar)
		joystick.blocked.append(base_bar.column)
	if horde:
		joystick.blocked.append(summon_button)
		zertwa_offer = ZertwaOffer.new()
		zertwa_offer.visible = false
		safe.add_child(zertwa_offer)
		result = RunResult.new()
		result.visible = false
		result.retry.connect(_on_retry)
		result.back_to_base.connect(func() -> void: Game.change_scene(BASE_SCENE))
		safe.add_child(result)
	stats_window = HeroStats.new()
	stats_window.visible = false
	safe.add_child(stats_window)
	if horde:  # w bazie okno umiejętności powstaje razem z oknami budynków
		skills_window = SkillsWindow.new()
		skills_window.visible = false
		safe.add_child(skills_window)
	pause_menu = PauseMenu.new()  # ostatnie dziecko: nad całym interfejsem
	pause_menu.visible = false
	if horde:
		pause_menu.base_scene = BASE_SCENE
	else:
		picker = LevelPicker.new()
		picker.visible = false
		picker.enter.connect(enter_dungeon)
		picker.pinnacle.connect(enter_pinnacle)
		picker.upgrades.connect(open_upgrades)
		safe.add_child(picker)
		tree_window = DungeonTreeWindow.new()
		tree_window.visible = false
		tree_window.closed.connect(open_picker)
		unlocks_window = UnlocksWindow.new()
		unlocks_window.visible = false
		unlocks_window.closed.connect(open_picker)
		safe.add_child(unlocks_window)
		picker.ladder.connect(func() -> void: unlocks_window.open())
		mods_window = ModsWindow.new()
		mods_window.visible = false
		mods_window.closed.connect(open_picker)
		safe.add_child(mods_window)
		picker.mods.connect(func() -> void: mods_window.open())
		safe.add_child(tree_window)
		smith_window = SmithWindow.new()
		smith_window.visible = false
		safe.add_child(smith_window)
		shop_window = ShopWindow.new()
		shop_window.visible = false
		safe.add_child(shop_window)
		market_window = MarketWindow.new()
		market_window.visible = false
		safe.add_child(market_window)
		stash_window = StashWindow.new()
		stash_window.visible = false
		safe.add_child(stash_window)
		skills_window = SkillsWindow.new()
		skills_window.visible = false
		safe.add_child(skills_window)
	pause_menu.closed.connect(_apply_settings)
	pause_menu.dev_embers.connect(_on_dev_embers)
	layer.add_child(pause_menu)


## Paski zdrowia (z tarczą Opieki Mokoszy) i many (z rezerwacją aur i ikonami aur) w `box` - w lochu i w bazie.
func _make_vitals(box: VBoxContainer) -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = ProtoHero.MAX_HP
	health_bar.value = ProtoHero.MAX_HP
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(0, 14)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.05, 0.05, 0.85)
	bg.border_color = Color(0.85, 0.62, 0.3)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.16, 0.12)
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(health_bar)
	shield_bar = ColorRect.new()
	shield_bar.color = Color(1.0, 0.86, 0.6, 0.9)
	shield_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_bar.anchor_top = 1.0
	shield_bar.anchor_bottom = 1.0
	shield_bar.offset_top = -3.0
	shield_bar.visible = false
	health_bar.add_child(shield_bar)
	health_text = _bar_text(health_bar, 10)
	mana_bar = ProgressBar.new()
	mana_bar.max_value = HeroLevels.MANA_BASE
	mana_bar.value = HeroLevels.MANA_BASE
	mana_bar.show_percentage = false
	mana_bar.custom_minimum_size = Vector2(0, 11)
	mana_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mana_bg := StyleBoxFlat.new()
	mana_bg.bg_color = Color(0.03, 0.05, 0.12, 0.85)
	mana_bg.border_color = Color(0.3, 0.45, 0.7)
	mana_bg.set_border_width_all(1)
	mana_bg.set_corner_radius_all(2)
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.2, 0.42, 0.9)
	mana_fill.set_corner_radius_all(2)
	mana_bar.add_theme_stylebox_override("background", mana_bg)
	mana_bar.add_theme_stylebox_override("fill", mana_fill)
	box.add_child(mana_bar)
	mana_reserved = ColorRect.new()  # rezerwacja aur: ciemny pas z prawej strony paska many
	mana_reserved.color = Color(0.3, 0.32, 0.42, 0.95)  # szaroniebieski - inny niż pusta część paska
	mana_reserved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mana_reserved.anchor_top = 0.0
	mana_reserved.anchor_bottom = 1.0
	mana_reserved.anchor_right = 1.0
	mana_reserved.visible = false
	mana_bar.add_child(mana_reserved)
	aura_icons = HBoxContainer.new()
	aura_icons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura_icons.alignment = BoxContainer.ALIGNMENT_END
	aura_icons.add_theme_constant_override("separation", 1)
	aura_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mana_reserved.add_child(aura_icons)
	mana_text = _bar_text(mana_bar, 9)


## Pasek u góry w lochu: zdrowie Wojciecha, pod nim pasek żaru (do przyzwania Wodza), a niżej poziom lochu,
## liczba pokonanych potworów, żar z wyprawy i czas.
func _make_horde_bar(top: HBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(box)
	_make_vitals(box)
	_make_xp_row(box)
	ember_bar = ProgressBar.new()
	ember_bar.max_value = _summon_cost()
	ember_bar.value = 0
	ember_bar.show_percentage = false
	ember_bar.custom_minimum_size = Vector2(0, 11)
	ember_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ember_bg := StyleBoxFlat.new()
	ember_bg.bg_color = Color(0.1, 0.05, 0.02, 0.85)
	ember_bg.border_color = Color(0.6, 0.35, 0.12)
	ember_bg.set_border_width_all(1)
	ember_bg.set_corner_radius_all(3)
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = EMBER_FILL
	_fill_style.set_corner_radius_all(3)
	ember_bar.add_theme_stylebox_override("background", ember_bg)
	ember_bar.add_theme_stylebox_override("fill", _fill_style)
	box.add_child(ember_bar)
	ember_text = _bar_text(ember_bar, 9)
	ember_text.text = "0 / %d" % _summon_cost()
	# dwa krótkie wiersze (w jednym nie mieściły się na 360 px i rozpychały cały interfejs): poziom i czas,
	# pokonane i żar
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	level_label = _hud_label(tr("Loch %d") % level)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(level_label)
	time_label = _hud_label("0:00")
	row.add_child(time_label)
	row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	kills_label = _hud_label(tr("Pokonane: %d") % 0)
	kills_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kills_label)
	var icon := TextureRect.new()
	icon.texture = preload("res://assets/watra/ember_icon.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	embers_label = _hud_label("0")
	embers_label.custom_minimum_size = Vector2(34, 0)
	row.add_child(embers_label)
	deaths_label = _hud_label(tr("Zgony: %d") % 0)
	deaths_label.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
	deaths_label.visible = Game.dev_immortal
	box.add_child(deaths_label)
	mods_label = _hud_label(DungeonMods.names(mods))
	mods_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
	mods_label.add_theme_font_size_override("font_size", 11)
	mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mods_label.visible = not mods.is_empty()
	box.add_child(mods_label)
	gift_label = _hud_label("")
	gift_label.visible = false
	box.add_child(gift_label)
	fps_label = _hud_label("")
	fps_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	fps_label.visible = Game.dev_fps
	box.add_child(fps_label)


## Kwadratowa ikonka 44 px w górnym rzędzie (Postać, Umiejętności).
func _top_icon(top: HBoxContainer, texture: Texture2D) -> Button:
	var b := Button.new()
	b.icon = texture
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(44, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.add_theme_constant_override("icon_max_width", 34)
	top.add_child(b)
	return b


## Wiersz postaci: „Poz. N” i cienki pasek doświadczenia.
func _make_xp_row(parent: Container) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	hero_level_label = _hud_label(tr("Poz. %d") % Game.hero_level)
	hero_level_label.add_theme_font_size_override("font_size", 11)
	hero_level_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	row.add_child(hero_level_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 11)
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.02, 0.85)
	bg.border_color = Color(0.55, 0.45, 0.2)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.8, 0.25)
	fill.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("background", bg)
	xp_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(xp_bar)
	xp_text = _bar_text(xp_bar, 9)


## Liczba na środku paska (z obwódką, czytelna na każdym kolorze wypełnienia).
func _bar_text(bar: ProgressBar, font_size: int) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_constant_override("line_spacing", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(l)
	return l


## Doświadczenie dla postaci (pokonany potwór) - liczone też do podsumowania wyprawy - i tyle samo mistrzostwa
## broni w ręku (Weapons).
func _gain_xp(amount: int) -> void:
	if hero.dead:
		return
	amount = roundi(amount * (1.0 + (gear.get("xp_pct", 0.0) + Game.tree_value("xp")) / 100.0))
	run_xp += amount
	Game.add_xp(amount)
	Game.add_mastery(roundi(amount * (1.0 + Game.tree_value("mastery") / 100.0)))


## Zmiana doświadczenia w Game: pasek i numer poziomu (na najwyższym poziomie pasek pełny).
func _on_xp(lvl: int, xp: int, need: int) -> void:
	hero_level_label.text = tr("Poz. %d") % lvl
	xp_bar.max_value = maxi(need, 1)
	xp_bar.value = xp if need > 0 else xp_bar.max_value
	xp_text.text = "%d / %d" % [xp, need] if need > 0 else tr("Najwyższy poziom")
	actions.set_hero_level(lvl, true)
	_apply_weapon()
	if hero.max_hp != HeroStats.max_hp(lvl, gear) and not hero.dead:
		hero.set_level(lvl, gear)  # np. reset postaci w trybie deweloperskim


## Włączone aury (Game.auras_on): kręgi i działanie pod postacią, ikonki na pasku many. Premie przychodzą przez
## Game.gear() (Auras.apply) razem ze zmianą ekwipunku (Game wysyła też inventory_changed).
func _apply_auras() -> void:
	auras_node.on = Game.auras_on.duplicate()
	auras_node.levels = Game.auras.duplicate()
	if aura_icons == null:
		return
	for c in aura_icons.get_children():
		c.queue_free()
	for id in Game.auras_on:
		var icon := TextureRect.new()
		icon.texture = Auras.icon_of(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(9, 9)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aura_icons.add_child(icon)
	_show_reserved()


## Talizmany: broń w ręku (trafienia, umiejętności) i założone talizmany z poziomami (Game.worn_talismans).
func _link_talismans() -> void:
	talismans_node.weapon = weapon
	weapon.talismans = talismans_node
	if not weapon.skill_used.is_connected(talismans_node.on_skill):
		weapon.skill_used.connect(talismans_node.on_skill)
	talismans_node.worn = Game.worn_talismans()


## Ciemny pas rezerwacji aur na pasku many (szerokość - część zarezerwowanej many).
func _show_reserved() -> void:
	if mana_reserved == null or hero == null:
		return
	var reserved := hero.reserved + hero.summon_reserved  # aury i przywołanie łuku
	mana_reserved.visible = reserved > 0
	mana_reserved.anchor_left = 1.0 - float(reserved) / maxf(hero.max_mana, 1.0)
	mana_reserved.offset_left = 0.0
	mana_reserved.offset_right = 0.0
	mana_reserved.offset_top = 0.0
	mana_reserved.offset_bottom = 0.0


## Zmiana ekwipunku (okno „Postać”, łup): nowe cechy postaci i miecza bez leczenia.
func _on_inventory() -> void:
	gear = _gear()
	if not hero.dead:
		hero.apply_gear(Game.hero_level, gear)
	_apply_weapon()


## Miecz: obrażenia z założonej broni, mnożnik z poziomu i premii, szybkość ataku, krytyki, premia przeciw elitom
## i bossom, krótsze odnowienie umiejętności, obszar; w lochu też zasięg zbierania i żar.
func _apply_weapon() -> void:
	weapon.damage = HeroStats.weapon_damage(gear)
	weapon.damage_mult = HeroStats.damage_mult(Game.hero_level, gear)
	weapon.speed_mult = HeroStats.weapon_speed_mult(Game.weapon, gear)  # broń magiczna - szybkość rzucania
	weapon.crit_chance = HeroStats.crit_chance(gear) / 100.0
	weapon.crit_mult = HeroStats.crit_damage(gear) / 100.0
	weapon.elite_mult = 1.0 + gear.get("elite_dmg_pct", 0.0) / 100.0
	weapon.cooldown_cut = gear.get("cdr_pct", 0.0) / 100.0
	weapon.area_bonus = gear.get("area_pct", 0.0)
	weapon.penetration = gear.get("pen_pct", 0.0) / 100.0
	weapon.aura_fire = gear.get("aura_fire", 0.0)
	weapon.elem_mult = 1.0 + gear.get("elem_dmg_pct", 0.0) / 100.0
	weapon.magic_mult = 1.0 + gear.get("magic_dmg_pct", 0.0) / 100.0 if Weapons.is_magic(Game.weapon) else 1.0
	weapon.item_skill_levels = gear.get("skill_bonus", {})
	weapon.item_all_levels = int(gear.get("skill_level_all", 0.0))
	weapon.tag_bonus = {}
	for tag in Skills.TAG_STATS:
		weapon.tag_bonus[tag] = gear.get(Skills.TAG_STATS[tag], 0.0) / 100.0
	weapon.afflicted_bonus = gear.get("afflicted_dmg_pct", 0.0) / 100.0
	weapon.full_hp_bonus = gear.get("full_hp_dmg_pct", 0.0) / 100.0
	weapon.proj_speed_mult = 1.0 + gear.get("proj_speed_pct", 0.0) / 100.0
	weapon.duration_mult = 1.0 + gear.get("duration_pct", 0.0) / 100.0
	weapon.extra_projectiles = int(gear.get("aura_projectiles", 0))  # Rój Strzyboga
	weapon.projectile_mult = 1.0 - gear.get("aura_proj_penalty", 0.0)
	if uniques_node:
		uniques_node.weapon = weapon
		uniques_node.worn = gear.get("uniques", {})
	ProtoTarget.burn_power = 1.0 + gear.get("aura_burn", 0.0)  # Złość Licha
	ProtoTarget.burn_length = 1.0 + (Auras.LICHO_TIME if gear.get("aura_burn", 0.0) > 0.0 else 0.0)
	if horde_spawner:
		horde_spawner.pickup_mult = 1.0 + gear.get("pickup_pct", 0.0) / 100.0
		horde_spawner.ember_mult = 1.0 + (gear.get("ember_pct", 0.0) + Game.tree_value("embers")) / 100.0


## Zmiana broni w bazie (okno umiejętności): nowy węzeł broni w miejscu starego (te same cele - kukły), statystyki
## i umiejętności nowej broni.
func _swap_weapon() -> void:
	if weapon.get_script() == Weapons.script_of(Game.weapon):
		return
	var old := weapon
	weapon = Weapons.make(Game.weapon)
	weapon.name = "Weapon"
	weapon.hero = hero
	weapon.auto_attack = old.auto_attack
	weapon.targets = old.targets
	weapon.position = old.position
	old.get_parent().add_child(weapon)
	old.get_parent().remove_child(old)
	old.queue_free()
	auras_node.weapon = weapon
	_link_talismans()
	_apply_weapon()
	_apply_skills()


## Umiejętności z miejsc na przyciski walki i do miecza (duży przycisk - umiejętność z auto atakiem).
func _apply_skills() -> void:
	actions.show_skills(Game.skill_slots, Skills.basic_of(Game.weapon))
	weapon.main_skill = Game.main_skill()
	weapon.skill_gems = Game.skill_gems
	weapon.skill_levels = Game.skill_levels


## Stuknięcie małego przycisku: umiejętność z tego miejsca; gdy się odnawia albo brakuje many - drgnięcie przycisku.
## Mgnienie (i Błysk Peruna katany) skacze, dopóki palec trzyma przycisk, a umiejętność ładowana (Sąd Peruna) ładuje
## się, dopóki go trzyma (puszczenie - `_on_skill_released`).
func _on_skill_pressed(slot: int) -> void:
	var id: String = Game.skill_slots[slot]
	if id == "" or not Game.slot_open(slot) or hero.dead:
		return
	if not weapon.cast(id):
		actions.button(slot).deny()
	elif id == weapon.blink_skill:
		weapon.flicker_held = true
	elif Skills.is_charged(id):
		weapon.charge_held = true
	elif id == "whirl":
		weapon.whirl_held = true  # Młynek wiruje, dopóki palec trzyma przycisk


## Puszczenie małego przycisku: koniec skoków Mgnienia i wyzwolenie ładowanej umiejętności.
func _on_skill_released() -> void:
	weapon.flicker_held = false
	weapon.charge_held = false
	weapon.whirl_held = false


## Odnowienie i brak many na przyciskach walki (co klatkę; przycisk przerysowuje się tylko przy zmianie).
func _update_skill_buttons() -> void:
	for slot in Skills.SLOTS:
		var id: String = actions.slot_skills[slot] if slot > 0 else weapon.main_skill
		var b := actions.button(slot)
		if id == "" or b.locked_level > 0:
			b.set_state(0.0, 0.0, false)
			continue
		b.set_state(weapon.cooldown_left(id), weapon.cooldown_full(id), not hero.can_pay(weapon.mana_cost(id)))


## Przedmiot na ziemi (z goblina albo skrzyni) - podniesione liczą się do podsumowania wyprawy.
func _track_loot(loot: ProtoLoot) -> void:
	loot.picked.connect(func(item: Dictionary) -> void:
		if item.has("rune"):
			run_runes += 1
		elif not item.has("gem") and not item.has("aura") and not item.has("talisman") and not item.has(Pinnacles.KEY):
			run_items += 1
		notify_loot(item, tr("Podniesiono: %s") % ProtoLoot.name_of(item)))
	loot.scrapped.connect(func(item: Dictionary, got: Dictionary, bag_full: bool) -> void:
		run_ore += int(got.ore)
		run_runes += 1 if got.rune != "" else 0
		if bag_full:
			notify_loot(item, tr("Torba pełna - rozbito: %s (+%d rudy)") % [Items.name_of(item), got.ore])
			return
		run_filtered += 1
		run_filtered_ore += int(got.ore)
		notify_loot(item, tr("Filtr rozbił: %s (+%d rudy)") % [Items.name_of(item), got.ore], true))


## Powiadomienie o łupie pod paskami u góry: ikona i napis w kolorze rzadkości, po chwili gaśnie.
## `dim` - przygaszone (przedmiot rozbity przez filtr łupu, ankieta autora 21.11.2026).
func notify_loot(item: Dictionary, text: String, dim := false) -> void:
	if loot_feed == null:
		return
	while loot_feed.get_child_count() >= FEED_MAX:
		var old := loot_feed.get_child(0)
		loot_feed.remove_child(old)
		old.queue_free()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.04, 0.7)
	style.border_color = ProtoLoot.color_of(item).darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(1)
	style.content_margin_right = 5
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ProtoLoot.icon_of(item)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(14, 14)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := _hud_label(text)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", ProtoLoot.color_of(item))
	row.add_child(label)
	if dim:
		panel.modulate = Color(1, 1, 1, 0.55)
	loot_feed.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(FEED_TIME)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)


## Awans: efekt na postaci (pełne zdrowie, napis, dźwięk), miga numer poziomu.
func _on_level_up(lvl: int) -> void:
	hero.level_up(lvl)
	hero_level_label.modulate = Color(2.0, 1.7, 0.8)
	hero_level_label.create_tween().tween_property(hero_level_label, "modulate", Color.WHITE, 0.8)


## Tryb deweloperski: żar na skróty - w lochu do paska wyprawy (szybkie przyzwanie Wodza), w bazie do Watry.
func _on_dev_embers(amount: int) -> void:
	if horde_spawner:
		horde_spawner.add_embers(amount)
	else:
		Game.embers += amount
		Game.save_game()
		Game.embers_changed.emit()


## Pasek zdrowia Wodza pod górnym rzędem (ukryty do przyzwania).
func _make_boss_bar(column: VBoxContainer) -> void:
	boss_box = VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 0)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.visible = false
	column.add_child(boss_box)
	var name_label := _hud_label(Lang.t(Pinnacles.BOSS_NAME) if pinnacle else Dungeons.boss_of(climate))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.45))
	boss_box.add_child(name_label)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size = Vector2(0, 10)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.03, 0.03, 0.9)
	bg.border_color = Color(0.55, 0.15, 0.1)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.62, 0.1, 0.08)
	fill.set_corner_radius_all(3)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar.add_theme_stylebox_override("fill", fill)
	boss_box.add_child(boss_bar)


## Przycisk „Przyzwij Wodza” u góry pod paskiem żaru (prośba autora: daleko od kciuka, żeby nie przyzwać
## Wodza przypadkiem w ferworze walki), widoczny przy pełnym pasku żaru.
func _make_summon_button(column: VBoxContainer) -> void:
	summon_button = Button.new()
	summon_button.text = Lang.t(Dungeons.get_data(climate).summon)
	summon_button.icon = preload("res://assets/watra/ember_icon.png")
	summon_button.add_theme_constant_override("icon_max_width", 22)
	summon_button.custom_minimum_size = Vector2(200, 52)
	summon_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summon_button.add_theme_font_size_override("font_size", 17)
	summon_button.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	summon_button.visible = false
	summon_button.pressed.connect(summon_chief)
	column.add_child(summon_button)


func _hud_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_time += delta
	_update_skill_buttons()
	if horde_spawner and time_label:
		var s := int(horde_spawner.time)
		time_label.text = "%d:%02d" % [s / 60, s % 60]
	if fps_label and fps_label.visible:
		fps_label.text = tr("%d kl./s, potwory: %d") % [Engine.get_frames_per_second(), horde_spawner._alive if horde_spawner else 0]
	if gift != "":
		_tick_gift(delta)
	_tick_wander(delta)
	if summon_button and summon_button.visible:  # pełny pasek pulsuje
		var k := 0.5 + 0.5 * sin(_time * 6.0)
		_fill_style.bg_color = EMBER_FILL.lerp(EMBER_FULL, k)
		summon_button.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.1, 0.85), k)


## Wędrowne cele (drzewko, prośba autora 20.11.2026): w trakcie Hordy co DungeonTree.WANDER_EVERY s szansa na cel
## spoza paska żaru (najwyżej WANDER_MAX naraz, nie wliczają się do progów paska).
var _wander_goals := 0
var _wander_acc := 0.0
var _wander_live: Array = []


func _tick_wander(delta: float) -> void:
	var chance := Game.tree_value("wander") / 100.0
	if chance <= 0.0 or phase != "horde" or hero == null or hero.dead or horde_spawner == null:
		return
	_wander_acc += delta
	if _wander_acc < DungeonTree.WANDER_EVERY:
		return
	_wander_acc = 0.0
	_wander_live = _wander_live.filter(func(g) -> bool: return is_instance_valid(g))
	if _wander_live.size() >= DungeonTree.WANDER_MAX or randf() >= chance:
		return
	_wander_goals += 1
	_wander_live.append(spawn_goal(DungeonGoals.roll(level, goal_kinds)))


## Zmiana żaru z wyprawy: licznik, pasek (do kosztu przyzwania) i przycisk przyzwania przy pełnym pasku.
func _on_embers(e: int) -> void:
	embers_label.text = str(e)
	if phase != "horde":
		return
	ember_bar.value = mini(e, _summon_cost())
	while goals.size() - _wander_goals < DungeonGoals.thresholds_passed(e, _summon_cost()) and not hero.dead:
		spawn_goal(DungeonGoals.roll(level, goal_kinds))
	ember_text.text = "%d / %d" % [e, _summon_cost()]
	var full := e >= _summon_cost()
	summon_button.visible = full and not hero.dead
	if not full:
		_fill_style.bg_color = EMBER_FILL


## Cel na mapie lochu w wolnym miejscu z dala od postaci (DungeonGoals.spot): skrzynia, kapliczka, Skarbnik,
## Krąg Żertwy albo Kryształ Watry.
## Pojawienie się ogłasza napis i dźwięk, a strzałka przy krawędzi ekranu wskazuje drogę.
func spawn_goal(kind: String) -> Node2D:
	var others: Array = goals.filter(func(g: Node2D) -> bool: return is_instance_valid(g)).map(
			func(g: Node2D) -> Vector2: return g.position)
	var at := DungeonGoals.spot(area, hero.position, others)
	var goal: Node2D
	match kind:
		"skarbnik":
			var spirit := ProtoSkarbnik.new()
			spirit.hero = hero
			spirit.level = level
			spirit.bounds = area.grow(-24)
			spirit.ore.connect(func(amount: int) -> void:
				run_ore += Game.add_ore(maxi(1, roundi(amount * _goal_reward()))))
			spirit.caught.connect(func(where: Vector2) -> void:
				announce(tr("Skarbnik złapany!"), spirit.goal_color)
				for i in ProtoSkarbnik.CATCH_RUNES:
					horde_spawner.drop_item({"rune": Runes.roll(level)}, where)
				horde_spawner.drop_item({"gem": Gems.roll(level)}, where))
			spirit.escaped.connect(func() -> void: announce(tr("Skarbnik zapadł się pod ziemię"), Color(0.8, 0.75, 0.6)))
			goal = spirit
			announce(tr("Na polanie zjawił się Skarbnik - złap go!"), spirit.goal_color)
		"zertwa":
			var stump := ProtoZertwa.new()
			stump.hero = hero
			horde_spawner.monster_died.connect(stump.offer_kill)
			stump.pack.connect(func(where: Vector2, count: int) -> void: horde_spawner.spawn_pack(where, count))
			stump.completed.connect(_on_zertwa_completed)
			stump.failed.connect(func() -> void: announce(tr("Krąg Żertwy zgasł"), Color(0.8, 0.6, 0.55)))
			goal = stump
			announce(tr("Na polanie stoi Krąg Żertwy - złóż daninę!"), stump.goal_color)
		"raid":
			var camp := ProtoRaid.new()
			camp.hero = hero
			camp.wave.connect(func(where: Vector2, count: int) -> void: horde_spawner.spawn_pack(where, count))
			camp.looted.connect(_on_raid_looted)
			goal = camp
			announce(tr("Na polanie rozbiła się Horda - ograb jej obóz!"), camp.goal_color)
		"crystal":
			var crystal := ProtoCrystal.new()
			crystal.hero = hero
			crystal.power = DungeonLevels.power(level)
			crystal.wave.connect(func(where: Vector2, count: int) -> void: horde_spawner.spawn_pack(where, count, crystal))
			crystal.defended.connect(_on_crystal_defended)
			crystal.destroyed.connect(func(_where: Vector2) -> void:
				Game.add_shards(DungeonGoals.CRYSTAL_SHARDS_LOST)
				announce(tr("Kryształ rozbity - zostało %d odprysków") % DungeonGoals.CRYSTAL_SHARDS_LOST, Color(0.8, 0.65, 0.55)))
			goal = crystal
			announce(tr("Na polanie lśni Kryształ Watry - podejdź i obroń go!"), crystal.goal_color)
		"shrine":
			var shrine := ProtoShrine.new()
			shrine.hero = hero
			shrine.gift = DungeonGoals.roll_gift()
			shrine.prayed.connect(grant_gift)
			goal = shrine
			announce(tr("Na polanie rozbłysła kapliczka!"), DungeonGoals.GIFTS[shrine.gift]["color"])
		_:
			var box := ProtoChest.new()
			box.hero = hero
			box.hold_time = DungeonGoals.CHEST_HOLD
			box.embers = roundi(DungeonGoals.chest_embers(level) * _goal_reward())
			box.items = DungeonGoals.chest_items(level, horde_spawner.loot_mult * horde_spawner.gem_mult,
					horde_spawner.rune_mult)
			box.loot_spawned.connect(_track_loot)
			box.ember_spawned.connect(func(e: ProtoEmber) -> void: e.collected.connect(horde_spawner.on_chest_ember))
			goal = box
			announce(tr("Na polanie pojawiła się skrzynia!"), box.goal_color)
	goal.name = "Goal%d" % goals.size()
	goal.position = at
	goals.append(goal)
	goal_kinds.append(kind)
	$World.add_child(goal)
	var ping := AudioStreamPlayer.new()
	ping.stream = preload("res://assets/watra/shrine_pray.ogg")
	ping.volume_db = -10.0
	ping.pitch_scale = 1.3
	ping.finished.connect(ping.queue_free)
	add_child(ping)
	ping.play()
	return goal


## Napad Hordy odparty: ruda od razu do zapasu (nagrody celów z drzewka, Skarbiec) i z szansą runa na ziemi.
func _on_raid_looted(at: Vector2) -> void:
	var got := Game.add_ore(roundi(randi_range(DungeonGoals.RAID_ORE.x, DungeonGoals.RAID_ORE.y) * _goal_reward()))
	run_ore += got
	if randf() < DungeonGoals.RAID_RUNE * horde_spawner.rune_mult:
		_drop_reward({"rune": Runes.roll(level)}, at, 0.3)
	announce(tr("Napad odparty! +%d rudy żelaza") % got, Color(0.95, 0.6, 0.4))


## Krąg Żertwy dopełniony: gra staje, wybór nagrody 1 z 3.
func _on_zertwa_completed(at: Vector2) -> void:
	if hero.dead:
		return
	joystick.release()
	actions.release_all()
	weapon.attack_held = false
	get_tree().paused = true
	zertwa_offer.chosen.connect(_on_zertwa_chosen.bind(at), CONNECT_ONE_SHOT)
	zertwa_offer.open(DungeonGoals.zertwa_offer(level))


## Wybrana nagroda Żertwy: przedmiot lub kamień wyskakuje z pnia i leci do postaci, żar od razu do paska.
func _on_zertwa_chosen(reward: Dictionary, at: Vector2) -> void:
	get_tree().paused = false
	if reward.has("embers"):
		horde_spawner.on_chest_ember(int(reward["embers"]))
		hero.float_text(tr("+%d żaru") % int(reward["embers"]), -60.0, Color(1.0, 0.7, 0.3), 14)
	else:
		_drop_reward(reward["item"], at, 0.2)


## Nagroda celu na ziemi: odskakuje od `at` i po chwili sama leci do postaci (jak łup ze skrzyni).
func _drop_reward(item: Dictionary, at: Vector2, delay: float) -> void:
	var loot := horde_spawner.drop_item(item, at + Vector2(0, -4))
	loot.spread = 30.0
	loot.magnet = 1000.0
	loot.delay = delay


## Kryształ obroniony: kamienie i runy (wg zdrowia, które zostało) oraz odpryski od razu do sakwy.
func _on_crystal_defended(at: Vector2, health: float) -> void:
	var shards := roundi(DungeonGoals.crystal_shards(health) * _goal_reward())
	Game.add_shards(shards)
	for i in DungeonGoals.crystal_gems(health):
		_drop_reward({"gem": Gems.roll(level)}, at, 0.3 + 0.2 * i)
	for i in DungeonGoals.crystal_runes(health):
		_drop_reward({"rune": Runes.roll(level)}, at, 0.4 + 0.2 * i)
	announce(tr("Kryształ obroniony! +%d odprysków") % shards, Color(1.0, 0.7, 0.35))


## Napis na środku ekranu (nad postacią) na chwilę: pojawienie się celu, dar kapliczki.
## Pokaz łupu: legenda albo unikat wypadł (ProtoLoot.ANNOUNCE) - napis na środku ekranu.
func announce_loot(item: Dictionary) -> void:
	if item.has(Pinnacles.KEY):
		announce(tr("Klucz do Gniazda Żmija!"), Pinnacles.KEY_COLOR)
		return
	var text := tr("Unikat: %s!") if Items.is_unique(item) else tr("Legendarny: %s!")
	announce(text % Items.name_of(item), Items.color_of(item))


func announce(text: String, color: Color) -> void:
	if banner == null:
		return
	banner.text = text
	banner.add_theme_color_override("font_color", color.lightened(0.3))
	banner.visible = true
	banner.modulate = Color(1, 1, 1, 0)
	var tween := banner.create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.2)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: banner.visible = false)


## Dar kapliczki: DungeonGoals.GIFT_TIME s (nowy zastępuje poprzedni), cechy od razu w postaci i broni.
func grant_gift(id: String) -> void:
	gift = id
	gift_left = DungeonGoals.GIFT_TIME + Game.tree_value("gift")
	var data: Dictionary = DungeonGoals.GIFTS[id]
	announce("%s\n%s" % [tr(data["name"]), tr(data["description"])], data["color"])
	hero.float_text(tr(data["name"]), -60.0, data["color"].lightened(0.3), 14)
	gift_label.add_theme_color_override("font_color", data["color"].lightened(0.3))
	gift_label.visible = true
	_refresh_gift()


func _tick_gift(delta: float) -> void:
	gift_left -= delta
	if gift_left <= 0.0:
		gift = ""
		gift_label.visible = false
		_refresh_gift()
		return
	gift_label.text = tr("%s: %d s") % [tr(DungeonGoals.GIFTS[gift]["name"]), ceili(gift_left)]


func _refresh_gift() -> void:
	if gift != "":
		gift_label.text = tr("%s: %d s") % [tr(DungeonGoals.GIFTS[gift]["name"]), ceili(gift_left)]
	_on_inventory()
	if horde_spawner:
		_apply_upgrades()


## Wartość daru kapliczki (`key` w DungeonGoals.GIFTS) albo `default`, gdy nie ma daru.
func _gift_value(key: String, default: float) -> float:
	return float(DungeonGoals.GIFTS[gift].get(key, default)) if gift != "" else default


## Cechy z przedmiotów (Game.gear) razem z darem kapliczki.
func _gear() -> Dictionary:
	var g := Game.gear()
	if gift == "":
		return g
	g = g.duplicate()
	var data: Dictionary = DungeonGoals.GIFTS[gift]
	for stat: String in data["stats"]:
		g[stat] = g.get(stat, 0.0) + float(data["stats"][stat])
	if data.has("regen_pct"):
		var max_hp := HeroStats.max_hp(Game.hero_level, g)
		g["regen"] = g.get("regen", 0.0) + max_hp * float(data["regen_pct"]) / 100.0
	return g


## Przyzwanie Wodza: zjada żar z paska (nadwyżka zostaje), gobliny uciekają, Wódz wchodzi nad postacią.
func summon_chief() -> void:
	if phase != "horde" or hero.dead or horde_spawner.embers < _summon_cost():
		return
	phase = "boss"
	horde_spawner.embers -= _summon_cost()
	embers_label.text = str(horde_spawner.embers)
	summon_button.visible = false
	ember_bar.visible = false
	horde_spawner.call_boss()
	match climate:
		Dungeons.FLOODED:
			chief = ProtoWodnik.new()
		Dungeons.CATACOMBS:
			chief = ProtoNecromancer.new()
		Dungeons.PLAINS:
			chief = ProtoStormEagle.new()
		Dungeons.VOLCANO:
			chief = ProtoFireElemental.new()
		Dungeons.SKY:
			chief = ProtoGryf.new()
		Dungeons.FROST:
			chief = ProtoDziadMroz.new()
		Dungeons.FOREST:
			chief = ProtoLeszy.new()
		Dungeons.TEMPLE:
			chief = ProtoSwarozyc.new()
		_:
			chief = ProtoChief.new()
	var spot := hero.position + CHIEF_OFFSET
	if not area.grow(-40).has_point(spot):
		spot = hero.position - CHIEF_OFFSET
	_add_boss(spot)


## Pogorzelisko: bez Hordy i paska żaru - od razu wchodzi Żmij Gorynycz.
func _start_pinnacle() -> void:
	phase = "boss"
	horde_spawner.call_boss()
	ember_bar.visible = false
	summon_button.visible = false
	var zmij := ProtoZmij.new()
	zmij.phase_changed.connect(func(_p: int) -> void:
		announce(tr("Głowa Żmija zgasła! Smok wpada w gniew."), Pinnacles.KEY_COLOR))
	chief = zmij
	_add_boss(PINNACLE_BOSS)
	chief.power *= Pinnacles.POWER


## Boss na polanie (w miejscu `spot`, przyciętym do brzegu): siła z poziomu lochu, pasek zdrowia, przywołani pomocnicy.
func _add_boss(spot: Vector2) -> void:
	chief.name = "Chief"
	chief.hero = hero
	chief.bounds = area.grow(-24)
	chief.power = DungeonLevels.power(level) * DungeonLevels.BOSS_POWER
	chief.hp_mult = DungeonLevels.hp_mult(level)
	chief.resists = Dungeons.resists(climate, level)
	chief.position = spot.clamp(area.position + Vector2(40, 40), area.end - Vector2(40, 40))
	chief.health_changed.connect(func(hp: int, max_hp: int) -> void:
		boss_bar.max_value = max_hp
		boss_bar.value = hp)
	chief.summon_minions.connect(func(points: Array) -> void:
		for p in points:
			horde_spawner.spawn_at(p, chief.minion_kind))
	chief.died.connect(_on_chief_died)
	$World.add_child(chief)
	boss_bar.max_value = chief.max_hp
	boss_bar.value = chief.hp
	boss_box.visible = true


## Wódz padł: pozostałe gobliny uciekają, po chwili spada skrzynia.
func _on_chief_died(_c: ProtoChief) -> void:
	phase = "loot"
	_gain_xp(HeroLevels.chief_xp(level) * (Pinnacles.XP_MULT if pinnacle else 1))
	horde_spawner.scatter()
	boss_box.visible = false
	var at := chief.position
	await get_tree().create_timer(CHEST_DELAY).timeout
	if hero.dead:
		return
	chest = ProtoChest.new()
	chest.name = "Chest"
	chest.hero = hero
	chest.embers = DungeonLevels.chest_embers(level)
	if pinnacle:
		_fill_pinnacle_chest(at)
		return
	chest.items = Items.roll_chest(level, hero.gear.get("rarity_pct", 0.0), hero.gear.get("quantity_pct", 0.0))
	if Pinnacles.roll_key(level, horde_spawner.loot_mult):  # klucz do Gniazda Żmija (od lochu Pinnacles.KEY_FROM)
		chest.items.append({Pinnacles.KEY: level})
	for id in Gems.roll_chest(level, horde_spawner.loot_mult * horde_spawner.gem_mult):
		chest.items.append({"gem": id})
	for id in Runes.roll_chest(level, horde_spawner.loot_mult * horde_spawner.rune_mult):
		chest.items.append({"rune": id})
	if Game.roll_weapon_seal(horde_spawner.loot_mult):  # Pieczęć Oręża - gdy jest jeszcze broń do odblokowania
		chest.items.append({"gem": Gems.WEAPON_SEAL})
	var aura := Auras.roll_chest(level, false, horde_spawner.loot_mult * horde_spawner.gem_mult)  # kamień aury (od lochu Auras.MIN_LEVEL)
	if aura != "":
		chest.items.append({"aura": aura})
	chest.loot_spawned.connect(_track_loot)
	chest.position = at
	chest.ember_spawned.connect(func(e: ProtoEmber) -> void: e.collected.connect(horde_spawner.on_chest_ember))
	chest.opened.connect(_on_chest_opened)
	$World.add_child(chest)


## Skrzynia Żmija: więcej żaru, pewna legenda, podwójne runy, szansa na unikat Żmija (Pinnacles.chest_items).
func _fill_pinnacle_chest(at: Vector2) -> void:
	chest.embers *= Pinnacles.CHEST_EMBERS
	chest.items = Pinnacles.chest_items(level, hero.gear.get("rarity_pct", 0.0), hero.gear.get("quantity_pct", 0.0),
			horde_spawner.loot_mult * horde_spawner.gem_mult)
	chest.loot_spawned.connect(_track_loot)
	chest.position = at
	chest.ember_spawned.connect(func(e: ProtoEmber) -> void: e.collected.connect(horde_spawner.on_chest_ember))
	chest.opened.connect(_on_chest_opened)
	$World.add_child(chest)


func _on_chest_opened() -> void:
	await get_tree().create_timer(VICTORY_DELAY).timeout
	victory()


## Zwycięstwo: cały żar z wyprawy do Watry, poziom przebity, okno zwycięstwa i pauza.
func victory() -> void:
	if phase == "won" or hero.dead:
		return
	phase = "won"
	horde_spawner.clock = false
	joystick.release()
	actions.release_all()
	weapon.attack_held = false
	var banked := horde_spawner.embers
	_bank()
	if pinnacle:
		Game.use_zmij_key(level)
		Game.pinnacle_key = 0
		Game.save_game()
		result.show_pinnacle(Lang.t(Pinnacles.BOSS_NAME), level, banked, horde_spawner.time, hero.deaths)
		result.add_xp_lines(run_xp, Game.hero_level if Game.hero_level > _start_hero_level else 0)
		result.add_loot_lines(run_items, run_runes, run_ore)
		result.add_filter_line(run_filtered, run_filtered_ore)
		get_tree().paused = true
		return
	var unlocked := level + 1 if Game.beat_level(level) else 0
	Game.save_if_dirty()
	result.show_victory(level, banked, unlocked, horde_spawner.kills, horde_spawner.time, hero.deaths)
	if unlocked > 0:
		result.add_unlock_lines(Unlocks.on_beat(level))
	result.add_xp_lines(run_xp, Game.hero_level if Game.hero_level > _start_hero_level else 0)
	result.add_loot_lines(run_items, run_runes, run_ore)
	result.add_filter_line(run_filtered, run_filtered_ore)
	get_tree().paused = true


## „Jeszcze raz” po śmierci albo „Następny poziom” po zwycięstwie.
func _on_retry() -> void:
	if pinnacle:  # Żmij: po zwycięstwie do bazy, po śmierci jeszcze raz (klucz został), o ile klucz jest
		if phase == "won" or Game.zmij_key_count(level) <= 0:
			Game.pinnacle_key = 0
			Game.change_scene(BASE_SCENE)
		else:
			Game.change_scene(HORDE_SCENE)
		return
	if phase == "won":
		Game.dungeon_level = mini(level + 1, Game.unlocked_level())
		Game.save_game()
	Game.change_scene(HORDE_SCENE)


## Baza: okno skrzyni (stuknięcie albo podejście).
func open_stash() -> void:
	joystick.release()
	actions.release_all()
	weapon.attack_held = false
	stash_window.open()


## Okno umiejętności: w bazie z kupowaniem (kamień run, pasek, ikonka), w lochu tylko przestawianie i kamienie.
func open_skills() -> void:
	_release()
	skills_window.open(not horde)


## Okno „Postać” (ikonka w górnym rzędzie).
func open_stats() -> void:
	_release()
	stats_window.open()


## Baza: kowal - przeróbka premii przedmiotów.
func open_smith() -> void:
	_release()
	smith_window.open()


## Baza: kupiec - klucze, dłuta, kamienie i przedmioty.
func open_shop() -> void:
	_release()
	shop_window.open()


## Baza: targ - rynek z innymi „graczami” (Market).
func open_market() -> void:
	_release()
	market_window.open()


## Baza: drzewko lochów (z wyboru poziomu przy Watrze; po zamknięciu wybór wraca).
func open_upgrades() -> void:
	_release()
	tree_window.open()


## Pasek skrótów w bazie: okno budynku od razu.
func _on_bar(id: String) -> void:
	match id:
		"watra":
			open_picker()
		"stash":
			open_stash()
		"skills":
			open_skills()
		"smith":
			open_smith()
		"shop":
			open_shop()
		"market":
			open_market()


## Puszcza gałkę i przyciski walki przed otwarciem okna.
func _release() -> void:
	joystick.release()
	actions.release_all()
	weapon.attack_held = false


## Baza: wybór poziomu lochu po dotknięciu Watry.
func open_picker() -> void:
	joystick.release()
	actions.release_all()
	picker.open(Game.dungeon_level, Game.unlocked_level())
	if Game.unlocks_seen < Game.best_level:  # nowości obejrzane - znaczek nad Watrą gaśnie
		Game.unlocks_seen = Game.best_level
		Game.save_game()
	watra.set_news(false)


func enter_dungeon(chosen: int) -> void:
	Game.pinnacle_key = 0
	Game.dungeon_level = chosen
	Game.save_game()
	Game.change_scene(HORDE_SCENE)


## Wejście do Gniazda Żmija z kluczem z poziomu `key_level` (wybór przy Watrze).
func enter_pinnacle(key_level: int) -> void:
	if Game.zmij_key_count(key_level) <= 0:
		return
	Game.pinnacle_key = key_level
	Game.save_game()
	Game.change_scene(HORDE_SCENE)


## Śmierć Wojciecha w lochu: chwila na upadek, potem okno wyniku i pauza.
func _on_hero_died() -> void:
	joystick.release()
	actions.release_all()
	weapon.attack_held = false
	await get_tree().create_timer(RESULT_DELAY).timeout
	summon_button.visible = false
	Game.save_if_dirty()
	result.show_result(horde_spawner.kills, horde_spawner.time, horde_spawner.embers)
	result.add_xp_lines(run_xp, Game.hero_level if Game.hero_level > _start_hero_level else 0)
	result.add_loot_lines(run_items, run_runes, run_ore)
	result.add_filter_line(run_filtered, run_filtered_ore)
	get_tree().paused = true


## Zebrany żar trafia do Watry (raz - licznik lochu się zeruje). Tylko po zwycięstwie nad Wodzem.
func _bank() -> void:
	if horde_spawner and not hero.dead:
		Game.bank_embers(horde_spawner.embers)
		horde_spawner.embers = 0


func _open_menu() -> void:
	joystick.release()
	actions.release_all()
	Game.save_if_dirty()
	pause_menu.open(horde_spawner.embers if horde_spawner and phase != "won" else 0)


## Po zamknięciu okna pauzy: ustawienia z Game na przyciski i postać (także tryb deweloperski).
func _apply_settings() -> void:
	actions.left_handed = Game.left_handed
	hero.gesture = Game.gesture
	hero.immortal = Game.dev_immortal
	weapon.auto_attack = Game.auto_attack
	if base_bar:
		base_bar.left_handed = Game.left_handed
	if deaths_label:
		deaths_label.visible = Game.dev_immortal
	if fps_label:
		fps_label.visible = Game.dev_fps


## Przycisk „wstecz” na Androidzie otwiera i zamyka pauzę; przełączenie telefonu na inną aplikację ją otwiera.
func _notification(what: int) -> void:
	if not pause_menu:
		return
	if picker and picker.visible:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			picker.close()
		return
	if stash_window and stash_window.visible:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			stash_window.back()
		return
	if skills_window and skills_window.visible:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			skills_window.back()
		return
	if stats_window and stats_window.visible:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			stats_window.back()
		return
	for w in [smith_window, shop_window, market_window, tree_window, unlocks_window, mods_window]:
		if w and w.visible:
			if what == NOTIFICATION_WM_GO_BACK_REQUEST:
				w.back()
			return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and pause_menu.visible:
		pause_menu.back()
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED] and not pause_menu.visible \
			and not (result and result.visible):
		_open_menu()

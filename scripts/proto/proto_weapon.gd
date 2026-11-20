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
## Trafienie mieczem (prośba autora 19.11.2026): każde trafienie miecza poza Rozłupaniem Ziemi rysuje na celu proste
## cięcie (z kreatora efektów) w poprzek kierunku od postaci; najwyżej SWORD_CUT_FX_PER_FRAME naraz (tłum przy Młynku).
const SWORD_CUT_FX := preload("res://assets/effects/sword_cut.png")
const SWORD_CUT_FX_FRAMES := 9
const SWORD_CUT_FX_FPS := 22.0
const SWORD_CUT_FX_ANCHOR := Vector2(42, 13)
const SWORD_CUT_FX_SIZE := 0.8
const SWORD_CUT_FX_PER_FRAME := 6

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
## Kulminacja Rozłupania (szlif 19.11.2026): od miejsca uderzenia, dalej od postaci, biegnie pęknięcie w ziemi
## (SLAM_CRACK px x obszar, rośnie przez SLAM_CRACK_TIME s), a wzdłuż niego po kolei wyskakują skalne kolce (efekt
## `slam_spikes` z kreatora PixelLab) - SLAM_SPIKES razy, każdy rani w promieniu SLAM_SPIKE_RADIUS SLAM_SPIKE_POWER siły
## i ogłusza na SLAM_SPIKE_STUN s.
const SLAM_CRACK := 120.0
const SLAM_CRACK_TIME := 0.25
const SLAM_SPIKES := 5
const SLAM_SPIKE_RADIUS := 20.0
const SLAM_SPIKE_POWER := 0.5
const SLAM_SPIKE_STUN := 0.6
const SLAM_SPIKE_FX := preload("res://assets/effects/slam_spikes.png")
const SLAM_SPIKE_FRAMES := 18
const SLAM_SPIKE_ANCHOR := Vector2(30, 34)
## Mgnienie (liczby z Watry): zasięg skoku (prośba autora 15.11.2026: 220 zamiast 150 - skoki między kukłami w bazie),
## ile ostatnich celów skoki omijają (prośba autora: 3 - w tłumie skoki rozchodzą się po grupie zamiast w kółko po dwóch
## wrogach), odstęp między skokami przy trzymaniu, jak daleko za celem ląduje postać, szerokość pasa cięcia wzdłuż drogi
## i promień cięcia wokół celu.
const FLICKER_RANGE := 220.0
const FLICKER_MEMORY := 3
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
## Szron (kamień) rani lodem: tyle razy siła spowolnienia jako % obrażeń trafienia (15-45% -> 7-22%).
const RIME_DAMAGE := 0.5
## Piorun (kamień) poraża trafionych przeskokiem na tyle sekund (jak katana - Elements.SHOCK_BONUS).
const DISCHARGE_SHOCK := 3.0
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
## Młynek trzymany (decyzja autora 17.11.2026): 5. poziom - tyle mniej many na sekundę, 10. poziom - wybuch co
## WHIRL_BLAST_EVERY s wirowania; kamień unikalny - wir rośnie przez WHIRL_GROW_TIME s do +WHIRL_GROW (zasięg i obrażenia).
const WHIRL_THRIFT := 0.3
const WHIRL_BLAST_EVERY := 2.5
const WHIRL_GROW_TIME := 4.0
const WHIRL_GROW := 1.0
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
## Młynek zużywa co sekundę tyle razy koszt many (start płaci raz koszt).
const WHIRL_DRAIN := 1.0

## Krąg stali: czas (5. poziom - dłużej), liczba widmowych mieczy (10. poziom - więcej), odległość rękojeści od środka
## postaci, spłaszczenie orbity (ziemia z góry pod kątem), obroty na sekundę, co ile ten sam miecz może ciąć tego samego
## wroga, połowa grubości ostrza do trafienia, wygląd (barwa, przezroczystość) i gaśnięcie na końcu.
const STEEL_TIME := 6.0
const STEEL_TIME_LONG := 8.0
const STEEL_SWORDS := 3
const STEEL_SWORDS_PERK := 5
const STEEL_INNER := 20.0
const STEEL_FLAT := 0.6
const STEEL_TURNS := 0.9
const STEEL_REHIT := 0.45
const STEEL_HIT_WIDTH := 8.0
const STEEL_TINT := Color(0.8, 0.95, 1.0, 1.0)
## Szlif Kręgu stali (19.11.2026): smuga za ostrzem każdego miecza (STEEL_TRAIL ostatnich pozycji czubka), kolor smug
## i iskier, miecze rosną z obszarem, błysk przy przywołaniu i znikaniu.
const STEEL_TRAIL := 8
const STEEL_GLOW := Color(0.55, 0.9, 1.0)
## Stałe rozjaśnienie widmowych mieczy (mieszanie addytywne na trawie było blade).
const STEEL_BRIGHT := Color(1.7, 1.9, 2.2)
const STEEL_FADE := 0.4
## Krąg stali z kamieniem unikalnym (Kamień Wiecznej Stali): bez końca, co sekundę płaci taki ułamek kosztu many.
const STEEL_DRAIN := 1.0 / 5.0

## Grupa węzłów, które miecz sam znajduje jako cele (potwory Hordy).
const TARGETS := &"proto_targets"
## Stany zwykłego ciosu (szybkość ataku i Pośpiech go przyspieszają); glewia i hydrosfera dokładają swoje.
const STRIKE_STATES := ["follow", "windup", "swing", "recover", "thrust_windup", "thrust", "thrust_recover",
		"orb_windup", "orb_shot", "k_windup", "k_swing", "k_recover"]

var hero: ProtoHero
## Żywioł obrażeń broni (Weapons.element_of; combo z przemoczeniem - Elements.soak_bonus). Ustawia podklasa.
var element := Elements.PHYSICAL
## Umiejętność skoków jak Mgnienie (miecz - „blink”, katana - Błysk Peruna), smuga skoku i kolor piorunów
## (zygzaki `_bolt`) - ustawia podklasa.
var blink_skill := ""
var _live_cache: Array[ProtoTarget] = []  # spis celów z tej klatki (_live_targets)
var _live_frame := -1
var _live_count := -1
var _area_cache := {}  # _area z tej klatki
var _area_frame := -1
var _grid := {}  # kratka (Vector2i) -> cele z tej klatki (_frame_targets, _near)
## Siatka celów (`_near`): bok kratki i zapas na ruch potworów od początku klatki (odrzut, skok).
const GRID_CELL := 40.0
const GRID_SLACK := 24.0
## Najwyżej tyle odłożonych trafień obszarowych na klatkę (_later).
const HIT_BUDGET := 24
## Skok Mgnienia/Błysku: tyle trafień od razu, reszta przez _later.
const FLICKER_HITS_NOW := 12
var _hit_queue: Array = []
const CENTER_PAD := 32.0  # najwyższy środek celu nad stopami (center_height) z zapasem
const _NO_CELL: Array = []
static var _bolt_glow: CanvasItemMaterial
var flicker_trail: Texture2D = FLICKER_TRAIL
## Czy skok pokazuje na celu cięcie Mgnienia miecza (katana ma własne cięcie - bez podwójnego efektu).
var flicker_cut := true
## Przebicie odporności potworów (premia `pen_pct` z przedmiotów, ułamek).
var penetration := 0.0
var bolt_color := Color(0.55, 0.85, 1.0)
## Jasny rdzeń zygzaka pioruna.
var bolt_core := Color(0.92, 0.98, 1.0)
## Palec trzyma przycisk umiejętności ładowanej (Skills.is_charged - Sąd Peruna katany).
var charge_held := false
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
## Aura Żar Swaroga (Auras): tyle części każdego trafienia dochodzi jako ogień (z podpaleniem); 0 - brak aury.
var aura_fire := 0.0
## Talizmany (ProtoTalismans): węzeł wołany przy każdym trafieniu (`on_hit`), dopłata many za umiejętności (Kryształ Peruna)
## i mnożnik obrażeń (Czaszka Biesa).
var talismans: ProtoTalismans
var mana_tax := 0.0
## Premia przedmiotów „+% obrażeń od żywiołów” (Items elem_dmg_pct): mnożnik każdego trafienia żywiołem (broń
## żywiołu, kamienie Żar / Szron / Piorun, ogień Swaroga, aury, talizmany); obrażenia fizyczne bez zmian.
var elem_mult := 1.0
## Talizmany (ProtoTalismans ustawia): dodatkowa premia żywiołów na chwilę (Łuska Żmija), zamiana obrażeń fizycznych
## na ogień (Krzesiwo Swaroga - `fire_convert` i premia `fire_convert_bonus`), premia z bliska / kara z daleka (Kieł
## Niedźwiedzia - `point_blank`).
var elem_extra := 0.0
var fire_convert := false
var fire_convert_bonus := 0.0
var point_blank := 0.0
## Aura Rój Strzyboga (Auras, arena ustawia): tyle pocisków więcej naraz i mnożnik ich obrażeń (kara aury).
var extra_projectiles := 0
var projectile_mult := 1.0
## Talizman Poroże Jelenia: chwilowo szybszy atak (część; mnoży speed_mult).
var speed_bonus := 0.0
## Kamień Echo: umiejętność, której powtórka czeka (za darmo - mana_cost 0); Rozprysk: trwa rozprysk (bez łańcucha).
var _echo_pending := ""
var _splashing := false
var bonus_mult := 1.0

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
## Ostatnie cele skoków (najnowszy na końcu, najwyżej FLICKER_MEMORY).
var _recent_targets: Array = []
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
## Palec trzyma mały przycisk Młynka (arena) - wiruje, dopóki trzyma.
var whirl_held := false
## Ile wybuchów Młynka było (10. poziom; do testów).
var whirl_blasts := 0
## Ile sekund trwa obecne wirowanie (kamień unikalny - wir rośnie).
var _whirl_time := 0.0
var _whirl_drain_acc := 0.0
var _whirl_blast_t := 0.0
var _bounces_left := 0
var _waves: Array = []
## Krąg stali: widmowe miecze ({"sprite", "power", "hits": {wróg: czas}}), ile jeszcze trwa, kąt obrotu.
var _ring: Array = []
var _ring_left := 0.0
var _ring_spin := 0.0
var _ring_trail: Line2D
var _ring_drain_acc := 0.0
## Licznik cięć-trafień w bieżącej klatce (SWORD_CUT_FX_PER_FRAME).
var _cut_frame := -1
var _cut_count := 0


func _ready() -> void:
	skill_used.connect(_on_skill_used)
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
	_drain_hits()
	var sp := _strike_speed() if _state in STRIKE_STATES else speed_mult * (1.0 + speed_bonus)
	_cooldown -= delta * sp
	_t += delta * sp
	for id in _cd:
		_cd[id] = maxf(_cd[id] - delta, 0.0)
	if hero.dead and _state != "follow":
		_end_skill()
	_process_waves(delta)
	_process_ring(delta)
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
	for t in _near(hero.global_position, reach):
		var d := hero.global_position.distance_to(t.global_position)
		if d <= best_d:
			best = t
			best_d = d
	return best


## Najdalszy żywy wróg w zasięgu `reach` od postaci (pioruny - długa, widoczna wiązka; null - brak).
func _farthest(reach := REACH) -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := -1.0
	for t in _near(hero.global_position, reach):
		var d := hero.global_position.distance_to(t.global_position)
		if d <= reach and d > best_d:
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
	for t in _near_c(_orbit_center(), reach):
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
		for t in _near_c(_orbit_center(), near_d):
			var d := t.center().distance_to(_orbit_center())
			if not hit.has(t) and d <= near_d:
				near = t
				near_d = d
		if near:
			_deal(near, _roll(power), hero.global_position, Skills.STRIKE)
			Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, near.center().round(), HIT_FX_ANCHOR)
	if not hit.is_empty():
		Input.vibrate_handheld(15)


## Cele, które da się jeszcze trafić: lista `targets` i potwory z grupy TARGETS. Spis zbiera się raz na klatkę
## (wydajność, pomiar `tools/combat_bench.gd` 20.11.2026: przy 150 potworach katana wołała to przy każdym przeskoku
## pioruna, a dawne sprawdzanie powtórek porównywało każdego z każdym), przy każdym wywołaniu bez poległych.
func _live_targets() -> Array[ProtoTarget]:
	var out: Array[ProtoTarget] = []
	for t in _frame_targets():
		if is_instance_valid(t) and t.alive():
			out.append(t)
	return out


## Spis celów z tej klatki bez kopiowania (mogą w nim być polegli - sprawdzaj is_instance_valid i alive).
## Przy okazji układa cele w siatkę (`_near`).
func _frame_targets() -> Array[ProtoTarget]:
	var frame := Engine.get_process_frames()
	var count := get_tree().get_node_count_in_group(TARGETS) + targets.size()  # nowy wróg w tej klatce - od nowa
	if frame != _live_frame or count != _live_count:
		_live_frame = frame
		_live_count = count
		_live_cache.clear()
		_grid.clear()
		var seen := {}
		for list: Array in [targets, get_tree().get_nodes_in_group(TARGETS)]:
			for t in list:
				if is_instance_valid(t) and t is ProtoTarget and not seen.has(t):
					seen[t] = true
					_live_cache.append(t)
					var key := Vector2i((t.global_position / GRID_CELL).floor())
					if _grid.has(key):
						_grid[key].append(t)
					else:
						_grid[key] = [t]
	return _live_cache


## Żywe cele w pobliżu `at`: wszyscy, których pozycja (stopy) jest najwyżej `radius` od `at`, i może kilku dalszych -
## odległość sprawdza wołający. Z siatki tej klatki (wydajność przy tłumie 150-250 potworów - pętle w każdej klatce
## i przy każdym trafieniu przeglądają tylko kratki dookoła, a nie wszystkich wrogów; `tools/combat_bench.gd`).
func _near(at: Vector2, radius: float) -> Array[ProtoTarget]:
	_frame_targets()
	var out: Array[ProtoTarget] = []
	var r := radius + GRID_SLACK
	var c0 := Vector2i(((at - Vector2(r, r)) / GRID_CELL).floor())
	var c1 := Vector2i(((at + Vector2(r, r)) / GRID_CELL).floor())
	if (c1.x - c0.x + 1) * (c1.y - c0.y + 1) > _grid.size():  # ogromny promień - taniej przejrzeć wszystkich
		return _live_targets()
	for x in range(c0.x, c1.x + 1):
		for y in range(c0.y, c1.y + 1):
			var cell: Array = _grid.get(Vector2i(x, y), _NO_CELL)
			for t: ProtoTarget in cell:
				if is_instance_valid(t) and t.alive():
					out.append(t)
	return out


## Trafienie obszarowe odłożone na później (wir, deszcz strzał, płonąca strefa, wybuch wody): `hit` woła się
## w jednej z najbliższych klatek, najwyżej HIT_BUDGET na klatkę - gdy kilka obszarów naraz trafia dziesiątki
## wrogów, praca rozkłada się na kilka klatek zamiast jednego przycięcia (tools/combat_bench.gd, 20.11.2026).
func _later(t: ProtoTarget, hit: Callable) -> void:
	_hit_queue.append([t, hit])


func _drain_hits() -> void:
	if _hit_queue.is_empty():
		return
	var n := mini(HIT_BUDGET, _hit_queue.size())
	var batch := _hit_queue.slice(0, n)
	_hit_queue = _hit_queue.slice(n)
	for e: Array in batch:
		var t = e[0]
		if is_instance_valid(t) and t.alive() and hero and not hero.dead:
			(e[1] as Callable).call()


## Żywe cele dla aur i talizmanów (ProtoAuras, ProtoTalismans): wszystkie i w pobliżu punktu (siatka). Do 20.11.2026
## aury i talizmany przeglądały samo `targets` - w lochu potworów tam nie ma (są w grupie TARGETS), więc ich
## działania obszarowe raniły tylko kukły w bazie (znalezione przy pomiarze `tools/combat_bench.gd`).
func live_targets() -> Array[ProtoTarget]:
	return _live_targets()


func targets_near(at: Vector2, radius: float) -> Array[ProtoTarget]:
	return _near(at, radius)


## Jak `_near`, ale dla odległości od środka celu (`center()` - wyżej niż stopy o center_height).
func _near_c(at: Vector2, radius: float) -> Array[ProtoTarget]:
	return _near(at + Vector2(0, CENTER_PAD * 0.5), radius + CENTER_PAD * 0.5)


func _set_state(state: String) -> void:
	_state = state
	_t = 0.0


## Obrażenia jednego trafienia: zwykłe cięcie razy `power` (mnożnik umiejętności).
func _roll(power := 1.0) -> int:
	return maxi(1, roundi(randi_range(damage.x, damage.y) * damage_mult * bonus_mult * power))


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


## Mnożnik zasięgu umiejętności (kamień Szerokość, premia przedmiotów i poziom; Skupienie zmniejsza).
func _area(skill: String) -> float:
	# zapamiętane na klatkę (strzały i pętle po wrogach pytają setki razy); klucz z premią i kamieniami - zmiana
	# w tej samej klatce (testy, okno) liczy od nowa
	var frame := Engine.get_process_frames()
	if frame != _area_frame:
		_area_frame = frame
		_area_cache.clear()
	var key := [skill, area_bonus, skill_gems.get(skill, []), level_of(skill)]
	var hit = _area_cache.get(key)
	if hit != null:
		return hit
	var focus := Gems.FOCUS_AREA if gem_power(skill, "focus") > 0.0 else 1.0
	var area := (1.0 + (gem_power(skill, "area") + area_bonus) / 100.0) * Skills.level_area(level_of(skill)) * focus
	_area_cache[key] = area
	return area


## Szybkość zwykłego ciosu: premia szybkości ataku, kamień Pośpiech i poziomy zwykłego ciosu (mniejszy „koszt” -
## szybszy cios).
func _strike_speed() -> float:
	return speed_mult * (1.0 + speed_bonus) * (1.0 + gem_power(basic, "haste") / 100.0) \
			* (2.0 - Skills.level_cost(level_of(basic)))


## Koszt many umiejętności z kamieniem Oszczędność i poziomem (Mgnienie z kamieniem unikalnym - o połowę mniej).
func mana_cost(id: String) -> int:
	if id == _echo_pending:
		return 0  # powtórka kamienia Echo jest za darmo
	var cost := Skills.mana_of(id) * (1.0 - gem_power(id, "thrift") / 100.0) * Skills.level_mana(level_of(id)) * (1.0 + mana_tax)
	if id == blink_skill and _unique(id):
		cost *= 0.5
	return roundi(cost)


## Koszt skoku Mgnienia.
func _blink_cost() -> int:
	return mana_cost(blink_skill)


## Pełne odnowienie umiejętności z kamieniem Pośpiech i poziomem.
## Młynek z kamieniem unikalnym - bez odnowienia (Mgnienie nie ma go wcale).
func cooldown_full(id: String) -> float:
	if id in ["whirl", "steel_ring"] and _unique(id):
		return 0.0
	return _cooldown_base(id)


## Odnowienie bez kamienia unikalnego (Młynek z nim - co tyle wybuch z 10. poziomu).
func _cooldown_base(id: String) -> float:
	return Skills.cooldown_of(id) * (1.0 - gem_power(id, "haste") / 100.0) * Skills.level_cost(level_of(id)) \
			* (1.0 - cooldown_cut)


## Trafienie umiejętnością `skill` - premia przeciw elitom i bossom, combo żywiołów (porażony wróg dostaje więcej
## od wszystkiego, przemoczony - od Gromu i lodu), trafienie krytyczne (złota liczba), obrażenia
## i działanie jej kamieni (podpalenie, spowolnienie - na przemoczonym zamrożenie, leczenie, mana,
## piorun).
## Węzły w świecie, którymi broń steruje co klatkę (lecące fale, strefy ognia, wiry...) - listy wpisów; przy zmianie
## broni (albo wyjściu z lochu) znikają razem z nią, inaczej zostawały zamrożone na ekranie (zgłoszenie autora
## 19.11.2026). Bronie dopisują swoje listy (super + własne).
func _world_fx() -> Array:
	return [_waves]


func _exit_tree() -> void:
	for list in _world_fx():
		_free_fx(list)
		if list is Array:
			list.clear()


## Usuwa węzły efektów z `v` (węzeł, lista albo słownik - wpis efektu); pomija cele i postać.
static func _free_fx(v: Variant) -> void:
	if v is Object:
		if is_instance_valid(v) and v is Node and not (v is ProtoTarget or v is ProtoHero):
			(v as Node).queue_free()
	elif v is Array:
		for x in v:
			_free_fx(x)
	elif v is Dictionary:
		for x in v.values():
			_free_fx(x)


## Proste cięcie na celu `t` (tylko miecz): skośnie w poprzek kierunku od `from`, lekko losowo.
func _sword_cut_fx(t: ProtoTarget, from: Vector2) -> void:
	var frame := Engine.get_process_frames()
	if frame != _cut_frame:
		_cut_frame = frame
		_cut_count = 0
	_cut_count += 1
	if _cut_count > SWORD_CUT_FX_PER_FRAME or not is_inside_tree():
		return
	var dir := t.center() - from
	var angle := (dir.angle() if dir.length() > 1.0 else 0.0) + PI / 2.0 + randf_range(-0.5, 0.5)
	var cut := Fx.once(get_parent(), SWORD_CUT_FX, SWORD_CUT_FX_FRAMES, SWORD_CUT_FX_FPS, t.center().round(),
			SWORD_CUT_FX_ANCHOR, 21, SWORD_CUT_FX_SIZE)
	cut.rotation = angle
	cut.self_modulate = Color(1.4, 1.5, 1.7)  # jaśniej - na trawie i goblinach cienka linia ginęła


## Trafienie aury (ProtoAuras: piorun Peruna, mróz Szronu, Błędny Ognik): `power` zwykłego ciosu w żywiole `elem`,
## z premią przeciw elitom i odpornością celu, bez krytyków i kamieni. Liczba w kolorze żywiołu. `flat` - stałe
## obrażenia dodane do rzutu (talizman Kryształ Peruna - część many).
func aura_hit(t: ProtoTarget, power: float, elem: String, from: Vector2, flat := 0) -> void:
	if not t.alive():
		return
	var amount := roundi((_roll(power) + flat) * (1.0 + t.pride))
	if _tough(t):
		amount = roundi(amount * elite_mult)
	if elem != Elements.PHYSICAL:
		amount = roundi(amount * elem_total())
	t.color_next = Elements.color_of(elem)
	t.take_damage(Elements.reduce(amount, t.resist(elem, penetration)), from)


## Premia żywiołów razem: przedmioty (elem_mult) i talizman Łuska Żmija (elem_extra).
func elem_total() -> float:
	return elem_mult * (1.0 + elem_extra)


## Kąty `count` pocisków (plus dodatkowe z aury Rój Strzyboga - `extra`) w stożku wokół `aim`, co `spread` radianów.
func fan(aim: float, count: int, spread: float, extra := true) -> Array[float]:
	var n := count + (extra_projectiles if extra else 0)
	var out: Array[float] = []
	for i in n:
		out.append(aim + spread * (i - (n - 1) / 2.0))
	return out


## Elita albo boss (premia przeciw elitom, słabsze dobijanie).
static func _tough(t: ProtoTarget) -> bool:
	return t is ProtoChief or (t is ProtoGoblin and t.elite != null)


## Dobija wroga (kamień Egzekucja, talizman Hak Kata): ciemnoczerwona liczba z resztą jego zdrowia.
func execute(t: ProtoTarget, from: Vector2) -> void:
	var rest := t.remaining_hp()
	if rest <= 0 or not t.alive():
		return
	t.color_next = Color(0.75, 0.1, 0.15)
	t.take_damage(rest, from)


func _deal(t: ProtoTarget, amount: int, from: Vector2, skill: String) -> void:
	var sockets: Array = skill_gems.get(skill, [])
	var elem := element
	if fire_convert and elem == Elements.PHYSICAL:  # Krzesiwo Swaroga: fizyczne -> ogień
		elem = Elements.FIRE
		amount = roundi(amount * (1.0 + fire_convert_bonus))
		t.color_next = Elements.color_of(Elements.FIRE)
	if _tough(t):
		amount = roundi(amount * elite_mult)
	if t.pride > 0.0:  # Piętno Czarnoboga
		amount = roundi(amount * (1.0 + t.pride))
	var mult := 1.0 + Gems.skill_power(sockets, "focus") / 100.0  # Skupienie
	if t.speed_factor() < 1.0:
		mult += Gems.skill_power(sockets, "hypothermia") / 100.0
	if t.is_burning():
		mult += Gems.skill_power(sockets, "combustion") / 100.0
	if point_blank > 0.0:  # Kieł Niedźwiedzia: z bliska więcej, z daleka mniej
		var d := t.global_position.distance_to(hero.global_position)
		mult *= 1.0 + point_blank if d <= Talismans.POINT_BLANK_NEAR else (1.0 - point_blank * 0.5 \
				if d >= Talismans.POINT_BLANK_FAR else 1.0)
	amount = roundi(amount * mult)
	var boost := elem_total() if elem != Elements.PHYSICAL else 1.0  # premia żywiołów (broń żywiołu)
	amount = roundi(amount * boost)
	var pen := penetration + Gems.skill_power(sockets, "pen") / 100.0  # Przebicie
	amount = Elements.reduce(amount, t.resist(elem, pen), _combo_mult(t, elem))  # odporność lochu na żywioł broni
	var keen := Gems.skill_power(sockets, "keen") / 100.0  # Bystre Oko
	var crit := randf() < crit_chance + keen
	if crit:
		amount = roundi(amount * (crit_mult + keen * Gems.KEEN_DAMAGE))
		t.crit_next = true
	t.take_damage(amount, from)
	t.crit_next = false
	if talismans != null:
		talismans.on_hit(t)
		if crit:
			talismans.on_crit()
	_support_hit(t, amount, from, elem, pen, sockets)
	if skill != "slam" and get_script() == ProtoWeapon:
		_sword_cut_fx(t, from)
	# ogień Swaroga i kamienie żywiołów liczą się od ciosu bez premii broni, za to z premią żywiołów raz
	var elem_base := amount / boost * elem_total()
	if aura_fire > 0.0 and t.alive():
		var fire := elem_base * aura_fire
		t.color_next = Elements.color_of(Elements.FIRE)
		t.take_damage(Elements.reduce(maxi(1, roundi(fire)), t.resist(Elements.FIRE, penetration)), from)
		t.burn(fire * Auras.SWAROG_BURN, BURN_TIME, penetration)
	if sockets.is_empty():
		return
	var p := Gems.skill_power(sockets, "ember")
	if p > 0.0:
		t.burn(elem_base * p / 100.0, BURN_TIME, penetration)
	p = Gems.skill_power(sockets, "rime")
	if p > 0.0:
		var soaked := t.is_soaked()
		if soaked:
			t.freeze(Elements.SOAK_FREEZE)  # lód na przemoczonym - krótkie zamrożenie
		t.slow(p / 100.0, SLOW_TIME)
		if t.alive():  # Szron rani też lodem (decyzja autora 17.11.2026): RIME_DAMAGE siły spowolnienia, combo z wodą
			t.color_next = Elements.color_of(Elements.COLD)
			t.take_damage(Elements.reduce(roundi(elem_base * p / 100.0 * RIME_DAMAGE), t.resist(Elements.COLD, penetration),
					Elements.soak_bonus(Elements.COLD, soaked)), from)
	p = Gems.skill_power(sockets, "leech")
	if p > 0.0:
		_leech_acc += amount * p / 100.0
		var heal := int(_leech_acc)
		if heal > 0:
			_leech_acc -= heal
			hero.heal(heal)
	if skill == basic:
		var thrift := Gems.skill_level(sockets, "thrift")
		if thrift > 0:
			hero.add_mana(Gems.thrift_mana(thrift))
	p = Gems.skill_power(sockets, "discharge")
	if p > 0.0 and not _chained:
		_chained = true
		for n in _chain_from(t, maxi(1, roundi(elem_base * p / 100.0))):
			n.shock(DISCHARGE_SHOCK)  # piorun z kamienia poraża jak katana (decyzja autora 17.11.2026)


## Kamienie z Path of Exile po trafieniu (20.11.2026): Odrzut, Twardość, Egzekucja, Rozprysk (wrogowie obok celu
## dostają część obrażeń - bez kolejnego rozprysku i efektów).
func _support_hit(t: ProtoTarget, amount: int, from: Vector2, elem: String, pen: float, sockets: Array) -> void:
	if sockets.is_empty():
		return
	var p := Gems.skill_power(sockets, "knockback")
	if p > 0.0 and t.alive():
		t.push_away(hero.global_position, p)
	p = Gems.skill_power(sockets, "fortify")
	if p > 0.0:
		hero.fortify(p / 100.0, Gems.FORTIFY_TIME)
	p = Gems.skill_power(sockets, "execute")
	if p > 0.0 and t.alive() and t.health_fraction() < p / 100.0 * (0.5 if _tough(t) else 1.0):
		execute(t, from)
	p = Gems.skill_power(sockets, "splash")
	if p > 0.0 and not _splashing:
		_splashing = true
		for e in _near(t.global_position, Gems.SPLASH_RADIUS):
			if e != t and e.global_position.distance_to(t.global_position) <= Gems.SPLASH_RADIUS:
				e.color_next = Elements.color_of(elem) if elem != Elements.PHYSICAL else Color(0, 0, 0, 0)
				e.take_damage(Elements.reduce(maxi(1, roundi(amount * p / 100.0)), e.resist(elem, pen)), from)
		_splashing = false


## Mnożnik combo żywiołów na celu `t`: porażony - +Elements.SHOCK_BONUS od wszystkiego, przemoczony - Grom i lód
## mocniej (Elements.soak_bonus).
func _combo_mult(t: ProtoTarget, elem := "") -> float:
	var mult := Elements.soak_bonus(elem if elem != "" else element, t.is_soaked())
	if t.is_shocked():
		mult *= 1.0 + Elements.SHOCK_BONUS
	return mult


## Wiązka pioruna (kamień Piorun, przeskoki katany): z celu `src` skacze po kolei `count` razy - za każdym razem
## z ostatnio trafionego (decyzja autora 19.11.2026, żeby wiązkę było widać): do NAJDALSZEGO wroga w zasięgu `range_px`,
## którego ta wiązka jeszcze nie trafiła; gdy takich nie ma - do najdalszego już trafionego (np. dwóch wrogów: skacze
## między nimi), nigdy w tego, na którym właśnie jest. Z przemoczonego celu (combo z wodą) Elements.SOAK_CHAIN_EXTRA
## skoków więcej i mocniej. Zwraca trafionych po kolei (z powtórkami).
func _chain_from(src: ProtoTarget, amount: int, count := CHAIN_TARGETS, range_px := CHAIN_RANGE) -> Array:
	if src.is_soaked():
		count += Elements.SOAK_CHAIN_EXTRA
		amount = roundi(amount * Elements.SOAK_BONUS)
	var hit: Array = []
	var visited := {src: true}
	var current := src
	for i in count:
		var next := chain_next(current, visited, range_px)
		if next == null:
			break
		_bolt(current.center(), next.center())
		next.color_next = Elements.color_of(Elements.LIGHTNING)
		next.take_damage(Elements.reduce(maxi(1, amount), next.resist(Elements.LIGHTNING, penetration)), current.global_position)
		hit.append(next)
		visited[next] = true
		current = next
	return hit


## Następny cel wiązki z `current`: najdalszy żywy wróg w zasięgu `range_px` spoza `visited`; gdy brak - najdalszy
## z `visited` (bez `current`); null - nie ma nikogo.
func chain_next(current: ProtoTarget, visited: Dictionary, range_px: float) -> ProtoTarget:
	var fresh: ProtoTarget = null
	var fresh_d := -1.0
	var old: ProtoTarget = null
	var old_d := -1.0
	var from := current.global_position
	var range_sq := range_px * range_px
	for t in _near(from, range_px):  # siatka - wołane przy każdym przeskoku pioruna
		if t == current:
			continue
		var d := t.global_position.distance_squared_to(from)
		if d > range_sq:
			continue
		if visited.has(t):
			if d > old_d:
				old = t
				old_d = d
		elif d > fresh_d:
			fresh = t
			fresh_d = d
	return fresh if fresh else old


## Zygzak pioruna między dwoma punktami (świat): szeroka niebieska poświata i jasny rdzeń (17.11.2026 - bardziej
## widoczny i niebieski jak inne pioruny), gaśnie w 0,3 s.
func _bolt(a: Vector2, b: Vector2) -> void:
	var glow := Line2D.new()
	glow.width = 4.0
	glow.default_color = Color(bolt_color, 0.55)
	glow.z_index = 21
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	if _bolt_glow == null:  # jeden materiał dla wszystkich piorunów (przy wiązkach jest ich dużo naraz)
		_bolt_glow = CanvasItemMaterial.new()
		_bolt_glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = _bolt_glow
	var core := Line2D.new()
	core.width = 1.5
	core.default_color = bolt_core
	var steps := 6
	var side := (b - a).orthogonal().normalized()
	for i in steps + 1:
		var k := float(i) / steps
		var jitter := 0.0 if i == 0 or i == steps else randf_range(-5.0, 5.0)
		glow.add_point(a.lerp(b, k) + side * jitter)
		core.add_point(glow.get_point_position(i))
	glow.add_child(core)
	get_parent().add_child(glow)
	var tween := glow.create_tween()
	tween.tween_interval(0.08)
	tween.tween_property(glow, "modulate:a", 0.0, 0.22)
	tween.tween_callback(glow.queue_free)


## Ile sekund odnowienia zostało umiejętności `id` (0 - gotowa).
func cooldown_left(id: String) -> float:
	return _cd.get(id, 0.0)


## Czy umiejętność da się teraz użyć (odnowiona i starcza many).
func can_use(id: String) -> bool:
	if id == "steel_ring" and _unique(id) and ring_left() > 0.0:
		return false  # krąg bez końca już krąży - auto atak tnie zwykłym ciosem
	var cost := _blink_cost() if id == blink_skill else mana_cost(id)
	return Skills.has(id) and cooldown_left(id) <= 0.0 and hero.can_pay(cost) and not hero.dead


## Użycie umiejętności z małego przycisku. W trakcie innego ruchu miecza czeka w kolejce. Zwraca false (i wysyła
## `cast_failed`), gdy się odnawia albo brakuje many.
func cast(id: String) -> bool:
	if not Skills.has(id) or hero.dead:
		return false
	if id == "whirl" and _state == "whirl":
		return true  # już wiruje (trzymany)
	if id == "steel_ring" and _unique(id) and ring_left() > 0.0:
		_clear_ring()  # Kamień Wiecznej Stali: drugie stuknięcie wyłącza krąg
		return true
	if cooldown_left(id) > 0.0:
		cast_failed.emit(id, "cooldown")
		return false
	if not hero.can_pay(_blink_cost() if id == blink_skill else mana_cost(id)):
		cast_failed.emit(id, "mana")
		return false
	if id == blink_skill:
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
			_whirl_time = 0.0
			_whirl_fx.visible = true
			_whirl_fx.scale = Vector2.ONE * _whirl_radius() / WHIRL_FX_RADIUS
			_ghosts[0].visible = gem_power("whirl", "multi") > 0.0
			_set_state("whirl")
		"throw":
			var best := _farthest(Skills.DATA.throw.range)  # przebija tłum do najdalszego (19.11.2026)
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
		"steel_ring":
			_start_ring()
	skill_used.emit(id)


## Krąg stali (pomysł autora, 15.11.2026): wokół postaci zaczynają krążyć widmowe miecze; miecz w ręku nie zmienia
## stanu, więc walczy dalej normalnie. Ponowne użycie w trakcie - krąg od nowa (z pełnym czasem).
## Kamień Mnożenie - jeden miecz więcej (z siłą kamienia). Kamień unikalny (Wiecznej Stali, pomysł autora 15.11.2026):
## krąg bez końca i bez odnowienia, co sekundę STEEL_DRAIN kosztu many; drugie stuknięcie albo brak many go wyłącza.
func _start_ring() -> void:
	_clear_ring()
	var glow := CanvasItemMaterial.new()  # widmowe miecze świecą (mieszanie addytywne)
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var count := STEEL_SWORDS_PERK if _perk("steel_ring", 1) else STEEL_SWORDS
	var extra := gem_power("steel_ring", "multi") / 100.0
	for i in count + (1 if extra > 0.0 else 0):
		var s := Sprite2D.new()
		s.texture = _sprite.texture
		s.centered = false
		s.offset = _sprite.offset
		s.scale = Vector2.ONE * SCALE
		s.modulate = STEEL_TINT
		s.material = glow
		s.top_level = true
		add_child(s)
		var trail := Line2D.new()  # smuga za czubkiem ostrza
		trail.top_level = true
		trail.width = 7.0
		trail.material = glow
		trail.joint_mode = Line2D.LINE_JOINT_ROUND
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		var fade := Gradient.new()
		fade.colors = PackedColorArray([Color(STEEL_GLOW, 0.0), Color(STEEL_GLOW, 0.95)])
		trail.gradient = fade
		var taper := Curve.new()
		taper.add_point(Vector2(0.0, 0.2))
		taper.add_point(Vector2(1.0, 1.0))
		trail.width_curve = taper
		add_child(trail)
		_ring.append({"sprite": s, "trail": trail, "power": extra if i >= count else 1.0, "hits": {}})
	_ring_trail = Line2D.new()  # delikatny ślad orbity - widać, dokąd sięga krąg
	_ring_trail.width = 1.5
	_ring_trail.top_level = true
	_ring_trail.z_index = -1
	_ring_trail.material = glow
	for i in 33:
		var a := TAU * i / 32.0
		_ring_trail.add_point(Vector2(cos(a), sin(a) * STEEL_FLAT) * (STEEL_INNER + BLADE * 0.8) * _area("steel_ring"))
	add_child(_ring_trail)
	_ring_left = STEEL_TIME_LONG if _perk("steel_ring", 0) else STEEL_TIME
	if _unique("steel_ring"):
		_ring_left = INF  # Kamień Wiecznej Stali: krąg trwa, dopóki starcza many
		_ring_drain_acc = 0.0
	_ring_spin = hero.facing.angle()
	hero.play_gesture(_orbit_center() + Vector2(0, ORBIT_HEIGHT + 10.0))
	for r in _ring:  # przywołanie: miecze rozbłyskują i „wskakują” na orbitę
		var sp: Sprite2D = r.sprite
		sp.self_modulate = Color(3.0, 3.0, 3.0)
		sp.create_tween().tween_property(sp, "self_modulate", STEEL_BRIGHT, 0.35)


## Krąg stali: miecze krążą po spłaszczonej orbicie (ostrzem na zewnątrz, z tyłu - za postacią), każdy tnie
## wroga, przez którego przechodzi jego ostrze, ale tego samego najwyżej co STEEL_REHIT.
func _process_ring(delta: float) -> void:
	if _ring.is_empty():
		return
	_ring_left -= delta
	if _ring_left <= 0.0 or hero.dead:
		_clear_ring()
		return
	if is_inf(_ring_left):
		_ring_drain_acc += mana_cost("steel_ring") * STEEL_DRAIN * delta
		var pay := int(_ring_drain_acc)
		if pay > 0:
			_ring_drain_acc -= pay
			if not hero.spend_mana(pay):
				cast_failed.emit("steel_ring", "mana")
				_clear_ring()
				return
	_ring_spin += TAU * STEEL_TURNS * delta
	var area := _area("steel_ring")
	var center := _orbit_center()
	var targets_now := _live_targets()
	_ring_trail.global_position = center
	_ring_trail.default_color = Color(STEEL_GLOW, 0.35 * clampf(_ring_left / STEEL_FADE, 0.0, 1.0))
	for i in _ring.size():
		var r: Dictionary = _ring[i]
		var s: Sprite2D = r.sprite
		var a := _ring_spin + TAU * i / _ring.size()
		var dir := Vector2(cos(a), sin(a) * STEEL_FLAT)
		var at := center + dir * STEEL_INNER * area
		s.global_position = at
		s.rotation = dir.angle()
		s.scale = Vector2.ONE * SCALE * area  # obszar powiększa też widmowe miecze
		s.z_index = -1 if sin(a) < -0.2 else 1
		var fade := clampf(_ring_left / STEEL_FADE, 0.0, 1.0)
		s.modulate.a = STEEL_TINT.a * fade
		var tip := at + dir.normalized() * BLADE * area
		var trail: Line2D = r.trail
		trail.add_point(tip)
		while trail.get_point_count() > STEEL_TRAIL:
			trail.remove_point(0)
		trail.z_index = s.z_index
		trail.modulate.a = fade
		for t in targets_now:
			var c := t.center()
			if Geometry2D.get_closest_point_to_segment(c, at, tip).distance_to(c) > STEEL_HIT_WIDTH + t.center_height * 0.4:
				continue
			if _clock - float(r.hits.get(t.get_instance_id(), -INF)) < STEEL_REHIT:
				continue
			r.hits[t.get_instance_id()] = _clock
			_deal(t, _roll(_power("steel_ring") * r.power), center, "steel_ring")
			var spark := Fx.once(get_parent(), HIT_FX, HIT_FX_FRAMES, HIT_FX_FPS, c.round(), HIT_FX_ANCHOR, 21, 0.85)
			spark.modulate = Color(0.75, 0.95, 1.4)  # błękitne iskry widmowej stali


func _clear_ring() -> void:
	for r in _ring:
		var sp: Sprite2D = r.sprite
		if is_inside_tree() and sp.modulate.a > 0.05:  # krąg znika: miecze rozbłyskują i rozwiewają się
			var ghost := sp.duplicate() as Sprite2D
			get_parent().add_child(ghost)
			ghost.global_position = sp.global_position
			ghost.self_modulate = Color(2.5, 2.5, 2.5)
			var tw := ghost.create_tween().set_parallel()
			tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
			tw.tween_property(ghost, "scale", ghost.scale * 1.4, 0.3)
			tw.chain().tween_callback(ghost.queue_free)
		sp.queue_free()
		(r.trail as Line2D).queue_free()
	_ring.clear()
	if _ring_trail:
		_ring_trail.queue_free()
		_ring_trail = null


## Ile jeszcze krąży Krąg stali (0 - nie krąży).
func ring_left() -> float:
	return _ring_left if not _ring.is_empty() else 0.0


## Młynek: miecz krąży wokół postaci (rękojeścią do niej), co WHIRL_TICK rani wszystkich w promieniu. Wiruje, dopóki
## gracz trzyma przycisk (decyzja autora 17.11.2026): spod dużego - „Atak” (auto atak - dopóki są wrogowie w pobliżu),
## spod małego - `whirl_held`; płaci manę co sekundę (WHIRL_DRAIN kosztu, 5. poziom - mniej), bez odnowienia; kończy się
## bez many. 10. poziom - wybuch co WHIRL_BLAST_EVERY s. Kamień unikalny - wir rośnie z czasem (`_whirl_grow`).
func _process_whirl(delta: float) -> void:
	_whirl_time += delta
	_spin += TAU * WHIRL_SPIN * delta
	_place(_spin)
	if _ghosts[0].visible:
		_ghosts[0].global_position = _orbit_center() + Vector2.from_angle(_spin + PI) * HILT_RADIUS
		_ghosts[0].rotation = _spin + PI
	_whirl_fx.position = _orbit_center() - global_position
	_whirl_fx.frame = int(_clock * WHIRL_FX_FPS) % WHIRL_FX_FRAMES
	_whirl_fx.scale = Vector2.ONE * _whirl_radius() / WHIRL_FX_RADIUS
	_tick -= delta
	if _tick <= 0.0:
		_tick = WHIRL_TICK
		var hit := false
		var extra := gem_power("whirl", "multi") / 100.0
		var power := _power("whirl") * _whirl_grow()
		for t in _near_c(_orbit_center(), _whirl_radius()):
			if t.center().distance_to(_orbit_center()) <= _whirl_radius():
				_deal(t, _roll(power), hero.global_position, "whirl")
				if extra > 0.0 and t.alive():
					_deal(t, _roll(power * extra), hero.global_position, "whirl")
				hit = true
		if hit:
			Input.vibrate_handheld(8)
	var drain := mana_cost("whirl") * WHIRL_DRAIN * (1.0 - WHIRL_THRIFT if _perk("whirl", 0) else 1.0)
	_whirl_drain_acc += drain * delta
	var pay := int(_whirl_drain_acc)
	if pay > 0:
		_whirl_drain_acc -= pay
		if not hero.spend_mana(pay):
			cast_failed.emit("whirl", "mana")
			_end_skill()
			return
	if _perk("whirl", 1):
		_whirl_blast_t += delta
		if _whirl_blast_t >= WHIRL_BLAST_EVERY:
			_whirl_blast_t = 0.0
			_whirl_blast()
	var held := attack_held or (auto_attack and _nearest(Skills.DATA.whirl.range) != null) if _whirl_main else whirl_held
	if not held:
		_end_skill()


## Kamień unikalny Młynka: mnożnik zasięgu i obrażeń rosnący z czasem wirowania (1 -> 1 + WHIRL_GROW).
func _whirl_grow() -> float:
	if not _unique("whirl"):
		return 1.0
	return 1.0 + WHIRL_GROW * clampf(_whirl_time / WHIRL_GROW_TIME, 0.0, 1.0)


func _whirl_radius() -> float:
	return WHIRL_RADIUS * _area("whirl") * _whirl_grow()


## 10. poziom Młynka: wybuch co WHIRL_BLAST_EVERY s wirowania - trafia wszystkich w promieniu wiru i odpycha ich od postaci.
func _whirl_blast() -> void:
	whirl_blasts += 1
	var radius := _whirl_radius() * 1.2
	for t in _near_c(_orbit_center(), radius):
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
	for t in _near_c(tip, reach):
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
			for t in _near_c(g.global_position, reach):
				if not _ghost_hits[i].has(t) and t.center().distance_to(g.global_position) <= reach + t.center_height * 0.5:
					_ghost_hits[i].append(t)
					_deal(t, _roll(power), g.global_position, "throw")
	if position.distance_to(target) < 2.0:
		if _state == "throw" and not _bounced and _perk("throw", 0):
			# 5. poziom: odbicie w najbliższego wroga, którego lot nie trafił - potem dopiero powrót
			_bounced = true
			var near: ProtoTarget = null
			var near_d := THROW_BOUNCE_RANGE * _area("throw")
			for t in _near(global_position, near_d):
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
	var near_d := THROW_BOUNCE_RANGE * _area("throw")
	for t in _near(from.global_position, near_d):
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
	for t in _near(at, radius):
		var d := t.global_position - at
		if Vector2(d.x, d.y * 1.6).length() <= radius:
			_deal(t, _roll(power), at, "slam")
			if not echo and not aftershock:
				t.stun(stun_time)
			if shocks.size() < SLAM_SHOCK_MAX:
				shocks.append(t)
	if _unique("slam") and not shocks.is_empty():
		get_tree().create_timer(0.12, false).timeout.connect(_slam_shocks.bind(shocks))
	# jasne kolce SLAM_FX przy postaci wyglądały źle (uwaga autora) - uderzenie to od razu ciemny kolec fali
	if not echo and not aftershock:
		_slam_crack(at)
	else:
		Fx.once(get_parent(), SLAM_SPIKE_FX, SLAM_SPIKE_FRAMES, 16.0, at.round(), SLAM_SPIKE_ANCHOR, 2, _area("slam"))
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


## Pęknięcie Rozłupania: od `at` dalej od postaci biegnie postrzępiona szczelina w ziemi, a za nią po kolei wyskakują
## skalne kolce, raniąc i ogłuszając wrogów na linii.
func _slam_crack(at: Vector2) -> void:
	var dir := at - hero.global_position
	dir = (dir if dir.length() > 4.0 else hero.facing).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var length := SLAM_CRACK * _area("slam")
	var side := dir.orthogonal()
	var crack := Line2D.new()
	crack.width = 2.0
	crack.default_color = Color(0.12, 0.08, 0.05, 0.85)
	crack.z_index = -1
	crack.joint_mode = Line2D.LINE_JOINT_ROUND
	var points := PackedVector2Array()
	var steps := 9
	for i in steps + 1:
		points.append(at + dir * length * i / steps + side * (0.0 if i == 0 else randf_range(-5.0, 5.0)))
	crack.add_point(points[0])
	get_parent().add_child(crack)
	var grow := crack.create_tween()
	grow.tween_method(func(k: float) -> void:
		var n := clampi(ceili(k * steps), 1, steps)
		while crack.get_point_count() < n + 1:
			crack.add_point(points[crack.get_point_count()]), 0.0, 1.0, SLAM_CRACK_TIME)
	grow.tween_interval(1.0)
	grow.tween_property(crack, "modulate:a", 0.0, 0.5)
	grow.tween_callback(crack.queue_free)
	Fx.once(get_parent(), SLAM_SPIKE_FX, SLAM_SPIKE_FRAMES, 16.0, at.round(), SLAM_SPIKE_ANCHOR, 2, _area("slam"))
	for i in SLAM_SPIKES:
		var spot := at + dir * length * (i + 1.0) / SLAM_SPIKES + side * randf_range(-4.0, 4.0)
		get_tree().create_timer(SLAM_CRACK_TIME * (i + 1.0) / SLAM_SPIKES, false).timeout.connect(_slam_spike.bind(spot))


## Skalny kolec w punkcie `spot`: efekt i trafienie (ogłuszenie) wrogów w promieniu.
func _slam_spike(spot: Vector2) -> void:
	if not is_inside_tree() or hero == null or hero.dead:
		return
	var area := _area("slam")
	Fx.once(get_parent(), SLAM_SPIKE_FX, SLAM_SPIKE_FRAMES, 16.0, spot.round(), SLAM_SPIKE_ANCHOR, 2, area)
	for t in _near(spot, SLAM_SPIKE_RADIUS * area + 6.0):
		var d := t.global_position - spot
		if Vector2(d.x, d.y * 1.6).length() <= SLAM_SPIKE_RADIUS * area + 6.0:
			_deal(t, _roll(_power("slam") * SLAM_SPIKE_POWER), spot, "slam")
			t.stun(SLAM_SPIKE_STUN)
	Input.vibrate_handheld(10)


## Kamień unikalny Rozłupania: wokół każdego trafionego (`sources`) fala uderzeniowa rani pobliskich (bez źródła
## i bez kolejnych fal).
func _slam_shocks(sources: Array) -> void:
	var radius := SLAM_SHOCK_RADIUS * _area("slam")
	var power := _power("slam") * SLAM_SHOCK_POWER
	for src in sources:
		if not is_instance_valid(src):
			continue
		var at: Vector2 = src.global_position
		for t in _near(at, radius):
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
		for t in _near_c(fx.global_position, reach):
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
	if cooldown_left(blink_skill) > 0.0:
		_flicker_once = false
		return
	if not _state in ["follow", "windup", "swing", "recover", "k_windup", "k_swing", "k_recover"]:
		return
	_flicker_once = false
	var cost := _blink_cost()
	if not hero.can_pay(cost):
		cast_failed.emit(blink_skill, "mana")
		_flicker_timer = 0.3
		return
	var best := _flicker_target()
	if best == null:
		cast_failed.emit(blink_skill, "target")
		_flicker_timer = 0.3
		return
	if cost > 0:
		hero.spend_mana(cost)
	_flicker_jump(best)
	_last_jump = _clock
	_blink_jumps += 1
	if _perk(blink_skill, 1) and _blink_jumps % Skills.BLINK_SPIN_EVERY == 0:
		_flicker_spin()
	_flicker_timer = FLICKER_INTERVAL / (speed_mult * (1.0 + gem_power(blink_skill, "haste") / 100.0))
	skill_used.emit(blink_skill)


## Najbliższy wróg w zasięgu Mgnienia, z pominięciem FLICKER_MEMORY ostatnich celów - do nich wraca tylko wtedy, gdy nie
## ma nikogo innego, i to od najdawniejszego (null - nikogo).
func _flicker_target() -> ProtoTarget:
	var best: ProtoTarget = null
	var best_d := INF
	for t in _near(hero.global_position, FLICKER_RANGE):
		var d := hero.global_position.distance_to(t.global_position)
		if d > FLICKER_RANGE:
			continue
		var age := _recent_targets.find(t)
		if age >= 0:
			d += FLICKER_RANGE * (1 + age)  # niedawno przebity - tylko gdy nie ma nikogo nowego; najdawniejszy pierwszy
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
	_recent_targets.erase(best)
	_recent_targets.append(best)
	if _recent_targets.size() > FLICKER_MEMORY:
		_recent_targets.pop_front()
	var travel := spot - from
	var body := Vector2(0, -ORBIT_HEIGHT)
	var trail := Fx.once(get_parent(), flicker_trail, 7, FLICKER_FX_FPS, from + body, FLICKER_TRAIL_ANCHOR)
	trail.rotation = travel.angle()
	var stretch := maxf(0.5, (travel.length() - 8.0) / FLICKER_TRAIL_LENGTH)
	trail.scale = Vector2(stretch, minf(stretch, 1.2))  # długi skok - dłuższa smuga, ale nie grubsza
	if flicker_cut:
		var cut := Fx.once(get_parent(), FLICKER_SLASH, 8, FLICKER_FX_FPS, best.center(), FLICKER_SLASH_ANCHOR)
		cut.rotation = travel.angle() + FLICKER_SLASH_TILT * (1.0 if randf() < 0.5 else -1.0)
	var area := _area(blink_skill)
	var hit: Array = []
	for t in _live_targets():
		var c := t.center()
		var on_path := Geometry2D.get_closest_point_to_segment(c, from + body, spot + body).distance_to(c) \
				<= FLICKER_PATH_WIDTH * area + t.center_height * 0.5
		if on_path or c.distance_to(best.center()) <= FLICKER_HIT_RADIUS * area:
			hit.append(t)
			if hit.size() <= FLICKER_HITS_NOW:
				_deal(t, _roll(_power(blink_skill)), spot, blink_skill)
				_blink_kill(t)
			else:  # skok przez dużą kulę wrogów: reszta trafień w kolejnych klatkach (_later)
				_later(t, func() -> void:
					_deal(t, _roll(_power(blink_skill)), spot, blink_skill)
					_blink_kill(t))
	var extra := gem_power(blink_skill, "multi") / 100.0
	if extra > 0.0:
		# Mnożenie: dodatkowe cięcie najbliższego wroga, którego skok nie trafił
		var near: ProtoTarget = null
		var near_d := FLICKER_EXTRA_RANGE
		for t in _near(spot, near_d):
			var d := t.global_position.distance_to(spot)
			if not hit.has(t) and d <= near_d:
				near = t
				near_d = d
		if near:
			var cut2 := Fx.once(get_parent(), FLICKER_SLASH, 8, FLICKER_FX_FPS, near.center(), FLICKER_SLASH_ANCHOR)
			cut2.rotation = randf() * TAU
			_deal(near, _roll(_power(blink_skill) * extra), spot, blink_skill)
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
		hero.add_mana(Skills.BLINK_MANA_ON_KILL * (2 if _perk(blink_skill, 0) else 1))


## 10. poziom Mgnienia: co Skills.BLINK_SPIN_EVERY skoków krótki wir - trafia wszystkich wokół postaci.
func _flicker_spin() -> void:
	_blink_spins += 1
	var radius := WHIRL_RADIUS * _area(blink_skill)
	for t in _near_c(_orbit_center(), radius):
		if t.center().distance_to(_orbit_center()) <= radius:
			_deal(t, _roll(_power(blink_skill) * FLICKER_SPIN_POWER), hero.global_position, blink_skill)
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


## Kamień Echo: po użyciu umiejętności z szansą jej powtórka za GEM_ECHO_DELAY s - bez many (mana_cost 0 dla
## `_echo_pending`) i od nowa z pełnym odnowieniem. Nie dla zwykłego ciosu, skoków, ładowanych, trzymanych i kręgu.
const GEM_ECHO_DELAY := 0.35


func _on_skill_used(id: String) -> void:
	if id == _echo_pending:
		_echo_pending = ""  # to była powtórka - bez kolejnej
		return
	var p := gem_power(id, "echo")
	if p <= 0.0 or id == basic or id == blink_skill or Skills.is_charged(id) or id in ["whirl", "steel_ring"] \
			or randf() >= p / 100.0:
		return
	await get_tree().create_timer(GEM_ECHO_DELAY, false).timeout
	if hero.dead or not is_inside_tree() or _echo_pending != "":
		return
	_echo_pending = id
	_cd.erase(id)
	hero.float_text(tr("Echo!"), -46.0, Gems.color_of(Gems.make("echo")), 11, 0.8)
	if not cast(id):
		_echo_pending = ""
		return
	await get_tree().create_timer(2.0, false).timeout  # bezpiecznik: powtórka nie ruszyła - koniec darmowej many
	if _echo_pending == id:
		_echo_pending = ""


## Tryb deweloperski i testy: zeruje odnowienia.
func reset_cooldowns() -> void:
	_cd.clear()
	_blink_jumps = 0

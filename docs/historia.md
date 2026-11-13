# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

## 13.11.2026 - żywioły i mistrzostwo broni (etap 1: fundament)

- Decyzje autora (ankieta 13.11.2026): żywioły jak w propozycji, najpierw fundament (efekty razem z bronią danego
  żywiołu); potwory na razie biją fizycznie, odporności bohatera później; miecz fizyczny, żywioł dodadzą mu najwyżej
  kamienie; nowe bronie odblokowuje postęp (Wódz na danym poziomie) albo wcześniej dużo złota; jedna broń naraz,
  zmiana w bazie; ulepszenia lochów za złoto, żar na umiejętności; mistrzostwo z pokonanych potworów i bossów.
- `scripts/elements.gd` (`Elements`): fizyczne + 8 żywiołów (ogień, woda, lód, Grom, ziemia, powietrze, Nawia, natura),
  nazwy, kolory, opisy działania (`EFFECTS`), odporności potworów (`MONSTER_RESIST`, na razie puste), obrażenia
  z odpornością `reduce` (odporność najwyżej 75%, wrażliwość do -100%, cały mnożnik z combo najwyżej `MAX_MULT` = x2).
  Jeszcze niepodpięte do walki - pierwsza broń żywiołowa to zrobi.
- `scripts/weapons.gd` (`Weapons`): rodzaje broni (na razie miecz: fizyczny, od początku), pola `unlock` (poziom lochu)
  i `price` (złoto) pod kolejne bronie, mistrzostwo po krzywej poziomów postaci (`xp_to_next`), najwyżej 50.
- Mistrzostwo (`Game.weapon`, `Game.mastery`, `Game.mastery_xp`, `add_mastery`, sygnały `mastery_changed`,
  `skill_unlocked`): arena dolicza je w `_gain_xp` - tyle samo co doświadczenie postaci, więc dla miecza tempo
  się nie zmienia. Progi umiejętności (`Skills.DATA` pole `mastery`): Młynek 3, Rzut 6, Rozłupanie 10, Mgnienie 15
  (jak dawne wymagane poziomy postaci). Odblokowana umiejętność sama wskakuje w wolne miejsce, nad postacią napis
  „Nowa umiejętność: …!” (`ProtoHero.skill_unlocked`, wspólne `float_text`). Limit poziomu umiejętności: połowa
  mistrzostwa (`Skills.level_cap`).
- Ulepszenia umiejętności za żar (`Game.upgrade_skill`, ceny bez zmian liczbowych: 40-200 x poziom), ulepszenia lochów
  za złoto (`Game.buy_upgrade`, ceny 50-1000 bez zmian). Okno umiejętności: żar i pasek mistrzostwa u góry, przy
  nieodblokowanej „od mistrz. N” zamiast „Kup”; okno ulepszeń lochów pokazuje złoto.
- Stary zapis (bez `mastery`, `Game._migrate_mastery`): mistrzostwo miecza = poziom postaci, kupione umiejętności
  i poziomy zostają, wraca złoto za umiejętności (`Skills.LEGACY_PRICE`) i ich poziomy oraz żar za ulepszenia lochów.
- Testy: `tests/test_elements.gd` (nowy), `test_skills.gd` (mistrzostwo, przejście zapisu), `test_base.gd` (złoto).

## 13.11.2026 - głębokie lochy trudniejsze, Mgnienie jak Flicker Strike

- Zgłoszenie autora z testu w oknie deweloperskim: na 100. poziomie lochu za mało potworów, za mało zdrowia i obrażeń
  (postać 15. poziomu wytrzymywała 2-3 ciosy), a Mgnienie ze 100% skrócenia odnowienia dawało prawie nietykalność.
- Siła lochu (`DungeonLevels.power`): `(1 + 0,15 x (poziom-1)) x 1,02^(poziom-1)` - 10. poziom x2,8 (było 2,35),
  50. x22 (było 8,4), 100. x113 (było 16). Premie przedmiotów, które rosną z lochem, idą za tą samą krzywą.
  Doświadczenie za potwory rośnie po staremu liniowo (`DungeonLevels.reward`), żeby postać nie awansowała lawinowo.
- Tłum (`DungeonLevels.crowd`): +1% gęstości strumienia na poziom, najwyżej x1,55; razy ulepszenie „Gęstsza Horda”.
  Twardy limit `ProtoHorde.ALIVE_CAP` = 70 potworów naraz. Pomiar w chmurze (programowy OpenGL): 45 goblinów - 55
  klatek/s, 70 - 43 klatek/s; do sprawdzenia na telefonie.
- Mgnienie (decyzja autora: spam jak Flicker Strike w PoE): bez odnowienia i bez limitu 3 skoków (`Skills` cooldown 0,
  usunięte `BLINK_JUMPS` i przerwa serii), hamulcem jest mana (7 na skok). Wróg zabity skokiem zwraca
  `Skills.BLINK_MANA_ON_KILL` = 2 many (`ProtoWeapon._blink_kill`, też z cięcia Mnożenia i wiru). Skok nie daje już
  nietykalności (`ProtoHero.teleport`). Nowe działania: 5. poziom - zwrot many x2 (było: pierwszy skok serii za darmo),
  10. poziom - wir co `BLINK_SPIN_EVERY` = 5 skoków (było: po ostatnim skoku serii). Kamień unikalny „Nieskończonej Mgły”:
  skoki za pół many (było: bez limitu i odnowienia). Ciosy goblinów nadal chybiają, gdy postać odskoczy w trakcie zamachu.
- Skrócenie odnowienia zostaje do 100% (autor: Mgnienie już go nie potrzebuje).
- Testy: `test_skills.gd` (Mgnienie), `test_horde.gd` (`_test_depth`).

## 13.11.2026 - okno trybu deweloperskiego

- Prośba autora: okno z wszystkimi funkcjami trybu deweloperskiego, każda statystyka postaci ustawiana na dowolną wartość
  (do sufitu) i wejście na dowolny poziom lochu bez przebijania poprzednich - do testów balansu.
- Pauza (`pause_menu.gd`): zamiast dwóch rzędów skrótów i przełącznika nieśmiertelności jeden przycisk „Tryb deweloperski”,
  który otwiera `DevWindow` (`scripts/ui/dev_window.gd`) nad pauzą; „wstecz” zamyka najpierw okno deweloperskie.
- `DevWindow`: nieśmiertelność, „Wszystkie poziomy lochu (bez przebijania)”, stare skróty (stałe `DEV_EMBERS`, `DEV_ITEMS`
  przeniesione z pauzy), poziom postaci przyciskami -10/-1/+1/+10 (`Game.dev_set_level`, 1-50, doświadczenie od zera),
  sekcja „Statystyki”: wiersz z opisem jak na przedmiocie i suwak z −/+/↺ dla obrażeń broni i każdej z 18 premii
  (zmienione - zielone). Suwak zastępuje sumę z przedmiotów, sięga do sufitu `Items.CAPS` albo `DevWindow.STAT_MAX`.
  „Wszystkie z przedmiotów” czyści nadpisania. Bez broni wiersz obrażeń pokazuje zwykły miecz.
- `Game`: `dev_stats` (statystyka -> wartość, `gear()` przez `Items.with_overrides`; obrażenia broni - klucz
  `Items.WEAPON_DAMAGE`, rozrzut x1,4 - `Items.weapon_damage_from`), `dev_all_levels` (`unlocked_level` daje
  `DEV_MAX_LEVEL` = 100), oba zapisywane w `user://settings.cfg` (sekcja `dev`). Zmiana suwaka od razu działa w grze
  (sygnał `inventory_changed`), zapis ustawień przy zamknięciu okna.
- Wybór poziomu przy Watrze (`level_picker.gd`): przy ponad 10 poziomach dochodzą przyciski −10 / +10.
- Test: `tests/test_dev.gd`; zrzuty: `SCRIPT=tools/dev_shots.gd tools/screenshot.sh <prefiks>`.

## 13.11.2026 - premie: obszar, unik, zasięg zbierania, żar

- Wybór autora z punktu „Na później” (więcej statystyk): wszystkie cztery premie, bez nowych kamieni. Każda na każdym miejscu.
- `Items` (`STAT_FORMATS`, `AFFIXES`, `CAPS`): `area_pct` 4-8% (+0,2 na poziom lochu, sufit 100%), `dodge_pct` 2-4% (+0,1,
  sufit 50%), `pickup_pct` 10-20% (+0,5, sufit 200%), `ember_pct` 4-8% (+0,3, sufit 100%). W puli jest teraz 18 premii.
- Obszar: `ProtoWeapon.area_bonus` (procenty) dodaje się do kamienia Szerokość w `_area` - działa na zwykły cios, falę,
  wir, rzut, Rozłupanie i Mgnienie.
- Unik: `ProtoHero.dodge` (0-1) w `take_damage` - chybiony cios daje napis „Unik!” (jasnoniebieski, `_spawn_text`),
  sygnał `dodged` i zwykłą krótką nietykalność (żeby dotyk goblina nie losował co klatkę).
- Zasięg zbierania i żar: `ProtoHorde.pickup_mult` mnoży przyciąganie iskier i łupu (razem z ulepszeniem „Długie ręce”),
  `ProtoHorde.ember_mult` mnoży żar z iskier (także ze skrzyni Wodza; ułamki zbierają się w `_ember_rest`). Więcej żaru
  to też szybciej pełny pasek przyzwania Wodza. Skrót deweloperski idzie przez `add_embers` (bez premii).
  Ustawia je `arena._apply_weapon` (też po zmianie ekwipunku w lochu).
- Okno „Postać” (`hero_stats.gd`): wiersze Unik, Obszar umiejętności, Zasięg zbierania, Żar - widoczne tylko z premią,
  w porównaniu przedmiotów.
- Test: `tests/test_items.gd` (`_test_utility_stats`).

## 13.11.2026 - nowe statystyki przedmiotów, poprawka górnego paska w lochu

- Pomysł autora: więcej statystyk na przedmiotach. Ustalone: 6 nowych premii, wszystkie na każdym miejscu (jak stare 8),
  bazowy krytyk postaci 5% za 150%, liczby jak w propozycji, kamienie bez zmian.
- `Items` (`STAT_FORMATS`, `AFFIXES`, `CAPS`, `DECIMAL_STATS`): `crit_pct` 2-4% (+0,1 na poziom lochu, sufit z przedmiotów
  95% - razem pewny krytyk), `crit_dmg_pct` 10-20% (+0,5), `life_on_kill` 1-2 (z siłą lochu), `cdr_pct` 3-6% (+0,15, sufit
  100% - odnowienie aż do zera; decyzja autora: osiągalne, ale bardzo trudne, jak w PoE),
  `elite_dmg_pct` 6-12% (+0,5), `mana_regen` 0,5-1,2 na s (z siłą lochu; jedno miejsce po przecinku, też przy wczytaniu zapisu).
- Działanie: `ProtoWeapon._deal` - premia przeciw elitom (`ProtoGoblin.elite`) i Wodzowi, krytyk (`crit_chance`,
  `crit_mult`; liczba złota, większa, z „!” - `ProtoTarget.crit_next`, `CRIT_COLOR`), `cooldown_cut` w `_cooldown_base`;
  arena ustawia je w `_apply_weapon` z `HeroStats.crit_chance` / `crit_damage` (bazowe `CRIT_CHANCE` 5, `CRIT_DAMAGE` 150);
  `ProtoHero` - mana na sekundę `HeroLevels.MANA_REGEN` + `mana_regen`; `ProtoHorde._on_died` leczy o `life_on_kill`.
- Okno „Postać”: nowe wiersze (szansa na krytyk, obrażenia krytyczne, odnowa many zawsze; zdrowie za zabicie,
  odnowienie, przeciw elitom - gdy przedmioty coś dają), porównanie przy zakładaniu (`COMPARE_KEYS`; odnowienie - mniej to lepiej).
- Poprawka: wiersz „Loch N · Pokonane · żar · czas” w lochu potrzebował ok. 216 px przy ok. 180 dostępnych - rozpychał
  cały interfejs (czas ucięty za krawędzią, okno „Postać” szersze od ekranu, ucięte „Wróć”). Teraz dwa wiersze:
  „Loch N … czas” i „Pokonane … żar”.
- Test: `_test_new_stats` w `tests/test_items.gd`.

## 13.11.2026 - elitarne potwory

- Ustalone z autorem: elity rzadko od 2. poziomu lochu, cechy Szybki, Tarczowy, Wybuchowy, Dowódczy, nagroda - przedmiot
  i dużo żaru, wygląd - większa, poświata, napis z cechami i pasek zdrowia. Kolczastego (odbijanie obrażeń) odradziłem na
  telefon (auto atak).
- `Elites` (`scripts/elites.gd`, dane): cechy z kolorami, pierwsza elita po 25-35 s, kolejne co 45-65 s; cech najwyżej
  1 (poziomy 2-3), 2 (od 4.), 3 (od 7.), losowo max-1..max; zdrowie x3 (+0,75 za każdą cechę ponad pierwszą), obrażenia x1,3,
  większa o 25%; nagroda: iskra za 10 żaru, przedmiot z wagami skrzyni bossa (`Items.CHEST_WEIGHTS`), doświadczenie x5.
  Szybki: prędkość x1,6, odstęp ataków x0,6. Tarczowy: tarcza 50% zdrowia, wraca po 4 s bez obrażeń (niebieskie liczby,
  bańka, niebieski pasek). Wybuchowy: po śmierci koło 34 px, po 1,2 s wybuch 20 obrażeń x siła poziomu (`ProtoElite.blast`,
  efekt `boss_slam` na pomarańczowo). Dowódczy: gobliny w promieniu 90 px szybsze i silniejsze o 30%, lekko złote
  (`ProtoGoblin.empower`, `hit_damage`, `speed_factor`), krąg na ziemi.
- `ProtoElite` (`scripts/proto/proto_elite.gd`, dziecko goblina, `promote` przed dodaniem do sceny): poświata - shader
  obrysu (1 px pełny + 2 px półprzezroczysty, pulsuje; zdejmowany po śmierci i ucieczce), napis z cechami (8 px), pasek zdrowia.
- `ProtoGoblin`: `elite`, `damage_mult`, `hit_damage()` (też łucznik i osiłek), `_absorb` (tarcza; także osiłek w zamachu
  i podpalenie), `empower`. `ProtoHorde`: `spawn_elite`, `spawn_at(pos, kind, elite_traits)`, `_roll_kind`, sygnał
  `elite_killed` (arena dolicza `HeroLevels.goblin_xp` x (Elites.XP - 1)).
- Test: `_test_elites` w `tests/test_horde.gd`; zrzuty `tools/elite_shots.gd`.

## 13.11.2026 - goblin osiłek (trzeci rodzaj potwora)

- Ustalone z autorem: goblin osiłek od 3. poziomu lochu, grafika ze SpriteKiln, cios w ziemię z czerwonym kołem.
- `ProtoGoblinBrute` (`scripts/proto/proto_goblin_brute.gd`, podklasa `ProtoGoblin`): 150 zdrowia, 28 px/s, z 28 px
  bierze zamach; koło `ProtoTelegraph` (promień 26) 14 px przed nim w stronę postaci, wypełnia się przez 1 s, potem
  maczuga uderza (22 obrażenia x siła poziomu, tylko w kole; efekt `boss_slam` i dźwięk `chief_slam`), 0,45 s powrotu,
  zamach co 2,4 s. Animacja `attack` rusza `ANIM_HIT_AT` s przed uderzeniem (jak u Wodza), uderzenie liczy zegar.
  Ciężki: cięcie w trakcie zamachu tylko rani (bez przerwania), odrzut i odepchnięcie x0,3; ogłuszenie przerywa i gasi koło.
- `DungeonLevels.brute_share`: od `BRUTE_FROM` = 3 udział 8%, +2% na poziom, sufit 15%; `ProtoHorde`: `spawn_at(pos, kind)`
  (`"goblin"`, `"archer"`, `"brute"`), `count(klasa)`, najwyżej `MAX_BRUTES` = 3 naraz, z osiłka iskra za `BRUTE_EMBERS` = 3 żaru.
- `ProtoGoblin.shadow_scale` (większy cień osiłka).
- Grafika: `art/specs/characters/goblin_brute/goblin_brute.yaml` (na bazie goblina) -> `assets/spritekiln/goblin_brute/`.
- Test: `_test_brute` w `tests/test_horde.gd`.

## 13.11.2026 - goblin łucznik (drugi rodzaj potwora)

- Ustalone z autorem: goblin łucznik od 2. poziomu lochu, grafika ze SpriteKiln, strzały do unikania.
- `ProtoGoblinArcher` (`scripts/proto/proto_goblin_archer.gd`, podklasa `ProtoGoblin` - ucieczka przed Wodzem, iskry,
  łup, ogłuszenie, rozpychanie bez zmian): 26 zdrowia (goblin 40), 38 px/s, trzyma dystans 65-130 px (za blisko -
  cofa się), strzał co 2,2 s. Naciąganie: na ziemi czerwona przerywana linia celu (`_AimLine`), podąża za postacią,
  0,3 s przed strzałem staje i jaśnieje (`AIM_LOCK`); strzał 0,63 s po początku (zdarzenie `release` animacji).
  Cięcie w trakcie naciągania przerywa strzał.
- `ProtoArrow` (`scripts/proto/proto_arrow.gd`): strzała z kreatora efektów PixelLab (prośba autora): `arrow_fly`
  (pętla 6 klatek 44x16, własny rysunek strzały 20x8 px - grubsze drzewce i czerwone lotki, czytelne na trawie,
  plus smugi pędu; obracana w kierunku lotu) i `arrow_hit` (błysk, iskry, drzazgi; `Fx.once`), wpisy w
  `pixellab_src/vfx/ids.json`; 115 px/s, 11 px nad ziemią z cieniem,
  trafia w promieniu 8 px od stóp postaci (8 obrażeń x siła poziomu), zasięg 240 px.
- `DungeonLevels.archer_share`: od `ARCHER_FROM` = 2 udział 15%, +3% na poziom, sufit 30%; `ProtoHorde.spawn_at(pos, archer)`,
  `ProtoHorde.archers()`, najwyżej `MAX_ARCHERS` = 6 naraz.
- `ProtoGoblin`: liczby i grafika w zmiennych (`scene_path`, `max_hp`, `speed`, `damage`, `attack_cooldown`,
  `strike_time`, `attack_time`), wczytane sceny w `_scenes` (osobno dla każdego rodzaju), ruch w marszu w `_walk_move`.
- Grafika: `art/specs/characters/goblin_archer/goblin_archer.yaml` (na bazie goblina) -> `assets/spritekiln/goblin_archer/`.
- Test: `_test_archer` w `tests/test_horde.gd`.

## 13.11.2026 - kamienie unikalne umiejętności, Mgnienie z odnowieniem

- Pomysł autora: po jednym unikalnym kamieniu na umiejętność, zmieniającym jej działanie. Ustalone: rzadko ze skrzyni
  Wodza (`Gems.CHEST_UNIQUE` 3% -> 8%, od 5. poziomu lochu, losowa umiejętność), zajmuje zwykłe gniazdo, bez stopni,
  pasuje tylko do swojej umiejętności (`Game.skill_socket_problem` -> "skill"). Identyfikator `unique:<umiejętność>`
  (`Gems.UNIQUE`, `is_unique`, `unique_of`, `has_unique`); `is_support` obejmuje też unikalne. Ikony - złote wersje ikon
  kamieni z Watry (`tools/unique_gem_art.py` -> `assets/watra/unique_gems/`). Skrót deweloperski „+kamienie” daje też unikalne.
- Działanie (`ProtoWeapon`, `_unique`): zwykły cios - Wichrowe Ostrze: każde cięcie wypuszcza falę (efekt
  `legend_wind_crescent` z Watry), 140 px, 260 px/s, przebija, 60% obrażeń cięcia (`_spawn_wave`, `_process_waves`);
  Młynek - Wieczny Wir: bez odnowienia, wiruje do drugiego stuknięcia / puszczenia „Atak” (auto atak - do braku wrogów)
  albo końca many, płaci 1/3 kosztu na sekundę (`WHIRL_DRAIN`), z 10. poziomem wybuch co czas odnowienia
  (`_cooldown_base`, min. 1 s); Rzut - Rykoszet: odbija się od trafionego w najbliższego nietrafionego (90 px), do 3 razy,
  widmowe miecze rozchodzą się od miejsca odbicia (`_ricochet`); Rozłupanie - Drżąca Ziemia: wokół każdego trafionego
  (najwyżej 10) fala 34 px, 50% siły, bez kolejnych fal (`_slam_shocks`, efekt `legend_shockwave` z Watry); Mgnienie -
  Nieskończona Mgła: bez limitu skoków i odnowienia (jak wcześniej).
- Zwykłe Mgnienie (decyzja autora): seria do 3 skoków (`Skills.BLINK_JUMPS`), potem 6 s odnowienia; urwana seria
  (0,6 s bez skoku) też włącza odnowienie (`_end_blink_series`).
- Okno: Młynek z kamieniem pokazuje „25 many, potem 8 na sekundę, bez odnowienia”. Testy: `test_gems.gd` (dane, łup,
  gniazda), `test_skills.gd` (`_test_unique`); zrzuty `tools/unique_shots.gd`.

## 13.11.2026 - poziomy umiejętności

- Ustalone z autorem: 10 poziomów, kolejny za złoto przy kamieniu run (przycisk „Ulepsz” w oknie umiejętności, drugie
  stuknięcie potwierdza), najwyżej połowa poziomu postaci w górę (`Skills.level_cap`: poz. 10 umiejętności od
  19. poziomu postaci). Cena z poziomu n na n+1: `Skills.UPGRADE_PRICE` x n (zwykły cios 40, Młynek 60, Rzut 90,
  Rozłupanie 140, Mgnienie 200 zł; razem do 10. poziomu 45 x cena, np. Mgnienie 9000 zł).
- Każdy poziom: +10% obrażeń (`Skills.level_damage`). Poziomy 3 i 7: -10% many i odnowienia (`level_cost`; zwykły cios -
  +10% szybkości), 4 i 8: +10% obszaru i zasięgu (`level_area`). Sumują się z kamieniami (Pośpiech, Oszczędność, Szerokość).
- Nowe działanie na 5. i 10. poziomie (`Skills.PERKS`, `ProtoWeapon._perk`): zwykły cios - co trzeci cios tnie dwa razy
  pełną siłą / cięcie najbliższego wroga poza łukiem (`STRIKE_CLEAVE_RANGE`); Młynek - 4 s zamiast 3 / wybuch na koniec
  z odepchnięciem (`ProtoTarget.push_away`, goblin; bossy i kukły stoją); Rzut - na końcu lotu odbicie w najbliższego
  nietrafionego wroga (`THROW_BOUNCE_RANGE` 90 px) / drugi pełny miecz (pierwszy widmowy miecz); Rozłupanie - ogłuszenie
  2 s zamiast 1,2 / druga fala po 0,5 s (pełna siła, bez ogłuszenia); Mgnienie - pierwszy skok serii za darmo (seria
  kończy się po `FLICKER_SERIES_GAP` 0,6 s bez skoku) / po ostatnim skoku wir wokół postaci (80% siły).
- Stan: `Game.skill_levels` (zapis, `skill_level`, `skill_upgrade_problem`, `upgrade_skill`; postać od nowa zeruje),
  miecz dostaje go w `Arena._apply_skills`. Okno: „poz. X/10” przy nazwie, mana i odnowienie z premią poziomu, progi 5/10
  (złote - odblokowane), „Następny poziom: …”. Testy w `test_skills.gd` (`_test_levels`), zrzut w `tools/skill_shots.gd`.

## 13.11.2026 - postać zawsze na środku ekranu

- Zgłoszenie autora: przy krawędzi mapy kamera stawała, postać zjeżdżała do rogu ekranu i chowała się pod palcem.
  Ustalone (wersja 1 z dwóch): kamera bez granic, za polaną ciemny pas. Las z grafik Watry wokół polany - może później.
- `Arena`: kamera bez `limit_*`; ciemne tło poza polaną poszerzone (`EDGE_PAD` 700 px - więcej niż pół najwyższego
  ekranu), wzdłuż brzegu miękki cień w stronę tła (4 paski z gradientem, `EDGE_SHADE` 28 px). Postać dalej nie wyjdzie
  za brzeg (`ProtoHero.bounds`). Test w `test_base.gd` (postać w rogu polany na środku ekranu).

## 13.11.2026 - ikonki „Postać” i „Umiejętności” w górnym rzędzie

- Pomysł autora: ekwipunek i umiejętności jednym stuknięciem w ikonkę, nie przez „Menu”. Ustalone: dwie ikonki 44 px
  w górnym rzędzie obok „Menu”, w bazie i w lochu (daleko od kciuka - bez przypadkowego otwarcia w walce), przyciski
  usunięte z pauzy.
- `Arena`: `stats_icon` (portret z Watry, `assets/watra/base/character.png`) otwiera `stats_window` (HeroStats),
  `skills_icon` (księga, `skills.png`) - `skills_window` (w bazie z kupowaniem, w lochu bez); `_top_icon`, `open_stats`,
  `open_skills(not horde)`; „wstecz” zamyka oba okna. „Menu” wyrównane do 44 px. HeroStats i SkillsWindow same
  zatrzymują i wznawiają grę. `PauseMenu` bez `stats_button`, `skills_button`, `stats`, `skills_window`.
- Testy (`test_items`, `test_hero_levels`, `test_skills`, `test_gems`) i narzędzia zrzutów otwierają okna z ikonek.

## 13.11.2026 - czytelniejsze okno „Postać” i kamienie

- Zgłoszenie autora: okno „Postać” zbyt rozległe, wkładanie kamieni nieintuicyjne, nie widać, co kamień robi
  w danej umiejętności. Ustalone: zakładki w „Postać”, „najpierw gniazdo”, opisy pod gniazdami, „najpierw kamień”.
  Na razie bez krótszego porównania przedmiotów (punkt niewybrany).
- `scripts/ui/hero_stats.gd`: okno na cały ekran, u góry poziom, doświadczenie i złoto, na dole zakładki
  „Ekwipunek” / „Statystyki” / „Sakwa (N)” i „Wróć” (`set_tab`, `page_equip`, `page_stats`, `page_pouch`).
  Ekwipunek: 6 miejsc wokół postaci, pod nią zdrowie, obrażenia i ochrona (`key_stats`), torba, sprzedaż hurtem,
  auto sprzedaż - na 16:9 bez przewijania. W opisie przedmiotu gniazda z krótkim opisem pod każdym (`socket_labels`);
  sakwa kamieni szlachetnych w opisie i przeciąganie zniknęły - stuknięcie gniazda otwiera GemPicker.
- `scripts/ui/gem_picker.gd` (`GemPicker`): panel wysuwany od dołu. „Najpierw gniazdo” (`open_skill_socket`,
  `open_item_socket`): tylko pasujące kamienie z działaniem w tym miejscu, ten sam rodzaj w innym gnieździe -
  przygaszony z powodem, kamień w gnieździe z „Wyjmij”, „Włóż” / „Wymień”. „Najpierw kamień” (`open_gem`, stuknięcie
  w sakwie): opis i lista miejsc - umiejętności (w pierwsze wolne gniazdo, `Game.free_skill_socket`) albo przedmioty
  (założone, potem torba - `Game.all_items`, `free_item_socket`) z powodem, gdy się nie da; klucz - „Otwórz”
  gniazdo w umiejętności, dłuto - „Dorób” w przedmiocie (oba z potwierdzeniem). Po włożeniu zamyka się (`changed`).
- Okno umiejętności, zakładka „Kamienie”: pod gniazdami krótki opis (`Gems.short_text`, `SHORT`: „Więcej ostrzy”,
  „Piorun 40%”, puste / zamknięte), stuknięcie otwartego gniazda i kamienia w sakwie otwiera GemPicker (przeciąganie
  zostało), przycisk „Wyjmij” w tej zakładce zniknął (jest w GemPicker). `GemSlot`: kropki stopnia (1-5) u dołu ikony.
- Testy: `test_gems.gd` (nowe drogi wkładania, opisy pod gniazdami, zakładki), zrzuty: `tools/gem_shots.gd`
  (nowe pliki `_1b_gniazdo`, `_1c_kamien`, `_2b_statystyki`, `_2c_sakwa`, `_3b_gniazdo`).

## 12.11.2026 - baza: ulepszenia lochów za żar, kowal, kupiec, pasek skrótów

- Ustalenia z autorem (zasady w `docs/GDD.md`, „Baza i waluty”): żar tylko na ulepszenia lochów, złoto na kowala
  (przeróbka jednej wybranej premii) i kupca (towar w ograniczonej liczbie, nowy po każdym pokonanym Wodzu),
  w bazie chodzenie postacią plus pasek ikon. Liczby zaproponowane przez Claude i zatwierdzone przez autora.
- `scripts/dungeon_upgrades.gd` (`DungeonUpgrades`): 4 ulepszenia po 5 stopni za 50/120/250/500/1000 żaru (razem 7680):
  Gęstsza Horda +10% potworów na stopień, Nauka z walki +8% doświadczenia, Hojność Watry +10% szansy na łup,
  Długie ręce +8 px zasięgu zbierania. Stan `Game.upgrades`, `upgrade_steps`, `upgrade_bonus`, `upgrade_price`,
  `buy_upgrade` (sygnał `Game.embers_changed` - licznik pod Watrą, `ProtoWatra.set_embers`).
- Działanie w lochu (`Arena._apply_upgrades`): `ProtoHorde.density` dzieli odstęp między potworami i mnoży ich
  największą liczbę naraz, `loot_mult` mnoży szanse w `Items.roll_goblin`, `Gems.roll_goblin` i `Gems.roll_chest`
  (nowy parametr `chance_mult`), `reach` dodaje piksele do `ProtoEmber.magnet` (40) i `ProtoLoot.magnet` (36);
  doświadczenie w `Arena._gain_xp` (razem z premią z przedmiotów).
- Kowal (`Items.reroll_affix`, `reroll_price`, `Game.reroll`): premia losowana od nowa (rodzaj spośród tych, których
  przedmiot jeszcze nie ma - może wypaść ten sam - i siła z poziomu przedmiotu); cena 2x cena sprzedaży, każda kolejna
  przeróbka 1,5x droższa (licznik `rerolls` w przedmiocie, zapisywany). Okno `scripts/ui/smith_window.gd`: założone
  i torba, opis przedmiotu od dołu z przyciskiem przy każdej premii, nowa premia błyska, dźwięk kowadła z Watry.
- Kupiec (`scripts/shop.gd`, `Shop`; `Game.shop`, `shop_ready`, `shop_offers`, `restock_shop`, `shop_problem`, `buy_offer`):
  Klucz Runiczny 400, Dłuto Jubilera 250, 2 różne kamienie 1. stopnia (Okruch) po 60, 3 przedmioty magiczne lub rzadkie
  (25%) z najwyższego przebitego lochu za 4x cenę sprzedaży. Pierwszy towar przy pierwszym otwarciu, nowa dostawa
  w `Arena.victory`. Okno `scripts/ui/shop_window.gd` (pełna torba - przedmiotu nie kupi, kamienie tak).
- Okna mają wspólny szkielet `scripts/ui/base_window.gd` (`BaseWindow`: panel na cały ekran, waluta w nagłówku,
  przewijana treść, „Wróć”, kupno drugim stuknięciem - `confirm`, `price_button`). Ulepszenia: `scripts/ui/upgrades_window.gd`,
  otwiera je przycisk „Ulepszenia lochów” w wyborze poziomu (`LevelPicker.upgrades`; po zamknięciu wybór wraca).
- W bazie: kowal (postać `smith` z Watry przy kowadle) i wędrowny kupiec (`traveling_merchant` przy straganie
  `stall_goods`) - `ProtoStash` umie arkusz klatek (`frames`, `rows`) i rekwizyt (`prop`, `prop_offset`); kukły
  przesunięte niżej (`Arena.DUMMIES`). Pasek skrótów `scripts/ui/base_bar.gd` (`BaseBar`): pionowa kolumna 5 ikon
  54 px w dolnym rogu po drugiej stronie niż przyciski walki (leworęczni - po prawej): Watra, Skrzynia, Umiejętności,
  Kowal, Kupiec. Grafiki i dźwięk z Watry w `assets/watra/base/`.
- Test `tests/test_base.gd`; zrzuty `SCRIPT=tools/base_shots.gd tools/screenshot.sh <prefiks>`. W `test_horde.gd`
  i `test_hero_levels.gd` przesunięte punkty „pustego miejsca” (teraz stoją tam pasek skrótów i kukła).

## 12.11.2026 - kamienie w umiejętnościach i ekwipunku (rozwój postaci, część 4)

- Ustalenia z autorem: kamienie to łup z lochu (od 3. poziomu lochu - decyzja autora; rzadko gobliny, częściej skrzynia
  Wodza), 5 stopni jak przedmioty (Okruch, Odłamek, Kamień, Szlifowany, Królewski; stopień = `Items.tier_for` poziomu).
  W umiejętności zmieniają działanie (8 rodzajów), w przedmiocie premia zależy od miejsca (4 rodzaje z Watry).
  Umiejętność: 5 gniazd, 2 otwarte, kolejne otwiera rzadki Klucz Runiczny (po jednym na gniazdo; pomysł autora - duża
  nagroda). Przedmiot: 1 gniazdo, bardzo rzadko 2 od razu (magiczny 1%, rzadki 3%), drugie dorabia rzadkie Dłuto Jubilera.
  Osobna sakwa (stosy, bez limitu). Wkładanie stuknięciem (kamień, potem gniazdo) albo przeciąganiem; wyjmowanie za darmo.
- `scripts/gems.gd` (`Gems`): identyfikator „rodzaj:stopień” (klucz `skill_key`, dłuto `chisel`), `SUPPORT` (Mnożenie,
  Szerokość, Żar, Szron, Piorun, Pośpiech, Oszczędność, Krwiopijca - siła na stopniach w `values`, opis według umiejętności
  w `skills`), `JEWELS` (rubin, szafir, szmaragd, onyks; cecha według grupy miejsc broń / strój / biżuteria) i `JEWEL_VALUES`,
  łup `roll_goblin` (1,2% kamień, 0,15% klucz lub dłuto), `roll_chest` (80% + 30% kamień, klucz 4% i dłuto 6%, +0,5 pkt
  za każdy poziom ponad 3., sufit 15% i 20%), `skill_power`. Ikony z Watry: `assets/watra/gems/` (kamienie, gniazdo,
  `rune_ascend` - klucz, `rune_polish` - dłuto) i `assets/watra/supports/`.
- `Game`: `gems` (sakwa), `skill_gems`, `skill_open` (w zapisie), `add_gem`, `gem_list`, `skill_socket_problem`
  (jeden rodzaj raz w umiejętności), `socket_skill` / `unsocket_skill`, `open_skill_socket`, `socket_item` /
  `unsocket_item` / `add_socket` (przedmiot zmieniany w miejscu), sprzedaż oddaje kamienie do sakwy, `dev_gems`
  (skrót „+kamienie” w pauzie), „Od nowa” zeruje.
- `Items`: `sockets` w przedmiocie (stare zapisy dostają jedno gniazdo), premie kamieni w `totals`, `socket_lines`.
- Walka (`ProtoWeapon`): `skill_gems`, każde trafienie przez `_deal` - Żar podpala (% trafienia przez 3 s), Szron spowalnia
  (2 s), Krwiopijca leczy, Piorun przeskakuje na 2 wrogów do 70 px (raz na klatkę), Oszczędność w zwykłym ciosie oddaje manę;
  `mana_cost`, `cooldown_full` (przyciski walki pokazują odnowienie z Pośpiechem), `_area` (Szerokość); Mnożenie: drugie
  cięcie zwykłego ciosu, widmowy miecz w Młynku, 3 miecze wachlarzem w Rzucie (`_ghosts`), druga fala Rozłupania,
  dodatkowe cięcie przy skoku Mgnienia. `ProtoTarget`: `burn`, `slow`, `speed_factor`, `burn_tick` (gobliny bez odrzutu),
  węzeł `_Status` rysuje płomyki i szronowy krąg. `ProtoHero.heal`, `add_mana`.
- Łup na ziemi: `ProtoLoot` z `{"gem": id}` (zawsze do sakwy, `name_of` / `color_of` / `icon_of`), gobliny (`ProtoHorde`)
  i skrzynia Wodza (arena dokłada `Gems.roll_chest`).
- Interfejs: `scripts/ui/gem_slot.gd` (`GemSlot` - okrągłe pole 44+ px, liczba sztuk, kłódka z kluczem, przeciąganie);
  okno umiejętności - zakładki „Miejsca” / „Kamienie” (gniazda wybranej umiejętności, sakwa, „Wyjmij”, klucz - drugie
  stuknięcie potwierdza, małe ikony kamieni w wierszach); okno „Postać” - sakwa pod torbą (stuknięcie - opis), w opisie
  przedmiotu gniazda, kamienie szlachetne i „Dłuto” (drugie stuknięcie potwierdza).
- Test `tests/test_gems.gd`, zrzuty `tools/gem_shots.gd`.

## 12.11.2026 - umiejętności miecza w odblokowanych miejscach

- Ustalenia z autorem: 4 umiejętności - Młynek, Rzut mieczem, Rozłupanie Ziemi, Mgnienie; kupowane za złoto w bazie
  przy nowym obiekcie (kamień run), stała cena i wymagany poziom (100 zł / poz. 3, 300 / 6, 800 / 10, 1500 / 15);
  rytm średni (15-25 many, odnowienie 4-8 s, mana +3/s). Mgnienie na prośbę autora działa jak w Watrze (niżej). Pomysł autora: zwykły cios też jest umiejętnością - można
  go przestawić, a pod duży przycisk dać inną; ta podlega auto atakowi. Przy braku many albo w czasie odnowienia
  duży przycisk tnie zwykłym ciosem (zgoda autora). Mgnienie nie może stać pod dużym przyciskiem (auto atak wrzucałby
  postać w hordę). Przypisywanie w oknie umiejętności stuknięciem albo przeciąganiem.
- `scripts/skills.gd` (`Skills`): dane (`DATA` - nazwa, ikona, mana, odnowienie, cena, poziom, `main`, `range` dla
  auto ataku, `power` - mnożnik cięcia), `ORDER`, `SLOTS` (0 - duży przycisk), `can_be_main`, `open_slots`.
- `Game`: `skills_owned`, `skill_slots` (w zapisie), `can_buy_skill`, `buy_skill` (wstawia w pierwsze wolne małe
  miejsce), `slot_open`, `assign_skill` (zamiana miejsc; to, co nie może stać pod „Atak”, zostawia go pustym),
  `clear_skill_slot`, `main_skill` (pusty „Atak” = zwykły cios), `dev_skills`, sygnał `skills_changed`; „Od nowa” zeruje.
- `ProtoHero`: odnawianie many (`HeroLevels.MANA_REGEN` = 3/s), `spend_mana`, `teleport` (skok Mgnienia: gasnący
  cień w miejscu startu, 0,15 s nietykalności, lądowanie w granicach areny i poza przeszkodami).
- `ProtoWeapon`: `cast` (mały przycisk; w trakcie innego ruchu - kolejka), `main_skill`, `can_use`, `cooldown_left`,
  sygnały `cast_failed`, `skill_used`. Młynek: 3 s wiru (2,2 obrotu/s), co 0,3 s 0,6 cięcia w promieniu 48 px,
  efekt `whirl` z Watry. Rzut: lot 130 px (300 px/s) i powrót (340 px/s), 1,5 cięcia raz w każdą stronę. Rozłupanie:
  wzlot nad cel (do 70 px), spadek, fala 46 px (spłaszczona) 2,2 cięcia i ogłuszenie 1,2 s, efekt `ground_slam`
  z Watry, drżenie kamery. Mgnienie jak w Watrze: dopóki palec trzyma przycisk (`flicker_held`; samo stuknięcie -
  jeden skok), co 0,32 s skok na wylot przez najbliższego wroga w zasięgu 150 px (poprzedni cel tylko, gdy nie ma
  innego), lądowanie 18 px za nim, 1,2 cięcia w pasie wzdłuż drogi i w promieniu 30 px od celu, 7 many za skok,
  bez odnowienia, bez wroga - drgnięcie przycisku; efekty `flicker_trail` i `flicker_hit` z Watry.
  `ActionCluster.release_all` puszcza też małe przyciski (pauza, okna, śmierć). Efekty: `pixellab_src/vfx/` + `ids.json` (z Watry) -> `python tools/vfx_art.py`.
- `ProtoTarget.stun` (domyślnie nic - Wódz i kukły), `ProtoGoblin.stun` (stoi, nie atakuje, szarzeje).
- Przyciski walki: `ActionCluster.show_skills` (ikony z miejsc), `button(slot)`; `ActionButton.set_state` (ciemny
  wycinek z sekundami odnowienia, niebieska ikona przy braku many), `deny` (drgnięcie). Arena: `_apply_skills`,
  `_on_skill_pressed`, `_update_skill_buttons`.
- Kamień run w bazie po drugiej stronie Watry (`Arena.RUNE_POS`, `ProtoStash` z `texture`/`title`/`sprite_scale`;
  grafika `assets/watra/rune_stone.png` z Watry) otwiera okno umiejętności z kupnem.
- `scripts/ui/skills_window.gd` (`SkillsWindow`): przewijana lista (ikona, mana i odnowienie, opis, cena/poziom,
  „Kup” z „Na pewno?”), na dole rząd miejsc „Atak” + 1-4 (zablokowane z poziomem), „Zdejmij”, „Wróć”; stuknij
  umiejętność, potem miejsce, albo przeciągnij (`scripts/ui/skill_slot.gd`, `SkillSlot`); z miejsca na listę - zdjęcie.
  Z pauzy („Umiejętności”) w lochu bez kupowania. Ikony z Watry: `assets/watra/skills/` (whirlwind, lunge, ground_slam, flicker).
- Pauza: „Auto atak (duży przycisk)”, skrót deweloperski „+umiejętności” (drugi rząd skrótów).
- Test `tests/test_skills.gd`, zrzuty `tools/skill_shots.gd`.

## 12.11.2026 - skrzynia w bazie z zakładkami za złoto

- Prośba autora; ustalone: 1 zakładka 20 miejsc na start, kolejne za 100, 300, 800, 2000 złota (razem 5),
  przenoszenie stuknięciem z przyciskiem albo przeciąganiem.
- `Game`: `stash` (lista zakładek), `STASH_TAB_SIZE`, `STASH_TAB_PRICES`, `next_tab_price`, `buy_stash_tab`,
  `to_stash`, `from_stash`, `stash_all`; w zapisie; „Od nowa” czyści skrzynię.
- `scripts/proto/proto_stash.gd` (`ProtoStash`): skrzynia z Watry obok Watry (`Arena.STASH_POS`), otwiera okno
  stuknięciem albo podejściem (ponownie dopiero po odejściu), przeszkoda dla postaci.
- `scripts/ui/stash_window.gd` (`StashWindow`): zakładki 1..N (44 px) i „+ zakładka N” (drugie stuknięcie „Kupić za N?”),
  siatka zakładki 5x4 i torba 5x4 (pola 48 px), opis przedmiotu z „Do skrzyni” / „Do torby”, „Wszystko do skrzyni”,
  „Wróć”; zatrzymuje grę, „wstecz” zamyka najpierw opis. `scripts/ui/item_slot.gd` (`ItemSlot`): pole z przeciąganiem
  (drag and drop Godota, palec przez emulację myszy) na drugą siatkę.
- Test `tests/test_stash.gd`, zrzuty `tools/stash_shots.gd`.

## 12.11.2026 - usprawnienia: pasek żaru, powiadomienia o łupie, sprzedaż hurtem, „Na pewno?” przy wyjściu

- Prośby autora. Pasek żaru pogrubiony do 11 px z liczbami „zebrane / 100” (`Arena.ember_text`).
- Powiadomienia o łupie pod paskami u góry (`Arena.notify_loot`, `loot_feed`): ikona i napis w kolorze rzadkości
  („Podniesiono: …”, „Sprzedano: … (+N złota)”, „Torba pełna - sprzedano: …”), najwyżej 4 naraz, gasną po 2,5 s.
- Okno „Postać”: pod torbą „Sprzedaj zwykłe” i „Sprzedaj magiczne i rzadkie” - pierwsze stuknięcie pokazuje
  „Na pewno? +N złota”, drugie sprzedaje (`Game.sell_all`, `sell_all_price`); przełącznik „Sprzedawaj zwykłe od razu
  po podniesieniu” (`Game.auto_sell_common`, `settings.cfg` sekcja `items`; `ProtoLoot` -> `Game.sell_loot`).
  Sygnał `ProtoLoot.sold` ma teraz `bag_full`; okno wyniku: „Łup sprzedany od razu: +N złota”.
- Pauza w lochu: „Uciekaj do bazy” i „Menu główne” pytają „Na pewno?” (`PauseMenu._leave`, ponowne otwarcie
  pauzy kasuje pytanie). Skrót deweloperski przemianowany na „+5 łupu” (nie mieścił się).

## 12.11.2026 - przedmioty: procenty rosną płynnie z lochem

- Decyzja autora (wariant A): premie procentowe i stała cecha butów i pierścienia rosły skokami co stopień
  (co 4 lochy) i stawały od lochu 17. Teraz rosną z każdym poziomem lochu (`Items.AFFIXES[...].per_level`):
  obrażenia +0,6, szybkość ataku +0,4, ruch +0,2, ochrona +0,2, doświadczenie +0,4 na poziom; buty i pierścień
  +0,2 (`BASE_PCT_PER_LEVEL`). Liczby stałe bez zmian (x `DungeonLevels.power`), sufity sumy (`CAPS`) zostają.

## 12.11.2026 - przedmioty (rozwój postaci, część 2)

- Ustalenia z autorem: 6 miejsc (broń, hełm, zbroja, buty, pierścień, amulet), łup ze skrzyni Wodza i rzadko
  z goblinów, 3 rzadkości z 1-4 premiami, okno ekwipunku razem z oknem „Postać”, torba 20 miejsc, siła przedmiotu
  z poziomu lochu, niepotrzebne sprzedaje się za złoto (nowa waluta), skrót deweloperski „+5 przedm.”.
- `scripts/items.gd` (`Items`): dane i losowanie. Stopień (wygląd i nazwa z Watry: żelazny, stalowy, mithrilowy,
  runiczny, smoczy) co 4 poziomy lochu (`tier_for`). Stała cecha miejsca (`BASE`): broń - obrażenia cięcia 15-21
  (+12% na poziom lochu, ±8%; zastępują zwykły miecz 14-20), hełm +8 i zbroja +18 zdrowia (x `DungeonLevels.power`),
  buty +4% ruchu, pierścień +4% obrażeń (+1 na stopień), amulet +10 many. Premie (`AFFIXES`, bez powtórzeń): zdrowie,
  mana, % obrażeń, % szybkości ataku, % szybkości ruchu, regeneracja zdrowia, % ochrony, % doświadczenia; sufity sumy
  (`CAPS`): ochrona 50%, ruch 50%, szybkość ataku 75%. Rzadkości: zwykły 0, magiczny 1-2, rzadki 3-4 premie; wagi
  goblina 65/28/7, skrzyni 35/45/20. Goblin upuszcza przedmiot z szansą 2,5% (`GOBLIN_DROP`), skrzynia Wodza 3
  (`roll_chest`, pierwszy co najmniej magiczny). Cena: 5 złota x siła lochu x rzadkość (1/2/4). Zapis trzyma tylko
  identyfikatory i liczby (`normalize` przy wczytaniu). `totals` - suma cech założonych.
- `Game`: `bag` (najwyżej `BAG_SIZE` 20), `equipped`, `gold` w zapisie; `add_item`, `equip` (zamiana - stary wraca
  na jego miejsce w torbie), `unequip`, `sell`, `dev_items`, `gear()`, sygnał `inventory_changed`; „Od nowa” czyści też
  przedmioty i złoto. Przedmioty zostają po śmierci i ucieczce (jak doświadczenie).
- `scripts/proto/proto_loot.gd` (`ProtoLoot`): przedmiot na ziemi - ikona, poświata w kolorze rzadkości, rzadki ze
  słupem światła; leci do postaci z 36 px, przy pełnej torbie odskakuje z napisem „Torba pełna!” i czeka, aż postać
  odejdzie. Łup ze skrzyni przy pełnej torbie sprzedaje się od razu (`sell_if_full`). Dźwięki z Watry (Kenney, CC0):
  `dropLeather`, `handleSmallLeather`, `glass_002` (rzadki), `handleCoins` (sprzedaż).
- Działanie cech: `ProtoHero.apply_gear` (zdrowie, mana, `move_mult`, `regen`, `protection`; zmiana ekwipunku nie
  leczy), `ProtoWeapon.damage` i `speed_mult` (cały cios szybszy), doświadczenie x premia w `Arena._gain_xp`; arena
  słucha `Game.inventory_changed`. Okno wyniku: „Przedmioty: N” (`RunResult.add_loot_lines`).
- `HeroStats` (okno „Postać i ekwipunek” w pauzie): poziom, 6 miejsc wokół Wojciecha (po lewej hełm, zbroja, buty,
  po prawej broń, amulet, pierścień), złoto, statystyki z przedmiotami (ochrona, regeneracja, doświadczenie tylko gdy
  niezerowe), torba 5x4 (pola 52 px). Opis przedmiotu przy dolnej krawędzi: cechy, „Po założeniu:” zmiany statystyk
  (zielone/czerwone), „Załóż”/„Zdejmij”, „Sprzedaj N” (magiczny i rzadki - „Na pewno?”), „Zamknij”; „wstecz” zamyka
  najpierw opis. Okno przewija się na 16:9. Ikony: `assets/watra/items/` (z Watry, z wersjami `_magic`, `_rare`).
- Test `tests/test_items.gd`, zrzuty `tools/item_shots.gd`.

## 12.11.2026 - liczby na paskach, mana i okno „Postać”

- Prośba autora: liczby na paskach zdrowia, many i doświadczenia oraz ekran statystyk („ciężko stwierdzić, co daje poziom”).
- Pusty pasek między zdrowiem a doświadczeniem to teraz **pasek many** (niebieski, 11 px, `Arena.mana_bar`). Mana:
  `HeroLevels.max_mana` = 50 + 5 na poziom, `ProtoHero.max_mana`/`mana`, sygnał `mana_changed`; na razie nic jej nie
  zużywa (czeka na umiejętności), awans napełnia ją do pełna.
- Liczby „obecne / największe” na środku pasków (`Arena._bar_text`, `health_text`, `mana_text`, `xp_text`; na
  najwyższym poziomie „Najwyższy poziom”). Pasek doświadczenia pogrubiony do 11 px.
- `scripts/ui/hero_stats.gd` (`HeroStats`): okno „Postać” pod przyciskiem w oknie pauzy (w lochu i w bazie) - poziom,
  doświadczenie, zdrowie, mana, obrażenia miecza (`damage_range`), szybkość ataku (`attacks_per_second` = 1 / (rozbieg
  + cięcie + powrót + odpoczynek) = 1,08/s), szybkość ruchu, miejsca na umiejętności; w zielonej kolumnie przyrost
  z następnym poziomem (+10 zdrowia, +5 many, +6% obrażeń, „na poz. 6”). „Wstecz” Androida najpierw zamyka to okno
  (`PauseMenu.back`).

## 12.11.2026 - rozwój postaci: poziomy doświadczenia, auto atak, skróty deweloperskie

- Ustalenia z autorem: zaczynamy od poziomów (przedmioty w kolejnej sesji); doświadczenie za każdego goblina i dużo
  za Wodza, śmierć go nie zabiera; awans daje statystyki (zdrowie, obrażenia, pełne leczenie) i odblokowuje miejsca
  na umiejętności; cienki pasek u góry, efekt awansu, podsumowanie w oknie wyniku; skróty deweloperskie w pauzie;
  auto atak w menu (prośba autora - tylko podstawowy cios).
- `scripts/hero_levels.gd` (`HeroLevels`): `xp_to_next(n)` = 50 * n^1,4 (50, 132, 233, 350, 476 … 1256 na 10.),
  `max_hp` = 100 + 10 na poziom, `damage_mult` = 1 + 0,06 na poziom, miejsca na umiejętności na poziomach 3, 6, 10, 15
  (`SKILL_SLOT_LEVELS`), `goblin_xp` = 2 x siła lochu, `chief_xp` = 60 x siła lochu (`DungeonLevels.power`), sufit 50.
- `Game`: `hero_level`, `hero_xp` w zapisie, `add_xp` (kilka awansów naraz, zwraca liczbę awansów), sygnały
  `xp_changed` i `leveled_up`; awans zapisuje od razu, zwykłe doświadczenie przy `save_if_dirty` (pauza, koniec wyprawy,
  zmiana sceny, przełączenie aplikacji - `Game._notification`). Ustawienie `auto_attack` (`settings.cfg`).
  Tryb deweloperski: `dev_level_up`, `reset_hero`.
- `ProtoHero`: `max_hp` z poziomu (`set_level`), `level_up` - pełne zdrowie, złoty błysk, słup światła z kręgiem
  (`_LevelGlow`, rysowany w kodzie), napis „Poziom N!”, dźwięk `assets/watra/level_up.ogg` (Kenney `jingles_PIZZI16`
  z Watry, CC0), wibracja 60 ms.
- `ProtoWeapon`: `damage_mult` (obrażenia x poziom), `auto_attack` - cios rusza sam, gdy cel jest w zasięgu `REACH`
  (`_nearest`); bez celu miecz czeka.
- Arena: wiersz „Poz. N” + złoty pasek doświadczenia 5 px (prośba autora, wcześniej niebieski) (`_make_xp_row`) - w lochu pod paskiem zdrowia, w bazie
  obok „Menu”; w lochu między zdrowiem a doświadczeniem pusty pasek 6 px na później (`spare_bar`, prośba autora); poziom lochu w pasku to teraz „Loch N”. Doświadczenie z goblinów (`kills_changed`) i Wodza
  (`_on_chief_died`), `run_xp` do podsumowania. `RunResult.add_xp_lines`: „Doświadczenie: +N”, „Awans na poziom N!”.
- `ActionButton.locked_level`: kłódka i „Poz. N” na zablokowanym miejscu, `unlock_flash` przy odblokowaniu
  (`ActionCluster.set_hero_level`).
- Okno pauzy: przełącznik „Auto atak (podstawowy cios)”, rząd skrótów deweloperskich „+1 poz.”, „+100 żaru” (w lochu
  do paska wyprawy - szybkie przyzwanie Wodza, w bazie do Watry - sygnał `dev_embers`), „Od nowa” (drugie stuknięcie
  „Na pewno?”). Okno przewija się, gdy nie mieści się na ekranie (`_fit`).
- Test `tests/test_hero_levels.gd`, zrzuty `tools/level_shots.gd`.

## 12.11.2026 - tryb deweloperski: nieśmiertelność

- Prośba autora (Wódz jest „trudnawy”, do testów balansu): w oknie pauzy przełącznik „Tryb deweloperski:
  nieśmiertelność” (`PauseMenu.immortal_toggle`, `Game.dev_immortal`, zapis w `user://settings.cfg`, sekcja `dev`).
- `ProtoHero.immortal`: zdrowie schodzi normalnie, a zamiast śmierci wraca do pełna ze złotym błyskiem; `deaths` liczy
  uniknięte zgony (`death_avoided`). W lochu czerwony licznik „Zgony: N” pod paskiem (widoczny tylko w trybie
  deweloperskim), okno zwycięstwa pokazuje „Zgony (nieśmiertelność): N”.
- Test w `tests/test_horde.gd`.

## 12.11.2026 - Wódz Goblinów, koniec wyprawy i poziomy lochu

- Ustalenia z autorem: pasek żaru 100 (`DungeonLevels.SUMMON_COST`), przyzwanie przyciskiem przy pełnym pasku, gobliny
  uciekają z piskiem, Wódz Goblinów (duży, w trofeach) z trzema atakami z ostrzeżeniem: cios w ziemię, okrzyk wojenny,
  rzut tasakiem; nagroda - skrzynia (na razie żar, potem łup); okno zwycięstwa; pokonanie bossa odblokowuje następny
  poziom, wybór poziomu przy Watrze (do najwyższego odblokowanego). Ucieczka i śmierć gaszą żar (zgodnie z GDD) - przycisk
  „Do bazy” w lochu usunięty, w pauzie „Uciekaj do bazy” z ostrzeżeniem (`PauseMenu.leave_note`).
- `scripts/dungeon_levels.gd` (`DungeonLevels`): `power(level)` = 1 + 0,15 na poziom (zdrowie i obrażenia goblinów i Wodza),
  `chest_embers(level)` = 20 + 10 na poziom. `Game`: `best_level` (najwyższy przebity), `dungeon_level` (wybrany),
  `unlocked_level()`, `beat_level()`; oba w zapisie.
- Arena w lochu: pasek żaru pod paskiem zdrowia (pulsuje, gdy pełny), „Poz. N” w pasku, przycisk „Przyzwij Wodza” (`summon_chief`;
  po ocenie na telefonie przeniesiony na górę pod pasek żaru - prośba autora, żeby nie przyzwać go przypadkiem): zjada 100 żaru (nadwyżka zostaje w liczniku), `ProtoHorde.call_boss` (strumień staje,
  `scatter` - gobliny `flee`: biegną od postaci 120 px/s, gasną po 1,4 s, piszczy najwyżej 6 - `tools/goblin_squeak.py`
  -> `assets/sounds/goblin_squeak_*.ogg`), Wódz 110 px nad postacią, pasek zdrowia Wodza pod górnym rzędem.
  Etapy `phase`: horde, boss, loot, won. Ziemia ma `z_index` -10 (ciała i ostrzeżenia na -1 były pod trawą).
- `proto_chief.gd` (`ProtoChief`): 700 zdrowia x siła (ok. 25 s cięcia), prędkość 30, wejście z rykiem i wstrząsem kamery
  (1,4 s nietykalności). Ataki co 1,1 s: cios w ziemię z bliska (koło 46 px, 1,1 s ostrzeżenia, 25 obrażeń), rzut tasakiem
  z daleka (koło 20 px pod postacią, 1 s, 20 obrażeń, powrót jak bumerang - 10), okrzyk co 9 s (fale, po 0,9 s 5 goblinów
  wokół przez `ProtoHorde.spawn_at` - dają iskry). Animacje modelu: `slam`, `throw`, `roar` (cios w `ANIM_HIT_AT`), do czasu
  modelu zastępczy goblin x1,6, czerwonawy (`ANIM_FALLBACK`). Dźwięki z Watry: `chief_roar` (horde_roar), `chief_slam`,
  `cleaver_land` (Kenney CC0).
- `proto_telegraph.gd` (`ProtoTelegraph`): czerwone koło z Watry (`telegraph.gd`), spłaszczone 0,6. `proto_cleaver.gd` -
  tasak rysowany w kodzie ze smugą `cleaver_spin`.
- Model Wodza w SpriteKiln (zatwierdzony przez autora): `art/specs/characters/goblin_chief/goblin_chief.yaml` (extends
  goblina, kość `big` x1,6, ok. 42 px + rogi, klatka 80; czaszka z rogami, farba wojenna, futrzana narzuta, kły, wielki
  tasak). Animacje: idle 1200 ms, walk 1000 ms (30 px/s = `ProtoChief.SPEED`), slam 920 ms (`hit` 400), throw 580 ms
  (`release` 300, kanał `knife_show` chowa tasak po rzucie), roar 1160 ms (`roar` 270), hit 210 ms, death 1490 ms.
  Eksport: `assets/spritekiln/goblin_chief/`.
- Efekty (ustalenie autora - z Watry, czego brak - w kreatorze PixelLab): z Watry `boss_appear` (wejście), `boss_slam`
  (cios), `boss_death` (śmierć), `chief_roar` (ryk Biesa przebarwiony - `vfx_art.py` umie teraz `source`, `hue`, `boost`);
  nowe w kreatorze: `cleaver_spin` (smuga wirującego tasaka, pętla) i `cleaver_impact` (iskry, kurz, odłamki przy upadku).
  `Fx.once` ma skalę `size`.
- `proto_chest.gd` (`ProtoChest`): skrzynia z Watry (`assets/watra/chest.png`) spada 1,4 s po śmierci Wodza, otwiera się
  z bliska (22 px) albo stuknięciem, sypie iskry (duże po 5), które po 0,5 s same lecą do postaci (`ProtoEmber.magnet`,
  `spread`, `delay`). Po 2,2 s `victory()`: `_bank` (cały żar z wyprawy), `Game.beat_level`, `RunResult.show_victory`
  („Następny poziom: N” / „Powrót do bazy”).
- `scripts/ui/level_picker.gd` (`LevelPicker`): dotknięcie Watry - ◀ Poziom N ▶, siła potworów, skrzynia Wodza, „Wejdź” /
  „Anuluj” w dolnej części, pauza; „wstecz” zamyka.
- Test `tests/test_horde.gd` (`_test_chief` i wybór poziomu), zrzuty `SCRIPT=tools/boss_shots.gd tools/screenshot.sh <prefiks>`.

## 12.11.2026 - iskry żaru dla Watry

- Ustalenia z autorem: iskry przyciągane z bliska, po śmierci przepadają (do Watry tylko przy powrocie), żar na razie
  tylko liczony (na co go wydawać - później), 1 iskra z goblina, co 20. goblin duża (5).
- `scripts/proto/proto_ember.gd` (`ProtoEmber`): wyskok z ciała, migotanie, poświata; od 40 px leci do postaci
  (przyspiesza 400 px/s²), `collected(value)`, brzęk (Kenney `glass_002`/`glass_005` z Watry -> `assets/watra/ember_pickup*.ogg`).
  Grafika z `tools/ember_art.py` -> `assets/effects/ember.png` (rząd 0 mała 1 żaru, rząd 1 duża 5, po 4 klatki 13x13).
- `ProtoHorde`: `embers`, `embers_changed`, `BIG_EVERY = 20`. Arena w lochu: ikona żaru (`assets/watra/ember_icon.png`
  z Watry) i licznik w pasku, przycisk „Do bazy” w górnym rzędzie (`return_to_base`); wyjście z okna pauzy też zanosi
  żar (`PauseMenu.leaving`). Śmierć: okno wyniku pokazuje „Zgasło żaru: N”.
- `Game`: zapis gry `save_path` (JSON `{"embers": N}`), `load_game`, `save_game`, `bank_embers` (zapis od razu),
  `embers_brought` - baza pokazuje „+N” nad Watrą z rozbłyskiem. `ProtoWatra`: „Żar Watry: N” pod ogniem, poświata
  rośnie logarytmicznie do 1,6x przy 1000 żaru (`glow_size`).
- Test `tests/test_horde.gd` (żar: wypadanie, przyciąganie, duża iskra, powrót, zapis, gaśnięcie po śmierci).

## 12.11.2026 - pierwszy potwór (goblin) i loch z Hordą

- Ustalenia z autorem: goblin, ciągły strumień, średnie obrażenia; polana z kukłami to baza, wejście do lochu przez
  dotknięcie Watry; po śmierci wynik i przyciski „Jeszcze raz” / „Powrót do bazy”.
- Goblin w SpriteKiln: `art/specs/characters/goblin/goblin.yaml` (dziedziczy po humanoidzie; ok. 27 px, głowa x1.4,
  długie uszy `ear_L/R`, skóra oliwkowa z chłodnymi cieniami, świecące bursztynowe oczy, tunika, tasak `knife` na
  `wrist_R`, sockety `knife_hit`/`knife_tip`). Animacje: idle 6x150 ms, walk 8x90 ms (ziemia 42 px/s = `ProtoGoblin.SPEED`
  - zmiana prędkości w grze wymaga zmiany chodu, inaczej stopy się ślizgają), attack 560 ms (`windup` 0 ms, `hit` po
  300 ms, pionowa smuga przez kość `fxspace`), hit 3x70 ms, death 1280 ms (pada na plecy). QA bez błędów.
  Eksport: `assets/spritekiln/goblin/` (scena `goblin.tscn` z `KilnSprite2D`), dodatek `addons/spritekiln` (bez
  włączania wtyczki w project.godot - skrypt działa sam).
- `scripts/proto/proto_target.gd` (`ProtoTarget`): wspólna baza celów miecza (`center`, `alive`, `take_damage`,
  `spawn_number`); `ProtoDummy` i `ProtoGoblin` po niej dziedziczą. Miecz (`ProtoWeapon._live_targets`) bije listę
  `targets` i grupę `ProtoWeapon.TARGETS` (potwory dopisują się same), pomija martwe.
- `proto_goblin.gd`: 40 zdrowia (2-3 cięcia), prędkość 42 (Wojciech 70), zamach z 15 px, cios trafia do 22 px
  (zdarzenie `hit` animacji - da się odskoczyć), 10 obrażeń co 1 s, rozpychanie w tłumie (`_separation`), odrzut,
  trafienie przerywa zamach; śmierć: animacja, 1,2 s ciała, zanikanie.
- `proto_horde.gd` (`ProtoHorde`): ciągły strumień - odstęp 1,3 -> 0,3 s i 8 -> 45 goblinów naraz w ciągu 180 s;
  pojawiają się tuż poza kadrem (`spawn_point`), liczy `kills` i `time`.
- `proto_hero.gd`: 100 zdrowia, `take_damage` (czerwony błysk, liczba, wibracja, 0,35 s nietykalności), `died`,
  przewrócenie się (Wojciech z Watry nie ma animacji śmierci), `obstacles` (okręgi spłaszczone w pionie).
- `proto_watra.gd` (`ProtoWatra`): Watra z Watry (`assets/watra/watra.png`, 6 klatek, 7 kl/s), poświata, iskry, napis
  pod ogniem; dotknięcie (`TAP_RECT`) -> `entered`. Krąg kamieni zatrzymuje postać.
- `arena.gd`: `@export var horde` - baza (`prototype.tscn`: kukły (-100,0), (100,10), (0,170), Watra (0,-115)) albo loch
  (`scenes/horde.tscn`: chłodniejsza trawa, pasek zdrowia, „Pokonane: N”, czas). `scripts/ui/run_result.gd`
  (`RunResult`): okno wyniku po 1,2 s od śmierci (pauza). Okno pauzy w lochu ma „Powrót do bazy” (`PauseMenu.base_scene`).
- Test `tests/test_horde.gd`; wydajność: 45 goblinów nie zmienia czasu klatki w chmurze.

## 12.11.2026 - styl grafiki (wywiad SpriteKiln)

- Odpowiedzi autora zapisane `spritekiln style set` w `spritekiln.toml`: topdown, 36 px (klatka 48, scale 0.04889),
  8 kierunków bez odbicia, paleta `watra`, outline selective, shading soft, lines depth, highlights, bez ditheringu,
  światło classic, proporcje stylized, twarz minimal, animacja fluid; notatki: pasuje do Watry, czytelne na telefonie,
  broń lewituje. Tabela w `docs/ART_SPEC.md`.
- Paleta `art/specs/palettes/watra.yaml`: rampy z `spritekiln palette ramp` dla kolorów z grafik Watry (wood, leather,
  cloth, skin, hair, steel, stone, straw, nawia) + gold, bone, blood, flame, eye, fx z palety gothic.

## 12.11.2026 - aktualizacja w grze bez całego apk

- Autoload `Updater` (`scripts/updater.gd`, pierwszy na liście autoloadów): w `_init` wczytuje `user://update/game.pck`
  (`ProjectSettings.load_resource_pack(..., true)`), jeśli `info.json` ma ten sam `APK_LEVEL` i wyższą kompilację niż
  `res://build_info.json` z apk (inaczej usuwa paczkę). `check()` czyta `version.json` z gałęzi `apk`
  (raw.githubusercontent.com, `?t=` omija pamięć podręczną), `download()` pobiera `game.pck` do `.part`, sprawdza
  SHA-256, zapisuje `info.json`. Stany: checking, up_to_date, available, downloading, ready, need_apk, error.
  Działa tylko w wyeksportowanej grze (`OS.has_feature("template")`) albo z argumentem `--with-updates`.
- Menu: przycisk pod „Graj” („Aktualizuj” / „Zamknij grę” / „Pobierz całą grę” / „Spróbuj ponownie”), postęp
  pobierania w %, wersja z numerem kompilacji. Gra pyta serwer sama przy wejściu do menu.
- Sprawdzone na wyeksportowanej grze (Linux): paczka podmienia sceny, skrypty, autoload `Game` i dodaje nowe klasy
  `class_name`; paczka gry ok. 0,6 MB (apk 28 MB). Nie przenosi project.godot, export_presets.cfg, updater.gd.
- `tools/build_android.sh` wpisuje `build_info.json` (kompilacja = `git rev-list --count HEAD`, commit; w .gitignore,
  w eksporcie przez `include_filter`) i eksportuje też `build/game.pck`; `tools/publish_apk.sh` wrzuca na gałąź `apk`
  apk, `game.pck` i `version.json` (build, commit, apk, size, sha256). Uprawnienie internetu w eksporcie włączone.
- Test `tests/test_updater.gd` (z `-- --with-updates`): mini-serwer HTTP na TCPServer, paczka z PCKPacker.
- Sprawdzone na telefonie autora: kompilacja 15 (pełny apk) -> „Aktualizuj” -> kompilacja 16.

## 12.11.2026 - efekt trafienia, miecz dalej od postaci

- Efekt trafienia z kreatora efektów PixelLab: „Watra Mobile - trafienie miecza” (My effects autora, id
  `c6789000-6891-435e-aa71-9c751f0cfed2`): części `hit_star` (x0.7) i `cooling_sparks` (x0.5), 42x39 px, 12 klatek
  20 fps, zaczepienie (23, 17). Plik `pixellab_src/vfx/sword_hit.png` (siatka 4x3, przezroczysty), wpis `sword_hit`
  w `ids.json`, w grze `assets/effects/sword_hit.png`. Pobieranie z `api.pixellab.ai` działa już w chmurze (curl
  adresu `download` z wyniku eksportu).
- `Fx.once` (`scripts/fx.gd`, jak `SkillEffects.sheet_once` w Watrze): odtwarza arkusz raz i usuwa efekt.
  Miecz odpala trafienie na linii od postaci do kukły, nie dalej niż 80% ostrza.
- `ProtoWeapon.HILT_RADIUS` 8 -> 14 px: miecz krąży dalej od postaci (półksiężyc cięcia skaluje się sam).

## 12.11.2026 - wersja na telefon z chmury

- `tools/build_android.sh`: buduje `build/WatraMobile.apk` (eksport „Android - testy”, arm64, ok. 28 MB). Doinstalowuje
  szablony Androida Godota 4.7.2 (`tools/android/remote_unzip.py` wyciąga z archiwum .tpz tylko 3 pliki zapytaniami
  o fragmenty) i Android SDK build-tools 35 w `/opt/android-sdk`, wpisuje ścieżki do ustawień edytora.
  Podpis: stały klucz testowy `tools/android/debug.keystore` (zmienne `GODOT_ANDROID_KEYSTORE_DEBUG_*`),
  więc kolejne wersje instalują się na poprzednich.

## 12.11.2026 - prototyp walki: lewitujący miecz i kukły

- „Graj” w menu otwiera `scenes/prototype.tscn` (`scripts/proto/arena.gd`, wszystko budowane w kodzie): polana
  720x1120 z trawy Watry, kamera z granicami, trzy kukły, przyciski „Menu” i „Gest: wł./wył.”, podpowiedź pod nimi.
- Grafiki i dźwięki z Watry w `assets/watra/`: Wojciech (`wojciech.png`, arkusz 8 kolumn, wiersz = animacja * 5 + kierunek,
  komórka 54 px, stopy na 46 px), kukła, żelazny miecz (chwyt 9.5,10, czubek 61,9, skala 0.5), trawa, 4 dźwięki trafienia kukły.
- `Joystick` (`scripts/ui/joystick.gd`): pływająca gałka - dotyk w dowolnym wolnym miejscu, promień 28 px, martwa strefa 15%,
  podąża za palcem; zdarzenia myszy (telefon zamienia dotyk na mysz), leży pod przyciskami.
- `ProtoHero`: chód 70 px/s, animacje idle/walk/slash z arkusza, 8 kierunków (zachód odbity). Gest = animacja `slash`
  z pustą dłonią, tylko w miejscu (w marszu postać tylko idzie).
- `ProtoWeapon`: miecz unosi się 22 px nad ziemią za ramieniem postaci (doganianie z opóźnieniem, kołysanie).
  Cios (przy trzymanym przycisku ataku) jak zwykły atak w Watrze: miecz wskakuje na orbitę wokół postaci
  (środek 12 px nad stopami, rękojeść 8 px od środka, ostrze 26 px na zewnątrz) i tnie łukiem 160° w stronę celu,
  kolejne cięcia na przemian z góry i z dołu (rozbieg 0,12 s, cięcie 0,18 s z `ease(progress, 0.5)`, trafienie
  w połowie - wszystkie kukły w łuku, 14-20 obrażeń, wibracja 15 ms, odpoczynek 0,55 s). Nad łukiem efekt cięcia
  ze zwykłego ataku Watry: `assets/effects/sword_slash.png` (kreator efektów PixelLab, `pixellab_src/vfx/ids.json`,
  5 klatek 64 px, skala = zasięg czubka / 29 px, `flip_v` przy cięciu od dołu).
- Przycisk ataku i miejsca na umiejętności (`scripts/ui/action_cluster.gd`, `action_button.gd`): prawy dolny róg,
  atak - kółko 64 px z ikoną żelaznego miecza z Watry (`assets/watra/iron_sword_icon.png`), wokół niego na łuku
  (promień 96 px, kąty 180-270°) 4 puste miejsca 44 px. Miecz tnie tylko, gdy przycisk jest trzymany - w stronę
  najbliższej kukły w promieniu 48 px, bez kukły przed siebie.
- Sterowanie wieloma palcami: gałka i przyciski akcji czytają `InputEventScreenTouch`/`ScreenDrag` z numerem palca
  (można iść i trzymać atak naraz); gałka nie startuje na przyciskach (`Joystick.blocked`). W testach
  `root.push_input(e, true)` - pozycje w pikselach gry.
- Okno pauzy (`scripts/ui/pause_menu.gd`, przycisk „Menu” w lewym górnym rogu; też przycisk „wstecz” Androida
  i przełączenie aplikacji): zatrzymuje grę (`get_tree().paused`), przełączniki „Atak i umiejętności po lewej”
  i „Gest postaci przy ataku” (wcześniej osobny przycisk na ekranie), „Wróć do gry”, „Menu główne”. Ustawienia
  w `Game` (`left_handed`, `gesture`) zapisane w `user://settings.cfg` (testy: `user://test_settings.cfg`).
  `ActionCluster.left_handed` odbija układ do lewego rogu (umiejętności na łuku od prawej do góry).
  `application/config/quit_on_go_back=false` - „wstecz” nie zamyka gry.
- `ProtoDummy`: błysk, przechył, liczby obrażeń, licznik obrażeń/s z 5 s, suma i trafienia, zerowanie po 4 s.
- Test `tests/test_prototype.gd` (palec prowadzi postać, miecz bije kukłę; z oknem zapisuje klatki zamachu).

## 12.11.2026 - start projektu

- Projekt Godota 4.7 „Watra Mobile” (`project.godot`): obraz gry **360x640** w pionie, rozciąganie `canvas_items`
  z `aspect=expand` (wyższe telefony, np. 20:9, widzą więcej w pionie), skalowanie całkowite (piksele zostają ostre),
  orientacja pionowa (`window/handheld/orientation=1`), okno na komputerze 450x800, mysz udaje dotyk
  (`emulate_touch_from_mouse`), renderer zgodności (`gl_compatibility` - działa na starszych telefonach i w chmurze tak samo
  jak na telefonie), filtr najbliższego sąsiada, przyciąganie do pikseli.
- Autoload `Game` (`scripts/game.gd`): wersja gry, zmiana sceny, ścieżka zapisu.
- `SafeArea` (`scripts/ui/safe_area.gd`): marginesy interfejsu od wcięcia aparatu i paska gestów.
- Ekran startowy-zaślepka (`scenes/main_menu.tscn`, `scripts/main_menu.gd`): ikona Watry, tytuł, hasło, „Graj”, wersja.
- Tłumaczenia jak w Watrze: `scripts/lang.gd`, `tools/texts.py`, `translations/teksty.csv` (pl/en), `translations/slowniczek.md`.
- Ustawienia eksportu „Android - testy” (`export_presets.cfg`, pakiet `pl.watra.mobile`, arm64), opis w `docs/ANDROID.md`.
- Testy: `tests/test_project.gd`, `tests/run_tests.ps1`; zrzuty ekranu `tools/screenshot.sh` (domyślnie 720x1280).
- Ściągawki `docs/sciagawka_spritekiln.md` i `docs/sciagawka_vfx.md`; efekty ataków z kreatora efektów PixelLab
  (ustalenie autora), `tools/vfx_art.py` (z Watry, sam ucina pasek podpisu) i `pixellab_src/vfx/ids.json`.
- SpriteKiln 0.3 (`spritekiln init --engine godot --ai claude`): `spritekiln.toml`, specyfikacje w `art/specs/`,
  eksport do `assets/spritekiln/`, instrukcje dla Claude w `.spritekiln/agent/` i `.claude/`, serwer MCP w `.mcp.json`.

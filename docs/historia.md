# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

## 12.11.2026 - Wódz Goblinów, koniec wyprawy i poziomy lochu

- Ustalenia z autorem: pasek żaru 100 (`DungeonLevels.SUMMON_COST`), przyzwanie przyciskiem przy pełnym pasku, gobliny
  uciekają z piskiem, Wódz Goblinów (duży, w trofeach) z trzema atakami z ostrzeżeniem: cios w ziemię, okrzyk wojenny,
  rzut tasakiem; nagroda - skrzynia (na razie żar, potem łup); okno zwycięstwa; pokonanie bossa odblokowuje następny
  poziom, wybór poziomu przy Watrze (do najwyższego odblokowanego). Ucieczka i śmierć gaszą żar (zgodnie z GDD) - przycisk
  „Do bazy” w lochu usunięty, w pauzie „Uciekaj do bazy” z ostrzeżeniem (`PauseMenu.leave_note`).
- `scripts/dungeon_levels.gd` (`DungeonLevels`): `power(level)` = 1 + 0,15 na poziom (zdrowie i obrażenia goblinów i Wodza),
  `chest_embers(level)` = 20 + 10 na poziom. `Game`: `best_level` (najwyższy przebity), `dungeon_level` (wybrany),
  `unlocked_level()`, `beat_level()`; oba w zapisie.
- Arena w lochu: pasek żaru pod paskiem zdrowia (pulsuje, gdy pełny), „Poz. N” w pasku, przycisk „Przyzwij Wodza” nad
  przyciskami ataku (`summon_chief`): zjada 100 żaru (nadwyżka zostaje w liczniku), `ProtoHorde.call_boss` (strumień staje,
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
  tasak rysowany w kodzie, `proto_ring.gd` - fale okrzyku i kurz.
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

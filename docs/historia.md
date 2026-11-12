# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

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

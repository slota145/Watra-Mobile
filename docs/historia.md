# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

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

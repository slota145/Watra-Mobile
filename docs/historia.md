# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

## 12.11.2026 - prototyp walki: lewitujący miecz i kukły

- „Graj” w menu otwiera `scenes/prototype.tscn` (`scripts/proto/arena.gd`, wszystko budowane w kodzie): polana
  720x1120 z trawy Watry, kamera z granicami, trzy kukły, przyciski „Menu” i „Gest: wł./wył.”, podpowiedź na dole.
- Grafiki i dźwięki z Watry w `assets/watra/`: Wojciech (`wojciech.png`, arkusz 8 kolumn, wiersz = animacja * 5 + kierunek,
  komórka 54 px, stopy na 46 px), kukła, żelazny miecz (chwyt 9.5,10, czubek 61,9, skala 0.5), trawa, 4 dźwięki trafienia kukły.
- `Joystick` (`scripts/ui/joystick.gd`): pływająca gałka - dotyk w dowolnym wolnym miejscu, promień 28 px, martwa strefa 15%,
  podąża za palcem; zdarzenia myszy (telefon zamienia dotyk na mysz), leży pod przyciskami.
- `ProtoHero`: chód 70 px/s, animacje idle/walk/slash z arkusza, 8 kierunków (zachód odbity). Gest = animacja `slash`
  z pustą dłonią, tylko w miejscu (w marszu postać tylko idzie).
- `ProtoWeapon`: miecz unosi się 22 px nad ziemią za ramieniem postaci (doganianie z opóźnieniem, kołysanie).
  Kukła w zasięgu 36 px (stopy-stopy) -> cios jak zwykły atak w Watrze: miecz wskakuje na orbitę wokół postaci
  (środek 12 px nad stopami, rękojeść 8 px od środka, ostrze 26 px na zewnątrz) i tnie łukiem 160° w stronę celu,
  kolejne cięcia na przemian z góry i z dołu (rozbieg 0,12 s, cięcie 0,18 s z `ease(progress, 0.5)`, trafienie
  w połowie - wszystkie kukły w łuku, 14-20 obrażeń, wibracja 15 ms, odpoczynek 0,55 s). Nad łukiem efekt cięcia
  ze zwykłego ataku Watry: `assets/effects/sword_slash.png` (kreator efektów PixelLab, `pixellab_src/vfx/ids.json`,
  5 klatek 64 px, skala = zasięg czubka / 29 px, `flip_v` przy cięciu od dołu).
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

# Watra Mobile

Gra mobilna na telefon trzymany **pionowo** (Godot 4.7, GDScript, pixel-art), oparta na świecie gry **Watra**
(repozytorium `slota145/Watra`): słowiański świat zalany przez Hordę, ostatnia osada Ostoja i jej ogień.
Hasło gry: „Dopóki płonie ogień, Ostoja trwa”. Rdzeń gry: **czyszczenie lochów z hubem** (wstępnie lochy w stylu Vampire Survivors, ale bez mechanik roguelike).
Projekt jest na starcie - szczegóły ustalamy z autorem (`docs/GDD.md`).

Osoba tworząca grę pracuje na Windowsie i rozmawia po polsku. Nie programuje na co dzień, więc wyjaśniaj prosto,
bez żargonu, i podawaj gotowe komendy do skopiowania. W odpowiedziach używaj form neutralnych płciowo
(np. „możesz”, „wpisz”, zamiast „zrobiłeś/zrobiłaś”). Poniżej „autor” oznacza tę osobę.

## Styl współpracy

- Bądź miły i entuzjastyczny. Ciesz się razem z autorem postępami w grze.
- Traktuj autora jak partnera w tworzeniu gry. Proponuj kreatywne pomysły na mechaniki, klimat, animacje i drobne
  detale budujące immersję.
- Wyraźnie oddzielaj swoje pomysły od tego, co już ustaliliście. Nie dodawaj nowych funkcji do gry bez zgody autora.
- Bądź przy tym szczery: jeśli pomysł, także autora, jest ryzykowny, zbyt pracochłonny lub nie pasuje do gry na telefon,
  powiedz o tym i zaproponuj lepszą opcję.

## Gra na telefon - zasady

- **Pion:** obraz gry 360x640 (`project.godot`), `canvas_items` + `aspect=expand` + skalowanie całkowite. Wyższe
  telefony (20:9) dostają więcej miejsca w pionie, więc układ interfejsu ma się rozciągać (kotwice, kontenery),
  a nie stać na sztywnych współrzędnych.
- **Dotyk:** każde sterowanie działa palcem. Pola do stukania min. 44x44 px gry, ważne przyciski w dolnej połowie
  ekranu (kciuk jednej ręki). Bez najeżdżania kursorem, skrótów klawiszowych jako jedynej drogi i małych okien.
  Na komputerze mysz udaje dotyk (`emulate_touch_from_mouse`). Sterowanie w grze czyta dotyk z numerem palca
  (`InputEventScreenTouch`/`ScreenDrag`), żeby działało kilkoma palcami naraz; w testach `root.push_input(e, true)`.
- **Bezpieczny obszar:** interfejs w `SafeArea` (`scripts/ui/safe_area.gd`) - wcięcia aparatu i paski gestów.
- **Wydajność:** renderer zgodności (`gl_compatibility`), słabsze telefony - unikaj ciężkich shaderów, setek świateł
  i tysięcy węzłów naraz; przy zmianach walki sprawdzaj liczbę klatek.
- **Przerwanie gry:** telefon może w każdej chwili przełączyć aplikację - zapisuj stan przy
  `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_GO_BACK_REQUEST` (przycisk „wstecz” na Androidzie).

## Relacja z Watrą

- Watra to osobna, duża gra na komputer. Przenosimy z niej pomysły, dane, grafiki i narzędzia, ale **kopiujemy**
  potrzebne pliki do tego repozytorium (bez wspólnych zależności), dostosowane do telefonu.
- Jeśli w sesji jest klon Watry (np. `../Watra`), szukaj w nim grepem - jej `CLAUDE.md` i `docs/historia.md` opisują
  wszystkie systemy. Słowniczek nazw: `translations/slowniczek.md` (skopiowany z Watry - Watra i Ostoja zostają po polsku).

## Struktura

- `scripts/`: logika. `game.gd` (autoload `Game`: wersja, zmiana sceny, zapis gry - żar Watry, przebity poziom lochu), `main_menu.gd` (ekran startowy),
  `lang.gd` (tłumaczenia), `scripts/ui/` (interfejs, `safe_area.gd`).
- `scripts/proto/`: prototyp walki (`arena.gd` - polana i interfejs, `proto_hero.gd` - postać, `proto_weapon.gd` -
  lewitujący miecz, `proto_target.gd` - wspólna baza celów miecza, `proto_dummy.gd` - kukła, `proto_goblin.gd` - goblin Hordy,
  `proto_horde.gd` - strumień potworów, `proto_watra.gd` - Watra = wejście do lochu i licznik żaru, `proto_ember.gd` - iskra żaru z potworów,
  `proto_chief.gd` - boss Wódz Goblinów (ataki z ostrzeżeniem `proto_telegraph.gd`, tasak `proto_cleaver.gd`),
  `proto_chest.gd` - skrzynia po bossie; `scripts/dungeon_levels.gd` - poziomy lochu (siła, koszt przyzwania, nagroda);
  `scripts/hero_levels.gd` - poziomy postaci (doświadczenie, zdrowie, obrażenia, miejsca na umiejętności; stan w `Game`);
  `scripts/skills.gd` - umiejętności miecza (dane; kupione i miejsca w `Game`, działanie w `proto_weapon.gd`, okno
  `scripts/ui/skills_window.gd` z polami `skill_slot.gd`, kamień run w bazie);
  `scripts/items.gd` - przedmioty (miejsca, rzadkości, premie, łup, ceny; torba, założone i złoto w `Game`),
  `proto_loot.gd` - przedmiot na ziemi, `proto_stash.gd` - skrzynia w bazie (okno `scripts/ui/stash_window.gd`, pola z przeciąganiem `item_slot.gd`);
  `scripts/ui/run_result.gd` - wynik po śmierci i okno zwycięstwa, `scripts/ui/level_picker.gd` - wybór poziomu przy Watrze); `scripts/ui/joystick.gd` - pływająca gałka (dotyk wieloma palcami),
  `scripts/ui/action_cluster.gd` i `action_button.gd` - przycisk ataku i miejsca na umiejętności w dolnym rogu,
  `scripts/ui/pause_menu.gd` - okno pauzy z ustawieniami sterowania i auto atakiem (zapis w `Game`, `user://settings.cfg`)
  oraz trybem deweloperskim (nieśmiertelność, skróty: +1 poziom, +100 żaru, +5 przedmiotów, postać od nowa), `scripts/ui/hero_stats.gd` -
  okno „Postać” ze statystykami, ekwipunkiem i torbą (przycisk w pauzie).
- `scripts/updater.gd`: autoload `Updater` (pierwszy na liście) - aktualizacja wersji testowej z menu bez całego apk
  (paczka `game.pck` z gałęzi `apk`); przy zmianach project.godot, export_presets.cfg, updater.gd albo wersji Godota
  podbij w nim `APK_LEVEL` (gra poprosi wtedy o pełny apk). Test: `tests/test_updater.gd -- --with-updates`.
- `scenes/`: sceny (`main_menu.tscn` startowa, `prototype.tscn` - baza prototypu pod „Graj” z kukłami i Watrą,
  `horde.tscn` - loch z ciągłym strumieniem goblinów; obie na `arena.gd`).
- `assets/`: grafiki, muzyka, dźwięki; `assets/watra/` - pliki skopiowane z Watry; `assets/spritekiln/` - postacie wyeksportowane ze SpriteKiln.
- `art/specs/`: specyfikacje postaci SpriteKiln (YAML; Godot je pomija). Wyniki renderów w `out/` są generowane i nie idą do gita.
- `tools/`: narzędzia (`screenshot.sh`/`screenshot.gd` - zrzuty ekranu, `texts.py` - napisy do tłumaczenia, `ember_art.py` - iskra żaru, `goblin_squeak.py` - pisk goblinów, `boss_shots.gd` - zrzuty walki z bossem, `level_shots.gd` - zrzuty rozwoju postaci, `item_shots.gd` - zrzuty przedmiotów, `stash_shots.gd` - zrzuty skrzyni, `skill_shots.gd` - zrzuty umiejętności,
  `vfx_art.py` - efekty z kreatora PixelLab do `assets/effects/`).
- `tests/`: testy (`run_tests.ps1` u autora).
- `translations/`: `teksty.csv` (pl/en), `pomijane.txt` (napisy bez tłumaczenia), `slowniczek.md`.
- `docs/`: wizja gry (`GDD.md`), zasady grafiki (`ART_SPEC.md`), lista zadań (`ROADMAP.md`), historia zmian
  (`historia.md`), ściągawki narzędzi (`sciagawka_*.md`), telefon z Androidem (`ANDROID.md`), obrazy referencyjne od autora (`docs/referencje/`). Godot je pomija.
- `export_presets.cfg`: eksport „Android - testy” (pakiet `pl.watra.mobile`, plik `build/WatraMobile.apk`).

## Uruchamianie i testy w chmurze (Linux, bez monitora)

Godot 4.7.2 jest dostępny jako `godot`, SpriteKiln jako `spritekiln` (jeśli go nie ma: `pip install "spritekiln[mcp,fast]"`).
W świeżym klonie zaimportuj najpierw zasoby, inaczej klasy globalne (`SafeArea`, `Lang`) nie są widoczne:
```bash
godot --headless --path . --import
```

Testy bez okna wypisują linie `OK …` / `FAIL …` i `WYNIK: …`:
```bash
godot --headless --path . -s res://tests/test_project.gd
```

Zrzut ekranu (Xvfb + programowy OpenGL; argumenty: plik, scena, sekundy, rozdzielczość - domyślnie 720x1280):
```bash
tools/screenshot.sh /tmp/menu.png
tools/screenshot.sh /tmp/wysoki.png "" 1 1080x2400
SCRIPT=tests/test_cos.gd tools/screenshot.sh <argumenty>
```
Sprawdzaj zmiany interfejsu w dwóch proporcjach: 720x1280 (16:9) i 1080x2400 (20:9). Obejrzyj zrzut narzędziem Read.
Komunikaty ALSA, o wyciekach tekstur i `ERR_CANT_OPEN` przy zamykaniu są niegroźne.

Wersja na telefon (Android): `tools/build_android.sh` -> `build/WatraMobile.apk` (za pierwszym razem doinstalowuje
szablony Godota i Android SDK, około minuty); plik wysyła autorowi `tools/publish_apk.sh` przez gałąź `apk` (osobna, jeden commit z plikiem i README, nadpisywana; autor pobiera
na telefonie z https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk - kafelek SendUserFile nie zapisał
się autorowi w „Pobranych”). Opis: `docs/ANDROID.md`.

U autora na Windowsie wszystkie testy uruchamia `tests/run_tests.ps1`. Nowy test dopisz też do listy `$tests` w tym pliku.
Testy zapisują do `user://test_savegame.json`, nigdy do zapisu gracza.

## Grafika

Zasady w `docs/ART_SPEC.md` (przeczytaj przed tworzeniem grafik). W skrócie: najpierw sprawdź grafiki Watry, potem
SpriteKiln (darmowy, postacie i potwory), a PixelLab tylko po pokazaniu autorowi kosztu - autor ma ograniczony limit
miesięczny (ceny i obejście blokady pobierania w chmurze: `CLAUDE.md` Watry, „PixelLab w chmurze”).
**Efekty ataków** (cięcia, trafienia, pociski, czary) robimy w kreatorze efektów PixelLab (`vfx_workbench`, darmowy) -
decyzja autora z 12.11.2026.
Ściągawki: `docs/sciagawka_spritekiln.md` (postacie, potwory, bronie) i `docs/sciagawka_vfx.md` (efekty, droga
do gry przez `pixellab_src/vfx/` i `python tools/vfx_art.py`). Czytaj odpowiednią przed pracą nad grafiką.
Instrukcje SpriteKiln są w bloku na końcu tego pliku (generuje go `spritekiln update` - nie edytuj go ręcznie).

## Konwencje

- Komentarze, nazwy w interfejsie i opisy commitów piszemy po polsku.
- Napisy dla gracza od razu gotowe do tłumaczenia (zasady w komentarzu `scripts/lang.gd`): `Lang.t("…")` albo `tr("…")`,
  zdanie z liczbą jako jeden wzór (`tr("Poziom %d") % lvl`), odmiana - `Lang.n`. Po dodaniu napisów: `python tools/texts.py`.
- Opisy skryptów i funkcji w komentarzach `##`, na początku pliku zwięźle, co skrypt robi.
- Wcięcia tabulatorami, typowanie statyczne (`var x := …`, `-> void`).
- Pliki `.uid` commitujemy razem ze skryptami.
- Część plików ma BOM UTF-8, więc przy edycji skryptem zachowuj kodowanie.

## Git

- Zmiany idą na gałąź roboczą, potem pull request do `main`. Autor zwykle prosi o założenie PR i od razu scalenie.
- **Po każdym scaleniu do `main`** uruchom `tools/publish_apk.sh` (buduje apk i paczkę `game.pck`, nadpisuje gałąź `apk`)
  i daj znać autorowi: zwykle wystarczy przycisk „Aktualizuj” w menu gry; gdy podbito `APK_LEVEL`, podaj link do
  pełnej gry: https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk (prośba autora).
- Gdy autor ma u siebie lokalne commity, `git pull` otwiera vima. Podpowiadaj wtedy `git pull --no-edit origin main`.
- Po pobraniu zmian polecaj `powershell -ExecutionPolicy Bypass -File aktualizuj.ps1` (pull + import zasobów;
  Godot autora: `C:\Godot_v4.7.2-stable_win64.exe\` - to folder z plikami `.exe` w środku).

## Oszczędzanie tokenów

- Nowy duży temat zaczynaj w nowej sesji - wszystko ważne jest w tym pliku i w `docs/historia.md`.
  Po zakończeniu większego tematu od razu daj autorowi gotowy prompt do nowej sesji na kolejny punkt.
- `docs/historia.md` i `docs/ROADMAP.md` przeszukuj grepem, gdy urosną.
- Zrzuty ekranu tylko przy zmianach wizualnych; przycinaj i zestawiaj kilka w jeden obraz.
- Odpowiedzi krótkie: bez powtarzania długich list, kodu i raportów.

## Lista zadań, wizja gry i grafika

- `docs/ROADMAP.md` - poprawki („Do poprawy”) i pomysły. Aktualizuj go, gdy autor rzuci pomysł albo zgłosi błąd.
  Zrobiony punkt przenieś (ze szczegółami) do `docs/historia.md`. Przed większym punktem dopytaj autora o szczegóły.
- `docs/GDD.md` - wizja gry; sprawdzaj w nim, czy pomysł pasuje. Zmieniaj tylko po decyzji autora.
- `docs/ART_SPEC.md` - zasady grafiki.

<!-- spritekiln:begin (generated from docs/agent by spritekiln; edit the sources, not this block) -->
## SpriteKiln assets
Sprites in this project are made with SpriteKiln: a YAML spec (skeleton, SDF primitives, materials, palette,
animations) is rendered into animated 8-direction pixel art (atlas + JSON + normal/emissive maps).

Read before working on an asset: `.spritekiln/agent/workflow.md` (commands and the working loop), `.spritekiln/agent/style.md` (the
project's art style) and `.spritekiln/agent/spec.md` (the spec format). Then, as needed: `.spritekiln/agent/modeling.md`,
`.spritekiln/agent/splash-to-model.md`, `.spritekiln/agent/animation.md`, `.spritekiln/agent/art-direction.md` and `.spritekiln/agent/recipe.md` (the modeler → art
director → animator recipe).

Rules that matter:
- Art style first: run `spritekiln style` before the first asset of a session. If no style is recorded,
  interview the user with the questions of `.spritekiln/agent/style.md` and record the answers before generating
  anything. Follow the recorded style in every asset; change it only when the user explicitly asks.
- Run `spritekiln validate <spec>` after every edit; problems come with file:line:column.
- Iterate with `spritekiln pose <spec> --dirs all` (about 1 s per direction); `spritekiln render` only at the end.
- A character's head and hair are decided in its `brief.head` and judged up close with
  `spritekiln pose <spec> --focus head --dirs all`: on a normal preview a face is a few pixels.
- Never call something visual good without looking at the PNG. If you cannot see images, use the numbers of
  `spritekiln review` (value, contrast, pixels per material, IoU) and `qa.json`.
- Keep the camera pitch, light and `camera.scale` shared by every asset of the game.
- Outputs under `out/` are generated: never edit them.
- `spritekiln export <spec>` hands a render to the engine configured in `spritekiln.toml`.
- With an MCP client, `spritekiln mcp` serves these operations as tools that return images and JSON.

Claude Code: skills `spritekiln`, `spritekiln-splash-to-model`, `spritekiln-animation`; agents `character-modeler`, `animator`, `pixel-art-director` (see `recipe.md` for the order).
<!-- spritekiln:end -->

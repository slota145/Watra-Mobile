# Ściągawka: kreator efektów PixelLab (vfx_workbench)

**Ustalenie autora (12.11.2026): efekty ataków (cięcia, trafienia, pociski, czary) robimy w kreatorze efektów PixelLab.**
Kreator jest darmowy, nie zużywa limitu generacji. Efekt zapisuje się w „My effects” autora na pixellab.ai, gdzie
autor może go poprawiać suwakami. Pełne opisy: `mcp__PixelLab__vfx_workbench` z `["describe", "<temat>"]`, tematy:
`start`, `parts`, `recipe`, `craft`, `cookbook`, `edits`, `presets`, `tools`, `tool <nazwa>`. Tryb `low`
(domyślny) zużywa mało tokenów.

## Jak to działa

Nic nie jest generowane przez AI: Claude składa efekt z gotowych **części** (parts, ze strojeniem i suwakami) i własnych
**warstw** (JSON), renderer rysuje ostry pixel-art, a Claude **ogląda każdą klatkę** i poprawia. Każda zmiana daje
nowy identyfikator kroku. Stare kroki zostają, więc można się cofnąć albo rozgałęzić pracę.

```
start [--sprite <obraz>] [--fps 16]          -> krok
<krok> add_part '{"name": "swing_slash"}'    -> nowy krok (render: oglądaj!)
<krok> set_part '{"id": "...", "size": 0.8, "colour": "fire", "start": 0, "end": 0.6}'
<krok> render '{"patch": [{"op": "retime", "frames": 8, "keep": "speed"}]}'
<krok> export --name "Cięcie miecza"         -> zapis w My effects + image id arkusza
<krok> export --replace <id efektu>           -> aktualizacja zapisanego efektu
effects                                       -> lista efektów autora
start --effect <id efektu>                    -> dalsza praca nad zapisanym (z suwakami ustawionymi przez autora)
```
- `--sprite`: efekt budowany wokół postaci (id z `pixelart_workbench`, `character:<id>:<kierunek>`, URL, base64;
  najwyżej 32 klatki po 512 px). Przy postaci ze SpriteKiln podaj klatkę jej animacji, żeby dopasować skalę.
- Limity: płótno 16-1024 px, 1-60 fps (domyślnie 12), do 120 klatek, klatki x szer. x wys. ≤ 32 x 1024 x 1024.
- Czas części: `start`/`end` to ułamki efektu. Przykład: błysk od 0, cięcie od 0,1, iskry od 0,3.
- Kolory: gotowe rampy `arcane, blood, electric, fire, frost, holy, nature, poison, shadow, smoke, water` albo własne
  kolory. Kolor części najpewniej zmienia łatka `ramps.<nazwa>`, bo sam `colour` w `set_part` bywa pomijany (doświadczenie z Watry).
- `role` (cast, projectile, impact, linger) i `core: true` porządkują efekt. `--game-pack` daje ZIP z osobnym klipem dla
  każdej części (np. sam pocisk), ale pobieranie plików z chmury nie działa (niżej).

## Części przydatne do ataków

- **Cięcia:** `swing_slash` (zamach, który „smaga”), `slash_trail`, `heavy_slash` (cios w ziemię), `spin_slash`
  (wirowanie 360°), `rising_slash`, `dash_slash`, `cross_slash`, `combo_slash`, `wave_slash` (lecąca fala),
  `thrust_streak` (pchnięcie), `zigzag_slash` (cięcie po własnej ścieżce, `points`).
- **Trafienia:** `hit_star`, `flash_burst`, `crit_hit`, `spark_burst`, `cooling_sparks`, `zap_hit`, `shock_bend`
  (fala wyginająca obraz), `hurt_flash`, `iframes_blink`, `pixel_shatter` (śmierć w piksele), `blood_splat`.
- **Pociski i łuk:** `arrow_arc`, `arrow_volley`, `magic_orb`, `fire_bolt`, `ice_lance`, `comet_trail`, a także `throw`
  (lot gotowego obrazka: arrow, dagger, sword, axe, spear...).
- **Czary i obszary:** `fire_blast`, `bolt_strike`, `storm_strike`, `ice_spikes`, `earth_spike`, `thorn_ring`,
  `ground_cracks`, `rune_circle`, `warn_strike` (zapowiedź ataku bossa), `shockwave_ring`.
- **Klimat Watry:** `ember_rise`, `campfire`, `flame_aura`, `shadow_flames` (Nawia), `curse_skulls`, `fireflies`, `frost_mist`.
- Lista z opisami: `["<krok>", "list_parts", "{\"tag\": \"slash\"}"]`, podgląd części: `get_part`.

Do lewitującej broni: smuga za bronią to `arc` z `profile: "slash"` i `points` wzdłuż toru broni albo `ribbon` na
ścieżce (`paths`). Mocny cios: `freeze` (zatrzymanie 2-4 klatek) i `impact` (klatka-błysk).

## Z kreatora do gry

Od 12.11.2026 pobieranie działa: `export` podaje adres `download https://api.pixellab.ai/mcp/pixel-tools/<id>/`
z plikami `<nazwa>.png` (przezroczysta siatka klatek, kolejność wierszami) i `<nazwa>.json` (klatki, czasy, `pivot`).
Pobierz PNG curlem do `pixellab_src/vfx/<nazwa>.png`, dopisz wpis w `ids.json` (przy siatce `columns`; zaczepienie =
`anchor (origin)` z wyniku eksportu) i uruchom `python tools/vfx_art.py`. W grze: `Fx.once` (`scripts/fx.gd`).

Gdyby pobieranie znów było zablokowane (dawne obejście):
1. `export` zwraca **image id** arkusza.
2. `mcp__PixelLab__pixelart_workbench` z `["join", "<image id>", "--as", "sheet", "--columns", "<liczba klatek>"]`
   zapisuje PNG w katalogu `tool-results` sesji: skala 1:1, pasek podpisu u góry, tło (31, 37, 44).
3. Skopiuj go bez zmian do `pixellab_src/vfx/<nazwa>.png` i dopisz efekt w `pixellab_src/vfx/ids.json`
   (`effect`, `name`, `frame` [szer, wys], `frames`, `fps`, `anchor` - punkt zaczepienia w klatce).
4. `python tools/vfx_art.py` utnie pasek, usunie tło i zapisze jeden rząd klatek do `assets/effects/<nazwa>.png`.
5. W grze: `Sprite2D` z `hframes` = liczba klatek i tween po `frame`. Watra ma gotowego pomocnika
   `SkillEffects.sheet_once` (`../Watra/scripts/skill_effects.gd`) do skopiowania przy pierwszym efekcie.

## Skala

Obraz gry ma 360 px szerokości. Efekt ataku wręcz zwykle zajmuje 1-2 wysokości postaci (np. 48-96 px przy postaci
48 px). Duże efekty obszarowe sprawdzaj na zrzucie 720x1280, bo nie mogą zasłaniać pół ekranu telefonu.

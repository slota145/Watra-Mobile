# Ściągawka: SpriteKiln (postacie i potwory)

Skrót dokumentacji SpriteKiln 0.3 dla kolejnych sesji. Pełne instrukcje są w `.spritekiln/agent/*.md`
(po angielsku; odświeża je `spritekiln update --files`). Czytaj je, gdy ściągawka nie wystarcza.

## Co to jest

Postać to plik YAML (szkielet, gładkie bryły 3D, materiały, paleta, animacje). SpriteKiln renderuje ją do pixel-artu
w 8 kierunkach (widok z góry 3/4), z dokładnym czasem klatek, zdarzeniami (`hit`, `step_l`), punktami zaczepienia
(sockets), mapą normalnych i warstwą świecącą. Darmowy i lokalny, czyli bez limitu generacji, ale renderuje tylko
to, co opiszemy bryłami. Najlepiej sprawdza się przy postaciach, potworach i broniach. Do kafelków i ikon lepszy jest PixelLab.

## W tym projekcie

- `spritekiln.toml`: specyfikacje w `art/specs/` (Godot je pomija), eksport do `assets/spritekiln/<nazwa>/`.
- **Styl zapisany 12.11.2026** (`spritekiln style`; tabela w `docs/ART_SPEC.md`): z góry 3/4, postać 36 px (klatka 48),
  8 kierunków, paleta `watra` (`art/specs/palettes/watra.yaml`), kontur barwny, miękkie cieniowanie, tylko oczy, płynna
  animacja. Zmieniaj go tylko na wyraźną prośbę autora (`spritekiln style set --<pole> ...`).
- Wyniki renderów (`out/`, `.kilncache/`) nie idą do gita (`.gitignore`), a eksport w `assets/spritekiln/` idzie.
- Agenci SpriteKiln w `.claude/agents/`: `character-modeler`, `animator`, `pixel-art-director` (tylko ocenia).
  Umiejętności: `spritekiln`, `spritekiln-animation`, `spritekiln-splash-to-model`. Wywiad o styl zawsze robi
  główna sesja, bo agenci nie mogą pytać autora.

## Komendy

```bash
spritekiln style                                   # zapisany styl projektu (najpierw!)
spritekiln new wojownik --extends                  # krótka specyfikacja na bazie humanoida
spritekiln kits                                    # gotowe części: sword, axe, bow, staff, shield, hood, cape...
spritekiln validate art/specs/characters/wojownik/wojownik.yaml   # po KAŻDEJ zmianie (błędy z linią i kolumną)
spritekiln pose <spec> --dirs all [--draft]       # podgląd 8 kierunków, ok. 1 s na kierunek
spritekiln pose <spec> --focus head --dirs all     # głowa z bliska (twarz to kilka pikseli)
spritekiln pose <spec> --anim attack --frame 3 --dirs s,e,n,se   # kluczowa klatka animacji
spritekiln render <spec> [--anims walk] [--draft]  # całe animacje: atlas, JSON, GIF-y, arkusze, raport QA
spritekiln review <spec> [--bg podloga.png]        # ocena w liczbach: kontrast, czytelność
spritekiln export <spec>                           # do Godota: assets/spritekiln/<nazwa>/
spritekiln palette ramp "#c0602a" --steps 5        # rampa kolorów z przesunięciem barwy
```
Spec bez gotowej specyfikacji: `spritekiln new <nazwa>` kopiuje szablon do przerobienia, a `--extends` dziedziczy po humanoidzie
i wypisuje tylko różnice. Gdy komendy nie ma w PATH: `python -m spritekiln`.

## Pętla pracy

1. Styl (raz na sesję) -> 2. przeczytaj spec i jej `brief:` (długi plik: `spritekiln spec outline`) ->
3. zmieniaj po trochu, jako tekst (nigdy nie przepisuj YAML-a skryptem, bo komentarze są ważne) -> 4. `validate`
(ostrzeżenia też: literówka w kluczu jest po cichu pomijana) -> 5. `pose --dirs all` i **obejrzyj PNG** (Read) ->
6. powtarzaj -> 7. `render` dopiero na końcu (3 animacje x 8 kierunków to kilka minut) i przeczytaj QA ->
8. pokaż autorowi GIF-y z `out/<nazwa>/preview/` -> 9. `export`.
Kolejność dla nowej postaci (recipe.md): model -> ocena dyrektora -> poprawki -> **autor zatwierdza model** -> animacje
-> ocena -> poprawki -> render -> eksport. Nie animuj, zanim autor nie zaakceptuje wyglądu.

## Animacje (skrót animation.md, dla 64 px)

| animacja | klatki | ms na klatkę |
|---|---|---|
| idle | 4-8 | 120-180 |
| walk | 8 | 90-110 |
| lekki atak | 5-7 | zamach 100-170, cios 40-60, powrót 100-130 |
| hit | 3-4 | 60-90 |
| death | 6-10 | 90-140, ostatnia 400+ |

- Cykle (idle, walk) to wyrażenia od `p` (0..2π), np. `"0.05*sin(p)"`. Nigdy nie używaj `t` w pętli.
  Akcje (atak, śmierć) to `keys`, czyli jedna klatka na klucz z własnym `ms`.
- Zdarzenia: `windup`, `hit`, `release`, `step_l`/`step_r`. W Godocie przychodzą sygnałem `anim_event`.
- Ruch krótszy niż 0,5 px migocze. Sprawdzaj kierunki `n` i ukośne, bo cios widoczny w `s` potrafi schować się za ciałem.

## W Godocie

`spritekiln export` wgrywa dodatek `addons/spritekiln` i tworzy scenę z węzłem `KilnSprite2D` (`AnimatedSprite2D`):
```gdscript
$Sprite.play_anim(&"walk")
$Sprite.face(velocity)            # najbliższy z 8 kierunków
$Sprite.anim_event.connect(func(anim, ev): if ev == &"hit": zadaj_obrazenia())
$Sprite.anim_finished.connect(func(anim): $Sprite.play_anim(&"idle"))
var dlon := $Sprite.to_global($Sprite.get_socket(&"hand_R"))   # punkt zaczepienia w tej klatce
```
Początek węzła to punkt na ziemi pod postacią, więc sortowanie po Y działa od razu.

## Pod nasze pomysły (GDD)

- **Lewitująca broń:** broń jako osobna specyfikacja (np. z kitu `sword`) renderowana w 1 kierunku, a kod ją obraca
  i przesuwa. Postać bez broni w dłoni.
- **Gest ataku w marszu:** osobna animacja (np. `walk_attack`), w której nogi idą jak w `walk`, a ręka i tułów robią
  gest. Dodaj zdarzenie `hit` w chwili ciosu i socket na dłoni (tam rozbłyska iskra i stamtąd startuje ruch broni).

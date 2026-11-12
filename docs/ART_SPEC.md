# Watra Mobile - zasady grafiki

Jak robić grafiki, żeby pasowały do gry. Na razie spisane są tylko ustalenia techniczne; styl ustalamy z autorem
przed pierwszą postacią (wywiad SpriteKiln - `spritekiln style`).

## Ekran i piksele

- Obraz gry ma **360x640 pikseli** w pionie. Telefon 1080x2400 pokazuje go w skali x3 (jeden piksel grafiki to 3x3
  piksele ekranu), a dodatkowa wysokość (800 zamiast 640) poszerza widok - nie rozciąga obrazu. Projektuj tak, żeby
  wszystko ważne mieściło się w 360x640, a nadmiar był tłem.
- Filtr tekstur: **najbliższy sąsiad**, położenia przyciągane do pełnych pikseli (`project.godot`).
- Bezpieczny obszar: interfejs wkładamy do `SafeArea` (`scripts/ui/safe_area.gd`), żeby nie wchodził pod wcięcie aparatu.
- Pola do stukania: co najmniej **44x44 px gry** (ok. 1 cm na telefonie), ważne przyciski w dolnej połowie ekranu (kciuk).
- Tekst: domyślna czcionka 16 px gry jest najmniejszą czytelną na telefonie; drobniejsze tylko dla dodatków (np. wersja).

## Skąd brać grafiki

1. **Watra** (`../Watra/assets/`, repozytorium `slota145/Watra`): ikony, obiekty, kafelki, efekty - najpierw sprawdź,
   czy coś pasuje. Uwaga: Watra ma obraz 640x360, więc grafiki mogą wymagać innej skali.
2. **SpriteKiln** (darmowy, lokalny): animowane postacie i potwory w 8 kierunkach z opisu w YAML. Ściągawka:
   `docs/sciagawka_spritekiln.md`, pełne instrukcje: `.spritekiln/agent/workflow.md`, styl projektu: `spritekiln style`. Wynik trafia do `assets/spritekiln/`.
3. **Kreator efektów PixelLab** (`vfx_workbench`, darmowy): **wszystkie efekty ataków** - ustalone z autorem 12.11.2026.
   Ściągawka: `docs/sciagawka_vfx.md`.
4. **PixelLab** (limit generacji autora): obiekty, kafelki, ikony, efekty. Zasady i ceny jak w `CLAUDE.md` Watry
   („PixelLab w chmurze”) - zanim wydasz generacje, policz koszt i pokaż go autorowi.

## Styl postaci (wywiad SpriteKiln z autorem, 12.11.2026)

Zapisany w `spritekiln.toml` (`spritekiln style` pokazuje go w każdej sesji); każda nowa postać, potwór i broń go trzyma.

| Co | Ustalenie |
|---|---|
| Widok | z góry 3/4 (`topdown`, kamera 38°) - jak w Watrze |
| Wielkość | postać wzrostu człowieka **36 px** (Wojciech z Watry ma 35 px i jest „w sam raz”), klatka 48 px, `camera.scale` 0.04889 - wspólna dla wszystkich |
| Kierunki | 8, bez odbicia lustrzanego |
| Kolory | jak w Watrze: ciepłe, przytulne fantasy (drewno, ogień, złoto Ostoi), Horda i Nawia chłodne i mroczne; paleta `art/specs/palettes/watra.yaml` (rampy z kolorów grafik Watry, `nawia` - chłodny fiolet) |
| Kontur i cieniowanie | kontur barwny (`selective`: każda część obrysowana najciemniejszym odcieniem swojego koloru), cieniowanie miękkie |
| Wykończenie | linie wewnętrzne `depth` (między częściami ciała), odblaski na metalu i klejnotach, bez ditheringu, światło `classic` (z góry z lewej) |
| Proporcje i twarze | stylizowane (głowa 1,2-1,4x), twarz: tylko oczy |
| Animacja | płynna (chód 8 klatek, klatki pośrednie) |
| Zasady | pasuje do grafik Watry stojących obok; czytelne na małym ekranie (wyraźne sylwetki, potwory rozpoznawalne w tłumie); broń gracza lewituje - postać bez broni w dłoni |

## Do ustalenia z autorem

- Rozmiar kafelka świata (Watra: 16x16 px) - przy pierwszym lochu.

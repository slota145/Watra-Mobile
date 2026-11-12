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

## Do ustalenia z autorem

- Wysokość postaci w pikselach gry (np. 32 albo 48 px przy szerokości ekranu 360).
- Kontur, cieniowanie, paleta (czy trzymamy ciepłe barwy Ostoi i chłodną Nawię jak w Watrze).
- Perspektywa: z góry jak w Watrze („low top-down”) czy inna - zależy od rodzaju rozgrywki (`docs/GDD.md`).
- Rozmiar kafelka świata (Watra: 16x16 px).

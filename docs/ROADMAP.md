# Watra Mobile - lista zadań

Zgłoszone poprawki i pomysły do zrobienia. Zrobiony punkt przenosimy (ze szczegółami) do `docs/historia.md`.
Przed rozpoczęciem większego punktu dopytujemy autora o szczegóły - to luźne pomysły, a nie gotowe projekty.

## Do poprawy

(na razie nic)

## Najbliższe kroki

0. Prototyp walki oceniony na telefonie (12.11.2026): gra się przyjemnie, ataki satysfakcjonujące, Wojciech w sam raz,
   tempo ataku celowo wolne - będzie co przyspieszać (szybkość ataku jako nagroda za rozwój).
   Wcześniej: **Ocena prototypu walki** (`scenes/prototype.tscn`): czy lewitujący miecz i gest się podobają, tempo ataku, zasięg,
   wielkość postaci na ekranie telefonu; efekt cięcia z Watry już jest; do decyzji efekt trafienia (kreator efektów PixelLab).

0b. Pierwszy potwór i Horda (12.11.2026, szczegóły w `docs/historia.md`): goblin ze SpriteKiln, baza z Watrą,
   loch z ciągłym strumieniem goblinów, pasek zdrowia, licznik, okno wyniku. Do oceny na telefonie: tempo strumienia,
   obrażenia, czytelność goblinów w tłumie. Oceniony na telefonie: działa i bardzo się podoba.
   Iskry żaru z goblinów dla Watry (12.11.2026) - na co wydawać żar, do ustalenia z autorem.
   Boss i poziomy lochu (12.11.2026): Wódz Goblinów za pełny pasek żaru, skrzynia, odblokowanie następnego poziomu.

1. **Wizja gry:** rdzeń ustalony (lochy + hub, może jak Vampire Survivors bez roguelike) - czekamy na pierwsze pomysły
   autora i odpowiedzi na pytania z `docs/GDD.md` („Do ustalenia”) - od nich zależy cała reszta.
2. ~~Styl grafiki~~ - zrobione 12.11.2026 (`docs/ART_SPEC.md`).
3. **Pierwsza wersja na telefon:** eksport na Androida (`docs/ANDROID.md`) i sprawdzenie, czy menu dobrze wygląda
   na telefonie autora (wcięcie aparatu, pasek gestów).
4. **Prototyp rozgrywki:** najmniejsza grywalna pętla wybrana w punkcie 1 (jedna postać, jeden rodzaj potwora,
   sterowanie dotykiem).
5. **Interfejs dotykowy:** wspólny styl przycisków (duże pola do stukania, min. 44 px gry), wibracje przy trafieniu.

## Pomysły autora (do zrobienia)

- **Boss w lochu (12.11.2026):** zrobione (szczegóły w `docs/historia.md`); do oceny na telefonie: czas zapełniania
  paska (100 żaru), trudność Wodza, czytelność ostrzeżeń. Do zrobienia: animacje Wodza (cios w ziemię, okrzyk, rzut)
  po zatwierdzeniu modelu; skrzynia da łup, gdy dojdą przedmioty.

## Pomysły (luźne, od Claude - czekają na decyzję autora)

- Watra jako „serce” ekranu startowego: animowany ogień, który przygasa, gdy długo nie grasz, i rozpala się po powrocie.
- Postęp offline: robotnicy Ostoi zbierają drewno i kamień, gdy telefon leży w kieszeni (jak obozy w BDO).
- Wspólne dane z Watrą (nazwy przedmiotów, potworów, słowniczek tłumaczeń), żeby obie gry trzymały ten sam świat.

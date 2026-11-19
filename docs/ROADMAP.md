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

1. **Wizja gry:** rdzeń ustalony (lochy + hub, może jak Vampire Survivors bez roguelike) - czekamy na pierwsze pomysły
   autora i odpowiedzi na pytania z `docs/GDD.md` („Do ustalenia”) - od nich zależy cała reszta.
2. ~~Styl grafiki~~ - zrobione 12.11.2026 (`docs/ART_SPEC.md`).
3. **Pierwsza wersja na telefon:** eksport na Androida (`docs/ANDROID.md`) i sprawdzenie, czy menu dobrze wygląda
   na telefonie autora (wcięcie aparatu, pasek gestów).
4. **Prototyp rozgrywki:** najmniejsza grywalna pętla wybrana w punkcie 1 (jedna postać, jeden rodzaj potwora,
   sterowanie dotykiem).
5. **Interfejs dotykowy:** wspólny styl przycisków (duże pola do stukania, min. 44 px gry), wibracje przy trafieniu.

## Ustalone, do zrobienia

- **Aury rezerwujące manę** (pomysł autora 19.11.2026, szczegóły ustalone tego samego dnia): osobna zakładka
  „Aury” obok broni; gracz włącza tyle aur, na ile starczy many (aura rezerwuje część maksymalnej many na stałe).
  Wymaga paska many (jeszcze go nie ma). Wzór: `../Watra/scripts/aura_data.gd` i `auras.gd`.
  - **Zdobywanie:** łup z lochów - rzadki „kamień aury” z bossa lub skrzyni; aura zostaje na zawsze.
  - **Poziomy 1-10 za duplikaty:** kolejny taki sam kamień podnosi poziom aury.
  - **Rezerwacja 25-35%:** na start mieszczą się 2 aury, z redukcją rezerwacji 3, w późnej grze 4.
    Mała premia „redukcja rezerwacji” (np. z poziomu aury albo przedmiotów).
  - **Wygląd:** delikatny, wolno obracający się krąg pod postacią w kolorze aury (kilka aur - kilka pierścieni)
    i małe ikonki przy pasku many.
  - **Propozycja 6 aur** (do potwierdzenia przy wdrażaniu): Krzepa (+zdrowie, 25%), Wiatr Strzyboga (+szybkość
    ruchu i ataku, 30%), Żar Swaroga (dodany ogień i podpalenie, 25%), Gniew Peruna (co 3 s piorun w wroga, 35%),
    Postrach (wrogowie w kręgu słabsi i wolniejsi, 30%), Szron Marzanny - nowa (wrogowie w kręgu zwalniają
    i dostają rany od mrozu, 25%).

## Pomysły (luźne, od Claude - czekają na decyzję autora)

- Watra jako „serce” ekranu startowego: animowany ogień, który przygasa, gdy długo nie grasz, i rozpala się po powrocie.
- Postęp offline: robotnicy Ostoi zbierają drewno i kamień, gdy telefon leży w kieszeni (jak obozy w BDO).
- Wspólne dane z Watrą (nazwy przedmiotów, potworów, słowniczek tłumaczeń), żeby obie gry trzymały ten sam świat.

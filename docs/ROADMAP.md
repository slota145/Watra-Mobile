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
   Iskry żaru z goblinów dla Watry (12.11.2026) - na co wydawać żar: ustalone (punkt „Baza: żar i złoto” niżej).
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
  paska (100 żaru), trudność Wodza, czytelność ostrzeżeń. Model, animacje i efekty
  Wodza gotowe; skrzynia daje żar i 3 przedmioty.

- **Rozwój postaci (12.11.2026):** poziomy doświadczenia, auto atak i skróty deweloperskie (+1 poziom, +100 żaru,
  postać od nowa) zrobione (szczegóły w `docs/historia.md`). Do oceny na telefonie: tempo awansów (krzywa w
  `HeroLevels`), czy Wódz robi się łatwiejszy. Pasek many i okno „Postać” ze statystykami zrobione - manę zużyją umiejętności.
  Przedmioty zrobione (12.11.2026, szczegóły w `docs/historia.md`). Do oceny na telefonie: szansa łupu z goblinów (2,5%),
  siła premii, ceny, czytelność okna na 16:9 (przewija się). Na co wydawać złoto - do ustalenia (kowal, sklep?).
  Umiejętności miecza zrobione (12.11.2026, szczegóły w `docs/historia.md`). Do oceny na telefonie: koszty many
  i odnowienia, siła Młynka/Rzutu/Rozłupania, czy auto atak z Młynkiem nie jest za mocny, ceny (100-1500 zł).
  Mgnienie działa jak w Watrze; „wirujące Mgnienie” (skoki w trakcie Młynka) - autor jeszcze nie wie, czy w tę stronę.
  Kamienie w umiejętnościach i ekwipunku zrobione (12.11.2026, szczegóły w `docs/historia.md`). Do oceny na telefonie:
  szanse łupu (goblin 1,2%, skrzynia 80% + 30%, klucz 4-15%, dłuto 6-20%), siła kamieni (Żar, Piorun, Mnożenie),
  czytelność gniazd w oknach, czy Szron i Żar dobrze widać na goblinach (znaczki rysowane w kodzie - może efekty z kreatora).
  Poziomy umiejętności zrobione (13.11.2026, szczegóły w `docs/historia.md`). Do oceny na telefonie: ceny ulepszeń
  (40-200 zł x poziom), czy +10% obrażeń na poziom jest odczuwalne, czy nowe działania z 5. i 10. poziomu są widoczne
  i nie za mocne (wybuch Młynka, drugi miecz Rzutu, wir po Mgnieniu - efekty pożyczone z innych umiejętności).
  Kamienie unikalne (po jednym na umiejętność) i Mgnienie z odnowieniem zrobione (13.11.2026, szczegóły w
  `docs/historia.md`). Do oceny na telefonie: szansa łupu (3-8% ze skrzyni Wodza od 5. poziomu), czy Młynek bez
  odnowienia nie jest za mocny (mana 1/3 kosztu na sekundę), siła fal Rozłupania i fali cięcia.
  Mgnienie jak Flicker Strike i trudniejsze głębokie lochy zrobione (13.11.2026). Do oceny na telefonie: czy 2 many za
  zabicie skokiem to dobry zwrot, czy 70 potworów naraz nie zwalnia telefonu, czy krzywa siły (100. poziom x113) pasuje.
  Później może: więcej kamieni unikalnych na umiejętność (autor: „na razie po jednym”).

- **Baza: żar i złoto (12.11.2026):** zrobione (szczegóły w `docs/historia.md`). Do oceny na telefonie: ceny ulepszeń
  i ich odczuwalność (czy +10% potworów widać), ceny kowala i kupca (przedmioty u kupca tanie wobec klucza),
  czy pasek skrótów nie zasłania widoku na 16:9.

- **Czytelniejsze okno „Postać” i kamienie (13.11.2026):** zrobione (szczegóły w `docs/historia.md`). Do oceny na
  telefonie: czy zakładki i wybór kamienia są wygodne, czy opisy pod gniazdami są czytelne (czcionka 9 px).
  Do decyzji później: krótsze porównanie przedmiotów (tylko zmieniające się liczby ze strzałkami).

- **Więcej statystyk na przedmiotach (13.11.2026):** zrobione, także drugi rzut - obszar umiejętności, unik, zasięg
  zbierania, więcej żaru (szczegóły w `docs/historia.md`). Do oceny na telefonie: czy unik 2-4% na przedmiot jest
  odczuwalny, czy +żar nie skraca za bardzo drogi do Wodza. Na później: nowe premie w kamieniach.

- **Glewia ognia i kolczyk z kłem (13.11.2026):** zrobione (szczegóły w `docs/historia.md`). Do oceny na telefonie:
  siła i zasięg umiejętności glewii wobec miecza, czy podpalenie jest odczuwalne, nowe działania 5. i 10. poziomu
  (propozycje Claude), cena 3000 zł i próg Wodza 10, czy płonący krąg i pas ognia nie zasłaniają wrogów, liczba klatek
  w Tańcu płomieni z ogniem na ziemi. Po poprawkach 14.11.2026 (Płonąca bruzda zamiast doskoku, nowy Taniec, zwężona
  smuga pchnięcia): czy wachlarz bruzdy trafia, czy seria cięć tańca czyta się na telefonie. Później: kamienie unikalne glewii, własne ikony umiejętności glewii (teraz z Watry),
  kolor liczb obrażeń od ognia.

- **Żywioły i wiele broni (13.11.2026):** etap 1 zrobiony - fundament żywiołów, mistrzostwo broni odblokowuje
  umiejętności, żar ulepsza umiejętności, złoto - ulepszenia lochów (szczegóły i decyzje w `docs/historia.md`).
  Do oceny na telefonie (balans): ceny ulepszeń umiejętności w żarze (te same liczby co dawniej w złocie) i ulepszeń
  lochów w złocie (te same co dawniej w żarze), czy złota i żaru starcza; czy napis „Nowa umiejętność” jest widoczny.
  Dalej: kolejne bronie po jednej, każda dopracowana, z działaniem swojego żywiołu (Elements.EFFECTS): łuk, hydrosfera,
  mroczna kosa, ostrza na łańcuchach, księgi żywiołów, sztylety powietrza, glewia ognia, lodowy rapier, elektryczna
  katana, kostur nekromancji; zmiana broni w bazie i kupno za złoto przed progiem (`Weapons.unlock`, `price`);
  kamienie dodające mieczowi żywioł; później odporności bohatera i potwory bijące żywiołami. Do decyzji: światło.

## Pomysły (luźne, od Claude - czekają na decyzję autora)

- Watra jako „serce” ekranu startowego: animowany ogień, który przygasa, gdy długo nie grasz, i rozpala się po powrocie.
- Postęp offline: robotnicy Ostoi zbierają drewno i kamień, gdy telefon leży w kieszeni (jak obozy w BDO).
- Wspólne dane z Watrą (nazwy przedmiotów, potworów, słowniczek tłumaczeń), żeby obie gry trzymały ten sam świat.
- Przedmioty: lewitujący miecz wygląda jak założona broń (stalowy, runiczny…); legendy z bossów; nazwy rzadkich
  przedmiotów składane z dwóch słów (jak w Watrze); kropka „nowe” na przycisku „Menu”, gdy w torbie jest nowy łup;
  porównanie z założonym przedmiotem także na ziemi (strzałka w górę nad lepszym).

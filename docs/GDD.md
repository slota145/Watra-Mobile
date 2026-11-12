# Watra Mobile - wizja gry

Krótki opis tego, czym Watra Mobile ma być. Służy do sprawdzania, czy nowy pomysł pasuje do gry. Zmieniamy go tylko
po decyzji autora. Szczegóły zrobionych systemów będą w `docs/historia.md`, a plany w `docs/ROADMAP.md`.

> **Szkic z 12.11.2026.** Ustalone są tylko punkty oznaczone „ustalone”. Reszta to pytania do autora (sekcja
> „Do ustalenia”) - nie projektujemy systemów, dopóki autor ich nie potwierdzi.

## Jednym zdaniem

Gra mobilna na telefon trzymany **pionowo**, oparta na świecie i klimacie Watry: słowiański świat zalany przez Hordę,
ostatnia osada Ostoja i jej ogień. Hasło: **„Dopóki płonie ogień, Ostoja trwa”**.

## Ustalone

- Nazwa robocza: **Watra Mobile** (12.11.2026).
- Platforma: telefony, **orientacja pionowa** (12.11.2026). Najpierw Android (łatwo wgrać na własny telefon), iOS później.
- Silnik: Godot 4.7, GDScript - jak w Watrze, żeby przenosić pomysły, dane i grafiki.
- Świat, nazwy i klimat z Watry (słowiańskie wierzenia, Ostoja, Watra, Horda, Nawia).
- Grafika: pixel-art; postacie i potwory można robić w SpriteKiln (z opisu, bez limitu generacji) albo w PixelLab.
- **Rdzeń gry: czyszczenie lochów z hubem** (12.11.2026). Gracz wraca między lochami do huba (najpewniej Ostoja),
  a w lochach walczy i zdobywa łup.

## Kierunek wstępny (autor jeszcze nie zdecydował)

- Lochy w stylu **Vampire Survivors** (fale potworów, gracz głównie się porusza, a ataki idą same?), ale **bez mechanik
  roguelike** - postęp zostaje między wyprawami (postać, łup, hub), a nie przepada po śmierci.
- **Siła postaci** (ustalone 12.11.2026): ekwipunek, umiejętności, kamienie wkładane w umiejętności i w ekwipunek,
  poziomy doświadczenia. W lochu nie wybiera się losowych ulepszeń (bez roguelike).
- **Lewitująca broń** (pomysł autora, rozważany): broń nie jest w dłoni, tylko unosi się obok postaci i sama porusza się
  płynnie przy atakach. Prostsze animacje postaci niż w Watrze; podobnie robi np. Brotato.
- Autor przygotowuje pierwsze pomysły - czekamy na nie przed projektowaniem systemów.

## Filary (kandydaci z Watry - do potwierdzenia)

1. **Ogień i dom.** Ostoja rośnie razem z graczem, do Watry zawsze się wraca.
2. **Łup, który cieszy.** Losowe premie, rzadkości, legendy, zaklinanie z ryzykiem (inspiracje: Path of Exile, BDO).
3. **Słowiański klimat.** Bogowie, demony i stwory z wierzeń Słowian, polskie nazwy, ciepły pixel-art z mrokiem Nawii.
4. **Krótkie sesje.** Telefon to gra „w autobusie”: rozgrywka da się przerwać w każdej chwili i wrócić po kilku minutach.
5. **Jedna ręka.** Pionowy ekran zachęca do grania kciukiem jednej ręki - ważne przyciski w dolnej połowie ekranu.

## Do ustalenia z autorem

- **Walka w lochu:** w stylu Vampire Survivors (auto-ataki, ruch palcem) czy ARPG jak Watra (gałka i przyciski
  umiejętności)? Co daje „bez roguelike”: czy w lochu w ogóle wybiera się ulepszenia, czy wszystko daje hub i ekwipunek?
- **Hub:** co w nim robimy (kowal, Watra, sklep, drzewko)? Ekran z budynkami do stukania czy chodzenie postacią?
- **Sterowanie:** gałka w miejscu dotyku, stuknięcie w cel, przeciąganie, auto-atak?
- **Co przenosimy z Watry:** łup i przedmioty, drzewko umiejętności, zaklinanie, lochy Watry, świat jak w MMO?
- **Sesje i postęp:** postęp offline (Ostoja zbiera surowce, gdy gracz nie gra)? Długość jednej wyprawy?
- **Zarabianie:** gra płatna, darmowa bez reklam, czy na razie tylko dla siebie i znajomych?
- **Połączenie z Watrą:** osobna historia w tym samym świecie, czy wersja kieszonkowa tej samej gry?
- **Kamera i widok:** z góry jak w Watrze, czy inny (np. bok, jak w grach typu obrona wieży)?

## Czego w grze nie będzie (do potwierdzenia)

- Rzeczy wymagających klawiatury i myszy (skróty klawiszowe, najeżdżanie kursorem, małe okna przesuwane za tło).
- Wymaganego połączenia z internetem - gra ma działać offline, jak Watra.

# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

## 21.11.2026 - Filtr łupu

Pomysł autora i ankieta 21.11.2026 (układ okna pokazany autorowi i zaakceptowany przed pisaniem kodu).
- **Logika** (`scripts/loot_filter.gd` - `LootFilter`): `verdict(filtr, przedmiot, ctx)` - kolejność: filtr wyłączony,
  legenda albo unikat (zawsze zostają; rozbijane są tylko zwykłe / magiczne / rzadkie), bezpiecznik (`safe_above` -
  premia ponad widełki, `safe_sockets` - 2 gniazda), `upgrade` - lepszy od założonego (`Items.is_upgrade`), rzadkość
  niezaznaczona w zasadach miejsca, co najmniej `count` premii z listy (`stats`) w progu stopnia (`tier`; pusta lista
  bez Automatu - liczy się każda premia). Zasady miejsc: `slots.all` wspólne, każde miejsce z `own` - własne
  (`rules_for`). `burns(game, item)` - skrót dla gry.
- **Automat** (`auto`): `auto_stats(broń, umiejętności)` - premie ogólne (`AUTO_GENERAL`: zdrowie, obrażenia, ochrona,
  odporności, poziom wszystkich umiejętności), broń magiczna - obrażenia magiczne i szybkość rzucania, reszta - szybkość
  ataku, broń żywiołu - obrażenia od żywiołów, znaczniki założonych umiejętności (`Skills.TAG_STATS` + pocisk: szybkość
  pocisków, obszar: obszar, przywołaniec: czas działania), poziom umiejętności tylko założonej. Próg „Auto” (`tier` 0):
  `auto_tier` - najlepszy stopień dostępny na poziomie lochu + 2 (loch 1: każdy, loch 40: T3); bez Automatu „Auto” = każdy.
- **Zapis:** `Game.loot_filter` w zapisie postaci (`_read_filter`, `LootFilter.normalize` poprawia zły zapis). Dawny
  przełącznik `auto_sell_common` (settings.cfg) już się nie zapisuje; postać bez zapisanego filtra przy włączonym
  przełączniku dostaje filtr włączony z rozbijaniem zwykłych (jak dotąd). Domyślnie filtr wyłączony.
- **W lochu:** `ProtoLoot` przy podniesieniu - `LootFilter.burns` -> `Game.dismantle_loot` (sygnał `scrapped`, bez pełnej
  torby); arena: przygaszone powiadomienie „Filtr rozbił: … (+N rudy)” (`notify_loot(…, dim)`), liczniki
  `run_filtered` / `run_filtered_ore`, w podsumowaniu wyprawy `RunResult.add_filter_line` („Filtr łupu rozbił 3 przedmioty (+7 rudy)”).
- **Okno** (`scripts/ui/loot_filter_window.gd` - `LootFilterWindow` na `BaseWindow`): z pauzy (przycisk „Filtr łupu”,
  też w lochu) i z torby okna „Postać” (przycisk „Filtr łupu: włączony/wyłączony” zamiast przełącznika). U góry
  przełączniki „Filtr” i „Automat”, rząd miejsc 44 px („Wsz.” + 6 ikon, pomarańczowa kropka - własne ustawienia);
  zakładki pod kciukiem: „Zasady” (własne ustawienia miejsca - włączenie kopiuje wspólne, rzadkości, próg stopnia
  i ile premii z „-”/„+”, opis zasady słowami, bezpiecznik) i „Premie” (5 grup, tylko premie możliwe w miejscu -
  `Items.affix_fits`, „A” i zielony kolor - premia z Automatu, „Wyczyść”). Pauzy nie zmienia (`_was_paused`), zapis
  przy zamknięciu, „wstecz” zamyka najpierw filtr.
- **Podgląd:** w torbie okna „Postać” ikona ognia (`assets/watra/ui/filter_fire.png` - znacznik ognia z Watry) przy
  przedmiotach, które filtr by rozbił.
- Test `tests/test_loot_filter.gd`, zrzuty `tools/filter_shots.gd`; `tests/test_items.gd` sprawdza rozbicie filtrem w lochu.
- Do oceny na telefonie: próg Automatu (najlepszy dostępny + 2), lista premii Automatu, czytelność okna.
- Na przyszłość (ROADMAP): filtr dla kamieni szlachetnych (potrzebują stopni premii).

## 21.11.2026 - Przedmioty krok 4: pokaz łupu

Ankieta autora (wszystkie propozycje Claude, z dodatków: napis z wibracją i strzałka przy krawędzi; bez nazwy na ziemi).
- **Słupy światła** (`ProtoLoot.BEAMS`, `_Beam` - wysokość, szerokość, iskry, pulsowanie): rzadki niski (34 px),
  legendarny wysoki z iskrami, unikat wyższy z iskrami i pulsowaniem, anielski - jasny słup jak legendarny z aureolą
  u podstawy. Magiczny - większa poświata.
- **Premia ponad widełki** (`_Star`): biało-błękitny błysk przy wypadnięciu, potem co 1,6 s mignięcie gwiazdki.
- **Dźwięki z Watry** (`assets/watra/legendary_drop.ogg`, `legendary_pickup.ogg`, `jingles_PIZZI01.ogg`): legenda
  i unikat przy wypadnięciu i podniesieniu, unikat dodatkowo dzwoneczek; rzadki - wyższe „dzyń” przy wypadnięciu.
- **Strzałka „lepszy”** (`_Arrow`, `refresh_better` - też po zmianie ekwipunku): `Items.is_upgrade` - puste miejsce
  zawsze; siła `Items.score` (premia T1 = 7 punktów ... T7 = 1, ponad widełki x1,3, plus 0,15 za poziom lochu do 40);
  unikat - lepszy, chyba że założony ten sam; założonego unikatu nic nie zastępuje.
- **Legenda i unikat:** napis na środku ekranu („Legendarny: …!”, „Unikat: …!” - `arena.announce_loot`, grupa
  `ProtoLoot.ANNOUNCE`), wibracja 90 ms, strzałka przy krawędzi ekranu, gdy leży poza kadrem (grupa GoalArrows).
- Zrzut `tools/loot_show_shots.gd`, test `tests/test_loot_show.gd`.

## 21.11.2026 - Przedmioty krok 3: 6 unikatów

Propozycja Claude zaakceptowana przez autora w całości, ankieta: kowal nie przerabia unikatów wcale, kolor złoto-brązowy,
szansa 0,2% od lochu 10.
- **Dane** (`Items.UNIQUES`): po jednym na miejsce, stała baza ze swoją stałą cechą, stałe premie z wąskimi widełkami
  (pole przedmiotu `ustats`; `hp_pct` - procent zdrowia, ujemne to kara) i siła działania (`upower`). Przedmiot:
  `rarity` "unique", `unique` - id, bez premii (`affixes` puste) i bez potencjału kowalskiego. `Items.make_unique`,
  `is_unique`, opis `unique_effect` / `unique_lines` (premie, działanie, cytat; `affix_lines` je zwraca), kolor linii
  `Items.line_color` (okna „Postać”, skrzynia, kowal). Kolor `RARITY_COLORS.unique` (0,8 / 0,62 / 0,36), złoto-brązowy
  słup światła na ziemi (`ProtoLoot`), grubsza ramka, ikona bazy w wersji `_rare` (własne ikony - później).
- **Łup:** `Items.roll` z łupu (`loot`) najpierw losuje unikat: `unique_chance` 0 przed lochem 10 (`UNIQUE_FROM`),
  0,2% na 10., liniowo do 0,5% na 40. i dalej. Zadane miejsce - unikat z tego miejsca. Nie z kuźni.
- **Kowal:** `Runes.blocker` - „Unikatu nie da się przerobić u kowala.”. Rozbicie 10 rudy, na targu x50.
- **Działanie** (`scripts/proto/proto_uniques.gd` - `ProtoUniques`, dziecko postaci, arena podaje `worn` w `_apply_weapon`):
  - Oko Licha (kolczyk, srebrny): +10-14% szybkości ataku i rzucania; `ProtoWeapon._deal` - bez krytyków, co 4.
    trafienie (`LICHO_EVERY`) x3 (duża liczba jak krytyk).
  - Korona Czarnoboga (hełm): +35-40% obrażeń, +15-20% zdrowia; `ProtoHero.crown` - umiejętności płacą zdrowiem 1:1
    (`_blood`, razem z Krwawym Sercem - większe), aury zabierają część największego zdrowia zamiast many
    (`HeroStats.max_hp` / `reserved_mana`). Przywołania łuku i Kule Arkanów rezerwują dalej manę.
  - Ostatnia Warownia (zbroja): -20% ruchu; co 0,2 s liczy wrogów w 70 px (`BASTION_RADIUS`, do 20) - +2% obrażeń
    (`ProtoWeapon.bastion_count`) i +1% mniej obrażeń od każdego ciosu (`ProtoHero.bastion_res`) na wroga; słaby krąg.
  - Ślady Swaroga (buty): +8-10% ruchu, -15% zdrowia; co 9 px drogi płomień (efekt glewii) na 2 s, co 0,5 s rani ogniem
    (`aura_hit`, 25-30% obrażeń broni na sekundę) i podpala stojących w nim wrogów.
  - Pierścień Strzyboga: -25% obrażeń pocisków; trafienie umiejętnością ze znacznikiem „pocisk” wypuszcza 3 odłamki
    (50% siły umiejętności, `aura_hit`, bez krytyków) w najbliższych innych wrogów (90 px). Uproszczenie: dzieli się
    każde trafienie pocisku, ale najwyżej raz na 0,08 s (`SPLIT_COOLDOWN` - Kule Arkanów i deszcz strzał trafiają bez
    przerwy), a nie tylko pierwsze trafienie danego pocisku.
  - Zwierciadło Mokoszy (amulet): umiejętność powtarza się po 0,4 s (mechanizm kamienia Echo, napis „Odbicie!”;
    te same wyjątki: zwykły atak, Mgnienie, ładowane, trzymane, Młynek, Krąg stali - `ProtoWeapon.mirror_echoes`),
    koszt many x1,8. Siła 55-60%: zamiast słabszej kopii obie mają po (100% + siła) / 2 (np. 2 x 79% = 158%) -
    pociski i kręgi rażą później niż sama umiejętność, więc nie da się osłabić tylko kopii.
- Tryb deweloperski: przycisk „+unikaty” (`Game.dev_uniques` - wszystkie 6 do torby). Zrzuty `tools/unique_item_shots.gd`.
- Testy w `tests/test_uniques.gd`.

## 21.11.2026 - Przedmioty krok 2: legendarne, ponad widełki, „Anielski”, Runa Bogów, potencjał kowalski

Ankieta autora (21.11.2026).
- **Legendarny** (`rarity` "legendary", pomarańczowy, pomarańczowy słup światła - `ProtoLoot._Beam.color`): zawsze 6
  premii o stopień lepszych (`Items.LEGEND_TIER_BOOST`, `make_affix(..., boost)` - też przy runach), tylko z łupu:
  `Items.roll(..., loot)` z szansą `legend_chance` (0,5% na lochu 1, 1% na 40., najwyżej 1,5%); kuźnia (`Game.forge`)
  podaje `loot` false. Wyniesienie go nie robi. Ruda 8, drugie gniazdo 10%, na targu x30.
- **Premie ponad widełki** (`Items.make_above`, pole premii `above`): z łupu każda premia z szansą 3% (od lochu 40 - 5%)
  dostaje najlepszy stopień z poziomu przedmiotu i wartość 5-30% ponad jego górną granicą; znaczek „T1+” i kolor
  `ABOVE_COLOR`, grubsza ramka pola (`Items.frame_of`). Poziomy umiejętności nie wychodzą ponad (`ABOVE_SKIP`). Szlif
  losuje nową wartość ponad widełkami.
- **Anielski** (`Items.is_angelic` - wszystkie premie ponad): przedrostek w rodzaju nazwy bazy („Anielski / Anielska /
  Anielskie”, `name_of`), jasna ramka `ANGELIC_COLOR`.
- **Potencjał kowalski** (`Items.POTENTIAL` 15-25, pola `potential`/`potential_max`, `potential_of`, linia w opisach -
  `potential_line`): runy zabierają `Runes.cost_of` (Szlif 1, Przekucie 1, Przydanie 2, Wyniesienie 2, Zmiana 2,
  Pieczęć 3), przy braku `Runes.blocker` nie pozwala. Stare przedmioty - pełny 25.
- **Runa Bogów** (`Runes.GODS`, premia ponad widełki, bez potencjału) i **Runa Odnowy** (`Runes.RENEWAL`, pełny
  potencjał): od lochu 40 z elit (0,2%) i skrzyni bossa (1% każda; najpierw 6% - za dużo, uwaga autora) - `Runes.roll_boss`; nie u kupca (`is_boss`), na targu
  (60 i 40 Szlifów). Ikony SpriteKiln `art/specs/props/runes/rune_gods.yaml`, `rune_renewal.yaml`. Zapas run u kowala
  w 2 rzędach.
- Uwagi autora: przedmioty na ziemi mniejsze (`ProtoLoot.ICON_SCALE` 0,32 zamiast 0,45), powiadomienia o łupie
  małe przy lewej krawędzi, najwyżej 3 (`arena.gd` `notify_loot`, `FEED_MAX`) - wcześniej zasłaniały postać.
  Premia „+1 do poziomu” może trafić na umiejętność każdej broni (decyzja autora - motywacja do nowych buildów).
- Testy w `tests/test_item_tiers.gd`.

## 21.11.2026 - Przedmioty krok 1: stopnie T1-T7, sufit na lochu 40, bazy, nowe premie

Ankieta autora (21.11.2026), krok 1 z 4 przebudowy przedmiotów (`docs/ROADMAP.md`).
- **Stopnie premii** (`Items.TIER_FROM` 1/5/10/16/22/30/40 dla T7...T1, wagi `TIER_WEIGHTS` 22/20/18/15/12/8/5):
  premia to `{"stat", "value", "tier"}`, widełki T7 i T1 w `Items.AFFIXES` (`t7`, `t1`), stopnie pomiędzy po równo
  (`tier_range`), zachodzą na siebie. Losowanie: `make_affix`, `roll_tier`, `tier_value`; `roll_affix` (kamienie
  szlachetne) losuje stopień. Znaczek „T3” przed premią (`affix_lines`, kowal - kolorowy `tier_color`).
- **Sufit siły na lochu 40** (`Items.MAX_LEVEL`): stała cecha i stopnie dalej nie rosną. Potwory od 40. rosną wolniej
  (`DungeonLevels.SLOW_FROM`, `SLOW_STEP` 6% siły z 40. na poziom: 50. x30, 100. x88 zamiast x148).
- **Bazy** (`Items.BASES`, pole przedmiotu `type`): 3 na miejsce ze stałą cechą (`implicit`, od 1. do 40. poziomu -
  `implicit_value`, zdrowie i regeneracja jak siła lochu), 5 stopni nazw i ikon (`VISUAL_FROM` 1/5/12/22/32). Nowe
  ikony: linie Watry (kaptur, skórznia, szata, nagolenice, kolczyk srebrny, sygnet, wisior) i przebarwione
  (`tools/item_bases_art.py` -> `assets/items/`: ząb, rogaty hełm, łapcie, złoty pierścień, wisior runiczny).
- **Rzadki 3-5 premii** (`AFFIX_COUNT`).
- **Nowe premie:** `skill_level` (+1, T2-T1 +2, jedna umiejętność - pole `skill`; kolczyk, hełm, amulet),
  `skill_level_all` (amulet od lochu 22), umiejętność do 12. poziomu (`ProtoWeapon.level_of`, `Items.ITEM_LEVELS_MAX`;
  okno umiejętności pokazuje „+N z przedmiotów” - `Game.item_skill_bonus`); `proj/area/melee/minion_dmg_pct` ze
  znacznikami umiejętności (`Skills.TAGS`, `ProtoWeapon.item_hit_bonus`); `proj_speed_pct` (`proj_speed_mult` - rzut
  mieczem, strzały, pociski wody i Arkanów, odłamki); `duration_pct` (`duration_mult` - Krąg stali, Słup ognia, Wir,
  Strażnik, Deszcz strzał, balista, podpalenia); `afflicted_dmg_pct` (podpalony, spowolniony, przemoczony, porażony),
  `full_hp_dmg_pct`; `kill_haste_pct` (`ProtoHero.on_kill`/`haste`, 3 s ruch i atak); `rarity_pct`
  (`Items.boosted_weights`), `quantity_pct` (gobliny częściej, skrzynia Wodza +1 przedmiot), `ore_pct` (`Game.ore_gain`).
  Statystyki w oknie „Postać” (`HeroStats.ITEM_STATS`).
- **Runy:** Szlif losuje wartość w tym samym stopniu (`Items.polish_affix`), reszta dodaje premie ze stopniem
  (`Items.add_affix`).
- **Kowal:** po stuknięciu miejsca 3 przyciski baz (ikona, nazwa, stała cecha), drugie stuknięcie bazy wykuwa
  (`Game.forge(slot, type)`).
- **Stare przedmioty** (`Items.normalize`): pierwsza baza miejsca, stała cecha od nowa z poziomu (do 40), obrażenia
  kolczyka przycięte do sufitu, premie - stopień najbliżej środka widełek (`nearest_tier`) i wartość w jego widełkach.
- Test `tests/test_item_tiers.gd`.

## 21.11.2026 - Księga Arkanów, żywioł Arkana, premie magiczne, wybór broni na start

Pomysły i ankieta autora (21.11.2026). Wszystko w jednym PR.
- **Żywioł Arkana** (`Elements.ARCANE`, kolor fioletowo-biały): trafienia wysysają manę (3% obrażeń, najwyżej 3 many
  na trafienie - `ProtoWeapon._deal`).
- **Premie przedmiotów**: `magic_dmg_pct` („+% obrażeń magicznych”, `ProtoWeapon.magic_mult` - tylko broń magiczna) i
  `cast_speed_pct` („+% szybkości rzucania czarów”, sufit 75%): broń magiczna (`Weapons.is_magic` - księga i hydrosfera)
  przyspiesza tylko od niej, reszta tylko od szybkości ataku (`HeroStats.weapon_speed_mult`).
- **Wybór broni na start** (`Weapons.START` - miecz, łuk, księga; `Game.start_weapon`, zapis „start_weapon”): przy
  tworzeniu postaci 3 przyciski w formularzu (`CharacterSelect.start_weapon`), dwie niewybrane od lochu 5 (miecz ma teraz
  `unlock` 5 - dostępny od początku jako domyślna broń startowa starych postaci). `Game.create_character(imię, ssf, broń)`.
- **Księga Arkanów** (`scripts/proto/proto_book.gd`, `Weapons.BOOK`): lewitująca księga ze SpriteKiln
  (`art/specs/props/book/arcane_book.yaml` -> `assets/spritekiln/book/arcane_book.png`), efekty z kreatora PixelLab
  (`assets/effects/arcane_*.png` - pocisk, trafienie, krąg, kula, kafelek promienia, błysk promienia, pieczęć, wybuch,
  odłamek; `pixellab_src/vfx/ids.json`), ikony czarów `assets/skills/book/`, kamienie unikalne
  `assets/watra/unique_gems/a_*.png` (`tools/unique_gem_art.py`). Czary (`Skills` a_*):
  - Pociski Arkanów (zwykły atak): 3 pociski - pierwszy w najbliższego, reszta w losowych wrogów, lecą łukiem albo
    zakosami i skręcają coraz ciaśniej; ogon to Line2D z ostatnich pozycji (wygina się po torze, fioletowy gradient).
    5. - 4 pociski, 10. - co trzeci rzut +2; unikalny (Rozprysku) - 3 odłamki z trafionego w pobliskich (40%).
  - Krąg Mocy: rani w spłaszczonym kręgu pod postacią (pętla z kreatora gaśnie po 0,5 s). 5. - +30%, 10. - drugi błysk;
    unikalny (Trwałego Kręgu) - krąg zostaje 8 s (tyka co 0,5 s), w kręgu czary +30% i pocisk więcej.
  - Kule Arkanów: przełącznik jak aura (`Skills.is_toggle`, rezerwuje 20% many przez `ProtoHero.summon_reserved`),
    3 kule, obrót od szybkości rzucania, promień i wielkość od obszaru. 5. - +30%, 10. - +2 kule; unikalny (Podwójnej
    Orbity) - druga orbita 1,7x dalej w przeciwną stronę. Kamień Echo nie przełącza kul.
  - Promień Arkanów (trzymany): w najbliższego, co 0,2 s rani cel i wrogów w 26 px wokół, mana co sekundę; kafelki
    promienia z kreatora wzdłuż Line2D (AtlasTexture, klatka po klatce). 5. - przeskok na drugiego wroga (70%),
    10. - obszar x1,5; unikalny (Emanacji) - co 0,5 s krąg magii wokół postaci (40%).
  - Pieczęcie Wybuchu: pod 4 wrogami oddalonymi od siebie (co najmniej 40 px), po 0,8 s wybuch (arkusz pieczęci
    zsynchronizowany z opóźnieniem). 5. - 6 pieczęci, 10. - ogłusza 0,5 s; unikalny (Splecionych Pieczęci) - wiązka
    między kolejnymi pieczęciami rani dotykających (25% co 0,2 s).
- Testy: `tests/test_book.gd` (nowy), `test_elements.gd` (9 żywiołów); zrzuty `tools/book_shots.gd`.
- **Dopieszczenie (prośby autora 21.11.2026):** Pociski Arkanów wylatują po kolei co 0,08 s (`ProtoBook._volley`,
  `MISSILE_STAGGER`; kolejne rzuty mogą się zazębiać); aura Rój Strzyboga dokłada kule do każdej orbity (`_orb_count`
  + `extra_projectiles`); promień wychodzi z dłoni postaci (`_hand_point`, a nie spod księgi), z błyskiem w dłoniach
  (`arcane_beam_cast`) i wirem na końcu (`arcane_beam_impact`); kamień Emanacji - fala magii `arcane_wave` (3 nowe
  efekty z kreatora PixelLab); odłamki x1,4 większe, z ogonem, wolniejsze i lecą najpierw w dalszych wrogów (35-120 px).
  Wzdłuż promienia płyną spiralnie dwie nitki iskier (`ProtoBook._Spiral`, rysowane w kodzie: 40 iskier na nitkę,
  piksel albo dwa, lekki rozrzut i migotanie, spirala 11 px szersza niż promień, z przodu jaśniejsze).

## 20.11.2026 - symulowany rynek: targ w bazie (ROADMAP punkt 5)

Ankieta z autorem (20.11.2026): handel wszystkim, ceny w Runach Szlifu, rynek żyje też offline (do 12 h), osobny
targ obok kupca, oferty z imionami i nickami „graczy”, opłata targowa 10%, całość naraz. Wzór: rynek Watry.
- `scripts/market.gd` (Market - dane i symulacja), stan w `Game.market` (zapis „market”), funkcje `Game.market_*`.
  Niedostępny dla SSF (`Game.market_open`).
- **Czas**: chwila rynku co 10 min czasu rzeczywistego (`Market.TICK`), nadrabiana przy wejściu do bazy i otwarciu
  targu (`Game.market_catch_up`); przerwa liczy się najwyżej 12 h (`OFFLINE_MAX`), cofnięty zegar nic nie daje;
  `Game.market_clock` do testów.
- **Giełda** (`Market.COMMODITIES`): runy (bez Szlifu - to pieniądz), ruda i odpryski w paczkach po 10, klucz, dłuto,
  Pieczęć Oręża. Cena błądzi wokół bazowej (0,5-2x), kupno x1,05, skup x0,95 minus 10% opłaty, każda paczka gracza
  przesuwa cenę o 3%. Runy: kupno nigdy taniej niż rozmiana u kupca, skup nigdy drożej niż kupiec sprzedaje
  (`Market.ask` / `bid` z identyfikatorem) - bez Szlifów z niczego.
- **Płacenie**: najpierw Szlify, brakujące z innych run od najtańszej po cenie skupu, reszta w Szlifach
  (`Game.market_pay`, `market_wealth`); ceny od 10 Szlifów pokazane też w Runach Zmiany (`Market.price_text`).
- **Oferty innych graczy** (10 naraz, `roll_listing`): przedmioty (60%), kamienie, talizmany od lochu 5, z poziomu
  okolic najgłębszego przebitego lochu; cena 0,7-1,4 x uczciwej (`fair_price`), okazje („Okazja!”) szybko znikają,
  stare po 24 chwilach; 24 imiona i nicki (`NAMES`).
- **Moje oferty** (najwyżej 5): przedmiot z torby (kamienie z gniazd wracają do sakwy) albo kamień z sakwy, cena -/+;
  sprzedaż z szansą 0,3 x (uczciwa/cena)^2 na chwilę, powyżej 1,5 x uczciwej nikt nie kupi; Szlify po opłacie
  od razu i wiadomość w oknie („Radomir kupił(a): …”).
- **Okno** `scripts/ui/market_window.gd`: zakładki Giełda / Oferty / Moje i „Wróć” na dole, w nagłówku Szlify.
  Targ w bazie: handlarz z Watry (`assets/watra/base/market_trader.png`) ze straganem (`market_stall.png`) między
  kupcem a kukłami; pasek skrótów ma teraz 6 ikon w dwóch kolumnach (mieści się w dolnej połowie 16:9).
- Testy: `tests/test_market.gd` (nowy); zrzuty `tools/market_shots.gd`.

## 20.11.2026 - Napad Hordy i wykuwanie z rudy (ROADMAP punkt 4, krok 3 - koniec punktu)

Decyzje autora (ankieta 20.11.2026): obóz goblinów, wykuwanie za 20 rudy z losową rzadkością z najgłębszego lochu.
- **Napad Hordy** (`scripts/proto/proto_raid.gd`, `DungeonGoals.KINDS` "raid" od 5. poziomu): obóz (namiot kobolda
  i przewrócony wóz z rudą z Watry - `assets/watra/raid_tent.png`, `raid_cart.png`, `raid_ore.png`) pod słupem światła;
  przy postaci zaczyna się napad - RAID_TIME 45 s, co 4 s z 3 stron paczka 4-6 potworów goniących postać; czas płynie
  tylko w kręgu obozu (RAID_RADIUS 85, spłaszczony, poza nim „Wróć do kręgu obozu!” i miga krąg), łuk postępu na kręgu.
  Odparty: 6-10 rudy (x nagrody celów z drzewka, potem Skarbiec) i 40% na runę (x Skarbiec) - `arena._on_raid_looted`.
  Na drabince odblokowań; zrzuty `tools/raid_shots.gd`.
- **Wykuwanie** u kowala (`Game.forge`, `forge_problem`, `Items.FORGE_ORE` 20, `FORGE_WEIGHTS` 35/45/20 jak skrzynia
  Wodza): w oknie kowala pod torbą rząd 6 przycisków z ikonami miejsc (pierwsze stuknięcie „Wykuć?”, drugie wykuwa
  i otwiera opis nowego przedmiotu - od razu można go zmieniać runami); ruda w nagłówku okna kowala.
- Testy: `test_goals` (Napad Hordy), `test_runes` (wykuwanie), `test_base` (wykuwanie w oknie).

## 20.11.2026 - gra bez złota: ruda, wymiana run, Pieczęć Oręża (ROADMAP punkt 4, krok 2)

Liczby z ankiety z autorem (20.11.2026). Złoto zniknęło ze wszystkich miejsc w grze.
- **Ruda żelaza** (`Game.ore`, ikona z Watry `assets/watra/items/iron_ore.png`): rozbijanie przedmiotów zamiast sprzedaży
  (`Items.ore_value`: zwykły 1, magiczny 2, rzadki 4; rzadki 15% na Runę Szlifu - `Items.SCRAP_RUNE`), `Game.dismantle`,
  `dismantle_all`, `dismantle_loot` (auto rozbijanie zwykłych - dawne `auto_sell_common` - i pełna torba przy skrzyni,
  sygnał `ProtoLoot.scrapped`). Ruda pokazana w oknie „Postać” i w skrzyni; na razie zbierana pod wykuwanie (krok 3).
- **Skarbnik**: trafienie wybija 1 rudę (`ProtoSkarbnik.ORE_HIT`, sygnał `ore`), złapanie - 2 runy (`CATCH_RUNES`) i kamień.
- **Skarbiec** (węzeł `gold` drzewka lochów, 15 x 4%): `Game.treasury_mult` - więcej rudy (rozbijanie, Skarbnik) i większa
  szansa na runy (potwory - `ProtoHorde.rune_mult`, skrzynia Wodza, skrzynie-cele, runa z rozbicia rzadkiego).
- **Kupiec** (`scripts/shop.gd`, okno `shop_window.gd`): stała wymiana bez limitu - runa za Runy Szlifu po kursie x1,5
  w górę (Przekucie 3, Przydanie 5, Zmiana 8, Wyniesienie 9, Pieczęć 30), rozmiana run na Szlify po kursie, Klucz Runiczny
  za 2 Runy Zmiany, Dłuto Jubilera za Runę Wyniesienia (`Game.buy_offer`, `shop_problem`). Półka z dostawami po bossie
  (`Game.shop`, `restock_shop`) usunięta.
- **Kamienie**: ulepszanie tylko za odpryski x3 (`Gems.UPGRADE_SHARDS` 6,75 x poziom; szlachetne 15/30/60), rozbijanie
  x3 (`SHATTER_BASE` 6, unikalny 45), Kryształ Watry daje 18-36 odprysków (zniszczony 9); sprzedaż kamieni usunięta
  (`Game.shatter_gems`, `shatter_gem`, `Gems.can_shatter`).
- **Zakładki skrzyni** za przebite lochy 5/15/30/50 (`Game.STASH_TAB_LEVELS`, `_sync_stash_tabs` przy `beat_level`
  i wczytaniu; nigdy nie zabiera), w oknie napis „Następna zakładka po lochu N”, na drabince odblokowań (rodzaj `stash`).
- **Pieczęć Oręża** (`Gems.WEAPON_SEAL`, ikona Runy Pieczęci z Watry `gems/weapon_seal.png`): 3% ze skrzyni Wodza, gdy
  jest broń do odblokowania i gracz nie ma już pieczęci (`Game.roll_weapon_seal`); w liście broni przycisk „Pieczęć”
  (`Game.unseal_weapon`). Ceny broni w złocie (`Weapons.price_of`) usunięte.
- **Stary zapis**: złoto (z zapisem i dawnymi zwrotami) przelicza się raz przy wczytaniu (`Game._convert_gold`):
  losowa runa bez Pieczęci za 1000 zł (najwyżej 20), reszta 1 ruda za 100 zł (najwyżej 100); w bazie napis zamiast
  podpowiedzi sterowania (`Game.gold_converted`).
- Okno wyniku: „Runy: N” i „Ruda żelaza: +N” zamiast złota.
- Testy: `test_runes` (przeliczenie złota, rozbijanie hurtem), `test_base` (wymiana u kupca), `test_items`, `test_gems`,
  `test_stash`, `test_goals` (Skarbnik), `test_glaive` (Pieczęć Oręża), `test_skills`, `test_tree`, `test_characters`.

## 20.11.2026 - runy zamiast złota u kowala (ROADMAP punkt 4, krok 1)

Ankieta z autorem (ustalenia całego punktu w `docs/ROADMAP.md`, punkt 4). Krok 1: runy i kowal; złoto w innych
miejscach zostaje na krok 2.
- `scripts/runes.gd` (Runes): 6 run z Watry (`../Watra/scripts/item_craft.gd`, ikony w `assets/watra/items/rune_*.png`):
  Szlifu (nowa wartość wybranej premii), Przekucia (premia od nowa - `Items.reroll_affix`), Przydania (+premia do 2
  w magicznym / 4 w rzadkim), Wyniesienia (zwykły -> magiczny -> rzadki, brakujące premie dolosowane), Zmiany
  (wszystkie premie od nowa w liczbie rzadkości), Pieczęci (wybrana zostaje, reszta od nowa). Wagi 10/7/5/3/3/0,8,
  Wyniesienia od lochu 3, Pieczęci od 20. Kurs (`value`, w Runach Szlifu): 1/2/3/6/5/20 - dla kupca i rynku.
  `Runes.blocker` - czemu runy nie da się użyć (napis dla gracza), `Runes.apply` - działanie.
- Stan `Game.runes` (runa -> ile, zapis „runes”), `Game.use_rune` (zużywa jedną), `Game.add_rune` (łup), `Game.dev_runes`
  (+5 każdej, przycisk „+runy” w oknie deweloperskim). Usunięte: `Game.reroll`, `Items.reroll_price`, REROLL_* (kowal
  nie bierze już złota).
- Łup (propozycja Claude - do oceny): potwór 0,2% (`Runes.MONSTER`), elita 8%, skrzynia Wodza 2 runy + 50% na trzecią,
  skrzynia-cel 50% (`DungeonGoals.CHEST_RUNE`), Kryształ Watry 1-2 (`crystal_runes`, druga przy połowie zdrowia), Krąg
  Żertwy - runa (bez Szlifu) jako nowa nagroda do wyboru. Mnożnik łupu (drzewko, modyfikatory) działa na szanse.
  Na ziemi runa to {"rune": id} (`ProtoLoot`, poświata magiczna; Wyniesienia, Zmiany i Pieczęci - ze słupem światła).
- Okno kowala (`scripts/ui/smith_window.gd`): u góry zapas run, po stuknięciu przedmiotu opis z premiami i siatką
  6 run (nazwa i liczba); wybrana runa pokazuje opis; runy na premię dodają „Użyj” przy premiach, pozostałe -
  „Użyj runy” z potwierdzeniem. Zmienione premie błyskają.
- Klucz Runiczny i Dłuto Jubilera dostały nowe ikony (dawniej ikony Runy Wyniesienia i Szlifu): klucz - fioletowy
  kryształ z Watry (`gems/key_rune.png`, dawna Runa Zatarcia), dłuto - Runa Szlifu z zielonym znakiem (`gems/chisel.png`).
- Testy: `tests/test_runes.gd` (nowy), `test_base.gd` (kowal na runach), `test_goals.gd` (5 nagród Żertwy).
- Ikony run ze SpriteKiln (prośba autora: spójniejszy wygląd niż mieszanka ikon z Watry): wspólny kamień runiczny
  `art/specs/props/runes/rune_base.yaml` (64 px, 1 kierunek, kamień odchylony do kamery, światło z lewej góry, kamera
  bliżej niż w postaciach - ikona) i 6 specyfikacji `rune_<id>.yaml` (`extends`; kolor kamienia, świecący wyryty znak):
  Szlif - szary z jasnoniebieskim rombem, Przekucie - ciemny z pomarańczowym młotem (T), Przydanie - zielony z kiełkiem
  (Algiz), Wyniesienie - bursztynowy ze strzałą w górę, Zmiana - fioletowy (Nawia) z zygzakiem, Pieczęć - czarny ze
  złotą obręczą i kręgiem z krzyżem. Wynik w `assets/runes/` (render `out/rune_<id>/rune_<id>.png`, skopiowany ręcznie).

## 20.11.2026 - wydajność walki, część 2: siatka wrogów, łuk, glewia, hydrosfera; naprawa aur i talizmanów

Prośba autora: ten sam pomiar dla Poszukującej strzały (5 naraz, nieskończona mana, spam) przy 150 i 200-250
potworach, optymalizacja i przegląd innych broni (np. odbijające się cięcia Tańca glewii).
- `tools/combat_bench.gd`: WEAPON, SKILL, EVERY, ONLY_SKILL, PROJ (np. `WEAPON=bow SKILL=b_seeker EVERY=0.1 ONLY_SKILL=1
  PROJ=3` - Poszukująca 10. poziomu, 2 + 3 = 5 strzał co 0,1 s).
- **Siatka wrogów raz na klatkę** (`ProtoWeapon._frame_targets` układa cele w kratki 40 px; `_near(punkt, promień)`
  i `_near_c` dla środka celu zwracają tylko wrogów z kratek dookoła). Przepięte pętle wykonywane co klatkę albo przy
  każdym trafieniu: strzały w locie i szukanie celu Poszukującej (najpierw 90 px, potem cały zasięg), deszcz strzał,
  podmuchy, balista; cięcia i odbicia Tańca glewii, płonące strefy, wybuchy; pociski, wiry, kule i Strażnicy
  hydrosfery; iskry, łuki, burza i pełzające pioruny katany; przeskoki piorunów (`chain_next`), skok Mgnienia/Błysku,
  rozprysk, Młynek, rzut, fale, Rozłupanie, cios miecza; aury i talizmany.
- **Błąd z wcześniejszych etapów:** aury (Szron, Postrach, Mgła, Czarnobóg, Ognik, Gniew Peruna, Zwiastuny) i talizmany
  obszarowe (Serce Goblina, Lont Pożogi, Serce Głębin, ciernie, pioruny...) przeglądały samo `weapon.targets`, a w lochu
  potworów tam nie ma (są w grupie TARGETS) - raniły tylko kukły w bazie. Testy tego nie wyłapały, bo same dopisywały
  gobliny do tej listy. Teraz `weapon.live_targets()` / `targets_near()`. W lochu aury i talizmany zaczną działać
  naprawdę - do sprawdzenia balans.
- Trafienia obszarowe rozłożone na klatki (`ProtoWeapon._later`, najwyżej 24 na klatkę): tyknięcia wiru, deszczu
  strzał i płonących stref; skok Błysku - 12 trafień od razu, reszta w kolejnych klatkach.
- Limity efektów: `Fx.crowded` - najwyżej 40 drobnych efektów trafienia jednego rodzaju naraz (rozbryzgi hydrosfery
  dochodziły do 560), krytyczne liczby obrażeń najwyżej 90.
- Mniej pracy goblinów co klatkę: rozpychanie co drugą klatkę (`_sep_phase`), bez ponownego ustawiania tej samej
  animacji i prawie tego samego kierunku (`_play`, `_face`); węzeł stanu celu zapamiętany w polu (`ProtoTarget._st`),
  zasięg umiejętności na klatkę (`ProtoWeapon._area`).
- Wyniki (logika w klatce, komputer w chmurze, pełna walka - 22 aury, 3 talizmany, 4 modyfikatory): łuk 250 potworów
  10,6 → ok. 7 ms, 150 - 6,5 → ok. 4,5 ms; katana 150 - ok. 3,3 ms; glewia (Taniec) 250 - ok. 5 ms; najcięższa
  hydrosfera z wirem (wciąga tłum w jedną kulę) 45. poziom 150 - ok. 7 ms. Gra trzyma najwyżej 150 potworów
  (ProtoHorde.ALIVE_CAP), więc 250 to zapas.

## 20.11.2026 - Gęstsza Horda do 15 punktów i wydajność ciężkiej walki

Prośba autora: więcej punktów w Gęstszej Hordzie - 15 (do +60% potworów, `DungeonTree.NODES.horde`), i pomiar
płynności przy Błysku Peruna z aurami, talizmanami i modyfikatorami, a gdy spada - optymalizacja.
- Nowe narzędzie `tools/combat_bench.gd`: tłum (np. 150 potworów), katana z Błyskiem Peruna co 0,25 s i resztą
  umiejętności, 22 aury, 3 talizmany na 10. poziomie, 4 modyfikatory lochu; czas logiki w klatce (średni, 95%,
  najgorszy, ile klatek ponad 16,7 ms), najliczniejsze węzły; zmienne NO_AURA, ONLY_AURA, NO_TAL, NO_MODS, NO_CAST.
- Wynik przed poprawkami (komputer w chmurze, poziom 5, 136 potworów): średnio 20 ms, najgorsza klatka 198 ms.
  Winni: każde trafienie od nowa uruchamiało dźwięk potwora (ok. 0,7 ms, kilkanaście trafień na klatkę), ponad 800
  liczb obrażeń naraz, a `ProtoWeapon._live_targets` sprawdzał powtórki każdy z każdym i katana wołała go przy
  każdym przeskoku pioruna.
- Poprawki: wspólny limit dźwięku trafienia wszystkich wrogów (`ProtoTarget.hit_sound_ok`, co 45 ms - goblin, osiłek,
  bossowie), najwyżej 60 liczb obrażeń naraz (`ProtoTarget.MAX_NUMBERS`, krytyczne zawsze), spis celów raz na klatkę
  (`ProtoWeapon._frame_targets`), szukanie następnego celu pioruna bez kopiowania listy (`chain_next`), jeden
  wspólny materiał piorunów (`_bolt`).
- Po poprawkach: poziom 5, 136 potworów - średnio ok. 4,3 ms, najgorsza 14 ms; poziom 45 - ok. 4,2 ms, pojedyncze
  klatki do ok. 25 ms przy skoku Błysku w środek kuli 40-70 wrogów (każde trafienie z przeskokiem pioruna).
  Dla porównania przed poprawkami przy 102 potworach (stary limit +20%): 6-9 ms.

## 20.11.2026 - drzewko lochów (zamiast ulepszeń lochów za złoto)

Prośba autora: ROADMAP punkt 3, drzewko jak atlas w PoE. Decyzje autora: punkt za każdy **pierwszy raz przebity**
poziom lochu (`Game.tree_total` = `best_level`), stare ulepszenia znikają ze **zwrotem złota** (50/120/250/500/1000 za
stopień - `Game._fix_tree`), **rysowane drzewko** przesuwane palcem, cofanie **za darmo**, zestaw węzłów zaproponowany
przez Claude plus węzeł autora - cele spoza paska żaru.
- Dane `scripts/dungeon_tree.gd` (`DungeonTree`): Watra w środku, 4 gałęzie, w każdej mały węzeł (5 punktów) i dwa duże
  (10-15), otwarte po 1 punkcie w małym. HORDA: Gęstsza Horda +4% potworów → Łowy na elity +5% elit (15), Szybkie
  przyzwanie -2% żaru na Wodza (10). ŁUP: Hojność Watry +4% łupu → Skarbiec +4% złota (15, w `Game.add_gold`), Kamienie
  Watry +6% kamieni, aur i talizmanów (10, `ProtoHorde.gem_mult`). NAUKA: Nauka z walki +4% doświadczenia → Mistrzostwo
  +4% (15), Żar Watry +5% żaru (10). CELE: Długie ręce +6 px zasięgu → Hojne bóstwa +6 s daru kapliczki (10), Szczodre
  cele +5% nagród celów (15 - żar skrzyń, złoto Skarbnika, odpryski Kryształu), **Wędrowne cele** (10, pomysł autora):
  co 20 s 5% szansy za punkt na dodatkowy cel na mapie niezależnie od paska żaru, najwyżej 2 naraz (`arena._tick_wander`,
  nie wliczają się do progów paska).
- Stan `Game.tree` (zapis `"tree"`), `tree_add`/`tree_remove` (ostatni punkt małego węzła zabiera duże za nim)/
  `tree_reset`, `tree_add_problem`; po wczytaniu nieznane i zamknięte węzły znikają, a gdy punktów jest więcej niż
  przebitych poziomów - drzewko od nowa. Działanie: `arena._apply_upgrades`, `_summon_cost`, `_goal_reward`.
- Okno `scripts/ui/dungeon_tree_window.gd` (przycisk „Drzewko” w wyborze poziomu): węzły 48 px z liczbą punktów,
  linie od Watry świecą przy węzłach z punktami, przesuwanie palcem, na dole opis wybranego węzła (teraz i następny
  punkt) z „−” i „+”, „Od nowa” z potwierdzeniem. Ikony z Watry w `assets/watra/tree/`.
- Usunięte `scripts/dungeon_upgrades.gd` i `scripts/ui/upgrades_window.gd`. Test `tests/test_tree.gd`.

## 20.11.2026 - Rój Strzyboga, dynamiczna Poszukująca, 10. poziom strzału z Wielostrzałem

Prośby autora (pytania: siła, pociski, nazwa).
- Aura **Rój Strzyboga** (`Auras` "roj", 30% many): +1 pocisk naraz, od 5. poziomu +2 (`roj_extra`), kara obrażeń tych
  pocisków 10% na 1. poziomie, 0 na 10. (`aura_projectiles`, `aura_proj_penalty` -> `ProtoWeapon.extra_projectiles`,
  `projectile_mult`). Stożek - `ProtoWeapon.fan(aim, count, spread)`; działa na strzał łuku (też Wielostrzał),
  Poszukującą (też z przywołania), bańki hydrosfery (zwykły atak, też krążące z kamieniem, i pociski Strażnika)
  i bełty balisty. Przyszłe pociski - przez `fan`.
- Poszukująca: prędkość zależy od kąta do celu (prosto - do SEEK_MAX 380, przy zawracaniu do SEEK_MIN 90), po
  przebiciu SEEK_COAST 0,22 s leci prosto i hamuje (`coast`), potem zawraca i przyspiesza.
- Kilka Poszukujących naraz (zgłoszenie autora - leciały gęsiego na tego samego wroga): wybierając cel, liczą wroga
  ściganego już przez inną strzałę jak dalszego o SEEK_CLAIM 140 px (`_seek_target`), przy wylocie wolą wrogów
  w stronę swojego lotu; stożek szerszy (SEEK_PAIR 32°) i każda startuje odsunięta o SEEK_SPAWN 10 px w swoją stronę.
- 10. poziom strzału działał tylko bez kamienia: teraz co trzeci strzał +2 strzały (`SHOT_PERK_EXTRA`) i ze zwykłym
  strzałem (3 strzały), i z Wielostrzałem (7).

## 20.11.2026 - łuk (piąta broń, powietrze)

Pomysł i decyzje autora (pytania przed pracą): żywioł powietrze, loch 5 albo 1500 zł (pierwsza broń po mieczu),
kolejność odblokowania (mistrzostwo 3/6/10/15) - Poszukująca, Deszcz, Potężny, Balista; balista z kamieniem powtarza
nasze umiejętności (jak Strażnik hydrosfery); Poszukująca z kamieniem - przywołanie rezerwujące manę jak aura.
- `scripts/proto/proto_bow.gd` (`ProtoBow`): każde trafienie strzałą lekko odpycha (`AIR_PUSH`). Strzał (`b_shot`,
  najdalszy wróg, 5. - przebija pierwszego, 10. - co trzeci dwie strzały; kamień Wielostrzału - 5 strzał w stożku po
  70%), Poszukująca strzała (`b_seeker`, jak Strzała tropiąca Watry: stała prędkość, skręt łukiem, przelot przez
  trafionego, 4/6 trafień, z 10. dwie; kamień Wiernego Tropiciela - przywołanie `_SummonArrow` krąży przy postaci,
  co 1,5 s strzela, rezerwuje 20% many - `ProtoHero.summon_reserved`, `apply_reserve`, drugie użycie odwołuje),
  Deszcz strzał (`b_rain`, krąg 40 px przez 1 s co 0,2 s; 5. - x1,3, 10. - 2 s; kamień Ulewy - 3 deszcze na
  oddalonych wrogów), Potężny strzał (`b_power`, ładowany: pas 80-150 x 20-46 px, podmuch rani i odpycha, strzała
  280 px przebija wszystkich; 5. - szybciej, 10. - ogłusza; kamień Wichury - co 36 px toru podmuch na boki),
  Balista (`b_ballista`, 8/11 s, co 0,6 s bełt, 10. - dwie; kamień Oblężnika - `_ballista_echo` powtarza
  Poszukującą, Deszcz i Potężny siłą 0,5).
- Grafika: łuk `assets/weapons/bow.png` (Łuk Burzy z Watry), ikony umiejętności z Watry (`assets/skills/bow/`), ikony
  kamieni unikalnych (`tools/unique_gem_art.py`), balista ze SpriteKiln (`art/specs/props/ballista_base` i
  `ballista_turret` - podstawa stoi, górna część `face(dir)` i animacja `shoot`; zapas - obrazek z Watry), efekty
  z kreatora PixelLab (`bow_arrow`, `bow_hit`, `arrow_rain`, `seeker_trail`, `power_charge`, `power_gust`, `side_gust`).
- `Weapons`: łuk w `ORDER` zaraz po mieczu; hydrosfera ma krótką nazwę „Hydro” (5 broni w rzędzie okna umiejętności).
- Test: `tests/test_bow.gd`; zrzuty `tools/bow_shots.gd`.
- Okno umiejętności (prośba autora): zamiast rzędu przycisków broni jeden przycisk „<broń w ręku> ▾ Zmień broń”
  otwiera listę broni (`SkillsWindow.weapon_menu`, `open_weapons`): ikona, nazwa, żywioł, stan (w ręku / dostępna /
  od którego lochu i za ile złota), przycisk „Weź” / „Kup” (drugie stuknięcie potwierdza kupno), przewijana palcem.

## 20.11.2026 - 10 kamieni wspierających i 10 talizmanów z Path of Exile

Decyzja autora (ankieta): obie dziesiątki naraz. Działają z każdą bronią - podpięte we wspólnym trafieniu
(`ProtoWeapon._deal`, nowe `_support_hit`, `execute`, `elem_total`, `_tough`) i sygnale `skill_used`.
- Kamienie (`Gems.SUPPORT`, ikony z Watry w `assets/watra/supports/`, `focus` i `execute` przebarwione): Echo (15-40%
  szans na powtórkę umiejętności za darmo po 0,35 s - `_on_skill_used`, `_echo_pending`; nie w zwykłym ciosie -
  `Gems.fits`, problem gniazda "basic"), Skupienie (+25-60% obrażeń, obszar x0,75), Rozprysk (20-55% obrażeń wrogom
  w 32 px od celu), Przebicie (-8-25 pkt odporności trafionych; zamiast przelatywania pocisków - to trzeba by pisać
  osobno dla każdej broni), Odrzut (push_away siła 60-150), Egzekucja (dobija poniżej 6-15% zdrowia, elity i bossów
  poniżej połowy - `ProtoTarget.health_fraction`, `remaining_hp`), Hipotermia (+20-50% na spowolnionych), Spalenie
  (+20-50% na płonących - `ProtoTarget.is_burning`), Bystre Oko (+5-15 pkt krytyka i 4 razy tyle obrażeń
  krytycznych), Twardość (po trafieniu 8-20% mniej obrażeń na 3 s - `ProtoHero.fortify`).
- Talizmany (`Talismans.DATA`, ikony - trofea z Watry): Łuska Żmija (krytyk - +30% obrażeń od żywiołów na 8 s,
  `elem_extra`), Hak Kata (dobija poniżej 8%), Poroże Jelenia (25% przy zabójstwie - +15% ruchu i ataku na 4 s,
  `speed_bonus`, `move_bonus`), Świeca Wiedźmy (po 50 wydanej many +15% obrażeń i +50% odnowy many na 4 s, sygnał
  `ProtoHero.mana_spent`), Lont Pożogi (płonący pokonany podpala sąsiadów w 50 px), Krwawe Serce (umiejętności płacą
  zdrowiem 100% -> 73% kosztu, `ProtoHero.blood_magic`, `can_pay`; aury bez limitu „mana na najdroższą
  umiejętność”), Nić Mokoszy (20-33% obrażeń bierze mana, `mana_shield`), Krzesiwo Swaroga (fizyczne -> ogień, +10-28%,
  `fire_convert`), Kieł Niedźwiedzia (do 60 px +25%, od 130 px -12,5%, `point_blank`), Szpon Upiora (poniżej połowy
  zdrowia +30%). Premie na chwilę liczy `ProtoTalismans._update_buffs` (mnożnik `bonus_mult` z Czaszką Biesa).
- Okno „Postać”: zakładka „Sakwa 126” bez nawiasów (z nawiasem ucinało się przy 10+ kamieniach).
- Testy: `test_talismans.gd` (`_test_poe` - każdy kamień i talizman w walce), `test_gems.gd`.

## 20.11.2026 - próba: wrogowie x3 zdrowia i x2 obrażeń

Prośba autora (na próbę, do oceny na telefonie): wszyscy wrogowie mają 3 razy więcej zdrowia i zadają 2 razy więcej
obrażeń. `DungeonLevels.enemy_hp` (3,0, w `hp_mult` - potwory i bossowie) i `enemy_damage` (2,0 - `ProtoHero.enemy_damage`
w `take_damage` i `ignite`: ciosy, strzały, wybuchy elit, podpalenia). Zmienne statyczne, żeby testy liczące na
konkretnych liczbach mogły je wyłączyć (test_auras, test_catacombs, test_flooded, test_horde, test_items, test_volcano).
Ocena autora po testach na telefonie: „jest super - czuć, że trzeba pofarmić, a postęp daje więcej satysfakcji” -
zostaje na stałe. Zmiana: dwie liczby w `scripts/dungeon_levels.gd`.

## 20.11.2026 - przewijanie palcem i szerokość okna talizmanów

Zgłoszenie autora: okno talizmanów nie mieściło się na ekranie, a listy przewijały się tylko w wąskich szczelinach
między wierszami (wiersze i przyciski łapały dotyk), suwaki z boku za wąskie.
- `TouchUi.drag_scroll(scroll)`: kontrolki w środku listy (też dodawane później - `SceneTree.node_added`) dostają
  MOUSE_FILTER_PASS, więc przeciągnięcie po wierszu i przycisku przewija listę, a stuknięcie dalej działa (przycisk przy
  przewijaniu się nie wciska); pasek przewijania szerszy (`SCROLLBAR_WIDTH` 10 px). Podpięte we wszystkich 10 listach
  (okno „Postać”, umiejętności z zakładkami Kamienie i Aury, wybór kamienia, okna bazy, pauza, tryb deweloperski,
  wybór postaci, wynik wyprawy).
- Okno talizmanów i zakładka „Aury”: tytuł „Nazwa 10/10” (bez „poz.”, czcionka 13) zawija się zamiast rozpychać okno
  (Szczęka Pożeracza 10/10 wypychała „Wróć” za ekran), mniejsza ikona (34 px) i przycisk (70 px). Dolny pasek zakładek
  okna „Postać” - czcionka 11, szersze „Ekwipunek”, „Statystyki”, „Talizmany”.
- Test: `tests/test_touch_ui.gd` (przeciąganie przez Input.parse_input_event).
- Nowe ikony i nazwy talizmanów (zgłoszenie autora: pierścienie myliły się z pierścieniami ekwipunku) - trofea
  i magiczne przedmioty z Watry: Róg Gruzłoga (był Sygnet), Pióro Gromu (Pierścień Gromu), Perła Topieli (Pierścień
  Topieli), Gałąź Leszego (Obręcz), Kora Leszego (Żołądź), Czaszka Biesa (Szpon), Ząb Pożeracza (Szczęka), Kryształ
  Peruna (Korona); Serce Goblina i Serce Głębin bez zmian. Identyfikatory w zapisie te same.
- Serce Głębin - nowy efekt z kreatora (prośba autora, kolce uderzenia w ziemię się nie podobały): `earth_tremor`
  (świecące pęknięcia i ziemista fala, 9 z 10 klatek, pod postacią - z_index -1), `ProtoTalismans.TREMOR_FX`.

## 20.11.2026 - obrażenia od żywiołów, nowe efekty talizmanów i aur

Decyzje autora: premia przedmiotów „+% obrażeń od żywiołów” wzmacnia też talizmany (sposób 1 - talizmany zostają bez
statystyk), nowe efekty z kreatora PixelLab tam, gdzie gra używała zastępczych.
- `Items`: premia `elem_dmg_pct` („+%d%% obrażeń od żywiołów”, 6-12% +0,8 na poziom lochu, bez sufitu), okno „Postać”
  - wiersz „Obrażenia od żywiołów”. `ProtoWeapon.elem_mult` (arena z sumy cech): mnoży trafienia żywiołem - broń żywiołu
  (glewia, hydrosfera, katana), ogień Swaroga, kamienie Żar / Szron / Piorun (liczone od ciosu bez premii broni, żeby
  nie mnożyć jej dwa razy - `elem_base`), `aura_hit` (aury i talizmany), podpalenie Zwiastuna Popiołu; fizyczne bez zmian.
- Sygnet Gruzłoga rani teraz żywiołem ziemi (wcześniej fizycznie).
- Nowe efekty z kreatora (`pixellab_src/vfx/ids.json`, `python tools/vfx_art.py`, w „My effects” autora):
  `frost_shatter` (Zwiastun Mrozu - kolce lodu, krąg i odłamki; większy ze spowolnionego), `roots_snare` (Obręcz
  Leszego - brązowe korzenie), `thorn_burst` (Żołądź Leszego - wieniec cierni), `blood_heal` (Szczęka Pożeracza -
  czerwone plusy leczenia, 12 z 14 klatek). Zwiastun Popiołu - wybuch glewii zamiast rysowanego kręgu (`_Burst` usunięty).

## 19.11.2026 - talizmany (przedmioty specjalne)

Pomysł autora (3 miejsca na przedmioty bez statystyk, z efektem). Decyzje z ankiety: forma - talizmany w 3 miejscach,
wypadają ze skrzyń na mapie lochu i z Kręgu Żertwy, 10 efektów od lochu 5, poziomy 1-10 za duplikaty (jak aury).
- `scripts/talismans.gd` (`Talismans`): `SLOTS` 3, `MAX_LEVEL` 10, `MIN_LEVEL` 5, `CHEST_CHANCE` 10% (razy mnożnik łupu),
  dane 10 talizmanów (`DATA`: nazwa, ikona z Watry w `assets/watra/talismans/`, kolor, kiedy działa - `trigger`,
  szansa i siła [poziom 1, przyrost]), opisy (`effect_text`), `roll_chest`, `roll`.
- 10 efektów (szansa / siła na 1. poziomie): Sygnet Gruzłoga (10%: fala 40 px, 80% ciosu, ogłuszenie 0,6 s),
  Pierścień Gromu (10%: grom Peruna 100% ciosu i przeskok na 2 wrogów w 70 px, porażenie), Pierścień Topieli (8%: wir
  60 px ciągnie wrogów, 4 razy po 25% ciosu wodą, przemoczenie), Obręcz Leszego (10%: korzenie 35 px, 40% ciosu,
  oplątanie 1,5 s +0,1/poz.), Żołądź Leszego (35% przy ranie: ciernie 45 px, 100% ciosu), Szpon Biesa (30% przy
  zabójstwie: +6% obrażeń na 5 s, do 5 razy - `ProtoWeapon.bonus_mult`), Serce Goblina (20%: wybuch pokonanego 45 px,
  60% ciosu ogniem), Szczęka Pożeracza (10%: leczy 2% zdrowia), Serce Głębin (co 3 s, -0,1 s/poz.: drżenie ziemi
  60 px, 50% ciosu), Korona Peruna (Archmage z PoE: każda umiejętność z kosztem many ciska piorun w najbliższego
  wroga - 30% ciosu + 15% pełnej many; umiejętności droższe o 25%, -1 pkt/poz. - `ProtoWeapon.mana_tax`).
  Efekty przy trafieniu najwyżej raz na 0,25 s (`HIT_GAP`); ranią przez `ProtoWeapon.aura_hit` (nowy parametr `flat`).
- `ProtoTalismans` (`scripts/proto/proto_talismans.gd`, dziecko postaci): `on_hit` (z `ProtoWeapon._deal`), `on_kill`
  (`ProtoHorde.monster_died`), `on_hurt` (nowy sygnał `ProtoHero.hurt`), `on_skill` (`ProtoWeapon.skill_used`),
  drżenie co kilka sekund; animacje z gry (fala z Watry, grom Peruna katany, wir hydrosfery, kolce Rozłupania,
  wybuch glewii, leczenie Nekromanty, uderzenie w ziemię). Arena: `talismans_node`, `_link_talismans`.
- `Game`: `talismans` (talizman -> poziom), `talisman_slots`, sygnał `talismans_changed`, `add_talisman` (nowy sam
  wskakuje w wolne miejsce), `equip_talisman` (zamiana miejsc), `unequip_talisman`, `worn_talismans`, zapis;
  `priciest_skill` liczy dopłatę Korony Peruna. `ProtoLoot`: łup `{"talisman": id}`. `DungeonGoals.chest_items`
  i `zertwa_offer` (od lochu 5 czwarta nagroda - talizman, żar zawsze ostatni).
- Okno „Postać”: zakładka „Talizmany” (3 miejsca, lista z poziomem i działaniem, „Załóż” / „Zdejmij”; przy pełnych
  miejscach „Załóż” każe stuknąć miejsce do zamiany).
- Test: `tests/test_talismans.gd`.

## 19.11.2026 - aury rezerwujące manę (krok 2: pozostałe 13 aur, mniejsza rezerwacja)

Decyzje autora (ankieta): dopasowania z ROADMAP bez zmian, premia „mniejsza rezerwacja many” na przedmiotach.
- `Auras`: 21 aur (`ORDER`, `DATA`), nowe stałe (`CIRCLE_TICK` 0,25 s, `MARK_TIME`, `POSTRACH_SLOW` 10%,
  `CZARNOBOG_BUILD` 4 s / `CZARNOBOG_FADE`, `MOKOSZ_DELAY` 3 s, `STONE_BELOW` 35%, `HERALD_RADIUS` 45 px, `MROZ_SLOW`,
  `MROZ_CHILLED` x1,5, `LICHO_TIME` +30%, `JARYLO_CRIT_DMG` x4, `WELES_XP` /10), `reserve_sum` (bez przycinania -
  sprawdzanie przy włączaniu i wczytaniu; przy kroku 1 wczytanie nie odrzucało nadmiaru), `cut_of`.
- Nowe aury (siła na 1. poziomie, przyrost za poziom, rezerwacja): Postrach (krąg 80 px: -15% obrażeń wrogów, +1,5;
  -10% szybkości; 30%), Mgła Nawii (krąg 86 px: 15% chybień, +1,5; 30%), Opieka Mokoszy (tarcza 15% zdrowia, +1,5,
  pełna po 3 s bez trafienia; 30%), Piętno Czarnoboga (krąg 76 px: do +20% obrażeń, +2, rośnie przez 4 s; 30%),
  Oko Jaryły (+5 pkt szansy na krytyk i +20% obrażeń krytycznych, +0,5 / +2; 25%), Pancerz Trzygłowa (+8% ochrony,
  +0,8; 30%), Kamienna Krew (-30% obrażeń poniżej 35% zdrowia, +2; 20%), Zwiastun Popiołu (wybuch zabitego 40%
  ciosu ogniem + podpalenie, +5; 25%), Zwiastun Mrozu (odłamki 40% ciosu mrozem, x1,5 ze spowolnionego, -30% szybkości;
  25%), Złość Licha (podpalenia +25% i +30% dłużej, +3; 30%), Pieczęć Rodu (+12% odporności na żywioły, +1,2; 30%),
  Hart Żywiołów (sufit odporności +5 pkt, do 85% na 10. poziomie; 35%), Dłoń Welesa (+50% zasięgu zbierania i +5%
  doświadczenia, +5 / +0,5; 20%).
- Wrogowie: `ProtoTarget.hit_hero` zamiast `hero.take_damage` w potworach i bossach (znaki `aura_weak`, `aura_miss`,
  `aura_until`; strzały i wybuch elity Lotnej bez zmian), `pride` (mnożnik w `ProtoWeapon._deal` i `aura_hit`),
  statyczne `burn_power` / `burn_length` (Licho, ustawia `Arena._apply_weapon`).
- `ProtoHero`: tarcza (`shield`, `shield_max`, sygnał `shield_changed`, jasny pas na dole paska zdrowia - `Arena.shield_bar`),
  `stone`, `max_res_bonus`, `enemy_missed` (napis „Chybił!”). `Items.totals` zostawia `element_res_raw` (dla Hartu).
- `ProtoAuras`: `_circle_tick`, `on_monster_died` (z `ProtoHorde.monster_died`, wybuch odroczony), krąg wybuchu `_Burst`.
- Przedmioty: premia `reserve_pct` („% mniejsza rezerwacja many przez aury”, 2-4% +0,04 na poziom lochu, sufit 20%),
  tylko pierścień i amulet (`AFFIXES` pole `slots`, `Items.affix_fits` - też u kowala); `Game.aura_cut`.
- Test: `tests/test_auras.gd` (krok 2 - `_test_step2`).

## 19.11.2026 - aury rezerwujące manę (krok 1: 8 aur)

Pomysł autora; lista 21 aur zatwierdzona 19.11.2026 (z gałęzi `ccr-23c5ddf4-xminpb`, kod tamtej gałęzi był na starej
wersji gry - przeniesiony i dopasowany). Decyzje autora z tej sesji (ankieta): kamienie aur od lochu 8 (na 1. poziomie
postać ma 50 many, a umiejętności kosztują 15-45, więc 2 aury po 25-35% zablokowałyby umiejętności), aura od razu przy
podniesieniu (bez sakwy), w tej sesji fundament i 8 aur.
- `scripts/auras.gd` (`Auras`): dane 8 aur (`DATA`: nazwa, rezerwacja `reserve`, kolor, zasięg kręgu, siła `power`
  [poziom 1, przyrost]), `MAX_RESERVED` 75%, `RESERVE_CUT` 2% taniej za poziom, `MIN_LEVEL` 8, szanse kamienia
  (`CHEST_CHANCE` 25% skrzynia Wodza, `GOAL_CHEST_CHANCE` 12% skrzynia na mapie lochu, razy mnożnik łupu - `roll_chest`),
  premie postaci (`apply` dopisuje do sumy cech przedmiotów: Strzybóg `move_pct` i `attack_speed_pct` z sufitami,
  klucze `aura_hp_pct`, `aura_regen_pct`, `aura_mana_regen_pct`, `aura_reserve`, `aura_fire`), opisy (`effect_text`),
  ikona rysowana w kodzie (`icon_of`).
- 8 aur: Krzepa (+20% zdrowia, +2/poz., 25%), Wiatr Strzyboga (+10% ruchu i ataku, +1/poz., 30%), Źródło Żywii
  (1% zdrowia/s, 20%), Źródło Many (2% many/s, 15%), Żar Swaroga (+15% ciosu jako ogień i podpalenie za połowę tego,
  `ProtoWeapon.aura_fire`, 25%), Gniew Peruna (co 3 s piorun w najbliższego wroga do 220 px, 120% ciosu, porażenie 2 s,
  35%), Błędny Ognik (krąży 40 px wokół postaci, 50% ciosu ogniem, ten sam wróg co 0,6 s, 35%), Szron Marzanny
  (krąg 70 px: -25% szybkości i co 0,5 s 15% ciosu mrozem, 25%). Trafienia aur - `ProtoWeapon.aura_hit` (rzut
  obrażeń broni, premia przeciw elitom, odporność celu, bez krytyków i kamieni).
- `Game`: `auras` (aura -> poziom), `auras_on`, sygnał `auras_changed`, `add_aura` (nowa / poziom wyżej / 0 na 10.),
  `toggle_aura`, `aura_problem` - limit 75% i zasada „aury nie zabierają many na najdroższą umiejętność w miejscach”
  (`priciest_skill`, koszt z poziomem umiejętności, bez kamieni; sprawdzane przy włączaniu), zapis, `reset_hero`;
  `gear()` zawiera premie aur.
- `ProtoHero`: `reserved`, `mana_cap()` (mana napełnia się najwyżej do tej granicy), zdrowie, odnowa i rezerwacja
  z `HeroStats.max_hp`, `max_mana`, `reserved_mana`, `regen`; wyłączona aura nie dolewa many od razu.
- `ProtoAuras` (`scripts/proto/proto_auras.gd`, dziecko postaci): obracające się kręgi w kolorach aur, piorun, mróz, ognik.
- Arena: ciemny pas rezerwacji z ikonkami aur na pasku many (`mana_reserved`, `aura_icons`), napis „mana / dostępna”,
  kamień aury w skrzyni Wodza; `DungeonGoals.chest_items` - w skrzyni-celu. `ProtoLoot`: łup `{"aura": id}`
  (świeci jak rzadki, napis „Nowa aura” / „poziom N” / „już najwyższy poziom”).
- Okno umiejętności: zakładka „Aury” (suma rezerwacji, wiersz każdej aury, „Włącz” / „Wyłącz”, powód odmowy w podpowiedzi).
  Okno „Postać”: mana „150 (wolne 90)”, zdrowie i odnowa z aurami.
- Test: `tests/test_auras.gd`.

## 19.11.2026 - szlif efektowności: Sąd Peruna, Rozłupanie Ziemi, Krąg stali, Płonąca bruzda

Wybór autora (ankieta): cztery umiejętności dostają mocniejszy wygląd i „kulminację”. Nowe efekty z darmowego
kreatora PixelLab (`pixellab_src/vfx/ids.json`, `python tools/vfx_art.py`).
- Sąd Peruna (`ProtoKatana._perun_storm`, `_perun_bolt_hit`): po cięciu wzdłuż linii biją gromy z nieba
  (`PERUN_STORM` 3-6 sztuk wg obszaru, co `PERUN_STORM_GAP` 0,06 s po `PERUN_STORM_DELAY` 0,1 s), każdy rani
  `PERUN_STORM_POWER` 0,35 siły w promieniu `PERUN_STORM_RADIUS` 22 px i poraża; drgnięcie kamery, ostatni - błysk
  ekranu (`_screen_flash`). Efekt `perun_bolt` („Sąd Peruna - grom z nieba”).
- Rozłupanie Ziemi (`ProtoWeapon._slam_crack`, `_slam_spike`): od miejsca uderzenia w stronę ataku biegnie szczelina
  (`SLAM_CRACK` 120 px w `SLAM_CRACK_TIME` 0,25 s), z której wyskakuje `SLAM_SPIKES` 5 skalnych kolców (promień 20 px,
  0,5 siły, ogłuszenie 0,6 s). Bez kolców przy echu i wstrząsach wtórnych. Efekt `slam_spikes`.
- Krąg stali (`ProtoWeapon._start_ring`, `_process_ring`, `_clear_ring`): widmowe miecze rozjaśnione (`STEEL_BRIGHT`),
  ze świecącymi smugami (`STEEL_TRAIL` 8 punktów, błękit `STEEL_GLOW`), błysk przy przywołaniu i znikaniu, widoczna
  orbita, błękitne iskry trafień.
- Płonąca bruzda (`ProtoGlaive._furrow_debris`): za każdym ognistym cięciem bruzdy sypią się iskry (addytywne)
  i grudki ziemi (`DEBRIS_EARTH`, szybciej opadają) - dwa emitery CPUParticles2D przy ziemi pod cięciem, w układzie
  świata. Same efekty - bez zmian siły. (Wcześniejsze wersje - słup płomieni, a potem biegnąca szczelina lawy -
  odrzucone przez autora i usunięte.)
- Błąd: po zmianie broni lecące efekty (fala miecza, cięcia i płonąca ziemia glewii, pociski i wiry hydrosfery, łuki
  i pioruny katany) zostawały zamrożone na ekranie. Teraz każda broń zwraca swoje listy w `_world_fx()`, a
  `ProtoWeapon._exit_tree` usuwa ich węzły (`_free_fx` pomija cele i postać). Test w `test_glaive.gd`.
- Poprawka po uwadze autora: przy Rozłupaniu Ziemi nie ma już jasnych kolców `ground_slam` przy postaci - uderzenie
  to od razu ciemny kolec fali (echo i wstrząs wtórny też); `ground_slam` został tylko przy wybuchu Młynka.
- Trafienie miecza (prośba autora): każde trafienie miecza poza Rozłupaniem Ziemi rysuje na celu proste cięcie
  (`ProtoWeapon._sword_cut_fx`, efekt `sword_cut` z kreatora - „Miecz - trafienie prostym cięciem”), w poprzek
  kierunku od postaci, rozjaśnione, wielkość `SWORD_CUT_FX_SIZE` 0,8; najwyżej 6 na klatkę (tłum przy Młynku).
  Tylko miecz (`get_script() == ProtoWeapon`) - glewia, hydrosfera i katana mają swoje efekty.
- Opisy umiejętności zaktualizowane; zrzuty `tools/perun_shots.gd`, `slam_shots.gd`, `ring_shots.gd`, `furrow_shots.gd`.

## 19.11.2026 - najdalszy cel dla pocisków i linii; nowy Taniec ostrza (cienkie linie, potem wybuch)

Decyzje autora (ankieta): umiejętności, które lecą przez tłum, celują w najdalszego wroga w zasięgu; zwykły cios
i skoki obronne zostają przy najbliższym. Taniec ostrza wyglądał jak seria szybkich zwykłych ciosów - przebudowa:
najpierw cienkie, precyzyjne linie, potem w tych samych miejscach naraz grube, efektowne cięcia.
- Najdalszy (`ProtoWeapon._farthest`): Rzut mieczem, bańka hydrosfery (zwykły atak), Fala (`_spawn_tide`), bruzda
  i sierpy glewii (`g_trail`, `g_dance`), Sąd Peruna katany. Opisy umiejętności zmienione.
- Taniec ostrza (`ProtoKatana._dance_line`, `_dance_burst`): każde cięcie to prosta, świecąca linia długości `DANCE_LINE`
  70 px (x obszar), skośnie o `DANCE_SLANT` 28° na przemian (krzyżują się jak „X”; Kamień Wiru Ostrza - gwiazda dookoła),
  katana przemyka wzdłuż linii, rani lekko (`DANCE_THIN` 0,3 siły). Po ostatnim cięciu `DANCE_BURST_DELAY` 0,3 s ciszy
  i wszystkie linie naraz wybuchają grubym cięciem (efekt `katana_dance_burst` z kreatora PixelLab, „Taniec ostrza -
  wybuch cięcia”), `DANCE_BURST` 0,9 siły w pasie x1,8, drgnięcie telefonu i kamery; potem piorun między trafionymi.
- Testy poprawione (Rzut i Fala celują w najdalszego); zrzuty `tools/dance_shots.gd`.

## 19.11.2026 - wiązki piorunów: najdalszy cel, bez powtórek; nowe wyładowanie Błysku Peruna

Prośba autora: wyładowanie z 10. poziomu Błysku Peruna (co 5. skok) zasłaniało postać - ma być wiązką błyskawic
przeskakującą po kilku wrogach. Wszystkie wiązki mają skakać do najdalszego dostępnego wroga (żeby było je widać)
i nie trafiać drugi raz tego samego, gdy są nietrafieni (dwóch wrogów - wiązka skacze między nimi).
- `ProtoWeapon._chain_from` to teraz wiązka po kolei (z ostatnio trafionego, nie wachlarz ze źródła): `chain_next` -
  najdalszy żywy wróg w zasięgu spoza trafionych tą wiązką, inaczej najdalszy z trafionych (nigdy ten, na którym jest).
  Działa dla kamienia Piorun, przeskoków katany (cięcia, kontry, 10. poziom Tańca) i combo z przemoczeniem.
- Błysk Peruna 10. poziom (`ProtoKatana._flicker_spin`): piorun z katany w najdalszego wroga w `FLASH_CHAIN_RANGE` 110 px
  (x obszar), potem `FLASH_CHAIN_JUMPS` 4 przeskoki (zasięg 90 px x obszar), każdy 80% siły, poraża; zabicia zwracają
  manę jak skok. Zamiast wybuchu wokół postaci.
- Koniec Tańca ostrza - piorun skacze między trafionymi do najdalszego; 5. poziom cięcia katany - piorun w najdalszego
  wroga w zasięgu (`ProtoWeapon._farthest`).
- Testy w `tests/test_katana.gd`, zrzut `tools/chain_shots.gd`.

## 19.11.2026 - obszar umiejętności w kamieniach unikalnych

Prośba autora: kamienie unikalne, do których to pasuje, mają rosnąć z obszarem umiejętności (np. łuk Gromowego Ostrza).
Przegląd wszystkich 20 kamieni: większość już używała `_area` (fala cięcia i fale Rozłupania miecza, Wieczny Wir,
Krąg stali, kontry Riposty, Wędrowne Gromy, Taniec ostrza, Pogorzelisko, Ognisty Deszcz, Bumerang, Rykoszet Płomieni,
Wodna Orbita, Wędrowny Wir, Erupcja). Poprawione:
- Kamień Gromowego Ostrza (katana): łuk pioruna jest szerszy i trafia szerzej (`_SparkArc.scale`, `SPARK_RADIUS` x obszar)
  - wcześniej z obszarem rósł tylko jego zasięg.
- Kamień Rykoszetu (Rzut): zasięg odbić x obszar (`THROW_BOUNCE_RANGE`; też odbicie z 5. poziomu).
- Fala hydrosfery (też Kamień Przypływu i echo Strażnika): trafia w promieniu x obszar (`WAVE_RADIUS`) - wcześniej
  rósł tylko obrazek (błąd także bez kamienia).
- Testy w `test_katana.gd` i `test_hydrosphere.gd`.

## 19.11.2026 - koszty many umiejętności, mana z przedmiotów, mana za zabicie

Uwaga autora: umiejętności kosztują za mało - da się nimi spamować bez rozwiniętej odnowy many i bez Oszczędności;
spam ma być możliwy dopiero przy dopracowanym buildzie, a wyższe poziomy umiejętności powinny kosztować więcej (jak w PoE).
Główna przyczyna: premie „+mana” i „+odnowa many” rosły z siłą lochu jak zdrowie (101. poziom: ~2800 many i ~144/s
z losowych rzadkich przedmiotów przy kosztach 10-30).
- Premie many liniowo: `mana` 5-12 + 0,6/poziom lochu, `mana_regen` 0,3-0,8 + 0,03/poziom (101.: do +72 i +3,8/s na
  premię). Stare przedmioty przycinane przy wczytaniu, stare kamienie szlachetne w sumie cech (`Items.clamp_affix`,
  `affix_max`, `CLAMPED_STATS`).
- Koszt many rośnie z poziomem umiejętności: +12% na poziom (`Skills.level_mana`, 10. poziom x2,08); poziomy 3 i 7
  skracają już tylko odnowienie (`level_cost`). Bazowe koszty x1,5 (np. Młynek 15/s, Rzut 22, Rozłupanie 38, Krąg 45).
  Okno umiejętności: „+12% many” w opisie następnego poziomu.
- Odnowa many z poziomem postaci: 3/s + 0,1 na poziom (`HeroLevels.mana_regen`, 50. ~7,9/s; `ProtoHero._mana_regen`).
- Nowa premia „Mana za zabicie” (`mana_on_kill` 0,2-0,4 + 0,005/poziom, szafiry, sufit 2 na zabicie; ułamki zbierają
  się w `ProtoHorde._mana_acc`), wiersz w oknie „Postać”.
- Bilans (średnio z 40 losowań, 4 zabicia/s): 101. loch - losowe przedmioty ~14 many/s, build na manę ~52/s; Młynek
  10. poziomu ~22/s (z Oszczędnością ~12), trzy umiejętności na odnowieniu ~38/s (z Oszczędnością ~21). Loch 5 -
  losowe ~5,5/s, Młynek 15/s, trzy umiejętności ~15/s.
- Testy `_test_mana` w `tests/test_items.gd`, poprawione liczby w `test_skills.gd`.

## 17.11.2026 - wspólna odporność potworów i przebicie odporności (wariant A)

Pytanie autora: czy dać potworom równe odporności na wszystko (też fizyczne)? Porównanie z Diablo 3 (bez odporności),
PoE (odporności żywiołów + przebicie) i Last Epoch (odporność rośnie z poziomem obszaru, przebicie i rozbijanie) -
decyzja autora: wariant A (odporność z głębią + przebicie + łagodny charakter lochów). Zastępuje szybszy wzrost
zdrowia i mocne odporności lochów z poprzedniego punktu (ten sam dzień).
- `DungeonLevels.base_resist`: wspólna odporność na wszystko, także fizyczne, `RESIST_STEP` 0,55% na poziom do
  `RESIST_MAX` 55% (10. ~5%, 50. ~27%, 101. 55%). `HP_GROWTH` z powrotem 1,0 (haczyk `hp_mult` zostaje).
- `Dungeons.RESISTS` - łagodny charakter lochu ±20% (Zatopione: woda +20%, Grom -20%; Katakumby: Nawia +20%, ogień -20%;
  Górskie równiny: Grom +20%, lód -20%; Wulkan: ogień +20%, woda -20%), `Dungeons.resists(id, level)` = wspólna + charakter.
- Przebicie odporności: premia `pen_pct` (przedmioty 2-5% + 0,1% na poziom lochu, rubiny w puli kamieni szlachetnych,
  sufit 55%), `ProtoWeapon.penetration`; `ProtoTarget.resist(element, pen)` zmniejsza odporność najwyżej do zera
  (wrażliwości nie pogłębia). Działa w ciosach, piorunie i szronie z kamieni, podpaleniu. Wiersz „Przebicie odporności”
  w oknie „Postać”.
- Wybór poziomu: „Odporność potworów: X% · Bardziej: … · Mniej: …”.
- Wynik (średnio z 30 losowań: 50. poziom postaci, rzadkie przedmioty, zwykłe cięcie): 101. loch - goblin ~2,8 ciosu,
  boss ~72; z przebiciem 45% - goblin ~1,4, boss ~36. Test `_test_resists` w `tests/test_elements.gd`.

## 17.11.2026 - obrażenia w głębi: więcej zdrowia potworów, słabszy poziom, odporności lochów

Uwaga autora po testach lochów 101 i 104 (50. poziom, losowe przedmioty z poziomu, umiejętności na 10.): przeżywalność
prawie w sam raz, ale wszystko pada od jednego ciosu, boss po kilku - to ma być możliwe tylko przy dobrym buildzie.
Decyzje (ankieta): jedno i drugie plus odporności na żywioły; cel na 101. - goblin 2-3 ciosy, boss ~70 (zwykłe cięcie,
losowe rzadkie przedmioty, bez kamieni).
- Zdrowie potworów i bossów rośnie szybciej niż obrażenia: `DungeonLevels.hp_mult` = `HP_GROWTH` 1,008 na poziom
  (10. x1,07, 50. x1,48, 101. x2,2) - `ProtoGoblin.hp_mult` (ustawia `ProtoHorde.spawn_at`, też wstawanie szkieletu),
  `ProtoChief.hp_mult` (arena).
- Awans +8% obrażeń (`HeroLevels.DAMAGE_STEP`; było +10%, wcześniej +6%) - 50. poziom x4,9 zamiast x5,9.
- Odporności lochów `Dungeons.RESISTS` (potwory i boss lochu, `ProtoTarget.resists`/`resist`): Zatopione podziemia - woda
  50%, ogień 30%, wrażliwe na Grom 25%; Katakumby - Nawia 50%, lód 30%, wrażliwe na ogień 25%; Górskie równiny - Grom 50%,
  woda 20%, wrażliwe na lód 25%; Wulkaniczne - ogień 60%, Grom 20%, wrażliwe na wodę 30% i lód 25%. Gobliny bez.
  Działa w `ProtoWeapon._deal` (żywioł broni, `Elements.reduce` z combo), piorun i szron z kamieni, podpalenie
  (`ProtoTarget.burn`). Fizyczne (miecz) bez odporności. Wybór poziomu pokazuje „Odporne: … · Wrażliwe: …”
  (`Dungeons.resist_text`).
- Wynik (średnio z 30 losowań, zwykłe cięcie): 101. loch - goblin ~3 ciosy (było ~0,9), boss ~78 (było ~25);
  50. - goblin ~0,9 (było 0,45), boss ~25 (12); 10. - prawie bez zmian.
- Test `_test_resists` w `tests/test_elements.gd`.

## 17.11.2026 - krótsza nietykalność po trafieniu

Uwaga autora po drugim teście: dalej za łatwo - można długo stać w miejscu i się leczyć (12. poziom, loch 5); w PoE,
Dwarven Realms i Vampire Survivors takie stanie kończy się śmiercią dużo szybciej. Przyczyna: po każdym trafieniu postać
była nietykalna 0,35 s, więc dostawała najwyżej ~3 ciosy na sekundę bez względu na tłum.
- `ProtoHero.HIT_INVULNERABLE` 0,1 s po zwykłym trafieniu (Riposta zostaje przy `INVULNERABLE` 0,35 s).
- Symulacja (postać 12. poziomu stoi z auto atakiem w lochu 5; pierwsze ~10 s potwory dopiero dochodzą): od otoczenia
  do śmierci bez przedmiotów ~7 s -> ~4-5 s, z przeciętnymi przedmiotami (+80 zdrowia, regeneracja 3/s, ochrona 15%,
  unik 8%, leczenie za zabicie) ~12-20 s -> ~6-7 s.

## 17.11.2026 - poprawki po pierwszej uczciwej wyprawie

Zgłoszenia autora (nowa postać, 4. loch, 12. poziom postaci) i decyzje z ankiety:
- Okno wyniku (`RunResult`): podsumowanie w przewijanym polu z zawijaniem linii (czcionka 14), przyciski zawsze na dole.
- Poziomy postaci (`HeroLevels`): wolniej i mocniej - `XP_BASE` 50 -> 150 (3x więcej na poziom), awans +10% obrażeń
  (było 6%), +20 zdrowia (10), +8 many (5).
- Trudność: siła potworów +20% na poziom (`DungeonLevels.POWER_STEP` 0,15 -> 0,20; nagrody dalej +15% - `REWARD_STEP`;
  10. ~3,4x, 50. ~29x, 100. ~148x), potwory (bez bossów) zadają x1,5 (`MONSTER_DAMAGE`, w `ProtoHorde.spawn_at`),
  gęściej od startu (`ALIVE_START` 25 -> 35, `ALIVE_END` 70 -> 85, grupki 4-6 / 5-8).
- Zdrowie za zabicie: działa w 1/4 wartości z przedmiotu (`Items.LIFE_ON_KILL_MULT` - tak samo dla starych przedmiotów
  i kamieni szlachetnych), ułamki zbierają się w `ProtoHorde._heal_acc`; opisy „+0,5 zdrowia za zabicie”.
- Młynek: wiruje, dopóki palec trzyma przycisk (duży - „Atak”/auto atak przy wrogach, mały - `ProtoWeapon.whirl_held`
  z `arena._on_skill_pressed`), bez odnowienia, 10 many na start i co sekundę (`WHIRL_DRAIN`); 5. poziom - 30% mniej many
  (było: 4 s zamiast 3), 10. poziom - wybuch co `WHIRL_BLAST_EVERY` 2,5 s. Kamień Wiecznego Wiru - „rośnie z czasem”:
  przez 4 s zasięg i obrażenia do +100% (`_whirl_grow`). Pośpiech na Młynku nic już nie daje (brak odnowienia).
- Kamienie ok. 3x rzadziej: goblin 0,4% (było 1,2%), rzadkie 0,05%, skrzynia bossa 30% + 10% (było 80% + 30%),
  skrzynia-cel 20% (było 50%).
- Kamienie żywiołów: Piorun - niebieskie liczby, poraża przeskokiem (`DISCHARGE_SHOCK` 3 s, jak katana); Szron -
  oprócz spowolnienia rani lodem (`RIME_DAMAGE` 0,5 siły, combo z przemoczeniem), błękitne liczby (`ProtoTarget.color_next`).
  Żar - podpalenie jak dotąd (pomarańczowe liczby).
- Piorun niebieski w całej grze: `Elements.COLORS` Grom niebieski (lód jaśniejszy), zygzak `_bolt` z szeroką
  addytywną poświatą i jasnym rdzeniem, gaśnie w 0,3 s.
- Bossowie też za łatwi (druga uwaga autora): `DungeonLevels.BOSS_POWER` 1,5 - zdrowie i obrażenia bossów x1,5
  (`arena.summon_chief`: `power` x BOSS_POWER).
- Testy poprawione pod nowe liczby; zrzuty `tools/result_shots.gd`.

## 16.11.2026 - wiele postaci

Pomysł autora (też do testów: jedna postać normalnie, druga w trybie deweloperskim). Decyzje (ankieta): bez limitu
postaci, tryb deweloperski osobno dla każdej, wspólne ustawienia sterowania i skrzynia w bazie, do wyboru postać SSF
(tylko własny łup, własna skrzynia), wybór na kartach z podglądem.
- `Game`: postać = plik `user://characters/<id>.json` (`chars_dir`) z `name`, `ssf`, `created` i `dev` (nieśmiertelność,
  wszystkie poziomy, licznik klatek, suwaki statystyk - wcześniej w settings.cfg); `list_characters`,
  `create_character`, `select_character` (zapis poprzedniej, wczytanie, `last_character` w ustawieniach - wybierana
  przy starcie), `delete_character`. Bez wybranej postaci (`save_path` "") nic się nie zapisuje. `save_settings`
  zapisuje też postać (tryb deweloperski).
- Wspólna skrzynia `user://shared_stash.json` (postacie bez SSF, `_uses_shared_stash`); „postać od nowa” jej nie czyści.
  Zapisy testowe (`save_path` z „test”) trzymają skrzynię w sobie, jak dawniej.
- Stary pojedynczy zapis `user://savegame.json` przechodzi raz na postać „Wojciech” (`_migrate_legacy`, plik `c0`,
  z trybem deweloperskim ze starych ustawień; stary plik zostaje jako `savegame.json.old`).
- Ekran `scripts/ui/character_select.gd` (`CharacterSelect`) po „Graj” w menu: karty (ikona broni, nazwa, poziom,
  najgłębszy loch, „SSF”, „Tryb deweloperski”; obecna postać w złotej ramce), „Graj” i „Usuń” z potwierdzeniem,
  „Nowa postać” - formularz (imię u góry ekranu - klawiatura telefonu zasłania dół, skrzynia Wspólna / SSF);
  bez postaci formularz otwiera się od razu. „Wstecz” Androida zamyka formularz / wybór.
- Testy `tests/test_characters.gd`; w `test_dev` i `test_horde` tryb deweloperski sprawdzany w zapisie postaci.
  Zrzuty `tools/character_shots.gd`.

## 16.11.2026 - modyfikatory lochów

Pomysł z Dwarven Realms. Decyzje autora (ankieta): gracz sam włącza modyfikatory przy wyborze poziomu, każdy utrudnia
i daje lepsze nagrody, od 20. poziomu lochu (szczebel drabinki odblokowań).
- `scripts/dungeon_mods.gd` (`DungeonMods`, `FROM_LEVEL` 20): Żarliwa Horda (potwory +25% prędkości, żar z iskier x2),
  Gromada (tłum x1,5, szansa łupu +30%), Krwawy księżyc (potwory +50% obrażeń, przedmioty z potworów z wagami rzadkości
  skrzyni bossa - `Items.roll_goblin(…, weights)`), Dwór elit (elity 2x częściej, doświadczenie za elity x2).
  Bossa nie zmieniają.
- Wybór w `Game.dungeon_mods` (zapis), działa tylko na poziomach >= 20 (`DungeonMods.active`). Okno
  `scripts/ui/mods_window.gd` (`ModsWindow`, przełączniki „Włącz” / „Włączony”) z przycisku „Modyfikatory” w wyborze
  poziomu (widoczny od 20.); wybór poziomu pisze „Modyfikatory: …”.
- W lochu: `ProtoHorde.mod_speed`, `mod_damage` (po `ProtoElite.promote`), `mod_embers` (`_on_ember`), `elite_rate`,
  `rare_loot`; gęstość i łup w `arena._apply_upgrades`; nazwy pod paskami (`arena.mods_label`).
- Testy w `tests/test_unlocks.gd` (`_test_mods`), zrzuty `tools/unlock_shots.gd` (`_4_wybor20`, `_5_modyfikatory`, `_6_loch`).

## 16.11.2026 - drabinka odblokowań

Pomysł z Dwarven Realms. Decyzje autora (ankieta): drabinka tylko POKAZUJE progi, które już są w grze (nic nowego się
nie blokuje), bez nagród za kamienie milowe; widać ją przy wyborze poziomu, w oknie zwycięstwa, w osobnym oknie
i jako znaczek „Nowość!” nad Watrą.
- `scripts/unlocks.gd` (`Unlocks`): wpisy z progów systemów (elity i ich cechy - `Elites`, łucznicy i osiłki -
  `DungeonLevels`, kamienie i kamienie unikalne - `Gems`, cele na mapie - `DungeonGoals.KINDS`, lochy - `Dungeons`,
  bronie za darmo - `Weapons.unlock_level`), więc zmiana progu w systemie zmienia drabinkę. Wpis: `beat` (który poziom
  przebić), `level`, `kind`, `text`, `icon`. `on_beat`, `new_at`, `next_after`, `has_new`.
- Wybór poziomu (`LevelPicker`): „Nowość: …” na poziomie, od którego coś dochodzi; na najwyższym poziomie
  „Następne odblokowanie po bossie poziomu N:” z listą. Przyciski „Drabinka” i „Ulepszenia” obok siebie (było jedno
  „Ulepszenia lochów” na całą szerokość).
- Okno `scripts/ui/unlocks_window.gd` (`UnlocksWindow`, na `BaseWindow`): wszystkie progi z ikoną, odblokowane
  (zielony napis), następny (złota ramka, przewija się do niego), dalsze przygaszone; „Wróć” wraca do wyboru poziomu.
- Okno zwycięstwa: „Odblokowano: …” (`RunResult.add_unlock_lines`).
- Znaczek „Nowość!” nad Watrą (`ProtoWatra.set_news`), gdy `Game.unlocks_seen` (w zapisie) < `best_level` i coś się
  odblokowało; otwarcie wyboru poziomu go gasi.
- Test `tests/test_unlocks.gd`, zrzuty `tools/unlock_shots.gd`.

## 16.11.2026 - cele na mapie lochu: Krąg Żertwy i Kryształ Watry

Ostatnie dwa cele z ankiety autora (pula: Żertwa od 15., Kryształ od 20. poziomu lochu).
- Krąg Żertwy `scripts/proto/proto_zertwa.gd` (`ProtoZertwa`, pień `assets/watra/zertwa_stump.png` z Watry): 1 s stania
  przy pniu zapala krwawy krąg (`ZER_RADIUS` 110 px, spłaszczony; węzeł pod potworami z_index -1, łuk postępu daniny),
  co `ZER_PACK_EVERY` 2,5 s paczka 4-6 potworów zza brzegu (`ProtoHorde.spawn_pack`, nie ponad `ALIVE_CAP`). Danina
  (`offer_kill`, sygnał `ProtoHorde.monster_died`): tylko pokonani w kręgu, elita x3; `ZER_GOAL` 80 w `ZER_TIME` 75 s,
  inaczej krąg gaśnie. Napis nad pniem „Danina N / 80 · s”. Komplet: gra staje i okno `scripts/ui/zertwa_offer.gd`
  (`ZertwaOffer`, 3 duże przyciski w dolnej połowie) - rzadki przedmiot, kamień albo żar skrzyni Wodza
  (`DungeonGoals.zertwa_offer`); przedmiot/kamień wyskakuje z pnia i leci do postaci (`arena._drop_reward`).
- Kryształ Watry `scripts/proto/proto_crystal.gd` (`ProtoCrystal`, grafiki kryształu i gruzu z Watry): przygaszony do
  podejścia postaci (`WAKE` 90 px), potem `CRYSTAL_TIME` 25 s obrony; co 5 s fala z 2 stron po 4-6 potworów
  (230 px od kryształu). Potwory z `ProtoGoblin.objective` idą bić kryształ (`_objective_move`, cios co
  `attack_cooldown` bez animacji - różne ataki podklas), chyba że postać jest bliżej niż `OBJECTIVE_AGGRO` 70 px.
  Zdrowie `CRYSTAL_HP` 600 x siła poziomu, pasek nad kryształem. Obroniony: 1-4 kamienie (wg zdrowia) i 6-12 odprysków
  (`Game.add_shards`), rozbity: gruz i 3 odpryski.
- Testy w `tests/test_goals.gd`, zrzuty `tools/goal_shots2.gd` (oba skrypty zrzutów usuwają testowy zapis na końcu -
  inaczej `test_horde` wczytywał poziom 22 z Katakumbami).

## 16.11.2026 - cele na mapie lochu: Skarbnik

Trzeci cel (decyzja autora: uciekający duch zamiast oferty z falami jak w Watrze), w puli od 10. poziomu lochu.
- `scripts/proto/proto_skarbnik.gd` (`ProtoSkarbnik`, cel miecza - `ProtoTarget`): złocista zjawa górnika
  (`assets/watra/skarbnik.png` = `miner_down.png` z Watry, shader `shaders/ghost.gdshader` z Watry - tu mocniej kryjący,
  żeby było go widać na trawie), złota poświata pod nim. Czeka pod słupem światła; budzi się, gdy postać podejdzie
  bliżej niż `WAKE` 110 px (albo po trafieniu), i ucieka `FLEE_TIME` 15 s z prędkością `SPEED` 58 (postać 70) z zakosami
  (`ZIGZAG`), ślizga się wzdłuż brzegu polany; ostatnie 3 s miga, potem zapada się pod ziemię.
- Trafienie (najwyżej co `HIT_GAP` 0,2 s - Młynek nie wybija złota seriami): złoto `gold_per_hit` = `Items.SELL_BASE`
  x `DungeonLevels.power` x `GOLD_HIT` 0,8 (12. poziom: 9 zł), złota liczba „+N”, brzęk monet, zachwianie (połowa
  prędkości na 0,5 s). Po `CATCH_HITS` 8 trafieniach złapany: `JACKPOT` 10 x złoto za trafienie i kamień na ziemi.
  Symulacja (auto atak, bez umiejętności): złapany w 4 na 4 próby, ale trzeba gonić.
- Złoto od razu do `Game.gold` (`Game.add_gold`, zapis przy `save_if_dirty`), w oknie wyniku linia „Złoto Skarbnika”
  (`RunResult.add_gold_line`, `arena.run_skarbnik_gold`).
- Testy w `tests/test_goals.gd`, zrzuty w `tools/goal_shots.gd` (`_4_skarbnik`, `_5_poscig`).

## 16.11.2026 - cele na mapie lochu: skrzynia i kapliczka

Pomysł z Dwarven Realms (decyzje autora z ankiety 16.11.2026): przy progach paska żaru na polanie pojawia się cel,
żeby między falami było dokąd biec. Na start skrzynia i kapliczka; Skarbnik, Krąg Żertwy i Kryształ Watry - dalej.
- `scripts/dungeon_goals.gd` (`DungeonGoals`): progi `THRESHOLDS` 25/50/75% `DungeonLevels.summon_cost`
  (`thresholds_passed`), pula wg poziomu `KINDS` (skrzynia od 1., kapliczka od 5. - pula rośnie co 5 poziomów),
  losowanie bez powtórek w jednym zejściu (`roll`; przy małej puli powtórki), miejsce `spot` (200-420 px od postaci,
  48 px od brzegu, 120 px od innych celów, poza ozdobami), łup skrzyni, dary kapliczek `GIFTS`.
- Skrzynia-cel: `ProtoChest.hold_time` (`CHEST_HOLD` 1,5 s stania w promieniu 30 px; odejście cofa postęp 2x szybciej,
  stuknięcie nie otwiera), kółko postępu na ziemi; łup: 1 przedmiot z wagami skrzyni Wodza, 50% na kamień (od 3.
  poziomu), żar = 25% żaru skrzyni Wodza (bez mnożnika głębi, idzie do paska).
- Kapliczka `scripts/proto/proto_shrine.gd` (`ProtoShrine`, grafika `assets/watra/shrine.png` i dźwięk
  `shrine_pray.ogg` z Watry): 1 s stania (`PRAY_TIME`), dar na 60 s (`GIFT_TIME`, nowy zastępuje stary) - nazwy z Watry:
  Moc Peruna (+50% obrażeń, +10% kryt.), Opieka Mokoszy (+20% uniku i ochrony, leczenie 3% zdrowia/s), Tchnienie
  Strzyboga (+30% ruchu i ataku), Hojność Dadźboga (łup x2). Dar doliczany do cech z przedmiotów (`arena._gear`,
  `_refresh_gift`), łup przez `_apply_upgrades`; napis daru z czasem pod paskami (`gift_label`).
- Pokazanie: słup światła `scripts/proto/goal_beam.gd` (`GoalBeam`, wielokąt addytywny, też `draw_ring`), strzałki przy
  krawędzi ekranu `scripts/ui/goal_arrows.gd` (`GoalArrows`, grupa `dungeon_goal`, omijają górny pasek), napis na
  środku ekranu (`arena.announce`) i dźwięk.
- Niezrobiony cel zostaje po przyzwaniu Wodza; nowe cele tylko w fazie Hordy.
- Test `tests/test_goals.gd`, zrzuty `tools/goal_shots.gd`.

## 16.11.2026 - mniej żaru w głębi

Uwaga autora: na 101. poziomie (Wulkaniczne równiny) w 2 minuty ~30 000 żaru. Przyczyny: iskra warta `reward`
(+15% na poziom, x16 na 101.) i osiłki (tu żużlowe golemy, 15% tłumu) zawsze z iskrą za 3. Decyzja autora:
- `DungeonLevels.ember_value(level)` = 1 + `EMBER_STEP` 0,02 na poziom (101. x3) - wartość iskry i koszt przyzwania
  (`summon_cost` = 100 x `ember_value` x `crowd`: 10. ~129, 50. ~295, 101. ~465); `reward` zostaje dla doświadczenia.
- Osiłki (goblin osiłek, topielica, rycerz-szkielet, szaman burzy, żużlowy golem) jak zwykłe: iskra z `EMBER_CHANCE`
  (20%), nadal warta `BRUTE_EMBERS` 3; duża iskra co `BIG_EVERY` i elity - zawsze.

## 16.11.2026 - gęstsza Horda grupkami, sufit 150 potworów

Uwaga autora: potworów zdecydowanie za mało. Decyzje autora: gęściej od startu, grupkami z różnych stron, sufit jak
najwyżej (endgame). Wyprawa do Wodza trwała u autora około 2 minut.
- `ProtoHorde.spawn_group`: grupka z jednego punktu tuż za kadrem (`spawn_point`), rozsypana wzdłuż krawędzi
  i na zewnątrz (`GROUP_SPREAD` 22 px - nigdy w kadr), wielkość 3-5 na starcie i 4-7 po rozkręceniu (`GROUP_START`,
  `GROUP_END`), nie ponad limit naraz; rodzaj każdego potwora z `_roll_kind` (limity łuczników i osiłków bez zmian).
- Liczby: grupka co 1,6 s -> 0,6 s (`INTERVAL_START/END`), naraz 25 -> 70 (było 8 -> 45), pełne tempo po 90 s
  (było 180 s), twardy limit `ALIVE_CAP` 150 (było 70; osiągalny z ulepszeniem „Gęstsza Horda” i tłumem głębokich lochów).
- Wydajność: odpychanie goblinów (`ProtoGoblin._separation`) sprawdzało cały tłum w każdej klatce (czas rósł z kwadratem
  liczby potworów); teraz siatka kratek `PERSONAL_SPACE` budowana raz na klatkę (`_crowd_grid`) i tylko 9 sąsiednich
  kratek. Pomiar `tools/crowd_bench.gd` (logika w chmurze): 70 potworów 2,9 -> 1,9 ms, 150: 8,2 -> 4,2 ms,
  200: 15,9 -> 6,9 ms.
- Tryb deweloperski: przełącznik „Licznik klatek i potworów” (`Game.dev_fps`, `arena.fps_label`) - do sprawdzenia
  tłumu na telefonie.
- Symulacja `tools/crowd_sim.gd` (stojąca postać z auto atakiem, poziom 1): przed - naraz 9-18, żar na bossa po 101 s;
  po - naraz 27 -> 70, żar na bossa po 46 s, 413 pokonanych w 2 minuty (było 110).
- Testy: grupka w `test_horde.gd`, gęstość z ulepszeniem w `test_base.gd`; test nieśmiertelności bez tłumu.
- Żar z głębią (decyzja autora: mniej żaru z potwora, ale im głębiej, tym więcej żaru z potwora i droższe przyzwanie):
  mała iskra wypada z `ProtoHorde.EMBER_CHANCE` (20%; duża iskra co 40. potwór, było co 20. - symulacja: przy 35% i co 20. żar na Wodza po 70 s, przy 20% po 80 s, teraz po 92 s - jak przed zagęszczeniem, 101 s) zwykłych potworów (duża co `BIG_EVERY`, osiłki i elity zawsze),
  iskra warta `DungeonLevels.reward(level)` (+15% na poziom, `_on_ember`); koszt przyzwania
  `DungeonLevels.summon_cost(level)` = `SUMMON_BASE` 100 x `reward` x `crowd` (1. poziom 100, 10. ~255, 50. ~1240,
  100. ~2460; było stałe `SUMMON_COST` 100) - wyprawa trwa podobnie, nadwyżka do bazy rośnie z głębią.

## 16.11.2026 - efekty ataków Wodnika i Nekromanty

Ciąg dalszy efektów bossów z kreatora PixelLab (darmowy; wpisy w `pixellab_src/vfx/ids.json`, arkusze w `assets/effects/`).
Decyzje autora: sople spadają z góry, Nawia zostaje fioletowa, wiązka wyssania zostaje kreską z efektem wzdłuż niej,
aury przy zapowiedzi ataku - tak.
- Wodnik (`proto_wodnik.gd`): `wodnik_wave` - fala z ciemną masą wody za grzywą piany (pętla w locie, skala `TIDE_SCALE`
  0,75, na końcu pasa rozprysk `hydro_splash`); `wodnik_vortex` - wir z szybszymi spiralami i krążącymi kroplami;
  `wodnik_icicle` - sopel spada z nieba w każde koło lodowych kropli (startuje `ICICLE_LEAD` = 7/18 s przed
  wypełnieniem koła, rozbija się w lodowe odłamki w 8. klatce; zastąpił niebieski rozprysk wody); `wodnik_geyser` -
  zmarszczki, słup wody i rozbryzg przy wezwaniu topielców (skala 0,8); `wodnik_aura` - krople krążące wokół Wodnika
  w stanach `WARN_STATES` (`_update_aura`, `aura_active`).
- Nekromanta (`proto_necromancer.gd`): kule `ProtoArrow.nawia` (`nawia_orb` - kula z dymiącym ogonem, trafienie
  `nawia_hit`) zamiast przebarwionych baniek; `bone_spikes` - kościane kolce w kołach kręgu (skala = promień koła /
  `SPIKES_RADIUS` 24) zamiast pożyczonego uderzenia; `nawia_drain` - drobinki płynące od postaci do Nekromanty,
  kafelki 48x16 wzdłuż kreski (ostatni przycięty `region_rect`, `_update_beam_fx`, `_clear_beam`), cieńsza kreska;
  `nawia_heal` - zielony błysk leczenia przy każdym ciosie wiązki; `nawia_summon` - krąg run z czarnym płomieniem
  Nawii przy przywołaniu; `nawia_aura` - dym Nawii za Nekromantą w `WARN_STATES` (z_index -1).
- Testy: `test_flooded.gd` (krople wokół Wodnika przy zapowiedzi i po ataku), `test_catacombs.gd` (kule `nawia`,
  drobinki i dym przy wiązce). Zrzuty `tools/flooded_shots.gd` (fala w locie) i `tools/catacombs_shots.gd` (kolce).

## 16.11.2026 - efekty ataków Gromoskrzydłego i Żywiołaka ognia

Uwaga autora: w walce z bossami za mało widać ich żywioł, a Gromoskrzydły „strzelał strzałami”. Decyzja autora:
pióra z podmuchu zastępują kule piorunów. Efekty z kreatora PixelLab (darmowy; wpisy w `pixellab_src/vfx/ids.json`,
arkusze w `assets/effects/`), w grze nowy pomocnik pętli `Fx.loop` (`scripts/fx.gd`).
- Gromoskrzydły (`proto_storm_eagle.gd`): `eagle_bolt` - piorun z nieba w każde koło burzy (startuje `BOLT_LEAD`
  = 0,2 s przed wypełnieniem koła, uderza w 5. klatce razem z obrażeniami); `eagle_aura` - aura iskier wokół orła
  od ostrzeżenia do końca nurkowania (`_aura`, `_remove_aura`); `eagle_gust` - pierścień wyładowania podmuchu
  (pod postaciami, z_index -1, skala `GUST_RADIUS / GUST_FX_RADIUS`); kule piorunów `ProtoArrow.orb` (`eagle_orb`
  w locie, trafienie `katana_hit` w skali 0,5) zamiast strzał.
- Żywiołak ognia (`proto_fire_elemental.gd`): `fire_wave` - pierścień fali z płomieniami (zamiast pojedynczych
  płomyków `burning`, pod postaciami); `lava_meteor` - kula lawy spada z nieba (startuje `METEOR_LEAD` = 7/18 s przed
  wypełnieniem koła, krater w 8. klatce); `charge_flame` - płomienna smuga w szarży (`_flame`, obrócona w kierunku
  taranu, za postacią).
- `tools/volcano_shots.gd`: zrzuty fali i lawy chwilę później (widać efekty).

## 15.11.2026 - piąty loch: Wulkaniczne równiny, Żywiołak ognia

Decyzje autora: najpierw po jednej krainie na każdy żywioł broni - brakowało ognia; Wulkaniczne równiny od 41, nowe
ogniste stwory (salamandra, ognik, żużlowy golem), boss Żywiołak ognia (Żmij Gorynycz zostaje na bossa szczytowego -
ROADMAP), ataki: Fala ognia, Deszcz lawy, Ognisty taran; ogień podpala; podłoże z generatora za darmo.
- `Dungeons.VOLCANO` (od 41, żywioł ognia, „Przyzwij Żywiołaka”). Drabinka: 1-10 gobliny, 11-20 podziemia, 21-30
  Katakumby, 31-40 Górskie równiny, 41-100 Wulkaniczne równiny, od 101 losowo.
- Podpalenie: `ProtoHero.ignite(obrażenia, czas)` - płomień co 0,5 s (`_burn_hit`: mniej o odporność, bez nietykalności,
  błysku i wibracji); `_check_death` wydzielone z `take_damage`.
- Płonąca ziemia `proto_fire_patch.gd` (`ProtoFirePatch.spawn`): koło płomyków `glaive_ground_fire`, co 0,5 s podpala
  stojącą w nim postać, gaśnie po czasie.
- Salamandra `proto_salamander.gd` (po goblinie): 32 zdrowia, 40 px/s, 8 ogniem + podpalenie. Ognik `proto_fire_wisp.gd`
  (po łuczniku): 24 zdrowia, żar 9 - ognista bańka (`ProtoArrow.ignite`), plucie zgrane z linią celu. Żużlowy golem
  `proto_slag_golem.gd` (po osiłku): 180 zdrowia, 24 px/s, uderzenie 24 ogniem, w kole płonąca ziemia na 3 s.
- Żywiołak ognia `proto_fire_elemental.gd` (po `ProtoChief`): 1100 zdrowia; Fala ognia (pierścień 26-100 -
  `ProtoTelegraph.inner`, 1,2 s, 26 + podpalenie; bezpiecznie przy nim i daleko), Deszcz lawy (7 kół wokół postaci,
  po kolei od 1 s, 18 + płonąca ziemia), Ognisty taran (pas 220x30, 0,9 s, szarża 0,4 s, 28 + ślad płonącej ziemi).
  Płomienie wybuchów - `burning.png`.
- Podłoże `assets/watra/volcano_floor.png` - generator `tools/volcano_floor.py`: płyty bazaltu (Woronoj, pofalowane
  krawędzie), płyty popiołu, szczeliny lawy z poświatą w skupiskach (szum), bez szwów.
- Wystrój (`ProtoDecor.DATA[VOLCANO]`): głazy, zwęglone pnie i drzewa, kamienie, gruz, kości, ogniska (poświata).
- Grafika SpriteKiln: `salamander` (czworonożna, własny szkielet), `fire_wisp` (bez szkieletu człowieka),
  `slag_golem`, `fire_elemental`.
- Test `tests/test_volcano.gd`, zrzuty `tools/volcano_shots.gd`.

## 15.11.2026 - czwarty loch: Górskie równiny, Gromoskrzydły

Decyzje autora: Górskie równiny od 31 (pomysł autora: ptakoludzie i elektryczny orzeł), ptakoludzie jak w Wietrznych
Turniach Watry (wojownik z doskokiem, miotacz oszczepów, szaman burzy), orzeł: Burza, Nurkowanie, Podmuch; piorun
poraża (więcej obrażeń przez chwilę). Podłoże z gotowych przejść Wang PixelLaba (uwaga autora: obrócona trawa
wyglądała źle, ucięte przejścia).
- `Dungeons.PLAINS` (od 31, żywioł Grom, „Przyzwij Gromoskrzydłego”). Drabinka: 1-10 gobliny, 11-20 podziemia,
  21-30 Katakumby, 31-100 równiny, od 101 losowo.
- Porażenie: `ProtoHero.shock(czas)` - przez ten czas obrażenia x`SHOCK_MULT` (1,25), postać miga na żółto.
- Ptakoczłek wojownik `proto_birdman.gd` (po goblinie): 44 zdrowia, 40 px/s, pchnięcie 11; z 45-110 px doskok -
  czerwony pas (0,55 s) do miejsca postaci, skok 0,3 s, 14 przy lądowaniu w pasie, odnowienie 4 s; trafienie
  przerywa zapowiedź. Miotacz `proto_birdman_thrower.gd` (po łuczniku): 32 zdrowia, oszczep 12 (`arrow_scale`,
  `arrow_tint` łucznika). Szaman burzy `proto_birdman_shaman.gd` (po osiłku): 120 zdrowia, z 100 px koło 22 pod
  postacią, piorun 22 Gromem + porażenie 2 s (efekt `katana_hit`).
- Gromoskrzydły `proto_storm_eagle.gd` (po `ProtoChief`; grafika z Watry `assets/watra/bosses/storm_eagle.png` -
  12 klatek machania, odbijana, unosi się 34 px i kołysze; `ProtoChief._make_sprite`, `move_speed`, `grounded` -
  orzeł lata, ozdoby go nie zatrzymują): 1000 zdrowia; Burza (5 kół pod postacią co 0,4 s, piorun po 0,85 s, 18
  + porażenie), Nurkowanie (pas 240x30, 1 s, przelot 0,35 s, 28 + porażenie), Podmuch (koło 52, 1 s, 16, odrzut
  70 px `ProtoHero.leap`, 10 piór Gromu dookoła).
- Podłoże `assets/watra/plains_floor.png` - generator `tools/plains_floor.py`: autotiling Wang z dwóch zestawów
  PixelLab Wietrznych Turni (łąka -> piarg, łąka -> kwiaty; `tools/data/plains/wang_*`), rogi siatki z szumu, róg
  kwiatów przy piargu zamieniany na łąkę (bez uciętych przejść), bez obracania kafelków.
- Wystrój gór (`ProtoDecor.DATA[PLAINS]`): kopczyki, suche drzewa, totem orła, gniazda, ruda, żerdzie, słup z
  gniazdem, chata na palach, piorunochron (poświata), dzwonki wietrzne.
- Grafika SpriteKiln ptakoludzi (wzory w `docs/referencje/turnie/`): `birdman` (z animacją `leap`),
  `birdman_thrower`, `birdman_shaman`.
- Test `tests/test_plains.gd`, zrzuty `tools/plains_shots.gd`.

## 15.11.2026 - wystrój lochów

Decyzje autora: same ozdoby (bez kolizji), losowy układ przy każdym wejściu, proste poświaty zamiast świateł Godota.
- `scripts/proto/proto_decor.gd` (`ProtoDecor`, tworzy arena w lochu): `DATA` - ozdoby każdego lochu (plik, waga, `frames`
  - warianty albo klatki, `fps` - animacja, `flat` - leży pod postaciami, `light` i `glow` - poświata); `scatter`
  rozrzuca COUNT=85 ozdób co najmniej 30 px od siebie, z wolnym kołem 70 px wokół startu postaci. Wysokie ozdoby stoją
  w świecie sortowanym po Y (postać chowa się za kolumną), płaskie mają z_index -5. Poświata: wspólna miękka plama
  (GradientTexture2D, mieszanie ADD, spłaszczona), lekko migocząca; animacje i migotanie w jednym `_process`.
- Grafiki z Watry w `assets/watra/decor/<loch>/`: gobliny - sztandar, kości, głazy, ognisko (4 klatki), padlina, pnie,
  kłody, garnki, tarcze, pale z czaszką, totem, ciernie, stojak z bronią; podziemia - misy z zielonym ogniem (2 klatki),
  pałki wodne i trzciny (warianty), garnki, zatopione drzewo, sieć, lilie, omszałe kamienie, pień, dzbany dusz
  (poświata), łódź, krzyż; Katakumby - kości, kandelabr, świece, trumna, zwłoki, kamienie, otwarty grób, kolumna,
  żebra, sarkofag, czaszki, posąg, pochodnie (2 klatki).
- Test w `tests/test_flooded.gd` (ozdoby, wolny start, poświaty), zrzuty `tools/decor_shots.gd`.
- Poprawki po uwagach autora: ozdoby mają kolizje (wysokie - koło u podstawy, `ProtoDecor.obstacles`, `push_out`;
  postać, potwory (+3 px) i bossowie (+8 px) obchodzą je bokiem; płaskie dalej bez kolizji), mniej ozdób (45, co
  najmniej 40 px od siebie), w Leżu goblinów jaśniejsze grafiki (namioty, posłanie, stojak ze skórami, kłody do
  siedzenia, łupy, beczka, palisada zamiast prawie czarnych głazów, pni i cierni) i lekkie rozjaśnienie (`TINT`).

## 15.11.2026 - poprawka: okno wyboru kamienia nie mieści się na ekranie

- Zgłoszenie autora: okno kamieni dla miecza za szerokie. Przyczyna: tytuł i podtytuł `GemPicker` („Kamienie
  umiejętności z sakwy - co zrobią w: Rozłupanie Ziemi”) nie zawijały się, więc długa nazwa umiejętności rozpychała
  okno (351 px przy 344 px miejsca). Teraz oba się zawijają. Przy cudzych kamieniach unikalnych napis „Pasuje tylko
  do: …” był dwa razy. Decyzja autora: kamienie unikalne innych umiejętności są w ogóle ukryte - w liście gniazda
  i w „Gdzie włożyć” kamienia unikalnego z sakwy (tylko jego umiejętność).
- Drugie zgłoszenie (zrzut z telefonu): całe okno umiejętności za szerokie. Przyczyna: z kamieniem unikalnym Młynka albo
  Kręgu stali linia many („20 many, potem 7 na sekundę, bez odnowienia”) nie zawijała się - okno miało 433 px przy 360.
  Teraz się zawija; test `tests/test_gems.gd` (`_test_window_width`) sprawdza okno przy wszystkich broniach,
  umiejętnościach na 10. poziomie i kamieniach unikalnych (obie zakładki). Okno „Postać” sprawdzone ręcznie przy
  skrajnych premiach - najszerzej 334 px.

## 15.11.2026 - trzeci loch: Katakumby, Nekromanta

Decyzje autora: Katakumby od 21. poziomu (drabinka: 1-10 gobliny, 11-20 Zatopione podziemia, 21+ Katakumby, od 101
losowo), ten sam schemat ról (zwykły / strzelający / silny + boss z 4 atakami); szkielet rozpada się i wstaje,
rycerz-szkielet z zamachem w wachlarzu, Nekromanta: kule Nawii, kościany krąg, wyssanie życia, przywołanie szkieletów.
- `Dungeons.CATACOMBS` (od 21, żywioł Nawii, „Przyzwij Nekromantę”), `ProtoHorde.make_monster`, arena wybiera bossa.
- Szkielet `proto_skeleton.gd` (po goblinie): 34 zdrowia, 40 px/s, cios 10; pierwsza śmierć - kupka kości (`is_pile`,
  bez sygnału `died`, iskry i łupu), po 3 s wstaje (`rise`, 0,8 s, bez trafień) z połową zdrowia; kupkę niszczy każde
  trafienie (cięcie, obszar, podpalenie); drugi raz nie wstaje. Elita wybucha raz, przy ostatecznej śmierci.
- Szkielet łucznik `proto_skeleton_archer.gd` (po łuczniku): 28 zdrowia, strzała Nawii 10 (`ProtoArrow.element`,
  `tint`; pocisk ma też `bubble`, `speed`, `fly_range`).
- Rycerz-szkielet `proto_skeleton_knight.gd` (po osiłku): 170 zdrowia, 26 px/s, zamach 24 w wachlarzu 120 stopni
  o promieniu 44 przed sobą (`ProtoTelegraph.arc` / `angle`, `ground_angle`; efekt cięcia miecza), z tyłu bezpiecznie.
- Nekromanta `proto_necromancer.gd` (po `ProtoChief`): 900 zdrowia, trzyma się 85 px od postaci; Kule Nawii (5 kul
  wachlarzem po 0,7 s, wolne 80 px/s, 16), Kościany krąg (12 kolców w pierścieniu wokół postaci z luką 3 kolców po
  stronie z dala od niego - 0,8 s, potem środek - 1,6 s, 22), Wyssanie życia (gdy postać w spłaszczonym kole o promieniu 110 - `in_drain_range`:
  po 0,4 s wiązka przez 2 s co 0,4 s 6 Nawią i +12 zdrowia Nekromancie; wyjście z koła przerywa), Przywołanie (4
  szkielety co 12 s). `passive` - testy i zrzuty (sam nie atakuje; też w `ProtoWodnik`).
- Podłoga `assets/watra/catacombs_floor.png` - generator `tools/catacombs_floor.py`: płyty o losowej szerokości
  i wysokości rzędów (przesunięte jak posadzka), ziarno z kolorów kafelka podłogi katakumb Watry, przygaszone
  pęknięcia, gruz, rzadko czaszki i krew (`tools/data/catacombs_decals/`), szum - pole 768 px bez szwów.
  `tools/data/.gdignore` - Godot pomija materiały generatorów.
- Grafika SpriteKiln (wzory w `docs/referencje/katakumby/`): `skeleton` (z animacją `rise`), `skeleton_archer`,
  `skeleton_knight`, `necromancer`.
- Test `tests/test_catacombs.gd`, zrzuty `tools/catacombs_shots.gd`.

## 15.11.2026 - drugi loch: Zatopione podziemia, Wodnik, odporność na żywioły

Decyzje autora: klimat Zatopionych podziemi (z Watry), wspólna drabinka poziomów - 1-10 gobliny, od 11 na stałe
podziemia, kolejne lochy w podobnym rytmie, od 101 przy każdym wejściu losowy loch (endgame); 3 potwory + boss
(topielec, żabołak, topielica, Wodnik z falą, wirem, lodowymi kroplami i wezwaniem topielców); jedna premia
„odporność na żywioły” zamiast osobnych.
- `scripts/dungeons.gd` (`Dungeons`): rodzaje lochów (`DATA`: nazwa, `from`, boss, napis przyzwania, podłoże
  i odcień, żywioł, opis), `for_level` (od `RANDOM_FROM`=101 losowo), `is_random`. Podłoże podziemi -
  `assets/watra/swamp_floor.png` - generator `tools/swamp_floor.py` (uwaga autora: kafelek 64 px za bardzo się
  powtarzał): kępki rzęsy i lilii wycięte z płycizny Watry (`assets/swamp/ground/shallow.png`, kopia w
  `tools/data/swamp_shallow_src.png`) rozrzucone losowo z odbiciami na polu 768x768 bez szwów, gęstość z miękkiego
  szumu (skupiska i otwarta woda), zmarszczki, kolory przesunięte w stronę mętnej, szaroniebieskiej wody.
- Arena: `climate` z poziomu przy wejściu, podłoże i odcień z `Dungeons`, nazwa bossa nad paskiem, „Przyzwij Wodnika”,
  boss `ProtoWodnik`. Wybór poziomu pokazuje nazwę i opis lochu („Loch losowy” od 101); wynik - „Pokonane potwory”.
- `ProtoHorde.climate` i `make_monster(loch, rola)`: role strumienia (zwykły / strzelający / silny) mają te same
  udziały i limity co gobliny. Potwory dziedziczą po goblinach: `ProtoGoblin.element` (żywioł ciosu),
  `_hit_hero` (co jeszcze robi trafienie), `squeaks` (podziemia nie piszczą przy ucieczce), `fallback_color`.
  - Topielec `proto_drowner.gd`: 48 zdrowia, 30 px/s, cios 11 wodą, przemoczenie (25% wolniej na 2 s).
  - Żabołak `proto_frogman.gd` (po łuczniku): 30 zdrowia, plucie 9 - kula wody (`ProtoArrow.water`: bańka hydrosfery,
    rozprysk, przemoczenie); animacja plucia rusza z opóźnieniem (`SPIT_AT`), żeby zgrać się z linią celu.
  - Topielica `proto_rusalka.gd` (po osiłku): 130 zdrowia, koło lodu wokół siebie (promień 34), cios 20 lodem
    i 50% wolniej na 1,5 s; `ProtoGoblinBrute.anim_hit_at` - chwila ciosu w animacji podklasy.
- Wodnik `proto_wodnik.gd` (po Wodzu - `ProtoChief` dostał `scene_path`, `base_hp`, `anim_hit_at`, `anim_fallback`,
  `keep_distance`): 800 zdrowia, trzyma się 70 px od postaci; Fala (pas 230x30 - `ProtoTelegraph.length/width/angle`,
  1,1 s, 24 wodą + przemoczenie, efekt `hydro_wave` przelatuje pasem), Wir (koło pod postacią 0,9 s, potem 2,5 s
  wciąga 45 px/s w zasięgu 70 i rani 8 co 0,5 s, `hydro_vortex`), Lodowe krople (5 kół, jedno pod postacią,
  spadają po kolei od 1 s, 18 lodem i 45% wolniej), Wezwanie (4 topielce z gejzerów co 11 s).
- Odporność na żywioły: premia `element_res_pct` (przedmioty 5-10% + 0,3 na poziom, onyks zamiast uniku), sufit 75%
  (`Elements.MAX_RESISTANCE`), `ProtoHero.element_res`, `take_damage(ile, żywioł)` - liczba w kolorze żywiołu;
  `ProtoHero.slow` (spowolnienie i barwa postaci). Wiersz „Odporność na żywioły” w Statystykach (gdy przedmioty coś dają).
- Grafika SpriteKiln (styl projektu, wzory z Watry w `docs/referencje/zatopione/`): `art/specs/characters/drowner`,
  `frogman`, `rusalka`, `wodnik` -> `assets/spritekiln/<nazwa>/`.
- Test `tests/test_flooded.gd`, zrzuty `tools/flooded_shots.gd`.

## 15.11.2026 - kamienie bez stopni: ulepszanie, sprzedaż, odpryski, nowa sakwa

Decyzje autora: kamienie bez stopni; kamienie umiejętności ulepsza się złotem i odpryskami (10 poziomów), szlachetne
wypadają z 2-3 losowymi premiami jak jewele w PoE, a ulepszenie dokłada im kolejną (do 5); te same kamienie to osobne
sztuki (na stosie w sakwie); premie z puli rodzaju, takie same w każdym miejscu przedmiotu; stare kamienie
szlachetne ze stopniem po prostu znikają z zapisu („nieważne”).
- `Gems` (`scripts/gems.gd`): identyfikatory - kamień umiejętności `"rodzaj:poziom"` (1-`MAX_LEVEL`=10, wypada na 1.),
  szlachetny `"rodzaj:poziom lochu:cecha=wartość,…"` (`make_jewel`, `jewel_stats`, `jewel_level`); `level_of` (szlachetny -
  liczba premii). Siła kamienia umiejętności płynnie między `values` [1. poziom, 10. poziom] (`support_value`, np. Żar
  20% -> 115%, Mnożenie 40 -> 100, Szerokość 15 -> 55, Szron 15 -> 45, Piorun 20 -> 80, Pośpiech 10 -> 33,
  Oszczędność 15 -> 45, Krwiopijca 2 -> 8; mana z ciosu `thrift_mana` 1 -> 4). Pule szlachetnych (`JEWELS.pool`):
  rubin - obrażenia, zdrowie, odnowa, szansa i obrażenia krytyczne; szafir - mana, odnowa many, odnowienie,
  doświadczenie, żar; szmaragd - szybkość ataku i ruchu, unik, zasięg zbierania, obszar; onyks - ochrona, zdrowie,
  zdrowie za zabicie, odnowa, unik. Siła premii = premia przedmiotu z tego poziomu lochu x0,6 (`JEWEL_MULT`), 3 premie
  w 35% (`JEWEL_THREE`). Ikona szlachetnego rośnie z liczbą premii (`<rodzaj>_<n>.png`).
- Ulepszenie (`upgrade_cost`, `upgraded`): kamień umiejętności z poziomu L - 80 x 1,45^(L-1) zł (do 10) i 2,25 x L
  odprysków (razem ok. 4900 zł i 100 odprysków do 10.); szlachetny - 3. premia 300 zł + 5, 4. - 900 + 10,
  5. - 2000 + 20 (złoto +5% na poziom lochu kamienia). Sprzedaż (`sell_price`): umiejętności 15 zł + połowa włożonego
  złota, szlachetny 10 zł za premię, unikalny 200; rozbicie (`shard_value`): 2 + połowa włożonych odprysków, unikalny 15.
  Klucze i dłuta nie idą na sprzedaż (`can_sell`). Kamienie unikalne bez ulepszeń.
- `Game`: `shards` (odpryski, w zapisie), `upgrade_gem` (sztuka z sakwy, kamień w gnieździe umiejętności albo
  przedmiotu), `sell_gems` / `gems_value` (cały stos kilku kamieni naraz), `sell_gem` (jedna sztuka), `gem_list(filtr,
  sortowanie "kind"/"level", przedział poziomu)`, `GEM_LEVEL_RANGES` (1-3, 4-7, 8-10); `dev_gems` daje też 100 odprysków.
  Kupiec: kamienie umiejętności 1. poziomu i szlachetne z poziomu lochu (`Shop.stock`).
- Sakwa (`HeroStats`, zakładka „Sakwa”): kamienie i odpryski u góry, rodzaj (Wszystkie / Umiejętności / Szlachetne),
  „Sortuj: rodzaj/poziom”, „Poziom: wszystkie/1-3/4-7/8-10”; pole kamienia (`GemSlot`) - poziom w lewym górnym rogu,
  kropki = premie szlachetnego, ptaszek przy zaznaczeniu. Nad zakładkami pasek „Zaznacz kilka” -> „Zaznacz widoczne”,
  „Anuluj”, „Sprzedaj N: X zł”, „Rozbij N: Y odpr.” (drugie stuknięcie potwierdza).
- `GemPicker`: kamień z sakwy - opis, „Ulepsz” (co da i koszt; okno zostaje otwarte z ulepszonym kamieniem),
  „Sprzedaj” i „Rozbij” jednej sztuki (potwierdzenie); w gnieździe umiejętności i przedmiotu - „Ulepsz” w miejscu.
- Testy: `tests/test_gems.gd` (`_test_upgrade_sell` i sakwa w oknie „Postać”), `test_base.gd` (kupiec), `test_items.gd`;
  zrzuty `tools/gem_shots.gd` (`_2d_zaznaczanie`, `_2e_ulepsz`, `_2f_szlachetny`).

## 15.11.2026 - kamienie unikalne katany

- Pomysły z ankiety (Riposta i Sąd Peruna - własne pomysły autora), `Gems.UNIQUE`, działanie w `ProtoKatana`:
  - Kamień Gromowego Ostrza (`k_slash`): z każdego cięcia leci do przodu łuk pioruna (`_SparkArc`, 240 px/s, 130 px),
    przebija wrogów, 50% siły cięcia (`_spawn_spark`, `_process_sparks_fly`).
  - Kamień Wiru Ostrza (`k_dance`): Taniec w miejscu - 6 cięć, każde obrócone o 60 stopni dookoła postaci (`SPIN_*`).
  - Kamień Łańcucha Kontr (`k_riposte`): każdy wróg trafiony kontrą (cięcie dookoła i okrąg) po 0,12 s sam tnie
    dookoła siebie (promień 30, 50% siły), trafieni przez niego też - łańcuchem; każdy wróg raz na Ripostę, najwyżej
    12 (`_echo_from`, `_process_echoes`, `ECHO_*`).
  - Kamień Wędrownych Gromów (`k_perun`): z cięcia wyskakuje 2-6 piorunów (wg naładowania) pełzających po ziemi
    (`_Crawler` ze śladem), każdy do innego wroga w pobliżu końca cięcia - najpierw nietrafionych cięciem; gdy cel
    zginie, szukają wolnego (`_spawn_crawlers`, `_process_crawlers`, `CRAWL_*`), 60% siły.
  - Błysk Peruna ma już Kamień Nieskończonej Mgły. Ikony z symboli Watry (`tools/unique_gem_art.py`: pierce, momentum,
    echo, discharge). Test `_test_unique` w `test_katana.gd`.

## 15.11.2026 - Krąg stali nie pod „Atak”

- Decyzja autora: Krąg stali nie może stać pod dużym przyciskiem (`main: false`) - odpala się go osobno, np. razem
  z Młynkiem pod „Atak”. Zapis gry zdejmuje go z „Atak” sam (`Game._read_slots`). Test w `test_skills.gd`.

## 15.11.2026 - przyciski nad Watrą i skrzynią

- Zgłoszenie autora: gdy za przyciskiem interfejsu („Postać”, „Umiejętności”) stała Watra albo skrzynia, stuknięcie
  otwierało to, co pod przyciskiem. Watra, skrzynie w bazie (też kamień run, kowal, kupiec) i skrzynia po bossie
  czytają dotyk w `_input` - przed przyciskami - więc pytają teraz `TouchUi.covers` (`scripts/ui/touch_ui.gd`: widoczna
  kontrolka z MOUSE_FILTER_STOP pod palcem w warstwie interfejsu areny, grupa `touch_ui`). Test `tests/test_touch_ui.gd`.

## 15.11.2026 - Kamień Wiecznej Stali (kamień unikalny Kręgu stali)

- Wybór autora z 4 propozycji Claude: krąg bez końca (wzór - Kamień Wiecznego Wiru Młynka). `Gems.UNIQUE["steel_ring"]`:
  krąg nie znika po czasie i nie ma odnowienia (`ProtoWeapon.cooldown_full`), co sekundę płaci 1/5 kosztu many
  (`STEEL_DRAIN`, ok. 6 many/s), drugie stuknięcie (`cast`) albo brak many go wyłącza; gdy krąży, `can_use` zwraca false,
  więc spod „Atak” auto atak tnie wtedy zwykłym ciosem. Okno umiejętności: „30 many, potem 6 na sekundę, bez odnowienia”.
  Ikona `assets/watra/unique_gems/steel_ring.png` z klepsydry Watry (`venom`, `tools/unique_gem_art.py`).
  Test w `test_skills.gd`.

## 15.11.2026 - skoki: pamięć 3 ostatnich celów, zasięg 220 px

- Prośba autora: w dużej grupie Błysk Peruna skakał w kółko po dwóch wrogach, a w bazie nie przeskakiwał między
  kukłami. Skoki (`ProtoWeapon._flicker_target`) omijają teraz 3 ostatnie cele (`FLICKER_MEMORY`, `_recent_targets`;
  wcześniej tylko ostatni) - wracają do nich dopiero, gdy nikogo innego nie ma w zasięgu, od najdawniejszego. Zasięg
  skoku 220 px zamiast 150 (`FLICKER_RANGE`; kukły stoją od siebie 160-220 px). Test w `test_katana.gd`.

## 15.11.2026 - Błysk Peruna: jedno cięcie, piorun przy postaci

- Zgłoszenie autora: pioruny Błysku Peruna wychodziły daleko przed postać i czasem były dwa cięcia. Przyczyny: piorun
  przelatujący przez cięcie (`ProtoKatana._ArcBolt`) był dzieckiem katany, która po skoku dolatywała do postaci
  i ciągnęła go o całą długość skoku (teraz `top_level`, stoi w miejscu cięcia); do cięcia katany dochodziło cięcie
  Mgnienia miecza na celu (`ProtoWeapon.flicker_cut` - katana go nie pokazuje). Cięcie po skoku zwrócone w przebitego
  wroga (za plecami), a nie w pustkę przed postacią; smuga długiego skoku wydłuża się, ale nie grubieje.

## 15.11.2026 - Krąg stali zamiast Mgnienia miecza

- Pomysł autora (ten sam co propozycja Claude): Krąg stali (`steel_ring`, miecz, mistrz. 15, 30 many, 12 s) zamiast
  Mgnienia - przez 6 s wokół postaci krążą 3 widmowe miecze (świecące, mieszanie addytywne, delikatny ślad orbity),
  0,9 obrotu/s po spłaszczonej orbicie, każdy tnie wroga, przez którego przechodzi ostrze (ten sam wróg co 0,45 s,
  siła 0,6). Prośba autora: miecz w ręku walczy w tym czasie normalnie - krąg nie zmienia stanu broni
  (`ProtoWeapon._start_ring`, `_process_ring`, stałe `STEEL_*`). 5. poziom - 8 s, 10. - 5 mieczy, kamień Mnożenie -
  jeden miecz więcej. Może stać pod „Atak”. Ikona `assets/skills/sword/steel_ring.png` (`tools/weapon_icons.py`, tło stalowe).
- Mgnienie zostało tylko jako Błysk Peruna katany; jego kamień unikalny (Kamień Nieskończonej Mgły, skoki za pół
  many) przeszedł na Błysk Peruna (`Gems.UNIQUE["k_flash"]`, ikona `unique_gems/k_flash.png`). Stary zapis:
  `Gems.LEGACY` zamienia `unique:blink`, a kamienie włożone w Mgnienie wracają do sakwy (`Game.load_game`).
- Testy: Krąg stali w `test_skills.gd`, testy skoków przeniesione do `test_katana.gd` (Błysk Peruna, zapis).

## 15.11.2026 - katana przebudowana: szermierka zamiast czarów

- Uwaga autora: katana miała za dużo umiejętności maga. Nowy zestaw (pomysły autora, szczegóły wybrane w ankiecie):
  - Błyskawiczne cięcie: nowy cienki efekt z kreatora (`katana_cut`, część `swing_slash`, środek łuku `CUT_MID`,
    klatki z własnym fps - `_process_cut`, odbicie ujemną skalą), przez cięcie przelatuje błękitny piorun
    (`ProtoKatana._ArcBolt`, rysowany w grze).
  - Taniec ostrza (`k_dance`, zamiast Iaido, mistrz. 3): postać idzie 80 px naprzód (`ProtoHero.leap`) i tnie 4 razy
    w kierunku marszu, potem błękitny piorun przeskakuje po kolei między trafionymi (5. - 6 cięć, 10. - piorun skacze
    też na 3 wrogów obok).
  - Riposta (`k_riposte`, zamiast Łańcucha piorunów, mistrz. 6): 3 s gardy (`ProtoHero.parry_left`, sygnał
    `parried`, napis „Riposta!”) - następny cios nie rani; kontra: cięcie dookoła z kreatora (`katana_riposte`,
    `spin_slash`), wyskok ku najbliższemu wrogowi z podskokiem i cienkie, równe cięcie po okręgu (`_Ring`, rysowane
    w grze); 0,7 s nietykalności (`ProtoHero.protect`) - propozycja Claude przyjęta (5. - garda 5 s, 10. - pioruny
    z okręgu).
  - Sąd Peruna (`k_perun`, mistrz. 10): przytrzymanie ładuje (do 1,5 s, `Skills.is_charged`, `ProtoWeapon.charge_held`,
    `Arena._on_skill_released`), puszczenie - cięcie w linii ku najbliższemu wrogowi, 60-200 px długości, 10-28 px
    szerokości, siła x0,8-1,5; na ziemi rośnie półprzezroczysty pas; efekt `katana_line` (`dash_slash`) rozciągnięty
    do długości; nie pod „Atak” (5. - ładuje się w 1 s, 10. - piorun na końcu cięcia).
  - Błysk Peruna (`k_flash`, zamiast Burzy ostrzy, mistrz. 15): Mgnienie miecza (w `ProtoWeapon` umiejętność skoków
    to teraz `blink_skill`, smuga `flicker_trail`, kolor piorunów `bolt_color`) z dwoma błękitnymi piorunami wzdłuż
    skoku; każde trafienie katany poraża (`ProtoKatana._deal`). Mgnienie zostaje też przy mieczu.
- Usunięte: efekty `katana_slash` i `katana_perun`, ikony Iaido, Łańcucha i Burzy. Ikony nowych umiejętności
  z `tools/weapon_icons.py`. Zapis gry pomija stare umiejętności i sam dopisuje nowe (`Game._unlock_skills`).
- Testy: `test_katana.gd` (taniec, garda i kontra, ładowanie, Błysk). Zrzuty `tools/katana_shots.gd`.

## 15.11.2026 - elektryczna katana, znak przemoczenia i combo wody z Gromem i lodem

- Ocena autora: balans glewii i hydrosfery (siła, zasięg, kamienie unikalne, efekty, ceny i progi) w sam raz - bez zmian.
- Znak przemoczenia (wybór autora: kapiące krople): `ProtoTarget.soak` (spowolnienie + `soak_left`), `is_soaked`;
  krople z kreatora efektów („Przemoczenie - kapiące krople (pętla)”, część `water_drips`) - `assets/effects/soak_drips.png`,
  zapętlone w `_Status` (skala 0,6 przy goblinie). Przy przemoczeniu nie rysuje się szronowy krąg spowolnienia.
  Hydrosfera przemacza przez `soak`.
- Combo (wybór autora: „oba”, `Elements.SOAK_BONUS`, `SOAK_CHAIN_EXTRA`, `SOAK_FREEZE`, `soak_bonus`): przemoczony
  dostaje od Gromu i lodu +30% (`ProtoWeapon._combo_mult`, żywioł broni w `ProtoWeapon.element`), piorun
  z przemoczonego (`_chain_from` - też kamień Wyładowanie) przeskakuje na 2 wrogów więcej i rani +30%, lód (kamień Szron)
  zamraża przemoczonego na 0,6 s (`ProtoTarget.freeze`, potem 2 s odporności - `FREEZE_IMMUNE`, żeby woda + Szron
  nie trzymały wroga w miejscu bez końca). Porażony (Grom) dostaje od wszystkiego +15% (`Elements.SHOCK_BONUS`,
  `ProtoTarget.shock`, żółte iskry wokół celu). Prawdziwa broń lodu dostanie +30% sama (`soak_bonus` dla `COLD`).
- Elektryczna katana (`Weapons.KATANA`, Grom, Wódz 20 albo 6000 zł - wybór autora; `scripts/proto/proto_katana.gd`),
  umiejętności zaproponowane przez Claude i przyjęte bez zmian: Błyskawiczne cięcie (`k_slash`, ok. 1,4 raza szybciej
  niż miecz, siła 0,75; 5. poz. - co 4. cięcie piorun w najbliższego, 10. - przeskok na 2 wrogów), Iaido (`k_iaido`,
  mistrz. 3, zryw 70 px na wylot przez wroga, rani pas drogi; 5. - 100 px, 10. - wyładowanie na końcu), Łańcuch piorunów
  (`k_chain`, mistrz. 6, 5 skoków co 0,07 s; 5. - 7, 10. - iskry na ziemi 2 s), Sąd Peruna (`k_perun`, mistrz. 10,
  3 pioruny z nieba, obszar 22 px, ogłuszenie 0,6 s; 5. - 5, 10. - druga seria po 0,5 s), Burza ostrzy (`k_storm`,
  mistrz. 15, katana sama skacze co 0,22 s między wrogami do 120 px od postaci przez 3 s; 5. - 4 s, 10. - rozgałęzienia
  na 2 wrogów). Każde trafienie poraża i 25% obrażeń przeskakuje na sąsiada (`ProtoKatana._hit`). Kamienie unikalne
  katany - później.
- Grafika (wybór autora: stal + niebieskie iskry): `assets/weapons/katana.png` (76x16, skala 0,5) rysowana skryptem
  `tools/katana_art.py`. Efekty z kreatora (My effects autora, `pixellab_src/vfx/ids.json`): `katana_hit` (trafienie
  piorunem, część `zap_hit`), `katana_perun` (piorun z nieba, `bolt_strike`), a `katana_slash` i `katana_trail` to
  przebarwione na błękit cięcie miecza i smuga Mgnienia (`hue`, `boost`). Ikony umiejętności `assets/skills/katana/`
  z `tools/weapon_icons.py` (tło burzowe).
- Okno umiejętności: przyciski broni z ikoną nad nazwą (4 bronie w rzędzie), zawijane mistrzostwo i nazwy umiejętności
  (wcześniej „Błyskawiczne cięcie poz. 1/10” rozpychało okno poza ekran).
- Testy: `tests/test_katana.gd` (dopisany do `run_tests.ps1`), zrzuty `tools/katana_shots.gd` (Burza ostrzy w chmurze
  ok. 75 klatek/s).

## 15.11.2026 - tryb deweloperski: więcej żaru

- Prośba autora: przycisk żaru w oknie deweloperskim daje 5000 zamiast 100 (`DevWindow.DEV_EMBERS`) - w lochu do paska
  wyprawy, w bazie do Watry.

## 15.11.2026 - sakwa w zakładce „Kamienie”: tylko pasujące kamienie

- Prośba autora: po wyborze umiejętności sakwa w zakładce „Kamienie” okna umiejętności pokazuje tylko kamienie, które
  da się do niej włożyć - klucz, zwykłe kamienie wsparcia i kamień unikalny tej umiejętności (unikalne innych umiejętności
  ukryte). Kamień unikalny stoi osobno, za złotą kreską z napisem „Unikalny” (`SkillsWindow._unique_divider`).
  Test w `test_gems.gd`.

## 14.11.2026 - hydrosfera: Wodny Strażnik zamiast Ulewy, kamienie unikalne

- Pomysły autora (warianty wybrane w ankiecie): Ulewa zastąpiona „Wodnym Strażnikiem” (`h_guardian`, mistrz. 15,
  30 many, 12 s): kula wody (tekstura hydrosfery 1:1, unosi się 16 px) pojawia się 10 px przed wrogiem (albo 50 px
  przed postacią) z wybuchem wody (34 px, x1,2 siły, odpycha), zostaje 6 s i co 0,5 s strzela pociskiem (bez rozprysku)
  w najbliższego wroga do 120 px; 5. poziom - 8 s, 10. - dwie kule po bokach. Usunięte sople Ulewy (`hydro_drop`).
- Kamienie unikalne (`Gems.UNIQUE`, ikony `unique_gem_art.py`: pierce, rime, frost_edge, brutal, warlord):
  Kamień Wodnej Orbity (pocisk: bańka zamiast lotu krąży 3 s wokół postaci, promień 40 (prośba autora: dalej od postaci; było 28), 0,9 obrotu/s, przebija -
  ten sam wróg co 0,5 s, najwyżej 4 naraz - `_orbits`; własny efekt z kreatora „Hydrosfera - krążąca bańka z ogonem” - `hydro_orbit`: bańka
  z ogonem wygiętym po łuku orbity, obracany w spłaszczonym węźle wokół postaci), Kamień Przypływu (6 fal dookoła, 60% siły), Kamień Wędrownego
  Wiru (wir płynie 32 px/s ku najbliższemu wrogowi, +1 s), Kamień Erupcji (każdy gejzer wypluwa 3 kule wody łukiem na
  40 px, po upadku obszar 18 px, 60% siły - `_lobs`), Kamień Echa (Strażnik powtarza Falę, Wir i Gejzery gracza ze
  swojego miejsca, za darmo, 50% siły - `_echo`). Funkcje umiejętności przyjmują punkt startu i mnożnik siły
  (`_spawn_tide(from, mult)`, `_add_vortex(at, mult)`, `_geysers(origin, mult)`, `_spawn_bolt`).
- Testy: `test_hydrosphere.gd` (`_test_unique`, Strażnik zamiast Ulewy).

## 14.11.2026 - hydrosfera: rozbryzg w kierunku trafienia

- Prośba autora: trafienie wodnym pociskiem było pionowym pluśnięciem. Nowy efekt z własnych warstw kreatora
  „Hydrosfera - rozbryzg w kierunku trafienia” (`hydro_spray`: błysk, łuk wody, krople i strugi w stożku w prawo,
  kilka kropel do tyłu), w grze obracany w kierunku uderzenia (`ProtoHydrosphere._spray_fx`): pocisk (kierunek lotu),
  rozprysk na sąsiadach (od trafionego ku sąsiadowi), Fala (kierunek fali, na każdym trafionym), wybuch wiru
  z 10. poziomu (od środka). Pionowe pluśnięcie zostaje dla Ulewy, gejzerów i pocisku, który nikogo nie trafił.

## 14.11.2026 - hydrosfera: nowe efekty Fali i Wiru (bardziej jak woda)

- Prośba autora: Fala wyglądała jak niebieskie cięcie, a Wir jak niebieska magia z latającym cięciem. Kreator nie ma
  gotowych części wody na fale i wiry, więc oba efekty złożone z własnych warstw kreatora: Fala (`hydro_wave`,
  „Hydrosfera - fala wody (pętla)”) - sierp wody (shape, wypełnienie edge), falująca grzywa piany i wewnętrzna linia
  piany (krzywe z formułami, ruch w pętli), krople pryskające do przodu i smugi kilwateru z tyłu; Wir (`hydro_vortex`,
  „Hydrosfera - wir wodny (pętla)”) - ciemna toń (glow na ziemi), dwie spirale wody na ziemi (jasna i ciemna, obrót
  w pętli), obręcz piany i krople krążące po brzegu. Usunięty łuk wiru `hydro_swirl` (przebarwione cięcie tańca)
  i obracany węzeł. Ikony Fali i Wiru odświeżone (`tools/weapon_icons.py`).

## 14.11.2026 - hydrosfera (trzecia broń, woda)

- Decyzje autora (ankiety 14.11.2026): hydrosfera - woda, walka na dystans, kula wody nad ręką; Wódz 15. poziomu albo
  4500 zł; umiejętności jak w propozycji Claude (nowe działania 5. i 10. poziomu też - do oceny).
- `ProtoHydrosphere` (`scripts/proto/proto_hydrosphere.gd`, dziedziczy po ProtoWeapon): każde trafienie przemacza
  (`_hit` -> `ProtoTarget.slow` 20% na 3 s). Wodny pocisk (`h_bolt`, zwykły cios): kula podlatuje i wypluwa bańkę
  230 px/s do 140 px, lekko naprowadzaną na cel; pęka na pierwszym trafionym, rozprysk 20 px (50%) - 5. poziom x1,5,
  10. - co trzeci strzał 3 bańki w wachlarzu ±18°. Fala (`h_wave`, mistrz. 3, 15 many, 5 s): sierp wody 160 px/s na
  110 px, przebija i odpycha (5. - x1,5 dalej, 10. - druga fala po 0,3 s). Wir (`h_vortex`, 6, 20 many, 8 s): 3 s
  w miejscu wroga, promień 42, wciąga (push_away od punktu za celem), co 0,4 s rani 0,35 (5. - 4 s, 10. - wybuch wody
  na koniec). Gejzery (`h_geyser`, 10, 25 many, 8 s): pod 5 najbliższymi wrogami w 120 px po 0,35 s (pod wrogiem
  tam, gdzie akurat stoi) - rani 1,8 i ogłusza 1 s (5. - 1,5 s, 10. - 8 gejzerów). Ulewa (`h_rain`, 15, 30 many,
  12 s): 4 s, co 0,25 s sopel spada w 0,3 s na losowego wroga w 130 px (5. - 6 s, 10. - co 0,125 s).
- `Weapons.script_of` / `make` (arena podmienia węzeł przez porównanie skryptu), `Weapons.short_name_of` (krótkie
  nazwy na przyciskach broni - „Glewia”; niedostępna broń pokazuje cenę), `STRIKE_STATES` z `orb_windup`/`orb_shot`.
- Grafika: kula 24 px w skali 0,5 (`assets/weapons/hydrosphere.png`, narzędzie pikseli PixelLab; pierwsza wersja 18 px
  1:1 była za duża i toporna). Efekty z kreatora (My effects autora): `hydro_bolt` (bańka, pętla), `hydro_splash`
  (rozprysk), `hydro_wave` (sierp wody, klatki 3-12 w pętli), `hydro_vortex` (kręgi z bąbelkami, pętla),
  `hydro_geyser`, `hydro_drop` (sopel, w grze ostrzem w dół) i `hydro_swirl` (łuk wiru - przebarwione cięcie tańca
  glewii, `vfx_art.py` `hue`; w grze obracany w spłaszczonym węźle). Ikony: `tools/weapon_icons.py` (dawniej
  `glaive_icons.py`, motyw wody - granat z turkusową poświatą) -> `assets/skills/hydro/`. Zrzuty `tools/hydro_shots.gd`
  (Ulewa z wirem: 61-68 klatek/s w chmurze).
- Test: `tests/test_hydrosphere.gd`. Kamieni unikalnych hydrosfera jeszcze nie ma.

## 14.11.2026 - efekt podpalenia na potworach

- Prośba autora: podpalony potwór płonie. Nowy zapętlony efekt z kreatora „Podpalenie potwora (pętla)”
  (`burning`, część flame_aura bez kręgu u stóp, 8 klatek, 12 fps, `assets/effects/burning.png`) zamiast trzech
  kropek nad głową. `ProtoTarget._Status`: dwie kopie płomieni - za celem (x1,6) i przed nim (x0,8, 75%), obie
  z mieszaniem addytywnym (`CanvasItemMaterial.BLEND_MODE_ADD` - ciemny kontur efektu znika, cel prześwituje),
  skala od `center_height` (goblin 18), klatki przesunięte między celami, gasną w ostatnich 0,4 s podpalenia.
  Działa dla każdego podpalenia (glewia, kamień Żar). W Tańcu płomieni z płonącymi goblinami 81 klatek/s w chmurze.

## 14.11.2026 - własne ikony umiejętności glewii

- Decyzja autora: ikony złożone z grafik gry zamiast PixelLab AI (limit autora: 9 generacji do 27.11).
  `tools/glaive_icons.py` składa 64x64: ramka w kształcie ikon Watry (kontur, łupkowy pas, jaśniejsza krawędź - `RING`),
  ciemne tło z żarem od dołu, głowica glewii w pełnej rozdzielczości (`HEAD`, cała pomniejszona miała drzewce jak nitka)
  i klatki efektów z kreatora: pchnięcie - smuga i trafienie, zamach - ognisty łuk, bruzda - płomyki i wachlarz sierpów,
  Słup ognia - wybuch z glewią ostrzem w dół, taniec - trzy łuki cięć. Wynik: `assets/skills/glaive/g_*.png`
  (ikona glewii na przycisku broni - `g_thrust`). Usunięte tymczasowe ikony z Watry (enchanted_blade, crescent,
  fire_wall, aura_swarog_ember, ks_blade_dance). Podpowiedź na polanie: „Trzymaj przycisk ataku” zamiast „miecz”.

## 14.11.2026 - kamienie unikalne glewii

- Pomysły autora (Słup ognia - wybór z propozycji Claude): Kamień Trójzęba (pchnięcie: 3 pchnięcia w stożku ±12°,
  każdy wróg obrywa raz), Kamień Pogorzeliska (zamach: płonąca ziemia wzdłuż łuku na 70% zasięgu, 3 s - strefa
  z kół `"circles"`, `_add_arc_zone`), Kamień Bumerangu (bruzda: cięcia po dolocie zawracają do postaci, 220 px/s,
  ranią drugi raz), Kamień Ognistego Deszczu (Słup ognia: glewia spada po kolei w 3 wrogów w promieniu 120 px,
  wybuchy 60%, kręgi 60%, szybsze wznoszenie - `_pillar_queue`), Kamień Rykoszetu Płomieni (taniec: sierp po
  trafieniu odbija się w najbliższego nietrafionego wroga do 90 px, do 3 odbić - `_bounce_target`).
- Dane w `Gems.UNIQUE` (klucze `g_*`), ikony `tools/unique_gem_art.py` (split, ember, echo, area, discharge; szary
  kamień „split” złocony po jasności - `FORCE`). Testy: `test_glaive.gd` (`_test_unique`), `test_gems.gd` - wszystkie
  umiejętności mają kamień unikalny.

## 14.11.2026 - glewia: Płonąca bruzda zamiast doskoku, nowy Taniec płomieni, zwężona smuga pchnięcia

- Prośby autora po teście: smuga pchnięcia miała płaski tył od strony postaci - `tools/vfx_art.py` dostał opcję
  `"taper": n` (pierwsze n kolumn klatki przycięte w szpic ku wysokości zaczepienia i obrysowane), dla `glaive_thrust` 14.
- Taniec płomieni bez wiru (Młynek miecza): co 0,3 s glewia przeskakuje pod nowy kąt (obrót 100-200° w losową stronę)
  i tnie łukiem 140° na przemian w obie strony; każde cięcie gra nowy efekt z kreatora `glaive_dance_slash`
  („Glewia - cięcie tańca”, łuk ognia, 28 fps) i w połowie wypuszcza sierp ognia jak wcześniej.
- Płonąca bruzda (`g_trail`, pomysł autora, decyzje z ankiety: krótki pas ognia, cięcia szybkie ok. 130 px):
  glewia wbija się w ziemię 12 px przed postacią i ryje do 40 px (0,1 s wbicie, 0,22 s ciągnięcie), postać stoi;
  zostaje pas ognia (3 s, 5. poziom - 5 s), a w wachlarzu ±20° wylatują 3 cięcia (10. poziom - 5) - sierpy
  `glaive_cut` 260 px/s na 130 px, przebijają i podpalają. Zasięg auto ataku 120. `_spawn_cut` ma teraz umiejętność,
  punkt startu, prędkość i zasięg.

## 13.11.2026 - glewia ognia (pierwsza nowa broń) i kolczyk z kłem

- Decyzje autora (ankiety 13.11.2026): pierwsza broń po mieczu - glewia ognia; za darmo po pokonaniu Wodza na 10.
  poziomie lochu, wcześniej za 3000 złota; zmiana broni w oknie umiejętności przy kamieniu run; miejsce „Broń”
  zamienione na kolczyk z kłem (wspólny dla wszystkich broni); umiejętności jak w propozycji, ale 15. próg to seria
  zamaszystych cięć lecących dookoła (pomysł autora zamiast kul ognia); grafika rysowana w narzędziu pikseli PixelLab,
  wszystkie efekty nowe z kreatora efektów.
- Kolczyk z kłem (`Items`): miejsce "earring" zamiast "weapon" (ikony z Watry - linia „fang”, 5 stopni + magiczne
  i rzadkie, `assets/watra/items/fang_*.png`, pusty `slot_earring.png`), stała cecha „Obrażenia ciosu” (dawne obrażenia
  cięcia miecza). Stare miecze z zapisu (torba, skrzynia, założone) wczytują się jako kolczyki tej samej siły
  (`Items.LEGACY_SLOTS`, `Items.normalize`, `Game.load_game`). Kamienie szlachetne: grupa „kolczyk” (dawniej „broń”).
- Bronie (`Weapons`): glewia (`glaive`: ogień, `unlock` 10, `price` 3000), `Weapons.make` - węzeł broni (miecz -
  ProtoWeapon, glewia - ProtoGlaive). `Game.weapon_available`, `buy_weapon`, `set_weapon` (sygnał `weapon_changed`),
  `weapons_bought`, `weapon_slots` - każda broń ma własne miejsca umiejętności i mistrzostwo; `assign_skill` przyjmuje
  tylko umiejętności broni w ręku. Arena podmienia węzeł broni po zmianie (`_swap_weapon`). Okno umiejętności: rząd
  przycisków broni pod mistrzostwem (stuknięcie bierze broń do ręki albo kupuje ją - drugie stuknięcie; z pauzy nic),
  lista tylko umiejętności broni w ręku (`row_boxes`).
- Umiejętności glewii (`Skills`, "weapon": "glaive", pole "burn" - ile obrażeń trafienia dopala się przez 3 s):
  Pchnięcie glewii (zwykły cios, zasięg 64, linia ±12 px, podpalenie 30%; 5. poziom - podpalenie x2, 10. - co trzecie
  dźga dwa razy), Ognisty zamach (mistrz. 3, 15 many, 5 s, łuk 200°, 58 px, x1,3, podpalenie 100%; 5. - odpycha,
  10. - drugi zamach w drugą stronę), Płonący ślad (mistrz. 6, 20 many, 7 s, doskok 90 px, pas ognia 3 s; 5. - 5 s,
  10. - wybuch na końcu), Słup ognia (mistrz. 10, 25 many, 8 s, wybuch 50 px x2,2 i płonący krąg 36 px na 3 s;
  5. - krąg x1,5, 10. - drugi wybuch po 0,5 s), Taniec płomieni (mistrz. 15, 30 many, 10 s, 3 s wirowania, co 0,3 s
  sierp ognia leci 70 px/s na 150 px i przebija; 5. - 4 s, 10. - po dwa sierpy w przeciwne strony). Ogień na ziemi
  co 0,5 s rani (25% siły umiejętności) i podpala. Nowe działania 5. i 10. poziomu zaproponował Claude - do oceny.
  Ceny ulepszeń w żarze jak umiejętności miecza (40-200 x poziom). Kamieni unikalnych glewia jeszcze nie ma.
- `ProtoGlaive` (`scripts/proto/proto_glaive.gd`) dziedziczy po ProtoWeapon (podążanie, mana, odnowienia, kamienie,
  krytyki); ProtoWeapon dostał `basic` (zwykły cios broni) i `STRIKE_STATES`, `Skills.basic_of`, `is_basic`,
  `of_weapon`, `burn_of`. Pusty „Atak” to zwykły cios broni w ręku (`Game.main_skill`, `ActionCluster.show_skills`).
- Grafika: glewia `assets/weapons/glaive.png` (96x20, skala 0,5) narysowana w pixelart_workbench (lint bez błędów).
  Efekty z kreatora (My effects autora, `pixellab_src/vfx/ids.json`): `glaive_thrust` (smuga pchnięcia),
  `glaive_sweep` (ognisty łuk), `glaive_blast` (wybuch), `glaive_ground_fire` (płomyk w pętli - wiele na pas i krąg),
  `glaive_cut` (lecący sierp, klatki 3-12 w pętli), `glaive_hit` (trafienie ogniem). Ikony umiejętności tymczasowo
  z Watry (enchanted_blade, crescent, fire_wall, aura_swarog_ember, ks_blade_dance). Zrzuty: `tools/glaive_shots.gd`
  (w tańcu z ogniem na ziemi 83 klatki/s w chmurze).
- Testy: `tests/test_glaive.gd` (nowy), `test_items.gd` (kolczyk i przejście zapisu).

## 13.11.2026 - żywioły i mistrzostwo broni (etap 1: fundament)

- Decyzje autora (ankieta 13.11.2026): żywioły jak w propozycji, najpierw fundament (efekty razem z bronią danego
  żywiołu); potwory na razie biją fizycznie, odporności bohatera później; miecz fizyczny, żywioł dodadzą mu najwyżej
  kamienie; nowe bronie odblokowuje postęp (Wódz na danym poziomie) albo wcześniej dużo złota; jedna broń naraz,
  zmiana w bazie; ulepszenia lochów za złoto, żar na umiejętności; mistrzostwo z pokonanych potworów i bossów.
- `scripts/elements.gd` (`Elements`): fizyczne + 8 żywiołów (ogień, woda, lód, Grom, ziemia, powietrze, Nawia, natura),
  nazwy, kolory, opisy działania (`EFFECTS`), odporności potworów (`MONSTER_RESIST`, na razie puste), obrażenia
  z odpornością `reduce` (odporność najwyżej 75%, wrażliwość do -100%, cały mnożnik z combo najwyżej `MAX_MULT` = x2).
  Jeszcze niepodpięte do walki - pierwsza broń żywiołowa to zrobi.
- `scripts/weapons.gd` (`Weapons`): rodzaje broni (na razie miecz: fizyczny, od początku), pola `unlock` (poziom lochu)
  i `price` (złoto) pod kolejne bronie, mistrzostwo po krzywej poziomów postaci (`xp_to_next`), najwyżej 50.
- Mistrzostwo (`Game.weapon`, `Game.mastery`, `Game.mastery_xp`, `add_mastery`, sygnały `mastery_changed`,
  `skill_unlocked`): arena dolicza je w `_gain_xp` - tyle samo co doświadczenie postaci, więc dla miecza tempo
  się nie zmienia. Progi umiejętności (`Skills.DATA` pole `mastery`): Młynek 3, Rzut 6, Rozłupanie 10, Mgnienie 15
  (jak dawne wymagane poziomy postaci). Odblokowana umiejętność sama wskakuje w wolne miejsce, nad postacią napis
  „Nowa umiejętność: …!” (`ProtoHero.skill_unlocked`, wspólne `float_text`). Limit poziomu umiejętności: połowa
  mistrzostwa (`Skills.level_cap`).
- Ulepszenia umiejętności za żar (`Game.upgrade_skill`, ceny bez zmian liczbowych: 40-200 x poziom), ulepszenia lochów
  za złoto (`Game.buy_upgrade`, ceny 50-1000 bez zmian). Okno umiejętności: żar i pasek mistrzostwa u góry, przy
  nieodblokowanej „od mistrz. N” zamiast „Kup”; okno ulepszeń lochów pokazuje złoto.
- Stary zapis (bez `mastery`, `Game._migrate_mastery`): mistrzostwo miecza = poziom postaci, kupione umiejętności
  i poziomy zostają, wraca złoto za umiejętności (`Skills.LEGACY_PRICE`) i ich poziomy oraz żar za ulepszenia lochów.
- Testy: `tests/test_elements.gd` (nowy), `test_skills.gd` (mistrzostwo, przejście zapisu), `test_base.gd` (złoto).

## 13.11.2026 - głębokie lochy trudniejsze, Mgnienie jak Flicker Strike

- Zgłoszenie autora z testu w oknie deweloperskim: na 100. poziomie lochu za mało potworów, za mało zdrowia i obrażeń
  (postać 15. poziomu wytrzymywała 2-3 ciosy), a Mgnienie ze 100% skrócenia odnowienia dawało prawie nietykalność.
- Siła lochu (`DungeonLevels.power`): `(1 + 0,15 x (poziom-1)) x 1,02^(poziom-1)` - 10. poziom x2,8 (było 2,35),
  50. x22 (było 8,4), 100. x113 (było 16). Premie przedmiotów, które rosną z lochem, idą za tą samą krzywą.
  Doświadczenie za potwory rośnie po staremu liniowo (`DungeonLevels.reward`), żeby postać nie awansowała lawinowo.
- Tłum (`DungeonLevels.crowd`): +1% gęstości strumienia na poziom, najwyżej x1,55; razy ulepszenie „Gęstsza Horda”.
  Twardy limit `ProtoHorde.ALIVE_CAP` = 70 potworów naraz. Pomiar w chmurze (programowy OpenGL): 45 goblinów - 55
  klatek/s, 70 - 43 klatek/s; do sprawdzenia na telefonie.
- Mgnienie (decyzja autora: spam jak Flicker Strike w PoE): bez odnowienia i bez limitu 3 skoków (`Skills` cooldown 0,
  usunięte `BLINK_JUMPS` i przerwa serii), hamulcem jest mana (7 na skok). Wróg zabity skokiem zwraca
  `Skills.BLINK_MANA_ON_KILL` = 2 many (`ProtoWeapon._blink_kill`, też z cięcia Mnożenia i wiru). Skok nie daje już
  nietykalności (`ProtoHero.teleport`). Nowe działania: 5. poziom - zwrot many x2 (było: pierwszy skok serii za darmo),
  10. poziom - wir co `BLINK_SPIN_EVERY` = 5 skoków (było: po ostatnim skoku serii). Kamień unikalny „Nieskończonej Mgły”:
  skoki za pół many (było: bez limitu i odnowienia). Ciosy goblinów nadal chybiają, gdy postać odskoczy w trakcie zamachu.
- Skrócenie odnowienia zostaje do 100% (autor: Mgnienie już go nie potrzebuje).
- Testy: `test_skills.gd` (Mgnienie), `test_horde.gd` (`_test_depth`).

## 13.11.2026 - okno trybu deweloperskiego

- Prośba autora: okno z wszystkimi funkcjami trybu deweloperskiego, każda statystyka postaci ustawiana na dowolną wartość
  (do sufitu) i wejście na dowolny poziom lochu bez przebijania poprzednich - do testów balansu.
- Pauza (`pause_menu.gd`): zamiast dwóch rzędów skrótów i przełącznika nieśmiertelności jeden przycisk „Tryb deweloperski”,
  który otwiera `DevWindow` (`scripts/ui/dev_window.gd`) nad pauzą; „wstecz” zamyka najpierw okno deweloperskie.
- `DevWindow`: nieśmiertelność, „Wszystkie poziomy lochu (bez przebijania)”, stare skróty (stałe `DEV_EMBERS`, `DEV_ITEMS`
  przeniesione z pauzy), poziom postaci przyciskami -10/-1/+1/+10 (`Game.dev_set_level`, 1-50, doświadczenie od zera),
  sekcja „Statystyki”: wiersz z opisem jak na przedmiocie i suwak z −/+/↺ dla obrażeń broni i każdej z 18 premii
  (zmienione - zielone). Suwak zastępuje sumę z przedmiotów, sięga do sufitu `Items.CAPS` albo `DevWindow.STAT_MAX`.
  „Wszystkie z przedmiotów” czyści nadpisania. Bez broni wiersz obrażeń pokazuje zwykły miecz.
- `Game`: `dev_stats` (statystyka -> wartość, `gear()` przez `Items.with_overrides`; obrażenia broni - klucz
  `Items.WEAPON_DAMAGE`, rozrzut x1,4 - `Items.weapon_damage_from`), `dev_all_levels` (`unlocked_level` daje
  `DEV_MAX_LEVEL` = 100), oba zapisywane w `user://settings.cfg` (sekcja `dev`). Zmiana suwaka od razu działa w grze
  (sygnał `inventory_changed`), zapis ustawień przy zamknięciu okna.
- Wybór poziomu przy Watrze (`level_picker.gd`): przy ponad 10 poziomach dochodzą przyciski −10 / +10.
- Test: `tests/test_dev.gd`; zrzuty: `SCRIPT=tools/dev_shots.gd tools/screenshot.sh <prefiks>`.

## 13.11.2026 - premie: obszar, unik, zasięg zbierania, żar

- Wybór autora z punktu „Na później” (więcej statystyk): wszystkie cztery premie, bez nowych kamieni. Każda na każdym miejscu.
- `Items` (`STAT_FORMATS`, `AFFIXES`, `CAPS`): `area_pct` 4-8% (+0,2 na poziom lochu, sufit 100%), `dodge_pct` 2-4% (+0,1,
  sufit 50%), `pickup_pct` 10-20% (+0,5, sufit 200%), `ember_pct` 4-8% (+0,3, sufit 100%). W puli jest teraz 18 premii.
- Obszar: `ProtoWeapon.area_bonus` (procenty) dodaje się do kamienia Szerokość w `_area` - działa na zwykły cios, falę,
  wir, rzut, Rozłupanie i Mgnienie.
- Unik: `ProtoHero.dodge` (0-1) w `take_damage` - chybiony cios daje napis „Unik!” (jasnoniebieski, `_spawn_text`),
  sygnał `dodged` i zwykłą krótką nietykalność (żeby dotyk goblina nie losował co klatkę).
- Zasięg zbierania i żar: `ProtoHorde.pickup_mult` mnoży przyciąganie iskier i łupu (razem z ulepszeniem „Długie ręce”),
  `ProtoHorde.ember_mult` mnoży żar z iskier (także ze skrzyni Wodza; ułamki zbierają się w `_ember_rest`). Więcej żaru
  to też szybciej pełny pasek przyzwania Wodza. Skrót deweloperski idzie przez `add_embers` (bez premii).
  Ustawia je `arena._apply_weapon` (też po zmianie ekwipunku w lochu).
- Okno „Postać” (`hero_stats.gd`): wiersze Unik, Obszar umiejętności, Zasięg zbierania, Żar - widoczne tylko z premią,
  w porównaniu przedmiotów.
- Test: `tests/test_items.gd` (`_test_utility_stats`).

## 13.11.2026 - nowe statystyki przedmiotów, poprawka górnego paska w lochu

- Pomysł autora: więcej statystyk na przedmiotach. Ustalone: 6 nowych premii, wszystkie na każdym miejscu (jak stare 8),
  bazowy krytyk postaci 5% za 150%, liczby jak w propozycji, kamienie bez zmian.
- `Items` (`STAT_FORMATS`, `AFFIXES`, `CAPS`, `DECIMAL_STATS`): `crit_pct` 2-4% (+0,1 na poziom lochu, sufit z przedmiotów
  95% - razem pewny krytyk), `crit_dmg_pct` 10-20% (+0,5), `life_on_kill` 1-2 (z siłą lochu), `cdr_pct` 3-6% (+0,15, sufit
  100% - odnowienie aż do zera; decyzja autora: osiągalne, ale bardzo trudne, jak w PoE),
  `elite_dmg_pct` 6-12% (+0,5), `mana_regen` 0,5-1,2 na s (z siłą lochu; jedno miejsce po przecinku, też przy wczytaniu zapisu).
- Działanie: `ProtoWeapon._deal` - premia przeciw elitom (`ProtoGoblin.elite`) i Wodzowi, krytyk (`crit_chance`,
  `crit_mult`; liczba złota, większa, z „!” - `ProtoTarget.crit_next`, `CRIT_COLOR`), `cooldown_cut` w `_cooldown_base`;
  arena ustawia je w `_apply_weapon` z `HeroStats.crit_chance` / `crit_damage` (bazowe `CRIT_CHANCE` 5, `CRIT_DAMAGE` 150);
  `ProtoHero` - mana na sekundę `HeroLevels.MANA_REGEN` + `mana_regen`; `ProtoHorde._on_died` leczy o `life_on_kill`.
- Okno „Postać”: nowe wiersze (szansa na krytyk, obrażenia krytyczne, odnowa many zawsze; zdrowie za zabicie,
  odnowienie, przeciw elitom - gdy przedmioty coś dają), porównanie przy zakładaniu (`COMPARE_KEYS`; odnowienie - mniej to lepiej).
- Poprawka: wiersz „Loch N · Pokonane · żar · czas” w lochu potrzebował ok. 216 px przy ok. 180 dostępnych - rozpychał
  cały interfejs (czas ucięty za krawędzią, okno „Postać” szersze od ekranu, ucięte „Wróć”). Teraz dwa wiersze:
  „Loch N … czas” i „Pokonane … żar”.
- Test: `_test_new_stats` w `tests/test_items.gd`.

## 13.11.2026 - elitarne potwory

- Ustalone z autorem: elity rzadko od 2. poziomu lochu, cechy Szybki, Tarczowy, Wybuchowy, Dowódczy, nagroda - przedmiot
  i dużo żaru, wygląd - większa, poświata, napis z cechami i pasek zdrowia. Kolczastego (odbijanie obrażeń) odradziłem na
  telefon (auto atak).
- `Elites` (`scripts/elites.gd`, dane): cechy z kolorami, pierwsza elita po 25-35 s, kolejne co 45-65 s; cech najwyżej
  1 (poziomy 2-3), 2 (od 4.), 3 (od 7.), losowo max-1..max; zdrowie x3 (+0,75 za każdą cechę ponad pierwszą), obrażenia x1,3,
  większa o 25%; nagroda: iskra za 10 żaru, przedmiot z wagami skrzyni bossa (`Items.CHEST_WEIGHTS`), doświadczenie x5.
  Szybki: prędkość x1,6, odstęp ataków x0,6. Tarczowy: tarcza 50% zdrowia, wraca po 4 s bez obrażeń (niebieskie liczby,
  bańka, niebieski pasek). Wybuchowy: po śmierci koło 34 px, po 1,2 s wybuch 20 obrażeń x siła poziomu (`ProtoElite.blast`,
  efekt `boss_slam` na pomarańczowo). Dowódczy: gobliny w promieniu 90 px szybsze i silniejsze o 30%, lekko złote
  (`ProtoGoblin.empower`, `hit_damage`, `speed_factor`), krąg na ziemi.
- `ProtoElite` (`scripts/proto/proto_elite.gd`, dziecko goblina, `promote` przed dodaniem do sceny): poświata - shader
  obrysu (1 px pełny + 2 px półprzezroczysty, pulsuje; zdejmowany po śmierci i ucieczce), napis z cechami (8 px), pasek zdrowia.
- `ProtoGoblin`: `elite`, `damage_mult`, `hit_damage()` (też łucznik i osiłek), `_absorb` (tarcza; także osiłek w zamachu
  i podpalenie), `empower`. `ProtoHorde`: `spawn_elite`, `spawn_at(pos, kind, elite_traits)`, `_roll_kind`, sygnał
  `elite_killed` (arena dolicza `HeroLevels.goblin_xp` x (Elites.XP - 1)).
- Test: `_test_elites` w `tests/test_horde.gd`; zrzuty `tools/elite_shots.gd`.

## 13.11.2026 - goblin osiłek (trzeci rodzaj potwora)

- Ustalone z autorem: goblin osiłek od 3. poziomu lochu, grafika ze SpriteKiln, cios w ziemię z czerwonym kołem.
- `ProtoGoblinBrute` (`scripts/proto/proto_goblin_brute.gd`, podklasa `ProtoGoblin`): 150 zdrowia, 28 px/s, z 28 px
  bierze zamach; koło `ProtoTelegraph` (promień 26) 14 px przed nim w stronę postaci, wypełnia się przez 1 s, potem
  maczuga uderza (22 obrażenia x siła poziomu, tylko w kole; efekt `boss_slam` i dźwięk `chief_slam`), 0,45 s powrotu,
  zamach co 2,4 s. Animacja `attack` rusza `ANIM_HIT_AT` s przed uderzeniem (jak u Wodza), uderzenie liczy zegar.
  Ciężki: cięcie w trakcie zamachu tylko rani (bez przerwania), odrzut i odepchnięcie x0,3; ogłuszenie przerywa i gasi koło.
- `DungeonLevels.brute_share`: od `BRUTE_FROM` = 3 udział 8%, +2% na poziom, sufit 15%; `ProtoHorde`: `spawn_at(pos, kind)`
  (`"goblin"`, `"archer"`, `"brute"`), `count(klasa)`, najwyżej `MAX_BRUTES` = 3 naraz, z osiłka iskra za `BRUTE_EMBERS` = 3 żaru.
- `ProtoGoblin.shadow_scale` (większy cień osiłka).
- Grafika: `art/specs/characters/goblin_brute/goblin_brute.yaml` (na bazie goblina) -> `assets/spritekiln/goblin_brute/`.
- Test: `_test_brute` w `tests/test_horde.gd`.

## 13.11.2026 - goblin łucznik (drugi rodzaj potwora)

- Ustalone z autorem: goblin łucznik od 2. poziomu lochu, grafika ze SpriteKiln, strzały do unikania.
- `ProtoGoblinArcher` (`scripts/proto/proto_goblin_archer.gd`, podklasa `ProtoGoblin` - ucieczka przed Wodzem, iskry,
  łup, ogłuszenie, rozpychanie bez zmian): 26 zdrowia (goblin 40), 38 px/s, trzyma dystans 65-130 px (za blisko -
  cofa się), strzał co 2,2 s. Naciąganie: na ziemi czerwona przerywana linia celu (`_AimLine`), podąża za postacią,
  0,3 s przed strzałem staje i jaśnieje (`AIM_LOCK`); strzał 0,63 s po początku (zdarzenie `release` animacji).
  Cięcie w trakcie naciągania przerywa strzał.
- `ProtoArrow` (`scripts/proto/proto_arrow.gd`): strzała z kreatora efektów PixelLab (prośba autora): `arrow_fly`
  (pętla 6 klatek 44x16, własny rysunek strzały 20x8 px - grubsze drzewce i czerwone lotki, czytelne na trawie,
  plus smugi pędu; obracana w kierunku lotu) i `arrow_hit` (błysk, iskry, drzazgi; `Fx.once`), wpisy w
  `pixellab_src/vfx/ids.json`; 115 px/s, 11 px nad ziemią z cieniem,
  trafia w promieniu 8 px od stóp postaci (8 obrażeń x siła poziomu), zasięg 240 px.
- `DungeonLevels.archer_share`: od `ARCHER_FROM` = 2 udział 15%, +3% na poziom, sufit 30%; `ProtoHorde.spawn_at(pos, archer)`,
  `ProtoHorde.archers()`, najwyżej `MAX_ARCHERS` = 6 naraz.
- `ProtoGoblin`: liczby i grafika w zmiennych (`scene_path`, `max_hp`, `speed`, `damage`, `attack_cooldown`,
  `strike_time`, `attack_time`), wczytane sceny w `_scenes` (osobno dla każdego rodzaju), ruch w marszu w `_walk_move`.
- Grafika: `art/specs/characters/goblin_archer/goblin_archer.yaml` (na bazie goblina) -> `assets/spritekiln/goblin_archer/`.
- Test: `_test_archer` w `tests/test_horde.gd`.

## 13.11.2026 - kamienie unikalne umiejętności, Mgnienie z odnowieniem

- Pomysł autora: po jednym unikalnym kamieniu na umiejętność, zmieniającym jej działanie. Ustalone: rzadko ze skrzyni
  Wodza (`Gems.CHEST_UNIQUE` 3% -> 8%, od 5. poziomu lochu, losowa umiejętność), zajmuje zwykłe gniazdo, bez stopni,
  pasuje tylko do swojej umiejętności (`Game.skill_socket_problem` -> "skill"). Identyfikator `unique:<umiejętność>`
  (`Gems.UNIQUE`, `is_unique`, `unique_of`, `has_unique`); `is_support` obejmuje też unikalne. Ikony - złote wersje ikon
  kamieni z Watry (`tools/unique_gem_art.py` -> `assets/watra/unique_gems/`). Skrót deweloperski „+kamienie” daje też unikalne.
- Działanie (`ProtoWeapon`, `_unique`): zwykły cios - Wichrowe Ostrze: każde cięcie wypuszcza falę (efekt
  `legend_wind_crescent` z Watry), 140 px, 260 px/s, przebija, 60% obrażeń cięcia (`_spawn_wave`, `_process_waves`);
  Młynek - Wieczny Wir: bez odnowienia, wiruje do drugiego stuknięcia / puszczenia „Atak” (auto atak - do braku wrogów)
  albo końca many, płaci 1/3 kosztu na sekundę (`WHIRL_DRAIN`), z 10. poziomem wybuch co czas odnowienia
  (`_cooldown_base`, min. 1 s); Rzut - Rykoszet: odbija się od trafionego w najbliższego nietrafionego (90 px), do 3 razy,
  widmowe miecze rozchodzą się od miejsca odbicia (`_ricochet`); Rozłupanie - Drżąca Ziemia: wokół każdego trafionego
  (najwyżej 10) fala 34 px, 50% siły, bez kolejnych fal (`_slam_shocks`, efekt `legend_shockwave` z Watry); Mgnienie -
  Nieskończona Mgła: bez limitu skoków i odnowienia (jak wcześniej).
- Zwykłe Mgnienie (decyzja autora): seria do 3 skoków (`Skills.BLINK_JUMPS`), potem 6 s odnowienia; urwana seria
  (0,6 s bez skoku) też włącza odnowienie (`_end_blink_series`).
- Okno: Młynek z kamieniem pokazuje „25 many, potem 8 na sekundę, bez odnowienia”. Testy: `test_gems.gd` (dane, łup,
  gniazda), `test_skills.gd` (`_test_unique`); zrzuty `tools/unique_shots.gd`.

## 13.11.2026 - poziomy umiejętności

- Ustalone z autorem: 10 poziomów, kolejny za złoto przy kamieniu run (przycisk „Ulepsz” w oknie umiejętności, drugie
  stuknięcie potwierdza), najwyżej połowa poziomu postaci w górę (`Skills.level_cap`: poz. 10 umiejętności od
  19. poziomu postaci). Cena z poziomu n na n+1: `Skills.UPGRADE_PRICE` x n (zwykły cios 40, Młynek 60, Rzut 90,
  Rozłupanie 140, Mgnienie 200 zł; razem do 10. poziomu 45 x cena, np. Mgnienie 9000 zł).
- Każdy poziom: +10% obrażeń (`Skills.level_damage`). Poziomy 3 i 7: -10% many i odnowienia (`level_cost`; zwykły cios -
  +10% szybkości), 4 i 8: +10% obszaru i zasięgu (`level_area`). Sumują się z kamieniami (Pośpiech, Oszczędność, Szerokość).
- Nowe działanie na 5. i 10. poziomie (`Skills.PERKS`, `ProtoWeapon._perk`): zwykły cios - co trzeci cios tnie dwa razy
  pełną siłą / cięcie najbliższego wroga poza łukiem (`STRIKE_CLEAVE_RANGE`); Młynek - 4 s zamiast 3 / wybuch na koniec
  z odepchnięciem (`ProtoTarget.push_away`, goblin; bossy i kukły stoją); Rzut - na końcu lotu odbicie w najbliższego
  nietrafionego wroga (`THROW_BOUNCE_RANGE` 90 px) / drugi pełny miecz (pierwszy widmowy miecz); Rozłupanie - ogłuszenie
  2 s zamiast 1,2 / druga fala po 0,5 s (pełna siła, bez ogłuszenia); Mgnienie - pierwszy skok serii za darmo (seria
  kończy się po `FLICKER_SERIES_GAP` 0,6 s bez skoku) / po ostatnim skoku wir wokół postaci (80% siły).
- Stan: `Game.skill_levels` (zapis, `skill_level`, `skill_upgrade_problem`, `upgrade_skill`; postać od nowa zeruje),
  miecz dostaje go w `Arena._apply_skills`. Okno: „poz. X/10” przy nazwie, mana i odnowienie z premią poziomu, progi 5/10
  (złote - odblokowane), „Następny poziom: …”. Testy w `test_skills.gd` (`_test_levels`), zrzut w `tools/skill_shots.gd`.

## 13.11.2026 - postać zawsze na środku ekranu

- Zgłoszenie autora: przy krawędzi mapy kamera stawała, postać zjeżdżała do rogu ekranu i chowała się pod palcem.
  Ustalone (wersja 1 z dwóch): kamera bez granic, za polaną ciemny pas. Las z grafik Watry wokół polany - może później.
- `Arena`: kamera bez `limit_*`; ciemne tło poza polaną poszerzone (`EDGE_PAD` 700 px - więcej niż pół najwyższego
  ekranu), wzdłuż brzegu miękki cień w stronę tła (4 paski z gradientem, `EDGE_SHADE` 28 px). Postać dalej nie wyjdzie
  za brzeg (`ProtoHero.bounds`). Test w `test_base.gd` (postać w rogu polany na środku ekranu).

## 13.11.2026 - ikonki „Postać” i „Umiejętności” w górnym rzędzie

- Pomysł autora: ekwipunek i umiejętności jednym stuknięciem w ikonkę, nie przez „Menu”. Ustalone: dwie ikonki 44 px
  w górnym rzędzie obok „Menu”, w bazie i w lochu (daleko od kciuka - bez przypadkowego otwarcia w walce), przyciski
  usunięte z pauzy.
- `Arena`: `stats_icon` (portret z Watry, `assets/watra/base/character.png`) otwiera `stats_window` (HeroStats),
  `skills_icon` (księga, `skills.png`) - `skills_window` (w bazie z kupowaniem, w lochu bez); `_top_icon`, `open_stats`,
  `open_skills(not horde)`; „wstecz” zamyka oba okna. „Menu” wyrównane do 44 px. HeroStats i SkillsWindow same
  zatrzymują i wznawiają grę. `PauseMenu` bez `stats_button`, `skills_button`, `stats`, `skills_window`.
- Testy (`test_items`, `test_hero_levels`, `test_skills`, `test_gems`) i narzędzia zrzutów otwierają okna z ikonek.

## 13.11.2026 - czytelniejsze okno „Postać” i kamienie

- Zgłoszenie autora: okno „Postać” zbyt rozległe, wkładanie kamieni nieintuicyjne, nie widać, co kamień robi
  w danej umiejętności. Ustalone: zakładki w „Postać”, „najpierw gniazdo”, opisy pod gniazdami, „najpierw kamień”.
  Na razie bez krótszego porównania przedmiotów (punkt niewybrany).
- `scripts/ui/hero_stats.gd`: okno na cały ekran, u góry poziom, doświadczenie i złoto, na dole zakładki
  „Ekwipunek” / „Statystyki” / „Sakwa (N)” i „Wróć” (`set_tab`, `page_equip`, `page_stats`, `page_pouch`).
  Ekwipunek: 6 miejsc wokół postaci, pod nią zdrowie, obrażenia i ochrona (`key_stats`), torba, sprzedaż hurtem,
  auto sprzedaż - na 16:9 bez przewijania. W opisie przedmiotu gniazda z krótkim opisem pod każdym (`socket_labels`);
  sakwa kamieni szlachetnych w opisie i przeciąganie zniknęły - stuknięcie gniazda otwiera GemPicker.
- `scripts/ui/gem_picker.gd` (`GemPicker`): panel wysuwany od dołu. „Najpierw gniazdo” (`open_skill_socket`,
  `open_item_socket`): tylko pasujące kamienie z działaniem w tym miejscu, ten sam rodzaj w innym gnieździe -
  przygaszony z powodem, kamień w gnieździe z „Wyjmij”, „Włóż” / „Wymień”. „Najpierw kamień” (`open_gem`, stuknięcie
  w sakwie): opis i lista miejsc - umiejętności (w pierwsze wolne gniazdo, `Game.free_skill_socket`) albo przedmioty
  (założone, potem torba - `Game.all_items`, `free_item_socket`) z powodem, gdy się nie da; klucz - „Otwórz”
  gniazdo w umiejętności, dłuto - „Dorób” w przedmiocie (oba z potwierdzeniem). Po włożeniu zamyka się (`changed`).
- Okno umiejętności, zakładka „Kamienie”: pod gniazdami krótki opis (`Gems.short_text`, `SHORT`: „Więcej ostrzy”,
  „Piorun 40%”, puste / zamknięte), stuknięcie otwartego gniazda i kamienia w sakwie otwiera GemPicker (przeciąganie
  zostało), przycisk „Wyjmij” w tej zakładce zniknął (jest w GemPicker). `GemSlot`: kropki stopnia (1-5) u dołu ikony.
- Testy: `test_gems.gd` (nowe drogi wkładania, opisy pod gniazdami, zakładki), zrzuty: `tools/gem_shots.gd`
  (nowe pliki `_1b_gniazdo`, `_1c_kamien`, `_2b_statystyki`, `_2c_sakwa`, `_3b_gniazdo`).

## 12.11.2026 - baza: ulepszenia lochów za żar, kowal, kupiec, pasek skrótów

- Ustalenia z autorem (zasady w `docs/GDD.md`, „Baza i waluty”): żar tylko na ulepszenia lochów, złoto na kowala
  (przeróbka jednej wybranej premii) i kupca (towar w ograniczonej liczbie, nowy po każdym pokonanym Wodzu),
  w bazie chodzenie postacią plus pasek ikon. Liczby zaproponowane przez Claude i zatwierdzone przez autora.
- `scripts/dungeon_upgrades.gd` (`DungeonUpgrades`): 4 ulepszenia po 5 stopni za 50/120/250/500/1000 żaru (razem 7680):
  Gęstsza Horda +10% potworów na stopień, Nauka z walki +8% doświadczenia, Hojność Watry +10% szansy na łup,
  Długie ręce +8 px zasięgu zbierania. Stan `Game.upgrades`, `upgrade_steps`, `upgrade_bonus`, `upgrade_price`,
  `buy_upgrade` (sygnał `Game.embers_changed` - licznik pod Watrą, `ProtoWatra.set_embers`).
- Działanie w lochu (`Arena._apply_upgrades`): `ProtoHorde.density` dzieli odstęp między potworami i mnoży ich
  największą liczbę naraz, `loot_mult` mnoży szanse w `Items.roll_goblin`, `Gems.roll_goblin` i `Gems.roll_chest`
  (nowy parametr `chance_mult`), `reach` dodaje piksele do `ProtoEmber.magnet` (40) i `ProtoLoot.magnet` (36);
  doświadczenie w `Arena._gain_xp` (razem z premią z przedmiotów).
- Kowal (`Items.reroll_affix`, `reroll_price`, `Game.reroll`): premia losowana od nowa (rodzaj spośród tych, których
  przedmiot jeszcze nie ma - może wypaść ten sam - i siła z poziomu przedmiotu); cena 2x cena sprzedaży, każda kolejna
  przeróbka 1,5x droższa (licznik `rerolls` w przedmiocie, zapisywany). Okno `scripts/ui/smith_window.gd`: założone
  i torba, opis przedmiotu od dołu z przyciskiem przy każdej premii, nowa premia błyska, dźwięk kowadła z Watry.
- Kupiec (`scripts/shop.gd`, `Shop`; `Game.shop`, `shop_ready`, `shop_offers`, `restock_shop`, `shop_problem`, `buy_offer`):
  Klucz Runiczny 400, Dłuto Jubilera 250, 2 różne kamienie 1. stopnia (Okruch) po 60, 3 przedmioty magiczne lub rzadkie
  (25%) z najwyższego przebitego lochu za 4x cenę sprzedaży. Pierwszy towar przy pierwszym otwarciu, nowa dostawa
  w `Arena.victory`. Okno `scripts/ui/shop_window.gd` (pełna torba - przedmiotu nie kupi, kamienie tak).
- Okna mają wspólny szkielet `scripts/ui/base_window.gd` (`BaseWindow`: panel na cały ekran, waluta w nagłówku,
  przewijana treść, „Wróć”, kupno drugim stuknięciem - `confirm`, `price_button`). Ulepszenia: `scripts/ui/upgrades_window.gd`,
  otwiera je przycisk „Ulepszenia lochów” w wyborze poziomu (`LevelPicker.upgrades`; po zamknięciu wybór wraca).
- W bazie: kowal (postać `smith` z Watry przy kowadle) i wędrowny kupiec (`traveling_merchant` przy straganie
  `stall_goods`) - `ProtoStash` umie arkusz klatek (`frames`, `rows`) i rekwizyt (`prop`, `prop_offset`); kukły
  przesunięte niżej (`Arena.DUMMIES`). Pasek skrótów `scripts/ui/base_bar.gd` (`BaseBar`): pionowa kolumna 5 ikon
  54 px w dolnym rogu po drugiej stronie niż przyciski walki (leworęczni - po prawej): Watra, Skrzynia, Umiejętności,
  Kowal, Kupiec. Grafiki i dźwięk z Watry w `assets/watra/base/`.
- Test `tests/test_base.gd`; zrzuty `SCRIPT=tools/base_shots.gd tools/screenshot.sh <prefiks>`. W `test_horde.gd`
  i `test_hero_levels.gd` przesunięte punkty „pustego miejsca” (teraz stoją tam pasek skrótów i kukła).

## 12.11.2026 - kamienie w umiejętnościach i ekwipunku (rozwój postaci, część 4)

- Ustalenia z autorem: kamienie to łup z lochu (od 3. poziomu lochu - decyzja autora; rzadko gobliny, częściej skrzynia
  Wodza), 5 stopni jak przedmioty (Okruch, Odłamek, Kamień, Szlifowany, Królewski; stopień = `Items.tier_for` poziomu).
  W umiejętności zmieniają działanie (8 rodzajów), w przedmiocie premia zależy od miejsca (4 rodzaje z Watry).
  Umiejętność: 5 gniazd, 2 otwarte, kolejne otwiera rzadki Klucz Runiczny (po jednym na gniazdo; pomysł autora - duża
  nagroda). Przedmiot: 1 gniazdo, bardzo rzadko 2 od razu (magiczny 1%, rzadki 3%), drugie dorabia rzadkie Dłuto Jubilera.
  Osobna sakwa (stosy, bez limitu). Wkładanie stuknięciem (kamień, potem gniazdo) albo przeciąganiem; wyjmowanie za darmo.
- `scripts/gems.gd` (`Gems`): identyfikator „rodzaj:stopień” (klucz `skill_key`, dłuto `chisel`), `SUPPORT` (Mnożenie,
  Szerokość, Żar, Szron, Piorun, Pośpiech, Oszczędność, Krwiopijca - siła na stopniach w `values`, opis według umiejętności
  w `skills`), `JEWELS` (rubin, szafir, szmaragd, onyks; cecha według grupy miejsc broń / strój / biżuteria) i `JEWEL_VALUES`,
  łup `roll_goblin` (1,2% kamień, 0,15% klucz lub dłuto), `roll_chest` (80% + 30% kamień, klucz 4% i dłuto 6%, +0,5 pkt
  za każdy poziom ponad 3., sufit 15% i 20%), `skill_power`. Ikony z Watry: `assets/watra/gems/` (kamienie, gniazdo,
  `rune_ascend` - klucz, `rune_polish` - dłuto) i `assets/watra/supports/`.
- `Game`: `gems` (sakwa), `skill_gems`, `skill_open` (w zapisie), `add_gem`, `gem_list`, `skill_socket_problem`
  (jeden rodzaj raz w umiejętności), `socket_skill` / `unsocket_skill`, `open_skill_socket`, `socket_item` /
  `unsocket_item` / `add_socket` (przedmiot zmieniany w miejscu), sprzedaż oddaje kamienie do sakwy, `dev_gems`
  (skrót „+kamienie” w pauzie), „Od nowa” zeruje.
- `Items`: `sockets` w przedmiocie (stare zapisy dostają jedno gniazdo), premie kamieni w `totals`, `socket_lines`.
- Walka (`ProtoWeapon`): `skill_gems`, każde trafienie przez `_deal` - Żar podpala (% trafienia przez 3 s), Szron spowalnia
  (2 s), Krwiopijca leczy, Piorun przeskakuje na 2 wrogów do 70 px (raz na klatkę), Oszczędność w zwykłym ciosie oddaje manę;
  `mana_cost`, `cooldown_full` (przyciski walki pokazują odnowienie z Pośpiechem), `_area` (Szerokość); Mnożenie: drugie
  cięcie zwykłego ciosu, widmowy miecz w Młynku, 3 miecze wachlarzem w Rzucie (`_ghosts`), druga fala Rozłupania,
  dodatkowe cięcie przy skoku Mgnienia. `ProtoTarget`: `burn`, `slow`, `speed_factor`, `burn_tick` (gobliny bez odrzutu),
  węzeł `_Status` rysuje płomyki i szronowy krąg. `ProtoHero.heal`, `add_mana`.
- Łup na ziemi: `ProtoLoot` z `{"gem": id}` (zawsze do sakwy, `name_of` / `color_of` / `icon_of`), gobliny (`ProtoHorde`)
  i skrzynia Wodza (arena dokłada `Gems.roll_chest`).
- Interfejs: `scripts/ui/gem_slot.gd` (`GemSlot` - okrągłe pole 44+ px, liczba sztuk, kłódka z kluczem, przeciąganie);
  okno umiejętności - zakładki „Miejsca” / „Kamienie” (gniazda wybranej umiejętności, sakwa, „Wyjmij”, klucz - drugie
  stuknięcie potwierdza, małe ikony kamieni w wierszach); okno „Postać” - sakwa pod torbą (stuknięcie - opis), w opisie
  przedmiotu gniazda, kamienie szlachetne i „Dłuto” (drugie stuknięcie potwierdza).
- Test `tests/test_gems.gd`, zrzuty `tools/gem_shots.gd`.

## 12.11.2026 - umiejętności miecza w odblokowanych miejscach

- Ustalenia z autorem: 4 umiejętności - Młynek, Rzut mieczem, Rozłupanie Ziemi, Mgnienie; kupowane za złoto w bazie
  przy nowym obiekcie (kamień run), stała cena i wymagany poziom (100 zł / poz. 3, 300 / 6, 800 / 10, 1500 / 15);
  rytm średni (15-25 many, odnowienie 4-8 s, mana +3/s). Mgnienie na prośbę autora działa jak w Watrze (niżej). Pomysł autora: zwykły cios też jest umiejętnością - można
  go przestawić, a pod duży przycisk dać inną; ta podlega auto atakowi. Przy braku many albo w czasie odnowienia
  duży przycisk tnie zwykłym ciosem (zgoda autora). Mgnienie nie może stać pod dużym przyciskiem (auto atak wrzucałby
  postać w hordę). Przypisywanie w oknie umiejętności stuknięciem albo przeciąganiem.
- `scripts/skills.gd` (`Skills`): dane (`DATA` - nazwa, ikona, mana, odnowienie, cena, poziom, `main`, `range` dla
  auto ataku, `power` - mnożnik cięcia), `ORDER`, `SLOTS` (0 - duży przycisk), `can_be_main`, `open_slots`.
- `Game`: `skills_owned`, `skill_slots` (w zapisie), `can_buy_skill`, `buy_skill` (wstawia w pierwsze wolne małe
  miejsce), `slot_open`, `assign_skill` (zamiana miejsc; to, co nie może stać pod „Atak”, zostawia go pustym),
  `clear_skill_slot`, `main_skill` (pusty „Atak” = zwykły cios), `dev_skills`, sygnał `skills_changed`; „Od nowa” zeruje.
- `ProtoHero`: odnawianie many (`HeroLevels.MANA_REGEN` = 3/s), `spend_mana`, `teleport` (skok Mgnienia: gasnący
  cień w miejscu startu, 0,15 s nietykalności, lądowanie w granicach areny i poza przeszkodami).
- `ProtoWeapon`: `cast` (mały przycisk; w trakcie innego ruchu - kolejka), `main_skill`, `can_use`, `cooldown_left`,
  sygnały `cast_failed`, `skill_used`. Młynek: 3 s wiru (2,2 obrotu/s), co 0,3 s 0,6 cięcia w promieniu 48 px,
  efekt `whirl` z Watry. Rzut: lot 130 px (300 px/s) i powrót (340 px/s), 1,5 cięcia raz w każdą stronę. Rozłupanie:
  wzlot nad cel (do 70 px), spadek, fala 46 px (spłaszczona) 2,2 cięcia i ogłuszenie 1,2 s, efekt `ground_slam`
  z Watry, drżenie kamery. Mgnienie jak w Watrze: dopóki palec trzyma przycisk (`flicker_held`; samo stuknięcie -
  jeden skok), co 0,32 s skok na wylot przez najbliższego wroga w zasięgu 150 px (poprzedni cel tylko, gdy nie ma
  innego), lądowanie 18 px za nim, 1,2 cięcia w pasie wzdłuż drogi i w promieniu 30 px od celu, 7 many za skok,
  bez odnowienia, bez wroga - drgnięcie przycisku; efekty `flicker_trail` i `flicker_hit` z Watry.
  `ActionCluster.release_all` puszcza też małe przyciski (pauza, okna, śmierć). Efekty: `pixellab_src/vfx/` + `ids.json` (z Watry) -> `python tools/vfx_art.py`.
- `ProtoTarget.stun` (domyślnie nic - Wódz i kukły), `ProtoGoblin.stun` (stoi, nie atakuje, szarzeje).
- Przyciski walki: `ActionCluster.show_skills` (ikony z miejsc), `button(slot)`; `ActionButton.set_state` (ciemny
  wycinek z sekundami odnowienia, niebieska ikona przy braku many), `deny` (drgnięcie). Arena: `_apply_skills`,
  `_on_skill_pressed`, `_update_skill_buttons`.
- Kamień run w bazie po drugiej stronie Watry (`Arena.RUNE_POS`, `ProtoStash` z `texture`/`title`/`sprite_scale`;
  grafika `assets/watra/rune_stone.png` z Watry) otwiera okno umiejętności z kupnem.
- `scripts/ui/skills_window.gd` (`SkillsWindow`): przewijana lista (ikona, mana i odnowienie, opis, cena/poziom,
  „Kup” z „Na pewno?”), na dole rząd miejsc „Atak” + 1-4 (zablokowane z poziomem), „Zdejmij”, „Wróć”; stuknij
  umiejętność, potem miejsce, albo przeciągnij (`scripts/ui/skill_slot.gd`, `SkillSlot`); z miejsca na listę - zdjęcie.
  Z pauzy („Umiejętności”) w lochu bez kupowania. Ikony z Watry: `assets/watra/skills/` (whirlwind, lunge, ground_slam, flicker).
- Pauza: „Auto atak (duży przycisk)”, skrót deweloperski „+umiejętności” (drugi rząd skrótów).
- Test `tests/test_skills.gd`, zrzuty `tools/skill_shots.gd`.

## 12.11.2026 - skrzynia w bazie z zakładkami za złoto

- Prośba autora; ustalone: 1 zakładka 20 miejsc na start, kolejne za 100, 300, 800, 2000 złota (razem 5),
  przenoszenie stuknięciem z przyciskiem albo przeciąganiem.
- `Game`: `stash` (lista zakładek), `STASH_TAB_SIZE`, `STASH_TAB_PRICES`, `next_tab_price`, `buy_stash_tab`,
  `to_stash`, `from_stash`, `stash_all`; w zapisie; „Od nowa” czyści skrzynię.
- `scripts/proto/proto_stash.gd` (`ProtoStash`): skrzynia z Watry obok Watry (`Arena.STASH_POS`), otwiera okno
  stuknięciem albo podejściem (ponownie dopiero po odejściu), przeszkoda dla postaci.
- `scripts/ui/stash_window.gd` (`StashWindow`): zakładki 1..N (44 px) i „+ zakładka N” (drugie stuknięcie „Kupić za N?”),
  siatka zakładki 5x4 i torba 5x4 (pola 48 px), opis przedmiotu z „Do skrzyni” / „Do torby”, „Wszystko do skrzyni”,
  „Wróć”; zatrzymuje grę, „wstecz” zamyka najpierw opis. `scripts/ui/item_slot.gd` (`ItemSlot`): pole z przeciąganiem
  (drag and drop Godota, palec przez emulację myszy) na drugą siatkę.
- Test `tests/test_stash.gd`, zrzuty `tools/stash_shots.gd`.

## 12.11.2026 - usprawnienia: pasek żaru, powiadomienia o łupie, sprzedaż hurtem, „Na pewno?” przy wyjściu

- Prośby autora. Pasek żaru pogrubiony do 11 px z liczbami „zebrane / 100” (`Arena.ember_text`).
- Powiadomienia o łupie pod paskami u góry (`Arena.notify_loot`, `loot_feed`): ikona i napis w kolorze rzadkości
  („Podniesiono: …”, „Sprzedano: … (+N złota)”, „Torba pełna - sprzedano: …”), najwyżej 4 naraz, gasną po 2,5 s.
- Okno „Postać”: pod torbą „Sprzedaj zwykłe” i „Sprzedaj magiczne i rzadkie” - pierwsze stuknięcie pokazuje
  „Na pewno? +N złota”, drugie sprzedaje (`Game.sell_all`, `sell_all_price`); przełącznik „Sprzedawaj zwykłe od razu
  po podniesieniu” (`Game.auto_sell_common`, `settings.cfg` sekcja `items`; `ProtoLoot` -> `Game.sell_loot`).
  Sygnał `ProtoLoot.sold` ma teraz `bag_full`; okno wyniku: „Łup sprzedany od razu: +N złota”.
- Pauza w lochu: „Uciekaj do bazy” i „Menu główne” pytają „Na pewno?” (`PauseMenu._leave`, ponowne otwarcie
  pauzy kasuje pytanie). Skrót deweloperski przemianowany na „+5 łupu” (nie mieścił się).

## 12.11.2026 - przedmioty: procenty rosną płynnie z lochem

- Decyzja autora (wariant A): premie procentowe i stała cecha butów i pierścienia rosły skokami co stopień
  (co 4 lochy) i stawały od lochu 17. Teraz rosną z każdym poziomem lochu (`Items.AFFIXES[...].per_level`):
  obrażenia +0,6, szybkość ataku +0,4, ruch +0,2, ochrona +0,2, doświadczenie +0,4 na poziom; buty i pierścień
  +0,2 (`BASE_PCT_PER_LEVEL`). Liczby stałe bez zmian (x `DungeonLevels.power`), sufity sumy (`CAPS`) zostają.

## 12.11.2026 - przedmioty (rozwój postaci, część 2)

- Ustalenia z autorem: 6 miejsc (broń, hełm, zbroja, buty, pierścień, amulet), łup ze skrzyni Wodza i rzadko
  z goblinów, 3 rzadkości z 1-4 premiami, okno ekwipunku razem z oknem „Postać”, torba 20 miejsc, siła przedmiotu
  z poziomu lochu, niepotrzebne sprzedaje się za złoto (nowa waluta), skrót deweloperski „+5 przedm.”.
- `scripts/items.gd` (`Items`): dane i losowanie. Stopień (wygląd i nazwa z Watry: żelazny, stalowy, mithrilowy,
  runiczny, smoczy) co 4 poziomy lochu (`tier_for`). Stała cecha miejsca (`BASE`): broń - obrażenia cięcia 15-21
  (+12% na poziom lochu, ±8%; zastępują zwykły miecz 14-20), hełm +8 i zbroja +18 zdrowia (x `DungeonLevels.power`),
  buty +4% ruchu, pierścień +4% obrażeń (+1 na stopień), amulet +10 many. Premie (`AFFIXES`, bez powtórzeń): zdrowie,
  mana, % obrażeń, % szybkości ataku, % szybkości ruchu, regeneracja zdrowia, % ochrony, % doświadczenia; sufity sumy
  (`CAPS`): ochrona 50%, ruch 50%, szybkość ataku 75%. Rzadkości: zwykły 0, magiczny 1-2, rzadki 3-4 premie; wagi
  goblina 65/28/7, skrzyni 35/45/20. Goblin upuszcza przedmiot z szansą 2,5% (`GOBLIN_DROP`), skrzynia Wodza 3
  (`roll_chest`, pierwszy co najmniej magiczny). Cena: 5 złota x siła lochu x rzadkość (1/2/4). Zapis trzyma tylko
  identyfikatory i liczby (`normalize` przy wczytaniu). `totals` - suma cech założonych.
- `Game`: `bag` (najwyżej `BAG_SIZE` 20), `equipped`, `gold` w zapisie; `add_item`, `equip` (zamiana - stary wraca
  na jego miejsce w torbie), `unequip`, `sell`, `dev_items`, `gear()`, sygnał `inventory_changed`; „Od nowa” czyści też
  przedmioty i złoto. Przedmioty zostają po śmierci i ucieczce (jak doświadczenie).
- `scripts/proto/proto_loot.gd` (`ProtoLoot`): przedmiot na ziemi - ikona, poświata w kolorze rzadkości, rzadki ze
  słupem światła; leci do postaci z 36 px, przy pełnej torbie odskakuje z napisem „Torba pełna!” i czeka, aż postać
  odejdzie. Łup ze skrzyni przy pełnej torbie sprzedaje się od razu (`sell_if_full`). Dźwięki z Watry (Kenney, CC0):
  `dropLeather`, `handleSmallLeather`, `glass_002` (rzadki), `handleCoins` (sprzedaż).
- Działanie cech: `ProtoHero.apply_gear` (zdrowie, mana, `move_mult`, `regen`, `protection`; zmiana ekwipunku nie
  leczy), `ProtoWeapon.damage` i `speed_mult` (cały cios szybszy), doświadczenie x premia w `Arena._gain_xp`; arena
  słucha `Game.inventory_changed`. Okno wyniku: „Przedmioty: N” (`RunResult.add_loot_lines`).
- `HeroStats` (okno „Postać i ekwipunek” w pauzie): poziom, 6 miejsc wokół Wojciecha (po lewej hełm, zbroja, buty,
  po prawej broń, amulet, pierścień), złoto, statystyki z przedmiotami (ochrona, regeneracja, doświadczenie tylko gdy
  niezerowe), torba 5x4 (pola 52 px). Opis przedmiotu przy dolnej krawędzi: cechy, „Po założeniu:” zmiany statystyk
  (zielone/czerwone), „Załóż”/„Zdejmij”, „Sprzedaj N” (magiczny i rzadki - „Na pewno?”), „Zamknij”; „wstecz” zamyka
  najpierw opis. Okno przewija się na 16:9. Ikony: `assets/watra/items/` (z Watry, z wersjami `_magic`, `_rare`).
- Test `tests/test_items.gd`, zrzuty `tools/item_shots.gd`.

## 12.11.2026 - liczby na paskach, mana i okno „Postać”

- Prośba autora: liczby na paskach zdrowia, many i doświadczenia oraz ekran statystyk („ciężko stwierdzić, co daje poziom”).
- Pusty pasek między zdrowiem a doświadczeniem to teraz **pasek many** (niebieski, 11 px, `Arena.mana_bar`). Mana:
  `HeroLevels.max_mana` = 50 + 5 na poziom, `ProtoHero.max_mana`/`mana`, sygnał `mana_changed`; na razie nic jej nie
  zużywa (czeka na umiejętności), awans napełnia ją do pełna.
- Liczby „obecne / największe” na środku pasków (`Arena._bar_text`, `health_text`, `mana_text`, `xp_text`; na
  najwyższym poziomie „Najwyższy poziom”). Pasek doświadczenia pogrubiony do 11 px.
- `scripts/ui/hero_stats.gd` (`HeroStats`): okno „Postać” pod przyciskiem w oknie pauzy (w lochu i w bazie) - poziom,
  doświadczenie, zdrowie, mana, obrażenia miecza (`damage_range`), szybkość ataku (`attacks_per_second` = 1 / (rozbieg
  + cięcie + powrót + odpoczynek) = 1,08/s), szybkość ruchu, miejsca na umiejętności; w zielonej kolumnie przyrost
  z następnym poziomem (+10 zdrowia, +5 many, +6% obrażeń, „na poz. 6”). „Wstecz” Androida najpierw zamyka to okno
  (`PauseMenu.back`).

## 12.11.2026 - rozwój postaci: poziomy doświadczenia, auto atak, skróty deweloperskie

- Ustalenia z autorem: zaczynamy od poziomów (przedmioty w kolejnej sesji); doświadczenie za każdego goblina i dużo
  za Wodza, śmierć go nie zabiera; awans daje statystyki (zdrowie, obrażenia, pełne leczenie) i odblokowuje miejsca
  na umiejętności; cienki pasek u góry, efekt awansu, podsumowanie w oknie wyniku; skróty deweloperskie w pauzie;
  auto atak w menu (prośba autora - tylko podstawowy cios).
- `scripts/hero_levels.gd` (`HeroLevels`): `xp_to_next(n)` = 50 * n^1,4 (50, 132, 233, 350, 476 … 1256 na 10.),
  `max_hp` = 100 + 10 na poziom, `damage_mult` = 1 + 0,06 na poziom, miejsca na umiejętności na poziomach 3, 6, 10, 15
  (`SKILL_SLOT_LEVELS`), `goblin_xp` = 2 x siła lochu, `chief_xp` = 60 x siła lochu (`DungeonLevels.power`), sufit 50.
- `Game`: `hero_level`, `hero_xp` w zapisie, `add_xp` (kilka awansów naraz, zwraca liczbę awansów), sygnały
  `xp_changed` i `leveled_up`; awans zapisuje od razu, zwykłe doświadczenie przy `save_if_dirty` (pauza, koniec wyprawy,
  zmiana sceny, przełączenie aplikacji - `Game._notification`). Ustawienie `auto_attack` (`settings.cfg`).
  Tryb deweloperski: `dev_level_up`, `reset_hero`.
- `ProtoHero`: `max_hp` z poziomu (`set_level`), `level_up` - pełne zdrowie, złoty błysk, słup światła z kręgiem
  (`_LevelGlow`, rysowany w kodzie), napis „Poziom N!”, dźwięk `assets/watra/level_up.ogg` (Kenney `jingles_PIZZI16`
  z Watry, CC0), wibracja 60 ms.
- `ProtoWeapon`: `damage_mult` (obrażenia x poziom), `auto_attack` - cios rusza sam, gdy cel jest w zasięgu `REACH`
  (`_nearest`); bez celu miecz czeka.
- Arena: wiersz „Poz. N” + złoty pasek doświadczenia 5 px (prośba autora, wcześniej niebieski) (`_make_xp_row`) - w lochu pod paskiem zdrowia, w bazie
  obok „Menu”; w lochu między zdrowiem a doświadczeniem pusty pasek 6 px na później (`spare_bar`, prośba autora); poziom lochu w pasku to teraz „Loch N”. Doświadczenie z goblinów (`kills_changed`) i Wodza
  (`_on_chief_died`), `run_xp` do podsumowania. `RunResult.add_xp_lines`: „Doświadczenie: +N”, „Awans na poziom N!”.
- `ActionButton.locked_level`: kłódka i „Poz. N” na zablokowanym miejscu, `unlock_flash` przy odblokowaniu
  (`ActionCluster.set_hero_level`).
- Okno pauzy: przełącznik „Auto atak (podstawowy cios)”, rząd skrótów deweloperskich „+1 poz.”, „+100 żaru” (w lochu
  do paska wyprawy - szybkie przyzwanie Wodza, w bazie do Watry - sygnał `dev_embers`), „Od nowa” (drugie stuknięcie
  „Na pewno?”). Okno przewija się, gdy nie mieści się na ekranie (`_fit`).
- Test `tests/test_hero_levels.gd`, zrzuty `tools/level_shots.gd`.

## 12.11.2026 - tryb deweloperski: nieśmiertelność

- Prośba autora (Wódz jest „trudnawy”, do testów balansu): w oknie pauzy przełącznik „Tryb deweloperski:
  nieśmiertelność” (`PauseMenu.immortal_toggle`, `Game.dev_immortal`, zapis w `user://settings.cfg`, sekcja `dev`).
- `ProtoHero.immortal`: zdrowie schodzi normalnie, a zamiast śmierci wraca do pełna ze złotym błyskiem; `deaths` liczy
  uniknięte zgony (`death_avoided`). W lochu czerwony licznik „Zgony: N” pod paskiem (widoczny tylko w trybie
  deweloperskim), okno zwycięstwa pokazuje „Zgony (nieśmiertelność): N”.
- Test w `tests/test_horde.gd`.

## 12.11.2026 - Wódz Goblinów, koniec wyprawy i poziomy lochu

- Ustalenia z autorem: pasek żaru 100 (`DungeonLevels.SUMMON_COST`), przyzwanie przyciskiem przy pełnym pasku, gobliny
  uciekają z piskiem, Wódz Goblinów (duży, w trofeach) z trzema atakami z ostrzeżeniem: cios w ziemię, okrzyk wojenny,
  rzut tasakiem; nagroda - skrzynia (na razie żar, potem łup); okno zwycięstwa; pokonanie bossa odblokowuje następny
  poziom, wybór poziomu przy Watrze (do najwyższego odblokowanego). Ucieczka i śmierć gaszą żar (zgodnie z GDD) - przycisk
  „Do bazy” w lochu usunięty, w pauzie „Uciekaj do bazy” z ostrzeżeniem (`PauseMenu.leave_note`).
- `scripts/dungeon_levels.gd` (`DungeonLevels`): `power(level)` = 1 + 0,15 na poziom (zdrowie i obrażenia goblinów i Wodza),
  `chest_embers(level)` = 20 + 10 na poziom. `Game`: `best_level` (najwyższy przebity), `dungeon_level` (wybrany),
  `unlocked_level()`, `beat_level()`; oba w zapisie.
- Arena w lochu: pasek żaru pod paskiem zdrowia (pulsuje, gdy pełny), „Poz. N” w pasku, przycisk „Przyzwij Wodza” (`summon_chief`;
  po ocenie na telefonie przeniesiony na górę pod pasek żaru - prośba autora, żeby nie przyzwać go przypadkiem): zjada 100 żaru (nadwyżka zostaje w liczniku), `ProtoHorde.call_boss` (strumień staje,
  `scatter` - gobliny `flee`: biegną od postaci 120 px/s, gasną po 1,4 s, piszczy najwyżej 6 - `tools/goblin_squeak.py`
  -> `assets/sounds/goblin_squeak_*.ogg`), Wódz 110 px nad postacią, pasek zdrowia Wodza pod górnym rzędem.
  Etapy `phase`: horde, boss, loot, won. Ziemia ma `z_index` -10 (ciała i ostrzeżenia na -1 były pod trawą).
- `proto_chief.gd` (`ProtoChief`): 700 zdrowia x siła (ok. 25 s cięcia), prędkość 30, wejście z rykiem i wstrząsem kamery
  (1,4 s nietykalności). Ataki co 1,1 s: cios w ziemię z bliska (koło 46 px, 1,1 s ostrzeżenia, 25 obrażeń), rzut tasakiem
  z daleka (koło 20 px pod postacią, 1 s, 20 obrażeń, powrót jak bumerang - 10), okrzyk co 9 s (fale, po 0,9 s 5 goblinów
  wokół przez `ProtoHorde.spawn_at` - dają iskry). Animacje modelu: `slam`, `throw`, `roar` (cios w `ANIM_HIT_AT`), do czasu
  modelu zastępczy goblin x1,6, czerwonawy (`ANIM_FALLBACK`). Dźwięki z Watry: `chief_roar` (horde_roar), `chief_slam`,
  `cleaver_land` (Kenney CC0).
- `proto_telegraph.gd` (`ProtoTelegraph`): czerwone koło z Watry (`telegraph.gd`), spłaszczone 0,6. `proto_cleaver.gd` -
  tasak rysowany w kodzie ze smugą `cleaver_spin`.
- Model Wodza w SpriteKiln (zatwierdzony przez autora): `art/specs/characters/goblin_chief/goblin_chief.yaml` (extends
  goblina, kość `big` x1,6, ok. 42 px + rogi, klatka 80; czaszka z rogami, farba wojenna, futrzana narzuta, kły, wielki
  tasak). Animacje: idle 1200 ms, walk 1000 ms (30 px/s = `ProtoChief.SPEED`), slam 920 ms (`hit` 400), throw 580 ms
  (`release` 300, kanał `knife_show` chowa tasak po rzucie), roar 1160 ms (`roar` 270), hit 210 ms, death 1490 ms.
  Eksport: `assets/spritekiln/goblin_chief/`.
- Efekty (ustalenie autora - z Watry, czego brak - w kreatorze PixelLab): z Watry `boss_appear` (wejście), `boss_slam`
  (cios), `boss_death` (śmierć), `chief_roar` (ryk Biesa przebarwiony - `vfx_art.py` umie teraz `source`, `hue`, `boost`);
  nowe w kreatorze: `cleaver_spin` (smuga wirującego tasaka, pętla) i `cleaver_impact` (iskry, kurz, odłamki przy upadku).
  `Fx.once` ma skalę `size`.
- `proto_chest.gd` (`ProtoChest`): skrzynia z Watry (`assets/watra/chest.png`) spada 1,4 s po śmierci Wodza, otwiera się
  z bliska (22 px) albo stuknięciem, sypie iskry (duże po 5), które po 0,5 s same lecą do postaci (`ProtoEmber.magnet`,
  `spread`, `delay`). Po 2,2 s `victory()`: `_bank` (cały żar z wyprawy), `Game.beat_level`, `RunResult.show_victory`
  („Następny poziom: N” / „Powrót do bazy”).
- `scripts/ui/level_picker.gd` (`LevelPicker`): dotknięcie Watry - ◀ Poziom N ▶, siła potworów, skrzynia Wodza, „Wejdź” /
  „Anuluj” w dolnej części, pauza; „wstecz” zamyka.
- Test `tests/test_horde.gd` (`_test_chief` i wybór poziomu), zrzuty `SCRIPT=tools/boss_shots.gd tools/screenshot.sh <prefiks>`.

## 12.11.2026 - iskry żaru dla Watry

- Ustalenia z autorem: iskry przyciągane z bliska, po śmierci przepadają (do Watry tylko przy powrocie), żar na razie
  tylko liczony (na co go wydawać - później), 1 iskra z goblina, co 20. goblin duża (5).
- `scripts/proto/proto_ember.gd` (`ProtoEmber`): wyskok z ciała, migotanie, poświata; od 40 px leci do postaci
  (przyspiesza 400 px/s²), `collected(value)`, brzęk (Kenney `glass_002`/`glass_005` z Watry -> `assets/watra/ember_pickup*.ogg`).
  Grafika z `tools/ember_art.py` -> `assets/effects/ember.png` (rząd 0 mała 1 żaru, rząd 1 duża 5, po 4 klatki 13x13).
- `ProtoHorde`: `embers`, `embers_changed`, `BIG_EVERY = 20`. Arena w lochu: ikona żaru (`assets/watra/ember_icon.png`
  z Watry) i licznik w pasku, przycisk „Do bazy” w górnym rzędzie (`return_to_base`); wyjście z okna pauzy też zanosi
  żar (`PauseMenu.leaving`). Śmierć: okno wyniku pokazuje „Zgasło żaru: N”.
- `Game`: zapis gry `save_path` (JSON `{"embers": N}`), `load_game`, `save_game`, `bank_embers` (zapis od razu),
  `embers_brought` - baza pokazuje „+N” nad Watrą z rozbłyskiem. `ProtoWatra`: „Żar Watry: N” pod ogniem, poświata
  rośnie logarytmicznie do 1,6x przy 1000 żaru (`glow_size`).
- Test `tests/test_horde.gd` (żar: wypadanie, przyciąganie, duża iskra, powrót, zapis, gaśnięcie po śmierci).

## 12.11.2026 - pierwszy potwór (goblin) i loch z Hordą

- Ustalenia z autorem: goblin, ciągły strumień, średnie obrażenia; polana z kukłami to baza, wejście do lochu przez
  dotknięcie Watry; po śmierci wynik i przyciski „Jeszcze raz” / „Powrót do bazy”.
- Goblin w SpriteKiln: `art/specs/characters/goblin/goblin.yaml` (dziedziczy po humanoidzie; ok. 27 px, głowa x1.4,
  długie uszy `ear_L/R`, skóra oliwkowa z chłodnymi cieniami, świecące bursztynowe oczy, tunika, tasak `knife` na
  `wrist_R`, sockety `knife_hit`/`knife_tip`). Animacje: idle 6x150 ms, walk 8x90 ms (ziemia 42 px/s = `ProtoGoblin.SPEED`
  - zmiana prędkości w grze wymaga zmiany chodu, inaczej stopy się ślizgają), attack 560 ms (`windup` 0 ms, `hit` po
  300 ms, pionowa smuga przez kość `fxspace`), hit 3x70 ms, death 1280 ms (pada na plecy). QA bez błędów.
  Eksport: `assets/spritekiln/goblin/` (scena `goblin.tscn` z `KilnSprite2D`), dodatek `addons/spritekiln` (bez
  włączania wtyczki w project.godot - skrypt działa sam).
- `scripts/proto/proto_target.gd` (`ProtoTarget`): wspólna baza celów miecza (`center`, `alive`, `take_damage`,
  `spawn_number`); `ProtoDummy` i `ProtoGoblin` po niej dziedziczą. Miecz (`ProtoWeapon._live_targets`) bije listę
  `targets` i grupę `ProtoWeapon.TARGETS` (potwory dopisują się same), pomija martwe.
- `proto_goblin.gd`: 40 zdrowia (2-3 cięcia), prędkość 42 (Wojciech 70), zamach z 15 px, cios trafia do 22 px
  (zdarzenie `hit` animacji - da się odskoczyć), 10 obrażeń co 1 s, rozpychanie w tłumie (`_separation`), odrzut,
  trafienie przerywa zamach; śmierć: animacja, 1,2 s ciała, zanikanie.
- `proto_horde.gd` (`ProtoHorde`): ciągły strumień - odstęp 1,3 -> 0,3 s i 8 -> 45 goblinów naraz w ciągu 180 s;
  pojawiają się tuż poza kadrem (`spawn_point`), liczy `kills` i `time`.
- `proto_hero.gd`: 100 zdrowia, `take_damage` (czerwony błysk, liczba, wibracja, 0,35 s nietykalności), `died`,
  przewrócenie się (Wojciech z Watry nie ma animacji śmierci), `obstacles` (okręgi spłaszczone w pionie).
- `proto_watra.gd` (`ProtoWatra`): Watra z Watry (`assets/watra/watra.png`, 6 klatek, 7 kl/s), poświata, iskry, napis
  pod ogniem; dotknięcie (`TAP_RECT`) -> `entered`. Krąg kamieni zatrzymuje postać.
- `arena.gd`: `@export var horde` - baza (`prototype.tscn`: kukły (-100,0), (100,10), (0,170), Watra (0,-115)) albo loch
  (`scenes/horde.tscn`: chłodniejsza trawa, pasek zdrowia, „Pokonane: N”, czas). `scripts/ui/run_result.gd`
  (`RunResult`): okno wyniku po 1,2 s od śmierci (pauza). Okno pauzy w lochu ma „Powrót do bazy” (`PauseMenu.base_scene`).
- Test `tests/test_horde.gd`; wydajność: 45 goblinów nie zmienia czasu klatki w chmurze.

## 12.11.2026 - styl grafiki (wywiad SpriteKiln)

- Odpowiedzi autora zapisane `spritekiln style set` w `spritekiln.toml`: topdown, 36 px (klatka 48, scale 0.04889),
  8 kierunków bez odbicia, paleta `watra`, outline selective, shading soft, lines depth, highlights, bez ditheringu,
  światło classic, proporcje stylized, twarz minimal, animacja fluid; notatki: pasuje do Watry, czytelne na telefonie,
  broń lewituje. Tabela w `docs/ART_SPEC.md`.
- Paleta `art/specs/palettes/watra.yaml`: rampy z `spritekiln palette ramp` dla kolorów z grafik Watry (wood, leather,
  cloth, skin, hair, steel, stone, straw, nawia) + gold, bone, blood, flame, eye, fx z palety gothic.

## 12.11.2026 - aktualizacja w grze bez całego apk

- Autoload `Updater` (`scripts/updater.gd`, pierwszy na liście autoloadów): w `_init` wczytuje `user://update/game.pck`
  (`ProjectSettings.load_resource_pack(..., true)`), jeśli `info.json` ma ten sam `APK_LEVEL` i wyższą kompilację niż
  `res://build_info.json` z apk (inaczej usuwa paczkę). `check()` czyta `version.json` z gałęzi `apk`
  (raw.githubusercontent.com, `?t=` omija pamięć podręczną), `download()` pobiera `game.pck` do `.part`, sprawdza
  SHA-256, zapisuje `info.json`. Stany: checking, up_to_date, available, downloading, ready, need_apk, error.
  Działa tylko w wyeksportowanej grze (`OS.has_feature("template")`) albo z argumentem `--with-updates`.
- Menu: przycisk pod „Graj” („Aktualizuj” / „Zamknij grę” / „Pobierz całą grę” / „Spróbuj ponownie”), postęp
  pobierania w %, wersja z numerem kompilacji. Gra pyta serwer sama przy wejściu do menu.
- Sprawdzone na wyeksportowanej grze (Linux): paczka podmienia sceny, skrypty, autoload `Game` i dodaje nowe klasy
  `class_name`; paczka gry ok. 0,6 MB (apk 28 MB). Nie przenosi project.godot, export_presets.cfg, updater.gd.
- `tools/build_android.sh` wpisuje `build_info.json` (kompilacja = `git rev-list --count HEAD`, commit; w .gitignore,
  w eksporcie przez `include_filter`) i eksportuje też `build/game.pck`; `tools/publish_apk.sh` wrzuca na gałąź `apk`
  apk, `game.pck` i `version.json` (build, commit, apk, size, sha256). Uprawnienie internetu w eksporcie włączone.
- Test `tests/test_updater.gd` (z `-- --with-updates`): mini-serwer HTTP na TCPServer, paczka z PCKPacker.
- Sprawdzone na telefonie autora: kompilacja 15 (pełny apk) -> „Aktualizuj” -> kompilacja 16.

## 12.11.2026 - efekt trafienia, miecz dalej od postaci

- Efekt trafienia z kreatora efektów PixelLab: „Watra Mobile - trafienie miecza” (My effects autora, id
  `c6789000-6891-435e-aa71-9c751f0cfed2`): części `hit_star` (x0.7) i `cooling_sparks` (x0.5), 42x39 px, 12 klatek
  20 fps, zaczepienie (23, 17). Plik `pixellab_src/vfx/sword_hit.png` (siatka 4x3, przezroczysty), wpis `sword_hit`
  w `ids.json`, w grze `assets/effects/sword_hit.png`. Pobieranie z `api.pixellab.ai` działa już w chmurze (curl
  adresu `download` z wyniku eksportu).
- `Fx.once` (`scripts/fx.gd`, jak `SkillEffects.sheet_once` w Watrze): odtwarza arkusz raz i usuwa efekt.
  Miecz odpala trafienie na linii od postaci do kukły, nie dalej niż 80% ostrza.
- `ProtoWeapon.HILT_RADIUS` 8 -> 14 px: miecz krąży dalej od postaci (półksiężyc cięcia skaluje się sam).

## 12.11.2026 - wersja na telefon z chmury

- `tools/build_android.sh`: buduje `build/WatraMobile.apk` (eksport „Android - testy”, arm64, ok. 28 MB). Doinstalowuje
  szablony Androida Godota 4.7.2 (`tools/android/remote_unzip.py` wyciąga z archiwum .tpz tylko 3 pliki zapytaniami
  o fragmenty) i Android SDK build-tools 35 w `/opt/android-sdk`, wpisuje ścieżki do ustawień edytora.
  Podpis: stały klucz testowy `tools/android/debug.keystore` (zmienne `GODOT_ANDROID_KEYSTORE_DEBUG_*`),
  więc kolejne wersje instalują się na poprzednich.

## 12.11.2026 - prototyp walki: lewitujący miecz i kukły

- „Graj” w menu otwiera `scenes/prototype.tscn` (`scripts/proto/arena.gd`, wszystko budowane w kodzie): polana
  720x1120 z trawy Watry, kamera z granicami, trzy kukły, przyciski „Menu” i „Gest: wł./wył.”, podpowiedź pod nimi.
- Grafiki i dźwięki z Watry w `assets/watra/`: Wojciech (`wojciech.png`, arkusz 8 kolumn, wiersz = animacja * 5 + kierunek,
  komórka 54 px, stopy na 46 px), kukła, żelazny miecz (chwyt 9.5,10, czubek 61,9, skala 0.5), trawa, 4 dźwięki trafienia kukły.
- `Joystick` (`scripts/ui/joystick.gd`): pływająca gałka - dotyk w dowolnym wolnym miejscu, promień 28 px, martwa strefa 15%,
  podąża za palcem; zdarzenia myszy (telefon zamienia dotyk na mysz), leży pod przyciskami.
- `ProtoHero`: chód 70 px/s, animacje idle/walk/slash z arkusza, 8 kierunków (zachód odbity). Gest = animacja `slash`
  z pustą dłonią, tylko w miejscu (w marszu postać tylko idzie).
- `ProtoWeapon`: miecz unosi się 22 px nad ziemią za ramieniem postaci (doganianie z opóźnieniem, kołysanie).
  Cios (przy trzymanym przycisku ataku) jak zwykły atak w Watrze: miecz wskakuje na orbitę wokół postaci
  (środek 12 px nad stopami, rękojeść 8 px od środka, ostrze 26 px na zewnątrz) i tnie łukiem 160° w stronę celu,
  kolejne cięcia na przemian z góry i z dołu (rozbieg 0,12 s, cięcie 0,18 s z `ease(progress, 0.5)`, trafienie
  w połowie - wszystkie kukły w łuku, 14-20 obrażeń, wibracja 15 ms, odpoczynek 0,55 s). Nad łukiem efekt cięcia
  ze zwykłego ataku Watry: `assets/effects/sword_slash.png` (kreator efektów PixelLab, `pixellab_src/vfx/ids.json`,
  5 klatek 64 px, skala = zasięg czubka / 29 px, `flip_v` przy cięciu od dołu).
- Przycisk ataku i miejsca na umiejętności (`scripts/ui/action_cluster.gd`, `action_button.gd`): prawy dolny róg,
  atak - kółko 64 px z ikoną żelaznego miecza z Watry (`assets/watra/iron_sword_icon.png`), wokół niego na łuku
  (promień 96 px, kąty 180-270°) 4 puste miejsca 44 px. Miecz tnie tylko, gdy przycisk jest trzymany - w stronę
  najbliższej kukły w promieniu 48 px, bez kukły przed siebie.
- Sterowanie wieloma palcami: gałka i przyciski akcji czytają `InputEventScreenTouch`/`ScreenDrag` z numerem palca
  (można iść i trzymać atak naraz); gałka nie startuje na przyciskach (`Joystick.blocked`). W testach
  `root.push_input(e, true)` - pozycje w pikselach gry.
- Okno pauzy (`scripts/ui/pause_menu.gd`, przycisk „Menu” w lewym górnym rogu; też przycisk „wstecz” Androida
  i przełączenie aplikacji): zatrzymuje grę (`get_tree().paused`), przełączniki „Atak i umiejętności po lewej”
  i „Gest postaci przy ataku” (wcześniej osobny przycisk na ekranie), „Wróć do gry”, „Menu główne”. Ustawienia
  w `Game` (`left_handed`, `gesture`) zapisane w `user://settings.cfg` (testy: `user://test_settings.cfg`).
  `ActionCluster.left_handed` odbija układ do lewego rogu (umiejętności na łuku od prawej do góry).
  `application/config/quit_on_go_back=false` - „wstecz” nie zamyka gry.
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

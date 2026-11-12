# Watra Mobile - historia zmian

Szczegóły zrobionych punktów: pliki, funkcje, liczby. Przeszukuj grepem, nie czytaj w całości.

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

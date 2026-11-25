class_name Gems
## Kamienie (rozwój postaci, część 4 - ustalone z autorem 12.11.2026). Dwa rodzaje kamieni, oba z łupu w lochu
## (od poziomu lochu MIN_LEVEL; rzadko z goblinów, częściej ze skrzyni Wodza):
## - kamienie umiejętności (SUPPORT, 8 rodzajów) - włożone w umiejętność zmieniają jej działanie (więcej ostrzy,
##   większy obszar, podpalenie, spowolnienie, piorun, krótsze odnowienie, mniej many, leczenie z obrażeń); każda
##   umiejętność ma 5 gniazd, otwarte 2 (SKILL_OPEN), kolejne otwiera rzadki Klucz Runiczny (KEY) - po jednym na gniazdo;
##   jeden rodzaj kamienia najwyżej raz w umiejętności; działanie - ProtoWeapon (`Gems.skill_power`);
## - kamienie szlachetne (JEWELS: rubin, szafir, szmaragd, onyks) - włożone w przedmiot dają swoje premie (2-5,
##   te same w każdym miejscu); przedmiot ma 1 gniazdo, bardzo rzadko 2
##   (Items.roll), drugie dorabia rzadkie Dłuto Jubilera (CHISEL); premie liczy Items.totals.
## - kamienie unikalne (UNIQUE, ustalone z autorem 13.11.2026) - po jednym na umiejętność, bez ulepszeń, pasują tylko
##   do swojej umiejętności, zajmują zwykłe gniazdo i zmieniają sposób jej działania (Młynek bez odnowienia, Mgnienie
##   bez limitu skoków, odbicia Rzutu, fale z trafionych Rozłupaniem, fala cięcia zwykłego ciosu); rzadko ze skrzyni
##   Wodza od UNIQUE_MIN_LEVEL; identyfikator "unique:<umiejętność>"; działanie - ProtoWeapon (`Gems.has_unique`).
## Bez stopni (przebudowa ustalona z autorem 15.11.2026): kamień umiejętności wypada na 1. poziomie i ulepsza się
## go odpryskami do MAX_LEVEL (do 20.11.2026 także złotem) (`upgrade_cost`, siła rośnie płynnie - `support_value`); kamień szlachetny
## wypada z 2-3 losowymi premiami z puli swojego rodzaju (JEWELS `pool`, te same w każdym miejscu przedmiotu, siła
## z poziomu lochu jak premie przedmiotów), a ulepszenie dokłada mu kolejną losową premię (do JEWEL_MAX). Niepotrzebny
## kamień rozbija się na odpryski (`shard_value`; odpryski w `Game.shards`; sprzedaży za złoto już nie ma).
## Kamienie leżą w osobnej sakwie (`Game.gems`: identyfikator -> ile sztuk; takie same kamienie leżą na stosie),
## więc nie zajmują torby. Identyfikatory: kamień umiejętności "rodzaj:poziom" (np. "ember:3"), szlachetny
## "rodzaj:poziom lochu:cecha=wartość,cecha=wartość" (np. "ruby:7:damage_pct=5,hp=18"), klucz, dłuto i Pieczęć Oręża - KEY, CHISEL, WEAPON_SEAL (SPECIAL).
## Wkładanie i wyjmowanie (za darmo), ulepszanie i rozbijanie - Game, okna SkillsWindow, HeroStats i GemPicker.

## Najwyższy poziom ulepszenia kamienia umiejętności; najwięcej premii kamienia szlachetnego (wypada z 2-3).
const MAX_LEVEL := 10
const JEWEL_MAX := 5
## Szansa, że kamień szlachetny wypadnie z 3 premiami (inaczej z 2).
const JEWEL_THREE := 0.35
## Siła premii kamienia szlachetnego względem takiej samej premii przedmiotu z tego poziomu lochu.
const JEWEL_MULT := 0.6
## Ulepszenie (decyzja autora 20.11.2026 - bez złota, odpryski x3): kamień umiejętności z poziomu L - UPGRADE_SHARDS x L
## odprysków; szlachetny - dołożenie premii nr 3, 4, 5 za JEWEL_SHARDS.
const UPGRADE_SHARDS := 6.75
const JEWEL_SHARDS := {3: 15, 4: 30, 5: 60}
## Rozbicie: SHATTER_BASE odprysków + SHATTER_SHARE włożonych (szlachetny liczony od 2 premii), unikalny SHATTER_UNIQUE.
const SHATTER_SHARE := 0.5
const SHATTER_BASE := 6
const SHATTER_UNIQUE := 45
## Kamienie wypadają od tego poziomu lochu (decyzja autora: najpierw przedmioty i umiejętności).
const MIN_LEVEL := 3
## Gniazda umiejętności: razem i otwarte na start.
const SKILL_SOCKETS := 5
const SKILL_OPEN := 2
const KEY := "skill_key"
const CHISEL := "chisel"
## Pieczęć Oręża (decyzja autora 20.11.2026 - zamiast kupowania broni za złoto): odblokowuje dowolną broń przed progiem.
## Wypada ze skrzyni Wodza z szansą CHEST_WEAPON_SEAL, gdy jest jeszcze broń do odblokowania (Game.roll_weapon_seal).
const WEAPON_SEAL := "weapon_seal"
const CHEST_WEAPON_SEAL := 0.03
## Łup (17.11.2026 - ok. 3x mniej, uwaga autora: za dużo kamieni na początku): szansa na kamień z goblina, na kamień ze skrzyni Wodza (dwie próby), na klucz i dłuto ze skrzyni
## (rośnie z poziomem lochu do sufitu) i z goblina.
const GOBLIN_GEM := 0.004
const CHEST_GEM := [0.3, 0.1]
const CHEST_KEY := Vector2(0.04, 0.15)
const CHEST_CHISEL := Vector2(0.06, 0.2)
const CHEST_RARE_STEP := 0.005
const GOBLIN_RARE := 0.0005
## Kamień unikalny ze skrzyni Wodza: od poziomu lochu, szansa (rośnie o CHEST_RARE_STEP na poziom do sufitu).
const UNIQUE_MIN_LEVEL := 5
const CHEST_UNIQUE := Vector2(0.03, 0.08)
## Szansa, że kamień to kamień umiejętności (inaczej szlachetny).
const SUPPORT_SHARE := 0.5

## Kamienie umiejętności: nazwa, ikona (z Watry), kolor, `values` - siła na 1. i MAX_LEVEL poziomie (pomiędzy płynnie), `unit` - jak pokazać
## liczbę, `text` - opis ogólny, `skills` - jak działa w danej umiejętności (gdy różnie).
## multi - dodatkowe ostrza / ciosy z obrażeniami `values` x zwykłe; area - obszar +%; ember - podpalenie
## (% obrażeń trafienia przez 3 s); rime - spowolnienie o % na 2 s; discharge - piorun przeskakuje na 2 wrogów (%
## obrażeń); haste - krótsze odnowienie (zwykły cios: szybszy); thrift - mniej many (zwykły cios: mana za trafienie);
## leech - leczy % zadanych obrażeń.
const SUPPORT := {
	"multi": {"name": "Mnożenie", "icon": "split", "color": Color(0.85, 0.85, 0.8), "unit": "pct",
		"values": [40, 100],
		"text": "Więcej ostrzy (dodatkowe zadają %d%% obrażeń).",
		"skills": {
			"strike": "Po cięciu pada drugie, w drugą stronę (%d%% obrażeń).",
			"whirl": "Wiruje drugi, widmowy miecz (%d%% obrażeń).",
			"throw": "Lecą 3 miecze wachlarzem (boczne - %d%% obrażeń).",
			"slam": "Po uderzeniu idzie druga, szersza fala (%d%% obrażeń).",
			"spectral_blades": "O jedno widmowe ostrze więcej (%d%% obrażeń).",
			"m_smash": "Zaraz po uderzeniu drugie, w kolejnego wroga (%d%% obrażeń).",
			"m_throw": "Młot odbija się o 2 razy więcej (te odbicia - %d%% obrażeń).",
			"m_leap": "Po wylądowaniu drugi, szerszy wstrząs (%d%% obrażeń).",
			"m_quake": "Każda fala uderza drugi raz (%d%% obrażeń).",
			"l_roots": "Korzenie przebijają 2 wrogów więcej (te trafienia - %d%% obrażeń).",
			"l_acorn": "Lecą 3 żołędzie wachlarzem (boczne - %d%% obrażeń, wybuch korzeni bez sadzonek).",
			"l_grasp": "Korzenie chwytają 2 wrogów więcej (%d%% obrażeń).",
			"l_spores": "Po chwili zarodniki wybuchają drugi raz (%d%% obrażeń).",
			"l_treants": "Przy tobie wyrasta drugi drzewiec (%d%% obrażeń).",
			"r_thrust": "Zaraz po pchnięciu drugie, w kolejnego wroga (%d%% obrażeń).",
			"r_lunge": "Obok ciebie leci lodowe odbicie, które też przebija (%d%% obrażeń).",
			"r_riposte": "Każda riposta trafia dwa razy (%d%% obrażeń).",
			"r_flurry": "Każde pchnięcie ma drugie, widmowe obok (%d%% obrażeń).",
			"r_swarm": "W chmurze pojawiają się 4 sople więcej (%d%% obrażeń).",
			"steel_ring": "Krąży o jeden widmowy miecz więcej (%d%% obrażeń).",
			"k_flash": "Każdy skok tnie też pobliskiego wroga (%d%% obrażeń).",
		}},
	"area": {"name": "Szerokość", "icon": "area", "color": Color(0.88, 0.75, 0.44), "unit": "pct",
		"values": [15, 55],
		"text": "Większy obszar: +%d%% zasięgu ciosu, wiru, fali i skoku."},
	"ember": {"name": "Żar", "icon": "ember", "color": Color(1.0, 0.55, 0.25), "unit": "pct",
		"values": [20, 115],
		"text": "Podpala trafionych: %d%% obrażeń przez 3 s."},
	"rime": {"name": "Szron", "icon": "rime", "color": Color(0.55, 0.85, 1.0), "unit": "pct",
		"values": [15, 45],
		"text": "Spowalnia trafionych o %d%% na 2 s i rani lodem (połowa tej liczby jako %% obrażeń)."},
	"discharge": {"name": "Piorun", "icon": "discharge", "color": Color(0.45, 0.7, 1.0), "unit": "pct",
		"values": [20, 80],
		"text": "Trafienie przeskakuje na 2 pobliskich wrogów (%d%% obrażeń od pioruna) i poraża ich."},
	"haste": {"name": "Pośpiech", "icon": "venom", "color": Color(0.55, 0.9, 0.5), "unit": "pct",
		"values": [10, 33],
		"text": "Odnowienie krótsze o %d%%.",
		"skills": {
			"strike": "Cios szybszy o %d%%.",
			"k_flash": "Skoki częstsze o %d%%.",
		}},
	"thrift": {"name": "Oszczędność", "icon": "echo", "color": Color(0.75, 0.55, 1.0), "unit": "pct",
		"values": [15, 45],
		"text": "Umiejętność kosztuje o %d%% mniej many.",
		"skills": {
			"strike": "Każde trafienie oddaje %d many.",
		}},
	"leech": {"name": "Krwiopijca", "icon": "brutal", "color": Color(0.95, 0.35, 0.35), "unit": "pct",
		"values": [2, 8],
		"text": "Leczy %d%% zadanych obrażeń."},
	# wzorowane na kamieniach wspierających Path of Exile (decyzja autora 20.11.2026; działanie - ProtoWeapon)
	"echo": {"name": "Echo", "icon": "herald", "color": Color(0.85, 0.6, 0.45), "unit": "pct",
		"values": [15, 40], "not_basic": true,
		"text": "%d%% szans, że umiejętność powtórzy się za darmo (nie w zwykłym ciosie)."},
	"focus": {"name": "Skupienie", "icon": "focus", "color": Color(0.9, 0.3, 0.3), "unit": "pct",
		"values": [25, 60],
		"text": "+%d%% obrażeń, ale obszar o 25%% mniejszy."},
	"splash": {"name": "Rozprysk", "icon": "fury", "color": Color(0.85, 0.55, 0.35), "unit": "pct",
		"values": [20, 55],
		"text": "Trafienie rani też wrogów tuż obok celu (%d%% obrażeń)."},
	"pen": {"name": "Przebicie", "icon": "pierce", "color": Color(0.7, 0.75, 0.85), "unit": "pct",
		"values": [8, 25],
		"text": "Odporność trafionych mniejsza o %d%% (nie spada poniżej zera)."},
	"knockback": {"name": "Odrzut", "icon": "momentum", "color": Color(0.45, 0.85, 0.5), "unit": "pct",
		"values": [60, 150],
		"text": "Odpycha trafionych (siła %d; bossowie stoją)."},
	"execute": {"name": "Egzekucja", "icon": "execute", "color": Color(0.7, 0.15, 0.2), "unit": "pct",
		"values": [6, 15],
		"text": "Dobija wrogów poniżej %d%% zdrowia (elity i bossów - poniżej połowy tej liczby)."},
	"hypothermia": {"name": "Hipotermia", "icon": "frost_edge", "color": Color(0.5, 0.8, 1.0), "unit": "pct",
		"values": [20, 50],
		"text": "+%d%% obrażeń przeciw spowolnionym i zamrożonym."},
	"combustion": {"name": "Spalenie", "icon": "fire_edge", "color": Color(1.0, 0.5, 0.2), "unit": "pct",
		"values": [20, 50],
		"text": "+%d%% obrażeń przeciw płonącym."},
	"keen": {"name": "Bystre Oko", "icon": "storm_edge", "color": Color(0.95, 0.85, 0.3), "unit": "pct",
		"values": [5, 15],
		"text": "+%d%% szansy na krytyk i 4 razy tyle obrażeń krytycznych."},
	"fortify": {"name": "Twardość", "icon": "warlord", "color": Color(0.65, 0.5, 0.85), "unit": "pct",
		"values": [8, 20],
		"text": "Po trafieniu przez 3 s dostajesz o %d%% mniej obrażeń."},
}
## Kamienie unikalne (klucz - umiejętność): nazwa, kolor, krótki opis pod gniazdem i pełny opis. Ikony -
## assets/watra/unique_gems/<umiejętność>.png (tools/unique_gem_art.py).
const UNIQUE_PREFIX := "unique:"
const UNIQUE := {
	"strike": {"name": "Kamień Wichrowego Ostrza", "short": "Fala cięcia",
		"text": "Każde cięcie wypuszcza do przodu falę, która przebija wrogów (60% obrażeń ciosu)."},
	"whirl": {"name": "Kamień Wiecznego Wiru", "short": "Rośnie z czasem",
		"text": "Im dłużej wirujesz, tym większy wir: przez 4 s zasięg i obrażenia Młynka rosną aż do +100%."},
	"throw": {"name": "Kamień Rykoszetu", "short": "Odbicia",
		"text": "Miecz (i widmowe miecze) odbija się od trafionego wroga w kolejnego - do 3 odbić."},
	"slam": {"name": "Kamień Drżącej Ziemi", "short": "Fale z trafionych",
		"text": "Każdy trafiony wróg wywołuje wokół siebie falę uderzeniową, która rani pobliskich (50% obrażeń)."},
	"spectral_blades": {"name": "Kamień Lustrzanych Ostrzy", "short": "Naśladują cię",
		"text": "Ostrza naśladują twoje umiejętności miecza: po każdej z nich każde ostrze powtarza ją przy swoim wrogu w słabszej wersji (40% siły) - cięcie, wir, rzut albo krąg."},
	# młot - broń ziemi (ustalone z autorem 21.11.2026; kamienie - propozycje Claude)
	"m_smash": {"name": "Kamień Lawiny", "short": "Odłamki skał",
		"text": "Co czwarte uderzenie wyrzuca 3 odłamki skały, które spadają na pobliskich wrogów (50% siły)."},
	"m_throw": {"name": "Kamień Powrotu", "short": "Rani przy powrocie",
		"text": "Wracając, młot przebija wszystkich na drodze do ciebie i rani ich jeszcze raz (60% siły)."},
	"m_leap": {"name": "Kamień Grzęzawiska", "short": "Krater zostaje",
		"text": "Krater zostaje na 4 s: wrogowie w nim są spowolnieni o 50% i co pół sekundy obrywają (20% siły)."},
	"m_quake": {"name": "Kamień Uskoku", "short": "Szczeliny",
		"text": "Każda fala wypuszcza szczelinę ze skalnymi kolcami w najbliższego wroga (40% siły)."},
	# Kostur Leszego - broń natury (pomysły autora 25.11.2026)
	"l_roots": {"name": "Kamień Zasiewu", "short": "Sadzonki z zabitych",
		"text": "Wróg zabity Biegnącymi Korzeniami ma 35% szansy zostawić po sobie sadzonkę."},
	"l_acorn": {"name": "Kamień Muchołówki", "short": "Mięsożerna roślina",
		"text": "Z żołędzia wyrasta mięsożerna roślina zamiast zwykłej sadzonki - co sekundę kłapie paszczą na najbliższego wroga (60% siły żołędzia). Liczy się jako sadzonka."},
	"l_grasp": {"name": "Kamień Głogu", "short": "Cierniowa sadzonka",
		"text": "Z wciągniętych wrogów wyrasta cierniowa sadzonka zamiast zwykłej - co 1,2 s strzela cierniem w losowego wroga (50% siły Uścisku). Liczy się jako sadzonka."},
	"l_spores": {"name": "Kamień Purchawki", "short": "Zatruci wybuchają",
		"text": "Zatruty wróg po śmierci może wybuchnąć takimi samymi zarodnikami (50% siły Pylenia, mniejszy obłok): 5% szansy za każdy znak trucizny, do 50%."},
	"l_treants": {"name": "Kamień Leszego", "short": "Drzewce oplatają",
		"text": "Drzewce co 3 s oplatają korzeniami najbliższego wroga: unieruchomiony na 1,5 s, obrywa 50% siły ciosu drzewca."},
	# lodowy rapier - broń lodu (ustalone z autorem 25.11.2026; kamienie - propozycje Claude)
	"r_thrust": {"name": "Kamień Sopli", "short": "Sople",
		"text": "Co czwarte pchnięcie wystrzeliwuje sopel, który leci daleko przed siebie i przebija wrogów (60% siły)."},
	"r_lunge": {"name": "Kamień Zamieci", "short": "Drugi wypad",
		"text": "Przez 1,5 s po wypadzie możesz wykonać drugi wypad za darmo, bez odnowienia."},
	"r_riposte": {"name": "Kamień Mroźnej Riposty", "short": "Riposta zamraża",
		"text": "Szansa na ripostę w kręgu rośnie o 25%, a wróg trafiony ripostą od razu zamarza."},
	"r_flurry": {"name": "Kamień Gradu", "short": "Lecące kolce",
		"text": "Podczas Gradu Pchnięć co 0,3 s wylatuje lodowy kolec w losowego wroga w pobliżu (50% siły pchnięcia rapiera)."},
	"r_swarm": {"name": "Kamień Szronowej Mgły", "short": "Rozprysk szronu",
		"text": "Sopel, który trafi wroga, rozpryskuje się szronem: wrogowie obok dostają 2 znaki chłodu i 30% siły sopla."},
	# elektryczna katana (pomysły autora 15.11.2026)
	"k_slash": {"name": "Kamień Gromowego Ostrza", "short": "Piorun z cięcia",
		"text": "Z każdego cięcia leci do przodu łuk pioruna, który przebija wrogów (50% obrażeń cięcia)."},
	"k_dance": {"name": "Kamień Wiru Ostrza", "short": "Taniec w miejscu",
		"text": "Taniec ostrza w miejscu: zamiast iść naprzód, tniesz 6 razy dookoła siebie."},
	"k_riposte": {"name": "Kamień Łańcucha Kontr", "short": "Kontry z trafionych",
		"text": "Każdy wróg trafiony kontrą sam tnie dookoła siebie (50% siły) - a trafieni przez niego też, łańcuchem (każdy wróg raz, najwyżej 12)."},
	"k_perun": {"name": "Kamień Wędrownych Gromów", "short": "Pioruny po ziemi",
		"text": "Z cięcia wyskakują pioruny pełzające po ziemi, każdy do innego wroga (60% siły) - im dłuższe ładowanie, tym więcej (2-6)."},
	"steel_ring": {"name": "Kamień Wiecznej Stali", "short": "Krąg bez końca",
		"text": "Krąg stali nie znika po czasie i nie ma odnowienia: krąży, dopóki go nie wyłączysz (drugie stuknięcie) albo nie skończy się mana - zużywa ją co sekundę."},
	"k_flash": {"name": "Kamień Nieskończonej Mgły", "short": "Skoki za pół many",
		"text": "Każdy skok Błysku Peruna kosztuje o połowę mniej many."},
	# łuk (ustalone z autorem 20.11.2026)
	"b_shot": {"name": "Kamień Wielostrzału", "short": "Wielostrzał",
		"text": "Zamiast jednej strzały wypuszczasz 5 w stożku przed sobą (każda 70% obrażeń)."},
	"b_seeker": {"name": "Kamień Wiernego Tropiciela", "short": "Przywołanie",
		"text": "Poszukująca strzała staje się przywołaniem: widmowa strzała krąży przy tobie i co 1,5 s wypuszcza Poszukującą strzałę. Rezerwuje 20% many; drugie stuknięcie ją odwołuje."},
	"b_rain": {"name": "Kamień Ulewy", "short": "3 deszcze",
		"text": "Spadają 3 deszcze strzał: na najbliższego wroga i na dwóch innych, oddalonych od siebie."},
	"b_power": {"name": "Kamień Wichury", "short": "Podmuch na boki",
		"text": "Za strzałą wzdłuż całego toru wiatr bije na boki - rani i odpycha wrogów od toru strzały (50% siły)."},
	"b_ballista": {"name": "Kamień Oblężnika", "short": "Powtarza umiejętności",
		"text": "Balista powtarza ze swojego miejsca twoją Poszukującą strzałę, Deszcz strzał i Potężny strzał - za darmo, z połową siły."},
	# Księga Arkanów (pomysły autora 21.11.2026)
	"a_missiles": {"name": "Kamień Rozprysku Arkanów", "short": "Odłamki",
		"text": "Z każdego trafionego wroga odpryskują 3 małe odłamki i uderzają pobliskich wrogów (40% siły pocisku)."},
	"a_circle": {"name": "Kamień Trwałego Kręgu", "short": "Krąg zostaje",
		"text": "Krąg zostaje na ziemi przez 8 s i rani dalej; gdy w nim stoisz, czary są o 30% silniejsze, a Pociski Arkanów lecą o 1 więcej."},
	"a_orbs": {"name": "Kamień Podwójnej Orbity", "short": "Druga orbita",
		"text": "Dalej od ciebie krąży druga orbita z taką samą liczbą kul, w przeciwną stronę."},
	"a_beam": {"name": "Kamień Emanacji", "short": "Fale magii",
		"text": "Dopóki rzucasz promień, co pół sekundy emanuje od ciebie magia, która rani wrogów wokół (40% siły)."},
	"a_seals": {"name": "Kamień Splecionych Pieczęci", "short": "Wiązki",
		"text": "Pieczęcie łączy magiczna wiązka, która rani każdego wroga, który jej dotknie, aż do wybuchu."},
	# mroczna kosa (pomysły autora 21.11.2026)
	"s_reap": {"name": "Kamień Żniwiarza", "short": "Fala Nawii",
		"text": "Każdy trafiony wróg ładuje kosę - po 15 trafieniach od ciebie rozchodzi się fala Nawii, która rani wszystkich wokół."},
	"s_square": {"name": "Kamień Czterech Stron", "short": "4 kwadraty",
		"text": "Pojawiają się 3 widmowe kosy: wszystkie cztery tną naraz i dookoła ciebie powstają 4 takie kwadraty."},
	"s_mow": {"name": "Kamień Rzędów Nawii", "short": "Rzędy wybuchów",
		"text": "Po cięciu w stożku wybucha Nawia - rzędami, a w każdym rzędzie od prawej do lewej (45% siły każdy wybuch)."},
	"s_dance": {"name": "Kamień Wirującego Ostrza", "short": "Wirujące ostrze",
		"text": "Przy końcowym cięciu wylatuje wirujące ostrze: przez 3 s leci od wroga do wroga, a na końcu wybucha."},
	"s_mara": {"name": "Kamień Bliźniaczych Mar", "short": "2 chmury",
		"text": "Z tobą zmieniają się w mgłę jeszcze dwie chmury - same latają po lochu, namierzają wrogów i ich przeklinają."},
	# glewia ognia (ustalone z autorem 14.11.2026)
	"g_thrust": {"name": "Kamień Trójzęba", "short": "3 pchnięcia",
		"text": "Glewia dźga trzy razy naraz w wąskim stożku przed sobą - każdy wróg obrywa raz."},
	"g_sweep": {"name": "Kamień Pogorzeliska", "short": "Płonąca ziemia",
		"text": "Zamach zostawia wzdłuż łuku płonącą ziemię, która przez 3 s rani i podpala wrogów."},
	"g_trail": {"name": "Kamień Bumerangu", "short": "Cięcia wracają",
		"text": "Cięcia bruzdy po dolocie zawracają do ciebie i ranią wrogów drugi raz."},
	"g_pillar": {"name": "Kamień Ognistego Deszczu", "short": "3 upadki",
		"text": "Glewia spada po kolei w 3 różnych wrogów w pobliżu (wybuchy 60% siły, mniejsze płonące kręgi)."},
	"g_dance": {"name": "Kamień Rykoszetu Płomieni", "short": "Odbicia sierpów",
		"text": "Sierpy ognia odbijają się od trafionego wroga w kolejnego w pobliżu - do 3 odbić."},
	# hydrosfera (pomysły autora 14.11.2026)
	"h_bolt": {"name": "Kamień Wodnej Orbity", "short": "Krążące bańki",
		"text": "Bańki nie lecą w wroga, tylko przez 3 s krążą wokół ciebie i przebijają wrogów (najwyżej 4 naraz)."},
	"h_wave": {"name": "Kamień Przypływu", "short": "Fale dookoła",
		"text": "Fala wylatuje na wszystkie strony: 6 fal dookoła ciebie, każda o 40% słabsza."},
	"h_vortex": {"name": "Kamień Wędrownego Wiru", "short": "Wir wędruje",
		"text": "Wir sam płynie ku najbliższym wrogom i wciąga ich po drodze; kręci się o 1 s dłużej."},
	"h_geyser": {"name": "Kamień Erupcji", "short": "Kule z gejzerów",
		"text": "Każdy gejzer wypluwa 3 kule wody, które spadają dookoła i ranią obszarem (60% siły gejzera)."},
	"h_guardian": {"name": "Kamień Echa", "short": "Strażnik powtarza",
		"text": "Strażnik powtarza ze swojego miejsca twoją Falę, Wir i Gejzery - za darmo, z połową siły."},
}
const UNIQUE_COLOR := Color(1.0, 0.82, 0.35)
## Dawne identyfikatory kamieni -> obecne (wczytanie starego zapisu): kamień unikalny Mgnienia miecza przeszedł
## na Błysk Peruna katany (15.11.2026).
const LEGACY := {"unique:blink": "unique:k_flash"}
const SUPPORT_ORDER := ["multi", "area", "ember", "rime", "discharge", "haste", "thrift", "leech", "echo", "focus",
		"splash", "pen", "knockback", "execute", "hypothermia", "combustion", "keen", "fortify"]
## Bystre Oko: obrażenia krytyczne = tyle razy szansa; Twardość - czas działania (s); Skupienie - obszar razy tyle;
## Rozprysk - promień wokół celu (px).
const KEEN_DAMAGE := 4.0
const FORTIFY_TIME := 3.0
const FOCUS_AREA := 0.75
const SPLASH_RADIUS := 32.0
## Oszczędność w zwykłym ciosie: many za trafienie na 1. i MAX_LEVEL poziomie.
const THRIFT_STRIKE := [1, 4]

## Kamienie szlachetne: nazwa, plik ikony (z Watry, `<rodzaj>_<liczba premii>.png` - kamień rośnie z premiami),
## kolor i `pool` - premie (Items.STAT_FORMATS), które mogą na nim wypaść; działają tak samo w każdym miejscu przedmiotu.
const JEWELS := {
	"ruby": {"name": "Rubin", "color": Color(1.0, 0.42, 0.42),
		"pool": ["damage_pct", "hp", "regen", "crit_pct", "crit_dmg_pct", "pen_pct"]},
	"sapphire": {"name": "Szafir", "color": Color(0.43, 0.66, 1.0),
		"pool": ["mana", "mana_regen", "cdr_pct", "xp_pct", "ember_pct", "mana_on_kill"]},
	"emerald": {"name": "Szmaragd", "color": Color(0.37, 0.86, 0.49),
		"pool": ["attack_speed_pct", "move_pct", "dodge_pct", "pickup_pct", "area_pct"]},
	"onyx": {"name": "Onyks", "color": Color(0.78, 0.78, 0.82),
		"pool": ["protection_pct", "hp", "life_on_kill", "regen", "element_res_pct"]},
}
const JEWEL_ORDER := ["ruby", "sapphire", "emerald", "onyx"]

const SPECIAL := {
	KEY: {"name": "Klucz Runiczny", "icon": "res://assets/watra/gems/key_rune.png", "color": Color(1.0, 0.8, 0.35),
		"text": "Otwiera kolejne gniazdo wybranej umiejętności (okno umiejętności)."},
	CHISEL: {"name": "Dłuto Jubilera", "icon": "res://assets/watra/gems/chisel.png", "color": Color(0.7, 0.85, 1.0),
		"text": "Dorabia drugie gniazdo w przedmiocie (opis przedmiotu w oknie „Postać”)."},
	WEAPON_SEAL: {"name": "Pieczęć Oręża", "icon": "res://assets/watra/gems/weapon_seal.png", "color": Color(1.0, 0.75, 0.3),
		"text": "Odblokowuje dowolną broń przed progiem lochu (lista broni przy kamieniu run w oknie umiejętności)."},
}
const SOCKET_ICON := preload("res://assets/watra/gems/socket.png")


## Identyfikator kamienia umiejętności z rodzaju i poziomu ulepszenia.
static func make(kind: String, level := 1) -> String:
	return "%s:%d" % [kind, clampi(level, 1, MAX_LEVEL)]


## Identyfikator kamienia szlachetnego: rodzaj, poziom lochu, z którego wypadł, i premie [[cecha, wartość], ...].
static func make_jewel(kind: String, dungeon_level: int, stats: Array) -> String:
	var parts: PackedStringArray = []
	for s in stats:
		var v: float = s[1]
		parts.append("%s=%s" % [s[0], str(snappedf(v, 0.1)) if s[0] in Items.DECIMAL_STATS else str(roundi(v))])
	return "%s:%d:%s" % [kind, maxi(dungeon_level, 1), ",".join(parts)]


static func kind_of(id: String) -> String:
	return id.get_slice(":", 0)


static func is_special(id: String) -> bool:
	return SPECIAL.has(id)


## Kamień umiejętności: zwykły (rodzaj:poziom) albo unikalny.
static func is_support(id: String) -> bool:
	return (SUPPORT.has(kind_of(id)) and id.get_slice_count(":") == 2 and id.get_slice(":", 1).is_valid_int()
			and int(id.get_slice(":", 1)) >= 1 and int(id.get_slice(":", 1)) <= MAX_LEVEL) or is_unique(id)


## Kamień unikalny ("unique:<umiejętność>").
static func is_unique(id: String) -> bool:
	return id.begins_with(UNIQUE_PREFIX) and UNIQUE.has(id.trim_prefix(UNIQUE_PREFIX))


## Identyfikator kamienia unikalnego umiejętności.
static func unique_of(skill: String) -> String:
	return UNIQUE_PREFIX + skill


## Umiejętność kamienia unikalnego ("" - to nie unikalny).
static func unique_skill(id: String) -> String:
	return id.trim_prefix(UNIQUE_PREFIX) if is_unique(id) else ""


## Czy w gniazdach umiejętności `skill` siedzi jej kamień unikalny.
static func has_unique(sockets: Array, skill: String) -> bool:
	return sockets.has(unique_of(skill))


## Kamień szlachetny z premiami (stare identyfikatory "rubin:stopień" sprzed 15.11.2026 nie przechodzą - decyzja autora).
static func is_jewel(id: String) -> bool:
	return JEWELS.has(kind_of(id)) and id.get_slice_count(":") == 3 and not jewel_stats(id).is_empty()


## Czy identyfikator jest poprawny (z zapisu gry).
static func valid(id) -> bool:
	return id is String and (is_special(id) or is_support(id) or is_jewel(id))


## Poziom ulepszenia kamienia umiejętności (1-MAX_LEVEL); szlachetny - liczba premii; inne - 0.
static func level_of(id: String) -> int:
	if is_unique(id) or is_special(id):
		return 0
	if JEWELS.has(kind_of(id)):
		return jewel_stats(id).size()
	return clampi(int(id.get_slice(":", 1)), 1, MAX_LEVEL) if id.contains(":") else 0


## Poziom lochu, z którego wypadł kamień szlachetny (siła dokładanych premii).
static func jewel_level(id: String) -> int:
	return maxi(int(id.get_slice(":", 1)), 1)


## Premie kamienia szlachetnego: [[cecha, wartość], ...] (pusta - zły identyfikator).
static func jewel_stats(id: String) -> Array:
	var out: Array = []
	if not JEWELS.has(kind_of(id)) or id.get_slice_count(":") != 3:
		return out
	for part in id.get_slice(":", 2).split(",", false):
		var stat := part.get_slice("=", 0)
		if not Items.STAT_FORMATS.has(stat) or not part.contains("="):
			return []
		out.append([stat, float(part.get_slice("=", 1))])
	return out


## Nazwa: „Żar”, „Rubin”, „Klucz Runiczny”, „Kamień Wichrowego Ostrza” (poziom pokazuje `kind_line` i pole).
static func name_of(id: String) -> String:
	if is_special(id):
		return Lang.t(SPECIAL[id].name)
	if is_unique(id):
		return Lang.t(UNIQUE[unique_skill(id)].name)
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	return Lang.t(data.name) if not data.is_empty() else ""


static func color_of(id: String) -> Color:
	if is_special(id):
		return SPECIAL[id].color
	if is_unique(id):
		return UNIQUE_COLOR
	var data: Dictionary = SUPPORT.get(kind_of(id), JEWELS.get(kind_of(id), {}))
	return data.get("color", Color.WHITE)


static func icon_of(id: String) -> Texture2D:
	if is_special(id):
		return load(SPECIAL[id].icon)
	if is_unique(id):
		return load("res://assets/watra/unique_gems/%s.png" % unique_skill(id))
	if is_support(id):
		return load("res://assets/watra/supports/%s.png" % SUPPORT[kind_of(id)].icon)
	if is_jewel(id):
		return load("res://assets/watra/gems/%s_%d.png" % [kind_of(id), clampi(level_of(id), 1, 5)])
	return null


## Rodzaj kamienia słowami („Kamień umiejętności, poziom 3/10”, „Kamień szlachetny, premie 3/5”).
static func kind_line(id: String) -> String:
	if is_special(id):
		return Lang.t("Rzadki przedmiot")
	if is_unique(id):
		return Lang.t("Kamień unikalny: %s") % Skills.name_of(unique_skill(id))
	if is_support(id):
		return Lang.t("Kamień umiejętności, poziom %d/%d") % [level_of(id), MAX_LEVEL]
	return Lang.t("Kamień szlachetny, premie %d/%d") % [level_of(id), JEWEL_MAX]


## Krótki opis działania kamienia pod gniazdem (kilka słów): kamień umiejętności w umiejętności `skill`,
## szlachetny - liczba premii.
const SHORT := {
	"multi": "Więcej ostrzy",
	"area": "+%d%% obszaru",
	"ember": "Podpala %d%%",
	"rime": "Spowalnia %d%%",
	"discharge": "Piorun %d%%",
	"haste": "-%d%% odnowienia",
	"thrift": "-%d%% many",
	"leech": "Leczy %d%%",
	"echo": "Powtórka %d%%",
	"focus": "+%d%% obrażeń",
	"splash": "Rozprysk %d%%",
	"pen": "-%d%% odporności",
	"knockback": "Odpycha",
	"execute": "Dobija %d%%",
	"hypothermia": "+%d%% na wolnych",
	"combustion": "+%d%% na płonących",
	"keen": "+%d%% krytyka",
	"fortify": "-%d%% obrażeń",
}
const SHORT_STRIKE := {"haste": "+%d%% szybkości", "thrift": "+%d many za cios"}


static func short_text(id: String, skill := "", _slot := "") -> String:
	if is_unique(id):
		return Lang.t(UNIQUE[unique_skill(id)].short)
	if is_support(id):
		var kind := kind_of(id)
		if kind == "thrift" and Skills.is_basic(skill):
			return Lang.t(SHORT_STRIKE.thrift) % thrift_mana(level_of(id))
		var text: String = SHORT_STRIKE[kind] if Skills.is_basic(skill) and SHORT_STRIKE.has(kind) else SHORT[kind]
		return Lang.t(text) % roundi(support_value(id)) if text.contains("%d") else Lang.t(text)
	if is_jewel(id):
		return Lang.n(level_of(id), "%d premia", "%d premie", "%d premii") % level_of(id)
	return ""


## Wartość z pary [na 1. poziomie, na MAX_LEVEL] dla poziomu `level` (płynnie, zaokrąglona).
static func _lerp_level(pair: Array, level: int) -> int:
	return roundi(lerpf(float(pair[0]), float(pair[1]), float(clampi(level, 1, MAX_LEVEL) - 1) / (MAX_LEVEL - 1)))


## Siła kamienia umiejętności (z `values` na jego poziomie).
static func support_value(id: String) -> float:
	return float(_lerp_level(SUPPORT[kind_of(id)].values, level_of(id))) if is_support(id) and not is_unique(id) else 0.0


## Oszczędność w zwykłym ciosie: many za trafienie na poziomie `level`.
static func thrift_mana(level: int) -> int:
	return _lerp_level(THRIFT_STRIKE, level)


## Opis działania kamienia umiejętności; z `skill` - jak działa w tej umiejętności.
static func support_text(id: String, skill := "") -> String:
	if not is_support(id):
		return ""
	if is_unique(id):
		var own := unique_skill(id)
		var text := Lang.t(UNIQUE[own].text)
		return text if skill == "" or skill == own else Lang.t("Pasuje tylko do: %s.") % Skills.name_of(own)
	var kind := kind_of(id)
	var data: Dictionary = SUPPORT[kind]
	if kind == "thrift" and Skills.is_basic(skill):
		return Lang.t(data.skills.strike) % thrift_mana(level_of(id))
	var text: String = data.get("skills", {}).get(skill, data.text)
	return Lang.t(text) % roundi(support_value(id))


## Premie kamienia szlachetnego słowami („+6% obrażeń”), każda osobno.
static func jewel_lines(id: String) -> Array[String]:
	var lines: Array[String] = []
	for s in jewel_stats(id):
		lines.append(Items.stat_text(s[0], s[1]))
	return lines


## Premie kamienia szlachetnego w jednej linii („+6% obrażeń, +20 do zdrowia”) - opis gniazda przedmiotu.
static func jewel_text(id: String, _slot := "") -> String:
	return ", ".join(jewel_lines(id))


## Linie opisu kamienia w sakwie (bez kontekstu umiejętności czy przedmiotu).
static func description(id: String) -> Array[String]:
	if is_special(id):
		return [Lang.t(SPECIAL[id].text)]
	if is_support(id):
		return [support_text(id)]
	return jewel_lines(id)


# --- łup ---

## Kamień szlachetny rodzaju `kind` z łupu na poziomie lochu: 2-3 różne premie z jego puli.
static func roll_jewel(kind: String, level: int, count := -1) -> String:
	if count < 0:
		count = 3 if randf() < JEWEL_THREE else 2
	var pool: Array = JEWELS[kind].pool.duplicate()
	pool.shuffle()
	var stats: Array = []
	for i in mini(count, pool.size()):
		stats.append([pool[i], _jewel_value(pool[i], level)])
	return make_jewel(kind, level, stats)


## Siła premii kamienia szlachetnego z poziomu lochu (część premii przedmiotu, co najmniej 1 / 0,1).
static func _jewel_value(stat: String, level: int) -> float:
	var v := Items.roll_affix(stat, level) * JEWEL_MULT
	return maxf(snappedf(v, 0.1), 0.1) if stat in Items.DECIMAL_STATS else float(maxi(roundi(v), 1))


## Kamień z łupu na poziomie lochu: kamień umiejętności (1. poziom) albo szlachetny z premiami z tego poziomu.
static func roll(level: int) -> String:
	if randf() < SUPPORT_SHARE:
		return make(SUPPORT_ORDER.pick_random())
	return roll_jewel(JEWEL_ORDER.pick_random(), level)


## Łup z goblina: kamień, klucz albo dłuto (rzadko; poniżej MIN_LEVEL nic) - "" gdy nic.
## `chance_mult` - mnożnik szans (ulepszenie łupu).
static func roll_goblin(level: int, chance_mult := 1.0) -> String:
	if level < MIN_LEVEL:
		return ""
	var r := randf()
	if r < GOBLIN_RARE * chance_mult:
		return KEY if randf() < 0.5 else CHISEL
	return roll(level) if r < (GOBLIN_RARE + GOBLIN_GEM) * chance_mult else ""


## Łup ze skrzyni Wodza: lista identyfikatorów (kamienie, klucz, dłuto; poniżej MIN_LEVEL - pusta).
## `chance_mult` - mnożnik szans (ulepszenie łupu).
static func roll_chest(level: int, chance_mult := 1.0) -> Array:
	var out: Array = []
	if level < MIN_LEVEL:
		return out
	for chance in CHEST_GEM:
		if randf() < chance * chance_mult:
			out.append(roll(level))
	var step := CHEST_RARE_STEP * (level - MIN_LEVEL)
	if level >= UNIQUE_MIN_LEVEL and randf() < minf(CHEST_UNIQUE.x + CHEST_RARE_STEP * (level - UNIQUE_MIN_LEVEL),
			CHEST_UNIQUE.y) * chance_mult:
		out.append(unique_of(UNIQUE.keys().pick_random()))
	if randf() < minf(CHEST_KEY.x + step, CHEST_KEY.y) * chance_mult:
		out.append(KEY)
	if randf() < minf(CHEST_CHISEL.x + step, CHEST_CHISEL.y) * chance_mult:
		out.append(CHISEL)
	return out


# --- ulepszanie, sprzedaż, rozbijanie ---

## Czy kamień da się ulepszyć (kamień umiejętności poniżej MAX_LEVEL, szlachetny poniżej JEWEL_MAX premii).
static func can_upgrade(id: String) -> bool:
	if is_jewel(id):
		return level_of(id) < mini(JEWEL_MAX, JEWELS[kind_of(id)].pool.size())
	return is_support(id) and not is_unique(id) and level_of(id) < MAX_LEVEL


## Koszt następnego ulepszenia w odpryskach; 0 - nie da się.
static func upgrade_cost(id: String) -> int:
	if not can_upgrade(id):
		return 0
	var lvl := level_of(id)
	if is_jewel(id):
		return JEWEL_SHARDS[lvl + 1]
	return roundi(UPGRADE_SHARDS * lvl)


## Kamień po ulepszeniu: kamień umiejętności o poziom wyżej, szlachetny z dołożoną losową premią z puli
## (z poziomu lochu kamienia). Gdy się nie da - ten sam identyfikator.
static func upgraded(id: String) -> String:
	if not can_upgrade(id):
		return id
	if is_support(id):
		return make(kind_of(id), level_of(id) + 1)
	var stats := jewel_stats(id)
	var free: Array = []
	for stat in JEWELS[kind_of(id)].pool:
		if not stats.any(func(s: Array) -> bool: return s[0] == stat):
			free.append(stat)
	var stat: String = free.pick_random()
	stats.append([stat, _jewel_value(stat, jewel_level(id))])
	return make_jewel(kind_of(id), jewel_level(id), stats)


## Ile odprysków włożono w ulepszenia kamienia (szlachetny liczony od 2 premii).
static func invested(id: String) -> int:
	var total := 0
	if is_jewel(id):
		for n in range(3, level_of(id) + 1):
			total += JEWEL_SHARDS[n]
	elif is_support(id) and not is_unique(id):
		for lvl in range(1, level_of(id)):
			total += upgrade_cost(make(kind_of(id), lvl))
	return total


## Czy kamień można rozbić (klucze, dłuta i pieczęcie nie).
static func can_shatter(id: String) -> bool:
	return is_support(id) or is_jewel(id)


## Ile odprysków daje rozbicie sztuki kamienia.
static func shard_value(id: String) -> int:
	if is_unique(id):
		return SHATTER_UNIQUE
	if can_shatter(id):
		return SHATTER_BASE + roundi(invested(id) * SHATTER_SHARE)
	return 0


## Czy kamień umiejętności pasuje do umiejętności `skill` (Echo nie działa w zwykłym ciosie - "not_basic").
static func fits(id: String, skill: String) -> bool:
	if not is_support(id) or is_unique(id):
		return true
	return not (SUPPORT[kind_of(id)].get("not_basic", false) and Skills.is_basic(skill))


## Siła kamienia umiejętności rodzaju `kind` w gniazdach (lista identyfikatorów; 0 - brak).
static func skill_power(sockets: Array, kind: String) -> float:
	for id in sockets:
		if id is String and is_support(id) and not is_unique(id) and kind_of(id) == kind:
			return support_value(id)
	return 0.0


## Poziom kamienia rodzaju `kind` w gniazdach (0 - brak).
static func skill_level(sockets: Array, kind: String) -> int:
	for id in sockets:
		if id is String and is_support(id) and not is_unique(id) and kind_of(id) == kind:
			return level_of(id)
	return 0

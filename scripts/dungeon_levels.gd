class_name DungeonLevels
## Poziomy lochu jak głębokie szczeliny w Diablo 3: każdy następny poziom ma silniejsze potwory i bossa
## (`power`) oraz bogatszą skrzynię bossa (`chest_embers`). Pokonanie bossa odblokowuje następny poziom
## (najwyższy przebity trzyma `Game.best_level`). Stąd też koszt przyzwania bossa - pełny pasek żaru w lochu.

## Koszt przyzwania bossa na 1. poziomie (pełny pasek żaru w lochu; przyzwanie go zjada, nadwyżka po zwycięstwie
## idzie do bazy). W głębi rośnie razem z wartością iskier (`ember_value`) i tłumem (`crowd`) - `summon_cost`.
const SUMMON_BASE := 100
## Wartość iskry żaru: +2% z każdym poziomem (101. poziom x3). Z +15% (jak doświadczenie) na 101. poziomie wpadało
## ~30 000 żaru w 2 minuty (uwaga autora 16.11.2026).
const EMBER_STEP := 0.02
## Siła potworów (zdrowie i obrażenia): +15% z każdym poziomem, a całość dodatkowo x1,02 na poziom - w głębi rośnie
## coraz szybciej (decyzja autora 13.11.2026: poziom 10 ~2,8x, 50 ~22x, 100 ~112x; wcześniej tylko liniowo, 100 = 16x).
## 17.11.2026 (gra za łatwa): +20% na poziom (10 ~3,4x, 50 ~29x, 100 ~148x); nagrody dalej rosną o REWARD_STEP.
const POWER_STEP := 0.20
const REWARD_STEP := 0.15
## Potwory (bez bossów) zadają tyle razy więcej obrażeń (decyzja autora 17.11.2026 - gra za łatwa).
const MONSTER_DAMAGE := 1.5
## Bossowie: tyle razy więcej zdrowia i obrażeń niż siła poziomu (uwaga autora 17.11.2026: bossowie też za łatwi).
const BOSS_POWER := 1.5
const POWER_GROWTH := 1.02
## Tłum: z każdym poziomem o tyle więcej potworów (gęstość strumienia), najwyżej CROWD_MAX razy
## (z 45 naraz robi się ~70 - ProtoHorde.ALIVE_CAP pilnuje telefonu).
const CROWD_STEP := 0.01
const CROWD_MAX := 1.55
## Żar ze skrzyni bossa na 1. poziomie i przyrost na każdy kolejny.
const CHEST_BASE := 20
const CHEST_STEP := 10
## Gobliny łucznicy: od tego poziomu, ich udział w strumieniu na nim, przyrost na każdy następny i sufit udziału.
const ARCHER_FROM := 2
const ARCHER_SHARE := 0.15
const ARCHER_SHARE_STEP := 0.03
const ARCHER_SHARE_MAX := 0.3
## Gobliny osiłki: od tego poziomu, udział na nim, przyrost na każdy następny i sufit udziału.
const BRUTE_FROM := 3
const BRUTE_SHARE := 0.08
const BRUTE_SHARE_STEP := 0.02
const BRUTE_SHARE_MAX := 0.15


## Mnożnik zdrowia i obrażeń potworów (i premii przedmiotów, które rosną z lochem) na danym poziomie (1. poziom - 1.0).
static func power(level: int) -> float:
	var steps := maxi(level, 1) - 1
	return (1.0 + POWER_STEP * steps) * pow(POWER_GROWTH, steps)


## Liniowy przyrost (stara krzywa siły) - doświadczenie za potwory, żeby postać nie awansowała lawinowo w głębi.
static func reward(level: int) -> float:
	return 1.0 + REWARD_STEP * (maxi(level, 1) - 1)


## Koszt przyzwania bossa (decyzja autora 16.11.2026): iskry są warte `ember_value` razy więcej, a potworów jest
## `crowd` razy więcej, więc koszt rośnie o oba mnożniki - wyprawa trwa podobnie długo, a nadwyżka do bazy rośnie z głębią.
## Poziom 1 - 100, 10 - ~129, 50 - ~295, 101 - ~465.
static func summon_cost(level: int) -> int:
	return roundi(SUMMON_BASE * ember_value(level) * crowd(level))


## Mnożnik wartości iskry żaru z potworów na danym poziomie (ProtoHorde._on_ember).
static func ember_value(level: int) -> float:
	return 1.0 + EMBER_STEP * (maxi(level, 1) - 1)


## Mnożnik liczby potworów w strumieniu na danym poziomie.
static func crowd(level: int) -> float:
	return minf(1.0 + CROWD_STEP * (maxi(level, 1) - 1), CROWD_MAX)


## Ile żaru sypie skrzynia po pokonaniu bossa.
static func chest_embers(level: int) -> int:
	return CHEST_BASE + CHEST_STEP * (maxi(level, 1) - 1)


## Jaka część goblinów ze strumienia to łucznicy (0 przed ARCHER_FROM).
static func archer_share(level: int) -> float:
	if level < ARCHER_FROM:
		return 0.0
	return minf(ARCHER_SHARE + ARCHER_SHARE_STEP * (level - ARCHER_FROM), ARCHER_SHARE_MAX)


## Jaka część goblinów ze strumienia to osiłki (0 przed BRUTE_FROM).
static func brute_share(level: int) -> float:
	if level < BRUTE_FROM:
		return 0.0
	return minf(BRUTE_SHARE + BRUTE_SHARE_STEP * (level - BRUTE_FROM), BRUTE_SHARE_MAX)

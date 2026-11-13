class_name DungeonLevels
## Poziomy lochu jak głębokie szczeliny w Diablo 3: każdy następny poziom ma silniejsze potwory i bossa
## (`power`) oraz bogatszą skrzynię bossa (`chest_embers`). Pokonanie bossa odblokowuje następny poziom
## (najwyższy przebity trzyma `Game.best_level`). Stąd też koszt przyzwania bossa - pełny pasek żaru w lochu.

## Tyle żaru zapełnia pasek w lochu i tyle zjada przyzwanie bossa (nadwyżka zostaje i po zwycięstwie idzie do bazy).
const SUMMON_COST := 100
## O tyle rośnie siła potworów (zdrowie i obrażenia) z każdym poziomem (+15%).
const POWER_STEP := 0.15
## Żar ze skrzyni bossa na 1. poziomie i przyrost na każdy kolejny.
const CHEST_BASE := 20
const CHEST_STEP := 10
## Gobliny łucznicy: od tego poziomu, ich udział w strumieniu na nim, przyrost na każdy następny i sufit udziału.
const ARCHER_FROM := 2
const ARCHER_SHARE := 0.15
const ARCHER_SHARE_STEP := 0.03
const ARCHER_SHARE_MAX := 0.3


## Mnożnik zdrowia i obrażeń potworów na danym poziomie (1. poziom - 1.0).
static func power(level: int) -> float:
	return 1.0 + POWER_STEP * (maxi(level, 1) - 1)


## Ile żaru sypie skrzynia po pokonaniu bossa.
static func chest_embers(level: int) -> int:
	return CHEST_BASE + CHEST_STEP * (maxi(level, 1) - 1)


## Jaka część goblinów ze strumienia to łucznicy (0 przed ARCHER_FROM).
static func archer_share(level: int) -> float:
	if level < ARCHER_FROM:
		return 0.0
	return minf(ARCHER_SHARE + ARCHER_SHARE_STEP * (level - ARCHER_FROM), ARCHER_SHARE_MAX)

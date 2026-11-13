class_name Elites
## Elitarne potwory w lochu (jak w Watrze - scripts/dungeon_elite.gd, uproszczone na telefon): zwykły goblin
## ze strumienia (każdego rodzaju) dostaje 1-3 cechy, jest większy, świeci w kolorze pierwszej cechy i ma nad
## głową napis z cechami i pasek zdrowia. Pojawia się rzadko (co `EVERY` s, od `FROM_LEVEL` poziomu lochu),
## ma więcej zdrowia i obrażeń, a pokonany daje pewny przedmiot, dużą iskrę żaru i więcej doświadczenia.
## Działanie cech: scripts/proto/proto_elite.gd. Napisy cech tłumaczone przy pokazywaniu (tr).

## Cechy: nazwa (do tłumaczenia) i kolor poświaty, napisu i znaczków.
const TRAITS := {
	"fast": {"name": "Szybki", "color": Color(0.62, 1.0, 0.42)},
	"shield": {"name": "Tarczowy", "color": Color(0.44, 0.83, 1.0)},
	"volatile": {"name": "Wybuchowy", "color": Color(1.0, 0.36, 0.17)},
	"commanding": {"name": "Dowódczy", "color": Color(1.0, 0.75, 0.25)},
}

## Od tego poziomu lochu; pierwsza elita po `FIRST` s (losowo w przedziale), kolejne co `EVERY` s.
const FROM_LEVEL := 2
const FIRST := Vector2(25.0, 35.0)
const EVERY := Vector2(45.0, 65.0)
## Najwięcej cech: 1 na poziomach 2-3, 2 od 4., 3 od 7.
const TWO_TRAITS_FROM := 4
const THREE_TRAITS_FROM := 7

## Zdrowie: x HEALTH, plus HEALTH_PER_TRAIT za każdą cechę ponad pierwszą; obrażenia x DAMAGE; większa o SCALE.
const HEALTH := 3.0
const HEALTH_PER_TRAIT := 0.75
const DAMAGE := 1.3
const SCALE := 1.25
## Nagroda: żar z iskry, doświadczenie (x zwykły goblin), przedmiot z wagami rzadkości skrzyni bossa.
const EMBERS := 10
const XP := 5

## Szybki: prędkość i odstęp między atakami.
const FAST_SPEED := 1.6
const FAST_COOLDOWN := 0.6
## Tarczowy: tarcza = ułamek zdrowia elity, wraca w całości po `SHIELD_DELAY` s bez obrażeń.
const SHIELD := 0.5
const SHIELD_DELAY := 4.0
## Wybuchowy: po śmierci koło `VOLATILE_RADIUS` wypełnia się przez `VOLATILE_WARN` s, potem wybuch.
const VOLATILE_RADIUS := 34.0
const VOLATILE_WARN := 1.2
const VOLATILE_DAMAGE := 20
## Dowódczy: gobliny w promieniu `AURA_RADIUS` są szybsze i silniejsze (odświeżane co `AURA_EVERY` s).
const AURA_RADIUS := 90.0
const AURA_EVERY := 0.5
const EMPOWER_SPEED := 1.3
const EMPOWER_DAMAGE := 1.3
const EMPOWER_TINT := Color(1.15, 1.0, 0.8)


## Ile cech najwyżej na danym poziomie lochu (0 - jeszcze bez elit).
static func max_traits(level: int) -> int:
	if level < FROM_LEVEL:
		return 0
	if level >= THREE_TRAITS_FROM:
		return 3
	return 2 if level >= TWO_TRAITS_FROM else 1


## Losowe cechy elity na danym poziomie (różne; liczba od max-1 do max, co najmniej 1).
static func roll_traits(level: int) -> Array[String]:
	var most := max_traits(level)
	var out: Array[String] = []
	if most <= 0:
		return out
	var pool: Array = TRAITS.keys()
	pool.shuffle()
	for i in randi_range(maxi(1, most - 1), most):
		out.append(pool[i])
	return out


## Mnożnik zdrowia elity z daną liczbą cech.
static func health_mult(traits: int) -> float:
	return HEALTH + HEALTH_PER_TRAIT * maxi(traits - 1, 0)


## Nazwy cech do napisu nad głową (przetłumaczone).
static func label(traits: Array) -> String:
	var names: PackedStringArray = []
	for t in traits:
		names.append(Lang.t(TRAITS[t].name))
	return " · ".join(names)

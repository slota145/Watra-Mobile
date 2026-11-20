class_name Shop
## Kupiec w bazie - wymiana run (ustalone z autorem 20.11.2026, ROADMAP punkt 4; wcześniej półka za złoto).
## Stała lista ofert (`offers`), bez limitu sztuk: każdą runę kupuje się za Runy Szlifu po kursie x BUY_MARKUP
## (zaokrąglone w górę - kupiec bierze swoje) i rozmienia na Runy Szlifu po kursie (Runes.value_of). Klucz Runiczny
## i Dłuto Jubilera (Gems) kupuje się za runy (KEY_PRICE, CHISEL_PRICE). Oferta to {"pay": runa, "cost": ile,
## "item": runa albo identyfikator Gems, "count": ile sztuk, "kind": "buy" / "change" / "gem"}.
## Wymianę robi Game.buy_offer, okno - scripts/ui/shop_window.gd.

const BUY_MARKUP := 1.5
const KEY_PRICE := {"pay": Runes.CHAOS, "cost": 2}
const CHISEL_PRICE := {"pay": Runes.ASCEND, "cost": 1}


## Wszystkie oferty: kupno run za Szlify, rozmiana run na Szlify, klucz i dłuto.
static func offers() -> Array:
	var out: Array = []
	for id in Runes.ORDER:
		if id != Runes.POLISH:
			out.append({"pay": Runes.POLISH, "cost": buy_cost(id), "item": id, "count": 1, "kind": "buy"})
	for id in Runes.ORDER:
		if id != Runes.POLISH:
			out.append({"pay": id, "cost": 1, "item": Runes.POLISH, "count": Runes.value_of(id), "kind": "change"})
	out.append({"pay": KEY_PRICE.pay, "cost": KEY_PRICE.cost, "item": Gems.KEY, "count": 1, "kind": "gem"})
	out.append({"pay": CHISEL_PRICE.pay, "cost": CHISEL_PRICE.cost, "item": Gems.CHISEL, "count": 1, "kind": "gem"})
	return out


## Ile Run Szlifu kosztuje runa `id` u kupca.
static func buy_cost(id: String) -> int:
	return ceili(Runes.value_of(id) * BUY_MARKUP)


## Nazwa, ikona i kolor tego, co daje oferta (runa albo klucz / dłuto).
static func name_of(offer: Dictionary) -> String:
	return Runes.name_of(offer.item) if Runes.valid(offer.item) else Gems.name_of(offer.item)


static func icon_of(offer: Dictionary) -> Texture2D:
	return Runes.icon_of(offer.item) if Runes.valid(offer.item) else Gems.icon_of(offer.item)


static func color_of(offer: Dictionary) -> Color:
	return Runes.color_of(offer.item) if Runes.valid(offer.item) else Gems.color_of(offer.item)

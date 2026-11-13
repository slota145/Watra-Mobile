class_name Shop
## Kupiec w bazie (ustalone z autorem 12.11.2026): towar w ograniczonej liczbie, odnawia się po każdym pokonanym
## bossie (`Game.restock_shop` przy zwycięstwie; pierwszy towar przy pierwszym otwarciu). Na półce: Klucz Runiczny,
## Dłuto Jubilera, kamienie najniższego stopnia (Okruch) i kilka przedmiotów (magiczne albo rzadkie) z poziomu
## najwyższego przebitego lochu. Oferta to słownik {"gem": identyfikator, "price"} albo {"item": przedmiot, "price"};
## kupiona znika z półki do następnej dostawy. Stan trzyma i zapisuje `Game.shop`, okno - `scripts/ui/shop_window.gd`.

## Ceny kluczy, dłut i kamieni (złoto).
const KEY_PRICE := 400
const CHISEL_PRICE := 250
const GEM_PRICE := 60
## Ile kamieni i przedmiotów na półce po dostawie.
const GEMS := 2
const ITEMS := 3
## Przedmiot kosztuje tyle razy więcej, niż daje jego sprzedaż.
const ITEM_MARKUP := 4
## Szansa, że przedmiot na półce jest rzadki (inaczej magiczny).
const RARE_CHANCE := 0.25


## Nowy towar na półce; przedmioty z poziomu lochu `level`.
static func stock(level: int) -> Array:
	var offers: Array = [{"gem": Gems.KEY, "price": KEY_PRICE}, {"gem": Gems.CHISEL, "price": CHISEL_PRICE}]
	var kinds: Array = Gems.SUPPORT_ORDER + Gems.JEWEL_ORDER
	kinds.shuffle()  # różne rodzaje kamieni
	for i in GEMS:
		offers.append({"gem": Gems.make(kinds[i], 0), "price": GEM_PRICE})
	for i in ITEMS:
		var item := Items.roll(level, "", "rare" if randf() < RARE_CHANCE else "magic")
		offers.append({"item": item, "price": Items.sell_price(item) * ITEM_MARKUP})
	return offers


## Oferta wczytana z zapisu (zły wpis - pusty słownik).
static func normalize(raw) -> Dictionary:
	if not raw is Dictionary or int(raw.get("price", 0)) <= 0:
		return {}
	if raw.has("gem") and Gems.valid(raw.gem):
		return {"gem": raw.gem, "price": int(raw.price)}
	if raw.has("item"):
		var item := Items.normalize(raw.item)
		if not item.is_empty():
			return {"item": item, "price": int(raw.price)}
	return {}


## Łup oferty w postaci jak ProtoLoot (do nazwy, koloru i ikony).
static func loot_of(offer: Dictionary) -> Dictionary:
	return {"gem": offer.gem} if offer.has("gem") else offer.item

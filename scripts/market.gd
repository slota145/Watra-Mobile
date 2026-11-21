class_name Market
## Symulowany rynek - targ w bazie (ROADMAP punkt 5, ankieta z autorem 20.11.2026; wzór: rynek Watry
## `../Watra/scripts/market.gd`, ale bez złota - handel wymienny jak w Path of Exile). Niedostępny dla postaci SSF.
## Pieniądzem jest Runa Szlifu: każda cena podana jest w Szlifach (droższe pokazane też w Runach Zmiany). Płacić można
## też innymi runami - Game.market_pay bierze najpierw Szlify, potem inne runy po cenie skupu (reszta w Szlifach).
## Dwie części:
## - Giełda (COMMODITIES): runy, ruda, odpryski, klucze, dłuta i Pieczęć Oręża w paczkach (`pack` sztuk); cena każdej
##   błądzi wokół ceny bazowej (`base`), kupno po cenie z narzutem (ASK), sprzedaż po cenie skupu (BID) minus opłata
##   targowa TAX. Duże ruchy gracza lekko przesuwają cenę (PUSH).
## - Oferty (listings): przedmioty, kamienie i talizmany wystawione przez „innych graczy” (imiona i nicki - NAMES) z ceną
##   wokół uczciwej (`fair_price`, PRICE_SPREAD); okazje szybko znikają, przepłacone wiszą długo. Gracz wystawia też
##   własne przedmioty z torby i kamienie z sakwy (`mine`, cena do wyboru); sprzedane - Szlify od razu (minus TAX)
##   i wpis w wiadomościach (`news`).
## Czas rynku: chwila (`tick`) co TICK s czasu rzeczywistego - także gdy gra jest wyłączona (offline najwyżej
## OFFLINE_MAX s, cofnięcie zegara nic nie daje); nadrabia Game.market_catch_up przy wejściu do bazy i otwarciu targu.
## Stan (słownik) trzyma i zapisuje Game.market; tu tylko dane i czyste funkcje.

const TICK := 600.0
const OFFLINE_MAX := 12 * 3600.0
## Opłata targowa od sprzedaży (decyzja autora) i rozrzut kupna / skupu wokół ceny.
const TAX := 0.1
const ASK := 1.05
const BID := 0.95
## O tyle (ułamek) przesuwa cenę jedna paczka kupiona albo sprzedana przez gracza.
const PUSH := 0.03
## Błądzenie ceny w jednej chwili: losowo +-WALK, powrót do bazy z siłą PULL, granice wokół bazy.
const WALK := 0.06
const PULL := 0.08
const PRICE_LIMITS := Vector2(0.5, 2.0)
## Towary giełdy: cena bazowa paczki w Szlifach i wielkość paczki. Runa Szlifu to pieniądz - nie ma jej na giełdzie.
const COMMODITIES := {
	Runes.REFORGE: {"base": 2.0, "pack": 1},
	Runes.GROWTH: {"base": 3.0, "pack": 1},
	Runes.CHAOS: {"base": 5.0, "pack": 1},
	Runes.ASCEND: {"base": 6.0, "pack": 1},
	Runes.SEAL: {"base": 20.0, "pack": 1},
	"ore": {"base": 2.0, "pack": 10},
	"shards": {"base": 1.5, "pack": 10},
	Gems.KEY: {"base": 10.0, "pack": 1},
	Gems.CHISEL: {"base": 6.0, "pack": 1},
	Gems.WEAPON_SEAL: {"base": 25.0, "pack": 1},
}
const COMMODITY_ORDER: Array[String] = [Runes.REFORGE, Runes.GROWTH, Runes.CHAOS, Runes.ASCEND, Runes.SEAL, "ore", "shards",
		Gems.KEY, Gems.CHISEL, Gems.WEAPON_SEAL]
## Oferty innych graczy: ile naraz, ile nowych w chwili, cena względem uczciwej (losowo), szansa, że w chwili ktoś
## wykupi ofertę (okazje częściej), po ilu chwilach stara oferta znika.
const LISTINGS := 10
const NEW_LISTINGS := 3
const PRICE_SPREAD := Vector2(0.7, 1.4)
const STALE_TICKS := 24
## Oferty gracza: najwyżej MINE_MAX naraz; szansa sprzedaży w chwili SELL_CHANCE x (uczciwa / cena)^2, a powyżej
## OVERPRICED x uczciwej ceny nikt nie kupi (inaczej przedmiot za 999 Szlifów i tak sprzedałby się przez noc).
const MINE_MAX := 5
const SELL_CHANCE := 0.3
const OVERPRICED := 1.5
const NEWS_MAX := 6
## Imiona i nicki „innych graczy” (offline MMO).
const NAMES := ["Radomir", "Wiedzma_Ola", "Bogumił", "Mściwój", "Zbyszko_z_Ostoi", "Jagna", "Lutobor", "Dobrawa",
		"Wilczek", "Gromisław", "Swarożyc77", "Mokoszanka", "Bartek_Kowal", "Ziemowit", "Dziewanna", "Leszy_PL",
		"Rogatek", "Wojsław", "Miłka", "Siwobrody", "Kupała", "Żmijka", "Bolko", "Welesowy"]


## Nowy stan rynku: ceny bazowe, pierwsze oferty, czas teraz.
static func fresh(level: int, now: float) -> Dictionary:
	var state := {"prices": {}, "listings": [], "mine": [], "news": [], "time": now}
	for id in COMMODITY_ORDER:
		state.prices[id] = COMMODITIES[id].base
	for i in LISTINGS:
		state.listings.append(roll_listing(level))
	return state


## Stan wczytany z zapisu (zły - pusty słownik; wołający robi wtedy `fresh`).
static func normalize(raw) -> Dictionary:
	if not raw is Dictionary or not raw.get("prices") is Dictionary:
		return {}
	var state := {"prices": {}, "listings": [], "mine": [], "news": [], "time": float(raw.get("time", 0.0))}
	for id in COMMODITY_ORDER:
		var base: float = COMMODITIES[id].base
		state.prices[id] = clampf(float(raw.prices.get(id, base)), base * PRICE_LIMITS.x, base * PRICE_LIMITS.y)
	for key in ["listings", "mine"]:
		var list = raw.get(key, [])
		if list is Array:
			for entry in list:
				var l := _normalize_listing(entry)
				if not l.is_empty():
					state[key].append(l)
	var news = raw.get("news", [])
	if news is Array:
		for line in news.slice(0, NEWS_MAX):
			state.news.append(str(line))
	return state


static func _normalize_listing(raw) -> Dictionary:
	if not raw is Dictionary or int(raw.get("price", 0)) <= 0:
		return {}
	var loot = raw.get("loot", {})
	if not loot is Dictionary:
		return {}
	if loot.has("gem"):
		if not Gems.valid(loot.gem):
			return {}
	elif loot.has("talisman"):
		if not Talismans.is_talisman(loot.talisman):
			return {}
	else:
		loot = Items.normalize(loot)
		if loot.is_empty():
			return {}
	return {"loot": loot, "price": int(raw.price), "seller": str(raw.get("seller", "")), "age": int(raw.get("age", 0))}


# --- giełda ---

static func pack_of(id: String) -> int:
	return COMMODITIES[id].pack if COMMODITIES.has(id) else 1


## Ile Szlifów kosztuje paczka towaru `id` (kupno) przy cenie `price`. Runa nigdy taniej niż u kupca przy rozmianie
## (Runes.value_of) - inaczej kupno tu i rozmiana u kupca dawałyby Szlify z niczego.
static func ask(price: float, id := "") -> int:
	var out := maxi(1, roundi(price * ASK))
	return maxi(out, Runes.value_of(id)) if Runes.valid(id) else out


## Ile Szlifów dostaje gracz za paczkę (skup minus opłata targowa) przy cenie `price`. Runa nigdy drożej niż kupiec
## ją sprzedaje bez jednego Szlifu (Shop.buy_cost) - z tego samego powodu.
static func bid(price: float, id := "") -> int:
	var out := maxi(1, roundi(price * BID * (1.0 - TAX)))
	return mini(out, Shop.buy_cost(id) - 1) if Runes.valid(id) and id != Runes.POLISH else out


## Nazwa towaru giełdy.
static func name_of(id: String) -> String:
	match id:
		"ore":
			return Lang.t("Ruda żelaza")
		"shards":
			return Lang.t("Odpryski")
	return Runes.name_of(id) if Runes.valid(id) else Gems.name_of(id)


static func icon_of(id: String) -> Texture2D:
	match id:
		"ore":
			return preload("res://assets/watra/items/iron_ore.png")
		"shards":
			return preload("res://assets/watra/gems/emerald_1.png")
	return Runes.icon_of(id) if Runes.valid(id) else Gems.icon_of(id)


static func color_of(id: String) -> Color:
	match id:
		"ore":
			return Color(0.95, 0.6, 0.4)
		"shards":
			return Color(0.6, 0.9, 0.7)
	return Runes.color_of(id) if Runes.valid(id) else Gems.color_of(id)


## Cena w Szlifach jako napis; od 10 Szlifów dopisana w Runach Zmiany („23 Szlify (4 Zm. + 3)”).
static func price_text(szlif: int) -> String:
	var chaos := roundi(COMMODITIES[Runes.CHAOS].base)
	if szlif < 10:
		return Lang.t("%d Szl.") % szlif
	return Lang.t("%d Szl. (%d Zm. + %d)") % [szlif, szlif / chaos, szlif % chaos]


# --- oferty przedmiotów ---

## Uczciwa cena łupu w Szlifach: przedmiot wg rzadkości i poziomu lochu, kamień wg rodzaju i ulepszeń, talizman stała.
static func fair_price(loot: Dictionary) -> int:
	if loot.has("talisman"):
		return 12
	if loot.has("gem"):
		var id: String = loot.gem
		if Gems.is_special(id):
			return roundi(COMMODITIES.get(id, {"base": 8.0}).base)
		if Gems.is_unique(id):
			return 25
		if Gems.is_jewel(id):
			return 2 + 2 * Gems.level_of(id) + Gems.jewel_level(id) / 10
		return 1 + Gems.level_of(id)
	var mult: int = {"common": 1, "magic": 3, "rare": 8}.get(loot.get("rarity", "common"), 1)
	return maxi(1, roundi(mult * (1.0 + int(loot.get("level", 1)) / 20.0)))


## Nowa oferta „innego gracza”: przedmiot (najczęściej), kamień albo talizman z okolic poziomu `level`.
static func roll_listing(level: int) -> Dictionary:
	var lvl := maxi(1, level + randi_range(-2, 2))
	var r := randf()
	var loot: Dictionary
	if r < 0.6:
		loot = Items.roll(lvl, "", "", {"common": 10, "magic": 55, "rare": 35})
	elif r < 0.9 or lvl < Talismans.MIN_LEVEL:
		loot = {"gem": Gems.roll(maxi(lvl, Gems.MIN_LEVEL))}
	else:
		loot = {"talisman": Talismans.roll()}
	var price := maxi(1, roundi(fair_price(loot) * randf_range(PRICE_SPREAD.x, PRICE_SPREAD.y)))
	return {"loot": loot, "price": price, "seller": NAMES.pick_random(), "age": 0}


## Jak bardzo oferta jest okazją: uczciwa cena / cena (powyżej 1 - taniej niż uczciwie).
static func deal_of(listing: Dictionary) -> float:
	return float(fair_price(listing.loot)) / maxf(1.0, float(listing.price))


# --- czas rynku ---

## Jedna chwila rynku: ceny błądzą, oferty znikają (wykupione albo stare) i dochodzą nowe, oferty gracza mogą się
## sprzedać. Zwraca Szlify za sprzedane oferty gracza (już po opłacie targowej) - dopisuje je Game.
static func tick(state: Dictionary, level: int) -> int:
	for id in COMMODITY_ORDER:
		var base: float = COMMODITIES[id].base
		var p: float = state.prices[id]
		p *= 1.0 + randf_range(-WALK, WALK)
		p += (base - p) * PULL
		state.prices[id] = clampf(p, base * PRICE_LIMITS.x, base * PRICE_LIMITS.y)
	var keep: Array = []
	for l: Dictionary in state.listings:
		l.age += 1
		var bought := randf() < clampf(0.12 * pow(deal_of(l), 3.0), 0.02, 0.9)
		if not bought and l.age < STALE_TICKS:
			keep.append(l)
	state.listings = keep
	var add := 0
	while state.listings.size() < LISTINGS and add < NEW_LISTINGS:
		state.listings.append(roll_listing(level))
		add += 1
	var earned := 0
	var mine: Array = []
	for l: Dictionary in state.mine:
		l.age += 1
		if randf() < sell_chance(l):
			var got := maxi(1, floori(l.price * (1.0 - TAX)))
			earned += got
			_news(state, Lang.t("%s kupił(a): %s za %d Szl. (po opłacie %d)") % [NAMES.pick_random(),
					ProtoLoot.name_of(l.loot), l.price, got])
		else:
			mine.append(l)
	state.mine = mine
	return earned


## Szansa, że oferta gracza sprzeda się w jednej chwili rynku.
static func sell_chance(listing: Dictionary) -> float:
	if deal_of(listing) < 1.0 / OVERPRICED:
		return 0.0
	return minf(SELL_CHANCE * pow(deal_of(listing), 2.0), 0.95)


static func _news(state: Dictionary, line: String) -> void:
	state.news.push_front(line)
	if state.news.size() > NEWS_MAX:
		state.news.resize(NEWS_MAX)


## Ile chwil nadrobić od `then` do `now` (offline najwyżej OFFLINE_MAX; zegar cofnięty - zero).
static func ticks_between(then: float, now: float) -> int:
	if now <= then:
		return 0
	return int(minf(now - then, OFFLINE_MAX) / TICK)

class_name ShopWindow
extends BaseWindow
## Okno kupca w bazie - wymiana run (Shop.offers, ustalone z autorem 20.11.2026). W nagłówku liczba Run Szlifu
## (nimi się płaci). Trzy części: „Kup runę” (za Runy Szlifu), „Rozmień na Runy Szlifu” i „Klucz i dłuto”. Rząd oferty:
## ikona, nazwa (z liczbą sztuk), ile masz tego i czym się płaci, przycisk z ceną i ikoną runy (drugie stuknięcie
## wymienia - BaseWindow.confirm).

const BUY_SOUND := preload("res://assets/watra/handleCoins.ogg")
const SECTIONS := {"buy": "Kup runę za Runy Szlifu", "change": "Rozmień na Runy Szlifu", "gem": "Klucz i dłuto"}


func _build() -> void:
	title_label.text = tr("Kupiec")


func refresh() -> void:
	currency_icon.visible = true
	set_currency(Runes.icon_of(Runes.POLISH), int(_game.runes.get(Runes.POLISH, 0)))
	clear_content()
	var offers: Array = Shop.offers()
	var section := ""
	for i in offers.size():
		var offer: Dictionary = offers[i]
		if offer.kind != section:
			section = offer.kind
			label(content, tr(SECTIONS[section]), 13, GOLD)
		var box := row(Shop.icon_of(offer), Shop.color_of(offer).darkened(0.3))
		var col := text_column(box)
		var title := Shop.name_of(offer)
		if offer.count > 1:
			title = tr("%s x%d") % [title, offer.count]
		label(col, title, 14, Shop.color_of(offer), true)
		var have: int = _game.runes.get(offer.item, 0) if Runes.valid(offer.item) else _game.gem_count(offer.item)
		label(col, tr("Masz: %d") % have, 11, TEXT)
		label(col, tr("Płacisz: %s (masz %d)") % [Runes.name_of(offer.pay), int(_game.runes.get(offer.pay, 0))], 11, DIM, true)
		var b := price_button(box, "offer_%d" % i, offer.cost, Runes.icon_of(offer.pay), _game.shop_problem(i) == "")
		b.name = "Buy_%d" % i
		b.pressed.connect(_buy.bind(i))
	label(content, tr("Kurs run (w Runach Szlifu): kupiec sprzedaje półtora razy drożej, niż skupuje."), 11, DIM, true)


func _buy(index: int) -> void:
	if not confirm("offer_%d" % index):
		return
	if _game.buy_offer(index):
		play(BUY_SOUND)
	refresh()

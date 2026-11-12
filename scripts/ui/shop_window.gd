class_name ShopWindow
extends BaseWindow
## Okno kupca w bazie (Shop, półka w Game.shop): rząd na każdą ofertę - ikona, nazwa w kolorze rzadkości, opis
## (premie przedmiotu, działanie kamienia) i przycisk z ceną w złocie (drugie stuknięcie kupuje). Kamienie, klucze
## i dłuta idą do sakwy, przedmioty do torby (pełna torba - przycisk nieaktywny i napis). Pod listą: kiedy nowy towar.

const BUY_SOUND := preload("res://assets/watra/handleCoins.ogg")


func _build() -> void:
	title_label.text = tr("Kupiec")


func refresh() -> void:
	set_currency(COIN, _game.gold)
	clear_content()
	var offers: Array = _game.shop_offers()
	label(content, tr("Torba: %d / %d") % [_game.bag.size(), _game.BAG_SIZE], 12, DIM)
	for i in offers.size():
		var offer: Dictionary = offers[i]
		var loot := Shop.loot_of(offer)
		var box := row(ProtoLoot.icon_of(loot), ProtoLoot.color_of(loot).darkened(0.3))
		var col := text_column(box)
		label(col, ProtoLoot.name_of(loot), 14, ProtoLoot.color_of(loot), true)
		var lines: Array[String] = []
		if offer.has("gem"):
			lines = Gems.description(offer.gem)
		else:
			lines.append(Items.kind_line(offer.item))
			lines.append_array(Items.base_lines(offer.item))
			lines.append_array(Items.affix_lines(offer.item))
		for line in lines:
			label(col, line, 11, TEXT, true)
		var problem: String = _game.shop_problem(i)
		if problem == "bag":
			label(col, tr("Torba pełna"), 11, Color(1, 0.45, 0.35))
		var b := price_button(box, "offer_%d" % i, offer.price, COIN, problem == "")
		b.name = "Buy_%d" % i
		b.pressed.connect(_buy.bind(i))
	if offers.is_empty():
		label(content, tr("Półka pusta."), 14, TEXT)
	label(content, tr("Nowy towar po każdym pokonanym Wodzu."), 12, DIM, true)


func _buy(index: int) -> void:
	if not confirm("offer_%d" % index):
		return
	if _game.buy_offer(index):
		play(BUY_SOUND)
	refresh()

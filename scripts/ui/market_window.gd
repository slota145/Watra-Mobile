class_name MarketWindow
extends BaseWindow
## Okno targu w bazie (Market, ROADMAP punkt 5 - ustalone z autorem 20.11.2026). W nagłówku Runy Szlifu (pieniądz
## targu); na dole, pod kciukiem, zakładki „Giełda”, „Oferty”, „Moje” i „Wróć”. Na górze treści ostatnie wiadomości
## (np. kto kupił ofertę gracza) i ile gracz może wydać (Szlify + inne runy po cenie skupu - Game.market_wealth).
## - Giełda: rząd na towar (Market.COMMODITY_ORDER) - ikona, nazwa z paczką, ile masz, przyciski „Kup” i „Sprzedaj”
##   z ceną w Szlifach (bez potwierdzenia - małe kwoty, cena widać od razu).
## - Oferty: przedmioty, kamienie i talizmany innych graczy (sprzedawca, „Okazja!”), przycisk z ceną - drugie
##   stuknięcie kupuje (BaseWindow.confirm).
## - Moje: własne oferty (przycisk „Zdejmij”), a niżej rzeczy do wystawienia (torba, kamienie z sakwy) - stuknięcie
##   wybiera, cena przyciskami -/+ (od uczciwej ceny), „Wystaw”.
## Postać SSF widzi zamknięty targ. Otwarcie nadrabia czas rynku (Game.market_catch_up).

const TABS := ["exchange", "listings", "mine"]
const TAB_NAMES := {"exchange": "Giełda", "listings": "Oferty", "mine": "Moje"}
const BUY_SOUND := preload("res://assets/watra/handleCoins.ogg")
const DEAL := 1.15

var tab := "exchange"
var tab_buttons := {}
## Wybrana rzecz do wystawienia ({"bag": indeks} albo {"gem": identyfikator}; pusty - nic) i jej cena.
var pick := {}
var pick_price := 1


func _build() -> void:
	title_label.text = tr("Targ")
	footer.move_child(back_button, 0)
	for t in TABS:
		var b := button(footer, tr(TAB_NAMES[t]))
		b.name = "Tab_" + t
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(set_tab.bind(t))
		tab_buttons[t] = b
	footer.move_child(back_button, footer.get_child_count() - 1)


func open() -> void:
	_game.market_catch_up()
	pick = {}
	super.open()


func set_tab(t: String) -> void:
	tab = t
	armed = ""
	pick = {}
	refresh()
	scroll.scroll_vertical = 0


func refresh() -> void:
	currency_icon.visible = true
	set_currency(Runes.icon_of(Runes.POLISH), int(_game.runes.get(Runes.POLISH, 0)))
	clear_content()
	for t in tab_buttons:
		var b: Button = tab_buttons[t]
		b.visible = _game.market_open()
		b.add_theme_color_override("font_color", GOLD if t == tab else TEXT)
	if not _game.market_open():
		label(content, tr("Postać SSF handluje tylko sama ze sobą - targ jest dla niej zamknięty."), 14, TEXT, true)
		return
	if _game.market.is_empty():
		_game.market_catch_up()
	for line in _game.market.news.slice(0, 2):
		label(content, line, 11, Color(0.6, 1.0, 0.6), true)
	label(content, tr("Możesz wydać: %s (Szlify i inne runy po cenie skupu). Targ żyje także, gdy telefon leży.")
			% Market.price_text(_game.market_wealth()), 11, DIM, true)
	match tab:
		"exchange":
			_build_exchange()
		"listings":
			_build_listings()
		_:
			_build_mine()


# --- giełda ---

func _build_exchange() -> void:
	label(content, tr("Kupno i sprzedaż w paczkach; cena skupu już po opłacie targowej (%d%%).") % roundi(Market.TAX * 100),
			11, DIM, true)
	for id in Market.COMMODITY_ORDER:
		var price: float = _game.market.prices[id]
		var box := row(Market.icon_of(id), Market.color_of(id).darkened(0.3))
		var col := text_column(box)
		var title := Market.name_of(id)
		if Market.pack_of(id) > 1:
			title = tr("%s x%d") % [title, Market.pack_of(id)]
		label(col, title, 13, Market.color_of(id), true)
		var base: float = Market.COMMODITIES[id].base
		var trend := "↑" if price > base * 1.05 else ("↓" if price < base * 0.95 else "")
		label(col, tr("Masz: %d  %s") % [_game.market_have(id), trend], 11, TEXT)
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 2)
		box.add_child(buttons)
		var buy := button(buttons, tr("Kup %d") % Market.ask(price, id))
		buy.name = "Buy_" + id
		_coin(buy)
		buy.disabled = _game.market_wealth(id) < Market.ask(price, id)
		buy.pressed.connect(func() -> void:
			if _game.market_buy(id):
				play(BUY_SOUND, -8.0)
			refresh())
		var sell := button(buttons, tr("Sprzedaj %d") % Market.bid(price, id))
		sell.name = "Sell_" + id
		_coin(sell)
		sell.disabled = _game.market_have(id) < Market.pack_of(id)
		sell.pressed.connect(func() -> void:
			if _game.market_sell(id):
				play(BUY_SOUND, -8.0)
			refresh())


## Przycisk giełdy: ikona Runy Szlifu przy cenie, szerokość pod kciuk.
func _coin(b: Button) -> void:
	b.custom_minimum_size = Vector2(110, 44)
	b.icon = Runes.icon_of(Runes.POLISH)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 16)
	b.add_theme_font_size_override("font_size", 13)


# --- oferty innych graczy ---

func _build_listings() -> void:
	var listings: Array = _game.market.listings
	if listings.is_empty():
		label(content, tr("Na razie nikt nic nie wystawił - zajrzyj później."), 13, TEXT, true)
	for i in listings.size():
		var l: Dictionary = listings[i]
		var loot: Dictionary = l.loot
		var box := row(ProtoLoot.icon_of(loot), ProtoLoot.color_of(loot).darkened(0.3))
		var col := text_column(box)
		label(col, ProtoLoot.name_of(loot), 13, ProtoLoot.color_of(loot), true)
		var who := tr("Sprzedaje: %s") % l.seller
		if Market.deal_of(l) >= DEAL:
			who += "  " + tr("Okazja!")
		label(col, who, 11, Color(0.6, 1.0, 0.6) if Market.deal_of(l) >= DEAL else DIM)
		for line in _loot_lines(loot):
			label(col, line, 11, TEXT, true)
		var problem: String = _game.market_listing_problem(i)
		if problem == "bag":
			label(col, tr("Torba pełna"), 11, Color(1, 0.45, 0.35))
		var b := price_button(box, "listing_%d" % i, int(l.price), Runes.icon_of(Runes.POLISH), problem == "")
		b.name = "Listing_%d" % i
		b.pressed.connect(_buy_listing.bind(i))


func _buy_listing(index: int) -> void:
	if not confirm("listing_%d" % index):
		return
	if _game.market_buy_listing(index):
		play(BUY_SOUND)
	refresh()


## Opis łupu w ofercie (krótko): przedmiot - rodzaj i premie, kamień - działanie, talizman - nic więcej.
func _loot_lines(loot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if loot.has("gem"):
		lines.append_array(Gems.description(loot.gem).slice(0, 2))
	elif loot.has("talisman"):
		lines.append(tr("Talizman (duplikat podnosi poziom)"))
	else:
		lines.append(Items.kind_line(loot))
		lines.append_array(Items.affix_lines(loot))
	return lines


# --- moje oferty i wystawianie ---

func _build_mine() -> void:
	label(content, tr("Twoje oferty: %d / %d") % [_game.market.mine.size(), Market.MINE_MAX], 13, GOLD)
	for i in _game.market.mine.size():
		var l: Dictionary = _game.market.mine[i]
		var box := row(ProtoLoot.icon_of(l.loot), ProtoLoot.color_of(l.loot).darkened(0.3))
		var col := text_column(box)
		label(col, ProtoLoot.name_of(l.loot), 13, ProtoLoot.color_of(l.loot), true)
		label(col, tr("Cena: %s (uczciwa: %d)") % [Market.price_text(int(l.price)), Market.fair_price(l.loot)], 11, TEXT, true)
		var b := button(box, tr("Zdejmij"))
		b.name = "Unlist_%d" % i
		b.custom_minimum_size = Vector2(90, 44)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.pressed.connect(func() -> void:
			_game.market_unlist(i)
			refresh())
	if not pick.is_empty():
		_build_pick()
	label(content, tr("Wystaw (stuknij rzecz):"), 13, GOLD)
	for i in _game.bag.size():
		_offer_row({"bag": i}, _game.bag[i])
	for id in _game.gem_list():
		if Gems.can_shatter(id):
			_offer_row({"gem": id}, {"gem": id})
	if _game.bag.is_empty() and _game.gem_list().is_empty():
		label(content, tr("Torba i sakwa są puste."), 12, DIM)


func _offer_row(source: Dictionary, loot: Dictionary) -> void:
	var box := row(ProtoLoot.icon_of(loot), ProtoLoot.color_of(loot).darkened(0.3))
	var col := text_column(box)
	var title := ProtoLoot.name_of(loot)
	if source.has("gem") and _game.gem_count(source.gem) > 1:
		title = tr("%s x%d") % [title, _game.gem_count(source.gem)]
	label(col, title, 12, ProtoLoot.color_of(loot), true)
	label(col, tr("Uczciwa cena: %d Szl.") % Market.fair_price(loot), 11, DIM)
	var b := button(box, tr("Wybierz"))
	b.name = "Pick_" + (str(source.bag) if source.has("bag") else source.gem)
	b.custom_minimum_size = Vector2(90, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(func() -> void:
		pick = source
		pick_price = Market.fair_price(loot)
		refresh()
		scroll.scroll_vertical = 0)


## Wybrana rzecz: cena -/+ i „Wystaw”.
func _build_pick() -> void:
	var loot: Dictionary = _game.bag[pick.bag] if pick.has("bag") and pick.bag < _game.bag.size() else {"gem": pick.get("gem", "")}
	if loot.has("gem") and _game.gem_count(loot.gem) <= 0:
		pick = {}
		return
	var box := row(ProtoLoot.icon_of(loot), GOLD)
	var col := text_column(box)
	label(col, ProtoLoot.name_of(loot), 13, ProtoLoot.color_of(loot), true)
	label(col, tr("Cena: %s, dostaniesz %d po opłacie") % [Market.price_text(pick_price),
			maxi(1, floori(pick_price * (1.0 - Market.TAX)))], 11, TEXT, true)
	if pick_price > Market.fair_price(loot) * Market.OVERPRICED:
		label(col, tr("Za drogo - nikt tego nie kupi (uczciwa cena: %d).") % Market.fair_price(loot), 11, Color(1, 0.45, 0.35), true)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 4)
	content.add_child(steps)
	for d in [-5, -1, 1, 5]:
		var b := button(steps, ("%+d" % d))
		b.name = "Price_%d" % d
		b.pressed.connect(func() -> void:
			pick_price = maxi(1, pick_price + d)
			refresh())
	var list := button(content, tr("Wystaw za %d Szl.") % pick_price)
	list.name = "List"
	list.disabled = _game.market.mine.size() >= Market.MINE_MAX
	list.pressed.connect(func() -> void:
		var ok: bool = _game.market_list(pick_price, pick.bag, "") if pick.has("bag") \
				else _game.market_list(pick_price, -1, pick.gem)
		if ok:
			play(BUY_SOUND, -6.0)
		pick = {}
		refresh())

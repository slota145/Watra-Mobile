class_name UpgradesWindow
extends BaseWindow
## Okno ulepszeń lochów za złoto (DungeonUpgrades, stan w Game.upgrades): rząd na każde ulepszenie - ikona,
## nazwa, stopień i obecna premia, następny stopień i przycisk z ceną w złocie (drugie stuknięcie kupuje).
## Otwiera je przycisk „Ulepszenia lochów” w wyborze poziomu przy Watrze.

const BUY_SOUND := preload("res://assets/watra/handleCoins.ogg")


func _build() -> void:
	title_label.text = tr("Ulepszenia lochów")
	var hint := label(content, tr("Złoto wzmacnia wszystkie lochy."), 12, DIM, true)
	hint.name = "Hint"


func refresh() -> void:
	set_currency(COIN, _game.gold)
	for c in content.get_children():
		if c.name != "Hint":
			content.remove_child(c)
			c.queue_free()
	for id in DungeonUpgrades.ORDER:
		var steps: int = _game.upgrade_steps(id)
		var box := row(DungeonUpgrades.icon_of(id), Color(0.6, 0.35, 0.12))
		var col := text_column(box)
		label(col, DungeonUpgrades.name_of(id), 15, GOLD)
		var now := DungeonUpgrades.text(id, steps) if steps > 0 else tr("jeszcze brak")
		label(col, tr("Stopień %d/%d: %s") % [steps, DungeonUpgrades.MAX_STEPS, now], 12, TEXT, true)
		var price: int = _game.upgrade_price(id)
		if price > 0:
			label(col, tr("Następny: %s") % DungeonUpgrades.text(id, steps + 1), 12, Color(1, 0.7, 0.35), true)
			var b := price_button(box, id, price, COIN, _game.gold >= price)
			b.name = "Buy_" + id
			b.pressed.connect(_buy.bind(id))
		else:
			label(col, tr("Najwyższy stopień"), 12, Color(0.6, 1, 0.6))


func _buy(id: String) -> void:
	if not confirm(id):
		return
	if _game.buy_upgrade(id):
		play(BUY_SOUND)
	refresh()

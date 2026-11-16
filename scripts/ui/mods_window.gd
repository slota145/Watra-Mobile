class_name ModsWindow
extends BaseWindow
## Okno modyfikatorów lochów (DungeonMods) z wyboru poziomu przy Watrze: rząd na każdy modyfikator - nazwa, co utrudnia
## (czerwono), co daje (zielono) i duży przełącznik „Włącz” / „Włączony”. Wybór od razu w Game.dungeon_mods (zapis);
## działa od DungeonMods.FROM_LEVEL. Po zamknięciu wraca wybór poziomu (sygnał `closed`).

const ON := Color(0.6, 1.0, 0.6)
const COST := Color(1.0, 0.55, 0.45)


func _build() -> void:
	title_label.text = tr("Modyfikatory lochów")
	currency_icon.visible = false
	currency_label.visible = false


func refresh() -> void:
	clear_content()
	label(content, tr("Każdy modyfikator utrudnia loch i daje lepsze nagrody. Działają od poziomu %d.") % DungeonMods.FROM_LEVEL,
			12, DIM, true)
	for id: String in DungeonMods.ORDER:
		var data: Dictionary = DungeonMods.DATA[id]
		var on: bool = _game.dungeon_mods.has(id)
		var box := row(null, data["color"] if on else Color(0.35, 0.28, 0.22))
		box.get_child(0).visible = false  # bez ikony - więcej miejsca na opis
		var col := text_column(box)
		label(col, DungeonMods.name_of(id), 15, data["color"] if on else GOLD)
		label(col, Lang.t(data["cost"]), 12, COST, true)
		label(col, Lang.t(data["reward"]), 12, ON, true)
		var b := button(box, tr("Włączony") if on else tr("Włącz"))
		b.name = "Toggle_" + id
		b.custom_minimum_size = Vector2(92, 48)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if on:
			b.add_theme_color_override("font_color", ON)
		b.pressed.connect(toggle.bind(id))


## Włącza albo wyłącza modyfikator i zapisuje wybór.
func toggle(id: String) -> void:
	if _game.dungeon_mods.has(id):
		_game.dungeon_mods.erase(id)
	else:
		_game.dungeon_mods.append(id)
	_game.save_game()
	refresh()

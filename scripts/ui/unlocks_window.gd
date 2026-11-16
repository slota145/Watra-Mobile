class_name UnlocksWindow
extends BaseWindow
## Okno „Drabinka odblokowań” (Unlocks): wszystkie progi po kolei - ikona, „Poziom N” i co się odblokowuje.
## Odblokowane (przebity poziom - Game.best_level) jasne z zielonym „odblokowane”, następny próg wyróżniony złotą
## ramką i napisem „następne”, dalsze przygaszone. Otwiera je przycisk „Drabinka odblokowań” w wyborze poziomu przy Watrze; po
## zamknięciu wybór wraca (sygnał `closed`). Przewija się do następnego progu.

const NEXT := Color(1.0, 0.8, 0.35)

## Rząd pierwszego wpisu następnego progu (okno przewija się do niego).
var _next_row: Control


func _build() -> void:
	title_label.text = tr("Drabinka odblokowań")
	currency_icon.visible = false
	currency_label.visible = false


func refresh() -> void:
	clear_content()
	_next_row = null
	var best: int = _game.best_level
	var next: Array = Unlocks.next_after(best)
	var next_beat: int = next[0].beat if not next.is_empty() else -1
	label(content, tr("Pokonaj bossa na poziomie, żeby odkryć nowości głębiej."), 12, DIM, true)
	for e: Dictionary in Unlocks.all():
		var done: bool = e.beat <= best
		var is_next: bool = e.beat == next_beat
		var color: Color = Unlocks.KINDS_COLOR[e.kind]
		var box := row(e.icon, NEXT if is_next else (color.darkened(0.4) if done else Color(0.3, 0.25, 0.2)))
		if is_next and _next_row == null:
			_next_row = box.get_parent()
		if not done:
			box.get_child(0).modulate = Color(0.45, 0.45, 0.45)
		var col := text_column(box)
		var head := tr("Poziom %d") % e.level
		if e.kind == "weapon":
			head = tr("Po bossie poziomu %d") % e.beat
		if done:
			head = tr("%s - odblokowane") % head
		elif is_next:
			head = tr("%s - następne") % head
		label(col, head, 12, NEXT if is_next else (Color(0.6, 1, 0.6) if done else DIM))
		label(col, e.text, 14, color if done or is_next else Color(0.7, 0.65, 0.6), true)


func open() -> void:
	super()
	await get_tree().process_frame
	if _next_row and is_instance_valid(_next_row):
		scroll.ensure_control_visible(_next_row)

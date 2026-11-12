class_name SafeArea
extends MarginContainer
## Kontener, który trzyma interfejs z dala od wcięcia aparatu, zaokrąglonych rogów i paska gestów telefonu.
## Wstaw go jako pierwszy węzeł interfejsu (na cały ekran), a przyciski i paski wkładaj do środka.
## Na komputerze bezpieczny obszar to całe okno, więc marginesy są zerowe (chyba że ustawisz `extra`).

## Dodatkowy odstęp od krawędzi w pikselach gry (na każdej stronie).
@export var extra := 4


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_update)
	_update()


## Przelicza bezpieczny obszar ekranu (piksele telefonu) na piksele gry i ustawia marginesy.
func _update() -> void:
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var view := get_viewport_rect().size
	var margins := [0.0, 0.0, 0.0, 0.0]  # lewo, góra, prawo, dół
	if OS.has_feature("mobile") and screen.x > 0.0 and safe.size.x > 0.0:
		var scale := view.x / screen.x
		margins = [safe.position.x * scale, safe.position.y * scale,
			(screen.x - safe.end.x) * scale, (screen.y - safe.end.y) * scale]
	for i in 4:
		add_theme_constant_override(["margin_left", "margin_top", "margin_right", "margin_bottom"][i],
			int(ceil(margins[i])) + extra)

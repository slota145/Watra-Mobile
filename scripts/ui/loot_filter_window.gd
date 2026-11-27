class_name LootFilterWindow
extends BaseWindow
## Okno „Filtr łupu” (ankieta autora 21.11.2026) - z pauzy (też w lochu) i z torby okna „Postać”. Ustawienia
## (LootFilter, `Game.loot_filter`) zapisują się w zapisie postaci przy zamknięciu.
## Nad przewijaną treścią: przełączniki „Filtr” i „Automat” oraz rząd miejsc (Wszystkie + 6 miejsc; kropka -
## miejsce ma własne ustawienia). Zakładki na dole, pod kciukiem: „Zasady” (własne ustawienia miejsca, rozbijane
## rzadkości, próg stopnia, ile premii z listy, bezpiecznik - wspólny) i „Premie” (lista premii do zachowania
## w grupach; „A” - premia dodana przez Automat). Nie zmienia pauzy: zostawia ją taką, jaka była przy otwarciu.

const RARITY_SHORT := {"common": "Zwykłe", "magic": "Magiczne", "rare": "Rzadkie"}
const ON_COLOR := Color(0.55, 1.0, 0.55)
const OWN_COLOR := Color(1.0, 0.6, 0.25)
const SLOT_BUTTON := 44

## Zakładka ("rules" albo "stats") i wybrane miejsce ("all" albo z Items.SLOTS).
var tab := "rules"
var slot := "all"
var on_toggle: CheckButton
var auto_toggle: CheckButton
var slot_buttons := {}
var tab_buttons := {}
var _was_paused := false


func _build() -> void:
	title_label.text = tr("Filtr łupu")
	(get_child(0) as ColorRect).color.a = 0.92  # okno pauzy pod spodem nie prześwituje
	var column := scroll.get_parent()
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	column.add_child(top)
	column.move_child(top, scroll.get_index())
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 6)
	top.add_child(toggles)
	on_toggle = _switch(toggles, tr("Filtr"))
	on_toggle.toggled.connect(func(on: bool) -> void:
		_game.loot_filter.on = on
		refresh())
	auto_toggle = _switch(toggles, tr("Automat"))
	auto_toggle.toggled.connect(func(on: bool) -> void:
		_game.loot_filter.auto = on
		refresh())
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 2)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(slots)
	for key in ["all"] + Items.SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(SLOT_BUTTON, SLOT_BUTTON)
		if key == "all":
			b.text = tr("Wsz.")
			b.add_theme_font_size_override("font_size", 11)
		else:
			b.icon = Items.slot_icon(key)
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dot := ColorRect.new()
		dot.name = "Own"
		dot.color = OWN_COLOR
		dot.size = Vector2(7, 7)
		dot.position = Vector2(SLOT_BUTTON - 10, 3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
		b.pressed.connect(func() -> void:
			slot = key
			armed = ""
			refresh()
			scroll.scroll_vertical = 0)
		slots.add_child(b)
		slot_buttons[key] = b
	for t in ["rules", "stats"]:
		var tb := button(footer, tr({"rules": "Zasady", "stats": "Premie"}[t]))
		tb.pressed.connect(func() -> void:
			tab = t
			refresh()
			scroll.scroll_vertical = 0)
		tab_buttons[t] = tb
	footer.move_child(back_button, footer.get_child_count() - 1)


func open() -> void:
	_was_paused = get_tree().paused
	super.open()


func close() -> void:
	visible = false
	get_tree().paused = _was_paused
	_game.save_game()
	closed.emit()


func refresh() -> void:
	var f: Dictionary = _game.loot_filter
	set_currency(ORE, _game.ore)
	on_toggle.set_pressed_no_signal(f.on)
	on_toggle.text = tr("Filtr: włączony") if f.on else tr("Filtr: wyłączony")
	auto_toggle.set_pressed_no_signal(f.auto)
	for key in slot_buttons:
		var b: Button = slot_buttons[key]
		b.get_node("Own").visible = key != "all" and f.slots[key].get("own", false)
		_look(b, key == slot)
	for t in tab_buttons:
		_look(tab_buttons[t], t == tab)
	clear_content()
	if not f.on:
		label(content, tr("Filtr wyłączony - wszystkie przedmioty trafiają do torby."), 12, DIM, true)
	if slot != "all":
		var own := _switch(content, tr("Własne ustawienia: %s") % Lang.t(Items.SLOT_NAMES[slot]))
		own.set_pressed_no_signal(f.slots[slot].own)
		own.toggled.connect(func(on: bool) -> void:
			if on:  # start z ustawień wspólnych
				var copy: Dictionary = f.slots.all.duplicate(true)
				copy["own"] = true
				f.slots[slot] = copy
			else:
				f.slots[slot].own = false
			refresh())
		if not f.slots[slot].own:
			label(content, tr("To miejsce używa ustawień „Wszystkie”. Włącz własne, żeby je zmienić."), 12, DIM, true)
	if tab == "rules":
		_rules_page(f)
	else:
		_stats_page(f)


## Zasady wybranego miejsca i bezpiecznik.
func _rules_page(f: Dictionary) -> void:
	var r: Dictionary = LootFilter.rules_for(f, slot)
	var editable: bool = slot == "all" or f.slots[slot].own
	if editable:
		label(content, tr("Rozbijaj przedmioty:"), 13, GOLD)
		var rar := HBoxContainer.new()
		rar.add_theme_constant_override("separation", 4)
		content.add_child(rar)
		for x in LootFilter.RARITIES:
			var b := button(rar, tr(RARITY_SHORT[x]))
			b.toggle_mode = true
			b.button_pressed = r.rarities.has(x)
			b.add_theme_color_override("font_color", Items.RARITY_COLORS[x] if r.rarities.has(x) else DIM.darkened(0.3))
			b.add_theme_color_override("font_pressed_color", Items.RARITY_COLORS[x])
			b.toggled.connect(func(on: bool) -> void:
				if on and not r.rarities.has(x):
					r.rarities.append(x)
				elif not on:
					r.rarities.erase(x)
				refresh())
			_look(b, r.rarities.has(x))
		var tiers: int = r.tier
		_stepper(tr("Próg stopnia premii"), _tier_text(f, r), func(d: int) -> void:
			var low := LootFilter.AUTO_TIER if f.auto else 1
			var t := maxi(int(r.tier), low)
			r.tier = clampi(t + d, low, Items.TIERS)
			refresh())
		_stepper(tr("Ile premii z listy"), str(r.count), func(d: int) -> void:
			r.count = clampi(int(r.count) + d, 1, LootFilter.MAX_COUNT)
			refresh())
		var tier := LootFilter.effective_tier(f, r, _game.dungeon_level)
		var listed: String = tr("z listy (zakładka „Premie”)") if not (r.stats.is_empty() and not f.auto) \
				else tr("dowolnych (lista jest pusta)")
		var t_text := tr("w dowolnym stopniu") if tier >= Items.TIERS else tr("w stopniu T%d lub lepszym") % tier
		label(content, Lang.n(int(r.count), "Zostaje przedmiot z co najmniej %d premią %s %s. Reszta zaznaczonych rzadkości rozbija się na rudę przy podniesieniu w lochu.",
				"Zostaje przedmiot z co najmniej %d premiami %s %s. Reszta zaznaczonych rzadkości rozbija się na rudę przy podniesieniu w lochu.",
				"Zostaje przedmiot z co najmniej %d premiami %s %s. Reszta zaznaczonych rzadkości rozbija się na rudę przy podniesieniu w lochu.") \
				% [int(r.count), listed, t_text], 11, DIM, true)
		if tiers == LootFilter.AUTO_TIER and f.auto:
			label(content, tr("Próg „Auto” rośnie z poziomem lochu: najlepszy dostępny stopień i dwa słabsze."), 11, DIM, true)
	label(content, tr("Kamienie szlachetne"), 13, GOLD)
	var js: int = int(f.get("jewel_stars", 0))
	_stepper(tr("Rozbijaj z oceną do"), tr("wyłączone") if js == 0 else Lang.n(js, "%d gwiazdki", "%d gwiazdek", "%d gwiazdek") % js,
			func(d: int) -> void:
				f.jewel_stars = clampi(js + d, 0, Gems.MAX_STARS - 1)
				refresh())
	label(content, tr("Słabsze kamienie szlachetne od razu zamieniają się na odpryski. Ocena (1-5 gwiazdek) - jak blisko najlepszych wartości są ich premie.") \
			if js > 0 else tr("Kamienie szlachetne trafiają do sakwy wszystkie."), 11, DIM, true)
	label(content, tr("Zawsze zachowuj (wszystkie miejsca)"), 13, GOLD)
	label(content, tr("Legendy i unikaty zostają zawsze."), 11, DIM, true)
	for key in ["safe_above", "safe_sockets", "upgrade"]:
		var text: String = {"safe_above": "Premia ponad widełki", "safe_sockets": "Dwa gniazda",
				"upgrade": "Lepsze od założonego (strzałka „lepszy”)"}[key]
		var s := _switch(content, tr(text))
		s.set_pressed_no_signal(f[key])
		s.toggled.connect(func(on: bool) -> void: f[key] = on)
	if f.auto:
		label(content, tr("Automat dokłada do listy premie pasujące do broni i założonych umiejętności (w zakładce „Premie” ze znaczkiem A) oraz zdrowie, obrażenia, ochronę i odporności. Twoje zaznaczenia i bezpiecznik zawsze wygrywają."), 11, DIM, true)


## Lista premii do zachowania w grupach (tylko premie, które mogą wypaść w tym miejscu).
func _stats_page(f: Dictionary) -> void:
	var r: Dictionary = LootFilter.rules_for(f, slot)
	var editable: bool = slot == "all" or f.slots[slot].own
	var auto: Array = LootFilter.auto_stats(_game.weapon, _game.skill_slots) if f.auto else []
	var head := HBoxContainer.new()
	content.add_child(head)
	var hint := label(head, tr("Zaznaczone: %d") % r.stats.size() if not r.stats.is_empty() \
			else tr("Pusta lista - liczy się każda premia."), 12, GOLD, true)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if editable and not r.stats.is_empty():
		var clear := button(head, tr("Wyczyść"))
		clear.size_flags_horizontal = Control.SIZE_SHRINK_END
		clear.custom_minimum_size.x = 96
		clear.pressed.connect(func() -> void:
			r.stats.clear()
			refresh())
	for g in LootFilter.GROUPS:
		var stats: Array = g[1].filter(func(s: String) -> bool: return slot == "all" or Items.affix_fits(s, slot))
		if stats.is_empty():
			continue
		label(content, tr(g[0]), 13, GOLD)
		for s in stats:
			var c := CheckBox.new()
			c.text = LootFilter.stat_name(s) + ("   A" if auto.has(s) and not r.stats.has(s) else "")
			c.custom_minimum_size = Vector2(0, 44)
			c.add_theme_font_size_override("font_size", 13)
			c.add_theme_color_override("font_color", TEXT if r.stats.has(s) else (ON_COLOR if auto.has(s) else DIM))
			c.button_pressed = r.stats.has(s)
			c.disabled = not editable
			c.toggled.connect(func(on: bool) -> void:
				if on and not r.stats.has(s):
					r.stats.append(s)
				elif not on:
					r.stats.erase(s)
				refresh())
			content.add_child(c)


## Próg stopnia słownie.
func _tier_text(f: Dictionary, r: Dictionary) -> String:
	var t := int(r.tier)
	if t == LootFilter.AUTO_TIER:
		return tr("Auto: T%d") % LootFilter.auto_tier(_game.dungeon_level) if f.auto else tr("Każdy")
	return tr("Każdy") if t >= Items.TIERS else tr("T%d i lepsze") % t


## Wiersz z nazwą i przyciskami „-” / „+” (pod palec) wokół wartości.
func _stepper(text: String, value: String, change: Callable) -> void:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 4)
	content.add_child(row_box)
	var l := label(row_box, text, 13, TEXT, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var minus := button(row_box, "-")
	minus.custom_minimum_size = Vector2(44, 44)
	minus.size_flags_horizontal = Control.SIZE_SHRINK_END
	minus.pressed.connect(change.bind(-1))
	var v := label(row_box, value, 14, GOLD)
	v.custom_minimum_size.x = 74
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var plus := button(row_box, "+")
	plus.custom_minimum_size = Vector2(44, 44)
	plus.size_flags_horizontal = Control.SIZE_SHRINK_END
	plus.pressed.connect(change.bind(1))


func _switch(parent: Control, text: String) -> CheckButton:
	var t := CheckButton.new()
	t.text = text
	t.custom_minimum_size = Vector2(0, 44)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 13)
	parent.add_child(t)
	return t


## Wybrany przycisk (miejsce, zakładka, rzadkość): złota ramka.
func _look(b: Button, active: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		if active:
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.26, 0.18, 0.1)
			st.border_color = GOLD
			st.set_border_width_all(2)
			st.set_corner_radius_all(5)
			st.set_content_margin_all(4)
			b.add_theme_stylebox_override(state, st)
		else:
			b.remove_theme_stylebox_override(state)

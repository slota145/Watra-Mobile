class_name TouchUi
## Czy stuknięcie trafia w interfejs (zgłoszenie autora 15.11.2026: przycisk „Postać” albo „Umiejętności” nad Watrą lub
## skrzynią otwierał to, co pod nim). Rzeczy w świecie, które reagują na dotyk w `_input` (Watra, skrzynie, kamień run,
## skrzynia po bossie), dostają zdarzenie przed przyciskami, więc pytają tu, czy pod palcem nie ma widocznej kontrolki,
## która łapie dotyk (MOUSE_FILTER_STOP). Arena dodaje warstwę interfejsu do grupy GROUP.

const GROUP := &"touch_ui"


## Czy w punkcie `pos` (współrzędne ekranu, jak InputEventScreenTouch.position) jest kontrolka interfejsu.
static func covers(tree: SceneTree, pos: Vector2) -> bool:
	for node in tree.get_nodes_in_group(GROUP):
		if _hit(node, pos):
			return true
	return false


static func _hit(node: Node, pos: Vector2) -> bool:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	if node is Control:
		var c := node as Control
		if c.mouse_filter == Control.MOUSE_FILTER_STOP and c.get_global_rect().has_point(pos):
			return true
	for child in node.get_children():
		if _hit(child, pos):
			return true
	return false


## Przewijanie palcem po całej liście (zgłoszenie autora 20.11.2026: lista przewijała się tylko w wąskich szczelinach
## między wierszami, bo wiersze i przyciski łapały dotyk dla siebie). Kontrolki w środku `scroll` (także dodawane później,
## np. przy odświeżeniu okna) dostają MOUSE_FILTER_PASS: stuknięcie nadal działa, a przeciągnięcie trafia do listy.
## Pasek przewijania robi się szerszy (SCROLLBAR_WIDTH), żeby dało się go złapać palcem.
const SCROLLBAR_WIDTH := 10.0


static func drag_scroll(scroll: ScrollContainer) -> void:
	scroll.get_v_scroll_bar().custom_minimum_size.x = SCROLLBAR_WIDTH
	_pass_all(scroll)
	var watch := func(n: Node) -> void:
		if is_instance_valid(scroll) and n is Control and not n is ScrollBar and scroll.is_ancestor_of(n):
			_pass_one(n as Control)
	scroll.tree_entered.connect(func() -> void:
		_pass_all(scroll)  # wiersze dodane, zanim lista trafiła na scenę
		scroll.get_tree().node_added.connect(watch))
	scroll.tree_exiting.connect(func() -> void: scroll.get_tree().node_added.disconnect(watch))
	if scroll.is_inside_tree():
		scroll.get_tree().node_added.connect(watch)


static func _pass_all(node: Node) -> void:
	for c in node.get_children(true):
		if c is ScrollBar:
			continue
		if c is Control:
			_pass_one(c as Control)
		_pass_all(c)


static func _pass_one(c: Control) -> void:
	if c.mouse_filter == Control.MOUSE_FILTER_STOP:
		c.mouse_filter = Control.MOUSE_FILTER_PASS

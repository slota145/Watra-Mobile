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

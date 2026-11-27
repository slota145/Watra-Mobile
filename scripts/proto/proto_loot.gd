class_name ProtoLoot
extends Node2D
## Przedmiot na ziemi w lochu (z goblina albo ze skrzyni Wodza). Wyskakuje łukiem, leży z poświatą w kolorze rzadkości
## (rzadki - dodatkowo słup światła, żeby było go widać z daleka), a gdy postać podejdzie bliżej niż `magnet`, leci do niej
## i trafia do torby (`Game.add_item`, sygnał `picked`). Przy pełnej torbie odskakuje, pokazuje „Torba pełna!”
## i czeka, aż postać odejdzie i wróci (można zrobić miejsce w oknie „Postać” w pauzie). Łup ze skrzyni Wodza
## (`sell_if_full`) przy pełnej torbie rozbija się od razu na rudę, żeby nie przepadł po oknie zwycięstwa.
## Przedmiot, którego nie chce filtr łupu (LootFilter, `Game.loot_filter`), od razu rozbija się na rudę.
## Arena pokazuje powiadomienie o każdym podniesionym i rozbitym przedmiocie (sygnały `picked`, `scrapped`).
## Kamień, klucz albo dłuto (Gems) to łup w postaci {"gem": identyfikator}: zawsze trafia do sakwy (`Game.add_gem`,
## bez limitu), świeci kolorem kamienia. Kamień aury ({"aura": identyfikator}, Auras) od razu uczy aury albo podnosi
## jej poziom (`Game.add_aura`, napis nad postacią), świeci jak rzadki; talizman ({"talisman": id}, Talismans) - tak samo
## (`Game.add_talisman`); runa ({"rune": id}, Runes) trafia do zapasu run (`Game.add_rune`); nazwę, kolor i ikonę
## każdego łupu dają `name_of`, `color_of`, `icon_of`. Klucz do Gniazda Żmija ({"zmij_key": poziom lochu}, Pinnacles)
## trafia do `Game.zmij_keys`, a przy wypadnięciu świeci jak legenda (słup, napis na środku ekranu, strzałka przy krawędzi).
## Pokaz łupu (krok 4 przebudowy przedmiotów, ankieta autora 21.11.2026): słupy światła rosnąco według rzadkości
## (BEAMS: rzadki niski, legendarny i unikat wysokie z iskrami, unikat pulsuje; anielski - jasny słup z aureolą),
## błysk i migająca gwiazdka przy premii ponad widełki, dźwięki z Watry (DROP_SOUNDS, PICKUP_SOUNDS), zielona strzałka
## „lepszy” nad przedmiotem silniejszym od założonego (Items.is_upgrade). Legenda i unikat: napis na środku ekranu
## i wibracja (grupa ANNOUNCE - arena `announce_loot`) oraz strzałka przy krawędzi ekranu, gdy leżą poza kadrem
## (grupa GoalArrows.GROUP: `goal_active`, `goal_icon`, `goal_color`).

signal picked(item: Dictionary)
## Przedmiot rozbity od razu: filtr łupu (LootFilter) albo pełna torba (`bag_full`, łup ze skrzyni);
## `got` - {"ore", "rune"} jak Game.dismantle.
signal scrapped(item: Dictionary, got: Dictionary, bag_full: bool)

const MAGNET := 36.0
const PICKUP := 6.0
## Ikony z Watry mają 64 px - na ziemi zmniejszone.
const ICON_SCALE := 0.32
const SOUND := preload("res://assets/watra/handleSmallLeather.ogg")
const SOUND_RARE := preload("res://assets/watra/glass_002.ogg")
const DROP_SOUND := preload("res://assets/watra/dropLeather.ogg")
const LEGEND_DROP := preload("res://assets/watra/legendary_drop.ogg")
const LEGEND_PICKUP := preload("res://assets/watra/legendary_pickup.ogg")
const UNIQUE_JINGLE := preload("res://assets/watra/jingles_PIZZI01.ogg")
## Grupa, której węzeł (arena) dostaje `announce_loot(item)` przy wypadnięciu legendy albo unikatu.
const ANNOUNCE := "loot_announce"
## Słupy światła: wysokość, szerokość, iskry, pulsowanie.
const BEAMS := {"rare": [34.0, 6.0, false, false], "legendary": [70.0, 8.0, true, false], "unique": [76.0, 9.0, true, true]}
const ARROW_COLOR := Color(0.45, 1.0, 0.45)
const VIBRATE_MS := 90

var hero: ProtoHero
var item: Dictionary = {}
var magnet := MAGNET
var spread := 12.0
## Przez tyle sekund po wypadnięciu przedmiot leży (wysyp ze skrzyni).
var delay := 0.0
## Przy pełnej torbie rozbij od razu (łup ze skrzyni).
var sell_if_full := false

var _sprite: Sprite2D
var _glow: Sprite2D
var _time := randf() * 10.0
var _pulled := false
var _speed := 0.0
var _taken := false
## Po nieudanym podniesieniu (pełna torba) czeka, aż postać się oddali.
var _blocked := false
var _game: Node
## Strzałka przy krawędzi ekranu (GoalArrows) - tylko legenda i unikat.
var goal_icon: Texture2D
var goal_color := Color.WHITE
var _better := false
var _arrow: _Arrow


## Nazwa łupu (przedmiot albo kamień).
static func name_of(loot: Dictionary) -> String:
	if loot.has(Pinnacles.KEY):
		return Pinnacles.key_name(int(loot[Pinnacles.KEY]))
	if loot.has("aura"):
		return Lang.t("Kamień aury: %s") % Auras.name_of(loot.aura)
	if loot.has("talisman"):
		return Lang.t("Talizman: %s") % Talismans.name_of(loot.talisman)
	if loot.has("rune"):
		return Runes.name_of(loot.rune)
	return Gems.name_of(loot.gem) if loot.has("gem") else Items.name_of(loot)


static func color_of(loot: Dictionary) -> Color:
	if loot.has(Pinnacles.KEY):
		return Pinnacles.KEY_COLOR
	if loot.has("aura"):
		return Auras.color_of(loot.aura)
	if loot.has("talisman"):
		return Talismans.color_of(loot.talisman)
	if loot.has("rune"):
		return Runes.color_of(loot.rune)
	return Gems.color_of(loot.gem) if loot.has("gem") else Items.color_of(loot)


static func icon_of(loot: Dictionary) -> Texture2D:
	if loot.has(Pinnacles.KEY):
		return Pinnacles.KEY_ICON
	if loot.has("aura"):
		return Auras.icon_of(loot.aura)
	if loot.has("talisman"):
		return Talismans.icon_of(loot.talisman)
	if loot.has("rune"):
		return Runes.icon_of(loot.rune)
	return Gems.icon_of(loot.gem) if loot.has("gem") else Items.icon_of(loot)


## Rzadkość do poświaty: kamienie świecą jak magiczne, klucz i dłuto - jak rzadkie (ze słupem światła).
func _rarity() -> String:
	if item.has(Pinnacles.KEY):
		return "legendary"
	if item.has("aura") or item.has("talisman"):
		return "rare"
	if item.has("rune"):
		return "rare" if Runes.is_rare(item.rune) else "magic"
	if item.has("gem"):
		return "rare" if Gems.is_special(item.gem) else "magic"
	return item.rarity


func _ready() -> void:
	_game = get_node("/root/Game")
	var color := color_of(item)
	_glow = Sprite2D.new()
	_glow.texture = ProtoWatra._glow_texture()
	_glow.scale = Vector2.ONE * (0.3 if _rarity() == "common" else (0.5 if _rarity() == "magic" else 0.45))
	_glow.modulate = Color(color, 0.35 if _rarity() == "common" else 0.6)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	add_child(_glow)
	var angelic := _is_item() and Items.is_angelic(item)
	if BEAMS.has(_rarity()) or angelic:
		var beam := _Beam.new()
		var look: Array = BEAMS.get(_rarity(), BEAMS.rare)
		if angelic:
			look = BEAMS.legendary.duplicate()
			beam.color = Items.ANGELIC_COLOR
			beam.halo = true
		elif _rarity() in ["legendary", "unique"]:
			beam.color = Items.RARITY_COLORS[_rarity()]
		beam.height = look[0]
		beam.width = look[1]
		beam.sparks = look[2]
		beam.pulse = look[3]
		add_child(beam)
	if _is_item() and Items.has_above(item):
		var star := _Star.new()
		star.color = Items.ANGELIC_COLOR if angelic else Items.ABOVE_COLOR
		add_child(star)
	_sprite = Sprite2D.new()
	_sprite.texture = icon_of(item)
	_sprite.scale = Vector2.ONE * (0.6 if item.has("aura") else ICON_SCALE * (0.75 if item.has("gem") or item.has("rune") or item.has(Pinnacles.KEY) else 1.0))
	add_child(_sprite)
	var land := position + Vector2(randf_range(-spread, spread), randf_range(-spread * 0.3, spread * 0.5))
	_sprite.position.y = -14.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", land, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "position:y", -7.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	_play(DROP_SOUND, -10.0)
	_show_off()


## Przedmiot (nie kamień, runa, aura ani talizman).
func _is_item() -> bool:
	return item.has("rarity") and item.has("slot")


## Pokaz łupu przy wypadnięciu: dźwięk rzadkości, strzałka „lepszy”, przy legendzie i unikacie napis, wibracja
## i strzałka przy krawędzi ekranu.
func _show_off() -> void:
	if item.has(Pinnacles.KEY):
		_play(LEGEND_DROP, -4.0, 0.8)
		goal_icon = icon_of(item)
		goal_color = Pinnacles.KEY_COLOR
		add_to_group(GoalArrows.GROUP)
		get_tree().call_group(ANNOUNCE, "announce_loot", item)
		Input.vibrate_handheld(VIBRATE_MS)
		return
	if not _is_item():
		return
	var r: String = item.rarity
	if r == "rare":
		_play(SOUND_RARE, -12.0, 1.35)
	elif r in ["legendary", "unique"]:
		_play(LEGEND_DROP, -4.0, 1.0)
		if r == "unique":
			_play(UNIQUE_JINGLE, -8.0, 1.0)
		goal_icon = icon_of(item)
		goal_color = Items.color_of(item)
		add_to_group(GoalArrows.GROUP)
		get_tree().call_group(ANNOUNCE, "announce_loot", item)
		Input.vibrate_handheld(VIBRATE_MS)
	refresh_better()
	_game.inventory_changed.connect(refresh_better)  # założony inny przedmiot - strzałka od nowa


## Strzałka „lepszy”: przedmiot silniejszy od założonego w tym miejscu (Items.is_upgrade; puste miejsce - zawsze).
func refresh_better() -> void:
	_better = _is_item() and not _taken and Items.is_upgrade(item, _game.equipped.get(item.slot, {}))
	if _better and _arrow == null:
		_arrow = _Arrow.new()
		add_child(_arrow)
	if _arrow:
		_arrow.visible = _better


## Czy strzałka „lepszy” jest pokazana (testy).
func is_better() -> bool:
	return _better


## Strzałka przy krawędzi ekranu (GoalArrows): póki leży.
func goal_active() -> bool:
	return not _taken


func _process(delta: float) -> void:
	_time += delta
	delay -= delta
	_glow.modulate.a = (0.3 if _rarity() == "common" else 0.5) + 0.12 * sin(_time * 5.0)
	if _taken or hero == null or hero.dead:
		return
	var target := hero.global_position + Vector2(0, -6)
	var to := target - global_position
	if _blocked:
		if to.length() > magnet * 1.6:
			_blocked = false
		return
	if not _pulled and delay <= 0.0 and to.length() <= magnet:
		_pulled = true
		_speed = 40.0
	if _pulled:
		_speed += 400.0 * delta
		global_position += to.normalized() * minf(_speed * delta, to.length())
		if to.length() <= PICKUP:
			_take()
	else:
		_sprite.position.y = -7.0 - 1.5 * (0.5 + 0.5 * sin(_time * 3.0))


func _take() -> void:
	var got := {}
	var bag_full := false
	if item.has("talisman"):
		var tl: int = _game.add_talisman(item.talisman)
		var tname := Talismans.name_of(item.talisman)
		if tl == 1:
			_float_text(tr("Nowy talizman: %s!") % tname, Talismans.color_of(item.talisman))
		elif tl > 1:
			_float_text(tr("%s - poziom %d!") % [tname, tl], Talismans.color_of(item.talisman))
		else:
			_float_text(tr("%s - już najwyższy poziom") % tname, Color(0.8, 0.75, 0.7))
	elif item.has("aura"):
		var lvl: int = _game.add_aura(item.aura)
		if lvl == 1:
			_float_text(tr("Nowa aura: %s!") % Auras.name_of(item.aura), Auras.color_of(item.aura))
		elif lvl > 1:
			_float_text(tr("%s - poziom %d!") % [Auras.name_of(item.aura), lvl], Auras.color_of(item.aura))
		else:
			_float_text(tr("%s - już najwyższy poziom") % Auras.name_of(item.aura), Color(0.8, 0.75, 0.7))
	elif item.has(Pinnacles.KEY):
		_game.add_zmij_key(int(item[Pinnacles.KEY]))
		_float_text(tr("Klucz do Gniazda Żmija!"), Pinnacles.KEY_COLOR)
	elif item.has("gem") and LootFilter.jewel_burns(_game.loot_filter, item.gem):
		var dust := Gems.shard_value(item.gem)  # filtr łupu: słaby kamień szlachetny od razu na odpryski
		_game.add_shards(dust)
		_float_text(tr("+%d odprysków") % dust, Color(0.75, 0.8, 0.95))
	elif item.has("gem"):
		_game.add_gem(item.gem)
	elif item.has("rune"):
		_game.add_rune(item.rune)
	elif LootFilter.burns(_game, item):
		got = _game.dismantle_loot(item)
	elif not _game.add_item(item):
		if not sell_if_full:
			_full()
			return
		bag_full = true
		got = _game.dismantle_loot(item)
	if not got.is_empty():
		_float_text(tr("+%d rudy") % got.ore, Color(0.95, 0.6, 0.4))
	_taken = true
	if not got.is_empty():
		scrapped.emit(item, got, bag_full)
	else:
		picked.emit(item)
	if (_is_item() and item.rarity in ["legendary", "unique"]) or item.has(Pinnacles.KEY):
		_play(LEGEND_PICKUP, -4.0, 1.0)
	else:
		_play(SOUND_RARE if _rarity() in ["rare", "legendary", "unique"] or item.has("gem") or item.has("aura") \
				or item.has("talisman") or item.has("rune") else SOUND, -6.0)
	for c in get_children():
		if c is CanvasItem:
			c.visible = false
	get_tree().create_timer(1.0).timeout.connect(queue_free)


## Pełna torba: przedmiot odskakuje od postaci i pokazuje napis.
func _full() -> void:
	_pulled = false
	_blocked = true
	var away := (global_position - hero.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	create_tween().tween_property(self, "position", position + away * 22.0, 0.25).set_ease(Tween.EASE_OUT)
	_float_text(tr("Torba pełna!"), Color(1, 0.55, 0.4))


## Napis nad przedmiotem, który unosi się i gaśnie.
func _float_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.03))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140, 16)
	label.position = position + Vector2(-70, -36)
	label.z_index = 20
	get_parent().add_child(label)  # obok przedmiotu - napis zostaje, gdy przedmiot znika
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 14.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.8)
	tween.tween_callback(label.queue_free)


## Dźwięk przy przedmiocie (`pitch` < 0 - lekko losowa wysokość, inaczej ta).
func _play(stream: AudioStream, volume: float, pitch := -1.0) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	audio.pitch_scale = randf_range(0.95, 1.1) if pitch < 0.0 else pitch
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)


## Słup światła nad przedmiotem (rysowany w kodzie): wysokość i szerokość według rzadkości, iskry unoszące się
## w słupie (legenda, unikat), wolne pulsowanie (unikat), aureola u podstawy (anielski).
class _Beam extends Node2D:
	const SPARKS := 6
	var color := Color(1.0, 0.85, 0.35)
	var height := 34.0
	var width := 6.0
	var sparks := false
	var pulse := false
	var halo := false
	var _t := randf() * 5.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.5 + 0.2 * sin(_t * 4.0)
		var grow := 1.0 + (0.18 * sin(_t * 2.0) if pulse else 0.0)
		for i in 3:
			var w := (width - i * width * 0.3) * grow
			draw_rect(Rect2(-w / 2.0, -height - 4.0, w, height), Color(color, 0.22 * a))
		if halo:
			draw_arc(Vector2(0, -2), 9.0 + sin(_t * 3.0), 0.0, TAU, 24, Color(color, 0.5 * a), 1.0)
		if sparks:
			for i in SPARKS:
				var f := fmod(_t * 0.45 + float(i) / SPARKS, 1.0)  # 0 - u podstawy, 1 - na górze
				var x := sin(_t * 2.0 + i * 1.7) * width * 0.6
				draw_rect(Rect2(x - 0.5, -4.0 - f * height, 1.0, 1.0), Color(color.lightened(0.5), 1.0 - f))


## Gwiazdka nad przedmiotem z premią ponad widełki: błysk przy wypadnięciu, potem co chwilę mignięcie.
class _Star extends Node2D:
	const EVERY := 1.6
	var color := Color(0.75, 1.0, 1.0)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var s := 0.0
		if _t < 0.5:
			s = 1.6 * (1.0 - _t / 0.5) + 0.4  # błysk przy wypadnięciu
		else:
			var k := fmod(_t, EVERY) / 0.35
			s = sin(k * PI) if k < 1.0 else 0.0
		if s <= 0.01:
			return
		var c := Vector2(6, -16)
		var r := 4.0 * s
		draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(color, 0.9), 1.0)
		draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(color, 0.9), 1.0)
		draw_rect(Rect2(c - Vector2(0.5, 0.5), Vector2(1, 1)), Color.WHITE)


## Zielona strzałka „lepszy” nad przedmiotem (lekko podskakuje).
class _Arrow extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		position.y = -22.0 - 1.5 * sin(_t * 5.0)
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(0, -4), Vector2(4, 1), Vector2(1.5, 1), Vector2(1.5, 4),
				Vector2(-1.5, 4), Vector2(-1.5, 1), Vector2(-4, 1)])
		draw_colored_polygon(pts, ProtoLoot.ARROW_COLOR)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.05, 0.2, 0.05), 1.0)

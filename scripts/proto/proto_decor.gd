class_name ProtoDecor
extends Node
## Wystrój lochu (ustalone z autorem 15.11.2026): ozdoby z grafik Watry (assets/watra/decor/<loch>/) rozrzucone losowo
## przy każdym wejściu po polanie. Wysokie ozdoby stoją w świecie sortowanym po Y (postać chowa się za kolumną) i mają
## przeszkodę u podstawy (prośba autora po pierwszej wersji bez kolizji): koło spłaszczone w pionie jak u postaci
## (`obstacles`, Vector3(x, y, promień); promień z szerokości grafiki albo `r`), z którego `push_out` wypycha postać
## (ProtoHero.obstacles), potwory (ProtoGoblin) i bossów (ProtoChief) - obchodzą ozdobę bokiem. Płaskie (`flat` -
## lilie, kości, świece) leżą pod postaciami i nie przeszkadzają. `TINT` - rozjaśnienie ozdób lochu (gobliny: grafiki
## lasu Watry były za ciemne na trawie).
## Część ozdób to kilka wariantów w jednym pliku (`frames` - losowa klatka), część jest animowana (`fps` - ogniska,
## pochodnie, misy z ogniem). Ozdoby ze światłem (`light`) dostają prostą poświatę: miękką plamę dodaną do obrazu
## (bez prawdziwych świateł Godota - tanio dla słabych telefonów), lekko migoczącą. Dane ozdób - DATA.

## Ozdoby lochu: plik (bez .png), waga losowania, `frames` - klatek w pliku, `fps` - animacja (0 - losowy wariant),
## `flat` - leży na ziemi, `light` - kolor poświaty, `glow` - jej promień (px).
const DATA := {
	Dungeons.GOBLINS: [
		{"f": "banner", "r": 5.0, "w": 2.0}, {"f": "barrel", "w": 2.0}, {"f": "bedroll", "w": 2.0, "flat": true},
		{"f": "bone_pile", "w": 2.0, "flat": true}, {"f": "bones", "w": 3.0, "flat": true},
		{"f": "campfire", "w": 2.0, "frames": 4, "fps": 8.0, "light": Color(1.0, 0.6, 0.25), "glow": 46.0},
		{"f": "goblin_tent_1", "w": 0.6, "r": 20.0}, {"f": "hide_rack", "w": 2.0}, {"f": "hide_tent", "w": 1.0},
		{"f": "log_seat", "w": 2.5}, {"f": "loot", "w": 1.5}, {"f": "palisade", "w": 1.0}, {"f": "pots", "w": 2.0},
		{"f": "shields", "w": 1.5}, {"f": "skull_pole", "r": 4.0, "w": 2.0}, {"f": "skull_totem", "w": 1.5},
		{"f": "tent", "w": 1.0}, {"f": "weapon_rack", "w": 1.0},
	],
	Dungeons.FLOODED: [
		{"f": "brazier", "w": 1.2, "frames": 2, "fps": 6.0, "light": Color(0.35, 1.0, 0.45), "glow": 40.0},
		{"f": "cattails", "w": 5.0, "frames": 3}, {"f": "clay_pots", "w": 2.0}, {"f": "drowned_tree_0", "r": 8.0, "w": 1.5},
		{"f": "fish_net", "w": 1.0}, {"f": "lilies", "w": 6.0, "frames": 3, "flat": true}, {"f": "mossy_rocks", "w": 3.0},
		{"f": "reeds", "w": 5.0, "frames": 2}, {"f": "rocks", "w": 4.0, "frames": 2, "flat": true},
		{"f": "rotten_stump", "w": 2.0}, {"f": "soul_jars", "w": 1.5, "light": Color(0.4, 0.95, 1.0), "glow": 22.0},
		{"f": "sunken_boat", "w": 1.0}, {"f": "sunken_cross", "r": 5.0, "w": 1.5},
	],
	Dungeons.CATACOMBS: [
		{"f": "bone_pile", "w": 3.0, "flat": true}, {"f": "candelabra", "r": 6.0, "w": 1.5, "light": Color(1.0, 0.7, 0.35), "glow": 44.0},
		{"f": "candle", "w": 3.0, "flat": true, "light": Color(1.0, 0.7, 0.35), "glow": 20.0}, {"f": "coffin", "w": 1.5},
		{"f": "corpses", "w": 1.5, "flat": true}, {"f": "fallen_stone", "w": 3.0}, {"f": "open_grave", "w": 1.0, "flat": true},
		{"f": "pillar_0", "r": 8.0, "w": 2.5}, {"f": "ribcage", "w": 2.5, "flat": true}, {"f": "sarcophagus", "w": 2.0},
		{"f": "skull_bones", "w": 4.0, "flat": true}, {"f": "skull_pile", "w": 1.5}, {"f": "skulls", "w": 4.0, "flat": true},
		{"f": "statue_0", "r": 8.0, "w": 1.0},
		{"f": "torch_stand", "r": 4.0, "w": 2.0, "frames": 2, "fps": 7.0, "light": Color(1.0, 0.6, 0.25), "glow": 50.0},
	],
	Dungeons.PLAINS: [
		{"f": "bone_pile", "w": 2.0, "flat": true}, {"f": "cairn", "w": 4.0}, {"f": "dead_tree_0", "r": 8.0, "w": 2.0},
		{"f": "dead_tree_1", "r": 7.0, "w": 2.0}, {"f": "eagle_totem", "w": 1.0}, {"f": "egg_nest", "w": 2.5, "flat": true},
		{"f": "iron_ore_0", "w": 3.0}, {"f": "perch_pole", "r": 6.0, "w": 1.0}, {"f": "pillar_nest_0", "r": 10.0, "w": 1.0},
		{"f": "stilt_hut_0", "r": 14.0, "w": 0.5},
		{"f": "storm_rod", "r": 5.0, "w": 1.5, "light": Color(0.6, 0.85, 1.0), "glow": 30.0}, {"f": "wind_chime", "w": 1.0},
	],
	Dungeons.VOLCANO: [
		{"f": "bones", "w": 2.0, "flat": true}, {"f": "boulders", "w": 4.0},
		{"f": "campfire", "w": 2.0, "frames": 4, "fps": 9.0, "light": Color(1.0, 0.5, 0.15), "glow": 48.0},
		{"f": "dead_stump", "w": 3.0}, {"f": "dead_tree", "r": 8.0, "w": 2.0}, {"f": "fallen_stone", "w": 2.5},
		{"f": "ribcage", "w": 1.5, "flat": true}, {"f": "rubble", "w": 3.0, "flat": true},
		{"f": "skull_bones", "w": 2.0, "flat": true},
	],
}
## Ile ozdób na polanie, najmniejsza odległość między nimi i wolne koło wokół startu postaci.
const COUNT := 45
const SPACING := 40.0
const CLEAR_RADIUS := 70.0
## Ozdoby leżące na ziemi - pod postaciami, nad podłogą.
const FLAT_Z := -5
const GLOW_Z := -4
## Przeszkoda: promień = szerokość grafiki x OBSTACLE_SHARE, w granicach OBSTACLE_MIN-OBSTACLE_MAX (albo `r` z DATA).
const OBSTACLE_SHARE := 0.32
const OBSTACLE_MIN := 5.0
const OBSTACLE_MAX := 15.0
## Rozjaśnienie ozdób lochu (mnożnik koloru; brak wpisu - bez zmian).
const TINT := {Dungeons.GOBLINS: Color(1.25, 1.22, 1.18)}

## Przeszkody ozdób obecnego lochu (wspólne dla postaci, potworów i bossa).
static var obstacles: Array[Vector3] = []

static var _glow_texture: Texture2D

## Animowane ozdoby i poświaty (do migotania): {"node", "frames", "fps", "t"} / {"node", "alpha", "t"}.
var _animated: Array = []
var _glows: Array = []


## Rozrzuca ozdoby lochu `climate` w prostokącie `area` (bez koła o promieniu CLEAR_RADIUS wokół `clear`)
## i dodaje je do świata `world` (sortowanego po Y). Zwraca liczbę postawionych ozdób.
func scatter(world: Node2D, climate: String, area: Rect2, clear: Vector2) -> int:
	var list: Array = DATA.get(climate, [])
	obstacles.clear()
	if list.is_empty():
		return 0
	var weights: Array = list.map(func(d: Dictionary) -> float: return d.w)
	var total := 0.0
	for w in weights:
		total += w
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < COUNT and tries < COUNT * 20:
		tries += 1
		var p := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if p.distance_to(clear) < CLEAR_RADIUS or placed.any(func(q: Vector2) -> bool: return q.distance_to(p) < SPACING):
			continue
		placed.append(p)
		var pick := randf() * total
		var data: Dictionary = list[0]
		for d in list:
			pick -= d.w
			if pick <= 0.0:
				data = d
				break
		_place(world, climate, data, p.round())
	return placed.size()


func _place(world: Node2D, climate: String, data: Dictionary, at: Vector2) -> void:
	var tex: Texture2D = load("res://assets/watra/decor/%s/%s.png" % [climate, data.f])
	var frames: int = data.get("frames", 1)
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = frames
	s.frame = randi() % frames
	s.centered = false
	s.offset = Vector2(-tex.get_width() / float(frames) / 2.0, -tex.get_height()).round()
	s.flip_h = randf() < 0.5
	s.position = at
	s.modulate = TINT.get(climate, Color.WHITE)
	if data.get("flat", false):
		s.z_index = FLAT_Z
	else:
		var w := tex.get_width() / float(frames)
		obstacles.append(Vector3(at.x, at.y, data.get("r", clampf(w * OBSTACLE_SHARE, OBSTACLE_MIN, OBSTACLE_MAX))))
	world.add_child(s)
	if data.get("fps", 0.0) > 0.0:
		_animated.append({"node": s, "frames": frames, "fps": data.fps, "t": randf() * 10.0})
	if data.has("light"):
		var g := Sprite2D.new()
		g.texture = _glow()
		var r: float = data.glow
		g.scale = Vector2(r, r * 0.6) / 32.0
		g.modulate = Color(data.light, 0.5)
		g.z_index = GLOW_Z
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		g.material = mat
		g.position = at + Vector2(0, -4)
		world.add_child(g)
		_glows.append({"node": g, "t": randf() * 10.0})


## Miękka okrągła plama (promień 32 px) - wspólna dla wszystkich poświat.
static func _glow() -> Texture2D:
	if _glow_texture == null:
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = grad
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_glow_texture = t
	return _glow_texture


## Punkt wypchnięty poza przeszkody ozdób (koła spłaszczone o połowę w pionie, jak ProtoHero._push_out);
## `margin` - dodatkowy odstęp (szerszy potwór, boss).
static func push_out(p: Vector2, margin := 0.0) -> Vector2:
	for o in obstacles:
		var r := o.z + margin
		var d := Vector2(p.x - o.x, (p.y - o.y) * 2.0)
		if d.length() < r:
			d = (d if d.length() > 0.01 else Vector2.DOWN).normalized() * r
			p = Vector2(o.x + d.x, o.y + d.y / 2.0)
	return p


func _exit_tree() -> void:
	obstacles.clear()


## Ile ozdób ma poświatę (testy).
func glow_count() -> int:
	return _glows.size()


func _process(delta: float) -> void:
	for a in _animated:
		a.t += delta
		var node: Sprite2D = a.node
		node.frame = int(a.t * a.fps) % a.frames
	for g in _glows:
		g.t += delta
		var node: Sprite2D = g.node
		node.modulate.a = 0.42 + 0.08 * sin(g.t * 7.0) + 0.05 * sin(g.t * 13.0)

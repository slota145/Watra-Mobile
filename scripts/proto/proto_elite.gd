class_name ProtoElite
extends Node2D
## Elita goblina (dziecko goblina, `ProtoGoblin.elite`; dane i liczby w scripts/elites.gd). `promote` wzmacnia goblina
## przed dodaniem do sceny: więcej zdrowia i obrażeń, większy, cechy:
## - Szybki: biega i atakuje szybciej,
## - Tarczowy: tarcza (`shield`) pochłania trafienia (niebieskie liczby), wraca po chwili bez obrażeń,
## - Wybuchowy: po śmierci czerwone koło (ProtoTelegraph), potem wybuch raniący w kole,
## - Dowódczy: gobliny wokół (krąg na ziemi) są szybsze i silniejsze (`ProtoGoblin.empower`).
## Wygląd: poświata wokół sylwetki w kolorze pierwszej cechy (prosty shader obrysu), nad głową napis z cechami
## i pasek zdrowia (z tarczą na niebiesko).

const SHIELD_NUMBER := Color(0.55, 0.85, 1.0)
const FX_BLAST := preload("res://assets/effects/boss_slam.png")
const BLAST_SOUND := preload("res://assets/watra/chief_slam.ogg")
const BAR_WIDTH := 24.0
const OUTLINE_SHADER := """
shader_type canvas_item;
uniform vec4 glow : source_color = vec4(1.0);
uniform float pulse = 1.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	if (COLOR.a < 0.1) {
		vec2 p = TEXTURE_PIXEL_SIZE;
		float near = max(max(texture(TEXTURE, UV + vec2(p.x, 0.0)).a, texture(TEXTURE, UV - vec2(p.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, p.y)).a, texture(TEXTURE, UV - vec2(0.0, p.y)).a));
		float far = max(max(texture(TEXTURE, UV + vec2(2.0 * p.x, 0.0)).a, texture(TEXTURE, UV - vec2(2.0 * p.x, 0.0)).a),
			max(max(texture(TEXTURE, UV + p).a, texture(TEXTURE, UV - p).a),
			max(texture(TEXTURE, UV + vec2(p.x, -p.y)).a, texture(TEXTURE, UV + vec2(-p.x, p.y)).a)));
		far = max(far, max(texture(TEXTURE, UV + vec2(0.0, 2.0 * p.y)).a, texture(TEXTURE, UV - vec2(0.0, 2.0 * p.y)).a));
		float a = near > 0.1 ? 0.95 : (far > 0.1 ? 0.4 : 0.0);
		COLOR = vec4(glow.rgb, a * pulse * tint.a);
	}
}
"""

static var _shader: Shader

var goblin: ProtoGoblin
var traits: Array[String] = []
## Tarcza (Tarczowy): obecna i pełna.
var shield := 0.0
var shield_max := 0.0

var _since_hit := 99.0
var _aura_left := 0.0
var _t := 0.0
var _label: Label
var _aura: _Aura
var _material: ShaderMaterial


## Robi z goblina elitę z danymi cechami (przed dodaniem goblina do sceny - zdrowie liczy się w jego _ready).
static func promote(g: ProtoGoblin, with_traits: Array[String]) -> ProtoElite:
	var e := ProtoElite.new()
	e.name = "Elite"
	e.goblin = g
	e.traits = with_traits
	g.elite = e
	g.max_hp = roundi(g.max_hp * Elites.health_mult(with_traits.size()))
	g.damage_mult = Elites.DAMAGE
	g.shadow_scale *= Elites.SCALE
	if "fast" in with_traits:
		g.speed *= Elites.FAST_SPEED
		g.attack_cooldown *= Elites.FAST_COOLDOWN
	if "shield" in with_traits:
		e.shield_max = g.max_hp * g.power * Elites.SHIELD
		e.shield = e.shield_max
	g.add_child(e)
	return e


## Kolor elity (pierwsza cecha).
func color() -> Color:
	return Elites.TRAITS[traits[0]].color


func max_health() -> float:
	return goblin.max_hp * goblin.power


func _ready() -> void:
	z_index = 20
	_setup.call_deferred()  # sprite goblina powstaje w jego _ready, po tym węźle


func _setup() -> void:
	if not is_instance_valid(goblin) or goblin._sprite == null:
		return
	goblin._sprite.scale *= Elites.SCALE
	goblin.center_height *= Elites.SCALE
	if "fast" in traits and goblin._scene:
		goblin._sprite.speed_scale = Elites.FAST_SPEED
	if _shader == null:
		_shader = Shader.new()
		_shader.code = OUTLINE_SHADER
	_material = ShaderMaterial.new()
	_material.shader = _shader
	_material.set_shader_parameter("glow", color())
	goblin._sprite.material = _material
	_label = Label.new()
	_label.text = Elites.label(traits)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", color().lightened(0.25))
	_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.03))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(90, 12)
	_label.position = Vector2(-45, _top() - 17)
	add_child(_label)
	if "commanding" in traits:
		_aura = _Aura.new()
		_aura.elite = self
		add_child(_aura)


## Wysokość czubka głowy nad ziemią (ujemna - w górę).
func _top() -> float:
	return -goblin.center_height * 2.0 - 4.0


func _process(delta: float) -> void:
	if not is_instance_valid(goblin):
		return
	if not goblin.alive():
		if _material and goblin._sprite:
			goblin._sprite.material = null  # ciało i uciekająca elita bez poświaty
			_material = null
			queue_redraw()
		return
	_t += delta
	_since_hit += delta
	if _material:
		_material.set_shader_parameter("pulse", 0.75 + 0.25 * sin(_t * 5.0))
	if shield_max > 0.0 and shield < shield_max and _since_hit >= Elites.SHIELD_DELAY:
		shield = shield_max
		_flash(Color(1.4, 2.0, 2.6))
	if "commanding" in traits:
		_aura_left -= delta
		if _aura_left <= 0.0:
			_aura_left = Elites.AURA_EVERY
			for n in get_tree().get_nodes_in_group(ProtoWeapon.TARGETS):
				if n != goblin and n is ProtoGoblin and n.global_position.distance_to(goblin.global_position) <= Elites.AURA_RADIUS:
					n.empower(Elites.AURA_EVERY * 2.5)
	queue_redraw()


## Trafienie elity: tarcza bierze, ile może (niebieska liczba); zwraca obrażenia, które przechodzą do zdrowia.
func absorb(amount: int) -> int:
	_since_hit = 0.0
	if shield <= 0.0 or amount <= 0:
		return amount
	var taken := minf(shield, float(amount))
	shield -= taken
	goblin.spawn_number(roundi(taken), SHIELD_NUMBER)
	_flash(Color(1.2, 1.8, 2.4))
	return amount - roundi(taken)


func _flash(tint: Color) -> void:
	if goblin._sprite == null:
		return
	goblin._sprite.modulate = tint
	goblin._sprite.create_tween().tween_property(goblin._sprite, "modulate", Color.WHITE, 0.15)


## Śmierć elity: napis i krąg znikają, Wybuchowy zostawia koło, które po chwili wybucha.
func on_death() -> void:
	if _label:
		_label.queue_free()
	if _aura:
		_aura.queue_free()
	queue_redraw()
	if "volatile" in traits:
		ProtoElite.blast(goblin.get_parent(), goblin.global_position, goblin.hero, roundi(Elites.VOLATILE_DAMAGE * goblin.power))


## Wybuch Wybuchowego: koło w miejscu śmierci wypełnia się przez VOLATILE_WARN s, potem rani postać w kole.
static func blast(world: Node, at: Vector2, hero: ProtoHero, dmg: int) -> ProtoTelegraph:
	var t := ProtoTelegraph.new()
	t.radius = Elites.VOLATILE_RADIUS
	t.duration = Elites.VOLATILE_WARN
	world.add_child(t)
	t.global_position = at
	var tween := t.create_tween()
	tween.tween_interval(Elites.VOLATILE_WARN)
	tween.tween_callback(func() -> void:
		if hero and is_instance_valid(hero) and not hero.dead and t.contains(hero.global_position):
			hero.take_damage(dmg)
		var fx := Fx.once(world, FX_BLAST, 12, 16.0, at, Vector2(37, 25), 20, Elites.VOLATILE_RADIUS / 34.0)
		fx.modulate = Color(1.6, 0.9, 0.6)
		var sound := AudioStreamPlayer2D.new()
		sound.stream = BLAST_SOUND
		sound.pitch_scale = randf_range(1.2, 1.35)
		sound.volume_db = -6.0
		world.add_child(sound)
		sound.global_position = at
		sound.play()
		sound.finished.connect(sound.queue_free)
		t.queue_free())
	return t


## Pasek zdrowia nad głową (z tarczą) i bańka tarczy.
func _draw() -> void:
	if not is_instance_valid(goblin) or not goblin.alive():
		return
	var y := _top() - 4.0
	var x := -BAR_WIDTH / 2.0
	draw_rect(Rect2(x - 1, y - 1, BAR_WIDTH + 2, 4), Color(0.08, 0.04, 0.03, 0.85))
	draw_rect(Rect2(x, y, BAR_WIDTH * clampf(goblin.hp / max_health(), 0.0, 1.0), 2), Color(0.86, 0.2, 0.15))
	if shield_max > 0.0 and shield > 0.0:
		draw_rect(Rect2(x, y, BAR_WIDTH * clampf(shield / shield_max, 0.0, 1.0), 1), SHIELD_NUMBER)
		var a := 0.35 + 0.15 * sin(_t * 4.0)
		draw_set_transform(Vector2(0, -goblin.center_height), 0.0, Vector2(1.0, 1.15))
		draw_arc(Vector2.ZERO, goblin.center_height * 1.25, 0.0, TAU, 28, Color(SHIELD_NUMBER, a), 1.0)
		draw_set_transform(Vector2.ZERO)


## Krąg Dowódczego na ziemi (pod postaciami): zasięg wzmocnienia.
class _Aura extends Node2D:
	var elite: ProtoElite

	func _ready() -> void:
		z_as_relative = false
		z_index = -1

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c: Color = Elites.TRAITS["commanding"].color
		var a := 0.22 + 0.08 * sin(elite._t * 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, Elites.AURA_RADIUS, 0.0, TAU, 56, Color(c, a), 1.0)
		draw_circle(Vector2.ZERO, Elites.AURA_RADIUS, Color(c, 0.05))

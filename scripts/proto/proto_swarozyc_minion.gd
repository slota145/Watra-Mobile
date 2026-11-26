class_name ProtoSwarozycMinion
extends ProtoGoblin
## Mniejszy Swarożyc - sługa bossa Świątyni Słońca (ProtoSwarozyc przyzywa go aureolą, `minion_kind` "swarozyc";
## ustalone z autorem 26.11.2026): ten sam model co boss, zmniejszony (MINION_SCALE) i półprzezroczysty jak świetlista
## zjawa. Podchodzi i dźga włócznią (animacja `attack` bossa, zdarzenie `hit`) - cios Prawią. Nie piszczy przy ucieczce.
## Do czasu grafiki - zastępczy kolor.

const MINION_HP := 70
const MINION_SPEED := 34.0
const MINION_DAMAGE := 14
## Model bossa jest ok. 1,45 raza większy od człowieka - sługa ma wzrost zwykłej postaci.
const MINION_SCALE := 0.7


func _init() -> void:
	scene_path = ProtoSwarozyc.SWAROZYC_SCENE
	max_hp = MINION_HP
	speed = MINION_SPEED
	damage = MINION_DAMAGE
	element = Elements.PRAWIA
	squeaks = false
	fallback_color = Color(1.0, 0.92, 0.6, 0.8)


func _ready() -> void:
	super()
	if _scene:
		_sprite.scale = Vector2.ONE * MINION_SCALE
		_sprite.modulate = Color(1.2, 1.15, 0.95, 0.8)

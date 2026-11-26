class_name ProtoKosciej
extends ProtoChief
## Kościej Nieśmiertelny - boss Wieży Kościeja (Dungeons.TOWER, ustalone z autorem 26.11.2026): czarnoksiężnik, którego śmierć ukryta jest w igle w jajku - trzeba zniszczyć jajo, inaczej się odradza; pieczęcie, teleport.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: model SpriteKiln assets/spritekiln/kosciej/,
## do czasu grafiki - powiększony goblin w zastępczym kolorze.

const BOSS_SCENE := "res://assets/spritekiln/kosciej/kosciej.tscn"
const BOSS_HP := 1450

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false


func _init() -> void:
	scene_path = BOSS_SCENE
	base_hp = BOSS_HP
	fallback_tint = Color(0.75, 0.55, 1.0)

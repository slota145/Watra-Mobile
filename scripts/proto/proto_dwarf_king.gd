class_name ProtoDwarfKing
extends ProtoChief
## Król Karłów Kowal - boss Kopalni karłów (Dungeons.MINE, ustalone z autorem 26.11.2026): opętany przez Hordę król karłów z wielkim młotem i kowadłem - uderzenia falą, deszcz odłamków, przywołuje skalne golemy.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Grafika: model SpriteKiln assets/spritekiln/dwarf_king/,
## do czasu grafiki - powiększony goblin w zastępczym kolorze.

const BOSS_SCENE := "res://assets/spritekiln/dwarf_king/dwarf_king.tscn"
const BOSS_HP := 1400

## Testy i zrzuty: sam nie wybiera ataków.
var passive := false


func _init() -> void:
	scene_path = BOSS_SCENE
	base_hp = BOSS_HP
	fallback_tint = Color(0.85, 0.6, 0.4)

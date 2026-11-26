class_name ProtoSeals
extends Node2D
## Magiczne pieczęcie - mechanika Wieży Kościeja (Dungeons.TOWER, decyzja autora 26.11.2026): na posadzce zapalają się pieczęcie - niebieska daje premię (mana, szybkość), czerwona wybucha; trzeba czytać kolory.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Arena tworzy węzeł tylko w tym lochu.

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: mechanika sama nie rusza.
var passive := false

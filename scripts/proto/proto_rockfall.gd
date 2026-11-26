class_name ProtoRockfall
extends Node2D
## Osuwiska - mechanika Kopalni karłów (Dungeons.MINE, decyzja autora 26.11.2026): co kilka sekund ze stropu spadają głazy w zapowiedzianych miejscach; zostają na chwilę jako przeszkody, za którymi można się chować przed pociskami.
## SZKIELET (26.11.2026) - do uzupełnienia przez pomocnika lochu. Arena tworzy węzeł tylko w tym lochu.

var hero: ProtoHero
var bounds := Rect2(-300, -300, 600, 600)
var power := 1.0
## Testy i zrzuty: mechanika sama nie rusza.
var passive := false

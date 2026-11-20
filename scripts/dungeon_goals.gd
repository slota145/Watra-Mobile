class_name DungeonGoals
extends RefCounted
## Cele na mapie lochu (pomysł z Dwarven Realms, ustalone z autorem 16.11.2026): przy progach paska przyzwania
## (THRESHOLDS - ułamki DungeonLevels.summon_cost) na mapie pojawia się cel, żeby między falami było dokąd biec.
## Cel losuje się z puli zależnej od poziomu lochu (KINDS - od którego poziomu), bez powtórek w jednym zejściu
## (gdy pula jest mniejsza niż liczba progów, powtórki są dozwolone). Niezrobiony cel zostaje po przyzwaniu Wodza.
## Na razie: skrzynia (ProtoChest z `hold_time` - stań przy niej), kapliczka (ProtoShrine - dar bóstwa na GIFT_TIME s)
## Skarbnik (ProtoSkarbnik - uciekający duch, trafienia wybijają rudę, złapany daje runy), Krąg Żertwy (ProtoZertwa - danina z potworów
## zabitych w kręgu, nagroda do wyboru 1 z 3 - ZertwaOffer), Kryształ Watry (ProtoCrystal - obrona przed falami)
## i Napad Hordy (ProtoRaid - obóz goblinów: przetrwaj fale w kręgu, nagroda ruda i czasem runa).
## Pokazanie graczowi: słup światła nad celem, strzałka przy krawędzi ekranu (GoalArrows), napis i dźwięk.

const THRESHOLDS: Array[float] = [0.25, 0.5, 0.75]
## Rodzaj celu -> od którego poziomu lochu jest w puli (pula rośnie co 5 poziomów - decyzja autora).
const KINDS := {"chest": 1, "shrine": 5, "raid": 5, "skarbnik": 10, "zertwa": 15, "crystal": 20}
## Cel pojawia się w takiej odległości od postaci (piksele gry; ekran ma 360 px szerokości).
const MIN_DIST := 200.0
const MAX_DIST := 420.0
## Najmniejszy odstęp od innych celów i od brzegu polany.
const GOAL_GAP := 120.0
const EDGE_MARGIN := 48.0

## Skrzynia-cel: tyle sekund stania przy niej, łup mniejszy niż skrzynia Wodza.
const CHEST_HOLD := 1.5
## Żar ze skrzyni-celu - ułamek żaru skrzyni Wodza (DungeonLevels.chest_embers).
const CHEST_EMBER_SHARE := 0.25
## Szansa na kamień (Gems.roll) i na runę (Runes.roll) ze skrzyni-celu.
const CHEST_GEM := 0.2
const CHEST_RUNE := 0.5

## Kapliczka: tyle sekund modlitwy (stania na niej) i czas daru.
const PRAY_TIME := 1.0
const GIFT_TIME := 60.0
## Dary bóstw (nazwy jak w Watrze, Boons): premie doliczane do cech z przedmiotów (`stats`, te same klucze co
## Items.totals), `loot` - mnożnik szansy łupu, `regen_pct` - % maks. zdrowia na sekundę.
const GIFTS := {
	"might": {"name": "Moc Peruna", "color": Color(1.0, 0.45, 0.3), "stats": {"damage_pct": 50.0, "crit_pct": 10.0},
			"description": "+50% obrażeń, +10% szansy na trafienie krytyczne"},
	"ward": {"name": "Opieka Mokoszy", "color": Color(0.45, 1.0, 0.5), "stats": {"dodge_pct": 20.0, "protection_pct": 20.0},
			"regen_pct": 3.0, "description": "+20% uniku i ochrony, leczenie 3% zdrowia na sekundę"},
	"haste": {"name": "Tchnienie Strzyboga", "color": Color(0.75, 1.0, 1.0), "stats": {"move_pct": 30.0, "attack_speed_pct": 30.0},
			"description": "+30% szybkości ruchu i ataku"},
	"fortune": {"name": "Hojność Dadźboga", "color": Color(1.0, 0.85, 0.3), "stats": {}, "loot": 2.0,
			"description": "Przedmioty i kamienie wypadają dwa razy częściej"},
}


## Rodzaje celów dostępne na tym poziomie lochu.
static func pool(level: int) -> Array[String]:
	var out: Array[String] = []
	for kind: String in KINDS:
		if level >= int(KINDS[kind]):
			out.append(kind)
	return out


## Losowy rodzaj celu; `used` - rodzaje już wylosowane w tym zejściu (bez powtórek, póki się da).
static func roll(level: int, used: Array) -> String:
	var all := pool(level)
	var fresh := all.filter(func(k: String) -> bool: return not used.has(k))
	return (fresh if not fresh.is_empty() else all).pick_random()


## Ile progów przekracza żar `embers` przy koszcie przyzwania `cost`.
static func thresholds_passed(embers: int, cost: int) -> int:
	var n := 0
	for t in THRESHOLDS:
		if embers >= ceili(cost * t):
			n += 1
	return n


## Miejsce na cel: w polanie, MIN_DIST-MAX_DIST od postaci, z dala od innych celów i ozdób. Kilka prób losowania,
## potem najlepsze z nich.
static func spot(area: Rect2, hero_pos: Vector2, others: Array) -> Vector2:
	var inner := area.grow(-EDGE_MARGIN)
	var best := inner.get_center()
	var best_score := -INF
	for i in 24:
		var p := hero_pos + Vector2.from_angle(randf() * TAU) * randf_range(MIN_DIST, MAX_DIST)
		p = p.clamp(inner.position, inner.end)
		p = ProtoDecor.push_out(p, 16.0).clamp(inner.position, inner.end)
		var score := 0.0
		var d := p.distance_to(hero_pos)
		if d < MIN_DIST:
			score -= MIN_DIST - d
		for o: Vector2 in others:
			score -= maxf(0.0, GOAL_GAP - p.distance_to(o))
		if score >= 0.0:
			return p
		if score > best_score:
			best_score = score
			best = p
	return best


## Łup skrzyni-celu: jeden przedmiot (wagi skrzyni Wodza), czasem kamień (od Gems.MIN_LEVEL, jak inne kamienie)
## i runa (CHEST_RUNE; `rune_mult` - Skarbiec drzewka lochów).
static func chest_items(level: int, loot_mult := 1.0, rune_mult := 1.0) -> Array:
	var items: Array = [Items.roll(level, "", "", Items.CHEST_WEIGHTS)]
	if level >= Gems.MIN_LEVEL and randf() < CHEST_GEM * loot_mult:
		items.append({"gem": Gems.roll(level)})
	if randf() < CHEST_RUNE * loot_mult * rune_mult:
		items.append({"rune": Runes.roll(level)})
	var aura := Auras.roll_chest(level, true, loot_mult)  # kamień aury (od lochu Auras.MIN_LEVEL)
	if aura != "":
		items.append({"aura": aura})
	var talisman := Talismans.roll_chest(level, loot_mult)  # talizman (od lochu Talismans.MIN_LEVEL)
	if talisman != "":
		items.append({"talisman": talisman})
	return items


static func chest_embers(level: int) -> int:
	return maxi(1, roundi(DungeonLevels.chest_embers(level) * CHEST_EMBER_SHARE))


## Krąg Żertwy: tyle daniny (zabitych w kręgu; elity ZER_ELITE) w ZER_TIME s, krąg o promieniu ZER_RADIUS
## (spłaszczony jak cień: w pionie połowa), co ZER_PACK_EVERY s paczka ZER_PACK potworów zza brzegu kręgu.
const ZER_GOAL := 80
const ZER_ELITE := 3
const ZER_TIME := 75.0
const ZER_RADIUS := 110.0
const ZER_PACK_EVERY := 2.5
const ZER_PACK := Vector2i(4, 6)

## Napad Hordy (decyzja autora 20.11.2026): RAID_TIME s w kręgu obozu (RAID_RADIUS, spłaszczony jak cień; poza nim
## czas stoi), co RAID_WAVE_EVERY s z RAID_SIDES stron paczka RAID_PACK potworów (RAID_SPAWN_DIST px od obozu).
## Nagroda: RAID_ORE rudy (razy nagrody celów z drzewka, potem Skarbiec) i z szansą RAID_RUNE runa (razy Skarbiec).
const RAID_TIME := 45.0
const RAID_RADIUS := 85.0
const RAID_WAVE_EVERY := 4.0
const RAID_SIDES := 3
const RAID_PACK := Vector2i(4, 6)
const RAID_SPAWN_DIST := 230.0
const RAID_ORE := Vector2i(6, 10)
const RAID_RUNE := 0.4

## Kryształ Watry: obrona przez CRYSTAL_TIME s, fale co CRYSTAL_WAVE_EVERY s z CRYSTAL_SIDES stron po CRYSTAL_PACK
## potworów (CRYSTAL_SPAWN_DIST px od kryształu); zdrowie CRYSTAL_HP x siła poziomu. Nagroda: kamienie
## (1 + CRYSTAL_GEMS x zdrowie, które zostało) i odpryski; zniszczony - tylko garść odprysków (CRYSTAL_SHARDS_LOST).
const CRYSTAL_TIME := 25.0
const CRYSTAL_WAVE_EVERY := 5.0
const CRYSTAL_SIDES := 2
const CRYSTAL_PACK := Vector2i(4, 6)
const CRYSTAL_SPAWN_DIST := 230.0
const CRYSTAL_HP := 600
const CRYSTAL_GEMS := 3
const CRYSTAL_SHARDS := Vector2i(18, 36)
const CRYSTAL_SHARDS_LOST := 9


## Nagrody Kręgu Żertwy do wyboru: rzadki przedmiot, kamień, runa (bez najprostszej Runy Szlifu) albo żar (tyle, ile ze skrzyni Wodza); od lochu
## Talismans.MIN_LEVEL także losowy talizman (decyzja autora 19.11.2026).
static func zertwa_offer(level: int) -> Array[Dictionary]:
	var offer: Array[Dictionary] = [
		{"item": Items.roll(level, "", "rare")},
		{"item": {"gem": Gems.roll(level)}},
		{"item": {"rune": Runes.roll(level, [Runes.POLISH])}},
	]
	if level >= Talismans.MIN_LEVEL:
		offer.append({"item": {"talisman": Talismans.roll()}})
	offer.append({"embers": DungeonLevels.chest_embers(level)})
	return offer


## Odpryski z obronionego kryształu (wg zdrowia, które zostało: 0-1).
static func crystal_shards(health: float) -> int:
	return roundi(lerpf(CRYSTAL_SHARDS.x, CRYSTAL_SHARDS.y, clampf(health, 0.0, 1.0)))


static func crystal_gems(health: float) -> int:
	return 1 + roundi(CRYSTAL_GEMS * clampf(health, 0.0, 1.0))


## Runy z obronionego kryształu: jedna, druga przy co najmniej połowie zdrowia.
static func crystal_runes(health: float) -> int:
	return 2 if health >= 0.5 else 1


## Losowy dar kapliczki.
static func roll_gift() -> String:
	return GIFTS.keys().pick_random()

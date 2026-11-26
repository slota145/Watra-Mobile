class_name ProtoHero
extends Node2D
## Postać w prototypie: Wojciech z Watry (arkusz assets/watra/wojciech.png) chodzi gałką.
## Arkusz: 8 kolumn = klatki, wiersze = animacja * 5 + kierunek (s, se, e, ne, n; zachód to odbicie).
## Bez broni w dłoni - broń lewituje obok (ProtoWeapon). Animacja "slash" z pustą dłonią służy za gest ataku.
## Zdrowie: potwory Hordy zadają obrażenia (`take_damage`), przy zerze postać pada (`died`). `obstacles` - okręgi
## (x, y, promień), przez które postać nie przechodzi (np. krąg kamieni Watry).
## Tryb deweloperski (`immortal`): zdrowie schodzi normalnie, ale zamiast śmierci wraca do pełna, a `deaths` liczy,
## ile razy postać by zginęła (sygnał `death_avoided`).
## Poziom postaci (`set_level`, HeroLevels) ustala największe zdrowie; awans (`level_up`) leczy do pełna
## ze złotym błyskiem, napisem „Poziom N!” i dźwiękiem. Przedmioty (`gear` - Items.totals) dokładają zdrowie, manę,
## szybkość ruchu, regenerację zdrowia i ochronę (mniej obrażeń od potworów).
## Mana odnawia się sama (HeroLevels.mana_regen z poziomu i premia przedmiotów `mana_regen`), a wydają ją umiejętności miecza (`spend_mana`). Skok Mgnienia
## Aury (Auras) rezerwują część many: `reserved` - tyle many z `max_mana` jest zajęte, mana napełnia się najwyżej do
## `mana_cap()`. Premie aur (zdrowie, odnowa) przychodzą w `gear` (Auras.apply), kręgi i działanie - dziecko ProtoAuras.
## (`teleport`) przenosi postać od razu, zostawia gasnący cień w miejscu startu i daje chwilę nietykalności.

signal health_changed(hp: int, max_hp: int)
signal mana_changed(mana: int, max_mana: int)
## Tarcza aury Opieka Mokoszy (pochłania obrażenia przed zdrowiem).
signal shield_changed(shield: int, shield_max: int)
## Cios wroga zranił postać (po tarczy, uniku i gardzie) - talizman Kora Leszego.
signal hurt(amount: int)
## Umiejętność kosztowała manę (talizman Świeca Wiedźmy liczy wydaną).
signal mana_spent(amount: int)
signal died
## Cios potwora chybił dzięki unikowi.
signal dodged
## Garda Riposty (katana) zablokowała cios - broń odpowiada kontrą.
signal parried
## Nieśmiertelność uratowała postać od śmierci (`count` - ile razy w tym lochu).
signal death_avoided(count: int)

const ANIMS := ["idle", "walk", "slash"]
const FPS := {"idle": 6.0, "walk": 14.0, "slash": 18.0}
const DIRS := 5
const FRAMES := 8
const SPEED := 70.0
## Zdrowie na 1. poziomie (wyżej - HeroLevels.max_hp).
const MAX_HP := HeroLevels.HP_BASE
const LEVEL_UP_SOUND := preload("res://assets/watra/level_up.ogg")
## Po trafieniu postać przez chwilę nie dostaje kolejnych obrażeń (kilka goblinów naraz nie zabija w mgnieniu oka).
const INVULNERABLE := 0.35
## Nietykalność po zwykłym trafieniu (17.11.2026: było 0,35 s - postać dostawała najwyżej ~3 ciosy na sekundę
## bez względu na tłum, więc stanie w miejscu było za bezpieczne; uwaga autora). Riposta zostaje przy INVULNERABLE.
const HIT_INVULNERABLE := 0.1

## Skąd postać bierze kierunek ruchu (gałka).
var joystick: Joystick
## Granica areny (postać nie wychodzi poza nią).
var bounds := Rect2(-300, -300, 600, 600)
## Czy przy ataku postać robi gest ręką.
var gesture := true
## Kierunek patrzenia (do gestu i do miejsca, w którym unosi się broń).
var facing := Vector2.DOWN
var velocity := Vector2.ZERO
var max_hp := MAX_HP
## Mana (zużywają ją umiejętności miecza).
var max_mana := HeroLevels.MANA_BASE
## Mana zarezerwowana przez włączone aury (część max_mana, której nie da się wydać).
var reserved := 0
## Mana zarezerwowana przez przywołanie (kamień Wiernego Tropiciela łuku - ProtoBow), osobno od aur.
var summon_reserved := 0
## Aura Opieka Mokoszy: tarcza (obecna i pełna) i ile sekund jeszcze do jej odnowienia (Auras.MOKOSZ_DELAY bez trafienia).
var shield := 0
var shield_max := 0
var _shield_wait := 0.0
## Aura Kamienna Krew: o tyle mniej obrażeń poniżej Auras.STONE_BELOW zdrowia.
var stone := 0.0
## Aura Hart Żywiołów: o tyle wyższy sufit odporności na żywioły (ułamek).
var max_res_bonus := 0.0
## Mnożnik obrażeń od wrogów (próba autora 20.11.2026 - DungeonLevels.enemy_damage): ciosy i podpalenia.
var enemy_damage := DungeonLevels.enemy_damage
## Kamień Twardość: o tyle mniej obrażeń jeszcze przez `fortify_left` s.
var fortify_pct := 0.0
var fortify_left := 0.0
## Talizmany (ProtoTalismans ustawia): Krwawe Serce - umiejętności płacą zdrowiem (`blood_magic` - ile zdrowia za 1 manę,
## 0 - zwykła mana); Nić Mokoszy - tyle obrażeń bierze mana (`mana_shield`); Poroże Jelenia - szybszy ruch
## (`move_bonus`); Świeca Wiedźmy - szybsza odnowa many (`mana_regen_bonus`).
var blood_magic := 0.0
## Unikaty (ProtoUniques ustawia): Korona Czarnoboga - umiejętności płacą zdrowiem (jak Krwawe Serce na 100%),
## Ostatnia Warownia - odporność na wszystkie ciosy (część) od liczby wrogów blisko.
var crown := false
var bastion_res := 0.0
var mana_shield := 0.0
var move_bonus := 0.0
var mana_regen_bonus := 0.0
var mana := HeroLevels.MANA_BASE
var hp := MAX_HP
var dead := false
## Tryb deweloperski: zamiast śmierci zdrowie wraca do pełna.
var immortal := false
## Ile razy postać zginęłaby bez nieśmiertelności.
var deaths := 0
## Przeszkody: Vector3(x, y, promień); w pionie spłaszczone o połowę (widok z góry 3/4).
var obstacles: Array[Vector3] = []
## Z przedmiotów: mnożnik szybkości ruchu, zdrowie na sekundę, część obrażeń, której postać nie dostaje (0-0,5).
var move_mult := 1.0
## Mnożnik szybkości z formy umiejętności (Postać Mary mrocznej kosy - mknąca chmura); 1.0 - zwykła postać.
var form_speed := 1.0
## Premia przedmiotów „szybkość ruchu i ataku po zabiciu” (Items kill_haste_pct, ułamek) i ile sekund jeszcze działa.
var kill_haste := 0.0
var haste_left := 0.0
var regen := 0.0
var protection := 0.0
## Odporność na żywioły (0-0,75, premia przedmiotów): o tyle mniej obrażeń od ciosów żywiołów (woda, lód...).
var element_res := 0.0
## Spowolnienie od potworów (przemoczenie, lód): ułamek szybkości mniej i ile sekund jeszcze; kolor postaci.
var chill := 0.0
var chill_left := 0.0
## Porażenie piorunem (żywioł Grom): przez `shock_left` s postać dostaje SHOCK_MULT obrażeń i miga na żółto.
const SHOCK_MULT := 1.25
var shock_left := 0.0
## Podpalenie (żywioł ognia): co BURN_TICK s traci `burn_damage` zdrowia (mniej o odporność na żywioły), przez `burn_left` s.
const BURN_TICK := 0.5
var burn_damage := 0
var burn_left := 0.0
var _burn_next := 0.0
var _chill_color := Color.WHITE
## Szansa na unik (0-1, premia przedmiotów): cios potwora nie zadaje obrażeń, nad głową napis „Unik!”.
var dodge := 0.0
var _regen_acc := 0.0
## Odnowa many na sekundę (poziom postaci i przedmioty - apply_gear).
var _mana_regen := HeroLevels.MANA_REGEN
var _mana_acc := 0.0
## Ostatnio podane cechy z przedmiotów (awans liczy z nimi nowe zdrowie).
var gear := {}

var _anim := "idle"
var _time := 0.0
var _sprite: Sprite2D
var _invulnerable := 0.0
## Garda Riposty: ile sekund następny cios zostanie zablokowany (0 - brak gardy).
var parry_left := 0.0
## Krąg Riposty Morozka (lodowy rapier): szansa (0-1), że cios zostanie odbity jak gardą (`parried`); broń ustawia ją
## co klatkę, gdy postać stoi w kręgu.
var parry_chance := 0.0
## Chłód w Lodowych jaskiniach (0-ProtoFrost.MAX_COLD; zbiera i rozgrzewa ProtoFrost).
var frost_cold := 0.0
## Ruch wymuszony przez broń (wyskok Riposty, krok Tańca ostrza): skąd, dokąd, czas, upływ, wysokość podskoku.
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_time := 0.0
var _leap_t := 0.0
var _leap_hop := 0.0


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = _shadow_texture()
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/watra/wojciech.png")
	_sprite.hframes = FRAMES
	_sprite.vframes = _sprite.texture.get_height() / 54
	_sprite.offset = Vector2(0, -19)  # stopy postaci w punkcie węzła (sortowanie po Y)
	add_child(_sprite)


func _process(delta: float) -> void:
	_invulnerable -= delta
	haste_left -= delta
	fortify_left -= delta
	if shield < shield_max and not dead:
		_shield_wait -= delta
		if _shield_wait <= 0.0:
			shield = shield_max
			shield_changed.emit(shield, shield_max)
	parry_left -= delta
	if chill_left > 0.0:
		chill_left -= delta
		if chill_left <= 0.0:
			chill = 0.0
			_sprite.self_modulate = Color.WHITE
	if burn_left > 0.0 and not dead:
		burn_left -= delta
		_burn_next -= delta
		if _burn_next <= 0.0:
			_burn_next = BURN_TICK
			_burn_hit()
	if shock_left > 0.0:
		shock_left -= delta
		if chill_left <= 0.0:  # spowolnienie ma pierwszeństwo w kolorze
			var on := int(shock_left * 12.0) % 2 == 0
			_sprite.self_modulate = Color(1.35, 1.3, 0.6) if on and shock_left > 0.0 else Color.WHITE
	if dead:
		velocity = Vector2.ZERO
		_leap_time = 0.0
		return
	if regen > 0.0 and hp < max_hp:
		_regen_acc += regen * delta
		if _regen_acc >= 1.0:
			var heal := int(_regen_acc)
			_regen_acc -= heal
			hp = mini(hp + heal, max_hp)
			health_changed.emit(hp, max_hp)
	if mana < mana_cap():
		_mana_acc += _mana_regen * (1.0 + mana_regen_bonus) * delta
		if _mana_acc >= 1.0:
			var add := int(_mana_acc)
			_mana_acc -= add
			mana = mini(mana + add, mana_cap())
			mana_changed.emit(mana, max_mana)
	else:
		_mana_acc = 0.0
	if _leap_time > 0.0:
		_process_leap(delta)
		return
	var input := joystick.vector if joystick else Vector2.ZERO
	velocity = input * SPEED * move_mult * form_speed * (1.0 + move_bonus + haste()) * (1.0 - chill)
	position = _push_out((position + velocity * delta).clamp(bounds.position, bounds.end))
	if input.length() > 0.05:
		facing = input.normalized()
	if _anim == "slash":
		# gest gra do końca; jeśli postać ruszyła, wraca do chodzenia, żeby nie sunąć po ziemi
		if input.length() > 0.05 or _time * FPS.slash >= FRAMES:
			_play("walk" if input.length() > 0.05 else "idle")
	else:
		_play("walk" if input.length() > 0.05 else "idle")
	_time += delta
	_update_frame()


## Ruch wymuszony: postać przesuwa się z `_leap_from` do `_leap_to` (wyskok - z podskokiem), gałka nie steruje.
func _process_leap(delta: float) -> void:
	_leap_t += delta
	var k := clampf(_leap_t / _leap_time, 0.0, 1.0)
	position = _push_out(_leap_from.lerp(_leap_to, ease(k, 0.6)).clamp(bounds.position, bounds.end))
	_sprite.position.y = -sin(k * PI) * _leap_hop
	velocity = Vector2.ZERO
	if k >= 1.0:
		_leap_time = 0.0
		_sprite.position.y = 0.0
	_time += delta
	_update_frame()


## Ruch wymuszony przez broń do punktu `to` (świat) w `time` s; `hop` - wysokość podskoku (0 - krok po ziemi).
func leap(to: Vector2, time: float, hop := 0.0) -> void:
	var parent := get_parent() as Node2D
	_leap_from = position
	_leap_to = parent.to_local(to) if parent else to
	_leap_time = maxf(time, 0.01)
	_leap_t = 0.0
	_leap_hop = hop
	var dir := _leap_to - _leap_from
	if dir.length() > 0.5:
		facing = dir.normalized()


## Przesunięcie przez wiatr (podmuch Podniebnych wysp, wciąganie wichrowca i trąby): o `offset` px w świecie,
## w granicach lochu i poza ozdobami; nie w czasie wyskoku ani po śmierci.
func drift(offset: Vector2) -> void:
	if dead or leaping():
		return
	position = _push_out((position + offset).clamp(bounds.position, bounds.end))


## Czy postać jest w trakcie ruchu wymuszonego (wyskok, krok).
func leaping() -> bool:
	return _leap_time > 0.0


## Nietykalność na `time` s (kontra Riposty).
func protect(time: float) -> void:
	_invulnerable = maxf(_invulnerable, time)


## Spowolnienie od potwora (`fraction` szybkości mniej przez `time` s; mocniejsze wygrywa, czas się odnawia)
## i barwa postaci (woda - niebieska, lód - jasnobłękitna) do końca spowolnienia.
func slow(fraction: float, time: float, color := Color(0.6, 0.8, 1.2)) -> void:
	if dead:
		return
	chill = maxf(chill if chill_left > 0.0 else 0.0, clampf(fraction, 0.0, 0.8))
	chill_left = maxf(chill_left, time)
	_chill_color = color
	_sprite.self_modulate = color


## Podpalenie: przez `time` s co BURN_TICK s traci `damage` zdrowia (silniejsze podpalenie wygrywa, czas się
## odnawia). Pierwszy płomień po BURN_TICK s.
func ignite(damage: int, time: float) -> void:
	if dead or damage <= 0:
		return
	if burn_left <= 0.0:
		_burn_next = BURN_TICK
	damage = roundi(damage * enemy_damage)
	burn_damage = maxi(burn_damage if burn_left > 0.0 else 0, damage)
	burn_left = maxf(burn_left, time)


## Płomień podpalenia: bez nietykalności, błysku i wibracji (żeby nie zasłaniać ciosów potworów), mała liczba.
func _burn_hit() -> void:
	var amount := maxi(1, roundi(burn_damage * (1.0 - element_res)))
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	_spawn_text("-%d" % amount, Color(1.0, 0.6, 0.25))
	_check_death()


## Porażenie piorunem: przez `time` s postać dostaje więcej obrażeń (SHOCK_MULT) i miga na żółto.
func shock(time: float) -> void:
	if not dead:
		shock_left = maxf(shock_left, time)


## Trafienie przez potwora: czerwony błysk, liczba nad głową, krótka nietykalność; przy zerze - śmierć.
## Garda Riposty (`parry_left`) blokuje cios i wysyła `parried`. `element` - żywioł ciosu (Elements; nie fizyczny -
## mniej o odporność na żywioły, liczba w kolorze żywiołu).
func take_damage(amount: int, element := Elements.PHYSICAL) -> void:
	if dead or _invulnerable > 0.0:
		return
	if parry_left > 0.0 or (parry_chance > 0.0 and randf() < parry_chance):
		parry_left = 0.0
		_invulnerable = INVULNERABLE
		_spawn_text(tr("Riposta!"), Color(0.6, 0.88, 1.0))
		parried.emit()
		return
	_invulnerable = HIT_INVULNERABLE
	if dodge > 0.0 and randf() < dodge:
		_spawn_text(tr("Unik!"), Color(0.75, 0.9, 1.0))
		dodged.emit()
		return
	amount = roundi(amount * enemy_damage)
	var res := element_res if element != Elements.PHYSICAL else 0.0
	var guard := 1.0 - stone if stone > 0.0 and hp < max_hp * Auras.STONE_BELOW else 1.0  # Kamienna Krew
	if fortify_left > 0.0:  # kamień Twardość
		guard *= 1.0 - fortify_pct
	guard *= 1.0 - bastion_res  # Ostatnia Warownia
	amount = maxi(1, roundi(amount * (1.0 - protection) * (1.0 - res) * guard * (SHOCK_MULT if shock_left > 0.0 else 1.0)))
	if mana_shield > 0.0 and mana > 0:  # Nić Mokoszy: część ciosu bierze mana
		var from_mana := mini(roundi(amount * mana_shield), mana)
		if from_mana > 0:
			mana -= from_mana
			amount -= from_mana
			mana_changed.emit(mana, max_mana)
			if amount <= 0:
				_spawn_text("-%d" % from_mana, Color(0.45, 0.65, 1.0))
				return
	if shield_max > 0:
		_shield_wait = Auras.MOKOSZ_DELAY
		if shield > 0:  # Opieka Mokoszy: tarcza bierze cios na siebie
			var absorbed := mini(shield, amount)
			shield -= absorbed
			amount -= absorbed
			shield_changed.emit(shield, shield_max)
			if amount <= 0:
				_spawn_text("-%d" % absorbed, Auras.color_of("mokosz").lightened(0.3))
				return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	hurt.emit(amount)
	_spawn_text("-%d" % amount, Color(1.0, 0.4, 0.35) if element == Elements.PHYSICAL \
			else Elements.COLORS.get(element, Color.WHITE).lerp(Color(1.0, 0.4, 0.35), 0.3))
	Input.vibrate_handheld(30)
	var tween := _sprite.create_tween()
	_sprite.modulate = Color(2.2, 0.5, 0.45)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.25)
	_check_death()


## Cios wroga chybił przez aurę Mgła Nawii albo oślepienie Prawią (`prawia`; ProtoTarget.hit_hero) - napis w kolorze przyczyny.
func enemy_missed(prawia := false) -> void:
	if not dead:
		_spawn_text(tr("Chybił!"), Elements.color_of(Elements.PRAWIA) if prawia else Auras.color_of("mgla").lightened(0.3))


## Zdrowie spadło do zera: śmierć (albo w trybie nieśmiertelności - złoty błysk i pełne zdrowie).
func _check_death() -> void:
	if hp == 0 and immortal:
		deaths += 1
		hp = max_hp
		health_changed.emit(hp, max_hp)
		_sprite.modulate = Color(2.4, 2.0, 0.9)  # złoty błysk zamiast śmierci
		death_avoided.emit(deaths)
		return
	if hp == 0:
		dead = true
		# padnięcie: postać przechyla się i ciemnieje (Wojciech z Watry nie ma animacji śmierci)
		_play("idle")
		var fall := _sprite.create_tween()
		fall.tween_property(_sprite, "rotation", PI / 2.0 * (-1.0 if _sprite.flip_h else 1.0), 0.35).set_ease(Tween.EASE_IN)
		fall.parallel().tween_property(_sprite, "position:y", 8.0, 0.35)
		fall.tween_property(_sprite, "modulate", Color(0.45, 0.4, 0.4), 0.4)
		died.emit()


## Leczenie (kamień Krwiopijca) - bez liczby nad głową, żeby nie zasłaniać walki.
func heal(amount: int) -> void:
	if dead or amount <= 0 or hp >= max_hp:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


## Mana za trafienie (kamień Oszczędność w zwykłym ciosie).
func add_mana(amount: int) -> void:
	if dead or amount <= 0 or mana >= mana_cap():
		return
	mana = mini(mana + amount, mana_cap())
	mana_changed.emit(mana, max_mana)


## Ile many można mieć najwyżej (pełna mana bez rezerwacji aur).
func mana_cap() -> int:
	return maxi(max_mana - reserved - summon_reserved, 0)


## Po zmianie rezerwacji przywołania: mana przycięta do nowej granicy, pasek odświeżony.
func apply_reserve() -> void:
	mana = mini(mana, mana_cap())
	mana_changed.emit(mana, max_mana)


## Kamień Twardość: przez `time` s o `pct` mniej obrażeń (silniejsza wygrywa, czas się odnawia).
func fortify(pct: float, time: float) -> void:
	if fortify_left <= 0.0 or pct >= fortify_pct:
		fortify_pct = pct
	fortify_left = maxf(fortify_left, time)


## Czy stać postać na umiejętność za `cost` many (z Krwawym Sercem - zdrowiem; zawsze musi zostać choć 1 zdrowia).
func can_pay(cost: int) -> bool:
	if _blood() > 0.0:
		return hp > roundi(cost * _blood())
	return mana >= cost


## Wydaje manę na umiejętność (z Krwawym Sercem - zdrowie). Zwraca false (i nic nie zabiera), gdy jej brakuje.
func spend_mana(amount: int) -> bool:
	if _blood() > 0.0:
		var life := roundi(amount * _blood())
		if life >= hp:
			return false
		hp -= life
		health_changed.emit(hp, max_hp)
		mana_spent.emit(amount)
		return true
	if amount > mana:
		return false
	mana -= amount
	mana_changed.emit(mana, max_mana)
	mana_spent.emit(amount)
	return true


## Ile zdrowia za 1 manę płacą umiejętności (Krwawe Serce, Korona Czarnoboga; 0 - płacą maną).
func _blood() -> float:
	return maxf(blood_magic, 1.0) if crown else blood_magic


## Skok Mgnienia do punktu `to` (świat; w granicach areny, poza przeszkodami): gasnący niebieskawy cień w miejscu
## startu, postać patrzy w stronę skoku, 0,15 s nietykalności. Zwraca punkt, w którym wylądowała (świat).
func teleport(to: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	var local := parent.to_local(to) if parent else to
	local = _push_out(local.clamp(bounds.position, bounds.end))
	if parent:
		var ghost := Sprite2D.new()
		ghost.texture = _sprite.texture
		ghost.hframes = _sprite.hframes
		ghost.vframes = _sprite.vframes
		ghost.frame = _sprite.frame
		ghost.flip_h = _sprite.flip_h
		ghost.offset = _sprite.offset
		ghost.position = position
		ghost.modulate = Color(0.6, 0.75, 1.0, 0.6)
		parent.add_child(ghost)
		var fade := ghost.create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, 0.25)
		fade.tween_callback(ghost.queue_free)
	var dir := local - position
	if dir.length() > 0.5:
		facing = dir.normalized()
	position = local  # bez nietykalności (decyzja autora 13.11.2026 - Mgnienie jak Flicker Strike)
	_update_frame()
	return parent.to_global(local) if parent else local


## Ustawia zdrowie i manę według poziomu postaci i przedmiotów (`gear` - Items.totals; pełne).
func set_level(level: int, items_gear := {}) -> void:
	apply_gear(level, items_gear)
	hp = max_hp
	health_changed.emit(hp, max_hp)
	mana = mana_cap()
	mana_changed.emit(mana, max_mana)


## Zabity potwór (ProtoHorde): premia przedmiotów kill_haste_pct przyspiesza na Items.KILL_HASTE_TIME (dłużej
## z premią czasu działania - duration_pct).
func on_kill() -> void:
	if kill_haste > 0.0:
		haste_left = Items.KILL_HASTE_TIME * (1.0 + gear.get("duration_pct", 0.0) / 100.0)


## Przyspieszenie po zabiciu teraz (ułamek; 0 - nie działa).
func haste() -> float:
	return kill_haste if haste_left > 0.0 else 0.0


## Przelicza cechy z poziomu i przedmiotów bez leczenia (zmiana ekwipunku w trakcie wyprawy): przyrost
## największego zdrowia i many dolicza się do obecnych, spadek tylko je przycina.
func apply_gear(level: int, items_gear: Dictionary) -> void:
	gear = items_gear
	_mana_regen = HeroLevels.mana_regen(level) + gear.get("mana_regen", 0.0)
	var new_hp := HeroStats.max_hp(level, gear)
	var new_mana := HeroStats.max_mana(level, gear)
	var new_reserved := HeroStats.reserved_mana(level, gear)
	hp = clampi(hp + maxi(new_hp - max_hp, 0), 0 if dead else 1, new_hp)
	# wyłączona aura nie dolewa many od razu (inaczej włączanie i wyłączanie w pauzie napełniałoby pasek)
	mana = clampi(mana + maxi(new_mana - max_mana, 0), 0, new_mana - new_reserved)
	max_hp = new_hp
	max_mana = new_mana
	reserved = new_reserved
	_mana_regen += new_mana * gear.get("aura_mana_regen_pct", 0.0)
	move_mult = 1.0 + gear.get("move_pct", 0.0) / 100.0
	kill_haste = gear.get("kill_haste_pct", 0.0) / 100.0
	regen = HeroStats.regen(level, gear)
	protection = gear.get("protection_pct", 0.0) / 100.0
	max_res_bonus = gear.get("aura_max_res", 0.0) / 100.0
	element_res = minf(gear.get("element_res_pct", 0.0) / 100.0, Elements.MAX_RESISTANCE + max_res_bonus)
	stone = gear.get("aura_stone", 0.0)
	var new_shield := roundi(max_hp * gear.get("aura_shield_pct", 0.0))
	if new_shield != shield_max:
		shield_max = new_shield
		shield = mini(shield, shield_max) if shield_max > 0 else 0
		_shield_wait = minf(_shield_wait, 0.5)  # nowa tarcza wkrótce się napełni
		shield_changed.emit(shield, shield_max)
	dodge = gear.get("dodge_pct", 0.0) / 100.0
	health_changed.emit(hp, max_hp)
	mana_changed.emit(mana, max_mana)


## Awans: nowe zdrowie (pełne), złoty błysk, słup światła, napis „Poziom N!” nad głową i dźwięk. Gra się nie zatrzymuje.
func level_up(level: int) -> void:
	if dead:
		return
	set_level(level, gear)
	_sprite.modulate = Color(2.4, 2.0, 0.9)
	var tween := _sprite.create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.6)
	var glow := _LevelGlow.new()
	glow.z_index = 15
	add_child(glow)
	float_text(tr("Poziom %d!") % level, -62.0)
	var sound := AudioStreamPlayer.new()
	sound.stream = LEVEL_UP_SOUND
	sound.volume_db = -4.0
	add_child(sound)
	sound.play()
	sound.finished.connect(sound.queue_free)
	Input.vibrate_handheld(60)


## Napis nad postacią, który unosi się i gaśnie (awans, nowa umiejętność z mistrzostwa broni); `y` - wysokość startu.
func float_text(text: String, y: float, color := Color(1.0, 0.86, 0.4), size := 16, seconds := 1.4) -> Label:
	var num := Label.new()
	num.text = text
	num.add_theme_font_size_override("font_size", size)
	num.add_theme_color_override("font_color", color)
	num.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	num.add_theme_constant_override("outline_size", 5)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(200, 20)
	num.position = Vector2(-100, y)
	num.z_index = 21
	add_child(num)
	var up := num.create_tween()
	up.tween_property(num, "position:y", num.position.y - 22, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	up.parallel().tween_property(num, "modulate:a", 0.0, 0.5).set_delay(seconds - 0.4)
	up.tween_callback(num.queue_free)
	return num


## Nowa umiejętność odblokowana mistrzostwem broni: niebieski napis wyżej niż napis awansu, dłużej widoczny.
func skill_unlocked(skill_name: String) -> void:
	if dead:
		return
	float_text(tr("Nowa umiejętność: %s!") % skill_name, -84.0, Color(0.6, 0.85, 1.0), 13, 2.4)


## Słup złotego światła przy awansie: rośnie od stóp w górę i gaśnie (rysowany w kodzie, bez tekstur).
class _LevelGlow extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / 0.25, 0.0, 1.0)
		var fade := 1.0 - clampf((_t - 0.4) / 0.6, 0.0, 1.0)
		var h := 70.0 * k
		for i in 4:  # kilka nakładających się pasów - miękki brzeg
			var w := 18.0 - i * 4.0
			draw_rect(Rect2(-w / 2.0, -h, w, h), Color(1.0, 0.82, 0.35, 0.12 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))  # krąg na ziemi spłaszczony jak w widoku 3/4
		draw_arc(Vector2.ZERO, 6.0 + 20.0 * k, 0.0, TAU, 24, Color(1.0, 0.85, 0.4, 0.7 * fade), 2.0)


## Wypycha punkt z przeszkód (okręgi spłaszczone w pionie).
func _push_out(p: Vector2) -> Vector2:
	for o in obstacles:
		var d := Vector2(p.x - o.x, (p.y - o.y) * 2.0)
		if d.length() < o.z:
			d = (d if d.length() > 0.01 else Vector2.DOWN).normalized() * o.z
			p = Vector2(o.x + d.x, o.y + d.y / 2.0)
	return p


## Napis nad głową, który unosi się i znika (liczba obrażeń, „Unik!”).
func _spawn_text(text: String, color: Color) -> void:
	var num := Label.new()
	num.text = text
	num.add_theme_font_size_override("font_size", 12)
	num.add_theme_color_override("font_color", color)
	num.add_theme_color_override("font_outline_color", Color(0.15, 0.04, 0.04))
	num.add_theme_constant_override("outline_size", 4)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(60, 16)
	num.position = Vector2(-30, -60)
	num.z_index = 20
	add_child(num)
	var tween := num.create_tween()
	tween.tween_property(num, "position:y", num.position.y - 16, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(num, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(num.queue_free)


## Gest ręką w stronę celu - wywołuje broń, gdy zaczyna zamach. Tylko w miejscu (w marszu postać tylko idzie).
func play_gesture(toward: Vector2) -> void:
	if not gesture or dead or velocity.length() > 5.0:
		return
	facing = (toward - global_position).normalized()
	_anim = "slash"
	_time = 0.0


func _play(anim: String) -> void:
	if anim != _anim:
		_anim = anim
		_time = 0.0


func _update_frame() -> void:
	# kąt 0 = wschód, rośnie zgodnie z ruchem wskazówek (oś Y w dół); kierunki co 45 stopni
	var octant := wrapi(roundi(facing.angle() / (PI / 4.0)), 0, 8)  # 0 e, 1 se, 2 s, 3 sw, 4 w, 5 nw, 6 n, 7 ne
	var dir: int = [2, 1, 0, 1, 2, 3, 4, 3][octant]
	_sprite.flip_h = octant in [3, 4, 5]
	var frame := int(_time * FPS[_anim]) % FRAMES
	_sprite.frame = (ANIMS.find(_anim) * DIRS + dir) * FRAMES + frame  # idle, walk, slash to 3 pierwsze animacje arkusza


static func _shadow_texture() -> Texture2D:
	var img := Image.create(14, 5, false, Image.FORMAT_RGBA8)
	for y in 5:
		for x in 14:
			var d := Vector2((x - 6.5) / 7.0, (y - 2.0) / 2.5).length()
			if d < 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.35))
	return ImageTexture.create_from_image(img)

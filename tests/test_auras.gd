extends SceneTree
## Test aur: dane wszystkich aur, limit rezerwacji many, włączanie w zakładce „Aury” okna pauzy, premie postaci
## (Krzepa, Wiatr Strzyboga), piorun Gniewu Peruna w kukłę, zapis włączonych aur.
## Z oknem (tools/screenshot.sh) zapisuje zrzut zakładki i polany z kręgami:
## SCRIPT=tests/test_auras.gd tools/screenshot.sh <folder>

var _failed := 0
var _shots := ""


func _initialize() -> void:
	var game := root.get_node("Game")
	game.save_path = "user://test_savegame.json"
	game.auras.clear()
	game.save_game()
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and DisplayServer.get_name() != "headless":
		_shots = args[0]
		DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _shot(name: String) -> void:
	if _shots == "":
		return
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(_shots.path_join(name + ".png"))


func _run() -> void:
	var game := root.get_node("Game")
	# dane
	_check(AuraData.ORDER.size() == 21 and AuraData.DATA.size() == 21, "21 aur na liście")
	var bad := AuraData.ORDER.filter(func(id: String) -> bool:
		var r := AuraData.reserve_of(id)
		return not AuraData.DATA.has(id) or r < 0.15 or r > 0.35 or AuraData.effect_text(id) == "")
	_check(bad.is_empty(), "każda aura ma dane, opis i rezerwację 15-35%% %s" % [bad])
	_check(AuraData.block_reason("perun", ["strzybog"]) == "", "2 aury mieszczą się w limicie")
	_check(AuraData.block_reason("krzepa", ["strzybog", "perun"]) != "", "trzecia droga aura się nie mieści")
	_check(AuraData.block_reason("krzepa", ["strzybog", "perun"], 0.3) == "", "redukcja rezerwacji robi miejsce")

	var arena: Node = load("res://scenes/prototype.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var hero: ProtoHero = arena.hero
	var menu: PauseMenu = arena.pause_menu
	var health := hero.max_health()
	arena._open_menu()
	menu.auras_tab.button_pressed = true
	_check(menu._aura_page.visible and not menu._game_page.visible, "zakładka Aury otwiera listę")
	menu.aura_toggles["krzepa"].button_pressed = true
	menu.aura_toggles["perun"].button_pressed = true
	_check(game.auras == ["krzepa", "perun"], "przełączniki włączają aury")
	menu.aura_toggles["strzybog"].button_pressed = true
	_check(not game.auras.has("strzybog") and not menu.aura_toggles["strzybog"].button_pressed
			and menu._aura_message.text != "", "za mało many: przełącznik wraca, jest komunikat")
	_check(hero.max_health() > health * 1.15, "Krzepa podnosi zdrowie (%.0f -> %.0f)" % [health, hero.max_health()])
	_check(is_equal_approx(hero.max_mana(), hero.full_mana() * 0.4), "aury rezerwują 60%% many (wolne %.0f)" % hero.max_mana())
	_check(hero.mana <= hero.max_mana(), "mana nie wychodzi ponad wolną")
	await _shot("1_aury")
	menu.close()

	# Gniew Peruna: piorun w najbliższą kukłę w ciągu 3 s
	var dummy: ProtoDummy = arena.weapon.targets[0]
	var before: int = dummy._count
	await create_timer(AuraData.PERUN_INTERVAL + 0.3).timeout
	_check(dummy._count > before or arena.weapon.targets.any(func(d: ProtoDummy) -> bool: return d._count > 0),
			"Gniew Peruna trafia kukłę")
	await _shot("2_polana")

	# zapis
	game.load_game()
	_check(game.auras == ["krzepa", "perun"], "włączone aury wracają po wczytaniu")
	game.auras.clear()
	game.save_game()
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)

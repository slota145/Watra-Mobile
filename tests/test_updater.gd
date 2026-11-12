extends SceneTree
## Test aktualizacji bez całego apk (Updater): mini-serwer HTTP w teście udaje gałąź `apk` na GitHubie
## (version.json i game.pck zrobiona przez PCKPacker). Sprawdza: brak nowej wersji, pobranie paczki z sumą SHA-256,
## złą sumę, wymaganie nowego apk i wczytanie paczki (plik z paczki widoczny jako res://).
## Uruchom z argumentem: godot --headless --path . -s res://tests/test_updater.gd -- --with-updates

const DIR := "user://test_update"
const SRV := "user://test_update_srv"
const PROBE := "res://updater_probe.txt"

var _failed := 0
var _server := TCPServer.new()
var _files: Dictionary = {}  # ścieżka -> bajty


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed += 1
	print(("OK   " if ok else "FAIL ") + what)


func _process(_delta: float) -> bool:
	_serve()
	return false


## Najprostszy serwer HTTP: jedno zapytanie na połączenie, odpowiedź i zamknięcie. Bez czekania w miejscu -
## połączenia czekają na zapytanie w kolejnych klatkach (klient HTTPRequest też działa w głównym wątku).
var _peers: Array = []  # [peer, odebrany tekst]


func _serve() -> void:
	while _server.is_connection_available():
		_peers.append([_server.take_connection(), ""])
	for entry in _peers.duplicate():
		var peer: StreamPeerTCP = entry[0]
		peer.poll()
		if peer.get_available_bytes() > 0:
			entry[1] += peer.get_utf8_string(peer.get_available_bytes())
		if not entry[1].contains("\r\n\r\n"):
			continue
		var path: String = entry[1].get_slice(" ", 1).get_slice("?", 0)
		var body: PackedByteArray = _files.get(path, PackedByteArray())
		var status := "200 OK" if _files.has(path) else "404 Not Found"
		var head := "HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [status, body.size()]
		peer.put_data(head.to_utf8_buffer())
		peer.put_data(body)
		peer.disconnect_from_host()
		_peers.erase(entry)


func _wait_state(updater: Node, states: Array) -> void:
	for i in 600:
		if updater.state in states:
			return
		await process_frame


func _publish(build: int, apk: int, sha_ok := true) -> void:
	DirAccess.make_dir_recursive_absolute(SRV)
	var src := SRV + "/probe.txt"
	var f := FileAccess.open(src, FileAccess.WRITE)
	f.store_string("kompilacja %d" % build)
	f.close()
	var pck_path := SRV + "/game.pck"
	var packer := PCKPacker.new()
	packer.pck_start(pck_path)
	packer.add_file(PROBE, src)
	packer.flush()
	var pck := FileAccess.get_file_as_bytes(pck_path)
	_files["/game.pck"] = pck
	var sha := FileAccess.get_sha256(pck_path) if sha_ok else "zla_suma"
	_files["/version.json"] = JSON.stringify({"build": build, "apk": apk, "size": pck.size(), "sha256": sha}).to_utf8_buffer()


func _run() -> void:
	var updater: Node = root.get_node("Updater")
	_check(updater.enabled, "aktualizacje włączone argumentem --with-updates")
	_check(_server.listen(0, "127.0.0.1") == OK, "mini-serwer działa")
	updater.base_url = "http://127.0.0.1:%d/" % _server.get_local_port()
	updater.dir = DIR
	DirAccess.remove_absolute(DIR + "/game.pck")
	DirAccess.remove_absolute(DIR + "/info.json")
	updater.build = 5

	_publish(5, updater.APK_LEVEL)
	updater.check()
	await _wait_state(updater, ["up_to_date", "available", "error", "need_apk"])
	_check(updater.state == "up_to_date", "ta sama kompilacja - brak aktualizacji (%s)" % updater.state)

	_publish(7, updater.APK_LEVEL + 1)
	updater.check()
	await _wait_state(updater, ["up_to_date", "available", "error", "need_apk"])
	_check(updater.state == "need_apk", "nowszy poziom apk - prośba o całą grę (%s)" % updater.state)

	_publish(7, updater.APK_LEVEL, false)
	updater.check()
	await _wait_state(updater, ["up_to_date", "available", "error", "need_apk"])
	updater.download()
	await _wait_state(updater, ["ready", "error"])
	_check(updater.state == "error" and not FileAccess.file_exists(DIR + "/game.pck"), "zła suma SHA-256 - paczka odrzucona")

	_publish(8, updater.APK_LEVEL)
	updater.check()
	await _wait_state(updater, ["up_to_date", "available", "error", "need_apk"])
	_check(updater.state == "available", "nowa kompilacja dostępna (%s)" % updater.state)
	updater.download()
	await _wait_state(updater, ["ready", "error"])
	_check(updater.state == "ready" and FileAccess.file_exists(DIR + "/game.pck"), "paczka pobrana i sprawdzona (%s)" % updater.state)
	var info: Dictionary = updater._read_json(DIR + "/info.json")
	_check(int(info.get("build", 0)) == 8, "zapisany numer kompilacji paczki")

	# wczytanie przy starcie: apk ma kompilację 5, paczka 8
	updater.base_build = 5
	_check(not FileAccess.file_exists(PROBE), "przed wczytaniem pliku z paczki nie ma")
	updater._load_pack()
	_check(updater.pack_loaded and updater.build == 8, "paczka wczytana, działa kompilacja 8")
	_check(FileAccess.get_file_as_string(PROBE) == "kompilacja 8", "plik z paczki widoczny w grze")

	# nowszy apk niż paczka - paczka usunięta
	updater.pack_loaded = false
	updater.base_build = 9
	updater._load_pack()
	_check(not updater.pack_loaded and not FileAccess.file_exists(DIR + "/game.pck"), "stara paczka usunięta po nowym apk")

	_server.stop()
	print("WYNIK: %s" % ("wszystko OK" if _failed == 0 else "%d błędów" % _failed))
	quit(1 if _failed else 0)

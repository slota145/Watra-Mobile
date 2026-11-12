extends Node
## Aktualizacje wersji testowej bez pobierania całego apk (autoload "Updater", PIERWSZY na liście autoloadów).
## Apk = silnik Godota (około 25 MB, zmienia się rzadko) + gra. Samą grę (skrypty, sceny, grafiki - kilka MB)
## tools/publish_apk.sh wrzuca też osobno jako paczkę game.pck na gałąź `apk`, razem z version.json
## (numer kompilacji, wymagany poziom apk, rozmiar i suma SHA-256 paczki).
## - Przy starcie (_init, zanim Godot wczyta inne autoloady i scenę startową) pobrana wcześniej paczka
##   user://update/game.pck zastępuje pliki gry z apk - o ile jest nowsza od apk i pasuje do jego poziomu.
## - Menu sprawdza version.json (check) i na życzenie gracza pobiera paczkę (download); nowa wersja działa
##   po ponownym uruchomieniu gry.
## Działa tylko w wyeksportowanej grze (w edytorze i testach - z argumentem --with-updates).
## Paczka przenosi skrypty (także nowe klasy class_name i autoload Game), sceny, grafiki i dźwięki - sprawdzone
## na wyeksportowanej grze. NIE przenosi zmian project.godot (ustawienia, lista autoloadów), export_presets.cfg
## (uprawnienia, ikona), tego pliku i wersji Godota - wtedy podbij APK_LEVEL, a gra poprosi o pobranie całości.

signal state_changed(state: String)

## Poziom apk: podbij przy każdej zmianie, której paczka nie przeniesie (patrz wyżej).
const APK_LEVEL := 1
const BASE_URL := "https://raw.githubusercontent.com/slota145/Watra-Mobile/apk/"
const APK_URL := "https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk"
## Numer kompilacji wpisywany przy eksporcie (tools/publish_apk.sh; w repozytorium go nie ma).
const BUILD_INFO := "res://build_info.json"

## Adres plików aktualizacji (testy podmieniają go na lokalny serwer).
var base_url := BASE_URL
## Folder z pobraną paczką (testy używają osobnego).
var dir := "user://update"
var enabled := false
## Kompilacja z apk i ta, która działa (apk albo wczytana paczka).
var base_build := 0
var build := 0
var pack_loaded := false
## idle, checking, up_to_date, available, downloading, ready, need_apk, error
var state := "idle"
## Zawartość version.json z serwera.
var remote: Dictionary = {}
var _http: HTTPRequest
var _step := ""


func _init() -> void:
	enabled = OS.has_feature("template") or "--with-updates" in OS.get_cmdline_user_args()
	base_build = int(_read_json(BUILD_INFO).get("build", 0))
	build = base_build
	if enabled:
		_load_pack()


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 60.0
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


## Wczytuje pobraną paczkę, jeśli jest nowsza od apk i zrobiona dla tego poziomu apk; przestarzałą usuwa.
func _load_pack() -> void:
	if not FileAccess.file_exists(_pack()):
		return
	var info := _read_json(_info())
	if int(info.get("apk", -1)) != APK_LEVEL or int(info.get("build", 0)) <= base_build:
		DirAccess.remove_absolute(_pack())  # nowszy apk albo paczka do innego apk
		return
	if ProjectSettings.load_resource_pack(_pack(), true):
		pack_loaded = true
		build = int(info.get("build", 0))


## Pyta serwer o najnowszą kompilację (bez pobierania paczki).
func check() -> void:
	if not enabled or state in ["checking", "downloading"]:
		return
	_step = "check"
	_set_state("checking")
	# parametr t omija pamięć podręczną serwera (GitHub trzyma pliki do 5 minut)
	if _http.request(base_url + "version.json?t=%d" % Time.get_unix_time_from_system()) != OK:
		_set_state("error")


## Pobiera nową paczkę (po check ze stanem "available").
func download() -> void:
	if state != "available":
		return
	DirAccess.make_dir_recursive_absolute(dir)
	_step = "download"
	_http.download_file = _pack() + ".part"
	_set_state("downloading")
	if _http.request(base_url + "game.pck?b=%d" % int(remote.get("build", 0))) != OK:
		_set_state("error")


## Postęp pobierania 0..1.
func progress() -> float:
	var total := int(remote.get("size", 0))
	return clampf(float(_http.get_downloaded_bytes()) / total, 0.0, 1.0) if total > 0 else 0.0


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var step := _step
	_http.download_file = ""
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_set_state("error")
		return
	if step == "check":
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data is Dictionary:
			_set_state("error")
			return
		remote = data
		if int(remote.get("build", 0)) <= build:
			_set_state("up_to_date")
		elif int(remote.get("apk", 0)) > APK_LEVEL:
			_set_state("need_apk")
		else:
			_set_state("available")
	elif step == "download":
		var part := _pack() + ".part"
		if FileAccess.get_sha256(part) != str(remote.get("sha256", "")):
			DirAccess.remove_absolute(part)
			_set_state("error")
			return
		DirAccess.rename_absolute(part, _pack())
		var f := FileAccess.open(_info(), FileAccess.WRITE)
		f.store_string(JSON.stringify({"build": int(remote.build), "apk": int(remote.apk)}))
		f.close()
		_set_state("ready")


func _pack() -> String:
	return dir + "/game.pck"


func _info() -> String:
	return dir + "/info.json"


func _set_state(s: String) -> void:
	state = s
	state_changed.emit(s)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

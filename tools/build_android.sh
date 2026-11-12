#!/usr/bin/env bash
# Buduje wersję testową na Androida (build/WatraMobile.apk) i samą grę do aktualizacji w grze (build/game.pck)
# w chmurze (Linux, bez monitora). Numer kompilacji (liczba commitów) trafia do build_info.json w grze.
# Za pierwszym razem doinstalowuje, czego brakuje (około minuty):
#   - z szablonów eksportu Godota tylko pliki Androida (bez pobierania całego archiwum 1,3 GB),
#   - Android SDK: build-tools (apksigner, zipalign) w /opt/android-sdk,
#   - ścieżki w ustawieniach edytora Godota.
# Podpis: klucz testowy z repozytorium (tools/android/debug.keystore, hasło "android") - ten sam w każdej sesji,
# więc nowa wersja instaluje się na telefonie na starej bez odinstalowywania. To NIE jest klucz do Sklepu Play.
# Użycie: tools/build_android.sh
set -euo pipefail

project="$(cd "$(dirname "$0")/.." && pwd)"
version="4.7.2"
templates="$HOME/.local/share/godot/export_templates/$version.stable"
sdk="/opt/android-sdk"
settings="$HOME/.config/godot/editor_settings-4.7.tres"
java_home="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"

if [[ ! -f "$templates/android_debug.apk" ]]; then
    echo "Pobieranie szablonów Androida dla Godota $version..."
    mkdir -p "$templates"
    (cd "$templates" && python3 "$project/tools/android/remote_unzip.py" \
        "https://github.com/godotengine/godot/releases/download/$version-stable/Godot_v$version-stable_export_templates.tpz" \
        version.txt android_debug.apk android_release.apk)
fi

if [[ ! -x "$sdk/build-tools/35.0.0/apksigner" ]]; then
    echo "Instalowanie Android SDK (build-tools)..."
    mkdir -p "$sdk/cmdline-tools"
    tmp="$(mktemp -d)"
    curl -sSLf -o "$tmp/t.zip" https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
    unzip -q "$tmp/t.zip" -d "$tmp"
    rm -rf "$sdk/cmdline-tools/latest" && mv "$tmp/cmdline-tools" "$sdk/cmdline-tools/latest"
    rm -rf "$tmp"
    yes | "$sdk/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$sdk" "build-tools;35.0.0" "platform-tools" >/dev/null
fi

# ustawienia edytora: plik tworzy pierwsze uruchomienie Godota
[[ -f "$settings" ]] || godot --headless --path "$project" --quit >/dev/null 2>&1 || true
python3 - "$settings" "$sdk" "$java_home" <<'PY'
import sys
path, sdk, java = sys.argv[1:]
want = {"export/android/android_sdk_path": sdk, "export/android/java_sdk_path": java}
try:
    lines = open(path, encoding="utf-8").read().splitlines()
except FileNotFoundError:
    lines = ['[gd_resource type="EditorSettings" format=3]', "", "[resource]"]
lines = [l for l in lines if l.split(" = ")[0] not in want]
lines += ['%s = "%s"' % kv for kv in want.items()]
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$project/tools/android/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

mkdir -p "$project/build"
# numer kompilacji w grze (Updater porównuje go z version.json na gałęzi apk)
printf '{"build": %d, "commit": "%s"}\n' "$(git -C "$project" rev-list --count HEAD)" \
    "$(git -C "$project" rev-parse --short HEAD)" > "$project/build_info.json"
godot --headless --path "$project" --import >/dev/null 2>&1 || true
godot --headless --path "$project" --export-debug "Android - testy" "$project/build/WatraMobile.apk" 2>&1 \
    | grep -E "ERROR|DONE" || true
# sama gra bez silnika - do aktualizacji w grze (przycisk „Aktualizuj”)
godot --headless --path "$project" --export-pack "Android - testy" "$project/build/game.pck" 2>&1 \
    | grep -E "ERROR|DONE" || true
ls -lh "$project/build/WatraMobile.apk" "$project/build/game.pck"

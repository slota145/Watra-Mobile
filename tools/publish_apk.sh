#!/usr/bin/env bash
# Buduje wersję na Androida (tools/build_android.sh) i wrzuca ją na gałąź `apk` w GitHubie,
# skąd autor pobiera ją na telefonie: https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk
# Obok apk leży game.pck (sama gra, kilka MB) i version.json (kompilacja, poziom apk z scripts/updater.gd,
# rozmiar i SHA-256 paczki) - z nich korzysta przycisk „Aktualizuj” w menu gry (Updater).
# Gałąź `apk` ma zawsze jeden commit i jest nadpisywana (force push), żeby repozytorium
# nie puchło o 28 MB przy każdej wersji. Uruchamiaj po każdym scaleniu do main.
# Użycie: tools/publish_apk.sh
set -euo pipefail

project="$(cd "$(dirname "$0")/.." && pwd)"
"$project/tools/build_android.sh"

version="$(grep -m1 '^config/version=' "$project/project.godot" | cut -d'"' -f2)"
commit="$(git -C "$project" rev-parse --short HEAD)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q -b apk
cp "$project/build/WatraMobile.apk" "$project/build/game.pck" .
build="$(git -C "$project" rev-list --count HEAD)"
apk_level="$(grep -m1 '^const APK_LEVEL' "$project/scripts/updater.gd" | grep -o '[0-9]\+')"
printf '{"build": %d, "commit": "%s", "apk": %d, "size": %d, "sha256": "%s"}\n' "$build" "$commit" "$apk_level" \
    "$(stat -c %s game.pck)" "$(sha256sum game.pck | cut -d' ' -f1)" > version.json
cat > README.md <<TXT
# Watra Mobile - wersja testowa na Androida

Wersja $version, kompilacja $build (kod: $commit). Pobierz \`WatraMobile.apk\` na telefonie, otwórz i zainstaluj.
Kolejne wersje gra pobiera sama (przycisk „Aktualizuj” w menu: game.pck + version.json).
Ta gałąź trzyma tylko najnowsze pliki (bez kodu gry).
TXT
git add -A
git -c user.name="$(git -C "$project" log -1 --format=%an)" -c user.email="$(git -C "$project" log -1 --format=%ae)" \
    commit -qm "Wersja testowa $version na Androida (kod $commit)"
git remote add origin "$(git -C "$project" remote get-url origin)"
for i in 1 2 3 4; do
    git push -q -f origin apk && break
    sleep $((2 ** i))
done
echo "Gotowe: https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk"

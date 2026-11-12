#!/usr/bin/env bash
# Buduje wersję na Androida (tools/build_android.sh) i wrzuca ją na gałąź `apk` w GitHubie,
# skąd autor pobiera ją na telefonie: https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk
# Gałąź `apk` ma zawsze jeden commit (plik + README) i jest nadpisywana (force push), żeby repozytorium
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
cp "$project/build/WatraMobile.apk" .
cat > README.md <<TXT
# Watra Mobile - wersja testowa na Androida

Wersja $version (kod: $commit). Pobierz \`WatraMobile.apk\` na telefonie, otwórz i zainstaluj.
Ta gałąź trzyma tylko najnowszy plik (bez kodu gry).
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

#!/bin/bash
# Na starcie sesji w chmurze: pilnuje, żeby praca szła na najnowszej wersji gry (origin/main).
# Powód (19.11.2026): jedna sesja wystartowała z kodu sprzed tygodnia i robiła od nowa rzeczy, które już były.
# - gałąź bez własnych commitów i bez zmian w plikach, a za main -> przestawiana na origin/main (nic nie ginie);
# - gałąź z własną pracą, a za main -> tylko ostrzeżenie (trzeba scalić origin/main, zanim PR).
# Wypisany tekst trafia do kontekstu sesji.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! timeout 60 git fetch -q origin main 2>/dev/null; then
	echo "UWAGA (hook startowy): nie udało się pobrać origin/main - sprawdź ręcznie, czy praca idzie na najnowszej wersji gry."
	exit 0
fi

main=$(git rev-parse origin/main)
if git merge-base --is-ancestor "$main" HEAD; then
	echo "Hook startowy: gałąź zawiera najnowszy main ($(git log -1 --format='%h %s' "$main"))."
	exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD)
own=$(git rev-list --count "$main"..HEAD)
behind=$(git rev-list --count HEAD.."$main")
if [ "$branch" != "HEAD" ] && [ "$own" = "0" ] && [ -z "$(git status --porcelain --untracked-files=no)" ]; then
	git checkout -q -B "$branch" "$main"
	echo "Hook startowy: gałąź $branch była $behind commitów za main (stara wersja gry) - przestawiona na origin/main ($(git log -1 --format='%h %s' "$main"))."
else
	echo "UWAGA (hook startowy): gałąź $branch jest $behind commitów ZA origin/main i ma $own własnych commitów lub zmiany w plikach."
	echo "Pracujesz na starszej wersji gry. Zanim cokolwiek zmienisz: git fetch origin main && git merge --no-edit origin/main (albo zacznij od origin/main). Powiedz o tym autorowi."
fi
exit 0

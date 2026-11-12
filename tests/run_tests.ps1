<#
Uruchamia wszystkie testy gry (tests/*.gd) w Godocie i podsumowuje wyniki.
Testy z oknem (zrzuty, mysz, interfejs) otwierają na chwilę okno gry; reszta działa bez okna.
Zapisy testów idą do user://test_savegame.json - prawdziwy zapis gracza zostaje nietknięty.

Użycie:  powershell -File tests/run_tests.ps1 [-Godot <ścieżka do Godot_v4.7.2-stable_win64_console.exe>]
Ścieżkę do Godota można też podać w zmiennej środowiskowej GODOT.
#>
param([string]$Godot = $env:GODOT)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Host "Podaj ścieżkę do Godota: -Godot <plik .exe> albo zmienna GODOT" -ForegroundColor Red
    exit 2
}
$out = Join-Path ([System.IO.Path]::GetTempPath()) "watra_mobile_tests"
New-Item -ItemType Directory -Force $out | Out-Null

# [plik, czy potrzebuje okna]
$tests = @(
    @("test_project.gd", $false)
)

Write-Host "Import zasobów..."
$p = Start-Process $Godot -ArgumentList "--path", $project, "--headless", "--import" -PassThru -NoNewWindow `
    -RedirectStandardOutput "$out\import_out.txt" -RedirectStandardError "$out\import_err.txt"
$p.WaitForExit(300000) | Out-Null

$failed = 0
foreach ($t in $tests) {
    $name = $t[0]
    $args = @("--path", $project)
    if ($t[1]) { $args += @("--resolution", "450x800") } else { $args += "--headless" }
    $args += @("-s", (Join-Path $PSScriptRoot $name))
    $log = $name -replace "[^A-Za-z0-9_.]", "_"
    $p = Start-Process $Godot -ArgumentList $args -PassThru -NoNewWindow `
        -RedirectStandardOutput "$out\$log.out.txt" -RedirectStandardError "$out\$log.err.txt"
    $timeout = 180000
    if (-not $p.WaitForExit($timeout)) { $p.Kill(); Write-Host "[CZAS] $name" -ForegroundColor Red; $failed++; continue }
    $lines = Get-Content "$out\$log.out.txt" -Encoding UTF8
    # błędy skryptów i zgłaszane przez silnik pomyłki (zwolnione obiekty w listach, błędne wywołania)
    $errors = Get-Content "$out\$log.err.txt" -Encoding UTF8 | Select-String "SCRIPT ERROR|Parse Error|Attempted to|Error calling"
    $bad = $lines | Select-String -CaseSensitive "^FAIL|BLAD|: BLAD"
    $good = ($lines | Select-String "^OK|: OK|WYNIK: OK|^===").Count
    if ($errors -or $bad -or $good -eq 0) {
        $failed++
        Write-Host "[BŁĄD] $name" -ForegroundColor Red
        $bad | ForEach-Object { Write-Host "    $_" }
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" }
    } else {
        Write-Host "[OK]   $name ($good)" -ForegroundColor Green
    }
}
Write-Host ""
if ($failed -eq 0) { Write-Host "Wszystkie testy przeszły." -ForegroundColor Green } else { Write-Host "Nieudane: $failed" -ForegroundColor Red }
exit $failed

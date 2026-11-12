# Watra Mobile na telefonie z Androidem

Jak zrobić plik `.apk` i wgrać grę na własny telefon.

## Najprościej: Claude buduje plik w chmurze

Poproś Claude o „zbudowanie apk”. Claude uruchamia `tools/build_android.sh` (sam doinstalowuje szablony Godota
i narzędzia Androida) i wrzuca plik na gałąź `apk`. Na telefonie otwórz w przeglądarce
https://github.com/slota145/Watra-Mobile/raw/apk/WatraMobile.apk, otwórz pobrany plik, zgódź się na instalację
z nieznanego źródła - i gotowe. Każda nowa wersja instaluje się na poprzedniej
(ten sam klucz testowy z `tools/android/debug.keystore`), a zapis i ustawienia zostają.

## Samodzielnie na komputerze

Robi się to raz; potem wystarczy „Export” w Godocie.

## Raz, na początek (Windows)

1. **Szablony eksportu Godota:** w Godocie menu *Editor → Manage Export Templates → Download and Install*
   (wersja 4.7.2, ok. 1 GB).
2. **Java (JDK 17):** w PowerShell:
   ```powershell
   winget install EclipseAdoptium.Temurin.17.JDK
   ```
3. **Android SDK:** zainstaluj Android Studio (`winget install Google.AndroidStudio`), uruchom je raz i pozwól pobrać SDK.
4. W Godocie *Editor → Editor Settings → Export → Android* wskaż:
   - *Java SDK Path*: folder JDK (np. `C:\Program Files\Eclipse Adoptium\jdk-17...`),
   - *Android SDK Path*: zwykle `C:\Users\slota\AppData\Local\Android\Sdk`.
   - *Debug Keystore*: plik `tools/android/debug.keystore` z repozytorium (użytkownik `androiddebugkey`,
     hasło `android`) - wtedy wersje z komputera i z chmury instalują się jedna na drugiej.

## Za każdym razem

1. W Godocie *Project → Export*, wybierz **„Android - testy”** i *Export Project* (plik trafia do `build/`).
2. Wyślij `build/WatraMobile.apk` na telefon (kabel, Dysk Google, mail) i otwórz go. Telefon zapyta o zgodę na
   instalację z nieznanego źródła - zgódź się dla tej jednej aplikacji.

## Szybciej: gra od razu na telefonie przez kabel

Włącz na telefonie *Opcje programisty → Debugowanie USB*, podłącz kabel i kliknij w Godocie ikonkę Androida
w prawym górnym rogu (*Remote Debug*). Gra uruchomi się na telefonie, a błędy pokażą się w Godocie.

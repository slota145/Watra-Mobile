# Watra Mobile na telefonie z Androidem

Jak zrobić plik `.apk` i wgrać grę na własny telefon. Robi się to raz; potem wystarczy „Export” w Godocie.

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
   Godot sam utworzy klucz do podpisywania wersji testowych (debug keystore).

## Za każdym razem

1. W Godocie *Project → Export*, wybierz **„Android - testy”** i *Export Project* (plik trafia do `build/`).
2. Wyślij `build/WatraMobile.apk` na telefon (kabel, Dysk Google, mail) i otwórz go. Telefon zapyta o zgodę na
   instalację z nieznanego źródła - zgódź się dla tej jednej aplikacji.

## Szybciej: gra od razu na telefonie przez kabel

Włącz na telefonie *Opcje programisty → Debugowanie USB*, podłącz kabel i kliknij w Godocie ikonkę Androida
w prawym górnym rogu (*Remote Debug*). Gra uruchomi się na telefonie, a błędy pokażą się w Godocie.

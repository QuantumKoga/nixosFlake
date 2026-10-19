{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
  }
}:

pkgs.mkShell {
  name = "air-umu";

  packages = with pkgs; [
    umu-launcher
    winetricks
    curl
    cabextract
  ];

  shellHook = ''
    export WINEPREFIX="$HOME/Games/adobeAir"

    export TMPDIR="/tmp"
    export TMP="$TMPDIR"
    export TEMP="$TMPDIR"

    export WINEESYNC=0
    export WINEFSYNC=0

    AIR="$HOME/.cache/air/AdobeAIRInstaller.exe"
    AIR_URL="https://archive.org/download/adobe-airinstaller/AdobeAIRInstaller.exe"

    mkdir -p "$HOME/Games" "$(dirname "$AIR")"

    # Sprawdzenie obecności bibliotek runtime Adobe AIR
    air_installed() {
      [ -f "$WINEPREFIX/drive_c/Program Files/Common Files/Adobe AIR/Versions/1.0/Adobe AIR.dll" ] ||
      [ -f "$WINEPREFIX/drive_c/Program Files (x86)/Common Files/Adobe AIR/Versions/1.0/Adobe AIR.dll" ]
    }

    echo "======================================"
    echo " Adobe AIR + UMU"
    echo " Prefix: $WINEPREFIX"
    echo "======================================"

    # Przygotowanie zależności gry tylko raz
    if [ ! -f "$WINEPREFIX/.air-runtime-ready" ]; then
      echo ">>> Instalowanie zależności Windows przez UMU..."

      if ! umu-run winetricks -q settings win7; then
        echo "Błąd konfiguracji prefixu."
        return 1
      fi

      if ! umu-run winetricks -q vcrun2010 gdiplus corefonts; then
        echo "Błąd instalacji zależności."
        return 1
      fi

      touch "$WINEPREFIX/.air-runtime-ready"
    fi

    # Pobranie instalatora Adobe AIR
    if [ ! -f "$AIR" ]; then
      echo ">>> Pobieranie instalatora Adobe AIR..."

      if ! curl -fL "$AIR_URL" -o "$AIR"; then
        echo "Nie udało się pobrać Adobe AIR."
        return 1
      fi
    fi

    # Instalacja AIR tylko wtedy, gdy brakuje runtime
    if ! air_installed; then
      echo ">>> Adobe AIR nie został wykryty."
      echo ">>> Uruchamiam instalator przez umu-run..."

      umu-run "$AIR"

      if ! air_installed; then
        echo ""
        echo "Nie potwierdzono instalacji Adobe AIR."
        echo "Sprawdź, czy instalator zakończył się poprawnie."
        return 1
      fi
    else
      echo ">>> Adobe AIR jest już zainstalowany."
    fi

    # Funkcja uruchamiająca grę
    run-game() {
      if ! air_installed; then
        echo "Brak Adobe AIR. Nie uruchamiam gry."
        return 1
      fi

      if [ "$#" -ne 1 ]; then
        echo 'Użycie: run-game "/ścieżka/do/Game.exe"'
        return 2
      fi

      if [ ! -f "$1" ]; then
        echo "Nie znaleziono pliku: $1"
        return 1
      fi

      echo ">>> Uruchamiam grę przez UMU..."
      umu-run "$1"
    }

    echo ""
    echo "Środowisko gotowe."
    echo 'Uruchom grę: run-game "/ścieżka/do/Game.exe"'
    echo "======================================"
  '';
}

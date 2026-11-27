
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

    # Check whether the Adobe AIR runtime libraries are installed
    air_installed() {
      [ -f "$WINEPREFIX/drive_c/Program Files/Common Files/Adobe AIR/Versions/1.0/Adobe AIR.dll" ] ||
      [ -f "$WINEPREFIX/drive_c/Program Files (x86)/Common Files/Adobe AIR/Versions/1.0/Adobe AIR.dll" ]
    }

    echo "======================================"
    echo " Adobe AIR + UMU"
    echo " Prefix: $WINEPREFIX"
    echo "======================================"

    # Set up game dependencies only once
    if [ ! -f "$WINEPREFIX/.air-runtime-ready" ]; then
      echo ">>> Installing Windows dependencies via UMU..."

      if ! umu-run winetricks -q settings win7; then
        echo "Failed to configure the Wine prefix."
        return 1
      fi

      if ! umu-run winetricks -q vcrun2010 gdiplus corefonts; then
        echo "Failed to install dependencies."
        return 1
      fi

      touch "$WINEPREFIX/.air-runtime-ready"
    fi

    # Download the Adobe AIR installer
    if [ ! -f "$AIR" ]; then
      echo ">>> Downloading the Adobe AIR installer..."

      if ! curl -fL "$AIR_URL" -o "$AIR"; then
        echo "Failed to download Adobe AIR."
        return 1
      fi
    fi

    # Install AIR only if the runtime is missing
    if ! air_installed; then
      echo ">>> Adobe AIR runtime was not detected."
      echo ">>> Launching the installer via umu-run..."

      umu-run "$AIR"

      if ! air_installed; then
        echo ""
        echo "Adobe AIR installation could not be verified."
        echo "Check whether the installer completed successfully."
        return 1
      fi
    else
      echo ">>> Adobe AIR is already installed."
    fi

    # Function for launching the game
    run-game() {
      if ! air_installed; then
        echo "Adobe AIR is missing. Cannot launch the game."
        return 1
      fi

      if [ "$#" -ne 1 ]; then
        echo 'Usage: run-game "/path/to/Game.exe"'
        return 2
      fi

      if [ ! -f "$1" ]; then
        echo "File not found: $1"
        return 1
      fi

      echo ">>> Launching the game via UMU..."
      umu-run "$1"
    }

    echo ""
    echo "Environment is ready."
    echo 'Launch the game: run-game "/path/to/Game.exe"'
    echo "======================================"
  '';
}

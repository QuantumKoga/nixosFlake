
{ pkgs ? import <nixpkgs> {} }:

let
  #flake = builtins.getFlake (toString ../.);

  #pkgs-unstable = import flake.inputs.nixpkgs-unstable {
  #  system = "x86_64-linux";
  #  config.allowUnfree = true;
  #};

  #wine = pkgs-unstable.wineWow64Packages.unstable.override {
  #  x11Support = false;
  #  waylandSupport = true;
  #};

  wine = pkgs.wineWow64Packages.stable;

  prefix = "$HOME/.local/share/wineprefixes/pkhex";

  dotnetVersion = "10.0.15";
  dotnetUrl =
    "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/${dotnetVersion}/windowsdesktop-runtime-${dotnetVersion}-win-x64.exe";

  ensureDotnet = pkgs.writeShellScriptBin "pkhex-ensure-dotnet" ''
    set -e

    export WINEPREFIX="${prefix}"

    DOTNET_DIR="$WINEPREFIX/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App"

    # Sprawdź, czy jest już zainstalowany .NET Desktop Runtime 10.x.
    if [ -d "$DOTNET_DIR/10.0.15" ]; then
      echo ".NET Desktop Runtime 10.x jest już zainstalowany."
      exit 0
    fi

    echo "Nie znaleziono .NET Desktop Runtime 10.x."
    echo "Przygotowuję prefix Wine..."

    mkdir -p "$WINEPREFIX"
    ${wine}/bin/wineboot -u

    # Katalog cache poza środowiskiem Nix.
    CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/pkhex"
    INSTALLER="$CACHE/windowsdesktop-runtime-${dotnetVersion}-win-x64.exe"

    mkdir -p "$CACHE"

    if [ ! -f "$INSTALLER" ]; then
      echo "Pobieranie .NET Desktop Runtime ${dotnetVersion}..."

      ${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --retry 3 \
        --output "$INSTALLER.tmp" \
        "${dotnetUrl}"

      mv "$INSTALLER.tmp" "$INSTALLER"
    else
      echo "Znaleziono instalator w cache."
    fi

    echo "Instalowanie .NET Desktop Runtime..."

    ls "$HOME/.local/share/wineprefixes/pkhex/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/"

    # Sprawdź faktyczny rezultat instalacji.
    if [ ! -d "$DOTNET_DIR/10.0.15" ]; then
      echo "BŁĄD: nie znaleziono .NET Desktop Runtime 10.0.15."
      echo "Sprawdź instalację w prefixie Wine."
      exit 1
    fi

    echo ".NET Desktop Runtime został zainstalowany poprawnie."
  '';

  pkhex = pkgs.writeShellScriptBin "pkhex" ''
    export WINEPREFIX="${prefix}"

    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_SYSTEM_GLOBALIZATION_PREDEFINED_CULTURES_ONLY=0

    EXE="''${PKHEX_EXE:-$PWD/PKHeX.exe}"

    if [ ! -f "$EXE" ]; then
      echo "Nie znaleziono PKHeX.exe: $EXE"
      echo "Możesz ustawić zmienną PKHEX_EXE."
      exit 1
    fi

    exec ${wine}/bin/wine "$EXE" "$@"
  '';

in

pkgs.mkShell {
  packages = [
    wine
    pkgs.curl
    ensureDotnet
    pkhex
  ];

  shellHook = ''
    echo "Przygotowywanie środowiska PKHeX..."

    if ! pkhex-ensure-dotnet; then
        echo "Nie udało się przygotować środowiska PKHeX."
        return 1
    fi

    echo ""
    echo "Środowisko PKHeX gotowe."
    echo "Uruchom program poleceniem: pkhex"
  '';
}


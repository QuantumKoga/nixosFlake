
{ pkgs ? import <nixpkgs> {} }:

let
  # flake = builtins.getFlake (toString ../.);

  # pkgs-unstable = import flake.inputs.nixpkgs-unstable {
  #   system = "x86_64-linux";
  #   config.allowUnfree = true;
  # };

  # wine = pkgs-unstable.wineWow64Packages.unstable.override {
  #   x11Support = false;
  #   waylandSupport = true;
  # };

  wine = pkgs.wineWow64Packages.stable;

  prefix = "$HOME/.local/share/wineprefixes/pkhex";

  dotnetVersion = "10.0.15";
  dotnetUrl =
    "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/${dotnetVersion}/windowsdesktop-runtime-${dotnetVersion}-win-x64.exe";

  ensureDotnet = pkgs.writeShellScriptBin "pkhex-ensure-dotnet" ''
    set -e

    export WINEPREFIX="${prefix}"

    DOTNET_DIR="$WINEPREFIX/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App"

    # Check whether .NET Desktop Runtime 10.x is already installed.
    if [ -d "$DOTNET_DIR/10.0.15" ]; then
      echo ".NET Desktop Runtime 10.x is already installed."
      exit 0
    fi

    echo ".NET Desktop Runtime 10.x was not found."
    echo "Preparing the Wine prefix..."

    mkdir -p "$WINEPREFIX"
    ${wine}/bin/wineboot -u

    # Cache directory outside the Nix environment.
    CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/pkhex"
    INSTALLER="$CACHE/windowsdesktop-runtime-${dotnetVersion}-win-x64.exe"

    mkdir -p "$CACHE"

    if [ ! -f "$INSTALLER" ]; then
      echo "Downloading .NET Desktop Runtime ${dotnetVersion}..."

      ${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --retry 3 \
        --output "$INSTALLER.tmp" \
        "${dotnetUrl}"

      mv "$INSTALLER.tmp" "$INSTALLER"
    else
      echo "Installer found in cache."
    fi

    echo "Installing .NET Desktop Runtime..."

    ls "$HOME/.local/share/wineprefixes/pkhex/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/"

    # Verify the actual installation result.
    if [ ! -d "$DOTNET_DIR/10.0.15" ]; then
      echo "ERROR: .NET Desktop Runtime 10.0.15 was not found."
      echo "Check the installation in the Wine prefix."
      exit 1
    fi

    echo ".NET Desktop Runtime was installed successfully."
  '';

  pkhex = pkgs.writeShellScriptBin "pkhex" ''
    export WINEPREFIX="${prefix}"

    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export DOTNET_SYSTEM_GLOBALIZATION_PREDEFINED_CULTURES_ONLY=0

    EXE="''${PKHEX_EXE:-$PWD/PKHeX.exe}"

    if [ ! -f "$EXE" ]; then
      echo "PKHeX.exe was not found: $EXE"
      echo "You can set the PKHEX_EXE environment variable."
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
    echo "Preparing the PKHeX environment..."

    if ! pkhex-ensure-dotnet; then
        echo "Failed to prepare the PKHeX environment."
        return 1
    fi

    echo ""
    echo "PKHeX environment is ready."
    echo "Launch the application using: pkhex"
  '';
}

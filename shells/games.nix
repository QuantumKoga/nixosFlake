
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    pkgs.umu-launcher
    #pkgs.proton-ge-bin
    pkgs.gamescope
    pkgs.wineWow64Packages.stable
  ];

  shellHook = ''
    export WINEPREFIX="''${WINEPREFIX:-$HOME/Games/U3D}"
    export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
    export GAME_WIDTH="''${GAME_WIDTH:-1920}"
    export GAME_HEIGHT="''${GAME_HEIGHT:-1080}"
    export GAME_FULLSCREEN="''${GAME_FULLSCREEN:-1}"

    run-game() {
      if [ -z "''${1:-}" ]; then
        echo "Usage: run-game /path/to/game.exe"
        return 1
      fi

      local game
      game="$(realpath "$1")" || return 1

      if [ ! -f "$game" ]; then
        echo "File not found: $game"
        return 1
      fi

      shift
      cd "$(dirname "$game")" || return 1

      echo "Running: $game"
      umu-run "$game" \
        -screen-width "$GAME_WIDTH" \
        -screen-height "$GAME_HEIGHT" \
        -screen-fullscreen "$GAME_FULLSCREEN" \
        "$@"
    }

    echo "Środowisko gier U3D"
    echo "Prefix: $WINEPREFIX"
    echo "Proton: $PROTONPATH"
    echo "Resolution: ''${GAME_WIDTH}x''${GAME_HEIGHT}"
    echo "Run: run-game /path/to/game.exe"
  '';
}

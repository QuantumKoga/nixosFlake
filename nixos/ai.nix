
{ config, pkgs, pkgs-unstable, ... }:

let
  # Pokemon data API from another repo of mine
  pokemonAiPython = pkgs.python3.withPackages (ps: with ps; [
    # Scraper dependencies
    requests
    beautifulsoup4
    lxml
    tqdm

    # Pokémon AI API
    fastapi
    uvicorn
    pydantic
    httpx
    orjson
  ]);
in
{
  # ------------------------------------------------------------
  # SYSTEM BASE PACKAGES
  # ------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    vim
    jq

    # Python environment for Pokémon AI API and scrapers
    pokemonAiPython

    # LLM tooling
    llama-cpp

    # Debugging GPU / system
    pciutils
    usbutils

    # Network debug
    iperf3
    openssl

    # ROCm tools (AMD)
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    rocmPackages.clr
    rocmPackages.rocblas
    rocmPackages.rocsparse
  ];


  # ------------------------------------------------------------
  # NETWORK / LAN ACCESS
  # ------------------------------------------------------------

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22     # SSH
      11434  # Ollama API
      8080   # Open WebUI
      8081   # SearXNG
    ];
  };

  networking.enableIPv6 = false;
  networking.nameservers = [ "192.168.50.1" ];
  services.resolved.enable = false;


  # ------------------------------------------------------------
  # MODELS PARTITION ACCESS
  # ------------------------------------------------------------

  systemd.tmpfiles.rules = [
    "d /data 0755 root root -"
    "d /data/ollama 0755 ollama ollama -"
  ];

  systemd.services.fix-ollama-data-perms = {
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      mkdir -p /data/ollama
      chown -R ollama:ollama /data/ollama
    '';
  };


  # ------------------------------------------------------------
  # SSH SERVER (remote maintenance over LAN)
  # ------------------------------------------------------------

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;   # You can disable this later
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      StreamLocalBindUnlink = true;
    };
  };


  # ------------------------------------------------------------
  # GPU / ACCELERATION BASELINE
  # ------------------------------------------------------------

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  # ------------------------------------------------------------
  # OLLAMA (core LLM runtime)
  # ------------------------------------------------------------

  services.ollama = {
    enable = true;

    package = pkgs-unstable.ollama-rocm;

    home = "/data/ollama";

    # LAN access
    host = "0.0.0.0";
    port = 11434;

    # acceleration = "rocm";
  };


  # ------------------------------------------------------------
  # POKEMON AI API
  # ------------------------------------------------------------

  systemd.services.pokemon-ai-api = {
    description = "Pokemon Champions API";

    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "simple";

      # Dedicated dynamic service user
      DynamicUser = true;

      # Project directory
      WorkingDirectory = "/data/pokemon_ai";

      # Start FastAPI through Uvicorn
      ExecStart = ''
        ${pokemonAiPython}/bin/uvicorn api.main:app \
          --host 127.0.0.1 \
          --port 8000
      '';

      Restart = "on-failure";
      RestartSec = 5;

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;

      ProtectSystem = "strict";
      ProtectHome = true;

      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;

      RestrictSUIDSGID = true;
      LockPersonality = true;

      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
    };
  };


  # ------------------------------------------------------------
  # OPEN WEB UI (chat interface)
  # ------------------------------------------------------------

  services.open-webui = {
    enable = true;

    host = "0.0.0.0";
    port = 8080;

    # package = pkgs.open-webui.override {
    #   python3Packages = pkgs.python312Packages;
    # };

    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";

      ENABLE_WEB_SEARCH = "true";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:8081/search?q=<query>";

      WEB_SEARCH_RESULT_COUNT = "10";

      DEFAULT_MODEL_PARAMS = ''{"function_calling":"native"}'';
    };
  };


  # ------------------------------------------------------------
  # SEARXNG (tool for LLM internet access)
  # ------------------------------------------------------------

  services.searx = {
    enable = true;

    settings = {
      server = {
        bind_address = "0.0.0.0";
        port = 8081;
        limiter = false;
        secret_key = "8855c6d5898e2d49b63275c8d6a0c23c1f983238dea2f549670ffaf399ace6b7";
      };

      search = {
        safe_search = 0;
        formats = [
          "html"
          "json"
        ];
      };
    };
  };


  # ------------------------------------------------------------
  # OPTIONAL: PERFORMANCE TUNING FOR LLM WORKLOADS
  # ------------------------------------------------------------

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };


  # ------------------------------------------------------------
  # USER EXPERIENCE
  # ------------------------------------------------------------

  services.tailscale.enable = false;


  # ------------------------------------------------------------
  # LAN VISIBILITY CONFIGURATION
  # ------------------------------------------------------------

  services.nginx = {
    enable = true;

    virtualHosts."ai.local" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };

      locations."/ollama/" = {
        proxyPass = "http://127.0.0.1:11434";
      };

      locations."/search/" = {
        proxyPass = "http://127.0.0.1:8081";
      };
    };
  };


  # ------------------------------------------------------------
  # HOST NAME
  # ------------------------------------------------------------

  networking.hostName = "minos";
}

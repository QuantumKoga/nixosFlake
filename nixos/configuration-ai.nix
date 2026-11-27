{ config, pkgs, ... }:

{
  system.stateVersion = "26.05";
  imports =
    [ # Include the results of the hardware scan.
      ./ai.nix
      ./security.nix
      ./packages-core.nix
      ./user-quantum.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  networking.interfaces.eno1.ipv4.addresses = [
    {
      address = "192.168.50.11";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.50.1";
  networking.nameservers = [ "192.168.50.1" ];

  systemd.services.disable-wifi = {
    description = "Disable Wi-Fi radio";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
    };
  };

  # Bluetooth settings
  hardware.bluetooth = {
    enable = false;
    powerOnBoot = true;
  };
  services.blueman.enable = false;

}

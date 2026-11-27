{ config, pkgs, ... }:

{
  system.stateVersion = "25.11";
  imports =
    [ # Include the results of the hardware scan.
      ./grub.nix
      ./environment.nix
      ./security.nix
      ./packages-core.nix
      ./user-quantum.nix
      ./gaming.nix
    ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # enable Bluetooth
  services.blueman.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    wireplumber.extraConfig = {
      "alsa" = {
        "monitor.alsa.reserve-device" = false;
      };
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Allow unfree packages and flakes
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}

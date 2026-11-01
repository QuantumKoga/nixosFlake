{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    brave
    gedit
    
    usbutils
    edid-decode
    drm_info
    libdrm

#    python3
  ];

  security.polkit.enable = true;
  programs.zsh.enable = true;
}

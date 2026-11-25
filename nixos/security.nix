{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    yubico-piv-tool
    pcsc-tools
    opensc
    gnupg
    pinentry-qt
  ];

  # =========================
  # GPG + YUBIKEY (CORE FIX)
  # =========================

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    enableExtraSocket = true;
  };

  # PCSC (POPRAWNIE)
  services.pcscd.enable = true;


  environment.sessionVariables = {
    GNUPG_NO_KEYBOXD = "1";
  };

  # =========================
  # PAM CONFIGURATION
  # =========================

  # U2F mapping file managed by NixOS
  environment.etc."u2f_keys" = {
    source = ../keys/u2f_keys;
    mode = "0600";
  };

  # YubiKey authentication
  security.pam.u2f = {
    enable = true;
    control = "sufficient";

    settings = {
      cue = true;
      authfile = "/etc/u2f_keys";
      #debug = true;
      #interactive = true;
    };
  };

  # SSH agent authentication
  security.pam.sshAgentAuth = {
    enable = true;

    # Root-controlled authorized keys file
    authorizedKeysFiles = [
      "/etc/ssh/authorized_keys.d/%u"
    ];
  };

  security.pam.services = {
    sddm = {
      u2f.enable = true;
      unixAuth = false;
    };

    login = {
      u2f.enable = true;
      unixAuth = false;
    };

    sudo = {
      u2f.enable = true;
      sshAgentAuth = true;
      unixAuth = false;
    };
  };
}
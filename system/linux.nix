# Shared configuration for Linux (NixOS) hosts
inputs@{ config, pkgs, ... }:
{
  imports = [ ./packages.nix ];

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
    experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];

  environment.shells =
    let
      users = builtins.filter (user: user.isNormalUser) (builtins.attrValues config.users.users);
      userPaths = builtins.map (user: "/etc/profiles/per-user/${user.name}/bin/nu") users;
    in
    with pkgs;
    [
      nushell
      zsh
    ]
    ++ userPaths;

  # Services
  services.openssh.enable = true;

  # Shells
  programs.zsh.enable = true;
}

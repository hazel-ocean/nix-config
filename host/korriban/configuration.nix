# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
    "pipe-operators"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [
    "amdgpu"
    # "vkms"
    "uinput"
  ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelParams = [
  # "usbcore.autosuspend=-1"
  # "pcie_aspm=off"
  # "video=DP-5:3048x2032R@60D"
  # ];

  # services.udev.packages = [ pkgs.sunshine ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # Firmware
  services.fwupd.enable = true; # Rescue with `system76-firmware-cli schedule --proprietary`
  hardware.system76.enableAll = true;
  hardware.steam-hardware.enable = true;
  hardware.enableAllHardware = true;
  hardware.uinput.enable = true;

  # Microcode updates for Ryzen
  hardware.cpu.amd.updateMicrocode = true;

  # Graphics
  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools

      libva-vdpau-driver
      libvdpau-va-gl
      libva-utils
    ];

    enable32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools

      libva-vdpau-driver
      libvdpau-va-gl
      libva-utils
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  #services.blueman.enable = true;

  networking.hostName = "korriban"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  services.timesyncd.enable = true;

  #### Network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true; # makes .local discovery nicer
    openFirewall = true;
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
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

  services.displayManager.autoLogin = {
    enable = true;
    user = "hazel";
  };
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;
  # services.xserver.videoDrivers
  programs.xwayland.enable = true;
  programs.niri.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  security.pam.services.hazel.kwallet.enable = true;

  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  # Enable the Cosmic Desktop Environment
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;

  fonts.enableDefaultPackages = true;
  fonts.packages = import ../../layers/fonts.nix { inherit pkgs; };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hazel = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Hazel Ocean Lewis";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "render"
      "input"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../pigeon/ssh/id_ed25519.pub
      ../espeon/ssh/id_ed25519.pub
    ];
  };

  programs.bash.enable = true;
  programs.zsh.enable = true;
  # programs.nushell.enable = true;

  # programs.firefox = {
  #   enable = true;
  #   nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  # };
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    ];
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "en-US" ];
    };
  };
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "hazel" ];
  };
  programs.kdeconnect.enable = true;

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    capSysAdmin = true;

    settings = {
      sunshine_name = config.networking.hostName;
      # adapter_name = "/dev/dri/renderD128"; # Radeon 9070 XT
      # capture = "kms";
      encoder = "vaapi";
    };

    applications = {
      apps = [
        {
          name = "Steam Big Picture - 01";
          image = "steam.png";
          auto-detach = "true";
          # gamescope --grab --force-grab-cursor --expose-wayland --prefer-vk-device /dev/dri/renderD128 -W 2048 -H 1330 -r 60 -e \
          # -- \
          cmd = ''
            gamescope --fullscreen --grab --force-grab-cursor --prefer-vk-device /dev/dri/renderD128 -w 1920 -h 1080 -W 2704 -H 1756 -r 80 -- sudo -u hazel setsid steam steam://open/bigpicture
          '';
        }
      ];
    };
  };
  # systemd.user.services.sunshine.serviceConfig.Environment = [
  #   "LIBVA_DRIVER_NAME=radeonsi"
  #   "VAAPI_DEVICE=/dev/dri/renderD128"
  # ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    forceEncodingConfig = true;
    hardwareAcceleration = {
      enable = true;
      device = "/dev/dri/renderD128";
      type = "vaapi";
    };
    transcoding = {
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        vp9 = true;
        hevc = true;
        hevc10bit = true;
        av1 = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = true;
      };
      # enableHardwareEncoding = true;
      # hardware
    };
  };

  services.tailscale.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    with pkgs;
    [
      brave
      # firefoxpwa
      helix
      lapce
      zed-editor
      zellij
      yazi
      ripgrep
      fd
      entr

      dconf-editor
      gnome-tweaks
      gnome-remote-desktop
      ghostty

      wayland-utils
      wl-clipboard
      pciutils
      libva-utils
      radeontop

      tailscale

      jellyfin
      jellyfin-ffmpeg
      jellyfin-desktop
      jellyfin-web

      moonlight-qt
      sunshine
      gamescope
      steam
      steam-run
      protonup-ng
      lutris
      (heroic.override {
        extraPkgs =
          pkgs: with pkgs; [
            gamescope
            gamemode
          ];
      })
      bottles

      vesktop
    ]
    ++ (with pkgs.kdePackages; [
      discover
      kcalc
      ksystemlog
      sddm-kcm
      isoimagewriter
      partitionmanager
    ]);

  environment.sessionVariables = {
    #   AMD_VULKAN_ICSD = "RADV";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/hazel/.steam/root/compatibilitytools.d";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon, start at boot
  boot.initrd.network.ssh.enable = true;
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings.PasswordAuthentication = false;
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [
      config.services.tailscale.port
      3389
    ];
    allowedTCPPorts = [ 3389 ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}:
let
  # Steam is single-instance per user: if a desktop Steam is already running
  # when moonshine launches its own, steam:// actions get forwarded to that
  # existing instance instead of running in moonshine's session, and only the
  # first action (e.g. opening Big Picture) reliably lands. Upstream's fix:
  # https://github.com/hgaiser/moonshine/issues/134
  steamShutdownPreCommand = [
    "${pkgs.bash}/bin/bash"
    "-c"
    ''
      if pgrep -x steam >/dev/null; then
        ${pkgs.steam}/bin/steam -shutdown &>/dev/null
        for i in $(seq 1 30); do
          pgrep -x steam >/dev/null || break
          sleep 1
        done
      fi
    ''
  ];
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../system/linux.nix
    ./kde.nix
    ./niri.nix
    ./wifi-ap.nix
  ];

  boot.initrd.kernelModules = [ "uinput" ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

      # Implicit Vulkan layers must land here (not environment.systemPackages)
      # to be found by /run/opengl-driver/share/vulkan/implicit_layer.d, which
      # is also what Steam's FHS runtime bind-mounts onto its library path.
      vkbasalt
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

  # AirPlay receiver (shairport-sync) runs as a user service via home-manager
  # so it can access the user's PipeWire session and follow KDE audio routing.
  # We just need the firewall ports open and the package available.

  networking.hostName = "korriban"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services.timesyncd.enable = true;

  #### Network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true; # makes .local discovery nicer
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true; # allow user services (e.g. shairport-sync) to advertise via mDNS
    };
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
  # Plasma lives in ./kde.nix; niri (moonshine-streamed only) + noctalia-shell
  # in ./niri.nix and ./home-niri.nix.

  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  # Enable the Cosmic Desktop Environment
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;

  fonts.enableDefaultPackages = true;
  fonts.packages = import ../../system/font-packages.nix { inherit pkgs; };

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
    # systemWide = true;
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
    shell = pkgs.nushell;
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

  programs.gamemode = {
    enable = true;
    enableRenice = true;
  };

  programs.gamescope = {
    enable = true;
    args = [
      "--rt"
      "--fullscreen"
      "-W"
      "3840"
      "-H"
      "2160"
      "-r"
      "120"
      "--hdr-enabled"
      "--force-grab-cursor"
    ];
    env = {
      DXVK_HDR = "1";
      ENABLE_GAMESCOPE_WSI = "1";
    };
  };

  programs.steam = {
    enable = true;
    protontricks.enable = true;
    gamescopeSession = {
      enable = true;
      env = {
        PROTON_ENABLE_WAYLAND = ""; # override the global; empty is the safest "off"
        PROTON_ENABLE_HDR = "";
      };
      steamArgs = [ "-pipewire-dmabuf" ];
    };
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

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
        av1 = true;
        h264 = true;
        hevc = true;
        hevc10bit = true;
        hevcRExt10bit = true;
        hevcRExt12bit = true;
        mpeg2 = true;
        vc1 = true;
        vp8 = true;
        vp9 = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = true;
      };
      enableSubtitleExtraction = true;
      enableToneMapping = true;
    };
  };

  services.moonshine = {
    enable = true;
    user = "hazel";
    uid = 1000; # users.users.hazel has no fixed uid declared; `id -u hazel`
    openFirewall = true; # LAN/tailscale-facing only, per the module's own warning

    settings = {
      name = config.networking.hostName;
      application = [
        {
          title = "Steam";
          command = [
            "${pkgs.steam}/bin/steam"
            "steam://open/bigpicture"
          ];
          pre_command = [ steamShutdownPreCommand ];
        }
      ];
    };
  };

  services.tailscale.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    brave
    firefox
    google-chrome
    helix
    lapce
    # noctalia-git
    vlc
    zed-editor
    zellij
    yazi
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
    nvtopPackages.amd

    tailscale
    shairport-sync

    jellyfin
    jellyfin-ffmpeg
    jellyfin-desktop
    jellyfin-web

    protonup-ng
    protonplus
    lutris
    gamescope-wsi
    mangojuice
    (heroic.override {
      extraPkgs =
        pkgs: with pkgs; [
          gamescope
          gamemode
        ];
    })
    bottles

    vesktop
    discord-canary

    jq
    pulseaudio
  ];

  environment.sessionVariables = {
    DXVK_HDR = "1";
    ENABLE_LAYER_MESA_ANTI_LAG = "1";
    PROTON_FSR4_RDNA3_UPGRADE = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_ENABLE_HDR = "1";
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
    settings = {
      PasswordAuthentication = false;
      ClientAliveInterval = 30;
      ClientAliveCountMax = 3;
    };
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    logRefusedPackets = true;
    logRefusedConnections = true;
    allowedUDPPorts = [
      config.services.tailscale.port
      3389
    ]
    ++ (builtins.genList (i: 6001 + i) 11); # UDP 6001-6011 for AirPlay audio
    allowedTCPPorts = [
      3389
      5000 # AirPlay RTSP (shairport-sync)
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

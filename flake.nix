{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    zjstatus.url = "github:dj95/zjstatus";
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-nixos = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    home-manager-master = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    helix = {
      url = "github:helix-editor/helix";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    tuios = {
      url = "github:Gaurav-Gosain/tuios";
      inputs.nixpkgs.follows = "nixpkgs-unstable"; # keep it compatible with your pkgs
    };
  };

  outputs =
    inputs@{
      # self,
      home-manager-master,
      home-manager-nixos,
      nixpkgs-unstable,
      nixos-stable,
      nix-darwin,
      flake-utils,
      zjstatus,
      helix,
      tuios,
      nixos-raspberrypi,
      ...
    }:
    let
      baseOverlays = [
        (final: prev: {
          zjstatus = zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
          helix-latest = helix.packages.${prev.stdenv.hostPlatform.system}.default;
        })
        (import ./overlay/vimPlugins.nix)
      ];
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = baseOverlays;
        isDarwin = builtins.elem system [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        nixpkgs = if isDarwin then nixpkgs-unstable else nixos-stable;
      in
      {
        devShells.default = import ./shell.nix {
          inherit nix-darwin;
          pkgs = import nixpkgs { inherit overlays system config; };
        };
      }
    )
    // {
      nixosConfigurations.ghastly =
        let
          system = "aarch64-linux";
          overlays = baseOverlays;
        in
        nixos-stable.lib.nixosSystem rec {
          inherit system;
          modules = [
            ./host/ghastly/configuration.nix
            home-manager-nixos.nixosModules.home-manager
            {
              home-manager.users.ocean = import ./home/console-user.nix {
                pkgs = import nixos-stable { inherit overlays system config; };
                config = {
                  user = "ocean";
                  home = "/home/ocean";
                  state_version = "22.11";
                };
                theme-config.helix = "base16_transparent";
              };
            }
          ];
        };

      nixosConfigurations.korriban =
        let
          system = "x86_64-linux";
          overlays = baseOverlays;
        in
        nixpkgs-unstable.lib.nixosSystem {
          inherit system;
          modules = [
            ./host/korriban/configuration.nix
            home-manager-master.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.hazel = import ./home/desktop-user.nix {
                username = "hazel";
                homeDirectory = "/home/hazel";
                stateVersion = "25.11";
                imports = [ ];
              };
            }
          ];
        };

      nixosConfigurations.rpi5 = nixos-raspberrypi.lib.nixosInstaller {
        specialArgs = inputs;
        modules = [
          {
            # Hardware specific configuration, see section below for a more complete
            # list of modules
            imports = with nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.display-vc4
              raspberry-pi-5.display-rp1
              raspberry-pi-5.bluetooth
            ];
          }

          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              networking.hostName = "rpi5-demo";

              system.nixos.tags =
                let
                  cfg = config.boot.loader.raspberryPi;
                in
                [
                  "raspberry-pi-${cfg.variant}"
                  cfg.bootloader
                  config.boot.kernelPackages.kernel.version
                ];
            }
          )
        ];
      };

      darwinConfigurations.pigeon =
        let
          username = "ocean";
          homeDirectory = "/Users/ocean";
          system = "aarch64-darwin";
          overlays = baseOverlays ++ [
            (import ./overlay/theme {
              source = ./host/pigeon/theme.nix;
            })
          ];
        in
        nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs-unstable {
            inherit system config overlays;
          };
          specialArgs = {
            rosetta-pkgs = import nixpkgs-unstable {
              inherit config overlays;
              system = "x86_64-darwin";
            };
          };
          modules = [
            ./host/pigeon/configuration.nix
            home-manager-master.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = (
                  import ./home/desktop-user.nix {
                    inherit username homeDirectory;
                    stateVersion = "24.11";
                    imports = [
                      ./programs/zed
                      ./host/pigeon/home-configuration.nix
                    ];
                  }
                );
              };
            }
          ];
        };

      darwinConfigurations.espeon =
        let
          username = "hazel";
          homeDirectory = "/Users/hazel";
          system = "aarch64-darwin";
          overlays = baseOverlays ++ [
            (final: prev: { tuios = tuios.packages.${system}.default; })
            (import ./overlay/mcp-servers.nix)
            (import ./overlay/theme {
              source = ./host/espeon/theme.nix;
            })
          ];
        in
        nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs-unstable {
            inherit system config overlays;
          };
          specialArgs = { };
          modules = [
            ./host/espeon/configuration.nix
            home-manager-master.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = (
                  import ./home/desktop-user.nix {
                    inherit username homeDirectory;
                    stateVersion = "25.05";
                    imports = [
                      ./programs/zed
                      ./host/espeon/home-configuration.nix
                    ];
                  }
                );
              };
            }
          ];
        };
    };
}

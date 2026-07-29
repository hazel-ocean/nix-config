{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    room.url = "github:rvcas/room";
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-nixos-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    home-manager-nixos-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    home-manager-master = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    helix.url = "github:helix-editor/helix";
    mcp-servers.url = "path:./packages/mcp-servers";
    obsidian-plugins.url = "path:./packages/obsidian-plugins";
    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };
    claude-zellij-whip = {
      url = "github:hazel-ocean/claude-zellij-whip";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{
      home-manager-master,
      home-manager-nixos-stable,
      home-manager-nixos-unstable,
      nixpkgs-unstable,
      nixos-unstable,
      nixos-stable,
      nix-darwin,
      flake-utils,
      room,
      nixos-raspberrypi,
      helix,
      mcp-servers,
      obsidian-plugins,
      ...
    }:
    let
      baseOverlays = [
        (final: prev: {
          room = room.packages.${prev.stdenv.hostPlatform.system}.default;
          helix-latest = helix.packages.${prev.stdenv.hostPlatform.system}.default.override {
            # Filter out the broken grammar
            includeGrammarIf = grammar: grammar.name != "lua-format-string";
          };
          nu-scripts = inputs.nu-scripts;
          claude-zellij-whip =
            inputs.claude-zellij-whip.packages.${prev.stdenv.hostPlatform.system}.default;
        })
        mcp-servers.overlays.default
        obsidian-plugins.overlays.default
        (import ./overlay/vimPlugins.nix)
      ];
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      mkDarwinHost =
        {
          hostname,
          username,
          stateVersion,
          system ? "aarch64-darwin",
          extraImports ? [ ],
          extraSpecialArgs ? { },
        }:
        let
          homeDirectory = "/Users/${username}";
          overlays = baseOverlays ++ [
            (import ./overlay/theme { source = ./host/${hostname}/theme.nix; })
          ];
        in
        nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs-unstable { inherit system config overlays; };
          specialArgs = extraSpecialArgs;
          modules = [
            ./host/${hostname}/configuration.nix
            home-manager-master.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./home/desktop-user.nix {
                  inherit username homeDirectory stateVersion;
                  imports = [
                    ./programs/zed
                    ./host/${hostname}/home-configuration.nix
                  ]
                  ++ extraImports;
                };
              };
            }
          ];
        };

      mkNixosHost =
        {
          hostname,
          username,
          stateVersion,
          system,
          nixpkgs ? nixos-unstable,
          home-manager ? home-manager-nixos-unstable,
          extraImports ? [ ],
          extraSpecialArgs ? { },
          extraModules ? [ ],
        }:
        let
          homeDirectory = "/home/${username}";
          overlays = baseOverlays ++ [
            (import ./overlay/theme { source = ./host/${hostname}/theme.nix; })
            (final: prev: {
              openldap = prev.openldap.overrideAttrs (_: {
                doCheck = !prev.stdenv.hostPlatform.isi686;
              });
            })
          ];
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = extraSpecialArgs;
          modules = [
            ./host/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs = {
                inherit config overlays;
              };
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.${username} = import ./home/desktop-user.nix {
                  inherit username homeDirectory stateVersion;
                  imports = [
                    ./programs/zed
                    ./host/${hostname}/home-configuration.nix
                  ]
                  ++ extraImports;
                };
              };
            }
          ]
          ++ extraModules;
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
            home-manager-nixos-stable.nixosModules.home-manager
            {
              home-manager.users.ocean = import ./home/console-user.nix {
                username = "ocean";
                homeDirectory = "/home/ocean";
                stateVersion = "22.11";
              };
            }
          ];
        };

      nixosConfigurations.korriban = mkNixosHost {
        hostname = "korriban";
        username = "hazel";
        stateVersion = "25.11";
        system = "x86_64-linux";
        nixpkgs = nixos-stable;
        home-manager = home-manager-nixos-stable;
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

      darwinConfigurations.pigeon = mkDarwinHost {
        hostname = "pigeon";
        username = "ocean";
        stateVersion = "24.11";
        extraSpecialArgs = {
          rosetta-pkgs = import nixpkgs-unstable {
            inherit config;
            overlays = baseOverlays ++ [
              (import ./overlay/theme { source = ./host/pigeon/theme.nix; })
            ];
            system = "x86_64-darwin";
          };
        };
      };

      darwinConfigurations.espeon = mkDarwinHost {
        hostname = "espeon";
        username = "hazel";
        stateVersion = "25.05";
      };
    };
}

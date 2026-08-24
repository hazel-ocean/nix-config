{
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    room.url = "github:rvcas/room";
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-nixos-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    home-manager-master = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    helix.url = "github:helix-editor/helix";
    mcp-servers.url = "path:./packages/mcp-servers";
    obsidian-plugins.url = "path:./packages/obsidian-plugins";
    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };
    clawd-back = {
      # Local checkout, so a change is testable before it is pushed. Point this
      # back at github:hazel-ocean/clawd-back to build on any other host.
      url = "git+file:///Users/hazel/OneSignal/workbench/workspaces/clawd-back/repo";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    agent-skills = {
      url = "git+ssh://git@github.com/OneSignal/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    moonshine = {
      url = "github:hgaiser/moonshine";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    moonlight-qt-src = {
      url = "git+https://github.com/moonlight-stream/moonlight-qt.git?ref=master&submodules=1";
      flake = false;
    };
    # Pinned to the commit moonlight-qt's dependency bump targets, since it
    # postdates libplacebo's last tagged release.
    libplacebo-src = {
      url = "github:haasn/libplacebo/4d82c6898551068d4ae6a6b5538efcddc2c7cf64";
      flake = false;
    };
  };

  outputs =
    inputs@{
      determinate,
      home-manager-master,
      home-manager-nixos-unstable,
      nixpkgs-unstable,
      nixos-unstable,
      nixos-stable,
      nix-darwin,
      flake-utils,
      room,
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
            # upstream: none filed; drop when the lua-format-string grammar builds.
            includeGrammarIf = grammar: grammar.name != "lua-format-string";
          };
          nu-scripts = inputs.nu-scripts;
          clawd-back =
            inputs.clawd-back.packages.${prev.stdenv.hostPlatform.system}.default;
          onesignal-repos-mcp =
            inputs.agent-skills.packages.${prev.stdenv.hostPlatform.system}.repos-mcp;
          onesignal-plugins = inputs.agent-skills.lib.plugins;
        })
        mcp-servers.overlays.default
        obsidian-plugins.overlays.default
        (import ./overlay/patches.nix)
        (import ./overlay/vimPlugins.nix)
        (import ./overlay/moonlight-qt.nix {
          src = inputs.moonlight-qt-src;
          libplaceboSrc = inputs.libplacebo-src;
        })
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
          extraModules ? [ ],
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
                  inherit
                    hostname
                    username
                    homeDirectory
                    stateVersion
                    ;
                  imports = [
                    ./programs/zed
                    ./host/${hostname}/home-configuration.nix
                  ]
                  ++ extraImports;
                };
              };
            }
          ] ++ extraModules;
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
                  inherit
                    hostname
                    username
                    homeDirectory
                    stateVersion
                    ;
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
      nixosConfigurations.korriban = mkNixosHost {
        hostname = "korriban";
        username = "hazel";
        stateVersion = "25.11";
        system = "x86_64-linux";
        nixpkgs = nixos-unstable;
        home-manager = home-manager-nixos-unstable;
        extraModules = [ inputs.moonshine.nixosModules.default ];
        extraImports = [ inputs.noctalia-shell.homeModules.default ];
      };

      darwinConfigurations.pigeon = mkDarwinHost {
        hostname = "pigeon";
        username = "hazel";
        stateVersion = "24.11";
        extraModules = [
          determinate.darwinModules.default
 
          ({ ... }: {
            # Enable the Determinate Nix module
            determinateNix.enable = true;
          })
        ];
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

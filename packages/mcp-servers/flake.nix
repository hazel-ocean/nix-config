{
  inputs = {
    mcp-obsidian-src = {
      url = "github:bitbonsai/mcp-obsidian/main";
      flake = false;
    };

    mcp-things-src = {
      url = "github:hald/things-mcp/master";
      flake = false;
    };

    mcp-slack-src = {
      url = "github:korotovsky/slack-mcp-server/master";
      flake = false;
    };

    # uv2nix stack: builds the things-mcp uv workspace hermetically (each
    # wheel/sdist fetched as its own FOD) instead of a network uv sync.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
    };
  };

  outputs =
    {
      mcp-obsidian-src,
      mcp-things-src,
      mcp-slack-src,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    {
      overlays.default = final: prev: {
        mcp-obsidian = final.callPackage ./obsidian.nix { src = mcp-obsidian-src; };
        mcp-things = final.callPackage ./things.nix {
          src = mcp-things-src;
          inherit pyproject-nix uv2nix pyproject-build-systems;
        };
        mcp-slack = final.callPackage ./slack.nix { src = mcp-slack-src; };
      };
    };
}

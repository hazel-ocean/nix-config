{
  inputs = {
    mcp-server-asana-src = {
      url = "github:roychri/mcp-server-asana/v1.6.0";
      flake = false;
    };

    mcp-obsidian-src = {
      url = "github:bitbonsai/mcp-obsidian/main";
      flake = false;
    };

    mcp-things-src = {
      url = "github:hald/things-mcp/v0.6.0";
      flake = false;
    };

    mcp-slack-src = {
      url = "github:korotovsky/slack-mcp-server/v1.1.28";
      flake = false;
    };
  };

  outputs =
    {
      mcp-server-asana-src,
      mcp-obsidian-src,
      mcp-things-src,
      mcp-slack-src,
      ...
    }:
    {
      overlays.default = final: prev: {
        mcp-asana = final.callPackage ./asana.nix { src = mcp-server-asana-src; };
        mcp-obsidian = final.callPackage ./obsidian.nix { src = mcp-obsidian-src; };
        mcp-things = final.callPackage ./things.nix { src = mcp-things-src; };
        mcp-slack = final.callPackage ./slack.nix { src = mcp-slack-src; };
      };
    };
}
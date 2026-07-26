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
  };

  outputs =
    {
      mcp-obsidian-src,
      mcp-things-src,
      mcp-slack-src,
      ...
    }:
    {
      overlays.default = final: prev: {
        mcp-obsidian = final.callPackage ./obsidian.nix { src = mcp-obsidian-src; };
        mcp-things = final.callPackage ./things.nix { src = mcp-things-src; };
        mcp-slack = final.callPackage ./slack.nix { src = mcp-slack-src; };
      };
    };
}

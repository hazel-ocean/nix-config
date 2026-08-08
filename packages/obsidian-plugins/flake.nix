{
  inputs = {
    obsidian-agent-client-src = {
      url = "github:RAIT-09/obsidian-agent-client";
      flake = false;
    };
  };

  outputs =
    {
      obsidian-agent-client-src,
      ...
    }:
    {
      overlays.default = final: prev: {
        obsidian-agent-client = final.callPackage ./obsidian-agent-client.nix {
          src = obsidian-agent-client-src;
        };
      };
    };
}

{
  inputs = {
    obsidian-agent-client-src = {
      url = "github:RAIT-09/obsidian-agent-client";
      flake = false;
    };
    claude-code-acp-src = {
      url = "github:zed-industries/claude-code-acp";
      flake = false;
    };
  };

  outputs =
    {
      obsidian-agent-client-src,
      claude-code-acp-src,
      ...
    }:
    {
      overlays.default = final: prev: {
        obsidian-agent-client = final.callPackage ./obsidian-agent-client.nix {
          src = obsidian-agent-client-src;
        };
        claude-code-acp = final.callPackage ./claude-code-acp.nix {
          src = claude-code-acp-src;
        };
      };
    };
}

# Obsidian Plugins

Nix packages for Obsidian plugins and their dependencies.

## Available Packages

| Package | Description |
|---------|-------------|
| `obsidian-agent-client` | Bring AI agents (Claude Code, Codex, Gemini CLI) into Obsidian via Agent Client Protocol (ACP) |
| `claude-code-acp` | ACP adapter for Claude Code - required dependency for obsidian-agent-client |

## Usage

### 1. Add the overlay to your configuration

In your `flake.nix`, add the overlay:

```nix
overlays = [
  (import ./overlay/obsidian-plugins.nix)
];
```

### 2. Add packages to home-manager

```nix
home.packages = with pkgs; [
  obsidian-agent-client
  claude-code-acp
];
```

### 3. Symlink the plugin into your Obsidian vault

In your home-manager configuration, add an activation script:

```nix
home.activation.obsidianPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run mkdir -p $VERBOSE_ARG \
    "$HOME/path/to/your/vault/.obsidian/plugins/agent-client"

  run ln -fsn $VERBOSE_ARG \
    ${pkgs.obsidian-agent-client}/* \
    "$HOME/path/to/your/vault/.obsidian/plugins/agent-client/"
'';
```

Note: We create the directory first and symlink the *contents* (using `/*`) rather than the directory itself. This allows Obsidian to write plugin-specific files (like `data.json` for settings) to the directory while the plugin code comes from the read-only Nix store.

### 4. Enable the plugin in Obsidian

After rebuilding your Nix configuration, restart Obsidian and enable **Agent Client** in **Settings → Community Plugins**.

## Configuration

### Agent Client Plugin Settings

After installing the plugin, configure it in **Obsidian Settings → Agent Client**:

1. **Node.js path**: The path to your Node.js binary
   ```sh
   which node
   # e.g., /etc/profiles/per-user/$USER/bin/node
   ```

2. **Claude Code ACP path**: The path to the claude-code-acp binary
   ```sh
   which claude-code-acp
   # e.g., /etc/profiles/per-user/$USER/bin/claude-code-acp
   ```

3. **API key** (optional): Your Anthropic API key, or leave empty if logged in via CLI

### Authentication

If you're not using an API key, log in via the Claude CLI first:

```sh
claude
# Follow the prompts to authenticate
```

## How It Works

- **obsidian-agent-client** is the Obsidian plugin that provides the UI and chat interface
- **claude-code-acp** is the Agent Client Protocol adapter that bridges Obsidian to Claude Code

The plugin spawns `claude-code-acp` as a subprocess and communicates with it via the ACP protocol.

## Updating

To update to newer versions:

1. Update the `version` and hashes in the respective `.nix` files
2. Run `nix build .#darwinConfigurations.<host>.pkgs.<package>` to get the new npm deps hash
3. Rebuild your configuration

## References

- [obsidian-agent-client](https://github.com/RAIT-09/obsidian-agent-client)
- [claude-code-acp](https://github.com/zed-industries/claude-code-acp)
- [Agent Client Protocol (ACP)](https://agentclientprotocol.com/)
- [Claude Code](https://www.anthropic.com/claude-code)
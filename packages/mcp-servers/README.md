# MCP Servers

This directory contains Nix packages for [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers, enabling AI assistants like Claude to interact with various applications and services.

## Available Servers

| Package | Command | Description |
|---------|---------|-------------|
| `mcp-things` | `mcp-things` | Interact with Things 3 task manager |
| `mcp-obsidian` | `mcp-obsidian` | Read/write access to Obsidian vaults |

## Installation

All MCP servers are automatically available via the `mcp-servers` overlay. Add the packages you need to your `home.packages`:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-things
    mcp-obsidian
  ];
}
```

Then rebuild your system:

```bash
darwin-rebuild switch --flake ~/.config/nix-config
```

## Configuration

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "things": {
      "command": "/etc/profiles/per-user/$USER/bin/mcp-things",
      "args": []
    },
    "obsidian": {
      "command": "/etc/profiles/per-user/$USER/bin/mcp-obsidian",
      "args": ["/path/to/your/vault"]
    }
  }
}
```

### Claude Code

```bash
# Things
claude mcp add-json things --scope user '{"type":"stdio","command":"/etc/profiles/per-user/$USER/bin/mcp-things","args":[]}'

# Obsidian
claude mcp add-json obsidian --scope user '{"type":"stdio","command":"/etc/profiles/per-user/$USER/bin/mcp-obsidian","args":["/path/to/your/vault"]}'
```

## Server-Specific Setup

### mcp-things

**Prerequisites:**
- Things 3 must be installed and opened at least once
- Enable Things URLs: **Things → Settings → General → Enable Things URLs**

**Example prompts:**
- "What's in my Things inbox?"
- "Create a todo to pack for my vacation next week"
- "Show me tasks that haven't been modified in over a month"

### mcp-obsidian

**Prerequisites:**
- An Obsidian vault (local directory with `.md` files)

**Example prompts:**
- "List files in my Obsidian vault"
- "Read my note called 'project-ideas.md'"
- "Create a new note with today's date"

## Adding a New MCP Server

1. Create a new package file (e.g., `newserver.nix`) in this directory
2. Add the package to `default.nix`:
   ```nix
   { pkgs }:
   {
     mcp-things = pkgs.callPackage ./things.nix { };
     mcp-obsidian = pkgs.callPackage ./obsidian.nix { };
     mcp-newserver = pkgs.callPackage ./newserver.nix { };
   }
   ```
3. Add to your host's `home.packages`
4. Rebuild and configure Claude

## Updating Packages

To update a package to a new version:

1. Update the `version` in the package's `.nix` file
2. Set the hash to `lib.fakeHash` (or an empty placeholder)
3. Run `darwin-rebuild switch` and copy the correct hash from the error
4. Replace the placeholder with the correct hash
5. Rebuild again

## Troubleshooting

### Check Claude Desktop logs

```bash
tail -f ~/Library/Logs/Claude/mcp*.log
```

### Test a server manually

```bash
mcp-things
# or
mcp-obsidian /path/to/vault
```

The server should start and wait for MCP protocol input. Press `Ctrl+C` to exit.

### "Could not attach to MCP" error

- Verify the command path matches `which <command>`
- Check that any required applications are installed and configured
- Restart Claude Desktop after config changes

## Architecture

```
packages/mcp-servers/
├── default.nix      # Exports all servers as an attribute set
├── README.md        # This file
├── obsidian.nix     # mcp-obsidian package (Node.js/npm)
└── things.nix       # mcp-things package (Python/uv)
```

The overlay at `overlay/mcp-servers.nix` makes all packages available as `pkgs.mcp-<name>`.

## References

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [things-mcp](https://github.com/hald/things-mcp)
- [mcp-obsidian](https://github.com/bitbonsai/mcp-obsidian)
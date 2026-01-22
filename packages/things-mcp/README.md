# Things MCP Server

This package integrates [things-mcp](https://github.com/hald/things-mcp) into your Nix configuration, allowing Claude Desktop and Claude Code to interact with Things 3.

## What is Things MCP?

Things MCP is a Model Context Protocol (MCP) server that lets Claude:
- Access your Things inbox, today list, upcoming tasks, etc.
- Create and update tasks and projects
- Search and analyze your tasks
- Help with task management and planning

## Build Status

✅ **Successfully tested and verified!** The package builds correctly and all Python dependencies are properly installed during the Nix build phase.

## How It's Packaged

This package uses Nix to fully build the application:
- **Nix** provides reproducibility and version pinning
- **uv** is used during the build phase to create a Python virtual environment with all dependencies
- The virtual environment is built into the Nix store, making it immutable and reproducible
- All dependencies are pre-installed during build, so there's **no startup delay** or runtime dependency resolution

The package creates a wrapper script that runs:
```bash
/nix/store/.../share/things-mcp/.venv/bin/python /nix/store/.../share/things-mcp/things_server.py
```

This means the MCP server starts instantly when Claude launches it.

## Installation

The package is automatically installed on the `espeon` host via the overlay in `overlay/things-mcp.nix`.

### Step 1: Rebuild your system

```bash
darwin-rebuild switch --flake ~/.config/nix-config
```

This will:
- Download things-mcp v0.6.0 from GitHub
- Build a Python virtual environment with all dependencies using `uv`
- Install the binary to your system

**Note:** The first build may take a few minutes as it downloads and installs all Python dependencies.

### Step 2: Verify installation

```bash
which things-mcp
```

Should output something like: `/nix/store/xxxxx-things-mcp-0.6.0/bin/things-mcp`

## Configuration

### Prerequisites

1. **Things 3** must be installed and have been opened at least once
2. Enable Things URLs: **Things → Settings → General → Enable Things URLs**
3. Install **Claude Desktop** (if not already installed)

### Step 3: Configure Claude Desktop

1. **Copy the things-mcp path** from `which things-mcp`

2. **Edit Claude Desktop config:**
   ```bash
   code ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. **Add the things MCP server:**
   ```json
   {
     "mcpServers": {
       "things": {
         "command": "/etc/profiles/per-user/$USER/bin/things-mcp",
         "args": []
       }
     }
   }
   ```
   
   Replace the path with your actual path from step 1.

4. **Restart Claude Desktop**

### Claude Code Setup (Homebrew)

Since Claude Code is managed via Homebrew, you can configure it using the same Nix-built binary:

```bash
claude mcp add-json things --scope user '{"type":"stdio","command":"/etc/profiles/per-user/$USER/bin/things-mcp","args":[]}'
```

## Usage

After setup, you can ask Claude:
- "What's in my Things inbox?"
- "Create a todo to pack for my beach vacation next week"
- "Show me tasks that haven't been modified in over a month"
- "Help me conduct a GTD-style weekly review"
- "Evaluate my current todos using the Eisenhower matrix"

## Updating

To update to a new version of things-mcp:

1. **Update the version in `packages/things-mcp/default.nix`:**
   ```nix
   version = "0.7.0";  # new version
   rev = "v${version}";
   ```

2. **Update the hash:**
   - Set `hash = lib.fakeHash;`
   - Run `darwin-rebuild switch --flake ~/.config/nix-config`
   - Copy the correct hash from the error message
   - Replace `lib.fakeHash` with the correct hash

3. **Rebuild:**
   ```bash
   darwin-rebuild switch --flake ~/.config/nix-config
   ```

4. **Update Claude Desktop config** with the new path from `which things-mcp`

## Troubleshooting

### "Could not attach to MCP" error

- Verify Things 3 is installed and has been opened at least once
- Check that "Enable Things URLs" is turned on in Things settings
- Make sure the path in your config matches the output of `which things-mcp`

### Check Claude Desktop logs

```bash
tail -f ~/Library/Logs/Claude/mcp*.log
```

### Test the server manually

```bash
things-mcp
# Should start the server and wait for MCP protocol input
# Press Ctrl+C to exit
```

### "Permission denied" or "Read-only file system" errors

This shouldn't happen anymore with the current implementation, as all dependencies are pre-built into the Nix store during the build phase. If you see these errors:

1. Make sure you've rebuilt your system after updating the package
2. Check that you're using the correct path from `which things-mcp`

## Architecture

- **Package**: `packages/things-mcp/default.nix` - Builds the application with all Python dependencies
- **Overlay**: `overlay/things-mcp.nix` - Makes it available as `pkgs.things-mcp`
- **Host Config**: `host/espeon/home-configuration.nix` - Installs it on espeon
- **Flake**: Adds overlay to espeon's configuration

## How It Works

1. **Build Phase**: Nix downloads the source and runs `uv sync --frozen` to build a complete Python virtual environment
2. **Install Phase**: The virtualenv and source files are copied to `/nix/store/.../share/things-mcp/`
3. **Runtime**: Claude Desktop/Code spawns the MCP server using the wrapper script
4. **Lifecycle**: The server runs as long as Claude is open, providing instant responses with no startup overhead

## References

- [things-mcp GitHub](https://github.com/hald/things-mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Things 3](https://culturedcode.com/things/)
- [uv - Python package manager](https://github.com/astral-sh/uv)

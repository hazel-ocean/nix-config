---
name: nix-config-setting
description: |
  Use when the user wants to change a personal or machine setting that is managed
  declaratively in their nix-config repo (~/.config/nix-config) — e.g. Claude Code
  settings (effort, model, theme, editorMode, permissions, hooks), home-manager
  program options, or host configuration. Edits the declarative source,
  sanity-checks that it still evaluates, then hands over a copy-paste `just apply`
  command (never runs it — apply needs sudo). Triggers on intents like "bump my
  effort to max", "change my editor mode", "add a permission", "turn on X in my
  config", "update my nix settings".
---

# Change a declaratively-managed setting

The user's machine and Claude Code settings are managed declaratively in
`~/.config/nix-config` (a Nix flake with nix-darwin + home-manager). Nothing is
edited at runtime — `~/.claude/settings.json` is a read-only symlink into the Nix
store. To change a setting you edit its declarative source and re-apply.

## Workflow

1. **Work in the config repo, not the current directory.** This skill is usually
   invoked from an unrelated project. Every edit targets `~/.config/nix-config`
   regardless of `cwd`.

2. **Locate the setting.**
   - **Claude Code settings** → `programs/claude/default.nix`, inside the
     `programs.claude-code.settings` attrset. Common keys:
     - effort → `effortLevel` (e.g. `"low" | "medium" | "high" | "max"`)
     - `model`, `theme`, `editorMode`, `tui`
     - `voice.{enabled,mode}`
     - `permissions.{allow,ask,deny}`, `permissions.defaultMode`
     - `enabledPlugins`, `hooks`
   - **Global Claude rules** → `programs/claude/CLAUDE.md`, which home-manager
     renders to `~/.claude/CLAUDE.md`. Nushell rules live under its `## Nushell`
     section.
   - **Host-specific settings** → `host/<host>/home-configuration.nix` or
     `host/<host>/configuration.nix` (hosts: `espeon`, `pigeon` on darwin;
     `korriban`, `ghastly`, `rpi5` on NixOS).
   - **Anything else** → `grep -rn` the repo for the option name (e.g. the
     home-manager option or program) and edit where it's defined.

3. **Make the edit.** Keep it minimal and match the surrounding Nix style. Follow
   the root `CLAUDE.md`: terse comments only where they earn their place. If the
   key doesn't exist yet, add it in the natural spot within the relevant attrset.

4. **Sanity-check evaluation — never build or switch.** Per the root `CLAUDE.md`,
   do not run `darwin-rebuild` / `nixos-rebuild` or a full host build. A
   lightweight eval is enough to catch errors:
   ```
   nix eval .#darwinConfigurations.espeon.config.system.build.toplevel.drvPath
   ```
   Swap the host as appropriate (`nixosConfigurations.korriban` for NixOS hosts).

5. **Hand over the apply command — do not run it.** Applying needs `sudo`
   (`just apply` → `sudo darwin-rebuild switch`), which can't be driven here.
   Tell the user what changed and give them a copy-paste block to run in another
   terminal (or via the `!` prefix in this session):
   ```
   cd ~/.config/nix-config && just apply
   ```
   `just apply` auto-detects the host from `hostname`, so no host argument is
   needed. Until they apply, the running config is unchanged.

6. **Don't commit** unless the user asks.

## Notes

- Runtime commands like `/effort` won't stick — they'd try to write the read-only
  `settings.json`. Routing the change through this skill is the intended path.
- If the requested change spans multiple hosts, edit the shared module
  (`programs/…`) rather than per-host files when the setting is meant to be global.

# nix-config

A Nix flake managing macOS (nix-darwin) and NixOS hosts via home-manager.

- **Hosts** (`host/<name>/`): `espeon` (darwin, primary — user `hazel`), `pigeon`
  (darwin, user `ocean`), `korriban` (NixOS, `hazel`), `ghastly`/`rpi5` (NixOS).
- **Layout**: `flake.nix` wires hosts via `mkDarwinHost`/`mkNixosHost`; per-program
  home-manager modules live under `programs/`; host-specific config under `host/`.
- Flake inputs are exposed to modules as `pkgs` attrs through `baseOverlays` in
  `flake.nix` (e.g. `room`, `helix-latest`, `nu-scripts`).

## Verifying changes — IMPORTANT

**Do not build or switch a system profile to verify a change.** Never run
`darwin-rebuild` / `nixos-rebuild` (or a full `nix build` of a host's
`system`/`toplevel`). These are slow and mutate the machine — they're mine to run.

Instead:

- Lightweight `nix eval` on a config attribute is fine for catching evaluation
  errors (e.g. `nix eval .#darwinConfigurations.espeon.config.system.build.toplevel.drvPath`).
- To confirm a profile actually **builds**, **output the command for me to run** and
  stop there. Don't run it yourself. Examples:
  - Build only (no activation): `darwin-rebuild build --flake .#espeon`
  - Apply (switch): `just apply`  *(→ `sudo darwin-rebuild switch --flake .#espeon`)*

## Conventions

- Match the surrounding Nix style; keep comments terse and only where they earn it.
- Nushell components: pure `.nu` modules load as overlays via
  `programs/nushell/default.nix`; compiled plugins go in `programs.nushell.plugins`.
  See `programs/nushell/AWESOME-NUSHELL.md`.

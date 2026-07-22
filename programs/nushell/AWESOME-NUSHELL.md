# Adding an awesome-nu component

[awesome-nu](https://github.com/nushell/awesome-nu) indexes Nushell scripts,
modules, and plugins. Pure-`.nu` modules/scripts are loaded here as **overlays**
via the registry in [`default.nix`](./default.nix); compiled plugins are a
different path (build a package, add it to `programs.nushell.plugins`).

The working example is the `task` overlay — `modules/background_task/task.nu` from
[`nushell/nu_scripts`](https://github.com/nushell/nu_scripts), pinned as a flake
input and auto-loaded on hosts that run the pueue daemon.

## Recipe

1. **Land the source somewhere the registry can point `src` at.**
   - *Tracked upstream (preferred):* add a non-flake input and expose it as a
     `pkgs` attribute through `baseOverlays` in [`../../flake.nix`](../../flake.nix)
     (the same idiom as `room`/`helix-latest`/`noctalia-git`), so it reaches this
     module via `pkgs` — no `specialArgs` threading. Pinned in `flake.lock`;
     `nix flake update <input>` bumps it with a reviewable diff. One input can
     serve several components from the same repo.
     ```nix
     # flake.nix
     nu-scripts = { url = "github:nushell/nu_scripts"; flake = false; };
     # …inside baseOverlays:
     nu-scripts = inputs.nu-scripts;
     ```
     Alternatively `pkgs.fetchFromGitHub { owner; repo; rev; hash; }` pins a single
     module without a flake input (manual `rev`/`hash` bumps).
   - *Forked / heavily modified:* vendor it as `overlays/<name>/mod.nu` and commit
     it, with a source URL + commit in the header. Prefer pinning once it's stable
     — an unpinned vendored copy is how the old `job` overlay silently went stale.

2. **Add a registry entry** in [`default.nix`](./default.nix). Shape:
   `{ name; src; file ? "mod.nu"; enable; prefix }` — `src` is the directory,
   `file` names the module (upstream files often aren't `mod.nu`), `enable` decides
   auto-load vs load-on-demand (`overlay use`), `prefix` namespaces commands.
   ```nix
   { name = "task"; src = "${pkgs.nu-scripts}/modules/background_task"; file = "task.nu"; enable = config.services.pueue.enable; prefix = true; }
   ```
   Gate `enable` on a real condition when the module has a runtime dep — `task`
   needs `pueued`, so it rides `config.services.pueue.enable` and auto-loads exactly
   where that daemon is on (see [`../../host/espeon/home-configuration.nix`](../../host/espeon/home-configuration.nix)).

## Trust & licensing

- Review any `.nu` before enabling — an overlay is arbitrary code loaded into every
  session it's active for, and Nushell runs external commands.
- Prefer `enable = false` (load-on-demand) for anything not audited but occasionally
  wanted.
- Preserve upstream license/attribution headers; awesome-nu entries carry their own
  licenses.
- A `rev`/lock bump is a reviewable event — read the diff before updating.

# Skills wiring: path form now, independent flake later

Planning note. Not wired yet — captures the intended evolution of how Claude Code
skills are managed in this repo.

## Current state (chosen for now)

- Path form: `programs.claude-code.skills = ./.agents/skills;` (`../default.nix:57`).
- home-manager symlinks that whole directory into `~/.claude/skills/` recursively,
  so dropping in a `<name>/SKILL.md` folder is auto-discovered — no `default.nix`
  edit per skill.
- In-repo skills today:
  - `.agents/skills/nushell-pro` — fetched via `npx skills`, tracked by
    `../skills-lock.json`.
  - `.agents/skills/nix-config-setting` — hand-written.
- This directory (`programs/claude/skills/`, holding `new-project`) is **not**
  referenced by nix today. Consolidating it into the managed set is an open item
  (see Decisions).

## Why move

- **Independent versioning.** Bump a skill (or its upstream source) without churning
  the system config; `nix flake update` just the skills.
- **Explicit pins.** Pin upstream skills (e.g. `nushell-pro`) by rev in a lockfile
  we own, instead of the `npx skills` side-channel.
- **Separation.** Skills become their own unit with their own `flake.lock`.

## Target: skills as their own flake

1. Extract skills into a dedicated flake — either a subflake in this repo
   (`programs/claude/skills/flake.nix`) or a standalone repo. It carries its own
   `flake.lock` pinning any upstream skill sources.
2. Expose a directory output suitable for consumption, e.g.
   `packages.<system>.default` = a tree of `<name>/SKILL.md` (plus each skill's
   `references/`, templates, etc.).
3. Add it as a root input in `flake.nix`:
   ```nix
   inputs.claude-skills.url = "path:./programs/claude/skills"; # or github:hazel/claude-skills
   ```
   (Expose it to modules via `baseOverlays`, matching how `nu-scripts` etc. are
   surfaced.)
4. Consume in the claude module, either:
   - path form: `skills = inputs.claude-skills.packages.${system}.default;`
   - attrset form to mix pinned + local:
     ```nix
     skills = {
       nushell-pro       = inputs.claude-skills.packages.${system}.nushell-pro;
       nix-config-setting = ./.agents/skills/nix-config-setting;
     };
     ```
5. Update independently: `nix flake update claude-skills`.

## Intermediate step (optional, if the flake is too much up front)

Convert the module to the **attrset form** in-repo first — enumerate each skill by
directory path. Gains explicit per-skill control and the ability to source some
entries from flake inputs/packages, without standing up a separate flake yet.
Tradeoff: every new skill then needs a line in `default.nix` (path form
auto-discovers). Use directory paths, not file paths, so skills with `references/`
subdirs come along whole.

## Decisions to make

- Subflake in this repo vs. a separate `claude-skills` repo.
- Fold `skills/new-project` and `.agents/skills/*` into one managed location.
- Reconcile the two lockfile stories: keep the `npx skills` workflow
  (`skills-lock.json` + `Justfile add-skill`) or replace it with nix-pinned flake
  inputs — avoid maintaining both.

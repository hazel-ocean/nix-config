# Incorporating components from awesome-nu

[awesome-nu](https://github.com/nushell/awesome-nu) is a curated index of Nushell
scripts, modules, and plugins. This config already carries one component lifted
from it — the `pueue` job-control module now living at
[`overlays/job/mod.nu`](./overlays/job/mod.nu). That module is the running
example below.

The question this doc answers: **how should we pull `.nu` components from
awesome-nu (and the upstream repos it links) into this Nix-managed config,
keeping them pinned, updatable, and attributable?**

Every overlay here is loaded from a Nix store path (see the registry in
[`default.nix`](./default.nix)), so whatever mechanism we choose only needs to
land the component's directory somewhere the registry can point `src` at.

---

## Option 1 — Vendor the file directly (current approach)

Copy the `.nu` file into `overlays/<name>/mod.nu` and commit it, as we did for
`job`.

- **Pros:** dead simple; no network at eval/build; free to modify locally; works
  offline; the file is right there to read.
- **Cons:** no provenance unless we add it by hand; updates are fully manual
  (copy-paste); easy to drift from upstream and forget where it came from.
- **Use when:** the component is small, we've modified it significantly, or it's
  effectively a local fork.
- **Mitigation:** record source URL + commit in the file header (the `job`
  overlay does this) so a future refresh knows its origin.

## Option 2 — Flake input per upstream repo (recommended for tracked components)

Add the component's upstream repo as a non-flake input and reference its files as
store paths:

```nix
# flake.nix
inputs.nu-pueue = {
  url = "github:<owner>/<repo>";
  flake = false;
};
```

Thread the input through to `programs/nushell/default.nix` (via `specialArgs` /
`extraSpecialArgs`, as the flake already does for other inputs) and point a
registry entry's `src` at it:

```nix
{ name = "job"; src = "${inputs.nu-pueue}/job.nu"; enable = false; }
```

- **Pros:** pinned in `flake.lock`; `nix flake update nu-pueue` bumps it with a
  reviewable lock diff; clear provenance; reproducible.
- **Cons:** a flake input per source can sprawl; upstream layout changes can
  break the `src` path; pulls the whole repo into the store.
- **Use when:** we track a component that upstream actively maintains and we want
  hands-off updates.

## Option 3 — `pkgs.fetchFromGitHub` for a single module

Fetch just the file(s) with an explicit `rev` + `hash`, no flake input:

```nix
src = pkgs.fetchFromGitHub {
  owner = "<owner>";
  repo = "<repo>";
  rev = "<commit>";
  hash = "sha256-...";
};
```

- **Pros:** pinned and reproducible; no flake-input clutter; can grab a
  subdirectory.
- **Cons:** manual `rev` + `hash` bumps (no `flake.lock` automation); a small
  amount of boilerplate per component.
- **Use when:** we want one pinned component without committing to a flake input,
  or need a specific unreleased commit.

## Option 4 — Curated overlay set (the organizing pattern, on top of 1–3)

Regardless of how each file arrives, express the collection as registry entries
with an `enable` flag — exactly the shape `default.nix` already uses. awesome-nu
components then become opt-in overlays sitting alongside the local ones, some
auto-loaded under conditions (e.g. `isDarwin`), the rest available via
`overlay use` on demand.

```nix
overlays = [
  { name = "time-machine"; src = ./overlays/time-machine; enable = isDarwin; prefix = true; }  # local
  { name = "job"; src = "${inputs.nu-pueue}/job.nu"; enable = false; prefix = true; }           # upstream (Option 2)
];
```

- **Pros:** one uniform, orthogonal model for local + upstream components;
  toggling and namespacing are declarative; mixing vendored and pinned sources is
  trivial.
- **Cons:** none beyond the sourcing option it wraps.

---

## Recommendation

- Default to **Option 2** (or **3**) for anything we intend to track from
  upstream — pinning + provenance for near-free.
- Keep **Option 1** only for components we've meaningfully forked (like the
  current `job` overlay), always with a source URL + commit in the header.
- Organize everything through the **Option 4** registry so local and upstream
  overlays share one enable/prefix model.

## Trust & licensing

- Review any `.nu` before vendoring — Nushell runs external commands; an overlay
  is arbitrary code loaded into every session it's enabled for.
- Prefer `enable = false` (load-on-demand) for anything not audited and needed
  everywhere.
- Preserve upstream license/attribution headers; awesome-nu entries carry their
  own licenses.
- When pinning (Options 2/3), a `rev`/lock bump is a reviewable event — read the
  diff before updating.

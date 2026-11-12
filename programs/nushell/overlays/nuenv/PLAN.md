# Plan: Find why hook-driven overlay hide leaks commands

## Goal

Find why `overlay hide` from a nushell hook leaves the commands of a
re-shown overlay callable, and find a workaround. If no workaround exists,
draft an upstream nushell issue for Hazel to approve.

## Context

- Module: `programs/nushell/overlays/nuenv/mod.nu` in nix-config.
- Wiring: `programs/nushell/default.nix`. It adds nu_scripts' `nu-hooks` to
  NU_LIB_DIRS and registers the `nuenv` overlay and its hooks.
- Both files are uncommitted. Do not commit unless Hazel asks.
- nushell is 0.116.1. Hazel's live shell runs the current module.
- First user: ProffieOS. Its `.env.nu` is
  `{overlays: [{path: mod.nu, name: proffie}]}`.

## How the module works

- `pre_prompt` runs a closure, `plan`, before every prompt.
- `plan` compares the current directory with `$env.NUENV_ACTIVE`, a stack of
  `{root, overlays}` records.
- `plan` writes `<cache>/nuenv/<pid>-plan.nu`. It holds the `overlay hide`
  lines for projects that the directory left, and a `source` of each new
  allowed `.env.nu`.
- `nuenv apply` reads each `.env.nu` return value and writes
  `<pid>-load.nu`. A new name gets `overlay use <path> as <name>`. A known
  name gets `overlay use <name>` then `cd <dir>`, because showing restores
  the PWD the overlay stored.
- Two string hooks source the two files. String hooks are needed because
  `overlay` and `source` act at parse time.
- The `env_change.PWD` hook prints an advisory for an unallowed `.env.nu`.

## The bug

Sequence, run from hooks: load, hide, show, hide.

| Step                            | Hook-driven | Typed in REPL | `nu -c` |
|---------------------------------|-------------|---------------|---------|
| 1st load, then hide             | clean       | clean         | clean   |
| show by name, then hide         | command still resolves | clean | clean |
| every later show, then hide     | command still resolves | clean | clean |

- After the leaking hide, `overlay list` shows `active: false`, and the
  overlay's `export-env` variables are gone. Only command resolution is
  wrong.
- Hazel saw the same leak in a real terminal: `proffie` commands stayed
  callable outside the repo.
- Unique overlay names per activation did not leak in the harness. That
  approach leaves one hidden overlay per re-entry, and Hazel rejected it.

## Findings (2026-11-11)

- The trigger is `source`, not hooks. Typed REPL lines reproduce the leak:
  `overlay use m.nu as t`, `source h.nu` (clean), `overlay use t`,
  `source h.nu` (leak: the overlay is inactive, its command still runs).
  `h.nu` contains `overlay hide t`.
- Only the sourced hide matters. A sourced show with a typed hide is clean.
  The first sourced hide after a fresh load is clean.
- File content does not matter: `overlay hide t`, `--keep-env [PWD]`,
  `overlay use t` then hide, and hide/use/hide all leak.
- Parser reading so far: `source` parses unscoped (no new scope frame).
  `parse_overlay_hide` is the same for typed and sourced input. Only
  `merge_delta` writes `engine_state.scope.active_overlays`. The root cause
  is not found yet.
- `open` is not const, so a fixed hook string cannot read an overlay name
  at parse time without `source`.
- Related upstream issues: #14739 (closed; a variable stayed after
  `overlay hide` inside a function) and #6530 (open; let hooks build REPL
  input strings, which would remove the need for `source`). No issue covers
  this leak.

## Outcome (2026-11-11)

- Overlay commands in any sourced file break once an overlay is hidden and
  shown again: a sourced hide leaves commands callable, and a sourced show
  can leave the overlay active with no commands, after which a hide fails
  to parse. Literal hook code (no `source` of overlay commands) is clean.
- The module now writes its plan as literal code into a marked
  `pre_prompt` entry (`{__nuenv: true, code: ...}`). The plan comes from
  `env_change.NUENV_TICK`, which fires every prompt because the last
  `pre_prompt` hook bumps `NUENV_TICK`. Source facts behind this:
  - `eval_hook` ends every hook with `merge_env` (`hook.rs:317`), so
    config changes from a closure reach `engine_state` at once.
  - `eval_pre_prompt_hooks` reads its list from `engine_state` when it
    runs, after env_change.
  - env_change fires when a value differs from `previous_env_vars`, which
    starts empty, so a variable set at startup fires on the first prompt.
- The closure reads each `.env.nu` return value from a child `nu`, because
  a closure cannot `source` a run-time path. The literal code still
  sources `.env.nu` into the shell. A `.env.nu` therefore runs twice on
  entry.
- No snippet files remain.
- The harness passed: four enter/leave cycles, nesting, a direct deep `cd`,
  outer removal and restore, disallow and allow in place, a naive
  `.env.nu`, the advisory, and a shell started inside a nested project.
- Still true: overlays loaded in the same prompt share one env frame (see
  the module header).
- Not done: confirmation in a real terminal, and the upstream issue (draft
  in this session, not posted).

## Investigation steps

1. Get the nushell 0.116.1 source: tag `0.116.1` of `nushell/nushell`, or
   `nix build nixpkgs#nushell.src`.
2. Read how a string hook is evaluated: `crates/nu-cmd-base/src/hook.rs`,
   `eval_hook`. Note how it parses, merges the delta, and evaluates.
3. Read how the REPL evaluates a typed line: `crates/nu-cli/src/repl.rs`
   and `eval_source`. Compare how each path updates the parser's active
   overlays (engine state scope) and the runtime's active overlays (stack).
4. Find the difference that makes a hook's hide of a re-shown overlay keep
   its declarations visible.
5. Test candidate workarounds in the harness below, then ask Hazel to
   confirm in a real terminal. The harness has been wrong before.

## Harness

Hooks fire only in an interactive shell, so the harness drives `nu` through
`script`. Make a fresh test directory and save this as `drive.sh` in it:

```bash
#!/bin/bash
# usage: drive.sh <config> <line>...   feeds lines to an interactive nu.
# HOME and XDG_CACHE_HOME point into the test dir, so $nu.cache-dir never
# touches the real one. XDG_CACHE_HOME alone is not enough.
S=$(cd "$(dirname "$0")" && pwd)
cfg=$1; shift
rm -f "$S/log.nuon"
mkdir -p "$S/home"
{
    sleep 3
    for line in "$@" exit; do printf '%s\r' "$line"; sleep 2; done
} | HOME="$S/home" XDG_CACHE_HOME="$S/cache" script -q "$S/out.txt" nu --config "$cfg" --env-config /dev/null --no-history >/dev/null 2>&1 &
pid=$!
n=$(( $# * 2 + 60 ))
for i in $(seq $n); do kill -0 $pid 2>/dev/null || break; sleep 1; done
kill $pid 2>/dev/null
cat "$S/log.nuon" 2>/dev/null
```

The config passed to `drive.sh`:

```nu
const NU_LIB_DIRS = ['<dir with a nu-hooks symlink to nu_scripts/nu-hooks/nu-hooks>']
overlay use '<path to mod.nu>' as nuenv
let nuenv_hooks = nuenv hooks
$env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append $nuenv_hooks.pre_prompt)
$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [] | append $nuenv_hooks.pwd)
$env.config.show_banner = false
```

- Get nu_scripts from the flake input:
  `nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.nu-scripts.outPath'`.
- Put the trust hashes in `<test dir>/cache/nushell/nuenv/allowed.txt`,
  one per line, from `open .env.nu | hash sha256` in each project.
- Probe with a typed line. Write to an absolute log path. A relative path
  writes into whatever directory the shell is in.
  `{step: in2, cmd: (try {p1-cmd} catch {null}), var: ($env.P1_VAR? | default null)} | to nuon -r | $in + (char nl) | save -a <abs>/log.nuon`
- Do not call commands from a helper defined in the config. The config is
  parsed at startup, so the command resolves to an external there.
- Do not use `help commands` or `scope commands` in probes. They took about
  8 seconds after an overlay reload, and the harness killed the shell.
- Kill stray sessions between runs: `pkill -f '<test dir>/cfg'`.
- Test project: `p1/.env.nu` returns
  `{overlays: [{path: mod.nu, name: p1}]}`, and `p1/mod.nu` is
  `export def p1-cmd [] { "v1" }` plus `export-env { $env.P1_VAR = "p1" }`.
- The bug sequence: `cd <p1>`, probe, `cd <test dir>`, probe, four times.
  A leak shows as `cmd: v1` on the second and later leave probes.

## Pending decision

- Hazel asked about a warning when an overlay name is already active but
  not in `NUENV_ACTIVE`, for example after a manual `overlay use`. The
  proposal: print a yellow warning, do not adopt it, never hide it. Hazel
  has not confirmed. Ask before building it.

## Done when

- A workaround passes the four-cycle hook test and Hazel confirms it in a
  real terminal, or
- an upstream issue draft is ready, with the minimal repro, for Hazel to
  approve. Do not post it without approval.

## Rules

- Never run `darwin-rebuild` or build the system. Check with
  `nix eval .#darwinConfigurations.pigeon.config.system.build.toplevel.drvPath`.
  Hand Hazel `just apply` to run.
- Do not commit nix-config unless Hazel asks.
- No em dashes. Terse comments that record why, not what.

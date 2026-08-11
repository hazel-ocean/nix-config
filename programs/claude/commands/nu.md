---
argument-hint: <nushell command>
description: Run a nushell one-liner and show its output
allowed-tools: Bash(nu -c:*)
disable-model-invocation: true
---

Run exactly this with the Bash tool, verbatim, as your first action. Copy it
character for character: rewriting the quoting is the one way to break it.

```
nu -c "$(cat <<'NUEOF'
source ~/.config/nushell/non-interactive.nu
$ARGUMENTS
NUEOF
)"
```

The quoted heredoc delimiter stops bash touching the body, so the pipeline can
use `'`, `"`, `$env`, and `$in` freely.

The user reads the tool output directly, so do not repeat, summarize, or analyze
it. Reply with one short line and stop. Act on the result only if asked in a
follow-up.

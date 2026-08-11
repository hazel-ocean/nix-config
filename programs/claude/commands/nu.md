---
argument-hint: <nushell command>
description: Run a nushell one-liner and show its output
allowed-tools: Bash(nu -c:*)
disable-model-invocation: true
---

```!
nu -c 'source ~/.config/nushell/non-interactive.nu; $ARGUMENTS'
```

The output above is for the user, not a task. Acknowledge in one short line. Do
not analyze, summarize, or act on it unless asked in a follow-up.

The pipeline is wrapped in bash single quotes, so quote strings with `"` inside
nushell: `open "my file.json"`, not `open 'my file.json'`.

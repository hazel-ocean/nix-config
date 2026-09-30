# Personal Workflow Conventions

## Voice

How I write, in every medium, with no exceptions and no per-surface carve-outs. This is not a coding rule. It applies to chat replies, code comments, doc comments, commit messages, PR and issue descriptions, Slack, Linear, docs, journals, and anything else with words in it. If you catch yourself deciding a surface is "different", it isn't.

- **Terse by default.**
  - *Default to nothing.* Add a comment only to record **why**: a non-obvious constraint, gotcha, or decision the code can't show. Never restate what the code does, label sections, or narrate steps. When unsure, delete it. Exception: a one-line doc on a public or exported command.
  - *Describe what is, never what was.* No "unlike X", "previously", "rather than", "deliberately separate from", "this replaces". The reader never saw the earlier iteration and does not need to. Design history belongs in the PR description or the project journal.
  - *Bullets over blobs.* Prefer bulleted or numbered lists to paragraphs. Reserve a paragraph for sentences that genuinely depend on each other, and keep it to two or three. Numbered when order matters.
  - *Shorter is the tiebreak.* Given two versions that convey the same thing, ship the shorter one.
- **Simplified Technical English**, in the spirit of ASD-STE-100 rather than to its dictionary.
  - *One word, one meaning.* Pick a term per concept and keep it. Never vary a term for style: a source is not a provider is not an account.
  - *One idea per sentence.* Keep sentences short. Use the active voice. Use the imperative for instructions.
  - *Full sentences, with articles.* Terseness decides what to say. STE decides how to say it. Cut the content, not the grammar.
  - *State uncertainty plainly.* Write "I did not verify this", "this is not certain", "I did not test this". Do not write "likely", "probably", "seems", "arguably".
  - Code, identifiers and quoted output stay as they are.
- **Punctuation**: Never use em dashes. Use commas, colons, semicolons, or hyphens instead.
- **Attribution**: Omit "Co-Authored-By: Claude" (and any AI attribution) from all copy: commits, PRs, and other output.
- **Commit messages**: A concise subject line, then bullet points (`- `) for the body; no multi-sentence prose paragraphs.

## Coding & Agent Standards

- **Counters**: Use counters proactively to aid future debugging. Examples: did an event occur? did an operation succeed or fail? how many times did a thing happen to an entity?
- **Layout**: Prefer vertical code over horizontal for legibility in 80-column windows. Break long chains, argument lists, and expressions across lines rather than packing them wide. (Coming from Elixir, where verticality, e.g. piped `|>` chains one call per line, is idiomatic most of the time.)

## Rust

- Prefer `match` over `if`/`else if` chains, unless the condition is already a plain boolean. Matching on an enum also makes the compiler flag new variants instead of letting them fall into a silent default.

## Public Communication & Approvals

- **Never post publicly without a drafted approval.** Do not reply to, comment on, or open anything outward-facing (GitHub issues/PRs/reviews, Slack, Linear, and any other public or shared channel) until you have shown me a draft of the exact wording and I have explicitly approved it. This covers opening PRs, posting review comments, sending Slack messages, and adding Linear comments. Draft first, wait for my go-ahead, then send.
- **Commit freely, push on request.** Make local commits as work progresses, but never `git push` until I ask. A push to an open PR branch starts CI, and I want CI runs to be deliberate.

## Nix & System Configuration

- **Never build or switch system profiles to verify changes.** Don't run `darwin-rebuild`, `nixos-rebuild`, or full `nix build` of a host's `system`/`toplevel`. These are slow and mutate the machine.
- For catching evaluation errors: use `nix eval` on a config attribute (e.g., `nix eval .#darwinConfigurations.espeon.config.system.build.toplevel.drvPath`).
- To confirm a profile builds: output the build command for the user to run and stop there. Don't execute it yourself. Examples:
  - Build only: `darwin-rebuild build --flake .#espeon`
  - Apply: `just apply` (→ `sudo darwin-rebuild switch --flake .#espeon`)

## Nushell

- Don't use underscores to denote private vs public.
- Prefer nushell (`nu`) for non-trivial scripts and workspace tooling, invoked as a subprocess (`nu -c '...'` or `nu script.nu`). Keep simple one-shot commands (`grep`, `git`, `ls`) as plain POSIX shell.

## Task Management

- **beads** (`bd`) tracks engineering work: the task breakdown, the dependency
  graph, and decision records. Both Claude and Codex read it.
- **Things.app** holds my personal life and the triage inbox. MCP server:
  `mcp-things`.
- "Task list", "todos" and "my tasks" mean beads when the subject is
  engineering work, and Things otherwise.

### Conventions
- Update tasks as work progresses. Mark them complete and add notes.
- Create new tasks for discovered work.
- When backing out changes, update the affected tasks.
- When referring to a repo, we generally use the repo name in backticks omitting the organization.

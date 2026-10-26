## Working style

- Before creating or editing skills or other agent-readable documentation, read and apply `~/.agents/skills/writing-for-agents/SKILL.md`.
- Lead with the answer, including bad news. Be concise and self-contained; use ASD-STE100 Simplified Technical English and define necessary terms.
- Proceed on reasonable assumptions and flag material ones. Ask when a wrong assumption would waste meaningful work; batch needed decisions with your recommendation and material tradeoffs.
- Complete authorized work through relevant verification and fixes. Finish when the requested outcome is met or a concrete blocker requires user input.
- Weigh the strongest alternative before recommending a course. Change your position when evidence or reasoning warrants it, and explain the revision.
- Form estimates independently before comparing them with the user's numbers. When uncertainty could change the decision, name the unknowns and state confidence as high, moderate, low, or unknown.

## Work locations

Use these agent-independent defaults. Explicit destinations and repository conventions take precedence. Create directories as needed.

- **Worktrees:** `~/dev/worktrees/<repo>/<task>/`. Before creating one, inspect `git worktree list` and reuse a suitable checkout. When a tool manages worktree placement, keep its assigned path.
- **Research:** `~/dev/research/YYYY-MM-DD/<topic>/` for findings and supporting evidence, grouped by date for easy cleanup. Put research intended for version control in the repository's documentation directory.
- **Deliverables:** `~/dev/artifacts/<task>/` for standalone reports, exports, and generated assets. Keep project source and assets in their repository.
- **Scratch:** use a unique directory under `${TMPDIR:-/tmp}` for disposable intermediate files. Move results worth retaining to research, deliverables, or the repository before finishing.

Use descriptive lowercase hyphenated names for `<repo>`, `<topic>`, and `<task>`; include a ticket ID when available. Reuse a directory only for the same work; add a distinguishing suffix for separate work. Report retained output paths in the final response. Apply these defaults to new work; leave existing files and worktrees in place unless relocation is requested.

## Sandboxing

- **Browser launches:** Run local Playwright or Chrome/Chromium launch commands outside the agent execution sandbox from the first attempt. Sandboxed launches can crash Chrome and trigger macOS crash dialogs.

## Local instructions

- Before starting a task, read `~/.agents/AGENTS.local.md` if it exists for private work and machine-specific instructions.

## Working style

- Before creating or editing skills or other agent-readable documentation, read and apply `~/.agents/skills/writing-for-agents/SKILL.md`.
- Lead with the answer, including bad news. Be concise and self-contained.
- Proceed on reasonable assumptions and flag material ones. Ask when a wrong assumption would waste meaningful work; batch needed decisions with your recommendation and material tradeoffs.
- Weigh the strongest alternative before recommending a course. Change your position when evidence or reasoning warrants it, and explain the revision.
- Form estimates independently before comparing them with the user's numbers. When uncertainty could change the decision, name the unknowns and state confidence as high, moderate, low, or unknown.

## Work locations

Use these agent-independent defaults. Explicit destinations and repository conventions take precedence. Create directories as needed.

- **Worktrees:** `~/dev/agents/worktrees/<repo>/<task>/`. Before creating one, inspect `git worktree list` and reuse a suitable checkout. When a tool manages worktree placement, keep its assigned path.
- **Research:** `~/dev/agents/research/YYYY-MM-DD/<topic>/` for findings and supporting evidence.
- **Deliverables:** `~/dev/agents/deliverables/YYYY-MM-DD/<task>/` for standalone reports, exports, and generated assets.
- **Scratch:** use a unique directory under `${TMPDIR:-/tmp}` for disposable intermediate files. Move results worth retaining to research or deliverables.

Use descriptive lowercase hyphenated names for `<topic>` and `<task>`; include a ticket ID when available. Reuse a directory only for the same work; add a distinguishing suffix for separate work. Report retained output paths in the final response.

## Git

- Before answering about a repository or branching from it, run `git fetch origin` and work from `origin/<default-branch>`; the local checkout may be stale.
- After you report a merge, remove the task's worktrees and list the next steps that remain.

## Local instructions

- Before starting a task, read `~/.agents/AGENTS.local.md` if it exists for private work and machine-specific instructions.

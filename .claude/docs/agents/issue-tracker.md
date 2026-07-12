# Issue tracker: Linear

Issues and PRDs live in Linear. Use the Linear MCP tools (`mcp__plugin_linear_linear__*`) for all operations. This config is machine-global: it applies to every repo unless the repo has its own `docs/agents/issue-tracker.md`.

## Team resolution

- Default team: **DEVOP**.
- A repo's own instructions (CLAUDE.md / AGENTS.md / OVERLAY.md) or its registry entry (`teams[].linearKeys`) override the default. Check there first.

## Conventions

- **Create an issue**: `save_issue` with team, title, markdown description. For agent-implementable tickets, follow the `core:create-groundcrew-ticket` skill conventions (assignee, `agent-*` label, implementation repo in the description).
- **Read an issue**: `get_issue` by key (e.g. `DEVOP-5804`); `list_comments` for the thread.
- **List / search**: `list_issues` with team, state, label, assignee filters.
- **Comment**: `save_comment`.
- **States and labels**: `save_issue` updates; `list_issue_statuses` / `list_issue_labels` to discover valid values before inventing new ones.
- Reference ticket keys in commit messages and PR titles per the repo's git workflow rules (e.g. `feat: ... (DEVOP-1234)`).

## Pull requests as a triage surface

Not applicable — PRs are not a request surface; work originates in Linear.

## When a skill says "publish to the issue tracker"

Create a Linear issue in the resolved team.

## When a skill says "fetch the relevant ticket"

`get_issue` by key, plus `list_comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a parent issue; tickets are **sub-issues**.

- **Map**: a Linear issue labelled `wayfinder-map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a sub-issue of the map (`save_issue` with `parentId`). Label `wayfinder-<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, assign the driving dev.
- **Blocking**: Linear's native "blocked by" relations. A ticket is unblocked when every blocker is done/canceled.
- **Frontier query**: list the map's open sub-issues, drop any with an open blocker or an assignee; first in map order wins.
- **Claim**: assign the issue to yourself — the session's first write.
- **Resolve**: comment the answer, mark Done, append a context pointer to the map's Decisions-so-far.

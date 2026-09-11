@/Users/rocky/.agents/AGENTS.md

## Picking models for subagents

Delegate bounded, fully specified implementation work. Write the prompt with explicit acceptance criteria, review the result, run the checks, then decide what to accept.

Cheapness is what I actually pay (OpenAI is near-free). Intelligence is how hard a problem the model handles unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model  | cheapness | intelligence | taste |
| ------ | --------- | ------------ | ----- |
| gpt    | 9         | 8            | 5     |
| sonnet | 5         | 5            | 7     |
| opus   | 4         | 7            | 8     |
| fable  | 2         | 9            | 9     |

- Start cheap to gather information. Rerun with a smarter model, without asking, the moment output misses the bar.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt, via the `codex:codex-rescue` agent; parallel agents need `isolation: 'worktree'`.
- Anything user-facing needs taste ≥ 7.
- Reviews of plans/implementations: fable or opus, optionally gpt as an extra independent perspective.

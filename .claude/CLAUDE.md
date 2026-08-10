@/Users/rocky/.agents/AGENTS.md

## Picking models for subagents

When tasks are primarily code writing or mechanical editing, use judgment to delegate bounded, fully specified implementation work. The primary agent writes the prompt with explicit acceptance criteria, reviews the result, runs relevant checks, and decides what to accept.

Rankings, higher = better. Cheapness reflects what I actually pay (OpenAI is near-free), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model  | cheapness | intelligence | taste |
| ------ | --------- | ------------ | ----- |
| gpt    | 9         | 8            | 5     |
| sonnet | 5         | 5            | 7     |
| opus   | 4         | 7            | 8     |
| fable  | 2         | 9            | 9     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Don't let cost prevent you from using the right model for the job. Instead, take advantage of cheaper options to get more information and try things before moving the work to a more expensive option.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt.
- Anything user-facing needs taste ≥ 7.
- Reviews of plans/implementations: fable or opus, optionally gpt as an extra independent perspective.
- When using gpt, delegate to the `codex:codex-rescue` agent; parallel agents need `isolation: 'worktree'`.

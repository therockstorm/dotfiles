# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to Linear. The mappings are workflow states and label conventions, not literal label strings — do not create labels named after the canonical roles.

| Label in mattpocock/skills | Linear equivalent                                              | Meaning                                  |
| -------------------------- | -------------------------------------------------------------- | ---------------------------------------- |
| `needs-triage`             | **Triage** workflow state                                       | Maintainer needs to evaluate this issue  |
| `needs-info`               | Triage state + comment tagging the reporter                     | Waiting on reporter for more information |
| `ready-for-agent`          | **Todo** state + `agent-*` label (Groundcrew pickup)            | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | **Todo** state, no agent label                                  | Requires human implementation            |
| `wontfix`                  | **Canceled** state with a closing comment                       | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), apply the corresponding state/label from this table.

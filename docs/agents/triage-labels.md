# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

## Repo state

`wontfix` already exists in `agenticsnz/unsorry`. The other four do not yet exist and will need creating on first use:

```sh
gh label create needs-triage    --description "Maintainer needs to evaluate this issue" --color FBCA04
gh label create needs-info      --description "Waiting on reporter for more information" --color D876E3
gh label create ready-for-agent --description "Fully specified, ready for an AFK agent"  --color 0E8A16
gh label create ready-for-human --description "Requires human implementation"            --color 1D76DB
```

These are distinct from the existing `swarm:*` PR labels (`swarm:prove`, `swarm:translate`, `swarm:decompose`, `swarm:demote`, `swarm:unblock`) and the conventional-commit type labels (`feat`, `fix`, `docs`, `ci`, …), which classify **PRs** under ADR-026. The triage labels above classify **issues**.

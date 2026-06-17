# PR body + announcement templates

## `chore(sourcing):` PR body

```markdown
## Sourced <N> goals — <theme(s)>

<N> new open goals (≤50), all four gates clear, all `status≜open`.

- **Theme(s):** <theme>
- **Difficulty:** <distribution, e.g. 4×diff-3, 2×diff-4> — target ≥3 (ADR-060).
- **Absence:** name-grep + family-grep clean at mathlib `<rev>` (<date>).
- **Triviality:** machine-checked non-trivial (battery v1) — `nlinarith`/SOS family
  survives by design (ADR-035).
- **Provable:** intended proofs compile under `lake env lean`; skeptic pass clean.
- **Dedup:** `git fetch origin` + slug/statement dedup vs live `origin/main goals/`.

Gate B validated locally (`python3 -m tools.gate_b validate .`). No
`docs/targets.md` regen (ADR-036). Generated with `tools/sourcing/gen_triples.py`.
```

Title MUST be `chore(sourcing): <description>` (ADR-026 needs a valid Conventional
type; `(sourcing)` is the project convention). ≤50 goals per PR.

## Issue #81 announcement (📣, after merge)

```markdown
📣 Sourced <N> goals — <theme> (PR #<PR>)

<one-line summary of the family>. Difficulty <range>. Backlog now <X> open / <Y>
candidates staged. All four gates clear; Gate B green.
```

## Issue #400 program-status update (edit the running comment)

```markdown
- Sourced <N> (<theme>, PR #<PR>) — difficulty ≥3; backlog <X> ahead.
```

After merge also flip the promoted entries in `backlog/candidates/<theme>.md`
from `[ ]` to `[x]`.

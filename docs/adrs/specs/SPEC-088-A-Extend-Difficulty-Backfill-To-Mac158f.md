# SPEC-088-A: Extend the Difficulty Backfill to mac-158f Template Goals

Implements: [ADR-088](../ADR-088-Extend-Difficulty-Backfill-To-Mac158f.md) · Status: Living · Updated: 2026-06-23

ADR-088 widens the seedkit difficulty backfill (ADR-087 / SPEC-087-A) to cover
ohdearquant's `mac-158f` deterministic Python/sympy templates, so identical-
triviality goals carry the same honest difficulty `1` regardless of which
deterministic pipeline proved them. This spec is the contract for that extension.
It is **difficulty-only**: mac-158f provenance is already honest (`python/sympy`
via the ADR-079 rule), so the provenance `_RULES` are unchanged.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `index_is_mac158f` predicate | `tools/repo/relabel_attribution.py` | no |
| D2 | `index_is_template_fixture` = seedkit ∪ mac-158f, driving Pass B | same | no |
| D3 | Tests for D1 + D2 + a mac-158f end-to-end correction | `tools/repo/tests/test_relabel_attribution.py` | no |

## 2. Identification (D1, D2)

`index_is_mac158f(text) -> bool` — true when `agent≜mac-158f` **and** the model is
a deterministic template, tolerant of pre- and post-relabel state:

- `model≜template-*` (pre-relabel, still `provider≜claude`), **or**
- `model≜sympy` with `provider≜python` (post-relabel — the honest engine).

A genuine LLM proof under the same agent (e.g. `model≜sonnet`) is **not** matched
(no `template-`/`sympy` engine), and another contributor's `python/sympy` is not
mac-158f (agent-gated).

`index_is_template_fixture(text)` returns `index_is_seedkit(text) or
index_is_mac158f(text)`. Pass B (difficulty) collects `goal≜<id>` from every index
record satisfying this union and corrects exactly those goals — the same
`correct_difficulty` (`2..5 → 1`, idempotent) and the same provenance-driven join
SPEC-087-A §3 defines. No goal-id prefix list.

## 3. Scope & invariants (unchanged from SPEC-087-A)

- **Difficulty only** for mac-158f; the provenance `_RULES` (ADR-079 mac-158f →
  `python/sympy`; seedkit → `lean/decide`|`ring`) are untouched.
- `goals/*.aisp` only (goals are never archived, so one pass fixes active +
  archived proofs' `difficulty_points`).
- `solver≜` credit never changes; idempotent + self-healing; rides the existing
  `attribution-relabel.yml` `git add -A` — no workflow/CODEOWNERS edit.
- First-run effect (live-corpus dry-run): difficulty backfill ~**1,063** goal
  records (≈ 561 seedkit + ≈ 502 mac-158f); provenance relabel ~**167** records
  (exact counts reported by the tool).

## 4. Tests (D3)

- `index_is_mac158f`: `python/sympy` and `template-*` under `agent≜mac-158f` are
  matched; `model≜sonnet` under the same agent and `python/sympy` under another
  agent are not;
- `index_is_template_fixture` matches both pipelines and rejects a non-fixture;
- end-to-end: a `mac-158f` `python/sympy` proof's goal at `difficulty≜4` → `1`,
  while its provenance stays `provider≜python` (no relabel); idempotent.

## 5. Out of scope

- mac-158f **provenance** (already honest via ADR-079).
- Any deterministic pipeline not yet identified — a future contributor's template
  engine would get its own `index_is_*` predicate added to the union.
- `solver≜` credit / credited-proof counts (ranking-neutral on the credit axis).

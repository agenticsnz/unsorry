# The goal triple — exact format

A sourced goal is three files. Prefer generating them with
`python3 -m tools.sourcing.gen_triples` (it produces exactly this schema and
Gate-B-validates); the templates here are for understanding and hand-editing. The
schema is SPEC-003-A; Gate B (`tools/gate_b/validator.py`) enforces it.

The unicode is load-bearing — copy it exactly: `⟦ ⟧` (U+27E6/7), `⟨ ⟩`
(U+27E8/9), `≜` (U+225C), `≔` (U+2254), `∅` (U+2205), `◊⁺` (U+25CA U+207A).

## 1. `goals/<slug>.lean` — the sorry-stub

```lean
import Mathlib

theorem <snake_name> <signature> := by
  sorry
```

- `<snake_name>` = the slug with `-`→`_` (e.g. `nat-succ-pos` → `nat_succ_pos`).
- `<signature>` is everything after the name: binders, `:`, proposition.
- Exactly `import Mathlib`, a blank line, the theorem, and `  sorry` (two spaces).

## 2. `goals/<slug>.aisp` — the goal record (fresh = open)

```
𝔸5.1.goal.<slug>@<YYYY-MM-DD>
γ≔unsorry.goal
⟦Ω:Goal⟧{
  id≜<slug>
  phase≜prove
  status≜open
  difficulty≜<0-5>
}
⟦Σ:Source⟧{
  src≜backlog/<slug>.md
}
⟦Γ:Deps⟧{
  deps≜⟨⟩
}
⟦Λ:Artifact⟧{
  lean≜goals/<slug>.lean
  sha≜∅
  aff≜-20
}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
```

Gate B rules a fresh goal must satisfy:

- Header `𝔸5.1.goal.<id>@<date>` with `<date>` = `YYYY-MM-DD`; the filename stem,
  the header name, and the `id` field must all be the same kebab slug
  (`[a-z0-9][a-z0-9-]*`, **no dots**).
- `phase≜prove`; `status≜open`; `difficulty` a single digit 0–5.
- `status≜open` **requires `sha≜∅`** (a real 64-hex sha is only for proved/archived).
- `lean≜goals/<slug>.lean` must point at the existing stub; `deps≜⟨⟩` (or
  `⟨id,id,…⟩` referencing real goals).
- All five blocks present (`⟦Ω⟧⟦Σ⟧⟦Γ⟧⟦Λ⟧⟦Ε⟧`); the band is exactly
  `⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩`. No `"`-quoted prose in the formal blocks (density lint).
- `aff≜-20` is the observed fresh-goal seed; it is a negative integer.

## 3. `backlog/<slug>.md` — the human entry + evidence

```markdown
# <slug>

<one-line statement in words>

- **Source:** <where it comes from; cite the ADR/issue, e.g. "#400 Identity Engine (ADR-043) — <family>; promoted from candidate backlog (#NNN).">
- **Reference:** <the claim restated, or "Not a named mathlib lemma in this form.">
- **Absence:** <gate-1 verdict + grep scope + mathlib rev + date>
- **Triviality:** <gate-3 verdict + "battery v1" + rev + date>
- **Difficulty:** <0-5>
- **Decomposition sketch:** <the intended proof; the hint a prover starts from>
```

Gate B only checks this file **exists** (it is the `src`), not its structure — but
the six bullets are the contract the skill and the prover rely on. The
**Decomposition sketch** is the most valuable line: it is the verified intended
proof, and a goal with a real sketch is a goal with depth.

## Candidate staging line (`backlog/candidates/<theme>.md`)

Cheaper than a full triple — no `.lean`, no build. Stage gate-1+gate-3 survivors:

```markdown
- [ ] `<snake_name>` — <one-line statement>
      absence: <verdict> · triviality: <verdict> · intended: <tactic sketch> · conf: high|med
```

Second line indented **6 spaces**; fields separated by ` · ` (U+00B7). Flip `[ ]`
→ `[x]` when promoted.

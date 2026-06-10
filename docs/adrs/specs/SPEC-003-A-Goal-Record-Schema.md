# SPEC-003-A: Goal Record Schema

Implements: [ADR-003](../ADR-003-AISP-Coordination-Format.md) · Status: Living · Updated: 2026-06-10

A goal record is the unit of claimable work. Every open target is a pair: `goals/<id>.aisp` (this record) and, for `prove`-phase goals, `goals/<id>.lean` (the statement carrying `sorry`).

## Identifiers

`Id ::= [a-z0-9][a-z0-9-]*` — kebab-case, no dots (dots are reserved as filename field separators). Applies to goal ids and agent ids alike.

## File format

```
𝔸5.1.goal.<id>@YYYY-MM-DD
γ≔unsorry.goal
⟦Ω:Goal⟧{
  id≜<id>
  phase≜translate
  status≜open
  difficulty≜1
}
⟦Σ:Source⟧{
  src≜backlog/<file>.md
}
⟦Γ:Deps⟧{
  deps≜⟨⟩
}
⟦Λ:Artifact⟧{
  lean≜∅
  sha≜∅
}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
```

## Field rules

| Field | Domain | Rules |
|---|---|---|
| `id` | `Id` | Must equal the `<id>` in the filename and in the `𝔸` header |
| `phase` | `translate` \| `prove` | `translate` = Phase-0/1 formalisation target; `prove` = Lean proof target |
| `status` | `open` \| `flagged` \| `translated` \| `blocked` \| `proved` | See transitions below |
| `difficulty` | integer 0–5 | 0 trivial … 5 research-grade |
| `src` | path | Must exist in the repo: a `backlog/*.md` file or a `decompositions/*.aisp` record |
| `deps` | `⟨⟩` or `⟨id,…⟩` | Every id must be an existing goal id; semantics `Post(dep) ⊆ Pre(this)` |
| `lean` | path or `∅` | Required (and must exist) iff `phase ≡ prove`; must be `∅` when `phase ≡ translate` |
| `sha` | 64 lowercase hex or `∅` | Required iff `status ∈ {translated, proved}`; SHA-256 of the normalized canonical statement (see SPEC-003-C normalization) |

**Claimed-ness is not a status.** Whether a goal is claimed is derived solely from live claim files on the `claims` branch (ADR-004). Duplicating it here would create a second source of truth.

## Status meanings and transitions

- `open` → claimable.
- `translated` (terminal for `translate` goals) — two independent translations matched; `sha` recorded.
- `flagged` — translations diverged; awaiting human/peer fidelity review.
- `blocked` — below affinity viability or awaiting decomposition; not claimable.
- `proved` (terminal for `prove` goals) — merged into `library/`; `library/index/<sha>.aisp` must exist.

The validator checks field validity and cross-file consistency, not history (transitions are not enforceable from a single tree snapshot).

## Gate B checks (required, `tools/gate_b`)

| Code | Check |
|---|---|
| GB001 | Header line parses: `𝔸5.1.goal.<id>@date`, `γ≔unsorry.goal` |
| GB002 | Filename / header / `id` field agree |
| GB003 | Enum fields within domain (`phase`, `status`, `difficulty`) |
| GB004 | `phase ≡ prove` ⇒ `lean` set and file exists; `phase ≡ translate` ⇒ `lean ≡ ∅` |
| GB005 | `status ∈ {translated, proved}` ⇒ `sha` is 64-hex |
| GB006 | `status ≡ proved` ⇒ `library/index/<sha>.aisp` exists |
| GB007 | Every dep references an existing goal id |
| GB008 | `src` path exists |
| GB009 | Quoted-prose density in formal blocks ≤ 0.30 (chars inside `"…"` ÷ non-whitespace chars) |
| GB017 | Required blocks present: `⟦Ω⟧`, `⟦Ε⟧` (full five-block form recommended; upstream tier is advisory) |

## Acceptance criteria (PR-3 tests)

1. Every file in `tools/gate_b/tests/fixtures/valid_tree/goals/` passes all checks.
2. Each `invalid_*` fixture tree fails with exactly the violation code named by its directory.
3. Validation of a 100-goal tree completes in < 1 s (no LLM, stdlib only).

# SPEC-003-C: Translation and Decomposition Records

Implements: [ADR-003](../ADR-003-AISP-Coordination-Format.md) · Status: Living · Updated: 2026-06-10

## Translation records — `translations/<goal-id>.<agent-id>.aisp` (on `main`)

One independent formalisation of a `translate`-phase goal's English statement, produced by one agent. The dual-translation fidelity gate (design doc §5) compares two of these.

```
𝔸5.1.tr.<goal-id>.<agent-id>@YYYY-MM-DD
γ≔unsorry.translation
⟦Ω:Tr⟧{goal≜<goal-id>; agent≜<agent-id>}
⟦Σ:Stmt⟧{
  stmt≜∀n,m∈ℕ:n+m≡m+n
}
⟦Γ:Provenance⟧{src≜backlog/<id>.md; independent≜⊤}
⟦Λ:Norm⟧{norm≜tools/fidelity}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
```

Rules:

- Filename fields must match `Ω` fields and header (GB002 family).
- `goal` must reference an existing goal with `phase ≡ translate` (GB016 if orphaned).
- `stmt` must be non-empty and pass the quoted-prose density lint (GB009): the statement is symbolic notation, not English wrapped in quotes.
- `independent≜⊤` asserts the agent did not read sibling translations before writing its own. This is a **contract assertion, not machine-enforced** — recorded honestly; the Phase-0 trial measures fidelity false-positives on planted pairs, which does not depend on it.

## Normalization (`tools/fidelity`, PR-5)

`norm(stmt)` is the canonical form used for both the fidelity diff and content addressing:

1. NFC Unicode normalization; collapse all whitespace runs to none (symbols) or single space (where significant).
2. Canonical symbol table: map alias glyphs to one representative (e.g. `→`/`⟶`, `≝`/`≜`, `x*y`/`x·y`) per the table shipped in `tools/fidelity/symbols.py`.
3. α-rename bound variables to a canonical sequence (`x₁,x₂,…` in binding order).
4. Redundant-parenthesis elimination (added after phase0-run-001, whose only two fidelity flags were paren-wrap false positives). Strips only provably meaning-preserving round-paren groups, to fixpoint: whole-statement wraps; single IDENT/NUM wraps **not** in application position (`P(x)` is never collapsed); directly-nested duplicates `((G))`; and a group spanning a binder's entire body to the end of its scope (immediately after `:`/`.`, closing where the enclosing group or statement ends). Interior grouping (`a+(b·c)`), `⟨⟩`, and all non-round brackets are untouched. Runs after α-renaming so scope resolution sees the original brackets.
5. Output: single line, UTF-8.

`sha ≜ SHA-256(hex, lowercase)` of the UTF-8 bytes of that single line. This same sha keys `library/index/<sha>.aisp`.

Two translations **match** iff their normalized forms are byte-identical. Mismatch ⇒ goal `status ≔ flagged`.

## Decomposition records — `decompositions/<parent-id>.<agent-id>.aisp` (on `main`)

Committed when a prove attempt fails: the parent goal is split into claimable sub-lemmas (design doc §6).

```
𝔸5.1.decomp.<parent-id>.<agent-id>@YYYY-MM-DD
γ≔unsorry.decomposition
⟦Ω:Decomp⟧{parent≜<parent-id>; agent≜<agent-id>}
⟦Σ:Subs⟧{
  sub₁≜⟨id≜<new-goal-id>,stmt≜…⟩
  sub₂≜⟨id≜<new-goal-id>,stmt≜…⟩
}
⟦Γ:Edges⟧{
  Post(sub₁)⊆Pre(sub₂); Post(sub₂)⊆Pre(parent)
}
⟦Λ:Requeue⟧{∀s∈subs:goal(s)≫status≔open}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
```

Rules:

- `parent` must reference an existing goal (GB016 if orphaned).
- Each `sub.id` must be a fresh `Id`; the same PR must add the corresponding new `goals/<sub-id>.aisp` records (with `src` pointing at this decomposition record).
- Edges use the binding form `Post(A) ⊆ Pre(B)`; every endpoint must be `parent` or a declared sub.
- At least one sub; at most 8 (a decomposition wider than that is itself a sign the parent needs re-thinking).

## Acceptance criteria (PR-3 / PR-5 tests)

1. Valid fixtures pass; `invalid_orphan_translation` fails GB016.
2. Normalization: the planted equivalent pairs in `tools/fidelity/tests/` normalize byte-identical; the planted non-equivalent pairs do not.
3. `sha` of the worked example in `valid_tree` matches the value committed in its goal record and index entry.

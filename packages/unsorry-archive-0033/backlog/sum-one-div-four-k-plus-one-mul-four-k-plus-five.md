# sum-one-div-four-k-plus-one-mul-four-k-plus-five

The sum over k<n of 1/((4k+1)(4k+5)) equals n/(4n+1).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family.
- **Reference:** The sum over k<n of 1/((4k+1)(4k+5)) equals n/(4n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; (1/4)(1/(4k+1) − 1/(4k+5)) telescopes to (1/4)(1 − 1/(4n+1)) = n/(4n+1); field_simp/ring.

# sum-odd-squares-eq

Three times the sum of the first n odd squares (2k+1)^2 equals n(2n-1)(2n+1).

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** Three times the sum of the first n odd squares (2k+1)^2 equals n(2n-1)(2n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; sum_range_succ + push_cast, nlinarith closes the cubic identity from the IH.

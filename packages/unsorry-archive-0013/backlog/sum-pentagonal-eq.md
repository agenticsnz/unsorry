# sum-pentagonal-eq

The sum of generalized pentagonal-type terms k(3k-1) over range n equals (n-1)^2·n.

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** The sum of generalized pentagonal-type terms k(3k-1) over range n equals (n-1)^2·n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction over ℤ to avoid Nat subtraction underflow; sum_range_succ, push_cast, nlinarith from the quadratic IH.

# sum-triple-product-eq

Four times the sum of products of three consecutive integers k(k+1)(k+2) equals (n-1)n(n+1)(n+2).

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** Four times the sum of products of three consecutive integers k(k+1)(k+2) equals (n-1)n(n+1)(n+2). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; peel last term with sum_range_succ, push_cast, then nlinarith closes using the cubic IH.

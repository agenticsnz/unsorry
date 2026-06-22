# sum-k-sq-mul-two-pow

The sum over k<n of k²·2^k equals (n²−4n+6)·2^n − 6.

- **Source:** #400 Identity Engine (ADR-043) — closed-form-sums family.
- **Reference:** The sum over k<n of k²·2^k equals (n²−4n+6)·2^n − 6. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Induction; peel the top term with sum_range_succ, rewrite by the IH, then push_cast and ring close the quadratic-coefficient identity.

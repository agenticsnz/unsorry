# sum-two-k-sub-one-mul-two-pow

The sum over k<n of (2k−1)·2^k equals (2n−5)·2^n + 5.

- **Source:** #400 Identity Engine (ADR-043) — closed-form-sums family.
- **Reference:** The sum over k<n of (2k−1)·2^k equals (2n−5)·2^n + 5. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Induction; sum_range_succ rewrite by IH; push_cast and ring close the linear-coefficient identity.

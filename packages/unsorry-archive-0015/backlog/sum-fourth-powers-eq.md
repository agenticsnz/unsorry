# sum-fourth-powers-eq

Thirty times the sum of fourth powers k^4 over range n equals the Faulhaber quartic closed form.

- **Source:** #400 Identity Engine (ADR-043) — figurate family.
- **Reference:** Thirty times the sum of fourth powers k^4 over range n equals the Faulhaber quartic closed form. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Induction; sum_range_succ + push_cast reduce to a degree-5 polynomial identity that nlinarith closes from the IH.

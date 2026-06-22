# hexagonal-eq-triangular-odd-index

The n-th hexagonal number n(2n-1) equals the (2n-1)-th triangular number.

- **Source:** #400 Identity Engine (ADR-043) — figurate-number family; promoted from candidate backlog (#610).
- **Reference:** The n-th hexagonal number n(2n-1) equals the (2n-1)-th triangular number. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 1
- **Decomposition sketch:** Rewrite the (2n-1)*(2n)/2 division exactly via Nat.mul_div_cancel on the even factor, then ring/omega. Verified to build (lake env lean).

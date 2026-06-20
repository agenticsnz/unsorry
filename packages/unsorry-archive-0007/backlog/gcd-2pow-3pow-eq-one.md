# gcd-2pow-3pow-eq-one

Powers of 2 and powers of 3 with the same exponent are coprime.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog.
- **Reference:** Powers of 2 and powers of 3 with the same exponent are coprime. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** From Nat.Coprime 2 3 use Nat.Coprime.pow to get coprimality of the powers, then unfold gcd. Verified to build (lake env lean) at sourcing.

# cube-of-sum-minus-cubes-div-by-sum

The difference between (a+b+c)³ and a³+b³+c³ is divisible by a+b (it equals 3(a+b)(b+c)(c+a)).

- **Source:** #400 Identity Engine (ADR-043) — algebraic identity family; promoted from candidate backlog (#610).
- **Reference:** The difference between (a+b+c)³ and a³+b³+c³ is divisible by a+b (it equals 3(a+b)(b+c)(c+a)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** exact ⟨3*(b+c)*(c+a), by ring⟩. Verified to build (lake env lean).

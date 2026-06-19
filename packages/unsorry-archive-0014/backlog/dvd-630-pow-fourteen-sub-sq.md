# dvd-630-pow-fourteen-sub-sq

The integer 630 = 2·3^2·5·7 divides n^14 - n^2 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 630 = 2·3^2·5·7 divides n^14 - n^2 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ZMod 630 decide bridge on x^14 - x^2 = 0; the 3^2 factor needs the n^2 head, distinguishing it from a squarefree n^a-n fact. Verified to build (lake env lean).

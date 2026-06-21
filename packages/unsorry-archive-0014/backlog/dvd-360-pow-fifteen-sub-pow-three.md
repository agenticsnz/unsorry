# dvd-360-pow-fifteen-sub-pow-three

The integer 360 = 2^3·3^2·5 divides n^15 - n^3 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 360 = 2^3·3^2·5 divides n^15 - n^3 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** Cast to ZMod 360 and `decide` x^15 = x^3; the 2^3 and 3^2 prime-power factors require the n^3 head, not a bare n^a-n form. Verified to build (lake env lean).

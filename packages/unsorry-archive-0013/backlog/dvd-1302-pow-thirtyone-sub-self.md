# dvd-1302-pow-thirtyone-sub-self

The integer 1302 = 2·3·7·31 divides n^31 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; promoted from candidate backlog (#610).
- **Reference:** The integer 1302 = 2·3·7·31 divides n^31 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** ZMod 1302 decide bridge with set_option maxRecDepth ~200000; exponent 31 makes kernel reduction heavier but still terminates (~26s). Verified to build (lake env lean).

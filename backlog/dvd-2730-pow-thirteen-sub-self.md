# dvd-2730-pow-thirteen-sub-self

2730 divides n^13 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family.
- **Reference:** 2730 divides n^13 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** 2730 = 2*3*5*7*13 and (p-1) | 12 for each of these primes, so x^13 = x in ZMod 2730; decide over all 2730 residues then lift with intCast_zmod_eq_zero_iff_dvd (large modulus needs raised maxRecDepth).

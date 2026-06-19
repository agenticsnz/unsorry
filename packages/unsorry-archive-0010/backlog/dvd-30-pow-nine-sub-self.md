# dvd-30-pow-nine-sub-self

30 divides n^9 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family.
- **Reference:** 30 divides n^9 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** 30 = 2*3*5 and (p-1) | 8 for each prime p, so x^9 = x in ZMod 30; verify by decide over all 30 residues and lift via intCast_zmod_eq_zero_iff_dvd.

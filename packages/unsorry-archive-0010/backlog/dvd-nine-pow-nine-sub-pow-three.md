# dvd-nine-pow-nine-sub-pow-three

9 divides n^9 - n^3 for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family.
- **Reference:** 9 divides n^9 - n^3 for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** In ZMod 9 the cube map satisfies (x^3)^3 = x^3 (the cubes are exactly the fixed points {0,1,8}), so x^9 = x^3; verify x^9 - x^3 = 0 by decide over 9 residues and lift via intCast_zmod_eq_zero_iff_dvd.

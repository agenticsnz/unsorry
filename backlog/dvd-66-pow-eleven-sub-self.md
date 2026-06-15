# dvd-66-pow-eleven-sub-self

66 divides n^11 - n for every integer n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family.
- **Reference:** 66 divides n^11 - n for every integer n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** 66 = 2*3*11 and (p-1) | 10 for each prime p, so x^11 = x in ZMod 66; verify by decide over all 66 residues, lift via intCast_zmod_eq_zero_iff_dvd.

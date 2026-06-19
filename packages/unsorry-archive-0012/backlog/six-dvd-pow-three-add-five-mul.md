# six-dvd-pow-three-add-five-mul

For every integer n, 6 ∣ n³ + 5n.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family. Classic elementary number theory.
- **Reference:** 6 ∣ n³ + 5n, since n³ + 5n = (n³ − n) + 6n and 6 ∣ n³ − n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 6 decide (∀ x : ZMod 6, x³ + 5x = 0); push_cast; ZMod.intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).

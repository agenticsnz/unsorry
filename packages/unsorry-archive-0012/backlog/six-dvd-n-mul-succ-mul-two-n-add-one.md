# six-dvd-n-mul-succ-mul-two-n-add-one

6 divides n(n+1)(2n+1) for every integer n (the numerator of ∑k²).

- **Source:** #400 Identity Engine (ADR-043) — divisibility family.
- **Reference:** 6 divides n(n+1)(2n+1) for every integer n (the numerator of ∑k²). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 6 decide (∀ x, x(x+1)(2x+1)=0); push_cast; ZMod.intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).

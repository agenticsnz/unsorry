# six-dvd-pow-three-sub-self

For every integer n, 6 ∣ n³ − n (= n(n−1)(n+1)).

- **Source:** Classic elementary inequality / number-theory fact (#400 plan Phase 3).
- **Reference:** For every integer n, 6 ∣ n³ − n (= n(n−1)(n+1)). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 6 decide + ZMod.intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).

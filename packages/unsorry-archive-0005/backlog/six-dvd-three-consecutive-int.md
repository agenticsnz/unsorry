# six-dvd-three-consecutive-int

For every integer n, 6 ∣ n(n+1)(n+2) — divisibility of the product of three consecutive integers, over ℤ.

- **Source:** Classic elementary number theory (library-growth batch, #400 plan Phase 3).
- **Reference:** For every integer n, 6 ∣ n(n+1)(n+2) — divisibility of the product of three consecutive integers, over ℤ. mathlib has `ZMod.pow_card` (Fermat) but not these specific named divisibility lemmas.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — stated over **all of ℤ**, so `decide` cannot enumerate and `omega` cannot see the nonlinear/modular structure.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** ZMod 6: decide ∀ m, m(m+1)(m+2)=0, then ZMod.intCast_zmod_eq_zero_iff_dvd. (Repo has the ℕ version; ℤ blocks decide.) Verified to build (lake env lean).

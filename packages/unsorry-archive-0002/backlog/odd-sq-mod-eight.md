# odd-sq-mod-eight

The square of every odd natural number leaves remainder 1 on division by 8: if n is odd then n^2 % 8 = 1.

- **Source:** classic identities
- **Reference:** Odd squares are ≡ 1 (mod 8); Hardy & Wright, An Introduction to the Theory of Numbers (quadratic-residue preliminaries); standard elementary number theory.
- **Absence:** machine-checked; `% 8 = 1` flags only a local hypothesis inside NumberTheory/Fermat.lean and the χ₈ quadratic-character machinery in LegendreSymbol/JacobiSymbol — neither states the odd-square fact; targeted re-grep (sq_mod_eight, mod_eight_eq_one) no-local-match (rev c5ea00351c28, 2026-06-12).
- **Difficulty:** 2
- **Decomposition sketch:** From Odd n obtain n = 2k+1; n^2 = 4k(k+1) + 1; L1: 2 ∣ k(k+1) (mathlib's Nat.even_mul_succ_self), hence 8 ∣ 4k(k+1); close by omega/Nat.add_mul_mod_self_left. 1-2 steps.

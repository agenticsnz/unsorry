# sq-mod-three

The square of any natural number not divisible by 3 leaves remainder 1 on division by 3: if n % 3 ≠ 0 then n^2 % 3 = 1.

- **Source:** classic identities (thread-B depth-chain leaf)
- **Reference:** Quadratic residues mod 3; Hardy & Wright, An Introduction to the Theory of Numbers (congruence preliminaries); standard elementary number theory.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-12); ZMod character machinery exists but the Nat-arithmetic statement is not present
- **Difficulty:** 2
- **Decomposition sketch:** n % 3 is 1 or 2 by omega from h; in each case write n = 3k + r and close n^2 % 3 by Nat.add_mul_mod_self / omega. 1 step.

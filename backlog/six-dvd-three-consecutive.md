# six-dvd-three-consecutive

For every natural n, 6 ∣ n(n+1)(n+2): the product of three consecutive integers is divisible by 6.

- **Source:** elementary number theory (product of k consecutive integers is divisible by k!)
- **Reference:** Hardy & Wright, An Introduction to the Theory of Numbers, §6 — the k=3 case. mathlib has `Nat.factorial_dvd_descFactorial` but no standalone `6 ∣ n(n+1)(n+2)`.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 2
- **Decomposition sketch:** L1 2 ∣ n(n+1) (two consecutive integers). L2 3 ∣ n(n+1)(n+2) (a `Decidable` mod-3 case split / `ZMod 3`). L3 combine via `Nat.Coprime.mul_dvd_of_dvd_of_dvd` (2 and 3 are coprime) ⇒ 6 ∣.

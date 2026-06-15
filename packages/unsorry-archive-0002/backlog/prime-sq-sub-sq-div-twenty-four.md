# prime-sq-sub-sq-div-twenty-four

For any two primes p, q both greater than 3, 24 divides p^2 - q^2 (stated over ℤ).

- **Source:** classic identities (thread-B depth-chain root; deps: prime-sq-mod-twenty-four)
- **Reference:** Standard corollary of "p² ≡ 1 (mod 24) for primes p > 3"; Sierpiński, Elementary Theory of Numbers; common olympiad exercise.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-12)
- **Difficulty:** 2
- **Decomposition sketch:** Apply dependency prime-sq-mod-twenty-four to both p and q (p^2 % 24 = 1, q^2 % 24 = 1), lift to ℤ congruences (Int.emod_emod_of_dvd / Int.natCast_mod), and conclude 24 ∣ p^2 - q^2 since both squares are ≡ 1 (mod 24) (Int.ModEq.sub / dvd_sub of the two congruences). 1-2 steps, reusing the mid-level dependency.

# prime-sq-mod-twenty-four

The square of every prime p > 3 leaves remainder 1 on division by 24: if p is prime and p > 3 then p^2 % 24 = 1.

- **Source:** classic identities (thread-B depth-chain mid; deps: odd-sq-mod-eight, sq-mod-three)
- **Reference:** Classic chestnut "24 divides p² − 1 for every prime p > 3"; Sierpiński, Elementary Theory of Numbers; standard olympiad/intro-NT result via CRT from the mod-8 and mod-3 facts.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-12)
- **Difficulty:** 3
- **Decomposition sketch:** p prime > 3 is odd (hp.odd_of_ne_two) and not divisible by 3 (else p = 3); apply dependency odd-sq-mod-eight to get p^2 % 8 = 1 and dependency sq-mod-three to get p^2 % 3 = 1; combine the coprime moduli 8 and 3 to p^2 % 24 = 1 (Nat.mod_mod_of_dvd / Nat.chineseRemainder or direct omega on the two congruences). 2-3 steps, reusing both proved leaves.

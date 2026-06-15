# three-cubes-div-nine

For every natural n, 9 divides n^3 + (n+1)^3 + (n+2)^3; the sum of any three consecutive cubes is divisible by 9.

- **Source:** classic identities
- **Reference:** Classic introductory number-theory / olympiad exercise; Engel, Problem-Solving Strategies (divisibility chapter); Sierpiński, Elementary Theory of Numbers (PWN/North-Holland, 1988).
- **Absence:** machine-checked; the `9 ∣` pattern flags only Data/Nat/Digits/Div.lean (the digit-sum divisibility rule nine_dvd_iff), verified to be a different theorem — the consecutive-cubes fact is not present (rev c5ea00351c28, 2026-06-12).
- **Difficulty:** 2
- **Decomposition sketch:** Expand to 3n^3 + 9n^2 + 15n + 9 (ring_nf), reduce 9 ∣ · to arithmetic mod 9 or mod 3 (the quotient is 3 ∣ n^3 + 2n = (n-1)n(n+1) mod 3, a product of three consecutive integers); alternatively cast to ZMod 9 and close by decide over the 9 residues via Nat.mod cases / omega. 1-2 steps.

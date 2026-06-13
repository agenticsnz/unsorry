# prime-fourth-power-mod-240

The fourth power of every prime p > 5 leaves remainder 1 on division by 240: if p is prime and p > 5 then p⁴ % 240 = 1.

- **Source:** classic identities (fourth-power congruence tower — **root**; deps: the mod-16, mod-3, mod-5 leaves)
- **Reference:** Classic competition gem "240 ∣ p⁴ − 1 for every prime p > 5", one power up from the proved-here "24 ∣ p² − 1 for primes p > 3" (binto-labs, `prime-sq-mod-twenty-four`). 240 = 16·3·5; the result is CRT over the three coprime moduli. Sierpiński, Elementary Theory of Numbers; standard olympiad result.
- **Absence:** machine-checked; the `240` pattern flags only numeric literals in analysis / modular-forms code (the E₄ Eisenstein-series coefficient `240`), verified unrelated — no p⁴-mod-240 congruence present (rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 4
- **Decomposition sketch:** p prime > 5 is odd (not 2), not divisible by 3 (not 3), not divisible by 5 (not 5) — each from primality + the bound. Apply the three leaves: `odd-fourth-power-mod-sixteen` (p⁴ ≡ 1 mod 16), `fourth-power-mod-three` (p⁴ ≡ 1 mod 3), `fourth-power-mod-five` (p⁴ ≡ 1 mod 5). Combine over the pairwise-coprime moduli 16, 3, 5 (lcm 240) to p⁴ ≡ 1 mod 240 — same CRT shape as `prime-sq-mod-twenty-four`, closable by omega on the three congruences. 3 steps, reusing all three leaves.

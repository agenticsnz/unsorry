# fourth-power-mod-three

The fourth power of any natural number not divisible by 3 leaves remainder 1 on division by 3: if n % 3 ≠ 0 then n⁴ % 3 = 1.

- **Source:** classic identities (fourth-power congruence tower — leaf; compounds on `sq-mod-three`)
- **Reference:** Quadratic residues mod 3: n² ≡ 1 (mod 3) for 3∤n, hence n⁴ ≡ 1 (mod 3). Hardy & Wright, An Introduction to the Theory of Numbers. One power up from the proved `sq-mod-three`.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 2
- **Decomposition sketch:** n⁴ = (n²)². Reuse the proved library lemma `sq-mod-three` (n² ≡ 1 mod 3), then (n²)² ≡ 1² = 1 mod 3 via Nat.pow_mod / Nat.mul_mod. 1 step.

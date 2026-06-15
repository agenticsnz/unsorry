# fourth-power-mod-five

The fourth power of any natural number not divisible by 5 leaves remainder 1 on division by 5: if n % 5 ≠ 0 then n⁴ % 5 = 1.

- **Source:** classic identities (fourth-power congruence tower — leaf; the Fermat case p=5)
- **Reference:** Fermat's little theorem at the prime 5: a⁴ ≡ 1 (mod 5) for gcd(a,5)=1. Hardy & Wright, An Introduction to the Theory of Numbers. The mod-5 leaf that the others (mod 16, mod 3) do not cover.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); mathlib has Fermat's little theorem in general (`ZMod.pow_card_sub_one_eq_one`) but not this concrete ℕ remainder statement.
- **Difficulty:** 3
- **Decomposition sketch:** Reduce mod 5: n % 5 ∈ {1,2,3,4} from h; in each residue class n⁴ % 5 = 1 by `decide` over `ZMod 5`, or `Nat.pow_mod` + interval_cases on n % 5 + omega. 1–2 steps.

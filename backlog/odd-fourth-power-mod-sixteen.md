# odd-fourth-power-mod-sixteen

The fourth power of every odd natural number leaves remainder 1 on division by 16: if n is odd then n⁴ % 16 = 1.

- **Source:** classic identities (fourth-power congruence tower — leaf; compounds on `odd-sq-mod-eight`)
- **Reference:** Standard elementary number theory: odd squares are ≡ 1 (mod 8), so odd fourth powers are ≡ 1 (mod 16). Hardy & Wright, An Introduction to the Theory of Numbers (quadratic-residue preliminaries). One power up from the proved `odd-sq-mod-eight`.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 2
- **Decomposition sketch:** n⁴ = (n²)². Reuse the proved library lemma `odd-sq-mod-eight` (n² ≡ 1 mod 8 ⇒ n² = 8k+1), then n⁴ = (8k+1)² = 16(4k²+k)+1 ≡ 1 mod 16; close by omega / Nat.add_mul_mod_self_left. 1–2 steps.

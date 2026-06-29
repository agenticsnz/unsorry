import Mathlib

theorem putnam_1983_a3 (p : ℕ)
(F : ℕ → ℕ)
(poddprime : Odd p ∧ p.Prime)
(hF : ∀ n : ℕ, F n = ∑ i ∈ Finset.range (p - 1), (i + 1) * n ^ i)
: ∀ a ∈ Finset.Icc 1 p, ∀ b ∈ Finset.Icc 1 p, a ≠ b → ¬(F a ≡ F b [MOD p]) := by
  sorry

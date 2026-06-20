import Mathlib

theorem sum_rhombic_dodecahedral_eq_fourth_power (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, ((2 * (k : ℤ) - 1) * (2 * (k : ℤ)^2 - 2 * (k : ℤ) + 1))
      = (n : ℤ)^4 := by
  sorry

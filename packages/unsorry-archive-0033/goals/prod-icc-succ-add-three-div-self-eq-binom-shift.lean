import Mathlib

theorem prod_icc_succ_add_three_div_self_eq_binom_shift (n : ℕ) :
    ∏ k ∈ Finset.Icc 1 n, ((k : ℚ) + 3) / (k : ℚ)
      = ((n : ℚ) + 1) * ((n : ℚ) + 2) * ((n : ℚ) + 3) / 6 := by
  sorry

import Mathlib

theorem sum_range_recip_choose_two_eq_two_n_div_succ (n : ℕ) : ∑ k ∈ Finset.range n, (1 / ((k + 2).choose 2 : ℚ)) = 2 * n / (n + 1) := by
  sorry

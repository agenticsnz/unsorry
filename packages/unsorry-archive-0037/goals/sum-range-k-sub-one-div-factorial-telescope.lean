import Mathlib

theorem sum_range_k_sub_one_div_factorial_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, ((k : ℝ) - 1) / k.factorial = 1 - 1 / n.factorial := by
  sorry

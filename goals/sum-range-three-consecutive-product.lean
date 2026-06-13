import Mathlib

theorem sum_range_mul_succ_mul_succ_succ (n : ℕ) :
    4 * ∑ i ∈ Finset.range n, i * (i + 1) * (i + 2)
      = (n - 1) * n * (n + 1) * (n + 2) := by
  sorry

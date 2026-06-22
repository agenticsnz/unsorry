import Mathlib

theorem sum_range_k_sq_mul_four_pow_closed (n : ℕ) :
    27 * ∑ k ∈ Finset.range n, (k : ℤ)^2 * 4^k
      = 4^n * (9 * (n:ℤ)^2 - 24 * n + 20) - 20 := by
  sorry

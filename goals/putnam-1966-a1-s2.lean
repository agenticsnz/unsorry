import Mathlib

theorem putnam_1966_a1_sum_closed (n : ℤ) (hn : 0 ≤ n) : (∑ m ∈ Finset.Icc 0 n, (if Even m then m / 2 else (m - 1) / 2)) = n ^ 2 / 4 := by
  sorry

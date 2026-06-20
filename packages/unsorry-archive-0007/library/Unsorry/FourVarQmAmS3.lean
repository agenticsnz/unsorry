import Mathlib

theorem two_pair_sums_le_four_sq_sum (a b c d : ℝ) : 2 * ((a + b) ^ 2 + (c + d) ^ 2) ≤ 4 * (a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2)
  := by
  ring_nf
  have h1 : 0 ≤ (a - b) ^ 2 := sq_nonneg (a - b)
  have h2 : 0 ≤ (c - d) ^ 2 := sq_nonneg (c - d)
  linarith
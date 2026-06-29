import Mathlib

theorem sq_lt_two_pow_step_from_five {n : ℕ} (hn : 5 ≤ n) (h : n ^ 2 < 2 ^ n) : (n + 1) ^ 2 < 2 ^ (n + 1) := by
  have h2 : 2 ^ (n + 1) = 2 * 2 ^ n := by ring
  nlinarith [h, hn, sq_nonneg n]
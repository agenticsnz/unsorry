import Mathlib.Tactic.NormNum

theorem sq_lt_two_pow_base_five : (5 : ℕ) ^ 2 < 2 ^ (5 : ℕ) := by
  norm_num

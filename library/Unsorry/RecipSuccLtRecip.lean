import Mathlib

theorem recip_succ_lt_recip (n : ℕ) (hn : 1 ≤ n) : (1 : ℝ) / ((n : ℝ) + 1) < 1 / (n : ℝ) := by
  have hn0 : (0 : ℝ) < (n : ℝ) := by
    have : (1 : ℝ) ≤ (n : ℝ) := by exact_mod_cast hn
    linarith
  exact one_div_lt_one_div_of_lt hn0 (by linarith)

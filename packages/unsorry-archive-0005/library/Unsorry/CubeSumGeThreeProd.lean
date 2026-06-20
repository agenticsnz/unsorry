import Mathlib.Tactic

theorem cube_sum_ge_three_prod (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) : 3 * (a * b * c) ≤ a ^ 3 + b ^ 3 + c ^ 3 := by
  have hsum : 0 ≤ a + b + c := by linarith
  have hsquares : 0 ≤ (a - b) ^ 2 + (b - c) ^ 2 + (c - a) ^ 2 :=
    by nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a)]
  have hprod :
      0 ≤ (a + b + c) * ((a - b) ^ 2 + (b - c) ^ 2 + (c - a) ^ 2) :=
    mul_nonneg hsum hsquares
  nlinarith

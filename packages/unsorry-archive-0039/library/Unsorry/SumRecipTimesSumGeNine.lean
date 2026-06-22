import Mathlib

theorem sum_recip_times_sum_ge_nine (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) : 9 ≤ (a + b + c) * (1 / a + 1 / b + 1 / c) := by
  have ha' := ha.ne'
  have hb' := hb.ne'
  have hc' := hc.ne'
  rw [div_add_div _ _ ha' hb', div_add_div _ _ (mul_ne_zero ha' hb') hc']
  rw [← mul_div_assoc, le_div_iff₀ (by positivity)]
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (a - c), mul_pos ha hb, mul_pos hb hc, mul_pos ha hc, mul_pos (mul_pos ha hb) hc]
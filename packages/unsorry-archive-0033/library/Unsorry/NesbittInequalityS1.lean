import Mathlib

theorem nesbitt_titu_lower_bound (a b c : ℝ) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) : (a + b + c) ^ 2 / (2 * (a * b + b * c + c * a)) ≤ a / (b + c) + b / (c + a) + c / (a + b) := by
  have hbc : 0 < b + c := by linarith
  have hca : 0 < c + a := by linarith
  have hab : 0 < a + b := by linarith
  have hden : 0 < 2 * (a * b + b * c + c * a) := by nlinarith [mul_pos ha hb, mul_pos hb hc, mul_pos hc ha]
  have key : a / (b + c) + b / (c + a) + c / (a + b)
      = (a * (c + a) * (a + b) + b * (b + c) * (a + b) + c * (b + c) * (c + a))
        / ((b + c) * (c + a) * (a + b)) := by
    field_simp
  rw [key, le_div_iff₀ (by positivity), div_mul_eq_mul_div, div_le_iff₀ hden]
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a),
    mul_pos ha hb, mul_pos hb hc, mul_pos hc ha, mul_pos (mul_pos ha hb) hc,
    mul_pos hbc hca, mul_pos hca hab, mul_pos hbc hab,
    mul_pos ha (mul_pos hb hc),
    mul_nonneg (mul_nonneg ha.le hb.le) (sq_nonneg (a - b)),
    mul_nonneg (mul_nonneg hb.le hc.le) (sq_nonneg (b - c)),
    mul_nonneg (mul_nonneg hc.le ha.le) (sq_nonneg (c - a)),
    mul_nonneg hc.le (sq_nonneg (a - b)),
    mul_nonneg ha.le (sq_nonneg (b - c)),
    mul_nonneg hb.le (sq_nonneg (c - a))]
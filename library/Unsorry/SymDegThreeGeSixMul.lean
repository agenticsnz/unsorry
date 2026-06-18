import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sym_deg_three_ge_six_mul (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) : 6 * (a * b * c) ≤ a ^ 2 * b + a * b ^ 2 + b ^ 2 * c + b * c ^ 2 + c ^ 2 * a + c * a ^ 2 := by
  first
    | nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c), mul_nonneg ha hb, mul_nonneg ha hc, mul_nonneg hb hc, mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)), mul_nonneg hc (sq_nonneg (a - b)), mul_nonneg (mul_nonneg ha hb) hc]
    | positivity
    | omega
    | (nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c), mul_nonneg ha hb, mul_nonneg ha hc, mul_nonneg hb hc, mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)), mul_nonneg hc (sq_nonneg (a - b)), mul_nonneg (mul_nonneg ha hb) hc, sq_nonneg (1:ℝ)])
    | (field_simp; rw [div_le_div_iff] <;> nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c), mul_nonneg ha hb, mul_nonneg ha hc, mul_nonneg hb hc, mul_nonneg ha (sq_nonneg (b - c)), mul_nonneg hb (sq_nonneg (a - c)), mul_nonneg hc (sq_nonneg (a - b)), mul_nonneg (mul_nonneg ha hb) hc])

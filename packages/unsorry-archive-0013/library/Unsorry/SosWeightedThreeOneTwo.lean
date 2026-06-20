import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sos_weighted_three_one_two (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : 3 * (a ^ 2 * b) ≤ a ^ 3 + 2 * b ^ 3 + a ^ 3 := by
  first
    | nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), mul_nonneg ha hb]
    | positivity
    | omega
    | (nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), mul_nonneg ha hb, sq_nonneg (1:ℝ)])
    | (field_simp; rw [div_le_div_iff] <;> nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), mul_nonneg ha hb])

import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sumsq_ge_ab_plus_bc (a b c : ℝ) : a * b + b * c ≤ a ^ 2 + b ^ 2 + c ^ 2 := by
  first
    | nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c)]
    | positivity
    | omega
    | (nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c), sq_nonneg (1:ℝ)])
    | (field_simp; rw [div_le_div_iff] <;> nlinarith [sq_nonneg a, sq_nonneg b, sq_nonneg c, sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg (a^2 - b^2), sq_nonneg (a*b), sq_nonneg (a - c), sq_nonneg (a + c), sq_nonneg (a^2 - c^2), sq_nonneg (a*c), sq_nonneg (b - c), sq_nonneg (b + c), sq_nonneg (b^2 - c^2), sq_nonneg (b*c), sq_nonneg (a + b - c)])

import Mathlib.Analysis.SpecialFunctions.Log.Base

/-!
AMC 12A 2003 Problem 24: over all reals `1 < b ≤ a`, the greatest value of
`logb a (a / b) + logb b (b / a)` is `0`.

The value `0` is attained at `a = b = 2`. For the upper bound, writing
`x = log a` and `y = log b` (both positive since `a` and `b` exceed `1`),
the expression is `(x - y) / x + (y - x) / y = -(x - y) ^ 2 / (x * y)`,
which is nonpositive because the numerator is a square and the denominator
is positive.
-/

theorem amc12a_2003_p24 :
    IsGreatest { y : ℝ | ∃ a b : ℝ, 1 < b ∧ b ≤ a ∧
      y = Real.logb a (a / b) + Real.logb b (b / a) } 0 := by
  constructor
  · exact ⟨2, 2, one_lt_two, le_rfl, by norm_num⟩
  · rintro y ⟨a, b, hb, hba, rfl⟩
    have ha : (1 : ℝ) < a := hb.trans_le hba
    have hb0 : (0 : ℝ) < b := one_pos.trans hb
    have ha0 : (0 : ℝ) < a := one_pos.trans ha
    have hlb : 0 < Real.log b := Real.log_pos hb
    have hla : 0 < Real.log a := Real.log_pos ha
    have key : Real.logb a (a / b) + Real.logb b (b / a) =
        -((Real.log a - Real.log b) ^ 2 / (Real.log a * Real.log b)) := by
      simp only [Real.logb, Real.log_div ha0.ne' hb0.ne',
        Real.log_div hb0.ne' ha0.ne']
      field_simp
      ring
    rw [key]
    exact neg_nonpos.mpr (div_nonneg (sq_nonneg _) (mul_nonneg hla.le hlb.le))

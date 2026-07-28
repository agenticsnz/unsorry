import Mathlib.Data.Real.Basic

/-- The product of two positive real numbers is positive. -/
theorem aime_1983_p9_mul_pos (a b : ℝ) (ha : 0 < a) (hb : 0 < b) : 0 < a * b :=
  mul_pos ha hb

import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

/-- The sine of a real number strictly between `0` and `π` is strictly positive. -/
theorem aime_1983_p9_sin_pos (x : ℝ) (h₀ : 0 < x) (h₁ : x < Real.pi) : 0 < Real.sin x :=
  Real.sin_pos_of_pos_of_lt_pi h₀ h₁

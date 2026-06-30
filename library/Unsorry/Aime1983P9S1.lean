import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

/-!
# AIME 1983 Problem 9 (positivity sublemma)

For `0 < x < π`, both `x` and `Real.sin x` are positive, so their product is positive.
-/

theorem aime_1983_p9_xsin_pos (x : ℝ) (h₀ : 0 < x ∧ x < Real.pi) :
    0 < x * Real.sin x :=
  mul_pos h₀.1 (Real.sin_pos_of_pos_of_lt_pi h₀.1 h₀.2)

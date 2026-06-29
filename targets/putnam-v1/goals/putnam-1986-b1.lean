import Mathlib

open  Real Equiv
noncomputable abbrev putnam_1986_b1_solution : ℝ := 2 / 5

theorem putnam_1986_b1 (b h : ℝ)
(hbh : b > 0 ∧ h > 0 ∧ b ^ 2 + h ^ 2 = 2 ^ 2)
(areaeq : b * h = 0.5 * b * (1 - h / 2))
: h = putnam_1986_b1_solution := by
  sorry

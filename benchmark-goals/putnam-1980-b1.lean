import Mathlib

open Real
abbrev putnam_1980_b1_solution : Set ℝ := {c : ℝ | c ≥ 1 / 2}

theorem putnam_1980_b1 (c : ℝ)
: (∀ x : ℝ, (exp x + exp (-x)) / 2 ≤ exp (c * x ^ 2)) ↔ c ∈ putnam_1980_b1_solution := by
  sorry

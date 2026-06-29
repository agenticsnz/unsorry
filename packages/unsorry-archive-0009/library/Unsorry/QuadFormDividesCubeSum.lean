import Mathlib

theorem quad_form_divides_cube_sum (a b : ℤ) : (a ^ 2 - a * b + b ^ 2) ∣ (a ^ 3 + b ^ 3) := by
  exact ⟨a + b, by ring⟩

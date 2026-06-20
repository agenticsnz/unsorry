import Mathlib

theorem three_cubes_minus_three_prod_dvd_sum (a b c : ℤ) : (a + b + c) ∣ (a^3 + b^3 + c^3 - 3*a*b*c) := by
  exact ⟨a^2 + b^2 + c^2 - a*b - b*c - c*a, by ring⟩

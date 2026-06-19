import Mathlib

theorem pell_d2_solution_coords_coprime (x y : ℤ) (h : x^2 - 2*y^2 = 1) : IsCoprime x y := by
  exact ⟨x, -2 * y, by linear_combination h⟩

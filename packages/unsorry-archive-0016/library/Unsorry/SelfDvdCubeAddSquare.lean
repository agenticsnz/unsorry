import Mathlib

theorem self_dvd_cube_add_square (n : ℤ) : n ∣ n ^ 3 + n ^ 2 := by
  exact ⟨n ^ 2 + n, by ring⟩

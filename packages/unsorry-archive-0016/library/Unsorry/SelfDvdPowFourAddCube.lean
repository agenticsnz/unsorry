import Mathlib

theorem self_dvd_pow_four_add_cube (n : ℤ) : n ∣ n ^ 4 + n ^ 3 := by
  exact ⟨n ^ 3 + n ^ 2, by ring⟩

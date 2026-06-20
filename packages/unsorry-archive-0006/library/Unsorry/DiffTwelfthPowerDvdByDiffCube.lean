import Mathlib

theorem diff_twelfth_power_dvd_by_diff_cube (a b : ℤ) : (a ^ 3 - b ^ 3) ∣ (a ^ 12 - b ^ 12) := by
  exact ⟨a ^ 9 + a ^ 6 * b ^ 3 + a ^ 3 * b ^ 6 + b ^ 9, by ring⟩

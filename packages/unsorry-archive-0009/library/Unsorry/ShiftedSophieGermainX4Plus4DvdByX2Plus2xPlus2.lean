import Mathlib

theorem shifted_sophie_germain_x4_plus_4_dvd_by_x2_plus_2x_plus_2 (x : ℤ) : (x ^ 2 + 2 * x + 2) ∣ (x ^ 4 + 4) := by
  exact ⟨x ^ 2 - 2 * x + 2, by ring⟩

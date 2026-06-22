import Mathlib

theorem sophie_germain_plus_factor_dvd (a b : ℤ) : (a ^ 2 + 2 * a * b + 2 * b ^ 2) ∣ (a ^ 4 + 4 * b ^ 4) := by
  exact ⟨a ^ 2 - 2 * a * b + 2 * b ^ 2, by ring⟩
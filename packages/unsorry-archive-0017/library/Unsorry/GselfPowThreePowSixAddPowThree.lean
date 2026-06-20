import Mathlib

theorem gself_pow_three_pow_six_add_pow_three (n : ℤ) : (n^3) ∣ (n^6 + n^3) := by
  exact ⟨n^3 + 1, by ring⟩

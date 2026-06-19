import Mathlib

theorem gself_pow_seven_add_pow_three (n : ℤ) : (n) ∣ (n^7 + n^3) := by
  exact ⟨n^6 + n^2, by ring⟩

import Mathlib

theorem gself_pow_six_add_pow_three (n : ℤ) : (n) ∣ (n^6 + n^3) := by
  exact ⟨n^5 + n^2, by ring⟩

import Mathlib

theorem gself_pow_three_pow_twelve_add_pow_six (n : ℤ) : (n^3) ∣ (n^12 + n^6) := by
  exact ⟨n^9 + n^3, by ring⟩

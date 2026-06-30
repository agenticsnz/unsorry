import Mathlib

theorem gself_pow_three_pow_seven_add_pow_six (n : ℤ) : (n^3) ∣ (n^7 + n^6) := by
  exact ⟨n^4 + n^3, by ring⟩

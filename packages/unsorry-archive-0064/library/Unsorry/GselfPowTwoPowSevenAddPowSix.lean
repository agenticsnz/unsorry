import Mathlib

theorem gself_pow_two_pow_seven_add_pow_six (n : ℤ) : (n^2) ∣ (n^7 + n^6) := by
  exact ⟨n^5 + n^4, by ring⟩

import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_six (n : ℤ) : (n^3) ∣ (n^20 + n^6) := by
  exact ⟨n^17 + n^3, by ring⟩

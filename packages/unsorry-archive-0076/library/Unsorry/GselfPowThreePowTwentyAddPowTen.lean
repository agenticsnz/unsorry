import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_ten (n : ℤ) : (n^3) ∣ (n^20 + n^10) := by
  exact ⟨n^17 + n^7, by ring⟩

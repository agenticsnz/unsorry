import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_seven (n : ℤ) : (n^3) ∣ (n^20 + n^7) := by
  exact ⟨n^17 + n^4, by ring⟩

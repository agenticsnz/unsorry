import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_nine (n : ℤ) : (n^3) ∣ (n^20 + n^9) := by
  exact ⟨n^17 + n^6, by ring⟩

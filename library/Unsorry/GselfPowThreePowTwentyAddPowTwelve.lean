import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^20 + n^12) := by
  exact ⟨n^17 + n^9, by ring⟩

import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^20 + n^12) := by
  exact ⟨n^16 + n^8, by ring⟩

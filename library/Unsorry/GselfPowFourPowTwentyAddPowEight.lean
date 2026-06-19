import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_eight (n : ℤ) : (n^4) ∣ (n^20 + n^8) := by
  exact ⟨n^16 + n^4, by ring⟩

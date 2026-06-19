import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_fifteen (n : ℤ) : (n^4) ∣ (n^20 + n^15) := by
  exact ⟨n^16 + n^11, by ring⟩

import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_eleven (n : ℤ) : (n^4) ∣ (n^20 + n^11) := by
  exact ⟨n^16 + n^7, by ring⟩

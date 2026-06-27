import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^20 + n^14) := by
  exact ⟨n^17 + n^11, by ring⟩

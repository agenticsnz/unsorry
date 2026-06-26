import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_three (n : ℤ) : (n^3) ∣ (n^20 + n^3) := by
  exact ⟨n^17 + 1, by ring⟩

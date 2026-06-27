import Mathlib

theorem gself_pow_three_pow_24_add_pow_twenty (n : ℤ) : (n^3) ∣ (n^24 + n^20) := by
  exact ⟨n^21 + n^17, by ring⟩

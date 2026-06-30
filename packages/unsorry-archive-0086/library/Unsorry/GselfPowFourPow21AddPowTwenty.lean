import Mathlib

theorem gself_pow_four_pow_21_add_pow_twenty (n : ℤ) : (n^4) ∣ (n^21 + n^20) := by
  exact ⟨n^17 + n^16, by ring⟩

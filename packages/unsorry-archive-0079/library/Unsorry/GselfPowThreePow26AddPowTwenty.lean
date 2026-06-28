import Mathlib

theorem gself_pow_three_pow_26_add_pow_twenty (n : ℤ) : (n^3) ∣ (n^26 + n^20) := by
  exact ⟨n^23 + n^17, by ring⟩

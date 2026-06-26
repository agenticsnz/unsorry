import Mathlib

theorem gself_pow_three_pow_23_add_pow_twenty (n : ℤ) : (n^3) ∣ (n^23 + n^20) := by
  exact ⟨n^20 + n^17, by ring⟩

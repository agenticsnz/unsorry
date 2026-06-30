import Mathlib

theorem gself_pow_three_pow_23_add_pow_ten (n : ℤ) : (n^3) ∣ (n^23 + n^10) := by
  exact ⟨n^20 + n^7, by ring⟩

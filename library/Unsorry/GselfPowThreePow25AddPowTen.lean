import Mathlib

theorem gself_pow_three_pow_25_add_pow_ten (n : ℤ) : (n^3) ∣ (n^25 + n^10) := by
  exact ⟨n^22 + n^7, by ring⟩

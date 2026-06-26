import Mathlib

theorem gself_pow_three_pow_21_add_pow_ten (n : ℤ) : (n^3) ∣ (n^21 + n^10) := by
  exact ⟨n^18 + n^7, by ring⟩

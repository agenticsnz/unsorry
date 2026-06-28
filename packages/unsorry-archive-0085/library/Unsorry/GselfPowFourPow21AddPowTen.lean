import Mathlib

theorem gself_pow_four_pow_21_add_pow_ten (n : ℤ) : (n^4) ∣ (n^21 + n^10) := by
  exact ⟨n^17 + n^6, by ring⟩

import Mathlib

theorem gself_pow_22_add_pow_ten (n : ℤ) : (n) ∣ (n^22 + n^10) := by
  exact ⟨n^21 + n^9, by ring⟩

import Mathlib

theorem gself_pow_three_pow_29_add_pow_ten (n : ℤ) : (n^3) ∣ (n^29 + n^10) := by
  exact ⟨n^26 + n^7, by ring⟩

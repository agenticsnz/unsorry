import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_ten (n : ℤ) : (n^2) ∣ (n^17 + n^10) := by
  exact ⟨n^15 + n^8, by ring⟩

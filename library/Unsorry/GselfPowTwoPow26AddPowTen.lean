import Mathlib

theorem gself_pow_two_pow_26_add_pow_ten (n : ℤ) : (n^2) ∣ (n^26 + n^10) := by
  exact ⟨n^24 + n^8, by ring⟩

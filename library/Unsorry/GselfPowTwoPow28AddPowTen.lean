import Mathlib

theorem gself_pow_two_pow_28_add_pow_ten (n : ℤ) : (n^2) ∣ (n^28 + n^10) := by
  exact ⟨n^26 + n^8, by ring⟩

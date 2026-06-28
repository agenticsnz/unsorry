import Mathlib

theorem gself_pow_three_pow_28_add_pow_ten (n : ℤ) : (n^3) ∣ (n^28 + n^10) := by
  exact ⟨n^25 + n^7, by ring⟩

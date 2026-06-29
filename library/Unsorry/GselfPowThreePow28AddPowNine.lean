import Mathlib

theorem gself_pow_three_pow_28_add_pow_nine (n : ℤ) : (n^3) ∣ (n^28 + n^9) := by
  exact ⟨n^25 + n^6, by ring⟩

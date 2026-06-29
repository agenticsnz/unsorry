import Mathlib

theorem gself_pow_three_pow_28_add_pow_eight (n : ℤ) : (n^3) ∣ (n^28 + n^8) := by
  exact ⟨n^25 + n^5, by ring⟩

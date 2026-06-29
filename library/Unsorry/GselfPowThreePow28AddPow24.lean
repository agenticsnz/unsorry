import Mathlib

theorem gself_pow_three_pow_28_add_pow_24 (n : ℤ) : (n^3) ∣ (n^28 + n^24) := by
  exact ⟨n^25 + n^21, by ring⟩

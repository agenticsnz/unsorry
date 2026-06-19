import Mathlib

theorem gself_pow_three_pow_28_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^28 + n^14) := by
  exact ⟨n^25 + n^11, by ring⟩

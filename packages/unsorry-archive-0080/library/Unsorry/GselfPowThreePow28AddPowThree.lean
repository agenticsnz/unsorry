import Mathlib

theorem gself_pow_three_pow_28_add_pow_three (n : ℤ) : (n^3) ∣ (n^28 + n^3) := by
  exact ⟨n^25 + 1, by ring⟩

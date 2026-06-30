import Mathlib

theorem gself_pow_three_pow_28_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^28 + n^15) := by
  exact ⟨n^25 + n^12, by ring⟩

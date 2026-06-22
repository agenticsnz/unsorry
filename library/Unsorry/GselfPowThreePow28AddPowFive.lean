import Mathlib

theorem gself_pow_three_pow_28_add_pow_five (n : ℤ) : (n^3) ∣ (n^28 + n^5) := by
  exact ⟨n^25 + n^2, by ring⟩

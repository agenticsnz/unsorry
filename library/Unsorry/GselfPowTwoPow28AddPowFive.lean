import Mathlib

theorem gself_pow_two_pow_28_add_pow_five (n : ℤ) : (n^2) ∣ (n^28 + n^5) := by
  exact ⟨n^26 + n^3, by ring⟩

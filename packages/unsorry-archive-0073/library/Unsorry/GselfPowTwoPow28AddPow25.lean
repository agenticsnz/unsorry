import Mathlib

theorem gself_pow_two_pow_28_add_pow_25 (n : ℤ) : (n^2) ∣ (n^28 + n^25) := by
  exact ⟨n^26 + n^23, by ring⟩

import Mathlib

theorem gself_pow_two_pow_28_add_pow_two (n : ℤ) : (n^2) ∣ (n^28 + n^2) := by
  exact ⟨n^26 + 1, by ring⟩

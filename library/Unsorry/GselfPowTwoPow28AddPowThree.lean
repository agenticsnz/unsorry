import Mathlib

theorem gself_pow_two_pow_28_add_pow_three (n : ℤ) : (n^2) ∣ (n^28 + n^3) := by
  exact ⟨n^26 + n, by ring⟩
